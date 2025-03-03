import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:markit/authentication.dart';
import 'package:markit/screens/signup_page.dart';
import 'package:markit/screens/userhome_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class loginPage extends StatefulWidget {
  const loginPage({super.key});

  @override
  State<loginPage> createState() => _loginPageState();
}

class _loginPageState extends State<loginPage> {
  bool isvisible = false;
  TextEditingController emailtxt = TextEditingController();
  TextEditingController passtxt = TextEditingController();

  Future<void> saveUserData(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
  }

  void loginUser() async {
    // Show the loading dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents the user from closing the dialog
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            color: Colors.deepPurple,
          ),
        );
      },
    );

    // Login the user
    String res = await Authentication()
        .loginUser(email: emailtxt.text, password: passtxt.text);

    if (res == "Success") {
      try {
        // Get the current user's UID
        String uid = FirebaseAuth.instance.currentUser!.uid;

        // Fetch user details from Firestore using UID
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("staffs")
            .doc(uid)
            .get();

        if (userDoc.exists) {
          // Extract the user's name
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          String userName = userData["name"];

          // Close the loading dialog
          Navigator.of(context).pop();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully logged In')),
          );
          await saveUserData(userName);
          // Navigate to the UserhomePage with the name
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserhomePage(
                name: userName, // Pass the user's name to the next screen
              ),
            ),
          );
        } else {
          throw Exception("User document not found");
        }
      } catch (e) {
        Navigator.of(context).pop(); // Close the loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to fetch user details: ${e.toString()}")),
        );
      }
    } else {
      Navigator.of(context).pop(); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 95, 0, 0),
                child: Text(
                  "Log In",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 35),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: Image.asset("lib/asserts/logo.jpg", height: 200, width: 200),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.only(left: 40.0, right: 40.0, top: 30),
              child: TextField(
                controller: emailtxt,
                decoration: InputDecoration(
                    hintText: "Enter Your Mail",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    suffixIcon: const Icon(Icons.mail)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 40.0, right: 40.0, top: 30),
              child: TextField(
                controller: passtxt,
                obscureText: !isvisible,
                decoration: InputDecoration(
                  hintText: "Enter password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  suffixIcon: InkWell(
                    onTap: () => setState(() {
                      isvisible = !isvisible;
                    }),
                    child: Icon(
                        !isvisible ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 40.0, top: 8),
                child: TextButton(
                  onPressed: () async {
                    if (emailtxt.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Please enter your email first.")),
                      );
                      return;
                    }

                    try {
                      await FirebaseAuth.instance
                          .sendPasswordResetEmail(email: emailtxt.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Password reset email sent.")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: ${e.toString()}")));
                    }
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Color(0xFF58B4FF), // Light Blue Color
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30.0),
              child: ElevatedButton(
                onPressed: () {
                  loginUser();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  minimumSize: const Size(135, 53),
                ),
                child: const Text(
                  "Log in",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("No account? "),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupPage()),
                    );
                  },
                  child: const Text(
                    "Signup",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 88, 180, 255),
                      fontWeight: FontWeight.bold,
                    ),
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
