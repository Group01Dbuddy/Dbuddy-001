import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:dbuddy/Screens/result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  String? selectedMeal;
  int mealWeight = 100; // in grams
  final List<String> mealOptions = ['Breakfast', 'Lunch', 'Snack', 'Dinner'];
  bool isFocused = false;

  bool get isButtonEnabled => selectedMeal != null && mealWeight > 0;

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
      _cameraController = CameraController(backCamera, ResolutionPreset.medium);
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

  // Resize image to prevent emulator crash
  File _resizeImage(File file) {
    final image = img.decodeImage(file.readAsBytesSync())!;
    final resized = img.copyResize(image, width: 224, height: 224);
    return File(file.path)..writeAsBytesSync(img.encodeJpg(resized));
  }

  Future<void> _onScanPressed() async {
    if (!isButtonEnabled) return;

    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Scanning...")));

    try {
      final XFile image = await _cameraController!.takePicture();
      final resized = _resizeImage(File(image.path));
      _navigateToResult(resized);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error capturing image: $e")));
    }
  }

  Future<void> _onUploadPressed() async {
    if (!isButtonEnabled) return;

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // compress a bit
      );
      if (image != null) {
        final resized = _resizeImage(File(image.path));
        _navigateToResult(resized);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error selecting image: $e")));
    }
  }

  void _navigateToResult(File image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          image: image,
          mealTime: selectedMeal!,
          mealWeight: mealWeight,
        ),
      ),
    );
  }

  void _onScannerTap() {
    setState(() => isFocused = true);
    Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => isFocused = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFFFF7A2F);
    final Color focusColor = const Color(0xFFFFA040);

    return Scaffold(
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CameraPreview(_cameraController!),

                // Top gradient
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

                // Top bar
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

                // Scanner box
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

                // Bottom container
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
                        color: Colors.white.withOpacity(0.15),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Meal dropdown
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
                              value: selectedMeal,
                              items: mealOptions
                                  .map(
                                    (meal) => DropdownMenuItem<String>(
                                      value: meal,
                                      child: Text(
                                        meal,
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => selectedMeal = val),
                            ),

                            const SizedBox(height: 16),

                            // Meal weight
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (mealWeight > 10) mealWeight -= 10;
                                      setState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '$mealWeight g',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      mealWeight += 10;
                                      setState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
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
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: isButtonEnabled
                                        ? _onUploadPressed
                                        : null,
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text("Upload Image"),
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
