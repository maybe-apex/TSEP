import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../components/mentee-customNavigationBar.dart';
import '../logic/mentee-cached-data.dart';
import '../logic/mentee-data-processing.dart';
import '../logic/mentee-firestore.dart';

import '../local-data/constants.dart';
import 'mentee-post-session-survey.dart';
import 'mentee-schedule-complete.dart';

final firestore = FirebaseFirestore.instance;
bool loading = false;
Map<String, dynamic> oldData = {}, newData = {};

class MenteeSchedulePage extends StatefulWidget {
  static String route = 'MenteeSchedulePage';
  @override
  _MenteeSchedulePageState createState() => _MenteeSchedulePageState();
}

List<Schedule> scheduleList = [];

class _MenteeSchedulePageState extends State<MenteeSchedulePage> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    Widget getDayCards() {
      DateTime today = DateTime.now();
      DateTime _firstDayOfTheWeek =
          today.subtract(new Duration(days: today.weekday));
      List<Widget> dayList = [];
      dayList.add(SizedBox(width: size.width * 0.02));
      for (var index = 1; index <= 7; index++) {
        dayList.add(
          DayCard(
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
                    .collection('MenteeInfo/$menteeUID/Schedule')
                    .orderBy('LectureTime')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (menteeSchedule.length == 0) {
                    return Column(
                      children: [
                        getDayCards(),
                        BreakLine(),
                        WeeklyStatisticsWrapper(schedule: scheduleList),
                        BreakLine(),
                        Container(
                          margin: EdgeInsets.only(top: 30),
                          child: Text(
                            "No lectured scheduled this week",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.black.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        )
                      ],
                    );
                  }
                  if (snapshot.connectionState != ConnectionState.active) {
                    return Column(
                      children: [
                        getDayCards(),
                        BreakLine(),
                        WeeklyStatisticsWrapper(schedule: scheduleList),
                        BreakLine(),
                        Container(
                          margin: EdgeInsets.only(top: 30),
                          child: SpinKitSquareCircle(
                            color: kRed.withOpacity(0.7),
                            size: 50,
                          ),
                        ),
                      ],
                    );
                  }
                  DateTime today = DateTime.now();
                  DateTime _firstDayOfTheWeek =
                      today.subtract(new Duration(days: today.weekday));
                  DateTime startDate = _firstDayOfTheWeek
                      .add(Duration(days: 1))
                      .subtract(Duration(
                          hours: TimeOfDay.now().hour,
                          minutes: TimeOfDay.now().minute));
                  DateTime endDate = _firstDayOfTheWeek
                      .add(Duration(days: 7))
                      .add(Duration(hours: 24 - TimeOfDay.now().hour));
                  List<Widget> scheduleCardList = [];
                  if (snapshot.hasData) {
                    scheduleList.clear();
                    final schedules = snapshot.data!.docs;
                    for (var schedule in schedules) {
                      DateTime timing = schedule.get('LectureTime').toDate();
                      if (timing.isAfter(endDate)) break;
                      var lectureTime = schedule.get('LectureTime').toDate();
                      Schedule s = Schedule(
                          mentor: mentorProfileData.fullName,
                          lesson: schedule.get('LessonNumber'),
                          duration: schedule.get('Duration'),
                          timing: timing,
                          menteeScheduleID: schedule.id,
                          postSessionSurvey: schedule.get('PostSessionSurvey'),
                          footNotes: schedule.get('FootNotes'));

                      if (lectureTime.isAfter(startDate)) {
                        scheduleList.add(s);
                        scheduleCardList.add(
                          ScheduleCard(schedule: s),
                        );
                      }
                    }
                  }
                  return Column(
                    children: [
                      getDayCards(),
                      BreakLine(),
                      WeeklyStatisticsWrapper(schedule: scheduleList),
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
      bottomNavigationBar: MenteeCustomBottomNavBar(
        active: 1,
      ),
    );
  }
}

class WeeklyStatisticsWrapper extends StatelessWidget {
  final List<Schedule> schedule;

  WeeklyStatisticsWrapper({
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    var x = getWeeklyStatistics(schedule);
    Duration LessonDuration = x.first;
    String lessonDurationHours = LessonDuration.inHours.toString();
    String lessonDurationMinutes =
        LessonDuration.inMinutes.remainder(60).toString();
    return Container(
      margin: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          WeeklyStatisticsCards(
              heading: "Attended this week",
              value: "${lessonDurationHours}hr ${lessonDurationMinutes}min"),
          WeeklyStatisticsCards(heading: "Lessons", value: x.last.toString()),
        ],
      ),
    );
  }
}

class WeeklyStatisticsCards extends StatelessWidget {
  final String heading, value;

  WeeklyStatisticsCards({required this.heading, required this.value});

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
    var weekday = DateFormat('EEE, d MMMM').format(schedule.timing);
    var lesson = schedule.lesson;
    String startTime = DateFormat('hh:mm').format(schedule.timing);
    startTime = startTime.replaceAll("AM", "am").replaceAll("PM", "pm");
    String endTime = DateFormat('hh:mm a')
        .format(schedule.timing.add(Duration(minutes: schedule.duration)));
    endTime = endTime.replaceAll("AM", "am").replaceAll("PM", "pm");
    bool surveyAvailable = false;
    if (schedule.postSessionSurvey)
      surveyAvailable = false;
    else if (!schedule.postSessionSurvey &&
        schedule.timing
            .add(Duration(minutes: schedule.duration))
            .isBefore(DateTime.now())) {
      surveyAvailable = true;
    }
    Size size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
        // constraints: BoxConstraints(minHeight: size.height * 0.09),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return Dialog(
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15)),
                        height: size.height * 0.18,
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(top: 12),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 13, vertical: 7),
                                decoration: BoxDecoration(
                                  color: kRed.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Please fill the survey with utmost sincerity",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    color: kRed.withOpacity(0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: size.height * 0.02),
                              SurveyWrapper(
                                schedule: schedule,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    height: 35,
                    width: 40,
                    margin: EdgeInsets.only(right: 5, left: 15),
                    decoration: !surveyAvailable
                        ? BoxDecoration(
                            color: kGreen,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: kBlue.withOpacity(0.3),
                                blurRadius: 10,
                              ),
                            ],
                          )
                        : BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: kGreen, width: 2),
                          ),
                    child: Center(
                      child: Text(
                        DateFormat('d').format(schedule.timing),
                        style: TextStyle(
                          color: !surveyAvailable ? Colors.white : kGreen,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(
                          maxWidth: size.width * 0.34,
                          minWidth: size.width * 0.3),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lesson $lesson',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "$weekday",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            lessonData[schedule.lesson].title,
                            style: TextStyle(
                                fontSize: 11,
                                color: kRed.withOpacity(0.7),
                                fontWeight: FontWeight.bold),
                          ),
                          Visibility(
                            visible: surveyAvailable,
                            child: Column(
                              children: [
                                SizedBox(height: 6),
                                Text(
                                  "Survey Available !",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: kGreen.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(right: 15),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$startTime - $endTime",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                        SizedBox(
                          height: size.height * 0.01,
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
                  ),
                ],
              ),
            ),
            Visibility(
              visible: schedule.footNotes != '',
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: kBlue.withOpacity(0.15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FootNotes:',
                      style: TextStyle(
                          fontSize: 15,
                          color: kBlue.withOpacity(0.9),
                          fontWeight: FontWeight.bold),
                    ),
                    SelectableText(
                      schedule.footNotes,
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            Visibility(
              visible: getLessonByNumber(schedule.lesson).videoLinks != null,
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: kRed.withOpacity(0.15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Watch / Listen:',
                      style: TextStyle(
                          fontSize: 15,
                          color: kRed.withOpacity(0.9),
                          fontWeight: FontWeight.bold),
                    ),
                    getLinks(getLessonByNumber(schedule.lesson).videoLinks),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getLinks(List<String>? videoLinks) {
    if (videoLinks == null) return Text('');
    int x = 1;
    List<Widget> result = [];
    for (var link in videoLinks) {
      result.add(InkWell(
        onTap: () => launch(link),
        child: Container(
          margin: EdgeInsets.fromLTRB(3, 10, 3, 0),
          padding: EdgeInsets.all(3),
          decoration: BoxDecoration(
              color: kRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3)),
          child: Text(
            'LINK $x',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12, color: kRed),
          ),
        ),
      ));
      x++;
    }
    return Row(mainAxisAlignment: MainAxisAlignment.start, children: result);
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

  DayCard({required this.date});

  @override
  Widget build(BuildContext context) {
    bool active = isActive(date);
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
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: size.width * 0.1, vertical: size.height * 0.04),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return MenteeScheduleComplete();
              }));
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
      ),
    );
  }
}

class SurveyWrapper extends StatelessWidget {
  Schedule schedule;
  SurveyWrapper({required this.schedule});
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return MenteePostSessionSurvey(
                  menteeScheduleID: schedule.menteeScheduleID,
                );
              },
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.only(bottom: 15),
          child: Center(
            child: Text(
              "POST SESSION SURVEY",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          height: size.height * 0.042,
          width: double.infinity,
          decoration: BoxDecoration(
            color: kGreen.withOpacity(0.9),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: kGreen.withOpacity(0.9),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
