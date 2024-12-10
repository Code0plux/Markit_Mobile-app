import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Authentication {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> signupUser({
    required String email,
    required String password,
    required String name,
  }) async {
    String res = "Some error occurred";
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _firestore.collection("staffs").doc(credential.user!.uid).set({
        "email": email,
        "uid": credential.user!.uid,
        "name": name,
      });
      res = "Success";
    } catch (e) {
      res = e.toString().split('] ').last;
    }
    return res;
  }

  Future<String> loginUser({
    required String email,
    required String password,
  }) async {
    String res = "Error occurred";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
            email: email, password: password);

        // Fetch user details after login
        String uid = userCredential.user!.uid;
        DocumentSnapshot userDoc =
            await _firestore.collection("staffs").doc(uid).get();

        if (userDoc.exists) {
          // User found
          res = "Success";
        } else {
          res = "User not found in database";
        }
      } else {
        res = "Enter all the fields";
      }
    } catch (e) {
      res = e.toString().split('] ').last;
    }
    return res;
  }
}
