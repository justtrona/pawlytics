import 'package:flutter/material.dart';
import 'package:pawlytics/views/donors/HomeScreenButtons/DonatePage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/donors/donors scrollable/connections/PetDetailsPage.dart';
import 'package:pawlytics/views/donors/HomeScreenButtons/DonatePage.dart';

class PetPage extends StatefulWidget {
  const PetPage({super.key});

  @override
  State<PetPage> createState() => _PetPageState();
}

/* ---------- Model ---------- */
class PetProfile {
  final String id;
  final String name;
  final String species; // "Dog" / "Cat"
  final String ageGroup; // using as “breed-ish”
  final String status; // e.g. "For Adoption"
  final String? imageUrl;
  final DateTime? createdAt;

  PetProfile({
    required this.id,
    required this.name,
    required this.species,
    required this.ageGroup,
    required this.status,
    required this.imageUrl,
    required this.createdAt,
  });

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse('$v');
    } catch (_) {
      return null;
    }
  }

  factory PetProfile.fromMap(Map<String, dynamic> m) {
    return PetProfile(
      id: (m['id'] ?? '').toString(),
      name: (m['name'] ?? 'Unnamed').toString(),
      species: (m['species'] ?? '').toString(),
      ageGroup: (m['age_group'] ?? '').toString(),
      status: (m['status'] ?? '').toString(),
      imageUrl: (m['image']?.toString().isEmpty ?? true)
          ? null
          : m['image'].toString(),
      createdAt: _toDate(m['created_at']),
    );
  }
}

/* ---------- Page ---------- */
class _PetPageState extends State<PetPage> {
  final _sb = Supabase.instance.client;

  String _searchQuery = '';
  String _selectedFilter = 'All'; // All / Dog / Cat
  bool _loading = false;
  String? _error;

  final List<PetProfile> _allPets = [];

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _sb
          .from('pet_profiles')
          .select('id, name, species, age_group, status, image, created_at')
          .order('created_at', ascending: false);

      final rows = (res as List).cast<Map<String, dynamic>>();
      final items = rows.map((m) => PetProfile.fromMap(m)).toList();

      setState(() {
        _allPets
          ..clear()
          ..addAll(items);
      });
    } on PostgrestException catch (e) {
      setState(() => _error = '${e.code}: ${e.message}');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PetProfile> get _filtered {
    final q = _searchQuery.trim().toLowerCase();
    return _allPets.where((p) {
      final matchesFilter =
          _selectedFilter == 'All' || p.species == _selectedFilter;
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.ageGroup.toLowerCase().contains(q) ||
          p.status.toLowerCase().contains(q);
    }).toList();
  }

  String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    // If you save storage paths, convert to a public URL here.
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final filteredPets = _filtered;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Pets",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2C47),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadPets,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPets,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.pets, size: 20, color: Color(0xFF1F2C47)),
                  SizedBox(width: 6),
                  Text(
                    "Dog & Cat Categories",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2C47),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Search + Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: "Search by name / age group",
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _FilterPill(value: _selectedFilter, onTap: _showFilterDialog),
              ],
            ),

            const SizedBox(height: 20),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorBox(message: _error!, onRetry: _loadPets)
            else if (filteredPets.isEmpty)
              _EmptyBox(
                onClear: () => setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'All';
                }),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.92,
                ),
                itemCount: filteredPets.length,
                itemBuilder: (context, index) {
                  final p = filteredPets[index];
                  return _PetCard(
                    id: p.id, // <- petId to carry forward
                    name: p.name,
                    breedLike: p.ageGroup.isEmpty ? '—' : p.ageGroup,
                    type: p.species,
                    imageUrl: _resolveImageUrl(p.imageUrl),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Filter by"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final val in const ['All', 'Dog', 'Cat'])
              ListTile(
                title: Text(val),
                trailing: _selectedFilter == val
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() => _selectedFilter = val);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/* ---------- Small UI pieces ---------- */

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.value, required this.onTap});
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: Colors.black26),
          const SizedBox(height: 10),
          const Text(
            'No pets found',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different keyword or clear your filter.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.breedLike,
    required this.type,
  });

  final String id; // <- petId
  final String? imageUrl;
  final String name;
  final String breedLike;
  final String type;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF1F2C47);

    void goDonate() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DonatePage(
            petId: id, // <- key piece
            allowInKind: true,
            autoAssignOpex: false,
            // no campaignId / opexId here so they’ll be NULL in the row
          ),
        ),
      );
    }

    return InkWell(
      onTap: goDonate, // tap the card to donate to this pet
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
              child: imageUrl == null
                  ? Container(
                      height: 150,
                      color: Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.pets,
                        size: 48,
                        color: Colors.white70,
                      ),
                    )
                  : Image.network(
                      imageUrl!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 150,
                        color: Colors.grey.shade300,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.pets,
                          size: 48,
                          color: Colors.white70,
                        ),
                      ),
                    ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 8, right: 4),
              height: 74,
              decoration: const BoxDecoration(
                color: brand,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "$breedLike • $type",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Details',
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PetDetailPage(
                            petId: id, // <-- pass the pet id
                            name: name,
                            image: imageUrl ?? '',
                            breed: breedLike,
                            type: type,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: goDonate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: brand,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Donate'),
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
