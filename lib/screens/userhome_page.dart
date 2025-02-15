import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:markit/screens/coursesetup_page.dart';
import 'package:markit/screens/login_page.dart';
import 'package:markit/screens/markentry_page.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserhomePage extends StatefulWidget {
  final String name; // Staff name
  UserhomePage({super.key, required this.name});

  @override
  State<UserhomePage> createState() => _UserhomePageState();
}

class _UserhomePageState extends State<UserhomePage> {
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
  }

  // Function to generate and download the PDF
// Function to generate and download the PDF
  Future<void> _generateAndDownloadPDF(String courseId) async {
    final pdf = pw.Document();

    try {
      // Fetch course data to determine total exercises
      final courseSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(courseId)
          .get();

      final courseData = courseSnapshot.data();
      final totalExercises = courseData?['totalex'] ?? 0;
      final details = courseData?['classdetails'] ?? 0;
      print('Class Details: $details');

      // Generate list of exercises (e.g., Ex1, Ex2, ..., ExN)
      List<String> exerciseList =
          List.generate(totalExercises, (index) => 'Ex ${index + 1}');
      print('Total Exercises: $totalExercises');

      // Dynamically fetch Dno IDs from the first exercise (assuming consistency)
      final firstExercise = exerciseList.first;
      final dnoSnapshots = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(courseId)
          .collection(firstExercise)
          .get();

      // Collect Dno values dynamically
      final List<int> dnoList = dnoSnapshots.docs
          .map((doc) => int.tryParse(doc.id) ?? -1) // Parse Dno as int
          .where((dno) => dno != -1) // Filter out invalid Dno values
          .toList();
      dnoList.sort(); // Sort Dno list if needed

      print('Fetched Dnos: $dnoList');

      if (dnoList.isEmpty) {
        print('No Dno documents found for $firstExercise');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No Dno records found for $courseId')),
        );
        return;
      }

      // Fetch marks for all exercises and Dnos
      List<Map<String, dynamic>> marksData = [];
      for (var dno in dnoList) {
        final row = {'Dno': dno}; // Initialize row with Dno

        for (var exercise in exerciseList) {
          final markDoc = await FirebaseFirestore.instance
              .collection('Courses')
              .doc(courseId)
              .collection(exercise)
              .doc(dno.toString())
              .get();

          final detailsref = await FirebaseFirestore.instance
              .collection('Courses')
              .doc(courseId)
              .get();

          final markData = markDoc.data();

          final prepMark = markData?.containsKey('preparationMark') == true
              ? markData!['preparationMark']
              : 0;

          final vivaMark = markData?.containsKey('vivaVoce') == true
              ? markData!['vivaVoce']
              : 0;

          row['${exercise}_prep'] = _parseMark(prepMark);
          row['${exercise}_viva'] = _parseMark(vivaMark);
        }

        marksData.add(row);
      }

      print('Marks Data: $marksData');

      // PDF Table Headers
      final headers = [
        'Dno',
        for (var ex in exerciseList) '$ex PR', // Preparation Mark as PR
        for (var ex in exerciseList) '$ex OP/VV', // Viva Voce as OP/VV
      ];

      // Table Rows
      final dataRows = marksData.map((row) {
        return [
          '$details${row['Dno']}',
          for (var ex in exerciseList) row['${ex}_prep'].toString(),
          for (var ex in exerciseList) row['${ex}_viva'].toString(),
        ];
      }).toList();

      print('Data Rows: $dataRows');

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(
                'Marks Report - $courseId',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'D.no',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      for (var ex in exerciseList) ...[
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            ex,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ]
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Container(),
                      for (var ex in exerciseList)
                        pw.Column(
                          children: [
                            pw.Text(
                              'PP',
                              style: pw.TextStyle(fontSize: 10),
                            ),
                            pw.Text(
                              'OP',
                              style: pw.TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                    ],
                  ),
                  for (var row in marksData)
                    pw.TableRow(
                      children: [
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '$details${row['Dno']}',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        for (var ex in exerciseList)
                          pw.Column(
                            children: [
                              pw.Text(
                                row['${ex}_prep'].toString(),
                                style: pw.TextStyle(fontSize: 10),
                              ),
                              pw.Text(
                                row['${ex}_viva'].toString(),
                                style: pw.TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                      ],
                    ),
                ],
              ),
            ],
          );
        },
      ));
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF for $courseId Generated Successfully')),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    }
  }

  dynamic _parseMark(dynamic mark) {
    if (mark == null) return '-';
    if (mark is int || mark is double) return mark;
    return int.tryParse(mark.toString()) ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.name,
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh), // Refresh Button
            onPressed: () {
              setState(() {}); // Reloads the page by triggering a rebuild
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await clearUserData();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => loginPage()),
              );
            },
          ),
        ],
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 224, 147, 238),
      ),
      body: Column(
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                "Courses",
                style: TextStyle(fontSize: 31, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('Staffs')
                  .doc(widget.name)
                  .collection('courses')
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No courses found"),
                  );
                }

                final courses = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final courseName = courses[index].id;
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(
                          courseName,
                          style: const TextStyle(fontSize: 18),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () {
                            _generateAndDownloadPDF(courseName);
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MarksEntryScreen(
                                      courseId: '$courseName',
                                    )),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseSetupScreen(
                    staffName: widget.name,
                  ),
                ),
              );
            },
            child: Text('Create Course'),
          ),
        ],
      ),
    );
  }
}
