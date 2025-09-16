import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/controller/registration-controller.dart';
import 'package:pawlytics/auth/auth_service.dart';
import 'package:pawlytics/route/route.dart' as route;

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final RegistrationCcontroller registrationCcontroller =
      RegistrationCcontroller();
  final AuthService authService = AuthService();

  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();

    // 🔥 Listen for auth state changes (redirect when confirmed)
    _authStream = authService.currentUserStream;
    _authStream.listen((user) {
      if (user != null && user.emailConfirmedAt != null) {
        Navigator.pushReplacementNamed(context, route.login);
      }
    });
  }

  @override
  void dispose() {
    registrationCcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: SizedBox(
          height: 40,
          width: 40,
          child: Image.asset(
            'assets/images/small_logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: registrationCcontroller.formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 30),
                  Text(
                    'SIGN UP',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                  Text(
                    'Together, we care. Join now.',
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey[700]),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(35.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller:
                              registrationCcontroller.fullNameController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.person),
                            labelText: 'Full Name',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)),
                            ),
                          ),
                          validator: (value) => registrationCcontroller
                              .validateField(value, 'Full Name'),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller:
                              registrationCcontroller.phoneNumberController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.phone),
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)),
                            ),
                          ),
                          validator:
                              registrationCcontroller.validatePhoneNumber,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: registrationCcontroller.emailController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.email),
                            labelText: 'Email Address',
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)),
                            ),
                          ),
                          validator: registrationCcontroller.validateEmail,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller:
                              registrationCcontroller.passwordController,
                          obscureText: registrationCcontroller.isHidden,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  registrationCcontroller.isHidden =
                                      !registrationCcontroller.isHidden;
                                });
                              },
                              icon: Icon(
                                registrationCcontroller.isHidden
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                            labelText: 'Password',
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)),
                            ),
                          ),
                          validator: registrationCcontroller.validatePassword,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: registrationCcontroller.confirmpasswordController,
                          obscureText: registrationCcontroller.isHiddenConfirm,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  registrationCcontroller.isHiddenConfirm =
                                      !registrationCcontroller.isHiddenConfirm;
                                });
                              },
                              icon: Icon(
                                registrationCcontroller.isHiddenConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                            prefixIcon: const Icon(Icons.lock),
                            labelText: 'Confirm Password',
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)),
                            ),
                          ),
                          validator:
                              registrationCcontroller.validatedConfirmPassword,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35.0),
                    child: ElevatedButton(
                      onPressed: () async =>
                          registrationCcontroller.performRegistration(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff27374d),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text(
                        'SIGN UP',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, route.login),
                        child: const Text(
                          ' Sign In',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
