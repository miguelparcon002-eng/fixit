import '../core/config/supabase_config.dart';
import '../models/admin_technician_list_item.dart';
import '../models/technician_profile_model.dart';

class AdminTechniciansService {
  Future<List<AdminTechnicianListItem>> listTechnicians() async {
    final client = SupabaseConfig.client;

    // We don't rely on foreign keys (technician_profiles.user_id references public.users.id)
    // so fetch both and merge.
    final usersRows = await client
        .from('users')
        .select('id, full_name, email, contact_number, city, address, verified, is_suspended, profile_picture, created_at')
        .eq('role', 'technician')
        .order('created_at', ascending: false);

    final profilesRows = await client.from('technician_profiles').select();

    // Completed bookings count per technician (source of truth)
    // Count completed bookings per technician.
    // We count in Dart to be robust against any unexpected casing/values.
    final bookingRows = await client
        .from('bookings')
        .select('technician_id, status');

    final completedCountByTech = <String, int>{};
    for (final row in (bookingRows as List).cast<Map<String, dynamic>>()) {
      final tid = row['technician_id'] as String?;
      if (tid == null) continue;

      final status = (row['status'] as String?) ?? '';
      if (status.toLowerCase() != 'completed') continue;

      completedCountByTech[tid] = (completedCountByTech[tid] ?? 0) + 1;
    }

    final profilesByUserId = <String, TechnicianProfileModel>{};
    for (final row in (profilesRows as List).cast<Map<String, dynamic>>()) {
      final p = TechnicianProfileModel.fromJson(row);
      profilesByUserId[p.userId] = p;
    }

    return (usersRows as List)
        .cast<Map<String, dynamic>>()
        .map((u) {
          final userId = u['id'] as String;
          return AdminTechnicianListItem(
            userId: userId,
            fullName: (u['full_name'] as String?) ?? 'Technician',
            email: (u['email'] as String?) ?? '',
            phone: u['contact_number'] as String?,
            city: u['city'] as String?,
            address: u['address'] as String?,
            verified: (u['verified'] as bool?) ?? false,
            isSuspended: (u['is_suspended'] as bool?) ?? false,
            createdAt: u['created_at'] != null
                ? DateTime.tryParse(u['created_at'] as String)
                : null,
            completedBookings: completedCountByTech[userId] ?? 0,
            profilePicture: u['profile_picture'] as String?,
            profile: profilesByUserId[userId],
          );
        })
        .toList();
  }
}
