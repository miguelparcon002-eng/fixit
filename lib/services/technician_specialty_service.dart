import '../core/config/supabase_config.dart';
import '../models/technician_specialty.dart';

class TechnicianSpecialtyService {
  final _supabase = SupabaseConfig.client;

  /// Get all specialties for a technician
  Future<List<TechnicianSpecialty>> getTechnicianSpecialties(String technicianId) async {
    try {
      final response = await _supabase
          .from('technician_specialties')
          .select()
          .eq('technician_id', technicianId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TechnicianSpecialty.fromJson(json))
          .toList();
    } catch (e) {
      print('TechnicianSpecialtyService: Error loading specialties - $e');
      return [];
    }
  }

  /// Add a specialty to a technician
  Future<TechnicianSpecialty?> addSpecialty({
    required String technicianId,
    required String specialtyName,
  }) async {
    try {
      final response = await _supabase
          .from('technician_specialties')
          .insert({
            'technician_id': technicianId,
            'specialty_name': specialtyName,
          })
          .select()
          .single();

      print('TechnicianSpecialtyService: Specialty added successfully');
      return TechnicianSpecialty.fromJson(response);
    } catch (e) {
      print('TechnicianSpecialtyService: Error adding specialty - $e');
      return null;
    }
  }

  /// Remove a specialty from a technician
  Future<bool> removeSpecialty(String specialtyId) async {
    try {
      await _supabase
          .from('technician_specialties')
          .delete()
          .eq('id', specialtyId);

      print('TechnicianSpecialtyService: Specialty removed successfully');
      return true;
    } catch (e) {
      print('TechnicianSpecialtyService: Error removing specialty - $e');
      return false;
    }
  }

  /// Set multiple specialties for a technician (replaces existing)
  Future<List<TechnicianSpecialty>> setSpecialties({
    required String technicianId,
    required List<String> specialtyNames,
  }) async {
    try {
      // Delete existing specialties
      await _supabase
          .from('technician_specialties')
          .delete()
          .eq('technician_id', technicianId);

      // Insert new specialties
      if (specialtyNames.isEmpty) return [];

      final inserts = specialtyNames
          .map((name) => {
                'technician_id': technicianId,
                'specialty_name': name,
              })
          .toList();

      final response = await _supabase
          .from('technician_specialties')
          .insert(inserts)
          .select();

      print('TechnicianSpecialtyService: Specialties updated successfully');
      return (response as List)
          .map((json) => TechnicianSpecialty.fromJson(json))
          .toList();
    } catch (e) {
      print('TechnicianSpecialtyService: Error setting specialties - $e');
      return [];
    }
  }

  /// Search technicians by specialty
  Future<List<String>> searchTechniciansBySpecialty(String specialtyName) async {
    try {
      final response = await _supabase
          .from('technician_specialties')
          .select('technician_id')
          .eq('specialty_name', specialtyName);

      return (response as List)
          .map((json) => json['technician_id'] as String)
          .toList();
    } catch (e) {
      print('TechnicianSpecialtyService: Error searching technicians - $e');
      return [];
    }
  }

  /// Stream specialties for real-time updates
  Stream<List<TechnicianSpecialty>> watchTechnicianSpecialties(String technicianId) {
    return _supabase
        .from('technician_specialties')
        .stream(primaryKey: ['id'])
        .eq('technician_id', technicianId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => TechnicianSpecialty.fromJson(json)).toList());
  }
}
