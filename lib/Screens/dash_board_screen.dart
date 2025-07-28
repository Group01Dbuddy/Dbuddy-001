import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- ADD THIS
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

// AddButton widget for use in the Add Meal dialog
class AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const AddButton({super.key, required this.onPressed, this.label = "Add"});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 246, 124, 42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Updated color
  final Color primaryColor = const Color.fromARGB(255, 246, 124, 42);

  int waterIntake = 3;
  final int waterGoal = 8;
  int _currentIndex = 0;

  final String userName = "buddy";
  final int consumedCalories = 1260;
  final int totalCalories = 1800;

  Map<String, bool> mealEnabled = {
    'Breakfast': true,
    'Lunch': true,
    'Snack': true,
    'Dinner': true,
  };

  // Add this method to show a dialog for adding a new meal reminder
  Future<void> _showAddMealDialog() async {
    String newMeal = '';
    TimeOfDay? pickedTime;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Meal Reminder'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Meal Name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter meal name'
                    : null,
                onChanged: (value) => newMeal = value.trim(),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                },
                child: Text(
                  pickedTime == null
                      ? 'Pick Time'
                      : 'Time: ${pickedTime!.format(context)}',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate() && pickedTime != null) {
                setState(() {
                  mealEnabled[newMeal] = true;
                  mealTimes[newMeal] = pickedTime!;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Map<String, TimeOfDay> mealTimes = {
    'Breakfast': const TimeOfDay(hour: 8, minute: 0),
    'Lunch': const TimeOfDay(hour: 12, minute: 30),
    'Snack': const TimeOfDay(hour: 16, minute: 0),
    'Dinner': const TimeOfDay(hour: 19, minute: 30),
  };

  @override
  Widget build(BuildContext context) {
    final double cardSize = 150;
    final double iconSize = 32;

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
            Row(
              mainAxisSize: MainAxisSize.min,
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
                const CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage(
                    'assets/images/profile_placeholder.jpg',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Calorie Tracker Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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
            ),

            const SizedBox(height: 10),

            // Date + Hydration Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: cardSize,
                  height: cardSize,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: iconSize,
                        color: primaryColor,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        _formattedDate(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: cardSize,
                  height: cardSize,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.3)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hydration',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.water_drop_rounded,
                        size: 36,
                        color: primaryColor,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$waterIntake / $waterGoal cups',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (waterIntake < waterGoal) waterIntake++;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 26),
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Meal Reminders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Dynamically render all meals
            ...mealTimes.keys
                .map((meal) => _buildReminderCard(meal, _getIconForMeal(meal)))
                .toList(),

            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: AddButton(
                label: "Add Meal",
                onPressed: _showAddMealDialog,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                color: _currentIndex == 0 ? primaryColor : Colors.grey,
                onPressed: () => setState(() => _currentIndex = 0),
              ),
              const SizedBox(width: 48),
              IconButton(
                icon: const Icon(Icons.history),
                color: _currentIndex == 1 ? primaryColor : Colors.grey,
                onPressed: () => setState(() => _currentIndex = 1),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primaryColor,
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
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

  Widget _buildReminderCard(String meal, IconData icon) {
    final bool enabled = mealEnabled[meal] ?? true;
    final TimeOfDay time = mealTimes[meal]!;

    final isCustomMeal = ![
      'Breakfast',
      'Lunch',
      'Snack',
      'Dinner',
    ].map((e) => e.toLowerCase()).contains(meal.toLowerCase());

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: enabled ? primaryColor : Colors.grey),
        title: Text(
          meal,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: enabled ? Colors.black : Colors.grey,
          ),
        ),
        subtitle: Text(time.format(context)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: enabled,
              activeColor: primaryColor,
              onChanged: (val) {
                setState(() => mealEnabled[meal] = val);
              },
            ),
            Icon(Icons.alarm, color: enabled ? primaryColor : Colors.grey),
            if (isCustomMeal)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  _showDeleteConfirmation(meal);
                },
              ),
          ],
        ),
        onTap: enabled
            ? () async {
                TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: time,
                );
                if (picked != null) {
                  setState(() => mealTimes[meal] = picked);
                }
              }
            : null,
      ),
    );
  }

  void _showDeleteConfirmation(String mealName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Meal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to remove "$mealName"?'),
            const SizedBox(height: 12),
            if (!['Breakfast', 'Lunch', 'Snack', 'Dinner'].contains(mealName))
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text(
                  'Delete this meal',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  setState(() {
                    mealTimes.remove(mealName);
                    mealEnabled.remove(mealName);
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                mealTimes.remove(mealName);
                mealEnabled.remove(mealName);
              });
              Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
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
        return Icons.fastfood;
    }
  }
}
