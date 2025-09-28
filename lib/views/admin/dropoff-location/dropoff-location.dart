import 'package:flutter/material.dart';
import 'package:pawlytics/route/route.dart' as route;
import 'package:pawlytics/views/admin/controllers/dropoff-controller.dart';
import 'package:pawlytics/views/admin/model/dropoff-model.dart';

class DropoffLocationPage extends StatefulWidget {
  const DropoffLocationPage({super.key});

  @override
  State<DropoffLocationPage> createState() => _DropoffLocationPageState();
}

class _DropoffLocationPageState extends State<DropoffLocationPage> {
  static const brand = Color(0xFF27374D);
  static const softGrey = Color(0xFFE9EEF3);

  final _searchCtrl = TextEditingController();
  final DropoffLocationController _controller = DropoffLocationController();

  List<DropoffLocation> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _loading = true);
    try {
      final data = await _controller.getAll();
      setState(() => _all = data);
    } catch (e) {
      debugPrint("Error loading locations: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  List<DropoffLocation> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((l) {
      return l.organization.toLowerCase().contains(q) ||
          l.address.toLowerCase().contains(q) ||
          l.phone.contains(q);
    }).toList();
  }

  OutlineInputBorder _searchBorder([Color? c]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c ?? Colors.transparent, width: 0),
  );

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                  ? const Center(
                      child: Text(
                        "No drop-off locations found",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final loc = _filtered[i];
                        return _LocationCard(
                          data: loc,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Open "${loc.organization}"'),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),

            // Add button pinned
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
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      route.createDropoff,
                    );
                    if (result == true) {
                      _loadLocations(); // ✅ Refresh list after adding
                    }
                  },
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

// ---- Card widget ----
class _LocationCard extends StatelessWidget {
  static const brand = Color(0xFF27374D);
  static const green = Color(0xFF25AE5F);
  static const red = Color(0xFFE85C5C);

  final DropoffLocation data;
  final VoidCallback? onTap;

  const _LocationCard({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: Colors.blueGrey.shade200, width: 1);
    final chipBg = data.status == 'Active'
        ? green.withOpacity(.14)
        : red.withOpacity(.12);
    final chipColor = data.status == 'Active' ? green : red;

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
                      data.organization,
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
                      data.status,
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

              // Scheduled Date
              _RowIconText(
                icon: Icons.schedule_rounded,
                text: data.scheduledAt.toString(), // format if needed
              ),
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
