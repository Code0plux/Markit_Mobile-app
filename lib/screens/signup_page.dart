import 'package:flutter/material.dart';
import 'package:markit/authentication.dart';
import 'package:markit/screens/login_page.dart';
import 'package:markit/screens/userhome_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  TextEditingController emailtxt = TextEditingController();
  TextEditingController passtxt1 = TextEditingController();
  TextEditingController passtxt2 = TextEditingController();
  TextEditingController nametxt = TextEditingController();
  bool isvisible = false;
  bool isvisible1 = false;

  bool validateFields() {
    if (nametxt.text.isEmpty ||
        emailtxt.text.isEmpty ||
        passtxt1.text.isEmpty ||
        passtxt2.text.isEmpty) {
      showError("All fields are required.");
      return false;
    }
    if (!RegExp(r"^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+$").hasMatch(emailtxt.text)) {
      showError("Enter a valid email.");
      return false;
    }
    if (passtxt1.text.length < 6) {
      showError("Password must be at least 6 characters.");
      return false;
    }
    if (passtxt1.text != passtxt2.text) {
      showError("Passwords do not match.");
      return false;
    }
    return true;
  }

  void showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void signupUser() async {
    if (!validateFields()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
            child: CircularProgressIndicator(color: Colors.deepPurple));
      },
    );

    String res = await Authentication().signupUser(
        email: emailtxt.text, password: passtxt1.text, name: nametxt.text);

    Navigator.pop(context);

    if (res == "Success") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => UserhomePage(name: nametxt.text)),
      );
    } else {
      showError(res);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Text("Sign up",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 35)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: Image.asset("lib/asserts/logo.jpg",
                    height: 200, width: 200),
              ),
              const SizedBox(height: 30),
              inputField(emailtxt, "Enter your email", Icons.mail),
              inputField(nametxt, "Enter your name", Icons.person),
              passwordField(passtxt1, "Enter password", isvisible,
                  () => setState(() => isvisible = !isvisible)),
              passwordField(passtxt2, "Confirm password", isvisible1,
                  () => setState(() => isvisible1 = !isvisible1)),
              Padding(
                padding: const EdgeInsets.only(top: 30.0),
                child: ElevatedButton(
                  onPressed: signupUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)),
                    minimumSize: const Size(135, 53),
                  ),
                  child: const Text("Sign up",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const loginPage())),
                child: const Text("Already Have an account?",
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.lightBlue,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget inputField(
      TextEditingController controller, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 40.0, right: 40.0, top: 20),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          suffixIcon: Icon(icon),
        ),
      ),
    );
  }

  Widget passwordField(TextEditingController controller, String hint,
      bool isVisible, VoidCallback toggleVisibility) {
    return Padding(
      padding: const EdgeInsets.only(left: 40.0, right: 40.0, top: 20),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
          suffixIcon: InkWell(
              onTap: toggleVisibility,
              child: Icon(isVisible ? Icons.visibility : Icons.visibility_off)),
        ),
      ),
    );
  }
}
