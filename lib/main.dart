import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:markit/screens/login_page.dart';
import 'package:markit/screens/userhome_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Student Marks App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue),
        home: UserhomePage(name: "arock"));
  }
}
