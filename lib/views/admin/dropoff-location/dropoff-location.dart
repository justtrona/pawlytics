import 'package:flutter/material.dart';
import 'package:pawlytics/route/route.dart' as route;

class DropoffLocation extends StatefulWidget {
  const DropoffLocation({super.key});

  @override
  State<DropoffLocation> createState() => _DropoffLocationState();
}

class _DropoffLocationState extends State<DropoffLocation> {
  // Theme
  static const brand = Color(0xFF27374D);
  static const softGrey = Color(0xFFE9EEF3);
  static const textMuted = Color(0xFF6A7886);
  static const green = Color(0xFF25AE5F);
  static const red = Color(0xFFE85C5C);

  final _searchCtrl = TextEditingController();

  final _all = <_Location>[
    const _Location(
      name: 'Law Office',
      address: 'Mac Arthur Highway, Davao City',
      hours: '9:00AM - 8:00PM',
      phone: '09123456789',
      active: true,
    ),
    const _Location(
      name: 'Davao Vets',
      address: 'Bajada, Davao City',
      hours: '9:00AM - 8:00PM',
      phone: '09123456789',
      active: true,
    ),
    const _Location(
      name: 'Dog Pound',
      address: 'Bajada, Davao City',
      hours: '9:00AM - 8:00PM',
      phone: '09123456789',
      active: false,
    ),
    const _Location(
      name: 'Panacan Barangay Hall',
      address: 'Panacan, Davao City',
      hours: '9:00AM - 8:00PM',
      phone: '09123456789',
      active: false,
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_Location> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((l) {
      return l.name.toLowerCase().contains(q) ||
          l.address.toLowerCase().contains(q) ||
          l.phone.contains(q);
    }).toList();
  }

  OutlineInputBorder _searchBorder([Color? c]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c ?? Colors.transparent, width: 0),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Locations'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search Locations',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: softGrey,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  enabledBorder: _searchBorder(),
                  focusedBorder: _searchBorder(),
                ),
              ),
            ),

            // List of locations
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final loc = _filtered[i];
                  return _LocationCard(
                    data: loc,
                    onTap: () {
                      // TODO: navigate to details / edit
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Open "${loc.name}"')),
                      );
                    },
                  );
                },
              ),
            ),

            // Add button pinned above nav bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
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
                  onPressed: () =>
                      Navigator.pushNamed(context, route.createDropoff),
                  child: const Text('Add Location'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Data model ----
class _Location {
  final String name;
  final String address;
  final String hours;
  final String phone;
  final bool active;

  const _Location({
    required this.name,
    required this.address,
    required this.hours,
    required this.phone,
    required this.active,
  });
}

// ---- Card widget ----
class _LocationCard extends StatelessWidget {
  static const brand = Color(0xFF27374D);
  static const softGrey = Color(0xFFE9EEF3);
  static const textMuted = Color(0xFF6A7886);
  static const green = Color(0xFF25AE5F);
  static const red = Color(0xFFE85C5C);

  final _Location data;
  final VoidCallback? onTap;

  const _LocationCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: Colors.blueGrey.shade200, width: 1);
    final chipBg = data.active ? green.withOpacity(.14) : red.withOpacity(.12);
    final chipColor = data.active ? green : red;
    final chipText = data.active ? 'Active' : 'Inactive';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: border,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: name + status chip
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      data.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: brand,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: chipColor, width: 1.2),
                    ),
                    child: Text(
                      chipText,
                      style: TextStyle(
                        color: chipColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: .2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Address
              _RowIconText(
                icon: Icons.location_on_outlined,
                text: data.address,
              ),
              const SizedBox(height: 6),

              // Hours
              _RowIconText(icon: Icons.schedule_rounded, text: data.hours),
              const SizedBox(height: 6),

              // Phone
              _RowIconText(icon: Icons.call_outlined, text: data.phone),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowIconText extends StatelessWidget {
  static const brand = Color(0xFF27374D);
  static const textMuted = Color(0xFF6A7886);

  final IconData icon;
  final String text;

  const _RowIconText({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: brand),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
