import 'package:flutter/material.dart';
import 'package:markit/authentication.dart';
import 'package:markit/backend/backend_operation.dart';
import 'package:markit/screens/signup_page.dart';

// ignore: camel_case_types
class loginPage extends StatefulWidget {
  const loginPage({super.key});

  @override
  State<loginPage> createState() => _loginPageState();
}

// ignore: camel_case_types
class _loginPageState extends State<loginPage> {
  final CreateUser = BackendOperation();
  bool isvisible = false;
  TextEditingController emailtxt = TextEditingController();
  TextEditingController passtxt = TextEditingController();
  void loginUser() async {
    String res = await Authentication()
        .loginUser(email: emailtxt.text, password: passtxt.text);
    if (res == "Success") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully logged In')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: Column(
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, 95, 0, 0),
              child: Text(
                "Log in",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 35),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.only(left: 40.0, right: 40.0, top: 60),
            child: TextField(
              controller: emailtxt,
              style: TextStyle(),
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
                  ))),
          Padding(
            padding: const EdgeInsets.only(top: 30.0),
            child: ElevatedButton(
              // ignore: avoid_print
              onPressed: () {
                CreateUser.read();
                loginUser();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 95, 57, 102),
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
              Text("No account? "),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignupPage()));
                },
                child: const Text(
                  "Signup",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
