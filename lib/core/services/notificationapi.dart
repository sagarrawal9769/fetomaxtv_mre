import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class NotificationApi {
  final _db = FirebaseFirestore.instance;
  final String? path;
  late CollectionReference ref;

  NotificationApi(this.path) {
    ref = _db.collection(path!);
  }

  Future<QuerySnapshot> getDataCollection() {
    return ref.get();
  }

  Stream<QuerySnapshot> streamDataCollection(String id) {
    return ref
        .where("toId", isEqualTo: id)
        .limit(20)
        .orderBy('createdOn', descending: true)
        .snapshots();
  }

  Future<DocumentSnapshot> getDocumentById(String id) {
    return ref.doc(id).get();
  }

  Future<void> removeDocument(String id) {
    return ref.doc(id).delete();
  }

  Future<DocumentReference> addDocument(Map data) {
    return ref.add(data);
  }

  Future<void> updateDocument(Map<String, dynamic> data, String id) {
    return ref.doc(id).update(data);
  }
}
