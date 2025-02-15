import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CourseSetupScreen extends StatelessWidget {
  final TextEditingController courseIdController = TextEditingController();
  final TextEditingController startDnoController = TextEditingController();
  final TextEditingController endDnoController = TextEditingController();
  final String staffName;

  CourseSetupScreen({super.key, required this.staffName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Course')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: courseIdController,
              decoration: const InputDecoration(labelText: 'Course Name'),
            ),
            TextField(
              controller: startDnoController,
              decoration: const InputDecoration(labelText: 'Starting D.no'),
              inputFormatters: [LengthLimitingTextInputFormatter(8)],
            ),
            TextField(
              controller: endDnoController,
              decoration: const InputDecoration(labelText: 'Ending D.no'),
              inputFormatters: [LengthLimitingTextInputFormatter(8)],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  final courseText = courseIdController.text;
                  final courseName = courseText.isNotEmpty ? courseText : null;
                  final startDnoText = startDnoController.text;
                  final endDnoText = endDnoController.text;

                  // Split the startDnoText into details and dno
                  if (startDnoText.length != 8 || endDnoText.length != 8) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('D.no must be exactly 8 characters')),
                    );
                    return;
                  }

                  final startDetails =
                      startDnoText.substring(0, 5); // First 5 characters
                  final startDno = int.tryParse(
                      startDnoText.substring(5, 8)); // Last 3 characters
                  final endDno = int.tryParse(
                      endDnoText.substring(5, 8)); // Last 3 characters

                  if (courseName == null ||
                      startDno == null ||
                      endDno == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please fill all fields correctly')),
                    );
                    return;
                  }

                  final courseRef = FirebaseFirestore.instance
                      .collection('Courses')
                      .doc(courseName);
                  final existingCourse = await courseRef.get();

                  final staffRef = FirebaseFirestore.instance
                      .collection('Staffs')
                      .doc(staffName);

                  if (existingCourse.exists) {
                    final action = await showDialog<String>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Course Already Exists'),
                          content: const Text(
                              'A course with this name already exists. Do you want to collaborate with it or create a new course with a different name?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'collab'),
                              child: const Text('Collaborate'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, 'new'),
                              child: const Text('Create New'),
                            ),
                          ],
                        );
                      },
                    );

                    if (action == 'collab') {
                      var staffCourseRef =
                          staffRef.collection('courses').doc(courseName);
                      await staffRef.set(
                          {'staffName': staffName}, SetOptions(merge: true));
                      await staffCourseRef
                          .set({'courseName': courseName, 'totalex': 10});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Collaborating with existing course!')),
                      );
                      return;
                    } else if (action == 'new') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a new course name!')),
                      );
                      return;
                    }
                  }

                  var staffCourseRef =
                      staffRef.collection('courses').doc(courseName);
                  await staffCourseRef
                      .set({'courseName': courseName, 'totalex': 10});

                  await courseRef.set({
                    'courseName': courseName,
                    'totalex': 10,
                    'classdetails': startDetails // Save the first 5 characters
                  });
                  print('Course document created successfully.');

                  WriteBatch batch = FirebaseFirestore.instance.batch();
                  for (int i = 1; i <= 10; i++) {
                    final exRef = courseRef.collection("Ex $i");

                    for (int dno = startDno; dno <= endDno; dno++) {
                      DocumentReference docRef = exRef.doc(dno.toString());
                      batch.set(docRef, {'preparationMark': 0, 'vivaVoce': 0});
                    }

                    DocumentReference dateRef = exRef.doc("date");
                    batch.set(dateRef, {'date': null});
                  }
                  await batch.commit();
                  print('Course setup complete.');

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Course setup successfully!')),
                  );
                } catch (e) {
                  print('Error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Create Course'),
            ),
          ],
        ),
      ),
    );
  }
}
