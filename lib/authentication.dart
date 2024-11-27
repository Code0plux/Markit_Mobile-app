import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Authentication {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<String> signupUser({
    required String email,
    required String password,
  }) async {
    String res = "Some error occured";
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await _firestore.collection("User").doc(credential.user!.uid).set({
        "email": email,
        "uid": credential.user!.uid,
      });
      res = "Success";
    } catch (e) {
      res = e.toString().split('] ').last;
    }
    return res;
  }

  Future<String> loginUser(
      {required String email, required String password}) async {
    String res = "Error occured";
    try {
      if (email.isNotEmpty && password.isNotEmpty) {
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);
        res = "Success";
      } else {
        res = "Enter all the field";
      }
    } catch (e) {
      res = e.toString().split('] ').last;
    }
    return res;
  }
}
