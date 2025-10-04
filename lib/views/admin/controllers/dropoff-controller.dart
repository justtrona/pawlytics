import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/admin/model/dropoff-model.dart';

class DropoffLocationController {
  final SupabaseClient _supabase = Supabase.instance.client;
  final String table = 'dropoff_locations';

  /// Create a new dropoff location
  Future<void> create(DropoffLocation location) async {
    try {
      await _supabase.from(table).insert(location.toMap());
    } on PostgrestException catch (e) {
      throw Exception('Failed to create location: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create location: $e');
    }
  }

  /// Update an existing location (by id in [location])
  Future<void> update(DropoffLocation location) async {
    if (location.id == null) {
      throw Exception('Cannot update: location.id is null.');
    }

    // Build update payload without immutable columns
    final payload = location.toMap()
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');

    try {
      await _supabase
          .from(table)
          .update(payload)
          .eq('id', location.id!); // ← non-null id
    } on PostgrestException catch (e) {
      throw Exception('Failed to update location: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }

  Future<void> deleteById(int id) async {
    try {
      await _supabase.from(table).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete location: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete location: $e');
    }
  }

  /// Delete a location by id
  Future<void> delete(int id) async {
    try {
      await _supabase.from(table).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete location: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete location: $e');
    }
  }

  /// Get all dropoff locations (latest first by created_at if present)
  Future<List<DropoffLocation>> getAll() async {
    try {
      final response = await _supabase
          .from(table)
          .select()
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((row) => DropoffLocation.fromMap(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch locations: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch locations: $e');
    }
  }

  /// Get a single dropoff location by ID
  Future<DropoffLocation?> getById(int id) async {
    try {
      final response = await _supabase
          .from(table)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return DropoffLocation.fromMap(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch location: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch location: $e');
    }
  }

  /// (Optional) Live stream if you want real-time updates in a list
  Stream<List<DropoffLocation>> watchAll() {
    // Requires RLS + realtime enabled for the table.
    return _supabase
        .from(table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map((r) => DropoffLocation.fromMap(r as Map<String, dynamic>))
              .toList(),
        );
  }
}
