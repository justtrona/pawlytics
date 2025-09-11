// lib/models/pet_profile.dart

import 'package:flutter/foundation.dart';

class PetProfile {
  String id;
  String name;
  String species;
  String ageGroup;
  String status;
  Map<String, bool> healthNeeds;

  PetProfile({
    required this.id,
    required this.name,
    required this.species,
    required this.ageGroup,
    required this.status,
    required this.healthNeeds,
  });

  // Map
  factory PetProfile.fromMap(Map<String, dynamic> map) {
    return PetProfile(
      id: map['id'],
      name: map['name'],
      species: map['species'],
      ageGroup: map['ageGroup'],
      status: map['status'],
      healthNeeds: Map<String, bool>.from(map['healthNeeds']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'ageGroup': ageGroup,
      'status': status,
      'healthNeeds': healthNeeds,
    };
  }

  //copywith
  PetProfile copyWith({
    String? name,
    String? species,
    String? ageGroup,
    String? status,
    Map<String, bool>? healthNeeds,
  }) {
    return PetProfile(
      id: id,
      name: name ?? this.name,
      species: species ?? this.species,
      ageGroup: ageGroup ?? this.ageGroup,
      status: status ?? this.status,
      healthNeeds: healthNeeds ?? Map.from(this.healthNeeds),
    );
  }
}
