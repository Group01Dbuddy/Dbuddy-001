import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResultScreen extends StatefulWidget {
  final File image;
  final String mealTime;
  final int mealWeight;

  const ResultScreen({
    super.key,
    required this.image,
    required this.mealTime,
    required this.mealWeight,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  String? _predictedFood;
  Map<String, dynamic>? _nutritionInfo;
  bool _isLoading = true;

  final List<String> highCalorieSuggestions = [
    "Opt for a smaller portion of rice and curry to reduce calorie intake.",
    "Choose fish ambul thiyal instead of meat curry for a lighter option.",
    "Incorporate more vegetables like gotukola salad into your meal.",
    "Drink plain water or herbal tea instead of sugary beverages.",
    "Try fruit-based desserts like mango or papaya for a lighter treat.",
    "Use coconut milk sparingly in your curries.",
    "Skip the ghee or use a low-fat version in cooking.",
    "Replace white rice with red rice or millet.",
    "Have a side salad with coconut sambol.",
    "Walk after eating to burn some calories.",
  ];

  final List<String> lowCalorieSuggestions = [
    "Add a serving of nuts like cashews for healthy fats.",
    "Include avocado in your meal for creaminess and calories.",
    "Have a piece of whole grain bread or roti.",
    "Add cheese or yogurt to your dish for protein and calories.",
    "Include a smoothie with local fruits like passion fruit.",
    "Eat a handful of dried fruits like raisins.",
    "Add coconut oil to your vegetables.",
    "Have a small piece of Sri Lankan halwa or chocolate.",
    "Include beans or lentils in your curry for fiber and calories.",
    "Drink a glass of buffalo milk or lassi.",
  ];

  @override
  void initState() {
    super.initState();
    _sendImageForPrediction();
  }

  Future<void> _sendImageForPrediction() async {
    final uri = Uri.parse(
      'https://9fd51852d76c.ngrok-free.app/predict',
    ); // Replace with your ngrok URL
    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      await http.MultipartFile.fromPath('image', widget.image.path),
    );

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonResponse = json.decode(respStr);

        setState(() {
          _predictedFood = jsonResponse['predicted_class'];
          _nutritionInfo = Map<String, dynamic>.from(
            jsonResponse['nutrition_info'],
          );
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        print('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error sending image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Result'),
        backgroundColor: const Color(0xFFFF7A2F),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Image display
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(widget.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Meal info
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Meal Time: ${widget.mealTime}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Weight: ${widget.mealWeight}g',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Prediction
                  if (_predictedFood != null)
                    Card(
                      elevation: 4,
                      color: const Color(0xFFFF7A2F),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Predicted Food: $_predictedFood',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Nutrition info
                  if (_nutritionInfo != null)
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              'Nutrition Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Calculate scaled nutrition based on meal weight
                            Builder(
                              builder: (context) {
                                double scale = widget.mealWeight / 100.0;
                                double scaledCalories =
                                    _nutritionInfo!['calories_per_100g'] *
                                    scale;
                                double scaledCarbs =
                                    _nutritionInfo!['carbs'] * scale;
                                double scaledProtein =
                                    _nutritionInfo!['protein'] * scale;
                                double scaledFat =
                                    _nutritionInfo!['fat'] * scale;
                                String? suggestion;
                                if (scaledCalories > 800) {
                                  suggestion =
                                      highCalorieSuggestions[Random().nextInt(
                                        highCalorieSuggestions.length,
                                      )];
                                } else if (scaledCalories < 300) {
                                  suggestion =
                                      lowCalorieSuggestions[Random().nextInt(
                                        lowCalorieSuggestions.length,
                                      )];
                                }
                                return Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildNutritionItem(
                                          'Calories',
                                          '${scaledCalories.toStringAsFixed(1)} kcal',
                                        ),
                                        _buildNutritionItem(
                                          'Carbs',
                                          '${scaledCarbs.toStringAsFixed(1)}g',
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildNutritionItem(
                                          'Protein',
                                          '${scaledProtein.toStringAsFixed(1)}g',
                                        ),
                                        _buildNutritionItem(
                                          'Fat',
                                          '${scaledFat.toStringAsFixed(1)}g',
                                        ),
                                      ],
                                    ),
                                    if (suggestion != null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        suggestion,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.blue,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Scan Again'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF7A2F),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Saved to history!'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildNutritionItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
