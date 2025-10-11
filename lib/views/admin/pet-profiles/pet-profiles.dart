// lib/views/admin/pet-profiles/pet-profiles.dart
import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/model/pet-profiles-model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/route/route.dart' as route;

// Adjust this path if your PetDetailPage lives elsewhere
import 'package:pawlytics/views/admin/pet-profiles/pet-detail-page.dart';

const _brand = Color(0xFF27374D);
const _brandDark = Color(0xFF1C2A3A);
const _accent = Color(0xFF4F8EDC);
const _softGrey = Color(0xFFEFF3F7);
const _line = Color(0xFFE5EDF4);
const _cardGrey = Color(0xFFF8FAFD);
const _chipGrey = Color(0xFFF1F4F7);
const _danger = Color(0xFFE74C3C);
const _success = Color(0xFF10B981);
const _warn = Color(0xFFF59E0B);

const _hPad = 12.0;
const _vGap = 12.0;
const _tileRadius = 16.0;

class PetProfiles extends StatefulWidget {
  const PetProfiles({super.key});

  @override
  State<PetProfiles> createState() => _PetProfilesState();
}

class _PetProfilesState extends State<PetProfiles> {
  List<PetProfile> _pets = [];
  bool _loading = true;

  int totalPets = 0;
  int adoptionCount = 0;
  int medicalCount = 0;

  String? _selectedType;
  bool _sortNewest = true;

  RealtimeChannel? _petChannel;

  @override
  void initState() {
    super.initState();
    _loadPets();
    _subscribeToPets();
  }

  Future<void> _loadPets() async {
    setState(() => _loading = true);

    try {
      final client = Supabase.instance.client;

      final rawResponse = _selectedType != null && _selectedType!.isNotEmpty
          ? await client
                .from('pet_profiles')
                .select()
                .eq('species', _selectedType!)
                .order('created_at', ascending: !_sortNewest)
          : await client
                .from('pet_profiles')
                .select()
                .order('created_at', ascending: !_sortNewest);

      final data = rawResponse as List<dynamic>;

      final pets = data
          .map((row) => PetProfile.fromMap(row as Map<String, dynamic>))
          .toList();

      setState(() {
        _pets = pets;
        _recalcStats();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading pets: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _recalcStats() {
    totalPets = _pets.length;
    adoptionCount = _pets.where((p) => p.status == 'For Adoption').length;
    medicalCount = _pets.where((p) => p.status == 'Needs Medical Care').length;
  }

  bool _matchesFilter(PetProfile p) {
    if (_selectedType == null || _selectedType!.isEmpty) return true;
    return p.species == _selectedType;
  }

  void _sortLocal() {
    _pets.sort((a, b) {
      final ad = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return _sortNewest ? bd.compareTo(ad) : ad.compareTo(bd);
    });
  }

  void _subscribeToPets() {
    final client = Supabase.instance.client;

    _petChannel = client
        .channel('public:pet_profiles')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pet_profiles',
          callback: (payload) {
            final newRecord = payload.newRecord;
            final oldRecord = payload.oldRecord;

            setState(() {
              switch (payload.eventType) {
                case PostgresChangeEvent.insert:
                  if (newRecord != null) {
                    final p = PetProfile.fromMap(newRecord);
                    if (_matchesFilter(p)) {
                      _pets = [p, ..._pets];
                      _sortLocal();
                    }
                  }
                  break;
                case PostgresChangeEvent.update:
                  if (newRecord != null && oldRecord != null) {
                    final updated = PetProfile.fromMap(newRecord);
                    final idx = _pets.indexWhere(
                      (p) => p.id == oldRecord['id'],
                    );
                    final matches = _matchesFilter(updated);

                    if (idx != -1 && matches) {
                      _pets[idx] = updated;
                    } else if (idx != -1 && !matches) {
                      _pets.removeAt(idx);
                    } else if (idx == -1 && matches) {
                      _pets = [updated, ..._pets];
                    }
                    _sortLocal();
                  }
                  break;
                case PostgresChangeEvent.delete:
                  if (oldRecord != null) {
                    _pets = _pets
                        .where((p) => p.id != oldRecord['id'])
                        .toList();
                  }
                  break;
                default:
                  break;
              }

              _recalcStats();
            });
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_petChannel != null) {
      Supabase.instance.client.removeChannel(_petChannel!);
    }
    super.dispose();
  }

  void _showFilterDialog() {
    final speciesList = _pets.isNotEmpty
        ? _pets.map((p) => p.species).toSet().toList()
        : ['Dog', 'Cat'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Filter by Type"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("All"),
              onTap: () {
                setState(() => _selectedType = null);
                Navigator.pop(context);
                _loadPets();
              },
            ),
            ...speciesList.map(
              (s) => ListTile(
                title: Text(s),
                onTap: () {
                  setState(() => _selectedType = s);
                  Navigator.pop(context);
                  _loadPets();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSort() {
    setState(() => _sortNewest = !_sortNewest);
    _loadPets();
  }

  Future<void> _openDetails(PetProfile pet) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PetDetailPage(pet: pet)),
    );
    if (changed == true) {
      // pet was saved or deleted
      await _loadPets();
    }
  }

  Future<void> _openAdd() async {
    final res = await Navigator.pushNamed(context, route.addPetProfile);
    if (res == true) {
      await _loadPets();
    }
  }

  int _gridCols(double width) => width > 900 ? 4 : (width > 600 ? 3 : 2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: _brandDark,
        centerTitle: true,
        leading: const BackButton(color: _brandDark),
        title: const Text(
          'Pet Profiles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _brandDark,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _line),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(_hPad, 10, _hPad, 24),
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _brand.withOpacity(.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: _brand,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Super Admin',
                        style: TextStyle(
                          color: Color(0xFF6A7886),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.pets_rounded, color: _brand, size: 26),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Stats cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '$totalPets',
                          label: 'Total Pets',
                          icon: Icons.inventory_2_rounded,
                          bubbleColor: _accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '$adoptionCount',
                          label: 'For Adoption',
                          icon: Icons.home_rounded,
                          bubbleColor: _success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '$medicalCount',
                          label: 'Needs\nMedical Care',
                          icon: Icons.healing_rounded,
                          bubbleColor: _warn,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: _vGap),

                  // Call-to-action row
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _line),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Pet'),
                            onPressed: _openAdd,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _brand,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.checklist_rounded),
                            label: const Text('All Statuses'),
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _brandDark,
                              side: const BorderSide(color: _line),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _vGap),

                  // Filters
                  Row(
                    children: [
                      Expanded(
                        child: _PillButton(
                          icon: Icons.filter_list_rounded,
                          label: _selectedType == null
                              ? 'Filter by Type'
                              : 'Type: $_selectedType',
                          onTap: _showFilterDialog,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PillButton(
                          icon: Icons.sort_rounded,
                          label: _sortNewest
                              ? 'Sort by Newest'
                              : 'Sort by Oldest',
                          onTap: _toggleSort,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: _vGap),

                  // Grid
                  LayoutBuilder(
                    builder: (context, c) {
                      final cols = _gridCols(c.maxWidth);
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pets.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          mainAxisExtent: 280,
                        ),
                        itemBuilder: (_, i) => _PetGridCard(
                          pet: _pets[i],
                          onTap: () => _openDetails(_pets[i]),
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

/* ================= UI widgets ================= */

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color bubbleColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.bubbleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      decoration: BoxDecoration(
        color: _cardGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bubbleColor.withOpacity(.18), bubbleColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: _brandDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6A7886),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PetGridCard extends StatelessWidget {
  final PetProfile pet;
  final VoidCallback onTap;
  const _PetGridCard({required this.pet, required this.onTap});

  Color _statusBg(String s) {
    switch (s) {
      case 'For Adoption':
        return _success.withOpacity(.15);
      case 'Adopted':
        return _accent.withOpacity(.15);
      default:
        return _danger.withOpacity(.12);
    }
  }

  Color _statusFg(String s) {
    switch (s) {
      case 'For Adoption':
        return _success;
      case 'Adopted':
        return _accent;
      default:
        return _danger;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'For Adoption':
        return Icons.home_rounded;
      case 'Adopted':
        return Icons.verified_rounded;
      default:
        return Icons.healing_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusBg = _statusBg(pet.status);
    final statusFg = _statusFg(pet.status);
    final statusIc = _statusIcon(pet.status);

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_tileRadius),
        side: const BorderSide(color: _line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(_tileRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image (no overlay now)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.06),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      pet.imageUrl?.isNotEmpty == true
                          ? pet.imageUrl!
                          : 'https://placehold.co/600x450?text=${pet.species}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: _softGrey,
                        alignment: Alignment.center,
                        child: const Icon(Icons.pets, size: 42),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Name
              Text(
                pet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: _brandDark,
                ),
              ),
              const SizedBox(height: 4),

              // Species · Age
              Text(
                '${pet.species} · ${pet.ageGroup}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6A7886),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              // ✅ Status chip BELOW species/age
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusFg.withOpacity(.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIc, size: 14, color: statusFg),
                    const SizedBox(width: 6),
                    Text(
                      pet.status,
                      style: TextStyle(
                        color: statusFg,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: _brand),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700, color: _brand),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _line),
        backgroundColor: _softGrey,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _ChipOutlined extends StatelessWidget {
  final String text;
  const _ChipOutlined({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _chipGrey,
        border: Border.all(color: _brand, width: 1.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _brand,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ChipFilled extends StatelessWidget {
  final String text;
  const _ChipFilled({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _brand,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ChipDanger extends StatelessWidget {
  final String text;
  const _ChipDanger({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _danger, width: 1.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _danger,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}
