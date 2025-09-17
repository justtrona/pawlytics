// import 'package:flutter/material.dart';
// import 'package:pawlytics/views/admin/model/pet-profiles.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class PetProfileController {
//   final TextEditingController nameController = TextEditingController();

//   PetProfile petProfile = PetProfile(
//     name: '',
//     species: 'Dog',
//     ageGroup: 'Puppy/Kitten',
//     status: 'For Adoption',
//     surgery: false,
//     dentalCare: false,
//     vaccination: false,
//     injuryTreatment: false,
//     deworming: false,
//     skinTreatment: false,
//     spayNeuter: false,
//   );

//   void dispose() => nameController.dispose();

//   void updateName() => petProfile = petProfile.copyWith(name: nameController.text);
//   void updateSpecies(String value) => petProfile = petProfile.copyWith(species: value);
//   void updateAgeGroup(String value) => petProfile = petProfile.copyWith(ageGroup: value);
//   void updateStatus(String value) => petProfile = petProfile.copyWith(status: value);

//   void toggleSurgery(bool value) => petProfile = petProfile.copyWith(surgery: value);
//   void toggleDentalCare(bool value) => petProfile = petProfile.copyWith(dentalCare: value);
//   void toggleVaccination(bool value) => petProfile = petProfile.copyWith(vaccination: value);
//   void toggleInjuryTreatment(bool value) => petProfile = petProfile.copyWith(injuryTreatment: value);
//   void toggleDeworming(bool value) => petProfile = petProfile.copyWith(deworming: value);
//   void toggleSkinTreatment(bool value) => petProfile = petProfile.copyWith(skinTreatment: value);
//   void toggleSpayNeuter(bool value) => petProfile = petProfile.copyWith(spayNeuter: value);

//   /// ← Insert this getter here, replacing any previous insertPayload or toMapInsert
//   Map<String, dynamic> get insertPayload => {
//         'name': petProfile.name,
//         'species': petProfile.species,
//         'age_group': petProfile.ageGroup,
//         'status': petProfile.status,
//         'surgery': petProfile.surgery ? 1 : 0,
//         'dental_care': petProfile.dentalCare ? 1 : 0,
//         'vaccination': petProfile.vaccination ? 1 : 0,
//         'injury_treatment': petProfile.injuryTreatment ? 1 : 0,
//         'deworming': petProfile.deworming ? 1 : 0,
//         'skin_treatment': petProfile.skinTreatment ? 1 : 0,
//         'spay_neuter': petProfile.spayNeuter ? 1 : 0,
//       };

//   Future<bool> savePet() async {
//     updateName();

//     try {
//       final inserted = await Supabase.instance.client
//           .from('pet_profiles')
//           .insert(insertPayload)
//           .select()
//           .maybeSingle();

//       if (inserted == null) return false;

//       petProfile = PetProfile.fromMap(inserted as Map<String, dynamic>);
//       return true;
//     } catch (e, st) {
//       debugPrint("Save pet error: $e\n$st");
//       return false;
//     }
//   }
// }


import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/model/pet-profiles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PetProfileController {
  final TextEditingController nameController = TextEditingController();

  PetProfile petProfile = PetProfile(
    name: 'Peter',
    species: 'cat',
    ageGroup: 'Adult',
    status: 'For Adoption',
  );

  void dispose() => nameController.dispose();

  void updateName() =>
      petProfile = petProfile.copyWith(name: nameController.text);
  void updateSpecies(String value) =>
      petProfile = petProfile.copyWith(species: value);
  void updateAgeGroup(String value) =>
      petProfile = petProfile.copyWith(ageGroup: value);
  void updateStatus(String value) =>
      petProfile = petProfile.copyWith(status: value);

  void toggleSurgery(bool value) =>
      petProfile = petProfile.copyWith(surgery: value);
  void toggleDentalCare(bool value) =>
      petProfile = petProfile.copyWith(dentalCare: value);
  void toggleVaccination(bool value) =>
      petProfile = petProfile.copyWith(vaccination: value);
  void toggleInjuryTreatment(bool value) =>
      petProfile = petProfile.copyWith(injuryTreatment: value);
  void toggleDeworming(bool value) =>
      petProfile = petProfile.copyWith(deworming: value);
  void toggleSkinTreatment(bool value) =>
      petProfile = petProfile.copyWith(skinTreatment: value);
  void toggleSpayNeuter(bool value) =>
      petProfile = petProfile.copyWith(spayNeuter: value);

  Future<bool> savePet() async {
    updateName();

    final payload = petProfile.toMapInsert();

    try {
      final inserted = await Supabase.instance.client
          .from('pet_profiles')
          .insert(payload)
          .select()
          .maybeSingle();

      String? newId;

      if (inserted == null) {
        newId = null;
      } else if (inserted is Map) {
        newId = inserted['id']?.toString();
      } else if (inserted is List && inserted.isNotEmpty) {
        final first = inserted[0];
        if (first is Map) newId = first['id']?.toString();
      }

      // only set id if we successfully found one
      if (newId != null && newId.isNotEmpty) {
        petProfile = petProfile.copyWith(id: newId);
      }

      return true; // if nag success
    } catch (e) {
      debugPrint("Save pet error: $e");
      return false; // failed
    }
  }
}
