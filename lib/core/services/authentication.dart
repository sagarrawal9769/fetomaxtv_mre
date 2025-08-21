import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

abstract class BaseAuth {
  Future<String> signIn(String email, String password);
  Future<String> signInAnonymously();
  Future<String> signInWithCustomToken(String token);

  Future<String> signUp(String email, String password);

  Future<User?> getCurrentUser();

  Future<void> sendEmailVerification();

  Future<void> signOut();

  Future<bool> isEmailVerified();
}


final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

class Auth implements BaseAuth {

  Future<String> signIn(String email, String password) async {
    var result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    User? user = result.user;
    return user!.uid;
  }
  Future<String> signInAnonymously() async{
    print("flutter: Auth being called");
    var result = await _firebaseAuth.signInAnonymously();
    print("flutter: Auth called");
    User? user = result.user;
    print("flutter: uid"+user!.uid);
    return user!.uid;
  }
  @override
  Future<String> signInWithCustomToken(String token) async {
    // TODO: implement signInWithCustomToken
    var result = await _firebaseAuth.signInWithCustomToken(token);
    User? user = result.user;
    return user!.uid;
  }
  Future<String> signUp(String email, String password) async {
    var result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);
    User? user = result.user;
    return user!.uid;
  }

  Future<User?> getCurrentUser() async {
    // await Future.delayed(Duration(seconds: 1));
    User? user = _firebaseAuth.currentUser;
    return user;
  }

  Future<void> signOut() async {
    return _firebaseAuth.signOut();
  }

  Future<void> sendEmailVerification() async {
    User? user = _firebaseAuth.currentUser!;
    user!.sendEmailVerification();
  }

  Future<bool> isEmailVerified() async {
    User? user = _firebaseAuth.currentUser!;
    return user!.emailVerified;
  }


}
