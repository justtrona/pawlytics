// lib/views/admin/model/pet-profiles.dart
import 'package:flutter/foundation.dart';

class PetProfile {
  /// Some databases have both `id` and `uuid`. We'll capture both and
  /// use whichever is present via [dbId].
  final String? id;
  final String? uuid;

  final String name;
  final String species;
  final String ageGroup;
  final String status;

  final bool surgery;
  final bool dentalCare;
  final bool vaccination;
  final bool injuryTreatment;
  final bool deworming;
  final bool skinTreatment;
  final bool spayNeuter;

  final String? imageUrl;
  final String? story;
  final DateTime? createdAt;

  /// Optional: total funds raised from `pet_profiles.funds`
  final double? funds;

  /// Prefer this for queries: falls back to `uuid` if `id` is null.
  String? get dbId => id ?? uuid;

  PetProfile({
    this.id,
    this.uuid,
    required this.name,
    required this.species,
    required this.ageGroup,
    required this.status,
    this.surgery = false,
    this.dentalCare = false,
    this.vaccination = false,
    this.injuryTreatment = false,
    this.deworming = false,
    this.skinTreatment = false,
    this.spayNeuter = false,
    this.imageUrl,
    this.story,
    this.createdAt,
    this.funds,
  });

  factory PetProfile.fromMap(Map<String, dynamic> map) {
    bool _toBool(dynamic v) => v == 1 || v == '1' || v == true || v == 'true';
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return PetProfile(
      // accept either column name
      id: (map['id'] ?? map['uuid'])?.toString(),
      uuid: map['uuid']?.toString(),
      name: (map['name'] ?? '').toString(),
      species: (map['species'] ?? '').toString(),
      ageGroup: (map['age_group'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      surgery: _toBool(map['surgery']),
      dentalCare: _toBool(map['dental_care']),
      vaccination: _toBool(map['vaccination']),
      injuryTreatment: _toBool(map['injury_treatment']),
      deworming: _toBool(map['deworming']),
      skinTreatment: _toBool(map['skin_treatment']),
      spayNeuter: _toBool(map['spay_neuter']),
      imageUrl: map['image']?.toString(),
      story: map['story']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      funds: _toDouble(map['funds']),
    );
  }

  Map<String, dynamic> toMapInsert() {
    return {
      'name': name,
      'species': species,
      'age_group': ageGroup,
      'status': status,
      'surgery': surgery ? 1 : 0,
      'dental_care': dentalCare ? 1 : 0,
      'vaccination': vaccination ? 1 : 0,
      'injury_treatment': injuryTreatment ? 1 : 0,
      'deworming': deworming ? 1 : 0,
      'skin_treatment': skinTreatment ? 1 : 0,
      'spay_neuter': spayNeuter ? 1 : 0,
      'image': imageUrl,
      'story': story,
      // Usually you don't insert `funds` manually; omit unless you need to.
    };
  }

  Map<String, dynamic> toMap() {
    final m = toMapInsert();
    if (id != null) m['id'] = id;
    if (createdAt != null) m['created_at'] = createdAt!.toIso8601String();
    // Do not write `uuid` by default; your DB should manage this.
    return m;
  }

  PetProfile copyWith({
    String? id,
    String? uuid,
    String? name,
    String? species,
    String? ageGroup,
    String? status,
    bool? surgery,
    bool? dentalCare,
    bool? vaccination,
    bool? injuryTreatment,
    bool? deworming,
    bool? skinTreatment,
    bool? spayNeuter,
    String? imageUrl,
    String? story,
    DateTime? createdAt,
    double? funds,
  }) {
    return PetProfile(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      species: species ?? this.species,
      ageGroup: ageGroup ?? this.ageGroup,
      status: status ?? this.status,
      surgery: surgery ?? this.surgery,
      dentalCare: dentalCare ?? this.dentalCare,
      vaccination: vaccination ?? this.vaccination,
      injuryTreatment: injuryTreatment ?? this.injuryTreatment,
      deworming: deworming ?? this.deworming,
      skinTreatment: skinTreatment ?? this.skinTreatment,
      spayNeuter: spayNeuter ?? this.spayNeuter,
      imageUrl: imageUrl ?? this.imageUrl,
      story: story ?? this.story,
      createdAt: createdAt ?? this.createdAt,
      funds: funds ?? this.funds,
    );
  }
}
