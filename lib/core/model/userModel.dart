import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? type;
  String? organizationId;
  String? organizationName;
  String? name;
  String? email;
  String? mobileNo;
  String? uid;
  String? notificationToken;
  String? documentId;
  bool delete = false;
  DateTime? createdOn;
  String? createdBy;
  Map? associations;
  Map? nurturaAssociation;

  UserModel.withData(
      {type,
      organizationId,
      organizationName,
      name,
      email,
      mobileNo,
      uid,
      notificationToken,
      documentId,
      delete = false,
      createdOn,
      createdBy,
      associations,
      nurturaAssociation
      });

  UserModel.fromMap(Map snapshot,String id):
        type = snapshot['type']  ?? '',
        organizationId = snapshot['organizationId'] ?? '',
        organizationName = snapshot['organizationName'] ?? '',
        name = snapshot['name'] ?? '',
        email = snapshot['email'] ?? '',
        mobileNo = snapshot['mobileNo'] ?? '',
        uid = snapshot['uid'] ?? '',
        notificationToken = snapshot['notificationToken'] ?? '',
        documentId = snapshot['documentId'] ?? '',
        delete = snapshot['delete'] ?? false,
        createdOn = snapshot['createdOn']==null?null:snapshot['createdOn'].toDate() ,
        createdBy = snapshot['createdBy'] ?? '',
        associations = snapshot['associations'],
        nurturaAssociation = snapshot['nurturaAssociation'] ?? null;


UserModel();

/*
  User({this.name,
    this.email,
    this.createdOn,
    this.createdBy,
    this.uid,
})
*/

  String? getType() {
    return type;
  }

  void setType(String type) {
    this.type = type;
  }

  String? getOrganizationName() {
    return organizationName;
  }

  void setOrganizationName(String organizationName) {
    this.organizationName = organizationName;
  }

  String? getOrganizationId() {
    return organizationId;
  }

  void setOrganizationId(String organizationId) {
    this.organizationId = organizationId;
  }

  String? getName() {
    return name;
  }

  void setName(String name) {
    this.name = name;
  }

  String? getEmail() {
    return email;
  }

  void setEmail(String email) {
    this.email = email;
  }

  String? getMobileNo() {
    return mobileNo;
  }

  void setMobileNo(String mobileNo) {
    this.mobileNo = mobileNo;
  }

  String? getUid() {
    return uid;
  }

  void setUid(String uid) {
    this.uid = uid;
  }

  String? getNotificationToken() {
    return notificationToken;
  }

  void setNotificationToken(String notificationToken) {
    this.notificationToken = notificationToken;
  }

  String? getDocumentId() {
    return documentId;
  }

  void setDocumentId(String documentId) {
    this.documentId = documentId;
  }

  DateTime? getCreatedOn() {
    return createdOn;
  }

  void setCreatedOn(DateTime createdOn) {
    this.createdOn = createdOn;
  }

  String? getCreatedBy() {
    return createdBy;
  }

  void setCreatedBy(String createdBy) {
    this.createdBy = createdBy;
  }

  bool isDelete() {
    return delete;
  }

  void setDelete(bool delete) {
    this.delete = delete;
  }


  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'name': name,
      'email': email,
      'mobileNo': mobileNo,
      'uid': uid,
      'notificationToken': notificationToken,
      'documentId': documentId,
      'delete': delete,
      'createdOn': createdOn,
      'createdBy': createdBy,
      'associations': associations,
      'nurturaAssociation': nurturaAssociation
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> doc) {
    return UserModel.withData(
        type: doc['type'],
        organizationId: doc['organizationId'],
        organizationName: doc['organizationName'],
        name: doc['name'],
        email: doc['email'],
        mobileNo: doc['mobileNo'],
        uid: doc['uid'],
        notificationToken: doc['notificationToken'],
        documentId: doc['documentId'],
        delete: doc['delete'],
        createdOn: doc['createdOn']?.toDate(),
        createdBy: doc['createdBy'],
        associations: doc['associations'],
        nurturaAssociation: doc['nurturaAssociation'] ?? null);

  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    return UserModel.fromJson(doc.data() as Map<String, dynamic>);
  }
}
