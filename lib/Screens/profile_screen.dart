import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- NEW: Import Firebase Auth
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Default values for profile fields. These will be overwritten by data from Firestore.
  String userName = "Demo User";
  int age = 21;
  double weight = 52;
  double height = 158;
  File?
  profileImage; // For locally selected image before upload (if you implement storage)

  final Color primaryColor = const Color.fromARGB(255, 246, 124, 42);

  double get bmi => weight / ((height / 100) * (height / 100));

  Color getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.yellow.shade700;
    if (bmi >= 18.5 && bmi < 25) return Colors.green.shade600;
    if (bmi >= 25 && bmi < 30) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  // User's activity level and daily calorie limit.
  // Make sure these default strings match your SignupScreen's options ('Beginner', 'Intermediate', 'Advanced')
  String activityLevel = 'Intermediate';
  int dailyCalorieLimit = 2000;

  // Calorie distribution for meals.
  late Map<String, int> mealCalories;

  // <--- NEW: Store the current Firebase User object
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    // Initialize mealCalories with default values before data loads.
    // This prevents errors if calculated before async data fetch completes.
    mealCalories = calculateMealCalories(dailyCalorieLimit, activityLevel);
    _initializeFirebaseAndLoadData();
  }

  Future<void> _initializeFirebaseAndLoadData() async {
    // It's generally best practice to initialize Firebase only once at your app's entry point (main.dart).
    // Keeping this line here for now as it was in your original code, but be aware of redundant calls.
    await Firebase.initializeApp();

    // <--- NEW: Get the current authenticated user
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser == null) {
      // If no user is logged in, you should redirect them to the sign-in/onboarding screen.
      // Make sure '/signin_screen' is a valid route in your app.
      print('No user logged in. Redirecting to sign-in.');
      if (mounted) {
        // Using pushReplacementNamed to prevent user from going back to profile screen using back button
        Navigator.pushReplacementNamed(context, '/signin_screen');
      }
      return; // Stop further execution if no user is found.
    }

    // <--- Load user data from Firestore for the logged-in user
    await _loadUserProfileData();
  }

  Future<void> _loadUserProfileData() async {
    // Ensure we have a user before attempting to load data
    if (_currentUser == null) {
      print('Attempted to load profile data but no user is logged in.');
      return;
    }

    try {
      // <--- CHANGED: Fetch data from Firestore using the current user's UID
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          userName = data['name'] ?? userName;
          age = data['age'] ?? age;
          // <--- Ensure correct type casting and default value for doubles
          weight = data['weight']?.toDouble() ?? weight;
          height = data['height']?.toDouble() ?? height;
          // <--- Using 'activityLevel' from Firestore, defaulting if not found
          activityLevel = data['activityLevel'] ?? activityLevel;
          // <--- Using 'calorieGoal' from Firestore, as per your SignupScreen's saving field name
          dailyCalorieLimit = data['calorieGoal'] ?? dailyCalorieLimit;
          // Recalculate meal calories with newly loaded data
          mealCalories = calculateMealCalories(
            dailyCalorieLimit,
            activityLevel,
          );
        });
      } else {
        print('User profile document not found for UID: ${_currentUser!.uid}.');
        // This might happen for new users who haven't completed their full profile yet,
        // or if there's an issue with signup data saving.
        // You might want to pre-populate their Firestore document with defaults here,
        // or prompt them to complete their profile.
      }
    } catch (e) {
      print('Error loading user profile data: $e');
    }
  }

  Future<void> _saveUserProfileData() async {
    // Ensure we have a user before attempting to save data
    if (_currentUser == null) {
      print('Attempted to save profile data but no user is logged in.');
      return;
    }

    try {
      // <--- CHANGED: Save data to Firestore using the current user's UID
      // <--- Using SetOptions(merge: true) to update only specified fields,
      //      leaving other fields in the document untouched. This is crucial!
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set({
            'name': userName,
            'age': age,
            'weight': weight,
            'height': height,
            'activityLevel': activityLevel,
            'calorieGoal':
                dailyCalorieLimit, // <--- Use 'calorieGoal' as saved in SignupScreen
          }, SetOptions(merge: true));
      print(
        'User profile data saved successfully for UID: ${_currentUser!.uid}',
      );
    } catch (e) {
      print('Error saving user profile data: $e');
    }
  }

  // Calculate calorie distribution using an activity factor.
  // <--- IMPORTANT: Aligned these string cases with what is saved in your SignupScreen
  Map<String, int> calculateMealCalories(int dailyLimit, String activity) {
    double factor;
    switch (activity.toLowerCase()) {
      case 'beginner':
        factor = 0.9;
        break;
      case 'intermediate':
        factor = 1.0;
        break;
      case 'advanced':
        factor = 1.1;
        break;
      default:
        factor = 1.0; // Default to moderate if activity level is unexpected
    }
    int adjustedLimit = (dailyLimit * factor).round();
    return {
      'Breakfast': (adjustedLimit * 0.3).round(),
      'Lunch': (adjustedLimit * 0.35).round(),
      'Snack': (adjustedLimit * 0.1).round(),
      'Dinner': (adjustedLimit * 0.25).round(),
    };
  }

  // Image picker for the profile photo.
  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        profileImage = File(pickedFile.path);
      });
      // TODO: Implement Cloud Storage for Firebase upload here.
      // You'll need to add 'firebase_storage' package and upload the file.
      // After successful upload, get the download URL and save it to the user's
      // Firestore document using _saveUserProfileData().
      print(
        'Profile image picked. (Saving to Cloud Storage not yet implemented)',
      );
    }
  }

  // Generic function to edit profile fields via an AlertDialog
  Future<void> editField({
    required String title,
    required String currentValue,
    required ValueChanged<String> onSave,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    final controller = TextEditingController(text: currentValue);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit $title"),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: "Enter $title"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text); // Calls the provided onSave callback
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // Specific handler for editing calorie limit
  Future<void> editCalorieLimit() async {
    await editField(
      title: "Daily Calorie Limit",
      currentValue: dailyCalorieLimit.toString(),
      keyboardType: TextInputType.number,
      onSave: (val) {
        final parsed = int.tryParse(val);
        if (parsed != null && parsed > 0) {
          setState(() {
            dailyCalorieLimit = parsed;
            // Recalculate meal calories as daily limit changed
            mealCalories = calculateMealCalories(
              dailyCalorieLimit,
              activityLevel,
            );
            _saveUserProfileData(); // <--- Save to Firestore
          });
        }
      },
    );
  }

  // Dropdown for selecting activity level
  Widget activityLevelDropdown() {
    // <--- IMPORTANT: These options MUST match exactly what you save in SignupScreen
    final List<String> activityOptions = [
      'Beginner',
      'Intermediate',
      'Advanced',
    ];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Activity Level", style: GoogleFonts.poppins(fontSize: 16)),
            DropdownButton<String>(
              // <--- Ensure the currently selected value is one of the options, otherwise it will be null
              value: activityOptions.contains(activityLevel)
                  ? activityLevel
                  : null,
              hint: const Text(
                "Select Activity",
              ), // Added a hint for when value is null
              items: activityOptions
                  .map(
                    (level) =>
                        DropdownMenuItem(value: level, child: Text(level)),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    activityLevel = val;
                    // Recalculate meal calories as activity level changed
                    mealCalories = calculateMealCalories(
                      dailyCalorieLimit,
                      activityLevel,
                    );
                    _saveUserProfileData(); // <--- Save to Firestore
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// A responsive box widget that displays each meal's calorie allocation.
  Widget mealItemBox(String mealTitle, int calories, double boxWidth) {
    return Container(
      width: boxWidth,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: primaryColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mealTitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "$calories cal",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Displays all the daily meal boxes in a read-only card.
  Widget mealCalorieDistributionCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(top: 15),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Divide the available width (subtracting padding) equally for 2 boxes per row.
            double boxWidth = (constraints.maxWidth - 40) / 2;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Daily Meal Calorie Goals",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.start,
                  children: mealCalories.entries
                      .map(
                        (entry) =>
                            mealItemBox(entry.key, entry.value, boxWidth),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
                Text(
                  "Total: ${mealCalories.values.fold(0, (a, b) => a + b)} cal",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // A simple card widget for editing fields such as Age, Height, Weight, etc.
  Widget _infoCard({
    required String title,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.poppins(fontSize: 16)),
              Row(
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit, size: 18, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }

  Future<void> _generateAndDownloadPdf(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.orange, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Dbuddy',
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Monthly Calorie Progress Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Name: $userName', style: pw.TextStyle(fontSize: 16)),
                pw.Text('Age: $age', style: pw.TextStyle(fontSize: 16)),
                pw.Text(
                  'Report Date: ${DateTime.now().toString().split(' ')[0]}',
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Daily Intake (Last 30 Days)',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Calories',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Water',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final date = (data['date'] as Timestamp?)?.toDate();
                      final consumedCalories = data['consumedCalories'] ?? 0;
                      final waterIntake = data['waterIntake'] ?? 0;
                      return pw.TableRow(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                              date != null
                                  ? '${date.month}/${date.day}/${date.year}'
                                  : 'Unknown Date',
                            ),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('$consumedCalories Kcal'),
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('$waterIntake cups'),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  '"Keep up the great work! Stay healthy, stay fit, and keep achieving your goals!"',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.orange,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'monthly_progress.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 246, 124, 42);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom header with a back button.
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: primaryColor),
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        '/dashboard_screen',
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Profile',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile photo with edit icon overlay.
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade300,
                          // If profileImage is null, it falls back to 'assets/profile.jpg'
                          backgroundImage: profileImage != null
                              ? FileImage(profileImage!)
                              : const AssetImage(
                                      'assets/images/profile_placeholder.jpg',
                                    )
                                    as ImageProvider,
                        ),
                        InkWell(
                          onTap: pickImage,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Editable user name.
                    InkWell(
                      onTap: () => editField(
                        title: "Name",
                        currentValue: userName,
                        onSave: (val) {
                          if (val.trim().isNotEmpty) {
                            setState(() {
                              userName = val.trim();
                              _saveUserProfileData(); // <--- Save to Firestore
                            });
                          }
                        },
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.edit, size: 20, color: primaryColor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Editable Age.
                    _infoCard(
                      title: "Age",
                      value: "$age",
                      onEdit: () => editField(
                        title: "Age",
                        currentValue: age.toString(),
                        onSave: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null && parsed > 0) {
                            setState(() {
                              age = parsed;
                              _saveUserProfileData(); // <--- Save to Firestore
                            });
                          }
                        },
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Height and Weight cards (arranged responsively).
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 400) {
                          return Column(
                            children: [
                              _infoCard(
                                title: "Height (cm)",
                                value: height.toStringAsFixed(1),
                                onEdit: () => editField(
                                  title: "Height",
                                  currentValue: height.toStringAsFixed(1),
                                  onSave: (val) {
                                    final parsed = double.tryParse(val);
                                    if (parsed != null && parsed > 0) {
                                      setState(() {
                                        height = parsed;
                                        _saveUserProfileData(); // <--- Save to Firestore
                                      });
                                    }
                                  },
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _infoCard(
                                title: "Weight (kg)",
                                value: weight.toStringAsFixed(1),
                                onEdit: () => editField(
                                  title: "Weight",
                                  currentValue: weight.toStringAsFixed(1),
                                  onSave: (val) {
                                    final parsed = double.tryParse(val);
                                    if (parsed != null && parsed > 0) {
                                      setState(() {
                                        weight = parsed;
                                        _saveUserProfileData(); // <--- Save to Firestore
                                      });
                                    }
                                  },
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(
                                child: _infoCard(
                                  title: "Height (cm)",
                                  value: height.toStringAsFixed(1),
                                  onEdit: () => editField(
                                    title: "Height",
                                    currentValue: height.toStringAsFixed(1),
                                    onSave: (val) {
                                      final parsed = double.tryParse(val);
                                      if (parsed != null && parsed > 0) {
                                        setState(() {
                                          height = parsed;
                                          _saveUserProfileData(); // <--- Save to Firestore
                                        });
                                      }
                                    },
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _infoCard(
                                  title: "Weight (kg)",
                                  value: weight.toStringAsFixed(1),
                                  onEdit: () => editField(
                                    title: "Weight",
                                    currentValue: weight.toStringAsFixed(1),
                                    onSave: (val) {
                                      final parsed = double.tryParse(val);
                                      if (parsed != null && parsed > 0) {
                                        setState(() {
                                          weight = parsed;
                                          _saveUserProfileData(); // <--- Save to Firestore
                                        });
                                      }
                                    },
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    // BMI Card placed immediately after Height/Weight.
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: getBMIColor(bmi).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: getBMIColor(bmi), width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "BMI",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "${bmi.toStringAsFixed(1)} — ${_bmiCategory(bmi)}",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: getBMIColor(bmi),
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Activity Level Dropdown.
                    activityLevelDropdown(),
                    const SizedBox(height: 15),
                    // Editable Daily Calorie Limit.
                    _infoCard(
                      title: "Daily Calorie Limit",
                      value: dailyCalorieLimit.toString(),
                      onEdit:
                          editCalorieLimit, // This calls editField, which then calls _saveUserProfileData
                    ),
                    // Read-only Daily Meal Calorie Goals.
                    mealCalorieDistributionCard(),
                    const SizedBox(height: 30),
                    // Monthly Progress and Download PDF row.
                    LayoutBuilder(
                      builder: (context, constraints) {
                        bool isMobile = constraints.maxWidth < 600;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade300,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: isMobile
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        '/monthly_progress_screen',
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "View Monthly Progress",
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: primaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.bar_chart,
                                              color: primaryColor,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: primaryColor,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed: () async {
                                        final user =
                                            FirebaseAuth.instance.currentUser;
                                        if (user == null) return;

                                        final thirtyDaysAgo = DateTime.now()
                                            .subtract(const Duration(days: 30));

                                        final querySnapshot =
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(user.uid)
                                                .collection(
                                                  'user_daily_progress',
                                                )
                                                .where(
                                                  'date',
                                                  isGreaterThanOrEqualTo:
                                                      Timestamp.fromDate(
                                                        thirtyDaysAgo,
                                                      ),
                                                )
                                                .orderBy(
                                                  'date',
                                                  descending: true,
                                                )
                                                .get();

                                        if (querySnapshot.docs.isNotEmpty) {
                                          await _generateAndDownloadPdf(
                                            querySnapshot.docs,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'No data available for PDF',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      icon: Icon(
                                        Icons.download,
                                        color: primaryColor,
                                      ),
                                      label: Text(
                                        "Download PDF",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () => Navigator.pushNamed(
                                          context,
                                          '/monthly_progress_screen',
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "View Monthly Progress",
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: primaryColor,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(
                                                Icons.bar_chart,
                                                color: primaryColor,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color: primaryColor,
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed: () async {
                                        final user =
                                            FirebaseAuth.instance.currentUser;
                                        if (user == null) return;

                                        final thirtyDaysAgo = DateTime.now()
                                            .subtract(const Duration(days: 30));

                                        final querySnapshot =
                                            await FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(user.uid)
                                                .collection(
                                                  'user_daily_progress',
                                                )
                                                .where(
                                                  'date',
                                                  isGreaterThanOrEqualTo:
                                                      Timestamp.fromDate(
                                                        thirtyDaysAgo,
                                                      ),
                                                )
                                                .orderBy(
                                                  'date',
                                                  descending: true,
                                                )
                                                .get();

                                        if (querySnapshot.docs.isNotEmpty) {
                                          await _generateAndDownloadPdf(
                                            querySnapshot.docs,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'No data available for PDF',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      icon: Icon(
                                        Icons.download,
                                        color: primaryColor,
                                      ),
                                      label: Text(
                                        "Download PDF",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    // Logout Button.
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                      onPressed: () async {
                        // <--- NEW: Sign out the user from Firebase Authentication
                        await FirebaseAuth.instance.signOut();
                        // Then navigate to your splash/login screen, clearing the navigation stack
                        if (mounted) {
                          Navigator.pushReplacementNamed(
                            context,
                            '/splash_logo_screen', // or '/signin_screen'
                          );
                        }
                      },
                      icon: Icon(Icons.logout, color: primaryColor),
                      label: Text(
                        'Logout',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
