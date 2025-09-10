// lib/controllers/pet_profile_controller.dart

import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/model/pet-profiles.dart';

class PetProfileController {
  final TextEditingController nameController = TextEditingController();

  PetProfile petProfile = PetProfile(
    name: 'Peter',
    species: 'Dog',
    ageGroup: 'Senior',
    status: 'For Adoption',
    healthNeeds: {
      'Surgery': true,
      'Deworming': false,
      'Dental Care': true,
      'Skin Treatment': false,
      'Vaccination': true,
      'Spay/Neuter': true,
      'Injury Treatment': false,
    },
  );

  void dispose() {
    nameController.dispose();
  }

  void updateSpecies(String species) {
    petProfile = petProfile.copyWith(species: species);
  }

  void updateAgeGroup(String ageGroup) {
    petProfile = petProfile.copyWith(ageGroup: ageGroup);
  }

  void updateStatus(String status) {
    petProfile = petProfile.copyWith(status: status);
  }

  void toggleHealthNeed(String key, bool value) {
    final newNeeds = Map<String, bool>.from(petProfile.healthNeeds);
    newNeeds[key] = value;
    petProfile = petProfile.copyWith(healthNeeds: newNeeds);
  }

  void updateName() {
    petProfile = petProfile.copyWith(name: nameController.text);
  }
}
