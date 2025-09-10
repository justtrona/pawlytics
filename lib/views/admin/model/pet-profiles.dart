// lib/models/pet_profile.dart

class PetProfile {
  String name;
  String species;
  String ageGroup;
  String status;
  Map<String, bool> healthNeeds;

  PetProfile({
    required this.name,
    required this.species,
    required this.ageGroup,
    required this.status,
    required this.healthNeeds,
  });

  PetProfile copyWith({
    String? name,
    String? species,
    String? ageGroup,
    String? status,
    Map<String, bool>? healthNeeds,
  }) {
    return PetProfile(
      name: name ?? this.name,
      species: species ?? this.species,
      ageGroup: ageGroup ?? this.ageGroup,
      status: status ?? this.status,
      healthNeeds: healthNeeds ?? Map.from(this.healthNeeds),
    );
  }
}
