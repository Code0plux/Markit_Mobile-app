import 'package:cloud_firestore/cloud_firestore.dart';

class BackendOperation {
  final _firestore = FirebaseFirestore.instance;

  create() {
    _firestore.collection("Staff").add({"Name": "Arockiam", "Role": "Hod"});
  }

  read() async {
    final data = await _firestore.collection("Staff").get();
    final user = data.docs[0];
    print(user["Name"]);
  }

  update() {
    _firestore
        .collection("Staff")
        .doc("ilwM7TUd1vDvG2CbFBQ3")
        .update({"Name": "Maheswaran", "Role": "Associate Professor"});
  }

  delete() {
    _firestore.collection("Staff").doc("ilwM7TUd1vDvG2CbFBQ3").delete();
  }
}
