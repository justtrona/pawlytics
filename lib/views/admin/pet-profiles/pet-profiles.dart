import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/model/pet-profiles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/route/route.dart' as route;

const _brand = Color(0xFF27374D);
const _softGrey = Color(0xFFE9EEF3);
const _cardGrey = Color(0xFFDDE5EC);
const _chipGrey = Color(0xFFF1F4F7);
const _danger = Color(0xFFE74C3C);

const _hPad = 10.0;
const _vGap = 10.0;
const _tileRadius = 10.0;

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

  // NEW state for filter & sort
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
      setState(() => _loading = false);
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
            debugPrint('Realtime event: ${payload.eventType}');

            final newRecord = payload.newRecord;
            final oldRecord = payload.oldRecord;

            setState(() {
              switch (payload.eventType) {
                case PostgresChangeEvent.insert:
                  if (newRecord != null) {
                    _pets = [PetProfile.fromMap(newRecord), ..._pets];
                  }
                  break;

                case PostgresChangeEvent.update:
                  if (newRecord != null && oldRecord != null) {
                    final index = _pets.indexWhere(
                      (p) => p.id == oldRecord['id'],
                    );
                    if (index != -1) {
                      _pets = [
                        for (int i = 0; i < _pets.length; i++)
                          if (i == index)
                            PetProfile.fromMap(newRecord)
                          else
                            _pets[i],
                      ];
                    }
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
      builder: (_) {
        return AlertDialog(
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
        );
      },
    );
  }

  void _toggleSort() {
    setState(() => _sortNewest = !_sortNewest);
    _loadPets();
  }

  int _gridCols(double _) => 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 24),
                children: [
                  Row(
                    children: const [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(''),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Super Admin',
                        style: TextStyle(
                          color: Color(0xFF6A7886),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.pets_rounded, color: _brand, size: 28),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pet Management',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _brand,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Stats
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '$totalPets',
                          label: 'Total Pets',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '$adoptionCount',
                          label: 'For Adoption',
                          underline: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '$medicalCount',
                          label: 'Needs\nMedical Care',
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: _vGap),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Pet'),
                          onPressed: () =>
                              Navigator.pushNamed(context, route.addPetProfile),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: _brand,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: _softGrey,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('All Statuses'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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

                  LayoutBuilder(
                    builder: (context, c) {
                      final cols = _gridCols(c.maxWidth);
                      const double tileHeight = 260.0;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pets.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: tileHeight,
                        ),
                        itemBuilder: (_, i) => _PetGridCard(pet: _pets[i]),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}

// Card
class _PetGridCard extends StatelessWidget {
  final PetProfile pet;
  const _PetGridCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardGrey,
      borderRadius: BorderRadius.circular(_tileRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_tileRadius),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: Image.network(
                    pet.imageUrl?.isNotEmpty == true
                        ? pet.imageUrl!
                        : 'https://placehold.co/300x300?text=${pet.species}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.pets, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pet.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              if (pet.status == 'For Adoption')
                const _ChipOutlined(text: 'FOR ADOPTION')
              else if (pet.status == 'Adopted')
                const _ChipFilled(text: 'ADOPTED')
              else
                const _ChipDanger(text: 'NEEDS MEDICAL CARE'),
              const SizedBox(height: 6),
              Text(
                '${pet.species} - ${pet.ageGroup}',
                style: const TextStyle(
                  color: Color(0xFF556270),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Small widgets
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final bool underline;
  final bool compact;

  const _StatCard({
    required this.value,
    required this.label,
    this.underline = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      decoration: BoxDecoration(
        color: _softGrey,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: _brand,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              height: 1.1,
              color: const Color(0xFF556270),
              decoration: underline ? TextDecoration.underline : null,
              decorationThickness: 2,
            ),
          ),
        ],
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
    return Material(
      color: _softGrey,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: _brand),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _brand,
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
          letterSpacing: .2,
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
          letterSpacing: .2,
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
          letterSpacing: .2,
        ),
      ),
    );
  }
}
