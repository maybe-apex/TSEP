import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'authentication.dart';
import 'mentee-cached-data.dart';
import 'mentee-data-processing.dart';

class MenteeProfileHandler {
  final firestore = FirebaseFirestore.instance;
  final auth = Authentication();
  DateTime joiningDate = DateTime.now();

  getData(VoidCallback callback) async {
    await getCurrentUser();
    getMenteeScheduleData(callback);
    getMenteeProfileData(callback);
    // getMentorProfileData(callback); now this is called inside getMenteeProfileData, calling it here didn't work for some reason :(
  }

  getCurrentUser() async {
    try {
      final User user = await auth.getCurrentUser();
      menteeUID = user.uid;
      menteeEmail = user.email ?? 'email';
    } catch (error) {
      print('MentorProfile error -> $error');
    }
  }

  getMenteeProfileData(VoidCallback callback) async {
    await for (var snapshot
        in firestore.collection('MenteeInfo').doc(menteeUID).snapshots()) {
      var firstName = snapshot.get('FirstName').toString();
      var lastName = snapshot.get('LastName').toString();
      menteeProfileData = MenteeProfileData(
        batchName: snapshot.get('BatchName').toString(),
        firstName: firstName,
        idNumber: snapshot.get('IDNumber'),
        lastName: lastName,
        organization: snapshot.get('Organization').toString(),
        email: snapshot.get('email'),
        joiningDate: snapshot.get('JoiningDate').toDate(),
        gender: snapshot.get('Gender'),
        age: snapshot.get('Age'),
        phoneNumber: snapshot.get('PhoneNumber'),
        initialLevel: snapshot.get('InitialLevel'),
      );
      joiningDate = snapshot.get('JoiningDate').toDate();
      mentorUID = snapshot.get('MentorUID');
      if (mentorUID != '')
        getMentorProfileData(callback);
      else
        callback();
    }
  }

  getMentorProfileData(VoidCallback callback) async {
    await for (var snapshot
        in firestore.collection('MentorData').doc(mentorUID).snapshots()) {
      var firstName = snapshot.get('FirstName').toString();
      var lastName = snapshot.get('LastName').toString();
      mentorProfileData = MentorProfileData(
        firstName: firstName,
        idNumber: snapshot.get('IDNumber'),
        lastName: lastName,
        email: snapshot.get('email'),
        gender: snapshot.get('Gender'),
        phoneNumber: snapshot.get('PhoneNumber'),
        fullName: "$firstName $lastName",
      );
      callback();
    }
  }

  getMenteeScheduleData(VoidCallback callback) async {
    await for (var snapshot in firestore
        .collection('MenteeInfo/$menteeUID/Schedule')
        .orderBy('LectureTime')
        .snapshots()) {
      menteeSchedule.clear();
      final schedules = snapshot.docs;
      for (var schedule in schedules) {
        Schedule sch = Schedule(
          mentor: schedule.get('MentorName'),
          lesson: schedule.get('LessonNumber'),
          duration: schedule.get('Duration'),
          timing: schedule.get('LectureTime').toDate(),
          menteeScheduleID: schedule.id,
          postSessionSurvey: schedule.get('PostSessionSurvey'),
          footNotes: schedule.get('FootNotes'),
        );
        menteeSchedule.add(sch);
      }
      menteeScheduleData = MenteeScheduleData(
        nextInteraction: getNextInteraction(menteeSchedule),
        lastInteraction: getLastInteraction(menteeSchedule),
        hoursPerWeek: getLectureHourRate(joiningDate, menteeSchedule).last,
        lecturesPerWeek: getLectureHourRate(joiningDate, menteeSchedule).first,
      );
      callback();
    }
  }
}

class MenteeProfileData {
  final String batchName,
      firstName,
      lastName,
      organization,
      email,
      gender,
      initialLevel;
  final int idNumber, phoneNumber, age;
  final DateTime joiningDate;

  MenteeProfileData(
      {required this.batchName,
      required this.firstName,
      required this.email,
      required this.gender,
      required this.joiningDate,
      required this.idNumber,
      required this.lastName,
      required this.organization,
      required this.phoneNumber,
      required this.age,
      required this.initialLevel});
}

class MentorProfileData {
  final String firstName, lastName, email, gender, fullName;
  final int phoneNumber, idNumber;
  MentorProfileData(
      {required this.firstName,
      required this.email,
      required this.gender,
      required this.lastName,
      required this.phoneNumber,
      required this.idNumber,
      required this.fullName});
}

class MenteeScheduleData {
  final Duration lastInteraction, nextInteraction;
  final double lecturesPerWeek, hoursPerWeek;

  MenteeScheduleData(
      {required this.nextInteraction,
      required this.lastInteraction,
      required this.hoursPerWeek,
      required this.lecturesPerWeek});
}

class Schedule {
  String mentor, menteeScheduleID, footNotes;
  DateTime timing;
  int duration, lesson;
  bool postSessionSurvey;
  Schedule({
    required this.menteeScheduleID,
    required this.mentor,
    required this.lesson,
    required this.duration,
    required this.timing,
    required this.postSessionSurvey,
    required this.footNotes,
  });
}

class Lesson {
  String title, duration, url;
  Lesson({required this.title, required this.duration, required this.url});
}