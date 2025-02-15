import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:markit/screens/login_page.dart';
import 'package:markit/screens/userhome_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final userData = await getUserData();
  await Firebase.initializeApp();
  runApp(MyApp(userData: userData));
}

Future<Map<String, String?>> getUserData() async {
  final prefs = await SharedPreferences.getInstance();
  return {'name': prefs.getString('userName')};
}

class MyApp extends StatelessWidget {
  final Map<String, String?> userData;
  const MyApp({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Marks App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: userData['name'] != null
          ? UserhomePage(name: userData['name']!)
          : loginPage(),
    );
  }
}
