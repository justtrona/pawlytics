import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ============================================================================
/// SUPABASE REPOSITORY – no server-side type filter, client-side "inkind" detect
/// ============================================================================
class SupabaseDonationRepository implements DonationRepository {
  final SupabaseClient _sb = Supabase.instance.client;

  // ---- helpers -------------------------------------------------------------
  InkindStatus _parseStatus(dynamic v) {
    final s = (v ?? 'pending').toString().toLowerCase();
    if (s == 'for_pickup' || s == 'forpickup') return InkindStatus.forPickup;
    if (s == 'received') return InkindStatus.received;
    return InkindStatus.pending;
  }

  // Heuristic to classify an in-kind row regardless of column names/values
  bool _looksInkind(Map r) {
    final typeA = r['donation_type']?.toString().toLowerCase();
    final typeB = r['donation_typ']?.toString().toLowerCase();
    final byType =
        typeA == 'inkind' ||
        typeA == 'in-kind' ||
        typeB == 'inkind' ||
        typeB == 'in-kind';

    final amount = r['amount'];
    final hasNoAmount = amount == null || (amount is num && amount == 0);
    final hasGoods =
        (r['item'] != null && r['item'].toString().trim().isNotEmpty) ||
        (r['quantity'] is num && (r['quantity'] as num) > 0);

    return byType || (hasNoAmount && hasGoods);
  }

  DonationModule _inferModule(Map row) {
    if ((row['allocation_id'] ?? row['opex_allocation_id'] ?? row['opex_id']) !=
        null) {
      return DonationModule.opex;
    }
    if (row['campaign_id'] != null) return DonationModule.campaign;
    return DonationModule.pet;
  }

  String _moduleRefName(DonationModule m, Map row) {
    switch (m) {
      case DonationModule.opex:
        final a = row['alloc_by_allocation_fk'] as Map?;
        final b = row['alloc_by_opex_allocation_fk'] as Map?;
        final c = row['alloc_by_opex_id_fkey'] as Map?;
        return (a?['category'] ?? b?['category'] ?? c?['category'])
                ?.toString() ??
            'OPEX';
      case DonationModule.campaign:
        final camp = row['campaigns'] as Map?;
        return camp?['program']?.toString() ??
            camp?['description']?.toString() ??
            'Campaign';
      case DonationModule.pet:
        final pet = row['pet_profiles'] as Map?;
        return pet?['name']?.toString() ?? 'Pet';
    }
  }

  DateTime? _tryDT(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  Donation _mapRow(Map row) {
    final module = _inferModule(row);
    final refName = _moduleRefName(module, row);

    final dropoff =
        row['drop_off_loc'] ??
        row['drop_off_location'] ??
        row['dropoff_location'];
    final phone = row['donor_phone'] ?? row['phone'];

    return Donation(
      id: (row['id'] as num).toInt(),
      donorName: (row['donor_name'] ?? 'Unknown').toString(),
      module: module,
      moduleRefName: refName,
      item: row['item']?.toString(),
      quantity: (row['quantity'] is num)
          ? (row['quantity'] as num).toInt()
          : null,
      notes: row['notes']?.toString(),
      dropOffLocation: dropoff?.toString(),
      scheduledAt: _tryDT(row['donation_date'] ?? row['donation_dat']),
      createdAt: _tryDT(row['created_at']) ?? DateTime.now(),
      inkindStatus: _parseStatus(row['inkind_status']),
      phone: phone?.toString(),
    );
  }

  // ---- queries -------------------------------------------------------------
  @override
  Future<List<Donation>> fetchInkindOnly() async {
    final data = await _sb
        .from('donations')
        .select(r'''
          *,
          alloc_by_allocation_fk:operational_expense_allocations!donations_allocation_fk(category),
          alloc_by_opex_allocation_fk:operational_expense_allocations!donations_opex_allocation_fk(category),
          alloc_by_opex_id_fkey:operational_expense_allocations!donations_opex_id_fkey(category),
          campaigns!left(program, description),
          pet_profiles!left(name)
        ''')
        // no server-side filter (avoids column-not-found errors)
        .order('created_at', ascending: false)
        .limit(1000);

    final rows = (data as List).cast<Map>();
    final inkindRows = rows.where(_looksInkind).toList();
    return inkindRows.map(_mapRow).toList();
  }

  @override
  Future<Donation> updateInkindStatus({
    required int donationId,
    required InkindStatus status,
    String? adminNote,
  }) async {
    final statusStr = switch (status) {
      InkindStatus.pending => 'pending',
      InkindStatus.forPickup => 'for_pickup',
      InkindStatus.received => 'received',
    };

    final payload = <String, dynamic>{
      'inkind_status': statusStr,
      'updated_at': DateTime.now().toIso8601String(),
      if (adminNote != null && adminNote.isNotEmpty) 'admin_note': adminNote,
    };

    final updated = await _sb
        .from('donations')
        .update(payload)
        .eq('id', donationId)
        // do not filter by donation_* here; avoids column mismatch
        .select(r'''
          *,
          alloc_by_allocation_fk:operational_expense_allocations!donations_allocation_fk(category),
          alloc_by_opex_allocation_fk:operational_expense_allocations!donations_opex_allocation_fk(category),
          alloc_by_opex_id_fkey:operational_expense_allocations!donations_opex_id_fkey(category),
          campaigns!left(program, description),
          pet_profiles!left(name)
        ''')
        .single();

    return _mapRow(updated as Map);
  }
}

/// ============================================================================
/// DOMAIN MODELS (INKIND-ONLY)
/// ============================================================================
enum DonationModule { opex, campaign, pet }

enum InkindStatus { pending, forPickup, received }

extension InkindStatusX on InkindStatus {
  String get label => switch (this) {
    InkindStatus.pending => 'Pending',
    InkindStatus.forPickup => 'For Pickup',
    InkindStatus.received => 'Received',
  };
  Color get color => switch (this) {
    InkindStatus.pending => Colors.orange,
    InkindStatus.forPickup => Colors.blue,
    InkindStatus.received => Colors.green,
  };
}

class Donation {
  final int id;
  final String donorName;
  final DonationModule module;
  final String moduleRefName; // OPEX category | Campaign title | Pet name
  final String? item;
  final int? quantity;
  final String? notes;
  final String? dropOffLocation;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final InkindStatus inkindStatus;
  final String? phone;

  Donation({
    required this.id,
    required this.donorName,
    required this.module,
    required this.moduleRefName,
    required this.createdAt,
    required this.inkindStatus,
    this.item,
    this.quantity,
    this.notes,
    this.dropOffLocation,
    this.scheduledAt,
    this.phone,
  });

  Donation copyWith({InkindStatus? inkindStatus}) => Donation(
    id: id,
    donorName: donorName,
    module: module,
    moduleRefName: moduleRefName,
    item: item,
    quantity: quantity,
    notes: notes,
    dropOffLocation: dropOffLocation,
    scheduledAt: scheduledAt,
    createdAt: createdAt,
    inkindStatus: inkindStatus ?? this.inkindStatus,
    phone: phone,
  );
}

/// ============================================================================
/// REPOSITORY CONTRACT
/// ============================================================================
abstract class DonationRepository {
  Future<List<Donation>> fetchInkindOnly();
  Future<Donation> updateInkindStatus({
    required int donationId,
    required InkindStatus status,
    String? adminNote,
  });
}

/// ============================================================================
/// SCREEN (INKIND-ONLY)
/// ============================================================================
class InkindMain extends StatefulWidget {
  const InkindMain({super.key});
  @override
  State<InkindMain> createState() => _InkindMainState();
}

class _InkindMainState extends State<InkindMain>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final DonationRepository repo;

  InkindStatus? statusFilter; // null = all
  String query = '';
  List<Donation> all = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    repo = SupabaseDonationRepository(); // ✅ REAL DATA
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await repo.fetchInkindOnly();
      setState(() {
        all = data;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Load failed: $e')));
      }
    }
  }

  List<Donation> _filtered() {
    final moduleFilter = switch (_tab.index) {
      1 => DonationModule.opex,
      2 => DonationModule.campaign,
      3 => DonationModule.pet,
      _ => null,
    };

    return all.where((d) {
      if (moduleFilter != null && d.module != moduleFilter) return false;
      if (statusFilter != null && d.inkindStatus != statusFilter) return false;
      if (query.isNotEmpty) {
        final q = query.toLowerCase();
        final hay = [
          d.donorName,
          d.moduleRefName,
          d.item ?? '',
          d.notes ?? '',
          d.dropOffLocation ?? '',
        ].join(' ').toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _changeStatus(BuildContext ctx, Donation d) async {
    final next = await showModalBottomSheet<_StatusChangeResult>(
      context: ctx,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _StatusSheet(current: d.inkindStatus),
    );
    if (next == null) return;
    try {
      final updated = await repo.updateInkindStatus(
        donationId: d.id,
        status: next.status,
        adminNote: next.note,
      );
      final idx = all.indexWhere((x) => x.id == d.id);
      setState(() => all[idx] = updated);
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Status updated to ${next.status.label}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In-Kind Donations (Admin)'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'OPEX'),
            Tab(text: 'Campaigns'),
            Tab(text: 'Pet Profiles'),
          ],
          onTap: (_) => setState(() {}),
        ),
      ),
      body: Column(
        children: [
          _Filters(
            status: statusFilter,
            onStatusChanged: (v) => setState(() => statusFilter = v),
            onSearch: (v) => setState(() => query = v),
            onRefresh: _load,
          ),
          const Divider(height: 0),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : _DonationList(
                    items: _filtered(),
                    onChangeStatus: _changeStatus,
                  ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// FILTERS
/// ============================================================================
class _Filters extends StatelessWidget {
  final InkindStatus? status;
  final ValueChanged<InkindStatus?> onStatusChanged;
  final ValueChanged<String> onSearch;
  final Future<void> Function() onRefresh;

  const _Filters({
    required this.status,
    required this.onStatusChanged,
    required this.onSearch,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            SizedBox(
              width: 260,
              child: TextField(
                onChanged: onSearch,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search donor, item, module…',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            _StatusChips(value: status, onChanged: onStatusChanged),
            IconButton(
              onPressed: onRefresh,
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  final InkindStatus? value;
  final ValueChanged<InkindStatus?> onChanged;

  const _StatusChips({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final entries = <(String, InkindStatus?)>[
      ('All', null),
      ('Pending', InkindStatus.pending),
      ('For Pickup', InkindStatus.forPickup),
      ('Received', InkindStatus.received),
    ];

    return Wrap(
      spacing: 6,
      children: entries.map((e) {
        final selected = value == e.$2;
        return ChoiceChip(
          label: Text(e.$1),
          selected: selected,
          onSelected: (_) => onChanged(e.$2),
        );
      }).toList(),
    );
  }
}

/// ============================================================================
/// LIST + CARD
/// ============================================================================
class _DonationList extends StatelessWidget {
  final List<Donation> items;
  final Future<void> Function(BuildContext, Donation) onChangeStatus;

  const _DonationList({required this.items, required this.onChangeStatus});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No in-kind donations found.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemBuilder: (ctx, i) {
        final d = items[i];
        return _DonationCard(
          donation: d,
          onChangeStatus: () => onChangeStatus(ctx, d),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemCount: items.length,
    );
  }
}

class _DonationCard extends StatelessWidget {
  final Donation donation;
  final VoidCallback onChangeStatus;

  const _DonationCard({required this.donation, required this.onChangeStatus});

  String get _moduleLabel => switch (donation.module) {
    DonationModule.opex => 'Operating Expense',
    DonationModule.campaign => 'Campaign',
    DonationModule.pet => 'Pet Profile',
  };

  @override
  Widget build(BuildContext context) {
    final status = donation.inkindStatus;

    return Card(
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetails(context, donation),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(radius: 22, child: Icon(Icons.card_giftcard)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          donation.donorName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        _Pill(text: _moduleLabel),
                        _Pill(text: donation.moduleRefName),
                        const _Pill(text: 'In-Kind'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Item: ${donation.item ?? '-'} • Qty: ${donation.quantity ?? 0}',
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (donation.dropOffLocation != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.place, size: 16),
                              const SizedBox(width: 4),
                              Text(donation.dropOffLocation!),
                            ],
                          ),
                        if (donation.scheduledAt != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event, size: 16),
                              const SizedBox(width: 4),
                              Text(_fmtDateTime(donation.scheduledAt!)),
                            ],
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.schedule, size: 16),
                            const SizedBox(width: 4),
                            Text('Created ${_relative(donation.createdAt)}'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusBadge(status),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onChangeStatus,
                    icon: const Icon(Icons.sync),
                    label: const Text('Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, Donation d) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _DetailsSheet(donation: d),
    );
  }
}

/// ============================================================================
/// DETAILS & STATUS SHEET
/// ============================================================================
class _DetailsSheet extends StatelessWidget {
  final Donation donation;
  const _DetailsSheet({required this.donation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 8,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Donation #${donation.id}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Field('Donor', donation.donorName),
                _Field('Module', switch (donation.module) {
                  DonationModule.opex => 'Operating Expense',
                  DonationModule.campaign => 'Campaign',
                  DonationModule.pet => 'Pet Profile',
                }),
                _Field('Reference', donation.moduleRefName),
                _Field('Item', donation.item ?? '-'),
                _Field('Quantity', '${donation.quantity ?? 0}'),
                if (donation.dropOffLocation != null)
                  _Field('Drop-off', donation.dropOffLocation!),
                if (donation.scheduledAt != null)
                  _Field('Schedule', _fmtDateTime(donation.scheduledAt!)),
                _Field('Created', _fmtDateTime(donation.createdAt)),
                if (donation.phone != null) _Field('Phone', donation.phone!),
                if (donation.notes != null) _Field('Notes', donation.notes!),
              ],
            ),
            const SizedBox(height: 16),
            _StatusBadge(donation.inkindStatus),
            const SizedBox(height: 12),
            Text(
              'Status Timeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text('• Pending → For Pickup → Received'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _StatusChangeResult {
  final InkindStatus status;
  final String? note;
  _StatusChangeResult(this.status, this.note);
}

class _StatusSheet extends StatefulWidget {
  final InkindStatus current;
  const _StatusSheet({required this.current});

  @override
  State<_StatusSheet> createState() => _StatusSheetState();
}

class _StatusSheetState extends State<_StatusSheet> {
  late InkindStatus _value;
  final TextEditingController _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _value = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Update Status', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<InkindStatus>(
            value: _value,
            items: InkindStatus.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                .toList(),
            onChanged: (v) => setState(() => _value = v!),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'New Status',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Admin note (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(
                    context,
                    _StatusChangeResult(
                      _value,
                      _note.text.trim().isEmpty ? null : _note.text.trim(),
                    ),
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// SMALL UI HELPERS
/// ============================================================================
class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final InkindStatus status;
  const _StatusBadge(this.status);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withOpacity(.15),
        border: Border.all(color: status.color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: status.color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.grey[700]),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

String _fmtDateTime(DateTime dt) {
  final d =
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  final t =
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  return '$d $t';
}

String _relative(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes.abs() < 60) {
    final m = diff.inMinutes.abs();
    return m == 0 ? 'just now' : '$m min ago';
  }
  if (diff.inHours.abs() < 24) return '${diff.inHours.abs()} h ago';
  return '${diff.inDays.abs()} d ago';
}
