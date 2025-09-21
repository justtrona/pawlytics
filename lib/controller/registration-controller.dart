import 'package:pawlytics/auth/auth_service.dart';
import 'package:pawlytics/model/register-model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/route/route.dart' as route;

class RegistrationCcontroller {
  final formKey = GlobalKey<FormState>();

  final fullNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpasswordController = TextEditingController();

  // role attribute
  String selectedRole = "donor"; // default role lang

  bool isHidden = true;
  bool isHiddenConfirm = true;

  final authService = AuthService();

  void togglePasswordVisibility(VoidCallback updateState) {
    updateState();
  }

  Future<void> performRegistration(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    try {
      final fullName = fullNameController.text.trim();
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      final phoneNumber = phoneNumberController.text.trim();

      final registerModel = RegisterModel(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        role: selectedRole,
        createdAt: DateTime.now(),
      );

      final AuthResponse response = await authService
          .signUpWithEmailAndPassword(registerModel);

      if (response.user != null) {
        final user = response.user!;

        if (user.emailConfirmedAt == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Account created! Please check your email to confirm before logging in.",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account confirmed! You can now log in."),
              backgroundColor: Colors.green,
            ),
          );
        }

        if (context.mounted) {
          Navigator.pushReplacementNamed(context, route.login);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Signup failed. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error"), backgroundColor: Colors.red),
      );
    }
  }

  // VALIDATORS

  String? validateField(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email Address is required.';
    }
    if (!RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    ).hasMatch(value)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone Number is required.';
    }
    if (value.length > 13) {
      return 'Phone Number must be less than 13 digits';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? validatedConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirm Password is required.';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  // CLEANUP
  void dispose() {
    fullNameController.dispose();
    phoneNumberController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmpasswordController.dispose();
  }
}
