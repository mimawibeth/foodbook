import 'package:cce106_flutter_project/auth/register.dart';
import 'package:cce106_flutter_project/views/dashboard.dart';
import 'package:flutter/material.dart';

class FoodBook extends StatefulWidget {
  const FoodBook({super.key});

  @override
  State<FoodBook> createState() => _FoodBookState();
}

class _FoodBookState extends State<FoodBook> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  late String errorMessage;
  late bool isError;

  @override
  void initState() {
    errorMessage = "";
    isError = false;
    super.initState();
  }

  void checkLogin(username, password) {
    setState(() {
      if (username == "") {
        errorMessage = "Please enter your Email";
        isError = true;
      } else if (password == "") {
        errorMessage = "Please enter your password";
        isError = true;
      } else {
        errorMessage = "";
        isError = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Off-White background
      body: Column(
        children: [
          // Top branding with curve
          ClipPath(
            clipper: CurveClipper(),
            child: Container(
              height: 230,
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

          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Login title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Login",
                          style: textstyle.copyWith(
                            fontSize: 25,
                            color: const Color(0xFF1C1C1C), // Almost Black
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Email label + field
                    const Text(
                      "Email Address",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1C), // Almost Black
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFFF2A541), // Mustard Yellow
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Password label + field
                    const Text(
                      "Password",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C1C), // Almost Black
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFFF2A541), // Mustard Yellow
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    // Forgot Password button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Forgot Password clicked"),
                            ),
                          );
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Color(0xFF1C1C1C), // Almost Black
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Error message
                    if (isError) Text(errorMessage, style: errorTextStyle),

                    const SizedBox(height: 15),

                    // Login Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: const Color(0xFFD72638), // Berry Red
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        checkLogin(
                          usernameController.text,
                          passwordController.text,
                        );
                        if (!isError) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Dashboard(),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 16,
                          color: Color(0xFFFAFAFA), // Off-White
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Create account prompt
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don’t have an account? ",
                          style: TextStyle(color: Color(0xFF1C1C1C)),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Sign up",
                            style: TextStyle(
                              color: Color.fromARGB(255, 65, 106, 242),
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
        ],
      ),
    );
  }
}

// Text styles
var textstyle = const TextStyle(
  fontWeight: FontWeight.bold,
  letterSpacing: 2,
  fontSize: 18,
);

var errorTextStyle = const TextStyle(
  fontWeight: FontWeight.bold,
  letterSpacing: 1,
  fontSize: 13,
  color: Colors.red,
);

var textstyle2 = const TextStyle(
  fontWeight: FontWeight.bold,
  letterSpacing: 2,
  fontSize: 14,
  color: Colors.white,
);
