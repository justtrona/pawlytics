import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/admin/model/utilities-model.dart';

class UtilityController {
  final _client = Supabase.instance.client;

  // Save a utility record
  Future<void> addUtility(Utility utility) async {
    await _client.from('utilities').insert({
      'type': utility.type,
      'amount': utility.amount,
      'due_date': utility.dueDate.toIso8601String(),
      'status': utility.status,
    });
  }

  // Get all utilities
  Future<List<Utility>> fetchUtilities() async {
    final res = await _client.from('utilities').select();

    return (res as List).map((row) {
      return Utility(
        type: row['type'] as String,
        amount: (row['amount'] as num).toDouble(),
        dueDate: DateTime.parse(row['due_date'] as String),
        status: row['status'] as String,
      );
    }).toList();
  }
}
