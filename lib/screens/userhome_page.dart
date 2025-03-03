import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:markit/screens/coursesetup_page.dart';
import 'package:markit/screens/login_page.dart';
import 'package:markit/screens/markentry_page.dart';
import 'package:markit/screens/profile.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _generateAndDownloadPDF(String courseId) async {
    final pdf = pw.Document();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Row(
            children: const [
              CircularProgressIndicator(color: Colors.deepPurple),
              SizedBox(width: 16),
              Text("Preparing PDF..."),
            ],
          ),
        );
      },
    );

    try {
      // Fetch course data to determine total exercises
      final courseSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(courseId)
          .get();
      final name = widget.name;
      final courseData = courseSnapshot.data();
      final totalExercises = courseData?['totalex'] ?? 0;
      final details = courseData?['classdetails'] ?? 'N/A';
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
      List<Future<void>> markFutures = [];
      List<Map<String, dynamic>> marksData = [];
      for (var dno in dnoList) {
        final row = {'Dno': dno};

        for (var exercise in exerciseList) {
          final future = FirebaseFirestore.instance
              .collection('Courses')
              .doc(courseId)
              .collection(exercise)
              .doc(dno.toString())
              .get()
              .then((markDoc) {
            final data = markDoc.data() ?? {};

            final prepMark = data['preparationMark'] ?? 0;
            final vivaMark = data['vivaVoce'] ?? 0;

            row['${exercise}_prep'] = _parseMark(prepMark);
            row['${exercise}_viva'] = _parseMark(vivaMark);
          });

          markFutures.add(future);
        }

        // Add completed row after fetching all exercises
        markFutures.add(Future(() => marksData.add(row)));
      }

      await Future.wait(markFutures);

      // Fetch dates for all exercises
      Map<String, String> exerciseDates = {};
      for (var exercise in exerciseList) {
        final dateDoc = await FirebaseFirestore.instance
            .collection('Courses')
            .doc(courseId)
            .collection(exercise)
            .doc('date')
            .get();

        if (dateDoc.exists) {
          final dateData = dateDoc.data();
          final date = dateData?['date'] as String?; // Fetch date as a string
          exerciseDates[exercise] =
              date ?? 'No Date'; // Use the date or 'No Date' if null
        } else {
          exerciseDates[exercise] = 'No Date';
        }
      }

      print('Exercise Dates: $exerciseDates');

      // PDF Table Headers
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4, // Keep Portrait
          build: (pw.Context context) => [
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text('MARK REPORT',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 20)),
            ),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Course Name: ',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight:
                              pw.FontWeight.normal, // Regular text for label
                        ),
                      ),
                      pw.Text(
                        courseId, // Course name in bold
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight:
                              pw.FontWeight.bold, // Bold for the course name
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Staff Name: ',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight:
                              pw.FontWeight.normal, // Regular text for label
                        ),
                      ),
                      pw.Text(
                        name, // Staff name in bold
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight:
                              pw.FontWeight.bold, // Bold for the staff name
                        ),
                      ),
                    ],
                  ),
                ]),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                // Table Header Row
                pw.TableRow(
                  children: [
                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('D.no',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ),
                    for (var ex in exerciseList)
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Column(
                          children: [
                            pw.Text(ex, style: pw.TextStyle(fontSize: 9)),
                            pw.Text(exerciseDates[ex] ?? 'No Date',
                                style: pw.TextStyle(fontSize: 7)),
                          ],
                        ),
                      ),
                  ],
                ),
                // Subheader Row for PP/OP
                pw.TableRow(
                  children: [
                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    for (var _ in exerciseList)
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('PP/OP',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 8)),
                      ),
                  ],
                ),
                // Data Rows
                for (var row in marksData)
                  pw.TableRow(
                    children: [
                      pw.Container(
                        alignment: pw.Alignment.center,
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('$details${row['Dno']}',
                            style: pw.TextStyle(fontSize: 9)),
                      ),
                      for (var ex in exerciseList)
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                              '${row['${ex}_prep']} / ${row['${ex}_viva']}',
                              style: pw.TextStyle(fontSize: 9)),
                        ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      );
      // Save and open the PDF
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF for $courseId Generated Successfully')),
      );
    } catch (e) {
      Navigator.pop(context);

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
        automaticallyImplyLeading: false,
        title: Text(
          (widget.name).toUpperCase(),
          style: TextStyle(
              fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: Builder(
          // Fix for missing menu icon
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {});
            },
          ),
        ],
        centerTitle: true,
        backgroundColor: Colors.deepPurple, // A more professional color
        elevation: 10, // Adds a subtle shadow
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.account_circle, size: 60, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    widget.name.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person, color: Colors.deepPurple),
              title: Text("Profile"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Profile(),
                  ),
                );
              },
            ),
            ListTile(
                leading: Icon(Icons.info, color: Colors.deepPurple),
                title: Text("About"),
                onTap: () async {
                  final Uri url = Uri.parse("https://www.sjctni.edu/");
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Could not launch URL")),
                    );
                  }
                }),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.deepPurple),
              title: Text("Logout"),
              onTap: () async {
                await clearUserData();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => loginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Text(
              "COURSES",
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 49, 34, 16)),
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
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Colors.deepPurple));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No courses found",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                final courses = snapshot.data!.docs;

                // Fetch classdetails for all courses asynchronously
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchCourseDetails(courses),
                  builder: (context, detailsSnapshot) {
                    if (detailsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Colors.deepPurple));
                    }

                    if (!detailsSnapshot.hasData ||
                        detailsSnapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          "No course details found",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      );
                    }

                    final courseDetails = detailsSnapshot.data!;

                    return ListView.builder(
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final courseName = courses[index].id;
                          final details = (courseDetails[index]
                                      ['classdetails'] ??
                                  'N/A'.toString())
                              .toUpperCase();
                          final nm = courseName.toUpperCase();

                          return Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              elevation: 4, // Adds a subtle shadow
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    12), // Rounded corners
                              ),
                              child: ListTile(
                                  title: Text(
                                    "$nm - $details",
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.download,
                                        color: Colors.deepPurple),
                                    onPressed: () {
                                      _generateAndDownloadPDF(courseName);
                                    },
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              MarksEntryScreen(
                                                courseId: '$courseName',
                                              )),
                                    );
                                  },
                                  onLongPress: () => showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Course'),
                                          content: Text(
                                              'Are you sure you want to delete course named $courseName?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                await FirebaseFirestore.instance
                                                    .collection('Staffs')
                                                    .doc(widget.name)
                                                    .collection('courses')
                                                    .doc(courseName)
                                                    .delete();
                                                await FirebaseFirestore.instance
                                                    .collection("Courses")
                                                    .doc(courseName)
                                                    .delete();

                                                Navigator.pop(context);
                                                setState(() {});
                                              },
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      )));
                        });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple, // Button color
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                ),
              ),
              child: const Text(
                'Create Course',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to fetch classdetails for all courses
  Future<List<Map<String, dynamic>>> _fetchCourseDetails(
      List<QueryDocumentSnapshot> courses) async {
    List<Map<String, dynamic>> courseDetails = [];

    for (final course in courses) {
      final courseName = course.id;
      final courseDoc = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(courseName)
          .get();

      final details = courseDoc.data()?['classdetails'] ?? 'N/A';
      courseDetails.add({'courseName': courseName, 'classdetails': details});
    }

    return courseDetails;
  }
}
