// import 'package:flutter/material.dart';
// import 'package:pawlytics/views/admin/admin_widgets/navigation-buttons.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:pawlytics/auth/auth_service.dart';
// import 'package:pawlytics/route/route.dart' as route;

// class LoginController {
//   final formKey = GlobalKey<FormState>();

//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();

//   bool isHidden = true;
//   final authService = AuthService();

//   void togglePasswordVisibility(VoidCallback updateState) {
//     updateState();
//   }

//   Future<void> performLogin(BuildContext context) async {
//     if (!formKey.currentState!.validate()) return;

//     try {
//       final email = emailController.text.trim();
//       final password = passwordController.text.trim();

//       final AuthResponse response = await authService
//           .signInWithEmailAndPassword(email, password);

//       if (response.user != null) {
//         final user = response.user!;

//         if (user.emailConfirmedAt == null) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("Please confirm your email before logging in."),
//               backgroundColor: Colors.orange,
//             ),
//           );
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("Login successful!"),
//               backgroundColor: Colors.green,
//             ),
//           );

//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (_) => const NavigationButtonAdmin()),
//           );
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Login failed. Please check your credentials."),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (error) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: $error"), backgroundColor: Colors.red),
//       );
//     }
//   }

//   //  VALIDATORS

//   String? validateEmail(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Email Address is required.';
//     }
//     if (!RegExp(
//       r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
//     ).hasMatch(value)) {
//       return 'Enter a valid email address.';
//     }
//     return null;
//   }

//   String? validatePassword(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Password is required.';
//     }
//     if (value.length < 8) {
//       return 'Password must be at least 8 characters';
//     }
//     return null;
//   }

//   // CLEANUP
//   void dispose() {
//     emailController.dispose();
//     passwordController.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/auth/auth_service.dart';
import 'package:pawlytics/route/route.dart' as route;

class LoginController {
  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isHidden = true;
  final authService = AuthService();

  Future<void> performLogin(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      final AuthResponse response = await authService
          .signInWithEmailAndPassword(email, password);

      final user = response.user;
      if (user == null) {
        _toast(
          context,
          "Login failed. Please check your credentials.",
          Colors.red,
        );
        return;
      }

      if (user.emailConfirmedAt == null) {
        _toast(
          context,
          "Please confirm your email before logging in.",
          Colors.orange,
        );
        return;
      }

      // ---- ROLE LOOKUP FROM user_metadata ----
      final meta = user.userMetadata ?? {};
      final rawRole = (meta['role'] ?? '').toString().toLowerCase();

      // Fallback to donor if missing/unknown
      final uid = Supabase.instance.client.auth.currentUser!.id;
      final row = await Supabase.instance.client
          .from('registration')
          .select('role')
          .eq('id', uid)
          .maybeSingle();

      final role = (row?['role'] ?? 'donor').toString().toLowerCase();
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, route.navigationButtonAdmin);
      } else {
        Navigator.pushReplacementNamed(context, route.routePage);
      }
    } catch (error) {
      _toast(context, "Error: $error", Colors.red);
    }
  }

  // VALIDATORS
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email Address is required.';
    final re = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!re.hasMatch(value)) return 'Enter a valid email address.';
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
  }

  void _toast(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }
}
