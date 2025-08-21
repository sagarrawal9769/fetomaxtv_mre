import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  // Singleton instance
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late FirebaseApp nurtura_copilot;
  late FirebaseFirestore nurtura_firestore;

  Future<void> initialize() async {
    // Initialize the secondary Firebase app
    nurtura_copilot = (defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb)
        ? await Firebase.initializeApp(
            name: 'nurtura_copilot',
            options: FirebaseOptions(
              apiKey: 'AIzaSyBHnI3YthO_RdigIMcBFWHw5WN3c-5p6ac',
              appId: '1:958302089299:ios:9272eeba627291dba456a6',
              messagingSenderId: '958302089299',
              projectId: 'caremother-partopro',
            ),
          )
        : (defaultTargetPlatform == TargetPlatform.android && !kIsWeb)
            ? await Firebase.initializeApp(
                name: 'nurtura_copilot',
                options: FirebaseOptions(
                  apiKey: 'AIzaSyDoxgp3KBIKKQ5q1NwkPNUdX0Ofm7X0cIQ',
                  appId: '1:958302089299:android:d3683ef509e1b1a9a456a6',
                  messagingSenderId: '958302089299',
                  projectId: 'caremother-partopro',
                ),
              )
            : await Firebase.initializeApp(
      name: 'nurtura_copilot',
                options: FirebaseOptions(
                    apiKey: "AIzaSyDNUOR0EO2gvV3FhAYXJ3AohxKbJ451gkM",
                    authDomain: "caremother-partopro.firebaseapp.com",
                    projectId: "caremother-partopro",
                    storageBucket: "caremother-partopro.firebasestorage.app",
                    messagingSenderId: "958302089299",
                    appId: "1:958302089299:web:405c491f966cefffa456a6",
                    measurementId: "G-VMV5KF4D36"),
              );

    // Initialize the secondary Firestore instance
    nurtura_firestore = FirebaseFirestore.instanceFor(app: nurtura_copilot);
  }
}
