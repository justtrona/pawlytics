import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/model/register-model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmailAndPassword(
    RegisterModel userModel,
  ) async {
    final response = await _supabase.auth.signUp(
      email: userModel.email,
      password: userModel.password,
      data: {
        'fullName': userModel.fullName,
        'phone_number': userModel.phoneNumber,
      },
    );

    final user = response.user;
    if (user == null) {
      throw Exception("Signup failed: User not created.");
    }

    await _supabase.from('registration').insert({
      'id': user.id, // same as Supabase Auth user ID
      'fullName': userModel.fullName,
      'email': userModel.email,
      'phone_number': userModel.phoneNumber,
      'created_at': userModel.createdAt.toIso8601String(),
    });

    return response;
  }

  Future<void> signOut() async {
    return await _supabase.auth.signOut();
  }

  Future<void> updateUserName(String fullName) async {
    await _supabase.auth.updateUser(
      UserAttributes(data: {'fullName': fullName}),
    );

    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase
          .from('registration')
          .update({'fullName': fullName})
          .eq('id', user.id);
    }
  }

  Future<RegisterModel?> getUserProfile(String userId) async {
    final data = await _supabase
        .from('registration')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return RegisterModel.fromMap(data);
  }

  User? get currentUser => _supabase.auth.currentUser;

  /// 🔥 Stream that listens for auth state changes
  Stream<User?> get currentUserStream =>
      _supabase.auth.onAuthStateChange.map((event) => event.session?.user);
}

























// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:pawlytics/model/register-model.dart';

// class AuthService {
//   final SupabaseClient _supabase = Supabase.instance.client;

//   Future<AuthResponse> signInWithEmailAndPassword(
//     String email,
//     String password,
//   ) async {
//     return await _supabase.auth.signInWithPassword(
//       email: email,
//       password: password,
//     );
//   }

//   Future<AuthResponse> signUpWithEmailAndPassword(
//     RegisterModel userModel,
//   ) async {
//     // 1. Create user in Supabase Auth
//     final response = await _supabase.auth.signUp(
//       email: userModel.email,
//       password: userModel.password,
//       data: {
//         'fullName': userModel.fullName,
//         'phone_number': userModel.phoneNumber,
//       },
//     );

//     final user = response.user;
//     if (user == null) {
//       throw Exception("Signup failed: User not created.");
//     }

//     // 2. Insert profile into registration table
//     await _supabase.from('registration').insert({
//       'id': user.id, // FK to auth.users.id
//       'fullName': userModel.fullName,
//       'email': userModel.email,
//       'phone_number': userModel.phoneNumber,
//       'created_at': userModel.createdAt.toIso8601String(),
//     });

//     return response;
//   }

//   Future<void> signOut() async {
//     return await _supabase.auth.signOut();
//   }

//   Future<void> updateUserName(String fullName) async {
//     // Update metadata in auth.users
//     await _supabase.auth.updateUser(
//       UserAttributes(data: {'fullName': fullName}),
//     );

//     final user = _supabase.auth.currentUser;
//     if (user != null) {
//       // Update registration table
//       await _supabase
//           .from('registration')
//           .update({'fullName': fullName})
//           .eq('id', user.id);
//     }
//   }

//   Future<RegisterModel?> getUserProfile(String userId) async {
//     final data = await _supabase
//         .from('registration')
//         .select()
//         .eq('id', userId)
//         .maybeSingle();

//     if (data == null) return null;
//     return RegisterModel.fromMap(data);
//   }
  
//   User? get currentUser => _supabase.auth.currentUser;
// }


// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:pawlytics/model/register-model.dart';

// class AuthService {
//   final SupabaseClient _supabase = Supabase.instance.client;


//   Future<AuthResponse> signInWithEmailAndPassword(
//     String email,
//     String password,
//   ) async {
//     return await _supabase.auth.signInWithPassword(
//       email: email,
//       password: password,
//     );
//   }

//   Future<AuthResponse> signUpWithEmailAndPassword(
//     RegisterModel userModel,
//   ) async {
//     final response = await _supabase.auth.signUp(
//       email: userModel.email,
//       password: userModel.password,
//       data: {
//         'fullName': userModel.fullName,
//         'phone_number': userModel.phoneNumber,
//       },
//     );

//     final user = response.user;
//     if (user == null) {
//       throw Exception("Signup failed: User not created.");
//     }

//     await _supabase.from('registration').insert({
//       'id': user.id, // same as Supabase Auth user ID
//       'fullName': userModel.fullName,
//       'email': userModel.email,
//       'phone_number': userModel.phoneNumber,
//       'created_at': userModel.createdAt.toIso8601String(),
//     });

//     return response;
//   }

//   Future<void> signOut() async {
//     return await _supabase.auth.signOut();
//   }

//   Future<void> updateUserName(String fullName) async {
//     await _supabase.auth.updateUser(
//       UserAttributes(data: {'fullName': fullName}),
//     );

//     final user = _supabase.auth.currentUser;
//     if (user != null) {
//       await _supabase
//           .from('registration')
//           .update({'fullName': fullName})
//           .eq('id', user.id);
//     }
//   }

//   Future<RegisterModel?> getUserProfile(String userId) async {
//     final data = await _supabase
//         .from('registration')
//         .select()
//         .eq('id', userId)
//         .maybeSingle();

//     if (data == null) return null;
//     return RegisterModel.fromMap(data);
//   }
  
//   User? get currentUser => _supabase.auth.currentUser;
// }

