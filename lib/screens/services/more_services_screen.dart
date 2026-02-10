import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/service_model.dart';
import '../../providers/service_provider.dart';
import 'package:go_router/go_router.dart';

class MoreServicesScreen extends ConsumerStatefulWidget {
  const MoreServicesScreen({super.key});

  @override
  ConsumerState<MoreServicesScreen> createState() => _MoreServicesScreenState();
}

class _MoreServicesScreenState extends ConsumerState<MoreServicesScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory; // null = All

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();

    final params = SearchServicesParams(
      query: query.isEmpty ? null : query,
      category: _selectedCategory,
    );

    final servicesAsync = ref.watch(searchServicesProvider(params));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('All Services'),
        backgroundColor: AppTheme.deepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _Header(
            searchController: _searchController,
            selectedCategory: _selectedCategory,
            onCategorySelected: (value) => setState(() => _selectedCategory = value),
            onQueryChanged: () => setState(() {}),
          ),
          Expanded(
            child: servicesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepBlue),
                ),
              ),
              error: (e, unused) => _ErrorState(
                title: 'Could not load services',
                message: e.toString(),
                onRetry: () => ref.invalidate(searchServicesProvider(params)),
              ),
              data: (services) {
                if (services.isEmpty) {
                  return _EmptyState(
                    title: 'No services found',
                    message: (query.isNotEmpty || _selectedCategory != null)
                        ? 'Try a different search or category.'
                        : 'No active services are available right now.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(searchServicesProvider(params));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: services.length,
                    separatorBuilder: (unused, unused2) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _ServiceListCard(
                        service: services[index],
                        onTap: () => _openBookingFlow(context),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openBookingFlow(BuildContext context) {
    context.push('/create-booking');
  }
}

class _Header extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final VoidCallback onQueryChanged;

  const _Header({
    required this.searchController,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onQueryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Find the right repair',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: searchController,
            onChanged: (unused) => onQueryChanged(),
            decoration: InputDecoration(
              hintText: 'Search services (screen, battery, water...)',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        onQueryChanged();
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: 'All',
                  isSelected: selectedCategory == null,
                  onTap: () => onCategorySelected(null),
                ),
                const SizedBox(width: 8),
                for (final cat in AppConstants.serviceCategories) ...[
                  _CategoryChip(
                    label: cat,
                    isSelected: selectedCategory == cat,
                    onTap: () => onCategorySelected(cat),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.deepBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.deepBlue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
          ),
        ),
      ),
    );
  }
}

class _ServiceListCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const _ServiceListCard({
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priceText = _formatPrice(service);
    final durationText = service.estimatedDuration > 0
        ? '${service.estimatedDuration} min'
        : 'Duration varies';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.deepBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.build_circle, color: AppTheme.deepBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.serviceName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Badge(
                        text: service.category,
                        color: const Color(0xFF17A2B8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _MiniInfo(icon: Icons.payments_outlined, text: priceText),
                      _MiniInfo(icon: Icons.schedule, text: durationText),
                      _MiniInfo(
                        icon: Icons.inventory_2_outlined,
                        text: _partsAvailabilityLabel(service.partsAvailability),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  String _formatPrice(ServiceModel service) {
    // Prefer base price when available; otherwise show range; otherwise fallback.
    if (service.basePrice != null) {
      return '₱${service.basePrice!.toStringAsFixed(0)}';
    }

    if (service.priceRangeMin != null || service.priceRangeMax != null) {
      final min = (service.priceRangeMin ?? 0).toStringAsFixed(0);
      final max = (service.priceRangeMax ?? 0).toStringAsFixed(0);
      return '₱$min - ₱$max';
    }

    return 'Price varies';
  }

  String _partsAvailabilityLabel(String value) {
    return switch (value) {
      'in_stock' => 'Parts in stock',
      'order_required' => 'Order required',
      'out_of_stock' => 'Out of stock',
      _ => value,
    };
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniInfo({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.deepBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
