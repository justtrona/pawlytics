import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/campaign-card-model.dart';

class CampaignsController {
  final SupabaseClient _sb;
  CampaignsController({SupabaseClient? supabase})
    : _sb = supabase ?? Supabase.instance.client;

  // ---------- helpers ----------
  double _d(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0.0;

  int _i(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0);

  DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v);
      } catch (_) {}
    }
    if (v is int) {
      return v > 1000000000000
          ? DateTime.fromMillisecondsSinceEpoch(v)
          : DateTime.fromMillisecondsSinceEpoch(v * 1000);
    }
    return null;
  }

  /// Priority (DUE wins):
  /// 1) deadline passed -> DUE
  /// 2) status text == 'due' -> DUE
  /// 3) is_active == false -> INACTIVE
  /// 4) is_active == true  -> ACTIVE
  /// 5) status text 'active'/'inactive'
  /// 6) fallback -> INACTIVE
  CampaignStatus _statusFrom({
    dynamic statusText,
    dynamic isActive,
    DateTime? deadline,
  }) {
    // 1) Hard override by deadline
    if (deadline != null && deadline.isBefore(DateTime.now())) {
      return CampaignStatus.due;
    }

    // 2) If text already says 'due'
    final s = statusText?.toString().trim().toLowerCase();
    if (s == 'due') return CampaignStatus.due;

    // 3/4) Explicit admin toggle
    if (isActive is bool) {
      if (!isActive) return CampaignStatus.inactive;
      if (isActive) return CampaignStatus.active;
    }

    // 5) Fallback to text if present
    if (s == 'active') return CampaignStatus.active;
    if (s == 'inactive') return CampaignStatus.inactive;

    // 6) Safe default
    return CampaignStatus.inactive;
  }

  List<String> _tagsFrom(dynamic tagsRaw, dynamic categoryRaw) {
    if (tagsRaw is List) {
      final list = tagsRaw
          .map((e) => e == null ? '' : e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    } else if (tagsRaw is String && tagsRaw.trim().isNotEmpty) {
      final list = tagsRaw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    }
    final cat = categoryRaw?.toString().trim();
    return [if (cat != null && cat.isNotEmpty) cat else 'General'];
  }

  // ---------- queries ----------
  Future<List<CampaignCardModel>> fetchCampaigns({bool useView = true}) async {
    final table = useView ? 'campaigns_with_totals' : 'campaigns';

    final rows = await _sb
        .from(table)
        .select()
        .order('created_at', ascending: false);

    final list = (rows as List).cast<Map<String, dynamic>>();

    return list.map((c) {
      final id = _i(c['id']);
      final title = (c['program'] ?? c['title'] ?? 'Untitled Campaign')
          .toString();
      final description = (c['description'] ?? 'No description available')
          .toString();
      final image =
          (c['image_url']?.toString() ?? 'assets/images/donors/rescue.png');

      final goal = _d(c['fundraising_goal']);
      final raised = _d(c['raised_amount']);
      double progress = _d(c['progress_ratio']);
      if (progress == 0 && goal > 0) progress = (raised / goal);
      progress = progress.clamp(0.0, 1.0);

      final tags = _tagsFrom(c['tags'], c['category']);
      final deadline = _date(c['deadline']);

      final status = _statusFrom(
        statusText: c['status'],
        isActive: c['is_active'],
        deadline: deadline,
      );

      return CampaignCardModel(
        id: id,
        title: title,
        description: description,
        tags: tags,
        image: image,
        goal: goal,
        raised: raised,
        progress: progress,
        status: status,
        deadline: deadline, // 👈 pass it through
      );
    }).toList();
  }

  Future<CampaignCardModel?> getCampaign(int id, {bool useView = true}) async {
    final table = useView ? 'campaigns_with_totals' : 'campaigns';
    final row = await _sb.from(table).select().eq('id', id).maybeSingle();
    if (row == null) return null;

    final c = row as Map<String, dynamic>;

    final goal = _d(c['fundraising_goal']);
    final raised = _d(c['raised_amount']);
    double progress = _d(c['progress_ratio']);
    if (progress == 0 && goal > 0) progress = (raised / goal);
    progress = progress.clamp(0.0, 1.0);

    final deadline = _date(c['deadline']);

    final status = _statusFrom(
      statusText: c['status'],
      isActive: c['is_active'],
      deadline: deadline,
    );

    return CampaignCardModel(
      id: _i(c['id']),
      title: (c['program'] ?? c['title'] ?? 'Untitled Campaign').toString(),
      description: (c['description'] ?? 'No description available').toString(),
      tags: _tagsFrom(c['tags'], c['category']),
      image: (c['image_url']?.toString() ?? 'assets/images/donors/rescue.png'),
      goal: goal,
      raised: raised,
      progress: progress,
      status: status,
      deadline: deadline, // 👈 pass it through
    );
  }
}
