import '../core/config/supabase_config.dart';
import '../core/utils/booking_notes_parser.dart';

class AdminReportsData {
  final int totalBookings;
  final int dayBookings;
  final int weekBookings;
  final int monthBookings;
  final double totalRevenue;
  final double dayRevenue;
  final double weekRevenue;
  final double monthRevenue;
  final int totalCustomers;
  final int dayCustomers;
  final int weekCustomers;
  final int monthCustomers;
  final int totalTechnicians;
  final int activeTechnicians;
  final int pendingBookings;
  final int completedBookings;
  final int dayCompletedBookings;
  final int weekCompletedBookings;
  final int monthCompletedBookings;
  final int cancelledBookings;
  final List<DeviceBreakdownItem> deviceBreakdown;
  final List<AreaBreakdownItem> popularAreas;
  final List<TechPerformanceItem> teamPerformance;

  const AdminReportsData({
    required this.totalBookings,
    required this.dayBookings,
    required this.weekBookings,
    required this.monthBookings,
    required this.totalRevenue,
    required this.dayRevenue,
    required this.weekRevenue,
    required this.monthRevenue,
    required this.totalCustomers,
    required this.dayCustomers,
    required this.weekCustomers,
    required this.monthCustomers,
    required this.totalTechnicians,
    required this.activeTechnicians,
    required this.pendingBookings,
    required this.completedBookings,
    required this.dayCompletedBookings,
    required this.weekCompletedBookings,
    required this.monthCompletedBookings,
    required this.cancelledBookings,
    required this.deviceBreakdown,
    required this.popularAreas,
    required this.teamPerformance,
  });
}

class DeviceBreakdownItem {
  final String deviceName;
  final int count;
  final double revenue;
  final double percentage;
  /// Raw model names that belong to this category, with their booking counts.
  final Map<String, int> models;

  const DeviceBreakdownItem({
    required this.deviceName,
    required this.count,
    required this.revenue,
    required this.percentage,
    this.models = const {},
  });
}

class AreaBreakdownItem {
  final String areaName;
  final int count;
  final double revenue;

  const AreaBreakdownItem({
    required this.areaName,
    required this.count,
    required this.revenue,
  });
}

class TechPerformanceItem {
  final String technicianId;
  final String name;
  final String? profileImageUrl;
  final int completedJobs;
  final double revenue;
  final double? averageRating;

  const TechPerformanceItem({
    required this.technicianId,
    required this.name,
    this.profileImageUrl,
    required this.completedJobs,
    required this.revenue,
    this.averageRating,
  });
}

class AdminReportsService {
  final _client = SupabaseConfig.client;

  Future<AdminReportsData> load() async {
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final weekAgo = now.subtract(const Duration(days: 7)).toUtc();
    final monthStart = DateTime(now.year, now.month, 1).toUtc();
    // ── All bookings (for status breakdown + device + area) ──────────────────
    final allBookingsRaw = await _client
        .from('bookings')
        .select('id, status, final_cost, estimated_cost, customer_address, diagnostic_notes, created_at, completed_at, technician_id');

    final allBookings = allBookingsRaw as List;

    // ── Users counts ──────────────────────────────────────────────────────────
    final customersRaw = await _client.from('users').select('id, created_at').eq('role', 'customer');
    final techniciansRaw = await _client.from('users').select('id, full_name, profile_image_url').eq('role', 'technician');

    final customers = customersRaw as List;
    final technicians = techniciansRaw as List;

    // ── Counts and revenue ────────────────────────────────────────────────────
    int totalBookings = allBookings.length;
    int dayBookings = 0;
    int weekBookings = 0;
    int monthBookings = 0;
    int pendingCount = 0;
    int completedCount = 0;
    int dayCompletedCount = 0;
    int weekCompletedCount = 0;
    int monthCompletedCount = 0;
    int cancelledCount = 0;
    double totalRevenue = 0;
    double dayRevenue = 0;
    double weekRevenue = 0;
    double monthRevenue = 0;

    // Track new customers by day/week/month
    int dayCustomers = 0;
    int weekCustomers = 0;
    int monthCustomers = 0;
    for (final c in customers) {
      final created = DateTime.tryParse(c['created_at'] as String? ?? '');
      if (created != null) {
        if (!created.isBefore(dayStart)) dayCustomers++;
        if (created.isAfter(weekAgo)) weekCustomers++;
        if (created.isAfter(monthStart)) monthCustomers++;
      }
    }

    // Device tally: category -> {count, revenue, models}
    final Map<String, int> deviceCount = {};
    final Map<String, double> deviceRevenue = {};
    final Map<String, Map<String, int>> deviceModels = {}; // category -> {rawModel -> count}

    // Area tally: normalised area label -> {count, revenue}
    final Map<String, int> areaCount = {};
    final Map<String, double> areaRevenue = {};

    // Technician revenue tally
    final Map<String, double> techRevenue = {};
    final Map<String, int> techJobs = {};

    for (final b in allBookings) {
      final status = (b['status'] as String? ?? '').toLowerCase();
      final amount = ((b['final_cost'] ?? b['estimated_cost'] ?? 0) as num).toDouble();
      final createdAt = DateTime.tryParse(b['created_at'] as String? ?? '') ?? now;
      final completedAtRaw = b['completed_at'] as String?;
      final eventDate = completedAtRaw != null ? DateTime.parse(completedAtRaw) : createdAt;
      final techId = b['technician_id'] as String?;

      // Status
      if (status == 'pending' || status == 'confirmed' || status == 'accepted' || status == 'in_progress') {
        pendingCount++;
      } else if (status == 'completed') {
        completedCount++;
        if (!eventDate.isBefore(dayStart)) dayCompletedCount++;
        if (eventDate.isAfter(weekAgo)) weekCompletedCount++;
        if (eventDate.isAfter(monthStart)) monthCompletedCount++;
        totalRevenue += amount;
        if (!eventDate.isBefore(dayStart)) dayRevenue += amount;
        if (eventDate.isAfter(weekAgo)) weekRevenue += amount;
        if (eventDate.isAfter(monthStart)) monthRevenue += amount;
        // Technician revenue
        if (techId != null) {
          techRevenue[techId] = (techRevenue[techId] ?? 0) + amount;
          techJobs[techId] = (techJobs[techId] ?? 0) + 1;
        }
      } else if (status == 'cancelled') {
        cancelledCount++;
      }

      // Period bookings count (all statuses)
      if (!eventDate.isBefore(dayStart)) dayBookings++;
      if (eventDate.isAfter(weekAgo)) weekBookings++;
      if (eventDate.isAfter(monthStart)) monthBookings++;

      // ── Device breakdown (from diagnostic_notes) ──────────────────────────
      final notes = b['diagnostic_notes'] as String?;
      if (notes != null && notes.isNotEmpty) {
        final parsed = parseBookingNotes(notes);
        final rawDevice = parsed.device ?? '';
        if (rawDevice.isNotEmpty) {
          final deviceKey = _normalizeDevice(rawDevice);
          deviceCount[deviceKey] = (deviceCount[deviceKey] ?? 0) + 1;
          final rawModel = parsed.model ?? '';
          final modelLabel = rawModel.isNotEmpty
              ? rawModel.trim()
              : rawDevice.trim().split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');
          final modelMap = deviceModels.putIfAbsent(deviceKey, () => {});
          modelMap[modelLabel] = (modelMap[modelLabel] ?? 0) + 1;
          if (status == 'completed') {
            deviceRevenue[deviceKey] = (deviceRevenue[deviceKey] ?? 0) + amount;
          }
        }
      }

      // ── Popular areas (from customer_address) ─────────────────────────────
      final address = b['customer_address'] as String?;
      if (address != null && address.isNotEmpty) {
        final areaKey = _normalizeArea(address);
        if (areaKey.isNotEmpty) {
          areaCount[areaKey] = (areaCount[areaKey] ?? 0) + 1;
          if (status == 'completed') {
            areaRevenue[areaKey] = (areaRevenue[areaKey] ?? 0) + amount;
          }
        }
      }
    }

    // ── Ratings per technician ────────────────────────────────────────────────
    final ratingsRaw = await _client
        .from('bookings')
        .select('technician_id, rating')
        .not('rating', 'is', null);

    final Map<String, List<int>> techRatings = {};
    for (final r in ratingsRaw as List) {
      final tId = r['technician_id'] as String?;
      final rating = r['rating'];
      if (tId != null && rating != null) {
        techRatings.putIfAbsent(tId, () => []).add((rating as num).toInt());
      }
    }

    // ── Build device breakdown list ───────────────────────────────────────────
    final totalDeviceBookings = deviceCount.values.fold(0, (a, b) => a + b);
    final deviceList = deviceCount.entries.map((e) {
      final pct = totalDeviceBookings > 0 ? e.value / totalDeviceBookings : 0.0;
      return DeviceBreakdownItem(
        deviceName: e.key,
        count: e.value,
        revenue: deviceRevenue[e.key] ?? 0,
        percentage: pct,
        models: deviceModels[e.key] ?? {},
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    // ── Build popular areas list ──────────────────────────────────────────────
    final areaList = areaCount.entries.map((e) {
      return AreaBreakdownItem(
        areaName: e.key,
        count: e.value,
        revenue: areaRevenue[e.key] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    // ── Build team performance list ───────────────────────────────────────────
    final teamList = technicians.map((t) {
      final tId = t['id'] as String;
      final ratings = techRatings[tId] ?? [];
      final avgRating = ratings.isNotEmpty
          ? ratings.fold(0.0, (s, r) => s + r) / ratings.length
          : null;
      return TechPerformanceItem(
        technicianId: tId,
        name: t['full_name'] as String? ?? 'Unknown',
        profileImageUrl: t['profile_image_url'] as String?,
        completedJobs: techJobs[tId] ?? 0,
        revenue: techRevenue[tId] ?? 0,
        averageRating: avgRating,
      );
    }).toList()
      ..sort((a, b) => b.completedJobs.compareTo(a.completedJobs));

    return AdminReportsData(
      totalBookings: totalBookings,
      dayBookings: dayBookings,
      weekBookings: weekBookings,
      monthBookings: monthBookings,
      totalRevenue: totalRevenue,
      dayRevenue: dayRevenue,
      weekRevenue: weekRevenue,
      monthRevenue: monthRevenue,
      totalCustomers: customers.length,
      dayCustomers: dayCustomers,
      weekCustomers: weekCustomers,
      monthCustomers: monthCustomers,
      totalTechnicians: technicians.length,
      activeTechnicians: techJobs.values.where((j) => j > 0).length,
      pendingBookings: pendingCount,
      completedBookings: completedCount,
      dayCompletedBookings: dayCompletedCount,
      weekCompletedBookings: weekCompletedCount,
      monthCompletedBookings: monthCompletedCount,
      cancelledBookings: cancelledCount,
      deviceBreakdown: deviceList,
      popularAreas: areaList.take(10).toList(),
      teamPerformance: teamList,
    );
  }

  /// Normalise device string to a display label.
  String _normalizeDevice(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.contains('iphone') || lower.contains('ios') || (lower.contains('mobile') && lower.contains('apple'))) {
      return 'iPhone';
    }
    if (lower.contains('samsung')) return 'Samsung';
    if (lower.contains('macbook') || lower.contains('mac book')) return 'MacBook';
    if (lower.contains('laptop') || lower.contains('notebook')) return 'Laptop';
    if (lower.contains('android') || lower.contains('mobile phone') || lower.contains('smartphone')) return 'Phone';
    if (lower.contains('tablet') || lower.contains('ipad')) return 'Tablet / iPad';
    if (lower.contains('desktop') || lower.contains('pc')) return 'Desktop / PC';
    // Title-case fallback
    return raw.trim().split(' ').map((w) {
      if (w.isEmpty) return '';
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Extract a short area label from a customer address string.
  String _normalizeArea(String address) {
    // Try to extract barangay
    final brgyMatch = RegExp(r'(Brgy\.?\s+[\w\s]+|Barangay\s+[\w\s]+)', caseSensitive: false).firstMatch(address);
    if (brgyMatch != null) return brgyMatch.group(0)!.trim();

    // Split by comma, use the most specific part (first segment)
    final parts = address.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) return parts.first;

    return address.trim();
  }
}
