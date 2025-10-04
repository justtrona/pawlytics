import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/donors/HomeScreenButtons/DonatePage.dart';
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
          _selectedFilter == 'All' ||
          p.species.toLowerCase() == _selectedFilter.toLowerCase();
      if (!matchesFilter) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.ageGroup.toLowerCase().contains(q) ||
          p.status.toLowerCase().contains(q) ||
          p.species.toLowerCase().contains(q);
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
        backgroundColor: Colors.white,
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
            icon: const Icon(Icons.refresh, color: Color(0xFF1F2C47)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPets,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // Tagline row
            Row(
              children: const [
                Icon(
                  Icons.volunteer_activism_rounded,
                  size: 20,
                  color: Color(0xFF1F2C47),
                ),
                SizedBox(width: 8),
                Text(
                  "Every gift helps a rescue find home.",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2C47),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search + Filter pills
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: "Search name, status, or breed",
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

            const SizedBox(height: 18),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 56),
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
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.74,
                ),
                itemCount: filteredPets.length,
                itemBuilder: (context, index) {
                  final p = filteredPets[index];
                  return _PetCard(
                    id: p.id,
                    name: p.name,
                    breedLike: p.ageGroup.isEmpty ? '—' : p.ageGroup,
                    type: p.species,
                    status: p.status,
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
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
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

/* ---------- Card ---------- */

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.breedLike,
    required this.type,
    required this.status,
  });

  final String id; // <- petId
  final String? imageUrl;
  final String name;
  final String breedLike;
  final String type;
  final String status;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF0F2D50);

    void goDonate() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DonatePage(petId: id, allowInKind: true, autoAssignOpex: false),
        ),
      );
    }

    void goDetails() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PetDetailPage(
            petId: id,
            name: name,
            image: imageUrl ?? '',
            breed: breedLike,
            type: type,
          ),
        ),
      );
    }

    // status pill color/icon
    final _StatusStyle st = _statusStyle(status);

    return InkWell(
      onTap: goDetails,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Image
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: AspectRatio(
                  aspectRatio: 4 / 5,
                  child: imageUrl == null
                      ? _placeholderImg()
                      : Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderImg(),
                        ),
                ),
              ),

              // Top-left status pill
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: st.bg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: st.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(st.icon, size: 14, color: st.fg),
                      const SizedBox(width: 6),
                      Text(
                        st.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: st.fg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Gradient bottom
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(0, .4),
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black54,
                        Colors.black87,
                      ],
                    ),
                  ),
                ),
              ),

              // Name + meta + buttons
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "$breedLike • $type",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: goDonate,
                            icon: const Icon(
                              Icons.volunteer_activism_rounded,
                              size: 18,
                            ),
                            label: const Text('Donate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: brand,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: goDetails,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(.9),
                            foregroundColor: brand,
                          ),
                          icon: const Icon(Icons.info_outline),
                          tooltip: 'Details',
                        ),
                      ],
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

  Widget _placeholderImg() => Container(
    color: Colors.grey.shade300,
    child: const Center(
      child: Icon(Icons.pets, size: 56, color: Colors.white70),
    ),
  );

  // Map status string -> colors, icon, normalized label
  _StatusStyle _statusStyle(String s) {
    final lower = s.toLowerCase();
    Color bg, border, fg;
    IconData icon;

    if (lower.contains('adopted')) {
      bg = const Color(0xFFEDE9FE);
      border = const Color(0xFFD9D6FE);
      fg = const Color(0xFF5B21B6);
      icon = Icons.verified;
    } else if (lower.contains('for adoption') ||
        (lower.contains('adopt') && !lower.contains('ed'))) {
      bg = const Color(0xFFEFFDF5);
      border = const Color(0xFFD1FAE5);
      fg = const Color(0xFF065F46);
      icon = Icons.home;
    } else if (lower.contains('foster')) {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      fg = const Color(0xFF92400E);
      icon = Icons.family_restroom;
    } else if (lower.contains('rehab') || lower.contains('treatment')) {
      bg = const Color(0xFFFFF1F2);
      border = const Color(0xFFFECACA);
      fg = const Color(0xFF9F1239);
      icon = Icons.healing;
    } else if (lower.contains('reserved') || lower.contains('hold')) {
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFFBFDBFE);
      fg = const Color(0xFF1D4ED8);
      icon = Icons.hourglass_top;
    } else {
      bg = Colors.white;
      border = Colors.black12;
      fg = const Color(0xFF1F2C47);
      icon = Icons.info_outline;
    }

    return _StatusStyle(_titleCase(s), bg, border, fg, icon);
  }

  String _titleCase(String input) {
    final t = input.trim();
    if (t.isEmpty) return 'Status';
    return t
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

class _StatusStyle {
  final String label;
  final Color bg, border, fg;
  final IconData icon;
  _StatusStyle(this.label, this.bg, this.border, this.fg, this.icon);
}
