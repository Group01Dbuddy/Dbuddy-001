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
  int consumedCalories = 0;
  int totalCalories = 2000;
  int waterIntake = 3;
  final int waterGoal = 8;
  String userName = 'User';
  String userImage = 'assets/images/profile_placeholder.jpg';

  Map<String, int> mealConsumedCalories = {
    'Breakfast': 0,
    'Lunch': 0,
    'Snack': 0,
    'Dinner': 0,
  };

  final Map<String, TimeOfDay> mealTimes = {
    'Breakfast': const TimeOfDay(hour: 8, minute: 0),
    'Lunch': const TimeOfDay(hour: 12, minute: 30),
    'Snack': const TimeOfDay(hour: 16, minute: 0),
    'Dinner': const TimeOfDay(hour: 19, minute: 30),
  };

  final Map<String, bool> mealEnabled = {
    'Breakfast': true,
    'Lunch': true,
    'Snack': true,
    'Dinner': true,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        userName = data['name'] ?? 'User';
        userImage = data['profileImage'] ?? userImage;
        totalCalories = data['calorieGoal'] ?? totalCalories;
        consumedCalories = data['consumedCalories'] ?? consumedCalories;
        mealConsumedCalories = Map<String, int>.from(
          data['mealConsumedCalories'] ?? mealConsumedCalories,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SDB',
              style: TextStyle(
                color: primaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
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
            const SizedBox(height: 20),
            _buildHydrationRow(),
            const SizedBox(height: 25),
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

  Widget _buildHydrationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCard(icon: Icons.calendar_today, label: _formattedDate()),
        _buildCard(
          icon: Icons.water_drop,
          label: '$waterIntake / $waterGoal cups',
          button: ElevatedButton(
            onPressed: () {
              setState(() {
                if (waterIntake < waterGoal) waterIntake++;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              minimumSize: const Size(40, 26),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String label,
    Widget? button,
  }) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: primaryColor),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (button != null) ...[const SizedBox(height: 8), button],
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
              trailing: Switch(
                value: mealEnabled[meal]!,
                activeColor: primaryColor,
                onChanged: (val) => setState(() => mealEnabled[meal] = val),
              ),
            ),
          );
        }).toList(),
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
