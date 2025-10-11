import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/donors/HomeScreenButtons/DonatePage.dart';

class PetDetailPage extends StatefulWidget {
  const PetDetailPage({
    super.key,
    required this.petId, // public.pet_profiles.id (text/uuid → pass as String)
    required this.name,
    required this.image, // asset path OR http url
    required this.breed,
    required this.type,
  });

  final String petId;
  final String name;
  final String image;
  final String breed;
  final String type;

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  bool isFavorite = false;

  Map<String, dynamic>? _row;
  String? _story;
  bool _loading = true;
  String? _error;

  // Summary from DB
  double _funds = 0.0; // from pet_profiles.funds
  int _donationCount = 0; // number of donations for this pet

  bool get _hasImage => widget.image.trim().isNotEmpty;
  bool get _isHttpImage =>
      _hasImage &&
      (widget.image.startsWith('http://') ||
          widget.image.startsWith('https://'));

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sb = Supabase.instance.client;

      // Explicitly type the futures list to avoid inference issues
      final futures = <Future<dynamic>>[
        sb
            .from('pet_profiles')
            .select('*')
            .eq('id', widget.petId)
            .maybeSingle(), // Map?
        sb.from('donations').select('id').eq('pet_id', widget.petId), // List
      ];

      final results = await Future.wait(futures);
      if (!mounted) return;

      // Pet row
      final Map<String, dynamic> row =
          (results[0] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final story = (row['story'] ?? '').toString().trim();

      // Funds from pet_profiles.funds (numeric)
      final fundsRaw = row['funds'];
      final funds = () {
        if (fundsRaw == null) return 0.0;
        if (fundsRaw is num) return fundsRaw.toDouble();
        return double.tryParse(fundsRaw.toString()) ?? 0.0;
      }();

      // Donations count
      final List<dynamic> donations = (results[1] as List<dynamic>? ?? []);
      final donationCount = donations.length;

      setState(() {
        _row = row;
        _story = story.isEmpty ? null : story;
        _funds = funds;
        _donationCount = donationCount;
        _loading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '${e.code}: ${e.message}';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /* ---------- flexible value readers ---------- */

  bool _readBoolAny(Map m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) {
        final v = m[k];
        if (v is bool) return v;
        if (v is num) return v != 0;
        final s = v.toString().toLowerCase();
        if (s == 'true' || s == 't' || s == '1' || s == 'yes' || s == 'y') {
          return true;
        }
      }
    }
    return false;
  }

  String? _readStringAny(Map m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) {
        final s = m[k].toString().trim();
        if (s.isNotEmpty) return s;
      }
    }
    return null;
  }

  /* ---------- tiny helpers ---------- */

  void _maybeAddChip(
    List<_ChipData> chips,
    Map row, {
    required List<String> keys,
    required String label,
    required IconData icon,
  }) {
    if (_readBoolAny(row, keys)) chips.add(_ChipData(label, icon));
  }

  // Normalize a status string (safe title-case-ish for chip text)
  String _normalizeStatus(String s) {
    final t = s.trim();
    if (t.isEmpty) return '';
    // Make only first letter uppercased per word; keep rest lower
    return t
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  // Add a STATUS chip based on pet_profiles.status string
  void _addStatusChipIfAny(List<_ChipData> chips, Map row) {
    final raw = _readStringAny(row, ['status']);
    if (raw == null || raw.isEmpty) return;

    final s = raw.toLowerCase();
    IconData icon;

    if (s.contains('adopted')) {
      icon = Icons.verified; // adopted / completed
    } else if (s.contains('for adoption') ||
        (s.contains('adopt') && !s.contains('ed'))) {
      icon = Icons.home; // for adoption
    } else if (s.contains('foster')) {
      icon = Icons.family_restroom;
    } else if (s.contains('rehab') || s.contains('treatment')) {
      icon = Icons.healing;
    } else if (s.contains('reserved') || s.contains('hold')) {
      icon = Icons.hourglass_top;
    } else {
      icon = Icons.info; // generic/unknown custom value
    }

    chips.add(_ChipData(_normalizeStatus(raw), icon));
  }

  /* ------------------------------------ UI ------------------------------------ */

  @override
  Widget build(BuildContext context) {
    final row = _row ?? const {};
    final gender = _readStringAny(row, ['gender']) ?? 'Male';
    final age = _readStringAny(row, ['age', 'age_group']) ?? 'Senior';

    // Quick facts
    final petInfo = {"Age": age, "Breed": widget.breed, "Gender": gender};

    // Chips (STATUS first, then booleans)
    final chips = <_ChipData>[];
    _addStatusChipIfAny(chips, row);

    _maybeAddChip(
      chips,
      row,
      keys: const ['vaccination', 'vaccinated', 'is_vaccinated'],
      label: 'Vaccinated',
      icon: Icons.vaccines,
    );
    _maybeAddChip(
      chips,
      row,
      keys: const ['surgery', 'had_surgery', 'needs_surgery'],
      label: 'Surgery',
      icon: Icons.healing,
    );
    _maybeAddChip(
      chips,
      row,
      keys: const ['dental_care', 'dentalCare'],
      label: 'Dental Care',
      icon: Icons.medical_services,
    );
    _maybeAddChip(
      chips,
      row,
      keys: const ['deworming'],
      label: 'Deworming',
      icon: Icons.pest_control,
    );
    _maybeAddChip(
      chips,
      row,
      keys: const ['injury_treatment', 'injuryTreatment'],
      label: 'Injury Treatment',
      icon: Icons.local_hospital,
    );
    _maybeAddChip(
      chips,
      row,
      keys: const ['skin_treatment', 'skinTreatment'],
      label: 'Skin Treatment',
      icon: Icons.healing,
    );
    _maybeAddChip(
      chips,
      row,
      keys: const [
        'spay_neuter',
        'spayed_neutered',
        'is_neutered',
        'is_spayed',
      ],
      label: 'Spay/Neuter',
      icon: Icons.pets,
    );

    void goDonate() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DonatePage(
            petId: widget.petId,
            allowInKind: false,
            autoAssignOpex: false,
            campaignTitle: widget.name,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadEverything,
            icon: const Icon(Icons.refresh, color: Colors.black87),
          ),
        ],
      ),

      /* --------- Gradient Donate FAB (center float) --------- */
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F2D50), Color(0xFFEC8C69)],
            ),
            borderRadius: BorderRadius.circular(36),
            boxShadow: const [
              BoxShadow(
                blurRadius: 14,
                offset: Offset(0, 8),
                color: Colors.black26,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: FloatingActionButton.extended(
              heroTag: 'donateFabPet',
              tooltip: 'Support this pet',
              onPressed: goDonate,
              icon: const Icon(Icons.volunteer_activism_rounded),
              label: const Text(
                'Donate Me',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),
        ),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorBox(message: _error!, onRetry: _loadEverything)
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header image (safe fallback if empty/invalid)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: !_hasImage
                          ? _placeholderHeader()
                          : _isHttpImage
                          ? Image.network(
                              widget.image,
                              height: 280,
                              width: double.infinity,
                              fit: BoxFit
                                  .contain, // ✅ show entire image, no cropping
                              alignment: Alignment.center,
                              errorBuilder: (_, __, ___) =>
                                  _placeholderHeader(),
                            )
                          : Image.asset(
                              widget.image,
                              height: 280,
                              width: double.infinity,
                              fit: BoxFit.contain, // ✅ same behavior for assets
                              alignment: Alignment.center,
                              errorBuilder: (_, __, ___) =>
                                  _placeholderHeader(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name + favorite
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            widget.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2C47),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                            size: 30,
                            color: const Color(0xFF1F2C47),
                          ),
                          onPressed: () =>
                              setState(() => isFavorite = !isFavorite),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick facts
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: petInfo.entries
                        .map((entry) => _buildMainTag(entry.key, entry.value))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  // ---- Support so far (Total funds + Number of donations) ----
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _supportSoFarCard(
                      total: _funds,
                      count: _donationCount,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Status + attribute chips
                  if (chips.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: chips
                            .map(
                              (c) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1F2C47),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(c.icon, size: 16, color: Colors.white),
                                    const SizedBox(width: 6),
                                    Text(
                                      c.label,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // About me (story)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "About me",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2C47),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _story ??
                          "${widget.name} is a lovely ${widget.breed} ${widget.type} looking for a forever home!\n\n"
                              "He was rescued in the Philippines after being abandoned. "
                              "Despite his hardships, he remains gentle and full of love. "
                              "Adopting ${widget.name} means giving him a second chance "
                              "to live in a safe and happy environment. He loves people, "
                              "is friendly with kids, and enjoys quiet afternoons. "
                              "Help us give ${widget.name} the life he deserves.",
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Color(0xFF1F2C47),
                      ),
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
    );
  }

  Widget _supportSoFarCard({required double total, required int count}) {
    String money(double v) => "₱${v.toStringAsFixed(0)}";
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 8),
            color: Colors.black12,
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Support so far",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2C47),
            ),
          ),
          const SizedBox(height: 6),
          const Divider(),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  label: "Total Funds",
                  value: money(total),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricTile(
                  label: "Donations",
                  value: count.toString(),
                  icon: Icons.people_alt_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2C47).withOpacity(.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1F2C47)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderHeader() {
    return Container(
      height: 280,
      width: double.infinity,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const Icon(Icons.pets, size: 56, color: Colors.white70),
    );
  }

  Widget _buildMainTag(String label, String value) {
    return Container(
      width: 150,
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2C47),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------- tiny helpers ----------------- */

class _ChipData {
  final String label;
  final IconData icon;
  _ChipData(this.label, this.icon);
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
      ),
    );
  }
}
