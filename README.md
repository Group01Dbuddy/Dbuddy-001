# Dbuddy – AI-Powered Nutrition & Diet Assistant

**Dbuddy (Diet Buddy)** is a mobile application designed to support university students, hostel residents, and working professionals in maintaining healthy eating habits through **real-time food recognition, calorie tracking, BMI calculation, and monthly diet reports**. It helps users maintain a healthier lifestyle by combining AI-powered food analysis with personalized nutrition guidance.

---

## ⚠️ Problem Statement

Many students, hostel residents, and working professionals struggle to maintain a healthy diet because they lack:

* Accurate calorie information
* Time to track meals
* Consistent dietary habits

Traditional calorie-tracking apps do not recognize Sri Lankan foods and require manual entry, making them inconvenient and inaccurate.

**Dbuddy provides a simple, real-time, ML-powered mobile solution that:**

* Automatically recognizes local foods from images
* Estimates calories and nutritional information instantly
* Tracks BMI and hydration
* Provides personalized dietary suggestions

---

## 🚀 Key Features

### AI Food Recognition

* Recognizes food items using a custom-trained **EfficientNetB7 model**
* Estimates calories and nutritional value per meal

### BMI Calculation & Recommendations

* Calculates BMI based on user profile (age, height, weight)
* Provides dietary suggestions according to BMI category:

  * **Underweight →** High-calorie foods
  * **Normal →** Balanced diet
  * **Overweight →** Reduce sugar/fat; increase fiber
  * **Obese →** Consult a dietitian

### User-Friendly Interface

* Orange-themed modern UI built in **Flutter**
* Intuitive navigation: Home, Profile, Camera/Scan, Scan History, Settings

### Hydration Tracking & Reports

* Tracks daily water intake
* Optional monthly **PDF report** summarizing calories and hydration

### User Profile & Health Insights

* Editable personal details
* BMI calculation with health status
* Signup/Login with **Firebase Authentication**

---

## 📱 Screens & UI

* Splash & Onboarding
* Login / Signup
* Dashboard
* Food Scan Page
* Profile & Settings
* Scan History

---

## 🧠 AI Model

* **EfficientNetB7** trained on a custom Sri Lankan food dataset
* Exported to **TFLite** for mobile inference
* Temporarily hosted via **Firebase tunnel** due to large model size

---

## 🛠️ Technology Stack

| Component   | Technology                          |
| ----------- | ----------------------------------- |
| UI/UX       | Figma                               |
| Mobile App  | Flutter (Dart)                      |
| ML Model    | TFLite (EfficientNetB7 pre-trained) |
| Backend     | Firebase Firestore & Auth           |
| PDF Reports | Flutter pdf & printing packages     |

---

## 💻 How It Works

1. User logs in / signs up via Firebase Authentication
2. Captures or selects a food image
3. ML model recognizes the food and estimates calories
4. App calculates BMI and provides personalized suggestions
5. User can track hydration and view monthly diet reports in PDF

---

## 👨‍💻 Team Members – Group 01

* W.A.D.N. Wickramarachchi
* T.L. Wannniarachchi
* M.H.F Hasna
* D.T.S.K. Jayathissa
* G.T.S. Madhuwanthi

---
![Uploading Gemini_Generated_Image_1qcx381qcx381qcx.png…]()

---
## 📄 License

This project is developed for academic purposes under the **University of Sri Jayewardenepura – Faculty of Technology**.
