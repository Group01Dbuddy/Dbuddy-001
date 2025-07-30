import 'package:flutter/material.dart';
import 'package:dbuddy/utils/colors_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "package:dbuddy/Screens/dash_board_screen.dart";

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _signIn() async {
    // Basic validation: Check if email or password fields are empty
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      if (!mounted) {
        return; // Always check mounted before context-dependent operations
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password.")),
      );
      return;
    }

    try {
      // Attempt to sign in with email and password
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final User? user =
          userCredential.user; // Get the user object from the credential

      // --- IMPORTANT: Check if the user's email is verified ---
      if (user != null) {
        // Reload the user to get the latest email verification status
        // This is crucial if they just verified their email outside the app
        await user.reload();
        // Get the refreshed user object
        final refreshedUser = FirebaseAuth.instance.currentUser;

        if (refreshedUser != null && !refreshedUser.emailVerified) {
          // If user exists but email is NOT verified
          // Optionally, resend verification email if you want to provide that convenience
          // Make sure not to spam, Firebase has rate limits
          // await refreshedUser.sendEmailVerification();

          if (!mounted) return; // Check mounted before showing UI
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Please verify your email address to continue. Check your inbox for a verification email.",
              ),
              duration: Duration(seconds: 6), // Keep message visible longer
            ),
          );
          // Sign out the user immediately so they can't proceed without verification
          await FirebaseAuth.instance.signOut();
          return; // Stop the sign-in process here
        }
      }
      // --- END: Email verification check ---

      // If sign-in is successful AND email is verified (or if no email verification is required/configured),
      // then navigate to your main app screen
      if (!mounted) return; // Check mounted before navigating
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const DashboardScreen(), // Navigate to your Dashboard
        ),
      );
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Authentication specific errors
      if (!mounted) return; // Check mounted before showing UI
      String errorMessage;
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage =
            'Invalid email or password.'; // Generic message for security
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address format is invalid.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled.';
      } else {
        errorMessage = 'An error occurred: ${e.message}';
      }
      print("Sign-in error: $errorMessage"); // Log full error for debugging
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      // Catch any other unexpected errors during the sign-in process
      if (!mounted) return; // Check mounted before showing UI
      print("General sign-in error: $e"); // Log for debugging
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred during sign in."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DBUDDY"),
        titleTextStyle: const TextStyle(
          fontFamily: 'finger',
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        centerTitle: true,
        backgroundColor: Colors
            .transparent, // AppBar background will be part of body's decoration
        elevation: 0, // No shadow
        flexibleSpace: Container(
          // Background image for the AppBar area
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                'assets/images/bg.jpg',
              ), // Ensure this path is correct
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      // The body container will hold the gradient background for the rest of the screen
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [hexStringToColor("#FF721A"), hexStringToColor("#FF450D")],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "LOGIN",
                    style: TextStyle(
                      color: Color.fromARGB(255, 250, 250, 250),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      hintText: "Email",
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "Password",
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hexStringToColor("#FF450D"),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _signIn, // Calls the _signIn function
                      child: const Text(
                        "Sign In",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hexStringToColor("#FF450D"),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/signup_screen',
                        ); // Navigates to Signup
                      },
                      child: const Text(
                        "Signup",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // TODO: Implement Forgot Password functionality here
                      // This would typically involve FirebaseAuth.instance.sendPasswordResetEmail(email: ...)
                    },
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
