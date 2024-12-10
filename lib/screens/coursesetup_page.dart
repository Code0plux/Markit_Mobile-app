import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CourseSetupScreen extends StatelessWidget {
  final TextEditingController courseIdController = TextEditingController();
  final TextEditingController startDnoController = TextEditingController();
  final TextEditingController endDnoController = TextEditingController();
  final TextEditingController exerciseController = TextEditingController();
  final String staffName = "arock"; // Staff name (fixed for this example)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Setup Course')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: courseIdController,
              decoration: InputDecoration(labelText: 'Course Name'),
            ),
            TextField(
              controller: startDnoController,
              decoration: InputDecoration(labelText: 'Starting D.no'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: endDnoController,
              decoration: InputDecoration(labelText: 'Ending D.no'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: exerciseController,
              decoration: InputDecoration(labelText: 'Number of Exercises'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final courseName = courseIdController.text.trim();
                final startDno = int.tryParse(startDnoController.text.trim());
                final endDno = int.tryParse(endDnoController.text.trim());
                final exercise = int.tryParse(exerciseController.text.trim());

                if (courseName.isEmpty ||
                    startDno == null ||
                    endDno == null ||
                    exercise == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill all fields correctly')),
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
                await courseRef.set({'courseName': courseName});
                courseRef = FirebaseFirestore.instance
                    .collection('Courses')
                    .doc(courseName);

                await courseRef.set({'courseName': courseName});
                for (int i = 1; i <= exercise; i++) {
                  // Add D.no data as sub-collections/documents
                  for (int dno = startDno; dno <= endDno; dno++) {
                    await courseRef
                        .collection("Ex $i")
                        .doc(dno.toString())
                        .set({
                      'preparationMark': 0,
                      'vivaVoce': 0,
                    });
                  }
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Course setup successfully!')),
                );
              },
              child: Text('Create Course'),
            ),
          ],
        ),
      ),
    );
  }
}
