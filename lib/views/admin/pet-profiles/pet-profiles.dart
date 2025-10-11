import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/model/pet-profiles-model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/route/route.dart' as route;
import 'package:pawlytics/views/admin/pet-profiles/pet-detail-page.dart';

// 🎨 Theme Colors
const _brand = Color(0xFF27374D);
const _brandDark = Color(0xFF1C2A3A);
const _accent = Color(0xFF4F8EDC);
const _softGrey = Color(0xFFF4F6F9);
const _line = Color(0xFFE5EDF4);
const _cardGrey = Color(0xFFF8FAFD);
const _danger = Color(0xFFE74C3C);
const _success = Color(0xFF10B981);
const _warn = Color(0xFFF59E0B);

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

      final pets = (rawResponse as List<dynamic>)
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

  void _subscribeToPets() {
    final client = Supabase.instance.client;
    _petChannel = client
        .channel('public:pet_profiles')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pet_profiles',
          callback: (payload) {
            setState(() => _loadPets());
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
    if (changed == true) await _loadPets();
  }

  Future<void> _openAdd() async {
    final res = await Navigator.pushNamed(context, route.addPetProfile);
    if (res == true) await _loadPets();
  }

  int _gridCols(double width) => width > 900 ? 4 : (width > 600 ? 3 : 2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softGrey,
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
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Stats Section
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            value: '$totalPets',
                            label: 'Total Pets',
                            icon: Icons.pets_rounded,
                            color: _accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            value: '$adoptionCount',
                            label: 'For Adoption',
                            icon: Icons.home_rounded,
                            color: _success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            value: '$medicalCount',
                            label: 'Needs\nMedical Care',
                            icon: Icons.healing_rounded,
                            color: _warn,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ✅ Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 18),
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
                            label: const Text('Statuses'),
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
                    const SizedBox(height: 20),

                    // ✅ Filter & Sort
                    Row(
                      children: [
                        Expanded(
                          child: _FilterButton(
                            icon: Icons.filter_alt_rounded,
                            label: _selectedType == null
                                ? 'Filter by Type'
                                : 'Type: $_selectedType',
                            onTap: _showFilterDialog,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FilterButton(
                            icon: Icons.sort_rounded,
                            label: _sortNewest
                                ? 'Newest First'
                                : 'Oldest First',
                            onTap: _toggleSort,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ✅ Pet Grid
                    LayoutBuilder(
                      builder: (context, c) {
                        final cols = _gridCols(c.maxWidth);
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _pets.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                mainAxisExtent: 280,
                              ),
                          itemBuilder: (_, i) => _PetCard(
                            pet: _pets[i],
                            onTap: () => _openDetails(_pets[i]),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 40), // ✅ bottom safe padding
                  ],
                ),
              ),
      ),
    );
  }
}

/* ------------------- Widgets ------------------- */

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ allow the card to grow; only enforce a small minimum
      constraints: const BoxConstraints(minHeight: 88),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // ✅ avoid bottom overflow
        children: [
          Container(
            width: 42, // a bit smaller
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.25), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min, // ✅ size to content
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: _brandDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label, // can include \n
                  maxLines: 2, // ✅ wrap onto two lines
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6A7886),
                    fontWeight: FontWeight.w600,
                    height: 1.15, // a touch tighter
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

class _PetCard extends StatelessWidget {
  final PetProfile pet;
  final VoidCallback onTap;
  const _PetCard({required this.pet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color bgColor;

    switch (pet.status) {
      case 'For Adoption':
        statusColor = _success;
        bgColor = _success.withOpacity(.1);
        break;
      case 'Adopted':
        statusColor = _accent;
        bgColor = _accent.withOpacity(.1);
        break;
      default:
        statusColor = _danger;
        bgColor = _danger.withOpacity(.1);
        break;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                pet.imageUrl?.isNotEmpty == true
                    ? pet.imageUrl!
                    : 'https://placehold.co/600x450?text=${pet.species}',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: 150, color: _softGrey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _brandDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.species} • ${pet.ageGroup}',
                    style: const TextStyle(
                      color: Color(0xFF6A7886),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      pet.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FilterButton({
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
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
