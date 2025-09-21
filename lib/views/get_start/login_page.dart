import 'package:flutter/material.dart';
import 'package:pawlytics/controller/login-controller.dart';
import 'package:pawlytics/route/route.dart' as route;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginController _controller = LoginController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white, centerTitle: true),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: Image.asset(
                'assets/images/PawLOGO.png',
                fit: BoxFit.cover,
              ),
            ),
            spacing(),
            Column(
              children: [
                Text(
                  'SIGN IN',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
                ),
                Text(
                  'Welcome back, hero of hope.',
                  style: TextStyle(fontSize: 16, color: Colors.blueGrey[700]),
                ),

                Padding(
                  padding: const EdgeInsets.all(35.0),
                  child: Form(
                    key: _controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email),
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          validator: _controller.validateEmail,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _controller.passwordController,
                          obscureText: _controller.isHidden,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock),
                            labelText: 'Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _controller.isHidden
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _controller.isHidden = !_controller.isHidden;
                                });
                              },
                            ),
                          ),
                          validator: _controller.validatePassword,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            spacing(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35.0),
              child: ElevatedButton(
                onPressed: () => _controller.performLogin(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff27374d),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text(
                  'SIGN IN',
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
                Text(
                  'Don\'t have an account?',
                  style: TextStyle(fontSize: 15, color: Colors.black),
                ),
                InkWell(
                  // Navigator.pop(context); use if humana ui sa users
                  onTap: () => Navigator.pushNamed(context, route.signup),
                  child: const Text(
                    ' Register',
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
      ),
    );
  }

  SizedBox spacing() => const SizedBox(height: 5);
}
