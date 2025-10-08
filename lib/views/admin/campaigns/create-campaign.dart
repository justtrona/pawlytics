// lib/views/admin/campaigns/create-campaign.dart (UI-only refresh + details nav)
import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/controllers/campaigns-controller.dart';
import 'package:pawlytics/views/admin/model/campaigns-model.dart';
import 'package:pawlytics/route/route.dart' as route;
import 'package:supabase_flutter/supabase_flutter.dart';

// ⬇️ Add this import so we can open the campaign details page
import 'package:pawlytics/views/admin/campaigns/campaign_details.dart';

class CreateCampaign extends StatefulWidget {
  const CreateCampaign({super.key});
  @override
  State<CreateCampaign> createState() => _CreateCampaignState();
}

class _CreateCampaignState extends State<CreateCampaign> {
  // --- Palette (unchanged semantics, refined tones) ---
  static const brand = Color(0xFF27374D);
  static const brandDark = Color(0xFF1B2A3A);
  static const accent = Color(0xFF4F8EDC);
  static const softGrey = Color(0xFFF2F5F8);
  static const tileGrey = Color(0xFFF8FAFD);
  static const textMuted = Color(0xFF6A7886);
  static const line = Color(0xFFE6EDF4);
  static const success = Color(0xFF10B981);
  static const warn = Color(0xFFF59E0B);
  static const danger = Color(0xFFE74C3C);

  // Highlight scheme
  static const hiBg = Color(0xFFFFF7EC); // soft warm
  static const hiBorder = Color(0xFFFFB74D); // orange border
  static const hiAccent = Color(0xFFFB8C00); // chip/progress

  final CampaignController _controller = CampaignController();

  // Base table rows
  List<Campaign> _campaigns = [];
  bool _loading = true;

  // Totals (from view) keyed by campaign id
  final Map<int, double> _raisedById = {};
  final Map<int, double> _progressById = {};

  String _statusFilter = 'All Statuses';
  String _sortBy = 'Date Created';

  RealtimeChannel? _campaignsChannel;

  @override
  void initState() {
    super.initState();
    _fetchCampaigns();
    _subscribeToChanges();
  }

  @override
  void dispose() {
    _campaignsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchCampaigns() async {
    try {
      final campaigns = await _controller.fetchCampaigns();
      final totals = await _controller.fetchCampaignTotals();

      _raisedById.clear();
      _progressById.clear();
      for (final t in totals) {
        final id = (t['id'] as num?)?.toInt();
        if (id == null) continue;

        final raised = t['raised_amount'] is num
            ? (t['raised_amount'] as num).toDouble()
            : double.tryParse('${t['raised_amount']}') ?? 0.0;

        final progress = t['progress_ratio'] is num
            ? (t['progress_ratio'] as num).toDouble()
            : double.tryParse('${t['progress_ratio']}') ?? 0.0;

        _raisedById[id] = raised;
        _progressById[id] = progress.clamp(0.0, 1.0);
      }

      if (!mounted) return;
      setState(() {
        _campaigns = campaigns;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching campaigns: $e")));
    }
  }

  void _subscribeToChanges() {
    final supabase = Supabase.instance.client;

    _campaignsChannel = supabase
        .channel('admin-campaigns-and-donations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'campaigns',
          callback: (_) => _fetchCampaigns(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'donations',
          callback: (_) => _fetchCampaigns(),
        )
        .subscribe();
  }

  // ---- Pinning & high-need helpers ----
  bool _isHighCategory(Campaign c) {
    final v = c.category.trim().toLowerCase();
    return v == 'urgent' ||
        v == 'emergency care' ||
        v == 'operational' ||
        v == 'operational support';
  }

  /// Reads optional DB pin fields if present on the model / row.
  /// Higher value = more pinned.
  int _pinScore(Campaign c) {
    // tolerant dynamic reads so your model doesn't need to declare them
    bool isFeatured = false;
    int priority = 0;
    DateTime? pinnedAt;

    try {
      final dyn = c as dynamic;
      final f = dyn.is_featured ?? dyn.isFeatured;
      if (f is bool) isFeatured = f;
      final p = dyn.priority;
      if (p is num) priority = p.toInt();
      final pa = dyn.pinned_at ?? dyn.pinnedAt;
      if (pa is DateTime) {
        pinnedAt = pa;
      } else if (pa is String) {
        pinnedAt = DateTime.tryParse(pa);
      }
    } catch (_) {}

    final catBoost = _isHighCategory(c) ? 1 : 0;
    final pinBoost = isFeatured ? 2 : 0;
    final timeBoost = pinnedAt == null ? 0 : 1; // any pinned_at bumps it

    // weight scheme: (featured 2x) + (category 1x) + (has pinned_at) + (priority)
    return (pinBoost * 10000) +
        (catBoost * 5000) +
        (timeBoost * 1000) +
        priority;
  }

  int _cmpBySelected(Campaign a, Campaign b) {
    switch (_sortBy) {
      case 'Deadline':
        return a.deadline.compareTo(b.deadline);
      case 'Goal Amount':
        return b.fundraisingGoal.compareTo(a.fundraisingGoal);
      case 'Progress':
        double p(Campaign c) => _progressById[c.id] ?? _safeProgressFor(c);
        return p(b).compareTo(p(a));
      case 'Date Created':
      default:
        return b.createdAt.compareTo(a.createdAt);
    }
  }

  List<Campaign> get _filtered {
    var list = _campaigns.where((c) {
      if (_statusFilter == 'All Statuses') return true;
      if (_statusFilter == 'Active') return c.deadline.isAfter(DateTime.now());
      if (_statusFilter == 'Ended') return c.deadline.isBefore(DateTime.now());
      return true;
    }).toList();

    // Combined comparator: pin score DESC, then selected sort
    list.sort((a, b) {
      final ps = _pinScore(b).compareTo(_pinScore(a));
      if (ps != 0) return ps;
      return _cmpBySelected(a, b);
    });

    return list;
  }

  // Aggregate stats
  int get _activeCount =>
      _campaigns.where((c) => c.deadline.isAfter(DateTime.now())).length;
  int get _totalCampaigns => _campaigns.length;
  num get _totalGoal =>
      _campaigns.fold<num>(0, (sum, c) => sum + c.fundraisingGoal);
  num get _totalRaised =>
      _campaigns.fold<num>(0, (sum, c) => sum + (_raisedById[c.id] ?? 0));

  // Helpers
  String _fmtMoney(num v) {
    final s = v.toStringAsFixed(0);
    final re = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return 'PHP ${s.replaceAllMapped(re, (m) => ',')}';
  }

  String _fmtDate(DateTime d) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  double _safeProgressFor(Campaign c) {
    final raised = _raisedById[c.id] ?? 0.0;
    final goal = c.fundraisingGoal;
    return goal > 0 ? (raised / goal).clamp(0.0, 1.0) : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGrey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: brandDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Campaigns',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: line),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchCampaigns,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    // --- Top stats row ---
                    Row(
                      children: [
                        Expanded(
                          child: _StatPill(
                            label: 'Total Campaigns',
                            value: '$_totalCampaigns',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatPill(
                            label: 'Active Campaigns',
                            value: '$_activeCount',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatPill(
                            label: 'Total Raised',
                            value: _fmtMoney(_totalRaised),
                            emphasize: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // --- Create Campaign CTA ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: line),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: brand.withOpacity(.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.campaign, color: brand),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Start a new campaign to raise funds',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: brandDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brand,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  route.campaignSettings,
                                );
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // --- Filters row ---
                    Row(
                      children: [
                        Expanded(
                          child: _FilterPill(
                            label: _statusFilter,
                            onTap: () async {
                              final v = await _pickOption(
                                context,
                                title: 'Status',
                                options: const [
                                  'All Statuses',
                                  'Active',
                                  'Ended',
                                ],
                                current: _statusFilter,
                              );
                              if (v != null) setState(() => _statusFilter = v);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FilterPill(
                            label: 'Sort by $_sortBy',
                            onTap: () async {
                              final v = await _pickOption(
                                context,
                                title: 'Sort By',
                                options: const [
                                  'Date Created',
                                  'Deadline',
                                  'Goal Amount',
                                  'Progress',
                                ],
                                current: _sortBy,
                              );
                              if (v != null) setState(() => _sortBy = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // --- Campaign list ---
                    if (_filtered.isEmpty)
                      Container(
                        height: 160,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: line),
                        ),
                        child: const Text(
                          "No campaigns found",
                          style: TextStyle(
                            color: textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      ..._filtered.map((c) {
                        final raised = _raisedById[c.id] ?? 0.0;
                        final progress =
                            _progressById[c.id] ?? _safeProgressFor(c);

                        final isHi = _pinScore(c) > 0; // high-need / pinned

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CampaignTile(
                            data: c,
                            raised: raised,
                            progress: progress,
                            money: _fmtMoney,
                            dateFmt: _fmtDate,
                            onTap: () async {
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CampaignDetails(campaign: c),
                                ),
                              );
                              if (changed == true) {
                                _fetchCampaigns();
                              }
                            },
                            pinned: isHi, // show pin icon
                            highlight: isHi, // 🔥 use special design
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }

  Future<String?> _pickOption(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String current,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ...options.map(
              (o) => ListTile(
                title: Text(
                  o,
                  style: TextStyle(
                    fontWeight: o == current
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: o == current ? brand : Colors.black87,
                  ),
                ),
                trailing: o == current
                    ? const Icon(Icons.check, color: brand)
                    : null,
                onTap: () => Navigator.pop(ctx, o),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/* ===================== WIDGETS (UI only) ===================== */

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _StatPill({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = emphasize ? _CreateCampaignState.brand : Colors.white;
    final fg = emphasize ? Colors.white : _CreateCampaignState.brandDark;
    final sub = emphasize ? Colors.white70 : _CreateCampaignState.textMuted;

    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _CreateCampaignState.line),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: sub,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.tune_rounded, color: _CreateCampaignState.brand),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _CreateCampaignState.brand,
          fontWeight: FontWeight.w800,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _CreateCampaignState.line),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _CampaignTile extends StatelessWidget {
  final Campaign data;
  final double raised; // from view
  final double progress; // 0..1
  final String Function(num) money;
  final String Function(DateTime) dateFmt;
  final VoidCallback? onTap; // open details
  final bool pinned; // show pin badge
  final bool highlight; // 🔥 special design for high-need

  const _CampaignTile({
    required this.data,
    required this.raised,
    required this.progress,
    required this.money,
    required this.dateFmt,
    this.onTap,
    this.pinned = false,
    this.highlight = false,
  });

  // --- status helpers (UI only) ---
  String _statusKey(dynamic status) {
    try {
      final n = (status as dynamic).name;
      if (n is String && n.isNotEmpty) return n.toLowerCase();
    } catch (_) {}
    var s = status?.toString() ?? '';
    final dot = s.lastIndexOf('.');
    if (dot != -1) s = s.substring(dot + 1);
    return s.trim().toLowerCase();
  }

  String _statusLabel(dynamic status) {
    switch (_statusKey(status)) {
      case 'active':
        return 'ACTIVE';
      case 'inactive':
        return 'INACTIVE';
      case 'due':
        return 'DUE';
      default:
        final k = _statusKey(status);
        return k.isEmpty ? '' : k.toUpperCase();
    }
  }

  Color _statusBg(dynamic status) {
    switch (_statusKey(status)) {
      case 'active':
        return _CreateCampaignState.brand.withOpacity(.10);
      case 'due':
        return _CreateCampaignState.warn.withOpacity(.12);
      case 'inactive':
        return Colors.blueGrey.withOpacity(.10);
      default:
        return Colors.blueGrey.withOpacity(.10);
    }
  }

  Color _statusFg(dynamic status) {
    switch (_statusKey(status)) {
      case 'active':
        return _CreateCampaignState.brand;
      case 'due':
        return const Color(0xFF92400E);
      case 'inactive':
        return Colors.blueGrey.shade700;
      default:
        return Colors.blueGrey.shade700;
    }
  }

  IconData _statusIcon(dynamic status) {
    switch (_statusKey(status)) {
      case 'active':
        return Icons.play_circle_fill_rounded;
      case 'due':
        return Icons.schedule_rounded;
      case 'inactive':
        return Icons.pause_circle_filled_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final raisedLabel = '${money(raised)} of ${money(data.fundraisingGoal)}';
    final st =
        (data as dynamic).status ??
        (data.deadline.isBefore(DateTime.now()) ? 'due' : 'active');

    // ✅ Always supply a BoxBorder (Border), not a BorderSide
    final BoxBorder cardBorder = highlight
        ? Border.all(color: _CreateCampaignState.hiBorder, width: 1.5)
        : Border.all(color: _CreateCampaignState.line, width: 1);

    final Color cardColor = highlight
        ? _CreateCampaignState.hiBg
        : Colors.white;

    final List<BoxShadow> shadow = highlight
        ? const [
            BoxShadow(
              color: Color(0x22FB8C00), // orange glow
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ]
        : const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ];

    final Color progressColor = highlight
        ? _CreateCampaignState.hiAccent
        : _CreateCampaignState.brand;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: cardBorder,
          boxShadow: shadow,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail placeholder
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 96,
                        height: 72,
                        color: _CreateCampaignState.softGrey,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.campaign,
                          size: 40,
                          color: highlight
                              ? _CreateCampaignState.hiAccent
                              : _CreateCampaignState.brand,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title + meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data.program,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: highlight
                                        ? _CreateCampaignState.hiAccent
                                        : _CreateCampaignState.brand,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (pinned) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.push_pin,
                                  size: 18,
                                  color: Colors.orange,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${data.category} • Goal: ${money(data.fundraisingGoal)} ${data.currency}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _CreateCampaignState.brandDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status chip OR High priority chip
                    highlight
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _CreateCampaignState.hiAccent.withOpacity(
                                .12,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _CreateCampaignState.hiAccent
                                    .withOpacity(.35),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.local_fire_department_rounded,
                                  size: 14,
                                  color: _CreateCampaignState.hiAccent,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'HIGH PRIORITY',
                                  style: TextStyle(
                                    color: _CreateCampaignState.hiAccent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    letterSpacing: .2,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _statusBg(st),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: _statusFg(st).withOpacity(.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _statusIcon(st),
                                  size: 14,
                                  color: _statusFg(st),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _statusLabel(st),
                                  style: TextStyle(
                                    color: _statusFg(st),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    letterSpacing: .2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),

                // Description
                if (data.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    data.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _CreateCampaignState.textMuted,
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Progress
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: _CreateCampaignState.softGrey,
                        color: progressColor,
                      ),
                      // percent label on top
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: .2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Money + dates
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      raisedLabel,
                      style: TextStyle(
                        color: highlight
                            ? _CreateCampaignState.hiAccent
                            : _CreateCampaignState.brand,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      'Deadline: ${dateFmt(data.deadline)}',
                      style: const TextStyle(
                        color: _CreateCampaignState.textMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Created: ${dateFmt(data.createdAt)} • Updated: ${dateFmt(data.updatedAt)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
