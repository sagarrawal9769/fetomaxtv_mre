import 'dart:async';
import 'package:fetomaxtv_mre/core/model/userModel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

enum authProblems { UserNotFound, PasswordNotValid, NetworkError, UnknownError }

class Auth {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<String> signIn(String email, String password) async {
    User? user = (await _auth.signInWithEmailAndPassword(
        email: email, password: password))
        .user;
    return user!.uid;
  }

  static Future<String> signUp(String email, String password) async {
    User? user = (await _auth.createUserWithEmailAndPassword(
        email: email, password: password))
        .user;
    return user!.uid;
  }

  static Future<void> signOut() async {
    return FirebaseAuth.instance.signOut();
  }

  static Future<User> getCurrentFirebaseUser() async {
    User? user = await FirebaseAuth.instance.currentUser;
    return user!;
  }

  static void addUser(UserModel user) async {
    checkUserExist(user.documentId!).then((value) {
      if (!value) {
        print("user ${user.name} ${user.email} added");
        FirebaseFirestore.instance
            .doc("users/${user.documentId}")
            .set(user.toJson());
      } else {
        print("user ${user.name} ${user.email} exists");
      }
    });
  }

  static Future<bool> checkUserExist(String userID) async {
    bool exists = false;
    try {
      await FirebaseFirestore.instance.doc("users/$userID").get().then((doc) {
        if (doc.exists)
          exists = true;
        else
          exists = false;
      });
      return exists;
    } catch (e) {
      return false;
    }
  }

  static Stream<UserModel> getUser(String userID) {
    return FirebaseFirestore.instance
        .collection("users")
        .where("userID", isEqualTo: userID)
        .snapshots()
        .map((QuerySnapshot snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromDocument(doc);
      }).first;
    });
  }

  static String getExceptionText(Exception e) {
    if (e is PlatformException) {
      switch (e.message) {
        case 'There is no user record corresponding to this identifier. The user may have been deleted.':
          return 'User with this e-mail not found.';
          break;
        case 'The password is invalid or the user does not have a password.':
          return 'Invalid password.';
          break;
        case 'A network error (such as timeout, interrupted connection or unreachable host) has occurred.':
          return 'No internet connection.';
          break;
        case 'The email address is already in use by another account.':
          return 'Email address is already taken.';
          break;
        default:
          return 'Unknown error occured.';
      }
    } else {
      return 'Unknown error occured.';
    }
  }
}
