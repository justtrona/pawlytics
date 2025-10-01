// lib/data/opex_repo.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class OpexRepo {
  final SupabaseClient _sb;
  OpexRepo({SupabaseClient? sb}) : _sb = sb ?? Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchAllocations() =>
      _sb.from('opex_allocations_with_totals').select().order('created_at');

  Future<Map<String, dynamic>> addAllocation({
    required String category,
    required double amount,
  }) async => await _sb
      .from('operational_expense_allocations')
      .insert({'category': category, 'amount': amount})
      .select()
      .single();

  Future<void> removeAllocation(int id) =>
      _sb.from('operational_expense_allocations').delete().eq('id', id);

  Future<void> insertOperationalDonation({
    required double amount,
    required String donationType,
    String? donorName,
  }) => _sb.from('donations').insert({
    'amount': amount,
    'donation_type': donationType,
    'donor_name': donorName,
    'is_operational': true, // DB trigger will auto-assign allocation
  });
}
