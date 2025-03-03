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
  bool issame() {
    return passtxt1.text == passtxt2.text;
  }

  void signupUser() async {
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
    if (issame()) {
      String res = await Authentication().signupUser(
          email: emailtxt.text, password: passtxt1.text, name: nametxt.text);
      if (res == "Success") {
        print("Success");
        Navigator.pop(context);
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => UserhomePage(
                      name: nametxt.text,
                    )));
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password are not same")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 20.0),
                    child: Text(
                      "Sign up",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 35),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: Image.asset("lib/asserts/logo.jpg",
                      height: 200, width: 200),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 40.0, right: 40.0, top: 30),
                  child: TextField(
                    controller: emailtxt,
                    decoration: InputDecoration(
                        hintText: "Enter your mail ",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        suffixIcon: const Icon(Icons.mail)),
                  ),
                ),
                Padding(
                    padding:
                        const EdgeInsets.only(left: 40.0, right: 40.0, top: 30),
                    child: TextField(
                        controller: nametxt,
                        decoration: InputDecoration(
                            hintText: "Enter your name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            suffixIcon: const Icon(Icons.person)))),
                Padding(
                    padding:
                        const EdgeInsets.only(left: 40.0, right: 40.0, top: 30),
                    child: TextField(
                        controller: passtxt1,
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
                            child: Icon(!isvisible
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ))),
                Padding(
                    padding:
                        const EdgeInsets.only(left: 40.0, right: 40.0, top: 30),
                    child: TextField(
                        controller: passtxt2,
                        obscureText: !isvisible1,
                        decoration: InputDecoration(
                          hintText: "Confirm password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          suffixIcon: InkWell(
                            onTap: () => setState(() {
                              isvisible1 = !isvisible1;
                            }),
                            child: Icon(!isvisible1
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ))),
                Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: ElevatedButton(
                    // ignore: avoid_print
                    onPressed: () {
                      signupUser();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      minimumSize: const Size(135, 53),
                    ),
                    child: const Text(
                      "Sign up",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const loginPage()));
                  },
                  child: const Text(
                    "Already Have an account?",
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.lightBlue,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
