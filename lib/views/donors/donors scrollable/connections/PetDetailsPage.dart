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

  bool get _isHttpImage => widget.image.startsWith('http');

  @override
  void initState() {
    super.initState();
    _loadPetRow();
  }

  Future<void> _loadPetRow() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sb = Supabase.instance.client;

      final res = await sb
          .from('pet_profiles')
          .select('*')
          .eq('id', widget.petId)
          .maybeSingle();

      if (!mounted) return;

      final row = (res ?? <String, dynamic>{});
      final story = (row['story'] ?? '').toString().trim();

      setState(() {
        _row = row;
        _story = story.isEmpty ? null : story;
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

  /* ---------- flexible value readers (table can use different names/types) ---------- */

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

  double? _readNumAny(Map m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) {
        final v = m[k];
        if (v is num) return v.toDouble();
        final p = double.tryParse(v.toString());
        if (p != null) return p;
      }
    }
    return null;
  }

  /* ------------------------------------ UI ------------------------------------ */

  @override
  Widget build(BuildContext context) {
    final row = _row ?? const {};
    final status = _readStringAny(row, ['status']); // e.g. "For Adoption"
    final gender = _readStringAny(row, ['gender']) ?? 'Male';
    final age = _readStringAny(row, ['age', 'age_group']) ?? 'Senior';

    // Progress values (pull from row if you later add columns like goal/raised)
    // Fallback demo values for now:
    final double goal = _readNumAny(row, ['goal_amount']) ?? 10000.0;
    final double raised = _readNumAny(row, ['raised_amount']) ?? 3500.0;
    final double progress = (raised / (goal <= 0 ? 1 : goal))
        .clamp(0.0, 1.0)
        .toDouble();

    // Quick facts (Age/Breed/Gender row)
    final petInfo = {"Age": age, "Breed": widget.breed, "Gender": gender};

    // Dynamic chips from the loaded row
    final chips = <_ChipData>[];
    if ((status ?? '').toLowerCase().contains('adopt')) {
      chips.add(_ChipData('For Adoption', Icons.home));
    }
    if (_readBoolAny(row, ['vaccination', 'vaccinated', 'is_vaccinated'])) {
      chips.add(_ChipData('Vaccinated', Icons.vaccines));
    }
    if (_readBoolAny(row, ['surgery', 'needs_surgery', 'had_surgery'])) {
      chips.add(_ChipData('Surgery', Icons.healing));
    }
    if (_readBoolAny(row, [
      'needs_medical_care',
      'needs_treatment',
      'treatment_needed',
      'injury_treatment',
      'skin_treatment',
    ])) {
      chips.add(_ChipData('Needs Treatment', Icons.favorite));
    }
    if (_readBoolAny(row, [
      'spay_neuter',
      'spayed_neutered',
      'is_neutered',
      'is_spayed',
    ])) {
      chips.add(_ChipData('Spay/Neuter', Icons.pets));
    }

    void goDonate() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DonatePage(
            petId: widget.petId, // donate to THIS pet
            allowInKind: false, // flip to true if you want in-kind here
            autoAssignOpex: false,
            campaignTitle: widget.name, // just for header text on donate page
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
            onPressed: _loadPetRow,
            icon: const Icon(Icons.refresh, color: Colors.black87),
          ),
        ],
      ),

      /* --------- Gradient Donate FAB (center float), as requested --------- */
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
          ? _ErrorBox(message: _error!, onRetry: _loadPetRow)
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 96), // leave space for FAB
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header image
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: _isHttpImage
                          ? Image.network(
                              widget.image,
                              height: 280,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 280,
                                color: Colors.grey.shade300,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.pets,
                                  size: 56,
                                  color: Colors.white70,
                                ),
                              ),
                            )
                          : Image.asset(
                              widget.image,
                              height: 280,
                              width: double.infinity,
                              fit: BoxFit.cover,
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
                  const SizedBox(height: 20),

                  /* -------- PROGRESS (placed BEFORE chips, as requested) -------- */
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress, // <-- double
                            minHeight: 12,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF1F2C47),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "₱${raised.toStringAsFixed(0)} raised of ₱${goal.toStringAsFixed(0)} goal",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2C47),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dynamic status chips (For Adoption, Vaccinated, etc.)
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
                          // fallback if no story in DB
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

                  const SizedBox(height: 120), // comfy bottom space
                ],
              ),
            ),
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
