/// Donors-facing model for campaign cards & details.

enum CampaignStatus { active, inactive, due, unknown }

class CampaignCardModel {
  final int id;
  final String title;
  final String description;
  final List<String> tags;
  final String image; // asset path or URL
  final double goal; // fundraising_goal
  final double raised; // from view (raised_amount) or 0 if not available
  final double progress; // 0.0..1.0 (from view or computed)
  final CampaignStatus status;

  // 👇 NEW: expose deadline so the UI can show it
  final DateTime? deadline;

  const CampaignCardModel({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.image,
    required this.goal,
    required this.raised,
    required this.progress,
    required this.status,
    this.deadline,
  });

  // ---------------- parsing helpers ----------------
  static int _i(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static double _d(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '')) ?? 0.0;
    return 0.0;
  }

  static String _s(dynamic v, String fallback) {
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }

  static DateTime? _date(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v);
      } catch (_) {}
    }
    if (v is int) {
      // Heuristic: big numbers are ms, small are seconds.
      return v > 1000000000000
          ? DateTime.fromMillisecondsSinceEpoch(v)
          : DateTime.fromMillisecondsSinceEpoch(v * 1000);
    }
    return null;
  }

  static List<String> _tags(dynamic tags, dynamic category) {
    if (tags is List) {
      final out = tags
          .map((e) => e == null ? '' : e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (out.isNotEmpty) return out;
    }
    if (tags is String && tags.trim().isNotEmpty) {
      final out = tags
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (out.isNotEmpty) return out;
    }
    final c = category?.toString().trim();
    return [if (c != null && c.isNotEmpty) c else 'General'];
  }

  /// Prefer whatever the admin saved in the DB (`status`) and only infer when
  /// it is missing. If `status` is null/empty: mark as DUE when deadline passed,
  /// otherwise INACTIVE as a safe default.
  static CampaignStatus _status(dynamic raw, {DateTime? deadline}) {
    if (raw != null) {
      final s = raw.toString().trim().toLowerCase();
      if (s == 'active') return CampaignStatus.active;
      if (s == 'inactive') return CampaignStatus.inactive;
      if (s == 'due') return CampaignStatus.due;
    }

    // If no status saved, infer from time (optional, but helpful).
    if (deadline != null && deadline.isBefore(DateTime.now())) {
      return CampaignStatus.due;
    }

    return CampaignStatus.inactive; // sensible fallback when missing
  }

  /// Build from a row (works with `campaigns_with_totals` view or base table).
  /// Expected keys: id, program/title, description, category/tags, image_url,
  /// fundraising_goal, raised_amount, progress_ratio, status, deadline
  factory CampaignCardModel.fromMap(Map<String, dynamic> map) {
    final id = _i(map['id']);
    final title = _s(map['program'] ?? map['title'], 'Untitled Campaign');
    final description = _s(map['description'], 'No description available');
    final image = _s(map['image_url'], 'assets/images/donors/rescue.png');

    final goal = _d(map['fundraising_goal']);
    final raised = _d(map['raised_amount']); // 0 if not provided by base table
    double progress = _d(map['progress_ratio']);
    if (progress == 0 && goal > 0) progress = raised / goal;
    progress = progress.clamp(0.0, 1.0);

    final deadline = _date(map['deadline']);
    final status = _status(map['status'], deadline: deadline);

    return CampaignCardModel(
      id: id,
      title: title,
      description: description,
      tags: _tags(map['tags'], map['category']),
      image: image,
      goal: goal,
      raised: raised,
      progress: progress,
      status: status,
      deadline: deadline, // 👈 store it
    );
  }

  // Convenience label for chips
  String get statusLabel {
    switch (status) {
      case CampaignStatus.active:
        return 'ACTIVE';
      case CampaignStatus.inactive:
        return 'INACTIVE';
      case CampaignStatus.due:
        return 'DUE';
      default:
        return '';
    }
  }

  // --------- NEW display helpers for deadline ---------
  bool get isDue => deadline != null && deadline!.isBefore(DateTime.now());

  /// Returns positive days until deadline, 0 if due/past, null if unknown.
  int? get daysUntilDeadline {
    if (deadline == null) return null;
    final diff = deadline!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// e.g., "Oct 15, 2025 (3 days left)" or "Oct 15, 2025 (due)"
  String get deadlineLabel {
    if (deadline == null) return 'No deadline';
    final d = deadline!;
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final base = '${months[d.month]} ${d.day}, ${d.year}';
    if (isDue) return '$base (due)';
    final days = daysUntilDeadline ?? 0;
    return days == 0
        ? '$base (today)'
        : '$base ($days day${days == 1 ? '' : 's'} left)';
  }
}
