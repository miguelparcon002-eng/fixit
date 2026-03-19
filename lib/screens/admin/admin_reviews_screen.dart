import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/ratings_provider.dart';
import '../../services/ratings_service.dart';
import '../../core/widgets/app_logo.dart';

// ── Filter state ────────────────────────────────────────────────────────────

enum _SortOrder { newest, oldest, highestRating, lowestRating }

class _FilterState {
  final String? technician;   // null = all
  final int? starFilter;      // null = all
  final _SortOrder sort;
  final String search;

  const _FilterState({
    this.technician,
    this.starFilter,
    this.sort = _SortOrder.newest,
    this.search = '',
  });

  bool get isActive =>
      technician != null || starFilter != null || search.isNotEmpty;

  _FilterState copyWith({
    Object? technician = _sentinel,
    Object? starFilter = _sentinel,
    _SortOrder? sort,
    String? search,
  }) =>
      _FilterState(
        technician: technician == _sentinel
            ? this.technician
            : technician as String?,
        starFilter: starFilter == _sentinel
            ? this.starFilter
            : starFilter as int?,
        sort: sort ?? this.sort,
        search: search ?? this.search,
      );

  static const _sentinel = Object();
}

// ── Screen ───────────────────────────────────────────────────────────────────

class AdminReviewsScreen extends ConsumerStatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  ConsumerState<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends ConsumerState<AdminReviewsScreen> {
  _FilterState _filter = const _FilterState();
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Rating> _apply(List<Rating> all) {
    var list = all.where((r) {
      if (_filter.technician != null && r.technician != _filter.technician) {
        return false;
      }
      if (_filter.starFilter != null && r.rating != _filter.starFilter) {
        return false;
      }
      if (_filter.search.isNotEmpty) {
        final q = _filter.search.toLowerCase();
        if (!r.customerName.toLowerCase().contains(q) &&
            !r.technician.toLowerCase().contains(q) &&
            !r.review.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();

    switch (_filter.sort) {
      case _SortOrder.newest:
        list.sort((a, b) => b.date.compareTo(a.date));
      case _SortOrder.oldest:
        list.sort((a, b) => a.date.compareTo(b.date));
      case _SortOrder.highestRating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _SortOrder.lowestRating:
        list.sort((a, b) => a.rating.compareTo(b.rating));
    }
    return list;
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() => _filter = const _FilterState());
  }

  @override
  Widget build(BuildContext context) {
    final ratingsAsync = ref.watch(ratingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/admin-home'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const AppLogo(
                size: 28,
                showText: false,
                assetPath: 'assets/images/logo_square.png'),
            const SizedBox(width: 10),
            const Text(
              'Customer Reviews',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.deepBlue),
            onPressed: () => ref.invalidate(ratingsProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
      ),
      body: ratingsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.deepBlue)),
        error: (_, _) => const Center(child: Text('Error loading reviews')),
        data: (allRatings) {
          // Unique technician names for filter
          final techNames = allRatings
              .map((r) => r.technician)
              .toSet()
              .toList()
            ..sort();

          // Per-technician stats (for summary cards)
          final Map<String, List<Rating>> byTech = {};
          for (final r in allRatings) {
            byTech.putIfAbsent(r.technician, () => []).add(r);
          }

          final filtered = _apply(allRatings);
          final overallAvg = filtered.isEmpty
              ? 0.0
              : filtered.map((r) => r.rating).reduce((a, b) => a + b) /
                  filtered.length;

          return Column(
            children: [
              // ── Stats header ───────────────────────────────────────
              _StatsHeader(
                totalReviews: allRatings.length,
                filteredCount: filtered.length,
                avgRating: overallAvg,
                techCount: techNames.length,
                isFiltered: _filter.isActive,
              ),

              // ── Search bar ─────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      setState(() => _filter = _filter.copyWith(search: v)),
                  decoration: InputDecoration(
                    hintText: 'Search customer, technician or review…',
                    hintStyle:
                        TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 20, color: AppTheme.deepBlue),
                    suffixIcon: _filter.search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 18, color: Colors.grey),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _filter =
                                  _filter.copyWith(search: ''));
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.deepBlue, width: 1.5),
                    ),
                  ),
                ),
              ),

              // ── Filter chips ───────────────────────────────────────
              _FilterBar(
                techNames: techNames,
                filter: _filter,
                byTech: byTech,
                onChanged: (f) => setState(() => _filter = f),
                onClear: _clearFilters,
              ),

              // ── Active filter banner ───────────────────────────────
              if (_filter.isActive)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list_rounded,
                          size: 14, color: AppTheme.deepBlue),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Showing ${filtered.length} of ${allRatings.length} reviews',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.deepBlue,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearFilters,
                        child: const Text('Clear all',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),

              // ── Review list ────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? _EmptyState(isFiltered: _filter.isActive)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) => _ReviewCard(rating: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Stats header ─────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  final int totalReviews;
  final int filteredCount;
  final double avgRating;
  final int techCount;
  final bool isFiltered;

  const _StatsHeader({
    required this.totalReviews,
    required this.filteredCount,
    required this.avgRating,
    required this.techCount,
    required this.isFiltered,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.deepBlue, AppTheme.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppTheme.deepBlue.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatTile(
            icon: Icons.star_rounded,
            iconColor: Colors.amber,
            value: avgRating.toStringAsFixed(1),
            label: 'Avg Rating',
          ),
          _Divider(),
          _StatTile(
            icon: Icons.rate_review_rounded,
            iconColor: Colors.white,
            value: isFiltered ? '$filteredCount/$totalReviews' : '$totalReviews',
            label: 'Reviews',
          ),
          _Divider(),
          _StatTile(
            icon: Icons.engineering_rounded,
            iconColor: Colors.white,
            value: '$techCount',
            label: 'Technicians',
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _StatTile(
      {required this.icon,
      required this.iconColor,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ]),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500)),
        ],
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
      width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3));
}

// ── Filter bar ────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  final List<String> techNames;
  final Map<String, List<Rating>> byTech;
  final _FilterState filter;
  final ValueChanged<_FilterState> onChanged;
  final VoidCallback onClear;

  const _FilterBar({
    required this.techNames,
    required this.byTech,
    required this.filter,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Technician filter + Sort
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Technician dropdown
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: filter.technician != null
                          ? AppTheme.deepBlue
                          : Colors.grey.shade200,
                      width: filter.technician != null ? 1.5 : 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: filter.technician,
                      isExpanded: true,
                      hint: const Text('All Technicians',
                          style: TextStyle(fontSize: 13)),
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.w600),
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: filter.technician != null
                              ? AppTheme.deepBlue
                              : Colors.grey),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Technicians'),
                        ),
                        ...techNames.map((t) {
                          final count = byTech[t]?.length ?? 0;
                          final avg = byTech[t] == null || byTech[t]!.isEmpty
                              ? 0.0
                              : byTech[t]!
                                      .map((r) => r.rating)
                                      .reduce((a, b) => a + b) /
                                  byTech[t]!.length;
                          return DropdownMenuItem<String?>(
                            value: t,
                            child: Row(
                              children: [
                                Expanded(
                                    child: Text(t,
                                        overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '★ ${avg.toStringAsFixed(1)} ($count)',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (v) =>
                          onChanged(filter.copyWith(technician: v)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Sort button
              _SortButton(
                current: filter.sort,
                onChanged: (s) => onChanged(filter.copyWith(sort: s)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Row 2: Star chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _StarChip(
                label: 'All Stars',
                isSelected: filter.starFilter == null,
                color: AppTheme.deepBlue,
                onTap: () => onChanged(filter.copyWith(starFilter: null)),
              ),
              ...List.generate(5, (i) {
                final star = 5 - i;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _StarChip(
                    label: '$star★',
                    isSelected: filter.starFilter == star,
                    color: _starColor(star),
                    count: byTech.values
                        .expand((l) => l)
                        .where((r) => r.rating == star)
                        .length,
                    onTap: () =>
                        onChanged(filter.copyWith(starFilter: star)),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Color _starColor(int star) {
    switch (star) {
      case 5: return const Color(0xFF00C853);
      case 4: return const Color(0xFF64DD17);
      case 3: return const Color(0xFFFFD600);
      case 2: return const Color(0xFFFF6D00);
      default: return const Color(0xFFDD2C00);
    }
  }
}

class _StarChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final int? count;
  final VoidCallback onTap;

  const _StarChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white70
                      : AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final _SortOrder current;
  final ValueChanged<_SortOrder> onChanged;

  const _SortButton({required this.current, required this.onChanged});

  String get _label {
    switch (current) {
      case _SortOrder.newest: return 'Newest';
      case _SortOrder.oldest: return 'Oldest';
      case _SortOrder.highestRating: return 'Top Rated';
      case _SortOrder.lowestRating: return 'Low Rated';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SortOrder>(
      initialValue: current,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded,
                size: 16, color: AppTheme.deepBlue),
            const SizedBox(width: 4),
            Text(_label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor)),
          ],
        ),
      ),
      itemBuilder: (_) => [
        _sortItem(_SortOrder.newest, 'Newest First', Icons.arrow_downward_rounded),
        _sortItem(_SortOrder.oldest, 'Oldest First', Icons.arrow_upward_rounded),
        _sortItem(_SortOrder.highestRating, 'Highest Rating', Icons.star_rounded),
        _sortItem(_SortOrder.lowestRating, 'Lowest Rating', Icons.star_outline_rounded),
      ],
    );
  }

  PopupMenuItem<_SortOrder> _sortItem(
          _SortOrder v, String label, IconData icon) =>
      PopupMenuItem(
        value: v,
        child: Row(children: [
          Icon(icon, size: 16, color: AppTheme.deepBlue),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ]),
      );
}

// ── Review card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final Rating rating;
  const _ReviewCard({required this.rating});

  Color get _starColor {
    switch (rating.rating) {
      case 5: return const Color(0xFF00C853);
      case 4: return const Color(0xFF64DD17);
      case 3: return const Color(0xFFFFD600);
      case 2: return const Color(0xFFFF6D00);
      default: return const Color(0xFFDD2C00);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Colored top strip
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: _starColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          AppTheme.deepBlue.withValues(alpha: 0.1),
                      child: Text(
                        rating.customerName.isNotEmpty
                            ? rating.customerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.deepBlue),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rating.customerName,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimaryColor)),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(
                                5,
                                (i) => Icon(
                                      i < rating.rating
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: Colors.amber,
                                      size: 16,
                                    )),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _starColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${rating.rating}.0',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(rating.date,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Technician chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.deepBlue.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.engineering_rounded,
                          size: 14, color: AppTheme.deepBlue),
                      const SizedBox(width: 6),
                      Text(rating.technician,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.deepBlue)),
                    ],
                  ),
                ),

                // Service/device chips
                if (rating.service.isNotEmpty || rating.device.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (rating.device.isNotEmpty)
                        _InfoChip(
                            icon: Icons.phone_android_rounded,
                            label: rating.device),
                      if (rating.service.isNotEmpty)
                        _InfoChip(
                            icon: Icons.build_rounded,
                            label: rating.service),
                    ],
                  ),
                ],

                // Review text
                if (rating.review.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.format_quote_rounded,
                            size: 16,
                            color: AppTheme.textSecondaryColor),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            rating.review,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimaryColor,
                                height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: AppTheme.textSecondaryColor),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600)),
        ]),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  const _EmptyState({required this.isFiltered});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered
                  ? Icons.filter_list_off_rounded
                  : Icons.star_outline_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'No reviews match your filter' : 'No reviews yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500),
            ),
            if (isFiltered) ...[
              const SizedBox(height: 8),
              Text('Try adjusting your search or filters',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade400)),
            ],
          ],
        ),
      );
}
