import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MonthlyProgressScreen extends StatefulWidget {
  const MonthlyProgressScreen({super.key});

  @override
  State<MonthlyProgressScreen> createState() => _MonthlyProgressScreenState();
}

class _MonthlyProgressScreenState extends State<MonthlyProgressScreen> {
  final Color primaryColor = const Color.fromARGB(255, 246, 124, 42);
  String userName = 'User';
  int age = 0;
  int totalCalories = 2000;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      final userData = userDoc.data()!;
      setState(() {
        userName = userData['name'] ?? 'User';
        age = userData['age'] ?? 0;
        totalCalories = userData['calorieGoal'] ?? 2000;
      });
    }
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Monthly Progress',
          style: GoogleFonts.poppins(
            color: primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download, color: primaryColor),
            onPressed: () async {
              final querySnapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('user_daily_progress')
                  .where(
                    'date',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo),
                  )
                  .orderBy('date', descending: true)
                  .get();

              if (querySnapshot.docs.isNotEmpty) {
                await _generateAndDownloadPdf(querySnapshot.docs);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No data available for PDF')),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('user_daily_progress')
            .where(
              'date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo),
            )
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No records found for the last 30 days.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp?)?.toDate();
              final consumedCalories = data['consumedCalories'] ?? 0;
              final waterIntake = data['waterIntake'] ?? 0;
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
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
                            height: 70,
                            width: 70,
                            child: CircularProgressIndicator(
                              value: totalCalories > 0
                                  ? consumedCalories / totalCalories
                                  : 0,
                              strokeWidth: 8,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            totalCalories > 0
                                ? '${((consumedCalories / totalCalories) * 100).toInt()}%'
                                : '0%',
                            style: const TextStyle(
                              fontSize: 14,
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
                            Text(
                              date != null
                                  ? '${date.month}/${date.day}/${date.year}'
                                  : 'Unknown Date',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$consumedCalories Kcal Eaten',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Water: $waterIntake cups',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
