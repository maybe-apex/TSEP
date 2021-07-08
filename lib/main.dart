import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import '../screens/mentee-schedule-page.dart';
import '../screens/mentee-profile.dart';
import '../screens/FAQ-page.dart';
import '../screens/guidelines-page.dart';
import '../screens/login-page.dart';
import '../screens/mentee-signup-page.dart';
import '../screens/mentor-profile.dart';
import '../screens/mentor-signup-page.dart';
import '../screens/mentor-schedule-complete.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp();
  final auth = FirebaseAuth.instance;
  User? user = auth.currentUser;
  bool isMentor = false;
  if (user != null) {
    await FirebaseFirestore.instance
        .collection('MentorData')
        .doc(user.uid)
        .get()
        .then((value) => isMentor = value.exists);
  }
  AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelKey: 'key1',
      channelName: 'Session Reminders',
      channelDescription: 'Reminders for Sessions',
      playSound: true,
      enableVibration: true,
      importance: NotificationImportance.High,
    )
  ]);
  runApp(TSEP(user: user, isMentor: isMentor));
}

class TSEP extends StatelessWidget {
  final User? user;
  final bool isMentor;
  TSEP({required this.user, required this.isMentor});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => LoginPage(),
        MentorProfile.route: (context) => MentorProfile(),
        MentorSignUp.route: (context) => MentorSignUp(),
        MenteeSignUp.route: (context) => MenteeSignUp(),
        MentorScheduleComplete.route: (context) => MentorScheduleComplete(),
        FAQPage.route: (context) => FAQPage(),
        GuidelinesPage.route: (context) => GuidelinesPage(),
        MenteeProfile.route: (context) => MenteeProfile(),
        MenteeSchedulePage.route: (context) => MenteeSchedulePage(),
      },
      theme: ThemeData(fontFamily: 'Montserrat'),
      initialRoute: user != null
          ? isMentor
              ? MentorProfile.route
              : MenteeProfile.route
          : LoginPage.route,
    );
  }
}
