import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/earnings_provider.dart';
class TechEarningsScreen extends ConsumerWidget {
  const TechEarningsScreen({super.key});
  String _formatTransactionDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} - $hour:$minute $amPm';
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalEarningsAsync = ref.watch(monthEarningsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Earnings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.deepBlue),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Track your income and transaction history',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'This Month',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Total Earnings',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    totalEarningsAsync.when(
                      data: (total) => Text(
                        '₱${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      loading: () => const Text(
                        '₱0.00',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      error: (e, _) => Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, child) {
                                final todayEarningsAsync = ref.watch(todayEarningsProvider);
                                return _SmallMetric(
                                  label: 'Today',
                                  value: todayEarningsAsync.when(
                                    data: (value) => '₱${value.toStringAsFixed(0)}',
                                    loading: () => '…',
                                    error: (_, _) => '—',
                                  ),
                                );
                              },
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, child) {
                                final weekEarningsAsync = ref.watch(weekEarningsProvider);
                                return _SmallMetric(
                                  label: 'This week',
                                  value: weekEarningsAsync.when(
                                    data: (value) => '₱${value.toStringAsFixed(0)}',
                                    loading: () => '…',
                                    error: (_, _) => '—',
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Consumer(
                builder: (context, ref, _) {
                  final filter = ref.watch(earningsFilterProvider);
                  return Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Transaction History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const _EarningsFilterSheet(),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: filter.isActive ? AppTheme.deepBlue : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: filter.isActive ? AppTheme.deepBlue : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: filter.isActive ? Colors.white : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                filter.isActive ? 'Filtered' : 'Filter',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: filter.isActive ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final range = ref.watch(selectedEarningsRangeProvider);
                  return Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'This Week',
                          isSelected: range == EarningsRange.week,
                          onTap: () => ref.read(selectedEarningsRangeProvider.notifier).state = EarningsRange.week,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TabButton(
                          label: 'This Month',
                          isSelected: range == EarningsRange.month,
                          onTap: () => ref.read(selectedEarningsRangeProvider.notifier).state = EarningsRange.month,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TabButton(
                          label: 'All',
                          isSelected: range == EarningsRange.all,
                          onTap: () => ref.read(selectedEarningsRangeProvider.notifier).state = EarningsRange.all,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Consumer(
                builder: (context, ref, child) {
                  final transactionsAsync = ref.watch(filteredTransactionsProvider);
                  return transactionsAsync.when(
                    data: (transactions) {
                      if (transactions.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No transactions yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Complete jobs to see your earnings here',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: transactions.map((booking) {
                          final txDate = booking.completedAt ?? booking.scheduledDate ?? booking.createdAt;
                          final dateStr = _formatTransactionDate(txDate);
                          final jobId = booking.id;
                          final amountValue = booking.finalCost ?? booking.estimatedCost ?? 0.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _TransactionItem(
                              bookingId: booking.id,
                              customerId: booking.customerId,
                              service: booking.serviceName,
                              jobId: '#$jobId',
                              date: dateStr,
                              isEmergency: booking.isEmergency,
                              amount: '+₱${amountValue.toStringAsFixed(2)}',
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (_, _) => Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Could not load transactions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _SmallMetric extends StatelessWidget {
  final String label;
  final String value;
  const _SmallMetric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.deepBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppTheme.deepBlue : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
class _TransactionItem extends ConsumerWidget {
  final String bookingId;
  final String customerId;
  final String service;
  final String jobId;
  final String date;
  final bool isEmergency;
  final String amount;
  const _TransactionItem({
    required this.bookingId,
    required this.customerId,
    required this.service,
    required this.jobId,
    required this.date,
    required this.isEmergency,
    required this.amount,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(userByIdProvider(customerId));
    final customerName = customerAsync.valueOrNull?.fullName ?? '…';
    return GestureDetector(
      onTap: bookingId.isEmpty ? null : () => context.push('/booking/$bookingId'),
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        customerName,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'completed',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isEmergency
                            ? Colors.red.withValues(alpha: 0.12)
                            : Colors.blue.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isEmergency
                              ? Colors.red.withValues(alpha: 0.25)
                              : Colors.blue.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Text(
                        isEmergency ? 'Emergency' : 'Regular',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isEmergency ? Colors.red : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$service • $jobId',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppTheme.successColor,
            ),
          ),
        ],
      ),
    ),
    );
  }
}
class _EarningsFilterSheet extends ConsumerStatefulWidget {
  const _EarningsFilterSheet();
  @override
  ConsumerState<_EarningsFilterSheet> createState() => _EarningsFilterSheetState();
}
class _EarningsFilterSheetState extends ConsumerState<_EarningsFilterSheet> {
  late EarningsFilter _local;
  final _minController = TextEditingController();
  final _maxController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _local = ref.read(earningsFilterProvider);
    if (_local.minAmount != null) _minController.text = _local.minAmount!.toStringAsFixed(0);
    if (_local.maxAmount != null) _maxController.text = _local.maxAmount!.toStringAsFixed(0);
  }
  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }
  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom ? (_local.fromDate ?? DateTime.now()) : (_local.toDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _local = isFrom
          ? _local.copyWith(fromDate: picked)
          : _local.copyWith(toDate: picked);
    });
  }
  void _apply() {
    final min = double.tryParse(_minController.text.trim());
    final max = double.tryParse(_maxController.text.trim());
    ref.read(earningsFilterProvider.notifier).state = _local.copyWith(
      minAmount: min,
      maxAmount: max,
      clearMin: min == null,
      clearMax: max == null,
    );
    Navigator.pop(context);
  }
  void _reset() {
    ref.read(earningsFilterProvider.notifier).state = const EarningsFilter();
    Navigator.pop(context);
  }
  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MMM d, yyyy');
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text('Filter Transactions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                ),
                TextButton(onPressed: _reset, child: const Text('Reset all')),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Date Range', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DatePickerTile(
                    label: 'From',
                    value: _local.fromDate != null ? df.format(_local.fromDate!) : null,
                    onTap: () => _pickDate(true),
                    onClear: _local.fromDate != null
                        ? () => setState(() => _local = _local.copyWith(clearFrom: true))
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DatePickerTile(
                    label: 'To',
                    value: _local.toDate != null ? df.format(_local.toDate!) : null,
                    onTap: () => _pickDate(false),
                    onClear: _local.toDate != null
                        ? () => setState(() => _local = _local.copyWith(clearTo: true))
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Amount Range (₱)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Min',
                      prefixText: '₱',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max',
                      prefixText: '₱',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Job Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 10),
            Row(
              children: [
                _ChipOption(
                  label: 'All',
                  selected: _local.emergencyOnly == null,
                  onTap: () => setState(() => _local = _local.copyWith(clearEmergency: true)),
                ),
                const SizedBox(width: 8),
                _ChipOption(
                  label: 'Regular',
                  selected: _local.emergencyOnly == false,
                  onTap: () => setState(() => _local = _local.copyWith(emergencyOnly: false)),
                ),
                const SizedBox(width: 8),
                _ChipOption(
                  label: 'Emergency',
                  selected: _local.emergencyOnly == true,
                  color: Colors.red,
                  onTap: () => setState(() => _local = _local.copyWith(emergencyOnly: true)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Sort By', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ChipOption(
                  label: 'Newest',
                  selected: _local.sort == EarningsSortOrder.newest,
                  onTap: () => setState(() => _local = _local.copyWith(sort: EarningsSortOrder.newest)),
                ),
                _ChipOption(
                  label: 'Oldest',
                  selected: _local.sort == EarningsSortOrder.oldest,
                  onTap: () => setState(() => _local = _local.copyWith(sort: EarningsSortOrder.oldest)),
                ),
                _ChipOption(
                  label: 'Highest Amount',
                  selected: _local.sort == EarningsSortOrder.highest,
                  onTap: () => setState(() => _local = _local.copyWith(sort: EarningsSortOrder.highest)),
                ),
                _ChipOption(
                  label: 'Lowest Amount',
                  selected: _local.sort == EarningsSortOrder.lowest,
                  onTap: () => setState(() => _local = _local.copyWith(sort: EarningsSortOrder.lowest)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Apply Filters', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _DatePickerTile extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const _DatePickerTile({required this.label, required this.value, required this.onTap, this.onClear});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: value != null ? AppTheme.deepBlue : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          color: value != null ? AppTheme.deepBlue.withValues(alpha: 0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: value != null ? AppTheme.deepBlue : Colors.grey.shade500),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: value != null ? AppTheme.deepBlue : Colors.grey.shade500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 14, color: AppTheme.deepBlue),
              ),
          ],
        ),
      ),
    );
  }
}
class _ChipOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  const _ChipOption({required this.label, required this.selected, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.deepBlue;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}