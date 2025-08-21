import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fetomaxtv_mre/core/services/authentication.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fetomaxtv_mre/ui/shared/constant.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
class LoginView extends StatefulWidget {
  LoginView({this.auth, this.loginCallback, this.phoneCallback}) {
  }


  final BaseAuth? auth;
  final VoidCallback? loginCallback;
  final VoidCallback? phoneCallback;

  @override
  State<StatefulWidget> createState() => new _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final FocusNode _emailFocus = new FocusNode();
  final FocusNode _passwordFocus = new FocusNode();
  final FocusNode _confirmFocus = new FocusNode();
  final _formKey = new GlobalKey<FormState>();
  static const MethodChannel platform = MethodChannel("com.doto.fetomax/print");
  final f = FocusNode();
  StreamSubscription<DocumentSnapshot>? _sessionSub;
  String? _customToken;
  bool _isBtnFocused = false;
  String? _email;
  String _password = "";
  String _confirm = "";
  String? _errorMessage;
  bool isFirstIn = true;
  bool? _isLoginForm;
  bool? _isLoading;
  String? _androidId = null;
  String? _anonmousUserID = null;

  // Check if form is valid before perform login or signup
  bool validateAndSave() {
    final form = _formKey.currentState;
    if (form!.validate()) {
      form!.save();
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _errorMessage = "";
    _isLoading = false;
    _isLoginForm = true;
    _fetchDeviceId();
    // f.addListener(() {
    //   setState(() {
    //     _isBtnFocused = f.hasFocus;
    //   });

    // });
  }

  Future<void> _fetchDeviceId() async {
    try {
      final String? androidID = await callAndroidIDMethodChannel();
      print('flutter: got androidID -> $androidID');

      if (androidID != null && androidID.isNotEmpty) {
        // if (!mounted) return;
        setState(()  {
          print("flutter: setStateCalled"+ androidID);
          _androidId = androidID;
        });
        signInAnonymously().then((_) {
          // success: if signInAnonymously updates state, it should check `mounted` itself
          print('signInAnonymously succeeded');
        }).catchError((error, st) {
          print('signInAnonymously failed: $error\n$st');
        });


      } else {
        print("getAndroidID is null or empty");
        signInAnonymously().then((_) {
          // success: if signInAnonymously updates state, it should check `mounted` itself
          print('signInAnonymously succeeded');
        }).catchError((error, st) {
          print('signInAnonymously failed: $error\n$st');
        });
      }
    } catch (e, st) {
      print('getAndroidID error: $e\n$st');
    }
  }

  // Perform login or signup
  void validateAndSubmit() async {
    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });
    if (validateAndSave()) {
      String userId = "";
      try {
        if (_isLoginForm!) {
          userId = await widget.auth!.signIn(_email!, _password);
          print('Signed in: $userId');
        } else {
          userId = await widget.auth!.signUp(_email!, _confirm);
          //widget.auth.sendEmailVerification();
          //_showVerifyEmailSentDialog();
          await createNewDoctor(userId);
          print('Signed up user: $userId');
        }
        setState(() {
          _isLoading = false;
        });

        if (userId.length > 0 && userId != null) {
          print('Signed in loginCallback:  $userId');
          widget.loginCallback!();
        }
      } catch (e) {
        print('Error: $e');
        setState(() {
          f.unfocus();
          _emailFocus.requestFocus();

          _isLoading = false;
          if (e.toString().contains("There is no user record"))
            _errorMessage = "Invalid email\/username";
          else
            _errorMessage = e.toString();
          _formKey.currentState!.reset();
        });
      }
    } else {
      f.unfocus();
      _emailFocus.requestFocus();
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> signInAnonymously() async {
    print('>>> signInAnonymously called');
    try {
      await widget.auth!.signInAnonymously();
      print("flutter: await SiginAnonymously"); // if this prints, call succeeded
    } catch (e, st) {
      print("flutter: Error"+e.runtimeType.toString() + ': ' + e.toString());
      print(st); // full stacktrace
      print('==== end ERROR ====');
      return;
    }
    print("flutter: await SiginAnonymously");
    final user = await widget.auth!.getCurrentUser();
    print("flutter: await SiginAnonymously2");
    if (user == null) {
      return;
    }

    String userId = user.uid;

    if (userId.isEmpty) {
      return;
    }
    print('Anonymous Signed in user id1 :  $userId');
    if (_androidId == null || _androidId!.isEmpty) {
      print('device id empty:  $_androidId');
      return;
    }
    setState(() {
      _anonmousUserID = userId;
    });

    print('Anonymous Signed in user id2 :  $userId');
    final tv_sessions =
        FirebaseFirestore.instance.collection('tv_sessions').doc(userId);

    await tv_sessions.set(
      {
        'uid': userId,
        'androidId': _androidId,
        'customToken': '',
        'createdOn': FieldValue.serverTimestamp(),
        'updatedOn': '',
      },
    );
    await _customTokenListener();
  }

  void resetForm() {
    _formKey.currentState!.reset();
    _errorMessage = "";
  }

  void _toggleFormMode() {
    resetForm();
    setState(() {
      _isLoginForm = !_isLoginForm!;
    });
  }

  Future<String?> callAndroidIDMethodChannel() async {
    try {
      // generic typed invokeMethod that returns Future<String?>
      final String? androidID = await platform.invokeMethod<String>('getAndroidID');
      return androidID;
    } catch (e) {
      print('callAndroidIDMethodChannel exception: $e');
      return null;
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    f.dispose();
    _sessionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFFFAF4FF), // light purple background
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _showTopBar(),
            Expanded(
              child: Center(
                child: Stack(
                  children: <Widget>[
                    _showForm(),
                    _showCircularProgress(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _showTopBar() {
    return Container(
      height: 64,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade900.withOpacity(0.25), // subtle blue shadow
            offset: Offset(0, 2), // shadow downwards
            blurRadius: 8, spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'images/doto_cm_blue.png',
              height: 40,
            ),
          ],
        ),
      ),
    );
  }

  Widget _showCircularProgress() {
    if (_isLoading!) {
      return Center(
          child: CircularProgressIndicator(
              valueColor: new AlwaysStoppedAnimation<Color>(Colors.black)));
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

//  void _showVerifyEmailSentDialog() {
//    showDialog(
//      context: context,
//      builder: (BuildContext context) {
//        // return object of type Dialog
//        return AlertDialog(
//          title: new Text("Verify your account"),
//          content:
//              new Text("Link to verify account has been sent to your email"),
//          actions: <Widget>[
//            new FlatButton(
//              child: new Text("Dismiss"),
//              onPressed: () {
//                toggleFormMode();
//                Navigator.of(context).pop();
//              },
//            ),
//          ],
//        );
//      },
//    );
//  }

  Widget _showForm() {
    String? qrData;
    final hasAndroid = (_androidId?.isNotEmpty ?? false);
    final hasAnon = (_anonmousUserID?.isNotEmpty ?? false);
    print("flutter: Android ID "+ (_androidId ?? "null"));
    print("flutter: Anon ID " + (_anonmousUserID ?? "null"));
    if (hasAndroid && hasAnon) {
      qrData = "https://cmconnect.caremother.in/"
          "?tvAndroidID=$_androidId"
          "&tvAnonUID=$_anonmousUserID";
    } else {
      print("flutter: QR Data Unavailable");
      qrData = null;
    }


    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ─────── Header ───────
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Color(0xFF0D2E6E),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Center(
                        child: Text(
                          'Caremother Central Monitoring',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // ─────── Body ───────
                    Expanded(
                      child: Row(
                        children: [
                          // ─── Left: QR only ───
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  // ✦ Panel Title
                                  Text(
                                    "Login with Mobile",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D2E6E),
                                    ),
                                  ),

                                  // ✦ Step 1 Card
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF0F4FF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Color(0xFF0D2E6E), width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        // Number bubble
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Color(0xFF0D2E6E),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              "1",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Scan the QR Code.",
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ✦ QR Code Centered
                                  qrData != null
                                      ? Center(
                                          child: QrImageView(
                                            data: qrData!,
                                            version: QrVersions.auto,
                                            size: 160,
                                            // smaller so it never overflows
                                            gapless: false,
                                          ),
                                        )
                                      : Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFFFF6F0),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Color(0xFFDD6B4A)),
                                          ),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.error,
                                                        size: 28,
                                                        color:
                                                            Color(0xFFDD6B4A)),
                                                    SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        "QR unavailable",
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Color(0xFFDD6B4A),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  "We couldn't generate or display the QR code. You can continue by signing in with your email and password.",
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.black87),
                                                ),
                                              ])),

                                  // ✦ Step 2 Card
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF0F4FF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Color(0xFF0D2E6E), width: 1),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Color(0xFF0D2E6E),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              "2",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Approve login on your phone to continue",
                                            style: TextStyle(
                                                fontSize: 15,
                                                color: Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ─── Divider ───
                          Container(
                            width: 1,
                            margin: EdgeInsets.symmetric(vertical: 24),
                            color: Colors.grey.shade300,
                          ),

                          // ─── Right: Email/Password ───
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Center(
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Login with Email",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0D2E6E),
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      showEmailInput(),
                                      SizedBox(height: 16),
                                      showPasswordInput(),
                                      SizedBox(height: 8),
                                      showErrorMessage(),
                                      SizedBox(height: 24),
                                      showPrimaryButton(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget showErrorMessage() {
    if (_errorMessage!.length > 0 && _errorMessage != null) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
          child: Center(
              child: Text(
            _errorMessage!,
            style: TextStyle(
                fontSize: 13.0,
                color: Colors.red,
                height: 1.0,
                fontWeight: FontWeight.w300),
          )));
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  Widget showLogo() {
    return new Hero(
      tag: 'hero',
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
        child: GestureDetector(
          onTap: () {
            // Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //         builder: (context) => MyHomePage(title: "asdasd",
            //
            //         )));
          },
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: 80.0,
            child: Image.asset('images/doto_cm_blue.png'),
          ),
        ),
      ),
    );
  }

  Widget showEmailInput() {
    return TextFormField(
      maxLines: 1,
      keyboardType: TextInputType.emailAddress,
      autofocus: false,
      focusNode: _emailFocus,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.email, color: Colors.black87),
        hintText: 'Email ID',
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      validator: (value) => value!.isEmpty ? 'Email can\'t be empty' : null,
      onSaved: (value) => _email = value!.trim(),
      onFieldSubmitted: (_) {
        _emailFocus.unfocus();
        FocusScope.of(context).requestFocus(_passwordFocus);
      },
    );
  }

  Widget showPasswordInput() {
    return TextFormField(
      obscureText: true,
      maxLines: 1,
      autofocus: false,
      focusNode: _passwordFocus,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.lock, color: Colors.black87),
        hintText: 'Password',
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        suffixIcon: Icon(Icons.visibility), // or use a toggle
      ),
      validator: (value) => value!.isEmpty ? 'Password can\'t be empty' : null,
      onChanged: (value) => _password = value.trim(),
      onSaved: (value) => _password = value!.trim(),
      onFieldSubmitted: (_) {
        _passwordFocus.unfocus();
        f.requestFocus();
      },
    );
  }

  Widget showConfirmPasswordInput() {
    return Visibility(
        visible: !_isLoginForm!,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0.0, 0, 0.0, 10),
          child: new TextFormField(
            maxLines: 1,
            obscureText: true,
            autofocus: false,
            focusNode: _confirmFocus,
            decoration: new InputDecoration(
                hintText: 'Confirm Password',
                icon: new Icon(
                  Icons.lock,
                  color: themeColor,
                )),
            validator: (value) => value!.isEmpty
                ? 'Password can\'t be empty'
                : (value!.compareTo(_password) != 0
                    ? 'Password should match'
                    : null),
            onSaved: (value) => _confirm = value!.trim(),
          ),
        ));
  }

  Widget showSecondaryButton() {
    return new TextButton(
        // onPressed: _toggleFormMode,
        onPressed: () {
          widget.phoneCallback!();
        },
        child: new RichText(
          text: new TextSpan(
            // Note: Styles for TextSpans must be explicitly defined.
            // Child text spans will inherit styles from parent
            style: new TextStyle(
              fontSize: 14.0,
              color: Colors.black,
            ),
            children: <TextSpan>[
              new TextSpan(
                text: _isLoginForm!
                    ? 'Don\'t have an account?'
                    : 'Have an account?',
              ),
              new TextSpan(
                  text: _isLoginForm! ? ' Sign up' : ' Sign in',
                  style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurpleAccent)),
            ],
          ),
        ));
    /*
        new Text(
            _isLoginForm
                ? 'Don\'t have an account? Sign up'
                : 'Have an account? Sign in',
            style: new TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300)),
        onPressed: toggleFormMode);*/
  }

  Widget showPrimaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        focusNode: f,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        onPressed: validateAndSubmit,
        child:
            Text("Login", style: TextStyle(color: Colors.white, fontSize: 18)),
      ),
    );
  }

  Future<void> _customTokenListener() async {
    final user = await widget.auth!.getCurrentUser();
    if (user == null) return;
    if (!user.isAnonymous) {
      return;
    }
    final userId = user.uid;
    _sessionSub?.cancel();
    _sessionSub = FirebaseFirestore.instance
        .collection('tv_sessions')
        .doc(userId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final data = snap.data()!;
      final token = data['customToken'] as String?;
      if (token != null && token.isNotEmpty) {
        setState(() {
          _customToken = token;
        });
        _sessionSub?.cancel();
        // → Do whatever you need with the new token
        print('Got new customToken: $_customToken');
        if (_customToken != null || _customToken!.isNotEmpty) {
          _siginInWithCustomToken();
        }
      }
    }, onError: (err) {
      print('Error listening to customToken: $err');
    });
  }

  Future<void> _siginInWithCustomToken() async {
    if (_customToken == null) return;
    final anonuser = await widget.auth!.getCurrentUser();
    if (anonuser == null) return;
    if (!anonuser.isAnonymous) {
      return;
    }
    await widget.auth!.signInWithCustomToken(_customToken!);
    final realuser = await widget.auth!.getCurrentUser();
    if (realuser == null) {
      return;
    }
    String userId = realuser.uid;
    print("Real User ID " + userId);
    if (userId.length > 0 && userId != null) {
      print('Signed in loginCallback:  $userId');
      widget.loginCallback!();
      await _removeDocument();
    }
  }

  Future<void> _removeDocument() async {
    if (_anonmousUserID == null || _anonmousUserID!.isEmpty) return;

    final docRef = FirebaseFirestore.instance
        .collection('tv_sessions')
        .doc(_anonmousUserID);

    await docRef.delete();

    print('Deleted doc ${docRef.id}');
  }

  Future<String> createNewDoctor(String userId) async {
    Map<String, dynamic> data = new Map<String, String>();
    data["name"] = "Doctor";
    data["mobileNo"] = "";
    data["email"] = _email;
    data["type"] = "doctor";
    data["uid"] = userId;

    DocumentReference ref =
        await FirebaseFirestore.instance.collection("users").add(data);

    data["documentId"] = ref.id;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(ref.id)
        .set(data, SetOptions(merge: true));

    return ref.id;
  }
}
