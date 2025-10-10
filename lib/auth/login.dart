import 'package:cce106_flutter_project/views/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cce106_flutter_project/auth/register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔐 FoodBook Login Page
class FoodBook extends StatefulWidget {
  const FoodBook({super.key});

  @override
  State<FoodBook> createState() => _FoodBookState();
}

class _FoodBookState extends State<FoodBook> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String errorMessage = '';
  bool isError = false;
  bool isLoading = false;
  bool _obscurePassword = true; // 👁️ Added for show/hide password

  Future<void> loginUser() async {
    setState(() {
      isError = false;
      errorMessage = '';
    });

    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      setState(() {
        isError = true;
        errorMessage = "Please fill in all fields.";
      });
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      final firstName = userDoc.data()?['firstName'] ?? '';

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Welcome back, $firstName!")));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        isError = true;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found for this email.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email format.';
            break;
          default:
            errorMessage = e.message ?? 'Login failed. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        isError = true;
        errorMessage = "Unexpected error: $e";
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ✅ Curved Header
          ClipPath(
            clipper: CurveClipper(),
            child: Container(
              height: 180,
              width: double.infinity,
              color: const Color(0xFFD72638),
              alignment: Alignment.center,
              child: const Text(
                "FoodBook",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 25,
                          color: Color(0xFF1C1C1C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 25),

                      // ✅ Email
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Email Address",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ✅ Password (with view toggle)
                      TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      if (isError)
                        Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      const SizedBox(height: 10),

                      // ✅ Login Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD72638),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: isLoading ? null : loginUser,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),

                      // ✅ Don’t have account?
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don’t have an account? "),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Same curved header style
class CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ✅ Placeholder dashboard
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome to FoodBook!"),
        backgroundColor: const Color(0xFFD72638),
      ),
      body: const Center(child: Text("You are now logged in 🎉")),
    );
  }
}
