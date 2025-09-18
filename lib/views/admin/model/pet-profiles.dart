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
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// // lib/models/pet_profile.dart
// // lib/models/pet_profile.dart
// class PetProfile {
//   final String? id; // nullable so we can create before DB assigns id
//   final String name;
//   final String species;
//   final String ageGroup;
//   final String status;

//   final bool surgery;
//   final bool dentalCare;
//   final bool vaccination;
//   final bool injuryTreatment;
//   final bool deworming;
//   final bool skinTreatment;
//   final bool spayNeuter;

//   PetProfile({
//     this.id,
//     required this.name,
//     required this.species,
//     required this.ageGroup,
//     required this.status,
//     this.surgery = false,
//     this.dentalCare = false,
//     this.vaccination = false,
//     this.injuryTreatment = false,
//     this.deworming = false,
//     this.skinTreatment = false,
//     this.spayNeuter = false,
//   });

//   // Convert DB row -> object (handles 0/1 or true/false)
//   factory PetProfile.fromMap(Map<String, dynamic> map) {
//     bool _toBool(dynamic v) => v == 1 || v == '1' || v == true || v == 'true';

//     return PetProfile(
//       id: map['id']?.toString(),
//       name: map['name'] ?? '',
//       species: map['species'] ?? '',
//       ageGroup: map['age_group'] ?? '',
//       status: map['status'] ?? '',
//       surgery: _toBool(map['surgery']),
//       dentalCare: _toBool(map['dental_care']),
//       vaccination: _toBool(map['vaccination']),
//       injuryTreatment: _toBool(map['injury_treatment']),
//       deworming: _toBool(map['deworming']),
//       skinTreatment: _toBool(map['skin_treatment']),
//       spayNeuter: _toBool(map['spay_neuter']),
//     );
//   }

//   // For insert (exclude id)
//   Map<String, dynamic> toMapInsert() {
//     return {
//       'name': name,
//       'species': species,
//       'age_group': ageGroup,
//       'status': status,
//       'surgery': surgery ? 1 : 0,
//       'dental_care': dentalCare ? 1 : 0,
//       'vaccination': vaccination ? 1 : 0,
//       'injury_treatment': injuryTreatment ? 1 : 0,
//       'deworming': deworming ? 1 : 0,
//       'skin_treatment': skinTreatment ? 1 : 0,
//       'spay_neuter': spayNeuter ? 1 : 0,
//     };
//   }

//   // Full map (include id) - useful for updates
//   Map<String, dynamic> toMap() {
//     final m = toMapInsert();
//     if (id != null) m['id'] = id;
//     return m;
//   }

//   PetProfile copyWith({
//     String? id,
//     String? name,
//     String? species,
//     String? ageGroup,
//     String? status,
//     bool? surgery,
//     bool? dentalCare,
//     bool? vaccination,
//     bool? injuryTreatment,
//     bool? deworming,
//     bool? skinTreatment,
//     bool? spayNeuter,
//   }) {
//     return PetProfile(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       species: species ?? this.species,
//       ageGroup: ageGroup ?? this.ageGroup,
//       status: status ?? this.status,
//       surgery: surgery ?? this.surgery,
//       dentalCare: dentalCare ?? this.dentalCare,
//       vaccination: vaccination ?? this.vaccination,
//       injuryTreatment: injuryTreatment ?? this.injuryTreatment,
//       deworming: deworming ?? this.deworming,
//       skinTreatment: skinTreatment ?? this.skinTreatment,
//       spayNeuter: spayNeuter ?? this.spayNeuter,
//     );
//   }
// }

// class PetProfile {
//   String? id; // make it nullable since DB can auto-generate
//   String name;
//   String species;
//   String ageGroup;
//   String status;

//   int surgery;
//   int dentalCare;
//   int vaccination;
//   int injuryTreatment;
//   int deworming;
//   int skinTreatment;
//   int spayNeuter;

//   PetProfile({
//     this.id,
//     required this.name,
//     required this.species,
//     required this.ageGroup,
//     required this.status,
//     this.surgery = 0,
//     this.dentalCare = 0,
//     this.vaccination = 0,
//     this.injuryTreatment = 0,
//     this.deworming = 0,
//     this.skinTreatment = 0,
//     this.spayNeuter = 0,
//   });

//   // Convert from DB row → Dart object
//   factory PetProfile.fromMap(Map<String, dynamic> map) {
//     return PetProfile(
//       id: map['id'],
//       name: map['name'],
//       species: map['species'],
//       ageGroup: map['age_group'],
//       status: map['status'],
//       surgery: map['surgery'] ?? 0,
//       dentalCare: map['dental_care'] ?? 0,
//       vaccination: map['vaccination'] ?? 0,
//       injuryTreatment: map['injury_treatment'] ?? 0,
//       deworming: map['deworming'] ?? 0,
//       skinTreatment: map['skin_treatment'] ?? 0,
//       spayNeuter: map['spay_neuter'] ?? 0,
//     );
//   }

//   // For updates (includes id)
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'species': species,
//       'age_group': ageGroup,
//       'status': status,
//       'surgery': surgery,
//       'dental_care': dentalCare,
//       'vaccination': vaccination,
//       'injury_treatment': injuryTreatment,
//       'deworming': deworming,
//       'skin_treatment': skinTreatment,
//       'spay_neuter': spayNeuter,
//     };
//   }

//   // For insert (excludes id)
//   Map<String, dynamic> toMapInsert() {
//     return {
//       'name': name,
//       'species': species,
//       'age_group': ageGroup,
//       'status': status,
//       'surgery': surgery,
//       'dental_care': dentalCare,
//       'vaccination': vaccination,
//       'injury_treatment': injuryTreatment,
//       'deworming': deworming,
//       'skin_treatment': skinTreatment,
//       'spay_neuter': spayNeuter,
//     };
//   }

//   // copyWith for updates
//   PetProfile copyWith({
//     String? name,
//     String? species,
//     String? ageGroup,
//     String? status,
//     int? surgery,
//     int? dentalCare,
//     int? vaccination,
//     int? injuryTreatment,
//     int? deworming,
//     int? skinTreatment,
//     int? spayNeuter,
//   }) {
//     return PetProfile(
//       id: id,
//       name: name ?? this.name,
//       species: species ?? this.species,
//       ageGroup: ageGroup ?? this.ageGroup,
//       status: status ?? this.status,
//       surgery: surgery ?? this.surgery,
//       dentalCare: dentalCare ?? this.dentalCare,
//       vaccination: vaccination ?? this.vaccination,
//       injuryTreatment: injuryTreatment ?? this.injuryTreatment,
//       deworming: deworming ?? this.deworming,
//       skinTreatment: skinTreatment ?? this.skinTreatment,
//       spayNeuter: spayNeuter ?? this.spayNeuter,
//     );
//   }
// }

// class PetProfile {
//   String id;
//   String name;
//   String species;
//   String ageGroup;
//   String status;

//   bool surgery;
//   bool dentalCare;
//   bool vaccination;
//   bool injuryTreatment;
//   bool deworming;
//   bool skinTreatment;
//   bool spayNeuter;

//   PetProfile({
//     required this.id,
//     required this.name,
//     required this.species,
//     required this.ageGroup,
//     required this.status,
//     this.surgery = false,
//     this.dentalCare = false,
//     this.vaccination = false,
//     this.injuryTreatment = false,
//     this.deworming = false,
//     this.skinTreatment = false,
//     this.spayNeuter = false,
//   });

//   PetProfile copyWith({
//     String? id,
//     String? name,
//     String? species,
//     String? ageGroup,
//     String? status,
//     bool? surgery,
//     bool? dentalCare,
//     bool? vaccination,
//     bool? injuryTreatment,
//     bool? deworming,
//     bool? skinTreatment,
//     bool? spayNeuter,
//   }) {
//     return PetProfile(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       species: species ?? this.species,
//       ageGroup: ageGroup ?? this.ageGroup,
//       status: status ?? this.status,
//       surgery: surgery ?? this.surgery,
//       dentalCare: dentalCare ?? this.dentalCare,
//       vaccination: vaccination ?? this.vaccination,
//       injuryTreatment: injuryTreatment ?? this.injuryTreatment,
//       deworming: deworming ?? this.deworming,
//       skinTreatment: skinTreatment ?? this.skinTreatment,
//       spayNeuter: spayNeuter ?? this.spayNeuter,
//     );
//   }
// }

// lib/models/pet_profile.dart
// class PetProfile {
//   String id;
//   String name;
//   String species;
//   String ageGroup;
//   String status;

//   // Health & care needs (1 = true, 0 = false in DB)
//   bool surgery;
//   bool dentalCare;
//   bool vaccination;
//   bool injuryTreatment;
//   bool deworming;
//   bool skinTreatment;
//   bool spayNeuter;

//   PetProfile({
//     required this.id,
//     required this.name,
//     required this.species,
//     required this.ageGroup,
//     required this.status,
//     this.surgery = false,
//     this.dentalCare = false,
//     this.vaccination = false,
//     this.injuryTreatment = false,
//     this.deworming = false,
//     this.skinTreatment = false,
//     this.spayNeuter = false,
//   });

//   factory PetProfile.fromMap(Map<String, dynamic> map) {
//     return PetProfile(
//       id: map['id'],
//       name: map['name'],
//       species: map['species'],
//       ageGroup: map['age_group'],
//       status: map['status'],
//       surgery: map['surgery'] == 1,
//       dentalCare: map['dental_care'] == 1,
//       vaccination: map['vaccination'] == 1,
//       injuryTreatment: map['injury_treatment'] == 1,
//       deworming: map['deworming'] == 1,
//       skinTreatment: map['skin_treatment'] == 1,
//       spayNeuter: map['spay_neuter'] == 1,
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'species': species,
//       'age_group': ageGroup,
//       'status': status,
//       'surgery': surgery ? 1 : 0,
//       'dental_care': dentalCare ? 1 : 0,
//       'vaccination': vaccination ? 1 : 0,
//       'injury_treatment': injuryTreatment ? 1 : 0,
//       'deworming': deworming ? 1 : 0,
//       'skin_treatment': skinTreatment ? 1 : 0,
//       'spay_neuter': spayNeuter ? 1 : 0,
//     };
//   }
// }

// class PetProfile {
//   String id;
//   String name;
//   String species;
//   String ageGroup;
//   String status;

//   int surgery;
//   int dentalCare;
//   int vaccination;
//   int injuryTreatment;
//   int deworming;
//   int skinTreatment;
//   int spayNeuter;

//   PetProfile({
//     required this.id,
//     required this.name,
//     required this.species,
//     required this.ageGroup,
//     required this.status,
//     this.surgery = 0,
//     this.dentalCare = 0,
//     this.vaccination = 0,
//     this.injuryTreatment = 0,
//     this.deworming = 0,
//     this.skinTreatment = 0,
//     this.spayNeuter = 0,
//   });

//   factory PetProfile.fromMap(Map<String, dynamic> map) {
//     return PetProfile(
//       id: map['id'],
//       name: map['name'],
//       species: map['species'],
//       ageGroup: map['age_group'],
//       status: map['status'],
//       surgery: map['surgery'],
//       dentalCare: map['dental_care'],
//       vaccination: map['vaccination'],
//       injuryTreatment: map['injury_treatment'],
//       deworming: map['deworming'],
//       skinTreatment: map['skin_treatment'],
//       spayNeuter: map['spay_neuter'],
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'species': species,
//       'age_group': ageGroup,
//       'status': status,
//       'surgery': surgery,
//       'dental_care': dentalCare,
//       'vaccination': vaccination,
//       'injury_treatment': injuryTreatment,
//       'deworming': deworming,
//       'skin_treatment': skinTreatment,
//       'spay_neuter': spayNeuter,
//     };
//   }

//   PetProfile copyWith({
//     String? id,
//     String? name,
//     String? species,
//     String? ageGroup,
//     String? status,
//     int? surgery,
//     int? dentalCare,
//     int? vaccination,
//     int? injuryTreatment,
//     int? deworming,
//     int? skinTreatment,
//     int? spayNeuter,
//   }) {
//     return PetProfile(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       species: species ?? this.species,
//       ageGroup: ageGroup ?? this.ageGroup,
//       status: status ?? this.status,
//       surgery: surgery ?? this.surgery,
//       dentalCare: dentalCare ?? this.dentalCare,
//       vaccination: vaccination ?? this.vaccination,
//       injuryTreatment: injuryTreatment ?? this.injuryTreatment,
//       deworming: deworming ?? this.deworming,
//       skinTreatment: skinTreatment ?? this.skinTreatment,
//       spayNeuter: spayNeuter ?? this.spayNeuter,
//     );
//   }
// }
