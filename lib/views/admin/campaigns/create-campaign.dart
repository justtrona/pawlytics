import 'package:flutter/material.dart';
import 'package:pawlytics/route/route.dart' as route;
import 'package:pawlytics/views/admin/controllers/campaigns-controller.dart';
import 'package:pawlytics/views/admin/model/campaigns-model.dart';

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

  String _statusFilter = 'All Statuses';
  String _sortBy = 'Date Created';

  @override
  Widget build(BuildContext context) {
    final filtered = _controller.filterCampaigns(
      statusFilter: _statusFilter,
      sortBy: _sortBy,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Campaigns'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // Top stats
            Row(
              children: [
                Expanded(
                  child: _StatPill(
                    label: 'Total Campaigns',
                    value: '${_controller.getTotalCampaigns()}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    label: 'Active Campaigns',
                    value: '${_controller.getActiveCount()}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatPill(
                    label: 'Total Donation Raised',
                    value: _controller.formatMoney(_controller.getTotalRaised()),
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
                        options: const ['All Statuses', 'Active', 'Ended'],
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
                          'Amount Raised',
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
            ...filtered.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CampaignTile(
                  data: c,
                  money: _controller.formatMoney,
                  dateFmt: _controller.formatDate,
                  onTap: () {
                    // TODO: open campaign details
                  },
                ),
              ),
            ),
          ],
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
                    fontWeight: o == current ? FontWeight.w700 : FontWeight.w500,
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

// ====== WIDGETS (keep them here) ======
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
    final bg = emphasize ? _CreateCampaignState.brand : _CreateCampaignState.softGrey;
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
            style: TextStyle(
              color: emphasize ? Colors.white70 : _CreateCampaignState.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
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
              const Icon(Icons.expand_more_rounded,
                  size: 18, color: _CreateCampaignState.brand),
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
  final VoidCallback? onTap;

  const _CampaignTile({
    required this.data,
    required this.money,
    required this.dateFmt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (data.raised / data.goal).clamp(0.0, 1.0);

    return Material(
      color: _CreateCampaignState.tileGrey,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 96,
                  height: 72,
                  child: Image.network(
                    data.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Colors.white,
                      child: Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, right: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _CreateCampaignState.brand,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${money(data.raised)} of ${money(data.goal)}',
                        style: const TextStyle(
                          color: _CreateCampaignState.brand,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: Colors.white.withOpacity(.7),
                          valueColor: const AlwaysStoppedAnimation(
                            _CreateCampaignState.brand,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Deadline: ${dateFmt(data.deadline)}',
                              style: const TextStyle(
                                color: _CreateCampaignState.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _StatusChip(status: data.status),
                        ],
                      ),
                    ],
                  ),
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
  final CampaignStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == CampaignStatus.active;
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
        ),
      ),
    );
  }
}
