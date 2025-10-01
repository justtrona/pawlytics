import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/admin/model/campaigns-model.dart';

class CampaignController {
  final _supabase = Supabase.instance.client;

  Future<List<Campaign>> fetchCampaigns() async {
    final response = await _supabase
        .from('campaigns')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((c) => Campaign.fromMap(c)).toList();
  }

  Future<Campaign?> getCampaign(int id) async {
    final response = await _supabase
        .from('campaigns')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (response == null) return null;
    return Campaign.fromMap(response);
  }

  Future<Campaign> createCampaign(Campaign campaign) async {
    final response = await _supabase
        .from('campaigns')
        .insert(campaign.toMap())
        .select()
        .single();
    return Campaign.fromMap(response);
  }

  Future<Campaign> updateCampaign(int id, Map<String, dynamic> data) async {
    final response = await _supabase
        .from('campaigns')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return Campaign.fromMap(response);
  }

  Future<void> deleteCampaign(int id) async {
    await _supabase.from('campaigns').delete().eq('id', id);
  }

  // 👇👇 ADD THESE 👇👇

  /// Pulls `id, raised_amount, progress_ratio` from the SQL view
  /// `public.campaigns_with_totals`. Returns a list of maps like:
  /// { "id": 27, "raised_amount": 1234.56, "progress_ratio": 0.2468 }
  Future<List<Map<String, dynamic>>> fetchCampaignTotals() async {
    final rows = await _supabase
        .from('campaigns_with_totals')
        .select('id, raised_amount, progress_ratio');

    return (rows as List).cast<Map<String, dynamic>>();
  }

  /// (Optional convenience) Returns a map keyed by campaign id.
  Future<Map<int, Map<String, double>>> fetchCampaignTotalsById() async {
    final list = await fetchCampaignTotals();
    final out = <int, Map<String, double>>{};
    for (final t in list) {
      final id = (t['id'] as num?)?.toInt();
      if (id == null) continue;
      final raised = t['raised_amount'] is num
          ? (t['raised_amount'] as num).toDouble()
          : double.tryParse('${t['raised_amount']}') ?? 0.0;
      final progress = t['progress_ratio'] is num
          ? (t['progress_ratio'] as num).toDouble()
          : double.tryParse('${t['progress_ratio']}') ?? 0.0;
      out[id] = {
        'raised_amount': raised,
        'progress_ratio': progress.clamp(0.0, 1.0),
      };
    }
    return out;
  }
}
