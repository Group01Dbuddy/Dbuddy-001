import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Color primaryColor = const Color.fromARGB(255, 246, 124, 42);
  int consumedCalories = 1000;
  int totalCalories = 8000;
  int waterIntake = 3;
  final int waterGoal = 8;
  String userName = 'User';
  String userImage = 'assets/images/profile_placeholder.jpg';
  late final DateTime now;
  late final DateTime startOfToday;
  late final DateTime startOfNextDay;

  Map<String, int> mealConsumedCalories = {
    'Breakfast': 0,
    'Lunch': 0,
    'Snack': 0,
    'Dinner': 0,
  };

  Map<String, TimeOfDay> mealTimes = {
    'Breakfast': const TimeOfDay(hour: 8, minute: 0),
    'Lunch': const TimeOfDay(hour: 12, minute: 30),
    'Snack': const TimeOfDay(hour: 16, minute: 0),
    'Dinner': const TimeOfDay(hour: 19, minute: 30),
  };

  Map<String, bool> mealEnabled = {
    'Breakfast': true,
    'Lunch': true,
    'Snack': true,
    'Dinner': true,
  };

  @override
  void initState() {
    super.initState();
    now = DateTime.now();
    startOfToday = DateTime(now.year, now.month, now.day);
    startOfNextDay = startOfToday.add(const Duration(days: 1));
    _loadUserData();
    _listenToTodayMealRecords();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Fetch user profile data from the 'users' collection
    // This part remains mostly the same, fetching name, profile image, and calorie goal.
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      final userData = userDoc.data()!;
      setState(() {
        userName = userData['name'] ?? 'User';
        userImage = userData['profileImage'] ?? userImage;
        totalCalories =
            userData['calorieGoal'] ?? totalCalories; // Your daily calorie goal
        // consumedCalories will be loaded from user_daily_progress below
        mealConsumedCalories = Map<String, int>.from(
          userData['mealConsumedCalories'] ?? mealConsumedCalories,
        );
      });
    }

    // 2. Fetch consumed calories for today from the 'user_daily_progress' collection
    // We'll use the user's email and today's date to find the specific daily record.
    final now = DateTime.now();
    // To query by date, we need to create a DateTime object representing the start of today.
    // This ensures we match records for the entire day, regardless of time.
    final startOfToday = DateTime(now.year, now.month, now.day);

    // Firestore stores dates as Timestamps. It's crucial that the 'date' field
    // in your 'user_daily_progress' collection is stored as a Firestore Timestamp
    // representing the start of the day for this query to work correctly.
    final todayTimestamp = Timestamp.fromDate(startOfToday);

    try {
      final dailyProgressQuery = await FirebaseFirestore.instance
          .collection('user_daily_progress')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
          )
          .where('date', isLessThan: Timestamp.fromDate(startOfNextDay))
          .limit(1) // Still limit to 1 if you expect only one daily record
          .get();

      if (dailyProgressQuery.docs.isNotEmpty) {
        final dailyData = dailyProgressQuery.docs.first.data();
        setState(() {
          // Update consumedCalories from the daily progress record
          consumedCalories = dailyData['consumedCalories'] ?? 0;
        });
      } else {
        // If no record exists for today yet, ensure consumedCalories is reset or set to 0.
        setState(() {
          consumedCalories = 0;
        });
      }
    } catch (e) {
      print("Error loading daily progress: $e");
      // Handle error, maybe set consumedCalories to 0 or display a message
      setState(() {
        consumedCalories = 0;
      });
    }
  }

  void _listenToTodayMealRecords() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    userDoc
        .collection('mealRecords')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        )
        .snapshots()
        .listen((snapshot) async {
          int totalCaloriesToday = 0;
          for (var doc in snapshot.docs) {
            totalCaloriesToday += (doc.data()['calories'] ?? 0) as int;
          }

          final userData = await userDoc.get();
          int calorieLimit = userData.data()?['calorieGoal'] ?? 2000;

          setState(() {
            consumedCalories = totalCaloriesToday;
            totalCalories = calorieLimit;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: null,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DBuddy',
              style: TextStyle(
                fontFamily: 'finger',
                color: primaryColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    'Hi, $userName!',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage(userImage),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCalorieProgress(),
            const SizedBox(height: 16),
            _buildHydrationRow(isSmallScreen),
            const SizedBox(height: 22),
            _buildMealReminderSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/scan_screen');
        },
        backgroundColor: primaryColor,
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Icon(Icons.notifications),
              SizedBox(width: 48),
              Icon(Icons.history),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieProgress() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, primaryColor.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 90,
                  width: 90,
                  child: CircularProgressIndicator(
                    value: consumedCalories / totalCalories,
                    strokeWidth: 10,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Text(
                  '${((consumedCalories / totalCalories) * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Calorie Progress',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$consumedCalories Kcal Eaten',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '${totalCalories - consumedCalories} Kcal Remaining',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    '$totalCalories Kcal Goal',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHydrationRow(bool isSmallScreen) {
    double cardHeight = isSmallScreen ? 120 : 140;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildCard(
            icon: Icons.calendar_today,
            label: _formattedDate(),
            height: cardHeight,
            iconSize: 30,
          ),
        ),
        const SizedBox(width: 20), // Increased gap
        Expanded(child: _buildHydrationCard(cardHeight)),
      ],
    );
  }

  Widget _buildHydrationCard(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.water_drop, size: 28, color: primaryColor),
          const SizedBox(height: 10),
          Text(
            '$waterIntake / $waterGoal cups',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _hydrationButton(
                icon: Icons.remove,
                onTap: () {
                  setState(() {
                    if (waterIntake > 0) waterIntake--;
                  });
                },
                color: primaryColor,
                iconSize: 18,
                splashRadius: 18,
              ),
              const SizedBox(width: 8),
              _hydrationButton(
                icon: Icons.add,
                onTap: () {
                  setState(() {
                    if (waterIntake < waterGoal) waterIntake++;
                  });
                },
                color: primaryColor,
                iconSize: 18,
                splashRadius: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _hydrationButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    double iconSize = 18,
    double splashRadius = 18,
  }) {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: iconSize),
        onPressed: onTap,
        splashRadius: splashRadius,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String label,
    double height = 140,
    double iconSize = 40,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: primaryColor),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMealReminderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal Reminders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        ...mealTimes.entries.map((entry) {
          final meal = entry.key;
          final time = entry.value;
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Icon(_getIconForMeal(meal), color: primaryColor),
              title: Text(meal),
              subtitle: Text(time.format(context)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.alarm, color: Colors.orange),
                    tooltip: 'Set Reminder',
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: time,
                      );
                      if (picked != null && picked != time) {
                        setState(() {
                          mealTimes[meal] = picked;
                        });
                        // TODO: Save to Firestore if needed
                      }
                    },
                  ),
                  Switch(
                    value: mealEnabled[meal]!,
                    activeColor: primaryColor,
                    onChanged: (val) => setState(() => mealEnabled[meal] = val),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        // Add More Button
        Center(
          child: TextButton.icon(
            icon: Icon(Icons.add_circle, color: primaryColor),
            label: Text(
              "Add More",
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              String? newMeal;
              TimeOfDay? newTime;
              final controller = TextEditingController();
              await showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setStateDialog) {
                      return AlertDialog(
                        title: const Text("Add New Meal Reminder"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                labelText: "Meal Name",
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.access_time),
                              label: Text(
                                newTime == null
                                    ? "Pick Time"
                                    : newTime!.format(context),
                              ),
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );
                                if (picked != null) {
                                  setStateDialog(() {
                                    newTime = picked;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            child: const Text("Cancel"),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          TextButton(
                            child: const Text("Add"),
                            onPressed: () {
                              newMeal = controller.text.trim();
                              if (newMeal != null &&
                                  newMeal!.isNotEmpty &&
                                  newTime != null) {
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              );
              if (newMeal != null && newMeal!.isNotEmpty && newTime != null) {
                setState(() {
                  mealTimes[newMeal!] = newTime!;
                  mealEnabled[newMeal!] = true;
                });
                // TODO: Save to Firestore if needed
              }
            },
          ),
        ),
      ],
    );
  }

  IconData _getIconForMeal(String meal) {
    switch (meal.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'snack':
        return Icons.fastfood;
      case 'dinner':
        return Icons.restaurant;
      default:
        return Icons.restaurant_menu;
    }
  }

  String _formattedDate() {
    final now = DateTime.now();
    return "${_monthName(now.month)} ${now.day}, ${now.year}";
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
