import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MarksEntryScreen extends StatefulWidget {
  final String courseId;

  const MarksEntryScreen({super.key, required this.courseId});

  @override
  _MarksEntryScreenState createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends State<MarksEntryScreen> {
  late int startDno;
  late int endDno;
  late int currentDno;
  String? selectedExercise;
  late String courseDetails;
  List<String> exerciseList = [];
  final TextEditingController preparationMarkController =
      TextEditingController();
  final TextEditingController vivaVoceController = TextEditingController();
  final TextEditingController dnoController = TextEditingController();
  bool isLoading = false;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    fetchCourseDetails();
  }

  Future<void> fetchCourseDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch course data
      final courseSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(widget.courseId)
          .get();

      final courseData = courseSnapshot.data();
      if (courseData != null) {
        fetchExercises(); // Fetch exercises first to determine Dno range
      }
    } catch (e) {
      print('Error fetching course details: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchExercises() async {
    setState(() {
      isLoading = true;
    });

    try {
      final courseSnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(widget.courseId)
          .get();

      final courseData = courseSnapshot.data();
      final totalExercises = courseData?['totalex'] ?? 0;

      // Generate exercise list
      exerciseList =
          List.generate(totalExercises, (index) => 'Ex ${index + 1}');
      if (exerciseList.isNotEmpty) {
        selectedExercise = exerciseList.first;
        await fetchDnoRange(
            selectedExercise!); // Fetch the Dno range dynamically
        fetchMarks(); // Fetch marks for the first Dno
        fetchDate(); // Fetch date for the first exercise
      }
    } catch (e) {
      print('Error fetching exercises: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchDnoRange(String exercise) async {
    try {
      // Fetch all document IDs (D.nos) from Firebase
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Courses')
          .doc(widget.courseId)
          .collection(exercise)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Extract and sort D.no values
        final docIds = querySnapshot.docs
            .map((doc) => int.tryParse(doc.id))
            .whereType<int>()
            .toList();
        docIds.sort();

        // Set startDno and endDno dynamically
        startDno = docIds.first;
        endDno = docIds.last;
        currentDno = startDno;

        // Update UI
        setState(() {
          dnoController.text = currentDno.toString();
        });

        // Fetch initial marks
        fetchMarks();
      } else {
        throw Exception('No documents found in exercise collection');
      }
    } catch (e) {
      print('Error fetching Dno range: $e');
      startDno = 1;
      endDno = 1;
      currentDno = startDno;
      setState(() {
        dnoController.text = currentDno.toString();
      });
    }
  }

  Future<void> fetchMarks() async {
    if (selectedExercise == null) return;

    final markDoc = await FirebaseFirestore.instance
        .collection('Courses')
        .doc(widget.courseId)
        .collection(selectedExercise!)
        .doc(currentDno.toString())
        .get();

    final markData = markDoc.data();
    if (markData != null) {
      preparationMarkController.text = markData['preparationMark'].toString();
      vivaVoceController.text = markData['vivaVoce'].toString();
    } else {
      preparationMarkController.clear();
      vivaVoceController.clear();
    }
  }

  Future<void> fetchDate() async {
    if (selectedExercise == null) return;

    final dateDoc = await FirebaseFirestore.instance
        .collection('Courses')
        .doc(widget.courseId)
        .collection(selectedExercise!)
        .doc('date')
        .get();

    final dateData = dateDoc.data();
    if (dateData != null && dateData['date'] != null) {
      setState(() {
        selectedDate = DateTime.tryParse(dateData['date']);
      });
    } else {
      setState(() {
        selectedDate = null;
      });
    }
  }

  Future<void> saveDate(DateTime date) async {
    if (selectedExercise == null) return;

    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    await FirebaseFirestore.instance
        .collection('Courses')
        .doc(widget.courseId)
        .collection(selectedExercise!)
        .doc('date')
        .set({'date': formattedDate});

    setState(() {
      selectedDate = date;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Date saved for $selectedExercise')),
    );
  }

  Future<void> saveMarks() async {
    if (selectedExercise == null) return;

    final preparationMark = int.tryParse(preparationMarkController.text) ?? 0;
    final vivaVoce = int.tryParse(vivaVoceController.text) ?? 0;

    await FirebaseFirestore.instance
        .collection('Courses')
        .doc(widget.courseId)
        .collection(selectedExercise!)
        .doc(currentDno.toString())
        .set({
      'preparationMark': preparationMark,
      'vivaVoce': vivaVoce,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Marks saved for Dno $currentDno')),
    );
  }

  void nextDno() async {
    await saveMarks(); // Save current marks before switching

    // Move to the next available D.no
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Courses')
        .doc(widget.courseId)
        .collection(selectedExercise!)
        .get();

    final docIds = querySnapshot.docs
        .map((doc) => int.tryParse(doc.id))
        .whereType<int>()
        .toList();
    docIds.sort();

    int currentIndex = docIds.indexOf(currentDno);
    if (currentIndex != -1 && currentIndex < docIds.length - 1) {
      setState(() {
        currentDno = docIds[currentIndex + 1];
        dnoController.text = currentDno.toString();
      });
      fetchMarks();
    }
  }

  void previousDno() async {
    await saveMarks(); // Save current marks before switching

    final querySnapshot = await FirebaseFirestore.instance
        .collection('Courses')
        .doc(widget.courseId)
        .collection(selectedExercise!)
        .get();

    final docIds = querySnapshot.docs
        .map((doc) => int.tryParse(doc.id))
        .whereType<int>()
        .toList();
    docIds.sort();

    int currentIndex = docIds.indexOf(currentDno);
    if (currentIndex > 0) {
      setState(() {
        currentDno = docIds[currentIndex - 1];
        dnoController.text = currentDno.toString();
      });
      fetchMarks();
    }
  }

  void updateDno() async {
    final newDno = int.tryParse(dnoController.text);
    if (newDno != null && newDno >= startDno && newDno <= endDno) {
      await saveMarks();
      setState(() {
        currentDno = newDno;
      });
      fetchMarks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid Dno')),
      );
    }
  }

  void pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      saveDate(pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Marks Entry - ${widget.courseId.toUpperCase()}', // Convert courseId to uppercase
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple, // Consistent AppBar color
        elevation: 10, // Subtle shadow
        iconTheme:
            const IconThemeData(color: Colors.white), // White back button
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.deepPurple, // Consistent loading indicator color
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dropdown for Exercise Selection
                  DropdownButton<String>(
                    value: selectedExercise,
                    onChanged: (value) {
                      setState(() {
                        selectedExercise = value;
                        currentDno = startDno;
                        dnoController.text = currentDno.toString();
                      });
                      fetchMarks();
                      fetchDate();
                    },
                    items: exerciseList
                        .map((exercise) => DropdownMenuItem(
                              value: exercise,
                              child: Text(
                                exercise
                                    .toUpperCase(), // Convert exercise to uppercase
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.deepPurple, // Consistent color
                                ),
                              ),
                            ))
                        .toList(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.deepPurple, // Consistent color
                    ),
                    dropdownColor: Colors.white, // Dropdown background color
                    icon: Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                    isExpanded: true,
                  ),
                  const SizedBox(height: 20), // Consistent spacing

                  // Date Picker Button
                  ElevatedButton(
                    onPressed: pickDate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.deepPurple, // Consistent button color
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12), // Button padding
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12), // Rounded corners
                      ),
                    ),
                    child: const Text(
                      'Pick Date',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10), // Consistent spacing

                  // Selected Date Display
                  if (selectedDate != null)
                    Text(
                      'Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.deepPurple, // Consistent text color
                      ),
                    ),
                  const SizedBox(height: 20), // Consistent spacing

                  // Preparation Mark TextField
                  TextField(
                    controller: preparationMarkController,
                    decoration: InputDecoration(
                      labelText: 'Preparation Mark',
                      labelStyle: TextStyle(color: Colors.deepPurple),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.deepPurple, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.deepPurple, width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.deepPurple), // Text color
                  ),
                  const SizedBox(height: 20), // Consistent spacing

                  // Viva Voce TextField
                  TextField(
                    controller: vivaVoceController,
                    decoration: InputDecoration(
                      labelText: 'Viva Voce',
                      labelStyle: TextStyle(color: Colors.deepPurple),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.deepPurple, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.deepPurple, width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.deepPurple), // Text color
                  ),
                  const SizedBox(height: 20), // Consistent spacing

                  // Dno Navigation Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Dno Button
                      ElevatedButton(
                        onPressed: previousDno,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.deepPurple, // Consistent button color
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12), // Button padding
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12), // Rounded corners
                          ),
                        ),
                        child: const Text(
                          'Previous Dno',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),

                      // Dno TextField
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: dnoController,
                          decoration: InputDecoration(
                            labelText: 'Dno',
                            labelStyle: TextStyle(color: Colors.deepPurple),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.deepPurple, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Colors.deepPurple, width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          style:
                              TextStyle(color: Colors.deepPurple), // Text color
                          onSubmitted: (value) => updateDno(),
                        ),
                      ),

                      // Next Dno Button
                      ElevatedButton(
                        onPressed: nextDno,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.deepPurple, // Consistent button color
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12), // Button padding
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12), // Rounded corners
                          ),
                        ),
                        child: const Text(
                          'Next Dno',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
