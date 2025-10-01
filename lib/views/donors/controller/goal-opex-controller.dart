// lib/controllers/opex_allocations_controller.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/donors/model/goal-opex-model.dart';

class OpexAllocationsController extends ChangeNotifier {
  final SupabaseClient _sb;

  OpexAllocationsController({SupabaseClient? supabase})
    : _sb = supabase ?? Supabase.instance.client;

  bool _loading = false;
  List<OpexAllocation> _items = [];

  bool get loading => _loading;
  List<OpexAllocation> get items => List.unmodifiable(_items);

  Future<void> loadAllocations() async {
    _loading = true;
    notifyListeners();
    try {
      final rows = await _sb
          .from('operational_expense_allocations')
          .select()
          .order('created_at', ascending: false);

      final list = (rows as List).cast<Map<String, dynamic>>();
      _items = list.map(OpexAllocation.fromMap).toList();
    } catch (e) {
      debugPrint('Failed to load allocations: $e');
      _items = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
