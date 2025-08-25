import 'package:flutter/material.dart';

class PetProfiles extends StatefulWidget {
  const PetProfiles({super.key});

  @override
  State<PetProfiles> createState() => _PetProfilesState();
}

// THEME
const _brand = Color(0xFF27374D);
const _softGrey = Color(0xFFE9EEF3);
const _cardGrey = Color(0xFFDDE5EC);
const _chipGrey = Color(0xFFF1F4F7);
const _danger = Color(0xFFE74C3C);

// Layout
const _hPad = 10.0;
const _vGap = 10.0;
const _tileRadius = 10.0;

class _PetProfilesState extends State<PetProfiles> {
  final _pets = <_Pet>[
    _Pet(
      name: 'Peter',
      breed: 'Aspin',
      age: 'Young',
      status: _PetStatus.forAdoption,
      photo:
          'https://images.unsplash.com/photo-1543466835-00a7907e9de1?q=80&w=600&auto=format&fit=crop',
    ),
    _Pet(
      name: 'Peter',
      breed: 'Askal',
      age: 'Senior',
      status: _PetStatus.forAdoption,
      photo:
          'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?q=80&w=600&auto=format&fit=crop',
    ),
    _Pet(
      name: 'Peter',
      breed: 'Puspin',
      age: 'Senior',
      status: _PetStatus.needsMedical,
      photo:
          'https://images.unsplash.com/photo-1518791841217-8f162f1e1131?q=80&w=600&auto=format&fit=crop',
    ),
    _Pet(
      name: 'Peter',
      breed: 'Aspin',
      age: 'Senior',
      status: _PetStatus.adopted,
      photo:
          'https://images.unsplash.com/photo-1548191265-cc70d3d45ba1?q=80&w=600&auto=format&fit=crop',
    ),
  ];

  // Always 2 columns
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(_hPad, 8, _hPad, 24),
          children: [
            // Header
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(''),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Super Admin',
                  style: TextStyle(
                    color: Color(0xFF6A7886),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.pets_rounded, color: _brand, size: 28),
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
              children: const [
                Expanded(
                  child: _StatCard(value: '250', label: 'Total Pets'),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    value: '120',
                    label: 'For Adoption',
                    underline: false,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    value: '6',
                    label: 'Needs\nMedical Care',
                    compact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: _vGap),

            // Add + filters
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Pet'),
                    onPressed: () {},
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
                    label: 'Filter by Type',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PillButton(
                    icon: Icons.sort_rounded,
                    label: 'Sort by Newest',
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: _vGap),

            // 2-column grid with fixed tile height (prevents overflow)
            LayoutBuilder(
              builder: (context, c) {
                final cols = _gridCols(c.maxWidth);
                const double tileHeight = 260.0;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pets.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols, // always 2
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

// ---------- Card like your screenshot ----------
class _PetGridCard extends StatelessWidget {
  final _Pet pet;
  const _PetGridCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardGrey,
      borderRadius: BorderRadius.circular(_tileRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_tileRadius),
        onTap: () {}, // hook to details if needed
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Fixed-size circular photo
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: Image.network(
                    pet.photo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Colors.white,
                      child: Icon(Icons.pets),
                    ),
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
              if (pet.status == _PetStatus.forAdoption)
                const _ChipOutlined(text: 'FOR ADOPTION')
              else if (pet.status == _PetStatus.adopted)
                const _ChipFilled(text: 'ADOPTED')
              else
                const _ChipDanger(text: 'NEEDS MEDICAL CARE'),
              const SizedBox(height: 6),
              Text(
                '${pet.breed} - ${pet.age}',
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

// ---------- Small widgets ----------
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
    // (Optional) slightly clamp text scaling so stats don't explode
    final scale = MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.2);

    return Container(
      // was: height: 70,
      constraints: const BoxConstraints(minHeight: 76), // allows growth
      decoration: BoxDecoration(
        color: _softGrey,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: scale),
        child: Column(
          mainAxisSize: MainAxisSize.min, // don’t force extra height
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
              softWrap: true,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                height: 1.1, // a bit tighter than 1.2
                color: const Color(0xFF556270),
                decoration: underline ? TextDecoration.underline : null,
                decorationThickness: 2,
              ),
            ),
          ],
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

// Chips
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

// Model
enum _PetStatus { forAdoption, adopted, needsMedical }

class _Pet {
  final String name;
  final String breed;
  final String age;
  final String photo;
  final _PetStatus status;
  _Pet({
    required this.name,
    required this.breed,
    required this.age,
    required this.photo,
    required this.status,
  });
}
