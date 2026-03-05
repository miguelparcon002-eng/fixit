import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/ratings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/ratings_service.dart';

// ─── Filter state ──────────────────────────────────────────────────────────────

enum RatingsSortOrder { newest, oldest }

// null = show all stars; 1-5 = filter to that star count
final ratingsStarFilterProvider = StateProvider<int?>((ref) => null);
final ratingsSortOrderProvider = StateProvider<RatingsSortOrder>((ref) => RatingsSortOrder.newest);

// ─── Screen ────────────────────────────────────────────────────────────────────

class TechRatingsScreen extends ConsumerWidget {
  const TechRatingsScreen({super.key});

  bool _isRatingForTechnician(String ratingTechnician, String userName) {
    final userNameLower = userName.toLowerCase();
    final ratingTechLower = ratingTechnician.toLowerCase();
    if (ratingTechLower == userNameLower) return true;
    if (userNameLower.contains(ratingTechLower)) return true;
    final nameParts = userName.split(' ');
    if (nameParts.length > 1) {
      final lastName = nameParts.last.toLowerCase();
      if (lastName == ratingTechLower) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingsAsync = ref.watch(ratingsProvider);
    final userAsync = ref.watch(currentUserProvider);
    final userName = userAsync.whenOrNull(data: (u) => u?.fullName) ?? 'Technician';
    final starFilter = ref.watch(ratingsStarFilterProvider);
    final sortOrder = ref.watch(ratingsSortOrderProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimaryColor, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/tech-profile');
            }
          },
        ),
        title: const Text(
          'Ratings & Reviews',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        actions: [
          // Sort button
          IconButton(
            tooltip: sortOrder == RatingsSortOrder.newest ? 'Sort: Newest first' : 'Sort: Oldest first',
            icon: Icon(
              sortOrder == RatingsSortOrder.newest ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: AppTheme.deepBlue,
            ),
            onPressed: () {
              ref.read(ratingsSortOrderProvider.notifier).state =
                  sortOrder == RatingsSortOrder.newest
                      ? RatingsSortOrder.oldest
                      : RatingsSortOrder.newest;
            },
          ),
        ],
      ),
      body: ratingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepBlue),
          ),
        ),
        error: (e, s) => const Center(child: Text('Error loading ratings')),
        data: (allRatings) {
          final myRatings = allRatings
              .where((r) => _isRatingForTechnician(r.technician, userName))
              .toList();

          // Stats
          final avg = myRatings.isEmpty
              ? 0.0
              : myRatings.map((r) => r.rating).reduce((a, b) => a + b) / myRatings.length;

          final starCounts = List.generate(5, (i) {
            final star = 5 - i;
            return myRatings.where((r) => r.rating == star).length;
          });

          // Apply filters
          var filtered = starFilter != null
              ? myRatings.where((r) => r.rating == starFilter).toList()
              : List<Rating>.from(myRatings);

          // Sort by date string (format: "Month DD, YYYY" or ISO)
          filtered.sort((a, b) {
            DateTime? da = _parseDate(a.date);
            DateTime? db = _parseDate(b.date);
            if (da == null && db == null) return 0;
            if (da == null) return 1;
            if (db == null) return -1;
            return sortOrder == RatingsSortOrder.newest
                ? db.compareTo(da)
                : da.compareTo(db);
          });

          return CustomScrollView(
            slivers: [
              // ── Summary header ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: _SummaryCard(
                    avg: avg,
                    total: myRatings.length,
                    starCounts: starCounts,
                  ),
                ),
              ),

              // ── Star filter chips ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Row(
                    children: [
                      _StarChip(
                        label: 'All',
                        isSelected: starFilter == null,
                        onTap: () => ref.read(ratingsStarFilterProvider.notifier).state = null,
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(5, (i) {
                        final star = 5 - i;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _StarChip(
                            label: '$star★',
                            isSelected: starFilter == star,
                            onTap: () => ref.read(ratingsStarFilterProvider.notifier).state = star,
                            color: _starColor(star),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // ── Result count ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    '${filtered.length} review${filtered.length != 1 ? 's' : ''}${starFilter != null ? ' for $starFilter★' : ''}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ),

              // ── Review cards ─────────────────────────────────────────────────
              if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_outline_rounded, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          starFilter != null
                              ? 'No $starFilter-star reviews yet'
                              : 'No reviews yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        if (starFilter == null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Complete jobs to receive reviews',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReviewCard(rating: filtered[index]),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
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

  DateTime? _parseDate(String date) {
    // Try ISO 8601 (e.g. "2026-03-04" or "2026-03-04T...")
    try {
      return DateTime.parse(date);
    } catch (_) {}
    // Try MM/dd/yyyy — the format used when saving ratings (DateFormat('MM/dd/yyyy'))
    try {
      return DateFormat('MM/dd/yyyy').parse(date);
    } catch (_) {}
    // Try M/d/yyyy
    try {
      return DateFormat('M/d/yyyy').parse(date);
    } catch (_) {}
    // Try "MMMM dd, yyyy" e.g. "March 04, 2026"
    try {
      return DateFormat('MMMM dd, yyyy').parse(date);
    } catch (_) {}
    // Try "MMM dd, yyyy" e.g. "Mar 04, 2026"
    try {
      return DateFormat('MMM dd, yyyy').parse(date);
    } catch (_) {}
    return null;
  }
}

// ─── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final double avg;
  final int total;
  final List<int> starCounts; // index 0 = 5★, index 4 = 1★

  const _SummaryCard({required this.avg, required this.total, required this.starCounts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.deepBlue, AppTheme.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepBlue.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: big number + stars
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(5, (i) => Icon(
                  i < avg.floor()
                      ? Icons.star_rounded
                      : (i < avg ? Icons.star_half_rounded : Icons.star_outline_rounded),
                  color: Colors.amber,
                  size: 20,
                )),
              ),
              const SizedBox(height: 6),
              Text(
                '$total review${total != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          // Right: bar breakdown
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = starCounts[i];
                final fraction = total > 0 ? count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 11),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 6,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 20,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Star filter chip ──────────────────────────────────────────────────────────

class _StarChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _StarChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppTheme.deepBlue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: activeColor.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }
}

// ─── Review card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final Rating rating;

  const _ReviewCard({required this.rating});

  Color get _starBgColor {
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Colored top accent strip
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: _starBgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.deepBlue.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          rating.customerName.isNotEmpty
                              ? rating.customerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.deepBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rating.customerName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (i) => Icon(
                              i < rating.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: Colors.amber,
                              size: 16,
                            )),
                          ),
                        ],
                      ),
                    ),
                    // Star badge + date stacked
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _starBgColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${rating.rating}.0',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rating.date,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Service info chip row
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (rating.device.isNotEmpty)
                      _InfoChip(icon: Icons.phone_android_rounded, label: rating.device),
                    if (rating.service.isNotEmpty)
                      _InfoChip(icon: Icons.build_rounded, label: rating.service),
                  ],
                ),
                if (rating.review.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.format_quote_rounded, color: AppTheme.textSecondaryColor, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            rating.review,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimaryColor,
                              height: 1.5,
                            ),
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.deepBlue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.deepBlue),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.deepBlue,
            ),
          ),
        ],
      ),
    );
  }
}
