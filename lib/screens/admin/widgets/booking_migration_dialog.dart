/// Admin dialog to manually trigger booking migration
/// Shows migration stats and allows admin to clean up invalid bookings

import 'package:flutter/material.dart';
import '../../../utils/booking_migration_utility.dart';

class BookingMigrationDialog extends StatefulWidget {
  const BookingMigrationDialog({super.key});

  @override
  State<BookingMigrationDialog> createState() => _BookingMigrationDialogState();
}

class _BookingMigrationDialogState extends State<BookingMigrationDialog> {
  bool _isLoading = false;
  MigrationStats? _stats;
  MigrationResult? _result;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await BookingMigrationUtility.getMigrationStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: $e')),
        );
      }
    }
  }

  Future<void> _runMigration() async {
    // Confirm with admin
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Migration'),
        content: Text(
          'This will remove ${_stats?.bookingsWithoutCustomerId ?? 0} bookings without customer IDs.\n\n'
          'This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Migrate Now'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final result = await BookingMigrationUtility.migrateLocalBookings();
      setState(() {
        _result = result;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration complete! Removed ${result.removedBookings} invalid bookings.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Reload stats
      await _loadStats();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Migration failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync, size: 28, color: Colors.blue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Booking Migration',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'This tool removes bookings without customer IDs to fix the appointment privacy issue.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_stats != null) ...[
              _buildStatCard('Total Bookings', _stats!.totalBookings.toString(), Icons.list),
              const SizedBox(height: 8),
              _buildStatCard(
                'Valid Bookings',
                _stats!.bookingsWithCustomerId.toString(),
                Icons.check_circle,
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              _buildStatCard(
                'Invalid Bookings',
                _stats!.bookingsWithoutCustomerId.toString(),
                Icons.error,
                color: Colors.red,
              ),
              
              if (_stats!.needsMigration) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_stats!.bookingsWithoutCustomerId} bookings need to be removed',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              if (_result != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 12),
                          Text(
                            'Migration Completed',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Removed: ${_result!.removedBookings} bookings'),
                      Text('Kept: ${_result!.validBookings} bookings'),
                    ],
                  ),
                ),
              ],
            ],
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : _loadStats,
                  child: const Text('Refresh'),
                ),
                const SizedBox(width: 8),
                if (_stats?.needsMigration == true)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _runMigration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Run Migration'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (color ?? Colors.blue).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
