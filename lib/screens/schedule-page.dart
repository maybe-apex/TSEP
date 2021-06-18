import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../local-data/constants.dart';
import '../logic/cached-data.dart';
import '../logic/data-processing.dart';
import '../logic/firestore.dart';
import '../components/CustomNavigationBar.dart';

final firestore = FirebaseFirestore.instance;
bool loading = false;

class SchedulePage extends StatefulWidget {
  @override
  _SchedulePageState createState() => _SchedulePageState();
}

List<Schedule> scheduleList = [];

class _SchedulePageState extends State<SchedulePage> {
  // Just Kept here for reference, using StreamBuilder instead not
  // Future<Widget> sync {
  //   DateTime today = DateTime.now();
  //   DateTime _firstDayOfTheweek =
  //       today.subtract(new Duration(days: today.weekday));
  //   DateTime startDate = _firstDayOfTheweek.add(Duration(days: 1));
  //   DateTime endDate = _firstDayOfTheweek.add(Duration(days: 7));
  //   List<Widget> ScheduleList = [];
  //   await for (var snapshot
  //       in firestore.collection('MentorData/${uid}/Schedule').snapshots()) {
  //     for (var schedule in snapshot.docs) {
  //       var lectureTime = schedule.get('LectureTime').toDate();
  //       if (lectureTime.isAfter(startDate) && lectureTime.isBefore(endDate)) {
  //         Schedule s = Schedule(
  //           mentee: schedule.get('MenteeName'),
  //           lesson: schedule.get('LessonNumber'),
  //           duration: schedule.get('Duration'),
  //           timing: schedule.get('LectureTime'),
  //         );
  //         ScheduleList.add(new ScheduleCard(
  //           s: s,
  //         ));
  //       }
  //     }
  //   }
  //   return new ListView(children: ScheduleList);
  // }

  @override
  Widget build(BuildContext context) {
    @override
    Size size = MediaQuery.of(context).size;
    // Deprecitated, using streamBuilder now !
    // Widget getSchedule() {
    //   DateTime today = DateTime.now();
    //   DateTime _firstDayOfTheweek =
    //       today.subtract(new Duration(days: today.weekday));
    //   DateTime startDate = _firstDayOfTheweek.add(Duration(days: 1));
    //   DateTime endDate = _firstDayOfTheweek.add(Duration(days: 7));
    //
    //   List<Widget> ScheduleList = [];
    //   for (var sche in schedule) {
    //     if (sche.timing.isAfter(startDate) && sche.timing.isBefore(endDate))
    //       ScheduleList.add(new ScheduleCard(s: sche));
    //   }
    //   return new ListView(children: ScheduleList);
    // }

    Widget getDayCards() {
      DateTime today = DateTime.now();
      DateTime _firstDayOfTheWeek =
          today.subtract(new Duration(days: today.weekday));
      List<Widget> dayList = [];
      dayList.add(SizedBox(width: size.width * 0.02));
      for (var index = 1; index <= 7; index++) {
        dayList.add(
          new DayCard(
            date: _firstDayOfTheWeek.add(
              Duration(days: index),
            ),
          ),
        );
      }
      dayList.add(SizedBox(width: size.width * 0.02));
      return new Row(
        children: dayList,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              TitleBar(),
              StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('MentorData/$mentorUID/Schedule')
                    .orderBy('LectureTime')
                    .snapshots(),
                builder: (context, snapshot) {
                  DateTime today = DateTime.now();
                  DateTime _firstDayOfTheweek =
                      today.subtract(new Duration(days: today.weekday));
                  DateTime startDate = _firstDayOfTheweek
                      .add(Duration(days: 1))
                      .subtract(Duration(
                          hours: TimeOfDay.now().hour,
                          minutes: TimeOfDay.now().minute));
                  DateTime endDate = _firstDayOfTheweek.add(Duration(days: 7));
                  List<Widget> scheduleCardList = [];
                  if (snapshot.hasData) {
                    scheduleList.clear();
                    final schedules = snapshot.data!.docs;
                    for (var schedule in schedules) {
                      var lectureTime = schedule.get('LectureTime').toDate();
                      Schedule s = Schedule(
                        mentee: schedule.get('MenteeName'),
                        lesson: schedule.get('LectureNumber'),
                        duration: schedule.get('Duration'),
                        timing: schedule.get('LectureTime').toDate(),
                        mentorScheduleID: schedule.id,
                        menteeScheduleID: schedule.get('MenteeScheduleID'),
                        menteeUID: schedule.get('MenteeUID'),
                      );
                      scheduleList.add(s);
                      if (lectureTime.isAfter(startDate) &&
                          lectureTime.isBefore(endDate)) {
                        scheduleCardList.add(
                          new ScheduleCard(schedule: s),
                        );
                      }
                    }
                  }
                  return Column(
                    children: [
                      getDayCards(),
                      BreakLine(),
                      TotalContributionLessonsTaughtWrapper(
                          schedule: scheduleList),
                      BreakLine(),
                      ...scheduleCardList
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        active: 1,
      ),
    );
  }
}

class TotalContributionLessonsTaughtWrapper extends StatelessWidget {
  final List<Schedule> schedule;
  TotalContributionLessonsTaughtWrapper({
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    var x = getTotalContribution(schedule);
    Duration totalContribution = x.first;
    String totalContributionHours = totalContribution.inHours.toString();
    String totalContributionMinutes =
        totalContribution.inMinutes.remainder(60).toString();
    return Container(
      margin: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TotalContributionLessonTaughtCard(
              heading: "Total Contribution",
              value:
                  "${totalContributionHours}hr ${totalContributionMinutes}min"),
          TotalContributionLessonTaughtCard(
              heading: "Lessons Taught", value: x.last.toString()),
        ],
      ),
    );
  }
}

class TotalContributionLessonTaughtCard extends StatelessWidget {
  final String heading, value;
  TotalContributionLessonTaughtCard(
      {required this.heading, required this.value});
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Container(
      child: Column(
        children: [
          Text(
            heading,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: size.height * 0.005),
          Text(
            value,
            style: TextStyle(
              color: Color(0xffD92136).withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  ScheduleCard({required this.schedule});
  @override
  Widget build(BuildContext context) {
    var weekday = DateFormat('EEE').format(schedule.timing);
    var lesson = schedule.lesson;
    String starttime = DateFormat('hh:mm').format(schedule.timing);
    starttime = starttime.replaceAll("AM", "am").replaceAll("PM", "pm");
    String endtime = DateFormat('hh:mm a')
        .format(schedule.timing.add(Duration(minutes: schedule.duration)));
    endtime = endtime.replaceAll("AM", "am").replaceAll("PM", "pm");
    Size size = MediaQuery.of(context).size;
    return InkWell(
      onTap: () {
        showDialog(
            context: context,
            builder: (context) {
              return Dialog(
                child: Container(
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(15)),
                  height: size.height * 0.2,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Delete Lecture",
                          style: TextStyle(
                              color: Color(0xffD92136).withOpacity(0.6),
                              fontWeight: FontWeight.bold,
                              fontSize: 20),
                        ),
                        Container(
                          margin: EdgeInsets.only(bottom: 10),
                          padding:
                              EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                          decoration: BoxDecoration(
                            color: Color(0xff1F78B4).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Are you sure? this action cannot be undone.",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: Color(0xff1F78B4).withOpacity(0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        CancelDeleteWrapper(
                          schedule: schedule,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            });
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
              ),
            ],
          ),
          width: size.width * 0.9,
          height: size.height * 0.1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: 35,
                width: 40,
                margin: EdgeInsets.only(right: 5, left: 15),
                decoration: BoxDecoration(
                  color: kBlue.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: kBlue.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    DateFormat('d').format(schedule.timing),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(minWidth: size.width * 0.32),
                margin:
                    const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.mentee,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(
                      height: 3,
                    ),
                    Text(
                      "$weekday, $lesson",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 5),
                    child: Text(
                      "$starttime - $endtime",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black.withOpacity(0.8),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_filled,
                        color: kGreen.withOpacity(0.8),
                        size: 12,
                      ),
                      Text(
                        "  ${schedule.duration} mins",
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: kGreen.withOpacity(0.8),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BreakLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 18),
      height: 1,
      width: size.width,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Color(0xff003670).withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}

class DayCard extends StatelessWidget {
  final DateTime date;
  DayCard({
    required this.date,
  });
  @override
  Widget build(BuildContext context) {
    bool active = isactive(date);
    bool event = iseventful(scheduleList, date);
    Color fontColor = active ? Colors.white : Colors.black.withOpacity(0.7);
    Color eventColor =
        active ? Colors.white.withOpacity(0.7) : kBlue.withOpacity(0.8);
    Size size = MediaQuery.of(context).size;
    return Container(
      width: 40,
      decoration: active
          ? BoxDecoration(
              color: kBlue.withOpacity(0.8),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: kBlue.withOpacity(0.3),
                  blurRadius: 10,
                ),
              ],
            )
          : null,
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 10, left: 4, right: 4),
            child: Text(
              DateFormat('EEE').format(date).toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: fontColor,
                fontSize: 12,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 2),
            child: Text(
              date.day.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: fontColor,
              ),
            ),
          ),
          Visibility(
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            visible: event,
            child: Container(
              margin: EdgeInsets.only(top: 3, bottom: 10),
              height: size.height * 0.005,
              width: size.width * 0.03,
              color: eventColor,
            ),
          )
        ],
      ),
    );
  }
}

class TitleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          child: Text(
            "Schedule",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
        ),
        SizedBox(
          width: screenWidth * 0.3,
          height: screenHeight * 0.12,
        ),
        InkWell(
          onTap: () {
            Navigator.pushNamed(context, "ScheduleComplete");
          },
          child: Container(
            decoration: BoxDecoration(
              color: kRed.withOpacity(0.7),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: kRed.withOpacity(0.7),
                  blurRadius: 10,
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            child: Text(
              "Show All",
              style:
                  TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        )
      ],
    );
  }
}

class CancelDeleteWrapper extends StatelessWidget {
  deleteSchedule(String mentorSchID, String menteeUID, String menteeSchID) {
    firestore
        .collection('MenteeInfo/$menteeUID/Schedule')
        .doc(menteeSchID)
        .delete();
    firestore
        .collection('MentorData/$mentorUID/Schedule')
        .doc(mentorSchID)
        .delete();
  }

  Schedule schedule;
  CancelDeleteWrapper({required this.schedule});
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              child: Center(
                child: Text(
                  "CANCEL",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              height: size.height * 0.042,
              width: size.width * 0.3,
              decoration: BoxDecoration(
                color: Color(0xff1F78B4),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xff1F78B4),
                    blurRadius: 10,
                  )
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              deleteSchedule(schedule.mentorScheduleID, schedule.menteeUID,
                  schedule.menteeScheduleID);
              Navigator.pop(context);
            },
            child: Container(
              child: Center(
                child: Text(
                  "DELETE",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              height: size.height * 0.042,
              width: size.width * 0.3,
              decoration: BoxDecoration(
                color: kRed.withOpacity(0.7),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: kRed.withOpacity(0.7),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
