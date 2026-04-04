import '../core/config/supabase_config.dart';
import '../models/technician_specialty.dart';
import '../core/utils/app_logger.dart';
class TechnicianSpecialtyService {
  final _supabase = SupabaseConfig.client;
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
      AppLogger.p('TechnicianSpecialtyService: Error loading specialties - $e');
      return [];
    }
  }
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
      AppLogger.p('TechnicianSpecialtyService: Specialty added successfully');
      return TechnicianSpecialty.fromJson(response);
    } catch (e) {
      AppLogger.p('TechnicianSpecialtyService: Error adding specialty - $e');
      return null;
    }
  }
  Future<bool> removeSpecialty(String specialtyId) async {
    try {
      await _supabase
          .from('technician_specialties')
          .delete()
          .eq('id', specialtyId);
      AppLogger.p('TechnicianSpecialtyService: Specialty removed successfully');
      return true;
    } catch (e) {
      AppLogger.p('TechnicianSpecialtyService: Error removing specialty - $e');
      return false;
    }
  }
  Future<List<TechnicianSpecialty>> setSpecialties({
    required String technicianId,
    required List<String> specialtyNames,
  }) async {
    try {
      await _supabase
          .from('technician_specialties')
          .delete()
          .eq('technician_id', technicianId);
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
      AppLogger.p('TechnicianSpecialtyService: Specialties updated successfully');
      return (response as List)
          .map((json) => TechnicianSpecialty.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.p('TechnicianSpecialtyService: Error setting specialties - $e');
      return [];
    }
  }
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
      AppLogger.p('TechnicianSpecialtyService: Error searching technicians - $e');
      return [];
    }
  }
  Stream<List<TechnicianSpecialty>> watchTechnicianSpecialties(String technicianId) {
    return _supabase
        .from('technician_specialties')
        .stream(primaryKey: ['id'])
        .eq('technician_id', technicianId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => TechnicianSpecialty.fromJson(json)).toList());
  }
}