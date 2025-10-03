// lib/views/admin/model/pet-profiles.dart
import 'package:flutter/foundation.dart';

class PetProfile {
  final String? id;
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
  final String? story; // 👈 NEW
  final DateTime? createdAt;

  PetProfile({
    this.id,
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
    this.story, // 👈 NEW
    this.createdAt,
  });

  factory PetProfile.fromMap(Map<String, dynamic> map) {
    bool _toBool(dynamic v) => v == 1 || v == '1' || v == true || v == 'true';

    return PetProfile(
      id: map['id']?.toString(),
      name: map['name'] ?? '',
      species: map['species'] ?? '',
      ageGroup: map['age_group'] ?? '',
      status: map['status'] ?? '',
      surgery: _toBool(map['surgery']),
      dentalCare: _toBool(map['dental_care']),
      vaccination: _toBool(map['vaccination']),
      injuryTreatment: _toBool(map['injury_treatment']),
      deworming: _toBool(map['deworming']),
      skinTreatment: _toBool(map['skin_treatment']),
      spayNeuter: _toBool(map['spay_neuter']),
      imageUrl: map['image'],
      story: map['story']?.toString(), // 👈 NEW
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
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
      'story': story, // 👈 NEW
    };
  }

  Map<String, dynamic> toMap() {
    final m = toMapInsert();
    if (id != null) m['id'] = id;
    if (createdAt != null) m['created_at'] = createdAt!.toIso8601String();
    return m;
  }

  PetProfile copyWith({
    String? id,
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
    String? story, // 👈 NEW
    DateTime? createdAt,
  }) {
    return PetProfile(
      id: id ?? this.id,
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
      story: story ?? this.story, // 👈 NEW
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
