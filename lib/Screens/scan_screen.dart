import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  String? selectedMeal;
  String foodType = '';
  int quantity = 1;

  final List<String> mealOptions = ['Breakfast', 'Lunch', 'Snack', 'Dinner'];

  bool isFocused = false; // For tap focus effect

  bool get isButtonEnabled {
    if (selectedMeal == null || foodType.isEmpty) return false;
    if (foodType == 'Countable' && quantity <= 0) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _initCamera();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      // Changed here to ResolutionPreset.max for high-quality capture
      _cameraController = CameraController(backCamera, ResolutionPreset.max);
      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScanPressed() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Scanning...")));
    // Add logic to process the scan and navigate if needed.
  }

  void _onScannerTap() {
    setState(() {
      isFocused = true;
    });
    // Return to normal after 1 second
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          isFocused = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFFFF7A2F);
    final Color focusColor = const Color(
      0xFFFFA040,
    ); // Brighter orange on focus
    final Color charcoal = const Color(0xFF333333);

    return Scaffold(
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CameraPreview(_cameraController!),

                // Top gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),

                // Top app bar
                Positioned(
                  top: 40,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Scan Food',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scanner box with tap-to-focus effect
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.25,
                  left: MediaQuery.of(context).size.width * 0.15,
                  right: MediaQuery.of(context).size.width * 0.15,
                  child: GestureDetector(
                    onTap: _onScannerTap,
                    child: FadeTransition(
                      opacity: Tween(
                        begin: 0.5,
                        end: 1.0,
                      ).animate(_animationController),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 180,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFocused ? focusColor : Colors.white,
                            width: isFocused ? 4 : 3,
                          ),
                          boxShadow: isFocused
                              ? [
                                  BoxShadow(
                                    color: focusColor.withOpacity(0.6),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : [],
                        ),
                        child: ScaleTransition(
                          scale: isFocused
                              ? _scaleAnimation
                              : const AlwaysStoppedAnimation(1),
                          child: Container(),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom glass container
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Dropdown for meal
                            DropdownButtonFormField<String>(
                              dropdownColor: Colors.white,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.2),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(
                                  Icons.restaurant_menu,
                                  color: Colors.white,
                                ),
                                hintText: 'Select Meal Time',
                                hintStyle: const TextStyle(color: Colors.white),
                              ),
                              style: const TextStyle(
                                color: Colors.black, // Selected item text color
                                fontSize: 16,
                              ),
                              value: selectedMeal,
                              items: mealOptions.map((meal) {
                                return DropdownMenuItem<String>(
                                  value: meal,
                                  child: Text(
                                    meal,
                                    style: const TextStyle(
                                      color: Colors
                                          .black, // Dropdown list item text color
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => selectedMeal = val),
                            ),

                            const SizedBox(height: 16),

                            // Countable/Non-countable toggle
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: ['Countable', 'Non-countable'].map((
                                  type,
                                ) {
                                  bool isSelected = foodType == type;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () =>
                                          setState(() => foodType = type),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primaryColor
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            type,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : charcoal,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Quantity input
                            if (foodType == 'Countable')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (quantity > 0)
                                        setState(() => quantity--);
                                    },
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '$quantity',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(() => quantity++),
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 16),

                            // Scan button
                            ElevatedButton.icon(
                              onPressed: isButtonEnabled
                                  ? _onScanPressed
                                  : null,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text("Scan Food"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isButtonEnabled
                                    ? primaryColor
                                    : Colors.grey.shade600,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
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
