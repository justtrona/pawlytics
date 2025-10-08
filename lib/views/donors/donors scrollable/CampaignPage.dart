import 'package:flutter/material.dart';
import 'package:pawlytics/views/donors/controller/campaign-controller.dart';
import 'package:pawlytics/views/donors/donors%20scrollable/connections/CampaignDetailsPage.dart';
import 'package:pawlytics/views/donors/model/campaign-card-model.dart';

class CampaignPage extends StatefulWidget {
  const CampaignPage({super.key});

  @override
  State<CampaignPage> createState() => _CampaignPageState();
}

class _CampaignPageState extends State<CampaignPage> {
  final controller = CampaignsController();
  late Future<List<CampaignCardModel>> _campaigns;

  // highlight palette (soft/warm)
  static const hiBg = Color(0xFFFFF7EC);
  static const hiBorder = Color(0xFFFFB74D);
  static const hiAccent = Color(0xFFFB8C00);

  // Filters / search state
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = 'All'; // All, Active, Due, Inactive
  String _timeFilter = 'All Time'; // Last 30 Days, This Month, This Year

  @override
  void initState() {
    super.initState();
    _campaigns = controller.fetchCampaigns(useView: false);
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ---------- Pin & priority helpers ----------
  bool _isHighCategory(CampaignCardModel m) {
    // use first tag as a "category" hint
    final v = (m.tags.isNotEmpty ? m.tags.first : '').trim().toLowerCase();
    return v == 'urgent' ||
        v == 'emergency care' ||
        v == 'operational' ||
        v == 'operational support';
  }

  int _pinScore(CampaignCardModel m) {
    // you can wire real DB pin fields later; for now category bump only
    final catBoost = _isHighCategory(m) ? 1 : 0;
    return catBoost * 5000 + (m.progress * 1000).toInt();
  }
  // --------------------------------------------

  // ---------- Status computation ----------
  String _computedStatus(CampaignCardModel m) {
    switch (m.status) {
      case CampaignStatus.inactive:
        return 'inactive';
      case CampaignStatus.due:
        return 'due';
      case CampaignStatus.active:
        return 'active';
      default:
        break;
    }
    // Fallback: infer from deadline if status unknown
    final d = m.deadline;
    if (d != null && d.isBefore(DateTime.now())) return 'due';
    return 'active';
  }
  // -----------------------------------------

  // ---------- Filters ----------
  bool _matchesStatus(CampaignCardModel m) {
    if (_statusFilter == 'All') return true;
    final st = _computedStatus(m);
    return st == _statusFilter.toLowerCase();
  }

  bool _matchesTime(CampaignCardModel m) {
    if (_timeFilter == 'All Time') return true;

    // IMPORTANT: use createdAt if present, else fallback to deadline
    final DateTime? basis = m.createdAt ?? m.deadline;
    if (basis == null) return true; // don't exclude if we don't know

    final now = DateTime.now();
    switch (_timeFilter) {
      case 'Last 30 Days':
        return basis.isAfter(now.subtract(const Duration(days: 30)));
      case 'This Month':
        final first = DateTime(now.year, now.month, 1);
        return basis.isAfter(first);
      case 'This Year':
        final first = DateTime(now.year, 1, 1);
        return basis.isAfter(first);
      default:
        return true;
    }
  }

  bool _matchesSearch(CampaignCardModel m) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return true;

    // status words act as filters
    const statusWords = {'active', 'due', 'inactive'};
    if (statusWords.contains(q)) {
      return _computedStatus(m) == q;
    }

    final hay = <String>[
      m.title,
      m.description,
      ...m.tags,
    ].join(' ').toLowerCase();

    return hay.contains(q);
  }
  // -----------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "Campaign",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2C47),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filters & search (functional)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(padding: const EdgeInsets.all(4))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Status filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade300,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        dropdownColor: Colors.white,
                        items: const ['All', 'Active', 'Due', 'Inactive']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _statusFilter = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Time filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _timeFilter,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade300,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        dropdownColor: Colors.white,
                        items:
                            const [
                                  'All Time',
                                  'Last 30 Days',
                                  'This Month',
                                  'This Year',
                                ]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _timeFilter = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: "Search Campaign (try: active, due, inactive…)",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade300,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 0),

          // Campaign list
          Expanded(
            child: FutureBuilder<List<CampaignCardModel>>(
              future: _campaigns,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final List<CampaignCardModel> data =
                    snapshot.data ?? const <CampaignCardModel>[];

                if (data.isEmpty) {
                  return const Center(child: Text("No campaigns found"));
                }

                // 1) Filter
                final filtered = data
                    .where(
                      (c) =>
                          _matchesStatus(c) &&
                          _matchesTime(c) &&
                          _matchesSearch(c),
                    )
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text("No results match filters"));
                }

                // 2) Sort: pinned first, then by progress desc
                filtered.sort((a, b) {
                  final ps = _pinScore(b).compareTo(_pinScore(a));
                  if (ps != 0) return ps;
                  return b.progress.compareTo(a.progress);
                });

                // 3) Render
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    final isPinned = _pinScore(c) > 0;

                    return CampaignCard(
                      model: c,
                      pinned: isPinned,
                      highlight: isPinned,
                      onDonate: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CampaignDetailsPage(
                              campaignId: c.id,
                              title: c.title,
                              image: c.image,
                              raised: "₱${c.raised.toStringAsFixed(2)}",
                              goal: "₱${c.goal.toStringAsFixed(2)}",
                              progress: c.progress,
                              description: c.description,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CampaignCard extends StatelessWidget {
  final CampaignCardModel model;
  final VoidCallback onDonate;
  final bool pinned; // shows pin icon
  final bool highlight; // special design

  const CampaignCard({
    super.key,
    required this.model,
    required this.onDonate,
    this.pinned = false,
    this.highlight = false,
  });

  // ---------- Status helpers ----------
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

  Color _statusBorder(dynamic status) {
    switch (_statusKey(status)) {
      case 'active':
        return const Color(0xFF23344E);
      case 'due':
        return const Color(0xFFB45309); // amber
      case 'inactive':
        return Colors.blueGrey.shade300;
      default:
        return Colors.blueGrey.shade300;
    }
  }

  Color _statusText(dynamic status) {
    switch (_statusKey(status)) {
      case 'active':
        return const Color(0xFF23344E);
      case 'due':
        return const Color(0xFF92400E);
      case 'inactive':
        return Colors.blueGrey.shade600;
      default:
        return Colors.blueGrey.shade600;
    }
  }
  // ------------------------------------

  // ---------- Deadline helpers ----------
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

  String _deadlineSuffix(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(d.year, d.month, d.day);
    final diff = dueDate.difference(today).inDays;

    if (diff < 0) return '(overdue)';
    if (diff == 0) return '(today)';
    if (diff == 1) return '(1 day left)';
    return '($diff days left)';
  }
  // -------------------------------------

  @override
  Widget build(BuildContext context) {
    final status = model.status;

    final Color cardBg = highlight
        ? _CampaignPageState.hiBg
        : const Color(0xFFC3D8E7);
    final BoxBorder cardBorder = highlight
        ? Border.all(color: _CampaignPageState.hiBorder, width: 1.5)
        : Border.all(color: const Color.fromARGB(255, 20, 11, 11), width: 1);

    final Color accent = highlight
        ? _CampaignPageState.hiAccent
        : const Color(0xFF23344E);

    final DateTime? deadline = model.deadline;
    final bool isOverdue =
        deadline != null && deadline.isBefore(DateTime.now());

    return Card(
      color: cardBg,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + chips
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: cardBorder,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: model.image.startsWith('http')
                        ? Image.network(
                            model.image,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            model.image,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),

                // High priority chip OR status chip (top-right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: highlight
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _CampaignPageState.hiAccent.withOpacity(.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _CampaignPageState.hiAccent.withOpacity(
                                .35,
                              ),
                              width: 1.2,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                size: 14,
                                color: _CampaignPageState.hiAccent,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'HIGH PRIORITY',
                                style: TextStyle(
                                  color: _CampaignPageState.hiAccent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: .2,
                                ),
                              ),
                            ],
                          ),
                        )
                      : (status != null && _statusKey(status).isNotEmpty)
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _statusBorder(status),
                              width: 1.2,
                            ),
                          ),
                          child: Text(
                            _statusLabel(status),
                            style: TextStyle(
                              color: _statusText(status),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              letterSpacing: .2,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Pin icon (top-left) when highlighted
                if (pinned)
                  const Positioned(
                    top: 8,
                    left: 8,
                    child: Icon(Icons.push_pin, size: 18, color: Colors.orange),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Title
            Row(
              children: [
                Expanded(
                  child: Text(
                    model.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Tags
            Wrap(
              spacing: 6,
              children: model.tags
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      backgroundColor: highlight
                          ? Colors.white
                          : const Color(0xFFDAD7D7),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 6),

            // Progress
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: model.progress,
                minHeight: 8,
                color: accent,
                backgroundColor: Colors.grey.shade300,
              ),
            ),

            const SizedBox(height: 6),

            // Money
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Raised: ₱${model.raised.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Goal: ₱${model.goal.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF02050A),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Deadline (visible to donors)
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 18,
                  color: isOverdue ? const Color(0xFFB45309) : Colors.blueGrey,
                ),
                const SizedBox(width: 6),
                Text(
                  deadline != null
                      ? 'Deadline: ${_fmtDate(deadline)} ${_deadlineSuffix(deadline)}'
                      : 'Deadline: —',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isOverdue
                        ? const Color(0xFF92400E)
                        : const Color(0xFF23344E),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Description
            Text(
              model.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF23344E)),
            ),

            const SizedBox(height: 12),

            // CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDonate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Donate",
                  style: TextStyle(color: Color.fromARGB(255, 215, 217, 220)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
