import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/admin/model/dropoff-model.dart';

class DropoffLocationController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String table = "dropoff_locations";

  /// Create a new dropoff location
  Future<void> create(DropoffLocation location) async {
    await _supabase.from(table).insert(location.toMap());
  }

  /// Get all dropoff locations (latest first)
  Future<List<DropoffLocation>> getAll() async {
    final response = await _supabase
        .from(table)
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => DropoffLocation.fromMap(row))
        .toList();
  }

  /// Get a single dropoff location by ID
  Future<DropoffLocation?> getById(int id) async {
    final response = await _supabase
        .from(table)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return DropoffLocation.fromMap(response);
  }
}
