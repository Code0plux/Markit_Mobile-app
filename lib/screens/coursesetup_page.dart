import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CourseSetupScreen extends StatelessWidget {
  final TextEditingController courseIdController = TextEditingController();
  final TextEditingController startDnoController = TextEditingController();
  final TextEditingController endDnoController = TextEditingController();
  final String staffName = "arock";

  CourseSetupScreen({super.key}); // Staff name (fixed for this example)

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
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: endDnoController,
              decoration: const InputDecoration(labelText: 'Ending D.no'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final courseName = courseIdController.text.trim();
                final startDno = int.tryParse(startDnoController.text.trim());
                final endDno = int.tryParse(endDnoController.text.trim());

                if (courseName.isEmpty || startDno == null || endDno == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please fill all fields correctly')),
                  );
                  return;
                }

                // Reference the staff's document
                final staffRef = FirebaseFirestore.instance
                    .collection('Staffs')
                    .doc(staffName);

                // Ensure the staff document exists
                await staffRef
                    .set({'staffName': staffName}, SetOptions(merge: true));

                // Add the course name under the staff's courses sub-collection
                var courseRef = staffRef.collection('courses').doc(courseName);

                // Create the course document under the staff
                await courseRef.set({'courseName': courseName, 'totalex': 10});
                courseRef = FirebaseFirestore.instance
                    .collection('Courses')
                    .doc(courseName);

                await courseRef.set({'courseName': courseName, 'totalex': 10});

                for (int i = 1; i <= 10; i++) {
                  // Add D.no data as sub-collections/documents
                  final exRef = courseRef.collection("Ex $i");

                  // Create D.no documents
                  for (int dno = startDno; dno <= endDno; dno++) {
                    await exRef.doc(dno.toString()).set({
                      'preparationMark': 0,
                      'vivaVoce': 0,
                    });
                  }

                  // Create the date document
                  await exRef.doc("date").set({
                    'date': null,
                  });
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Course setup successfully!')),
                );
              },
              child: const Text('Create Course'),
            ),
          ],
        ),
      ),
    );
  }
}
