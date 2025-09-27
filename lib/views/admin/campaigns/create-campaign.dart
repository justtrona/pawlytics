import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/controllers/campaigns-controller.dart';
import 'package:pawlytics/views/admin/model/campaigns-model.dart';
import 'package:pawlytics/route/route.dart' as route;
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateCampaign extends StatefulWidget {
  const CreateCampaign({super.key});

  @override
  State<CreateCampaign> createState() => _CreateCampaignState();
}

class _CreateCampaignState extends State<CreateCampaign> {
  static const brand = Color(0xFF27374D);
  static const softGrey = Color(0xFFE9EEF3);
  static const tileGrey = Color(0xFFDDE5EC);
  static const textMuted = Color(0xFF6A7886);

  final CampaignController _controller = CampaignController();

  List<Campaign> _campaigns = [];
  bool _loading = true;

  String _statusFilter = 'All Statuses';
  String _sortBy = 'Date Created';

  RealtimeChannel? _campaignsChannel;

  @override
  void initState() {
    super.initState();
    _fetchCampaigns();
    _subscribeToCampaigns();
  }

  @override
  void dispose() {
    _campaignsChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchCampaigns() async {
    try {
      final data = await _controller.fetchCampaigns();
      if (!mounted) return;
      setState(() {
        _campaigns = data;
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

  void _subscribeToCampaigns() {
    final supabase = Supabase.instance.client;

    _campaignsChannel = supabase
        .channel('campaigns-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'campaigns',
          callback: (payload) {
            _fetchCampaigns();
          },
        )
        .subscribe();
  }

  List<Campaign> get _filtered {
    var list = _campaigns.where((c) {
      if (_statusFilter == 'All Statuses') return true;
      if (_statusFilter == 'Active') return c.deadline.isAfter(DateTime.now());
      if (_statusFilter == 'Ended') return c.deadline.isBefore(DateTime.now());
      return true;
    }).toList();

    switch (_sortBy) {
      case 'Date Created':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Deadline':
        list.sort((a, b) => a.deadline.compareTo(b.deadline));
        break;
      case 'Goal Amount':
        list.sort((a, b) => b.fundraisingGoal.compareTo(a.fundraisingGoal));
        break;
    }
    return list;
  }

  int get _activeCount =>
      _campaigns.where((c) => c.deadline.isAfter(DateTime.now())).length;
  int get _totalCampaigns => _campaigns.length;
  num get _totalGoal =>
      _campaigns.fold<num>(0, (sum, c) => sum + c.fundraisingGoal);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: BackButton(
          color: Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Campaigns'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchCampaigns,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // Top stats
                    Row(
                      children: [
                        Expanded(
                          child: _StatPill(
                            label: 'Total Campaigns',
                            value: '$_totalCampaigns',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatPill(
                            label: 'Active Campaigns',
                            value: '$_activeCount',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatPill(
                            label: 'Total Goal Amount',
                            value: _fmtMoney(_totalGoal),
                            emphasize: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Create Campaign
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brand,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, route.campaignSettings);
                        },
                        child: const Text('Create Campaign'),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filters row
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

                    // Campaign list
                    if (_filtered.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text("No campaigns found"),
                        ),
                      )
                    else
                      ..._filtered.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CampaignTile(
                            data: c,
                            money: _fmtMoney,
                            dateFmt: _fmtDate,
                          ),
                        ),
                      ),
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
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...options.map(
              (o) => ListTile(
                title: Text(
                  o,
                  style: TextStyle(
                    fontWeight: o == current
                        ? FontWeight.w700
                        : FontWeight.w500,
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

// ====== WIDGETS ======
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
    final bg = emphasize
        ? _CreateCampaignState.brand
        : _CreateCampaignState.softGrey;
    final fg = emphasize ? Colors.white : _CreateCampaignState.brand;

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: emphasize
                  ? Colors.white70
                  : _CreateCampaignState.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: 16,
              fontWeight: FontWeight.w800,
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
    return Material(
      color: _CreateCampaignState.softGrey,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _CreateCampaignState.brand,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.expand_more_rounded,
                size: 18,
                color: _CreateCampaignState.brand,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampaignTile extends StatelessWidget {
  final Campaign data;
  final String Function(num) money;
  final String Function(DateTime) dateFmt;

  const _CampaignTile({
    required this.data,
    required this.money,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _CreateCampaignState.tileGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Navigate to details
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Program + category + goal
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 96,
                      height: 72,
                      color: Colors.white,
                      child: const Icon(
                        Icons.campaign,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.program,
                          style: const TextStyle(
                            color: _CreateCampaignState.brand,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${data.category} • Goal: ${money(data.fundraisingGoal)} ${data.currency}',
                          style: const TextStyle(
                            color: _CreateCampaignState.brand,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(isActive: data.deadline.isAfter(DateTime.now())),
                ],
              ),

              const SizedBox(height: 10),

              // Description
              if (data.description.isNotEmpty)
                Text(
                  data.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _CreateCampaignState.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Deadline: ${dateFmt(data.deadline)}',
                    style: const TextStyle(
                      color: _CreateCampaignState.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  if (data.notifyAt75)
                    const Chip(
                      label: Text("Notify @ 75%"),
                      backgroundColor: Colors.red,
                      labelStyle: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                'Created: ${dateFmt(data.createdAt)} • Updated: ${dateFmt(data.updatedAt)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive
              ? _CreateCampaignState.brand
              : Colors.blueGrey.shade300,
          width: 1.2,
        ),
      ),
      child: Text(
        isActive ? 'Active' : 'Ended',
        style: TextStyle(
          color: isActive
              ? _CreateCampaignState.brand
              : Colors.blueGrey.shade600,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: .2,
        ),
      ),
    );
  }
}
