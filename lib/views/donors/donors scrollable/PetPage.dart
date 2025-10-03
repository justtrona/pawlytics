// lib/views/donors/donors scrollable/connections/pet_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/donors/donors scrollable/connections/PetDetailsPage.dart';

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
  final String ageGroup; // you previously showed this; using as “breed-ish”
  final String status; // e.g. "For Adoption"
  final String? imageUrl; // may be null/empty
  final DateTime? createdAt;
  final int campaignId; // default until you add a real column

  PetProfile({
    required this.id,
    required this.name,
    required this.species,
    required this.ageGroup,
    required this.status,
    required this.imageUrl,
    required this.createdAt,
    required this.campaignId,
  });

  static double _toD(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse('$v');
    } catch (_) {
      return null;
    }
  }

  factory PetProfile.fromMap(
    Map<String, dynamic> m, {
    int defaultCampaignId = 26,
  }) {
    return PetProfile(
      id: (m['id'] ?? m['uuid'] ?? '').toString(),
      name: (m['name'] ?? 'Unnamed').toString(),
      species: (m['species'] ?? '').toString(),
      ageGroup: (m['age_group'] ?? '').toString(),
      status: (m['status'] ?? '').toString(),
      imageUrl: (m['image']?.toString().isEmpty ?? true)
          ? null
          : m['image'].toString(),
      createdAt: _toDate(m['created_at']),
      campaignId: m['campaign_id'] is num
          ? (m['campaign_id'] as num).toInt()
          : defaultCampaignId,
    );
  }
}

/* ---------- Page ---------- */
class _PetPageState extends State<PetPage> {
  final _sb = Supabase.instance.client;

  // UI state
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All / Dog / Cat
  bool _loading = false;
  String? _error;

  // Data
  static const int _defaultCampaignId = 26;
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
          .select(
            'id, uuid, name, species, age_group, status, image, created_at, campaign_id',
          )
          .order('created_at', ascending: false);

      final rows = (res as List).cast<Map<String, dynamic>>();
      final items = rows
          .map(
            (m) => PetProfile.fromMap(m, defaultCampaignId: _defaultCampaignId),
          )
          .toList();

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
      // Search by name + ageGroup (you previously used “breed”)
      return p.name.toLowerCase().contains(q) ||
          p.ageGroup.toLowerCase().contains(q) ||
          p.status.toLowerCase().contains(q);
    }).toList();
  }

  // If you later store storage paths instead of full URLs,
  // resolve them here via storage.getPublicUrl(bucket, path).
  String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw;
    // TODO: if you store storage paths like "pets/abc.jpg",
    // return _sb.storage.from('YOUR_BUCKET').getPublicUrl(raw);
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
                  childAspectRatio: 0.9,
                ),
                itemCount: filteredPets.length,
                itemBuilder: (context, index) {
                  final p = filteredPets[index];
                  return _PetCard(
                    name: p.name,
                    breedLike: p.ageGroup.isEmpty
                        ? '—'
                        : p.ageGroup, // using age_group as “breed-ish”
                    type: p.species,
                    imageUrl: _resolveImageUrl(p.imageUrl),
                    campaignId: p.campaignId,
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
    required this.imageUrl,
    required this.name,
    required this.breedLike,
    required this.type,
    required this.campaignId,
  });

  final String? imageUrl;
  final String name;
  final String breedLike;
  final String type;
  final int campaignId;

  @override
  Widget build(BuildContext context) {
    final brand = const Color(0xFF1F2C47);

    return Container(
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
            height: 70,
            decoration: BoxDecoration(
              color: brand,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 6,
                  right: 6,
                  child: IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    iconSize: 20,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PetDetailPage(
                            campaignId: campaignId,
                            name: name,
                            image:
                                imageUrl ??
                                '', // your details page can handle empty
                            breed: breedLike,
                            type: type,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
