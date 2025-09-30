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
}
