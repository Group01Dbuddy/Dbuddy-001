import 'package:dbuddy/Screens/signin_screen.dart';
import 'package:flutter/material.dart';
import 'package:dbuddy/utils/colors_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController passwordController =
      TextEditingController(); // This should be the main password
  final TextEditingController goalController = TextEditingController();
  final TextEditingController activityLevelController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController(); // This should be the confirm password
  DateTime? birthday;
  double? weight;
  double? height;
  int? calorieGoal;

  int _currentPage = 0;

  final PageController _pageController = PageController();

  void _nextPage() {
    // _currentPage is 0 to 5 for 6 pages (0, 1, 2, 3, 4, 5)
    // If _currentPage is less than 5, it means we are not on the last page (page 5)
    if (_currentPage < 5) {
      setState(() {
        _currentPage++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      // This means we are on the last page (page 5), and _nextPage acts as submit
      _signUp(); // Call the sign-up function when "Next" is pressed on the last page
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  Future<void> _pickBirthday() async {
    DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        birthday = picked;
      });
    }
  }

  void _signUp() async {
    // --- START: Streamlined Validation ---
    // 1. Check for empty fields
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All fields on the first page are required."),
        ),
      );
      return;
    }

    // 2. Check password match
    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match.")));
      return;
    }

    // 3. Check password length
    if (passwordController.text.trim().length < 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 6 characters long."),
        ),
      );
      return;
    }

    // 4. Basic email format validation
    if (!emailController.text.trim().contains('@') ||
        emailController.text.trim().contains(' ')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email address.")),
      );
      return;
    }

    // --- END: Streamlined Validation ---

    try {
      // 1. Create user in Firebase Authentication
      final UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      User? newUser = userCredential.user;

      if (newUser != null) {
        // Optional: Update display name in Firebase Auth
        await newUser.updateDisplayName(nameController.text.trim());

        // --- NEW: Send email verification ---
        await newUser.sendEmailVerification();
        print("Verification email sent to ${newUser.email}"); // For debugging

        // 2. Save additional user profile data to Cloud Firestore
        await FirebaseFirestore.instance.collection('users').doc(newUser.uid).set({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'birthday': birthday
              ?.toIso8601String(), // Store birthday as ISO 8601 string
          'weight': weight,
          'height': height,
          'gender': genderController.text.trim(),
          'goal': goalController.text.trim(),
          'calorieGoal': calorieGoal,
          'activityLevel': activityLevelController.text.trim(),
          'createdAt':
              FieldValue.serverTimestamp(), // Timestamp for when the user was created
        });

        // 3. Inform user and navigate to SigninScreen
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Account created! Please verify your email to log in.",
            ),
            duration: Duration(
              seconds: 5,
            ), // Keep the message visible a bit longer
          ),
        );
        // Using pushAndRemoveUntil to clear the signup stack and go back to SigninScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SigninScreen()),
          (Route<dynamic> route) => false, // Remove all previous routes
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("User creation failed. Please try again."),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else {
        errorMessage = 'An error occurred during sign up: ${e.message}';
      }
      print("Sign-up error: $errorMessage");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      if (!mounted) return;
      print("General sign-up error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An unexpected error occurred during sign up."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sign Up",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'finger',
          ),
        ),
        backgroundColor: hexStringToColor("#FF450D"),
        centerTitle: true,
      ),
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
            child: SizedBox(
              height: 500,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Page 1: Name, Email, Password
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Main info",
                          style: TextStyle(
                            color: Color.fromARGB(255, 250, 250, 250),
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: "Name",
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
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
                        // Corrected: passwordController for "Password"
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
                        const SizedBox(height: 20),
                        // Corrected: confirmPasswordController for "Confirm Password"
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText:
                                "Confirm Password", // Changed from "Conform"
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
                            onPressed: _nextPage,
                            child: const Text(
                              "Next",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Page 2: Birthday and gender
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Birthday and Gender",
                          style: TextStyle(
                            color: Color.fromARGB(255, 250, 250, 250),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        GestureDetector(
                          onTap: _pickBirthday,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.transparent),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cake, color: Colors.grey),
                                const SizedBox(width: 12),
                                Text(
                                  birthday == null
                                      ? "Select your birthday"
                                      : "${birthday!.day}/${birthday!.month}/${birthday!.year}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          "Gender",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              RadioListTile<String>(
                                title: const Text("Male"),
                                value: "Male",
                                groupValue: genderController.text,
                                onChanged: (value) {
                                  setState(() {
                                    genderController.text = value!;
                                  });
                                },
                              ),
                              RadioListTile<String>(
                                title: const Text("Female"),
                                value: "Female",
                                groupValue: genderController.text,
                                onChanged: (value) {
                                  setState(() {
                                    genderController.text = value!;
                                  });
                                },
                              ),
                              RadioListTile<String>(
                                title: const Text("Other"),
                                value: "Other",
                                groupValue: genderController.text,
                                onChanged: (value) {
                                  setState(() {
                                    genderController.text = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _prevPage,
                              child: const Text(
                                "Back",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hexStringToColor("#FF450D"),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 32,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed:
                                  birthday != null &&
                                      genderController.text.isNotEmpty
                                  ? _nextPage
                                  : null,
                              child: const Text(
                                "Next",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Page 3: Active level Weight & Height
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Physical Info",
                          style: TextStyle(
                            color: Color.fromARGB(255, 250, 250, 250),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        TextField(
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            hintText: "Weight (kg)",
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.monitor_weight),
                          ),
                          onChanged: (val) {
                            setState(() {
                              weight = double.tryParse(val);
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            hintText: "Height (cm)",
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.height),
                          ),
                          onChanged: (val) {
                            setState(() {
                              height = double.tryParse(val);
                            });
                          },
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _prevPage,
                              child: const Text(
                                "Back",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hexStringToColor("#FF450D"),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 32,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: (weight != null && height != null)
                                  ? _nextPage
                                  : null,
                              child: const Text(
                                "Next",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Page 4: Calorie Goal
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Daily Calorie Goal",
                          style: TextStyle(
                            color: Color.fromARGB(255, 250, 250, 250),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "Daily Calorie Goal",
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(Icons.local_fire_department),
                          ),
                          onChanged: (val) {
                            setState(() {
                              calorieGoal = int.tryParse(val);
                            });
                          },
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _prevPage,
                              child: const Text(
                                "Back",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hexStringToColor("#FF450D"),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 32,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: (calorieGoal != null)
                                  ? _nextPage
                                  : null,
                              child: const Text(
                                "Next",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Page 5: Activity Level & Goal
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center, // Center content vertically
                      children: [
                        const Text(
                          "Activity & Goal",
                          style: TextStyle(
                            color: Color.fromARGB(255, 250, 250, 250),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // 🌟 Activity Level Dropdown
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: DropdownButtonFormField<String>(
                            // Ensure the value matches an item, or set to null initially
                            value:
                                [
                                  'Beginner',
                                  'Intermediate',
                                  'Advanced',
                                ].contains(activityLevelController.text)
                                ? activityLevelController.text
                                : null,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Select Activity Level",
                              prefixIcon: Icon(Icons.fitness_center),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                            items: ['Beginner', 'Intermediate', 'Advanced'].map(
                              (level) {
                                return DropdownMenuItem<String>(
                                  value: level,
                                  child: Text(level),
                                );
                              },
                            ).toList(),
                            onChanged: (value) {
                              setState(() {
                                activityLevelController.text = value!;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 16), // spacing between dropdowns
                        // 🎯 Goal Dropdown
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          child: DropdownButtonFormField<String>(
                            // Ensure the value matches an item, or set to null initially
                            value:
                                [
                                  'Weight Loss',
                                  'Gain Fat',
                                  'Balance',
                                ].contains(goalController.text)
                                ? goalController.text
                                : null,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Select Goal",
                              prefixIcon: Icon(Icons.track_changes),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                            items: ['Weight Loss', 'Gain Fat', 'Balance'].map((
                              goal,
                            ) {
                              return DropdownMenuItem<String>(
                                value: goal,
                                child: Text(goal),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                goalController.text = value!;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _prevPage,
                              child: const Text(
                                "Back",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hexStringToColor("#FF450D"),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 32,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed:
                                  (goalController.text.isNotEmpty &&
                                      activityLevelController.text.isNotEmpty)
                                  ? _nextPage // This will now trigger _signUp
                                  : null,
                              child: const Text(
                                "Next",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Page 6: Review & Submit
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Review & Submit",
                          style: TextStyle(
                            color: Color.fromARGB(255, 250, 250, 250),
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Card(
                          color: Colors.white.withOpacity(0.95),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Name: ${nameController.text}"),
                                Text("Email: ${emailController.text}"),
                                Text(
                                  "Birthday: ${birthday != null ? "${birthday!.day}/${birthday!.month}/${birthday!.year}" : ""}",
                                ),
                                Text("Gender: ${genderController.text}"),
                                Text(
                                  "Activity Level: ${activityLevelController.text}",
                                ),
                                Text("Weight: ${weight ?? ""} kg"),
                                Text("Height: ${height ?? ""} cm"),
                                Text("Calorie Goal: ${calorieGoal ?? ""}"),
                                Text("Goal: ${goalController.text}"),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: _prevPage,
                              child: const Text(
                                "Back",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            SizedBox(
                              width: 150,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hexStringToColor("#FF450D"),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                // This button directly calls _signUp because _nextPage
                                // handles the final page transition to _signUp logic
                                onPressed: _signUp,
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SigninScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Already have an account? Sign In",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
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
