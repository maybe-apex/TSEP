import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../logic/mentee-cached-data.dart';
import '../logic/mentee-data-processing.dart';
import '../local-data/constants.dart';

class MenteePostSessionSurvey extends StatefulWidget {
  String menteeScheduleID, mentorName;
  MenteePostSessionSurvey(
      {required this.menteeScheduleID, required this.mentorName});
  static String route = "PostSessionSurvey";

  @override
  _MenteePostSessionSurveyState createState() =>
      _MenteePostSessionSurveyState();
}

Map<String, dynamic> oldData = {}, newData = {};
TimeOfDay pickedTime = TimeOfDay.now();
DateTime pickedDate = DateTime.now();
var remarkController = TextEditingController();
int pickedDuration = 0, pickedLesson = -1;
String _menteeScheduleID = '';

class _MenteePostSessionSurveyState extends State<MenteePostSessionSurvey> {
  final firestore = FirebaseFirestore.instance;
  getData() async {
    await firestore
        .collection('MenteeInfo/$menteeUID/Schedule')
        .doc(widget.menteeScheduleID)
        .get()
        .then((var value) {
      DateTime time = DateTime.fromMicrosecondsSinceEpoch(
          value.get('LectureTime').microsecondsSinceEpoch);
      setState(() {
        pickedTime = TimeOfDay.fromDateTime(time);
        pickedDate = time;
        pickedDuration = value.get('Duration');
        pickedLesson = value.get('LessonNumber');
      });
      oldData = {'Duration': pickedDuration};
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    getData();
    _menteeScheduleID = widget.menteeScheduleID;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              TitleBar(),
              MenteeLessonWrapper(mentorName: widget.mentorName),
              SizedBox(height: 20),
              TimeDatePickerWrapper(),
              BreakLine(),
              FootNotesWrapper(),
              DurationWrapper(),
              BreakLine(),
              CancelConfirmWrapper(),
            ],
          ),
        ),
      ),
    );
  }
}

class CancelConfirmWrapper extends StatelessWidget {
  final firestore = FirebaseFirestore.instance;
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.only(bottom: size.height * 0.04),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InkWell(
            onTap: () {
              Navigator.pop(context);
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
              height: size.height * 0.07,
              width: size.width * 0.4,
              decoration: BoxDecoration(
                color: Color(0xffD92136).withOpacity(0.7),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xffD92136).withOpacity(0.7),
                    blurRadius: 10,
                  )
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              await firestore
                  .collection('/MenteeInfo/$menteeUID/Schedule')
                  .doc(_menteeScheduleID)
                  .update({
                "Duration": pickedDuration,
                "Remarks": remarkController.text,
                "PostSessionSurvey": true,
              });
              newData = {
                'Duration': pickedDuration,
                'Remark': remarkController.text
              };
              firestore.collection('Logs').add({
                'Event': 'Post Session Survey Filled by Mentee',
                'OldData': oldData,
                'NewData': newData,
                'UID': menteeUID,
                'MenteeName': menteeName,
                'DateModified': DateTime.now(),
              });
              Navigator.of(context).pop(context);
            },
            child: Container(
              child: Center(
                child: Text(
                  "CONFIRM",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              height: size.height * 0.07,
              width: size.width * 0.4,
              decoration: BoxDecoration(
                color: kLightBlue,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: kLightBlue,
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

class DurationWrapper extends StatefulWidget {
  @override
  _DurationWrapperState createState() => _DurationWrapperState();
}

class _DurationWrapperState extends State<DurationWrapper> {
  callback(Duration dur) {
    setState(() {
      pickedDuration = dur.inMinutes.toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              "Duration",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 16),
            ),
            Container(
              decoration: BoxDecoration(
                color: Color(0xff34A853).withOpacity(0.3),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DurationNum(
                      duration: Duration(minutes: 30), callback: callback),
                  DurationNum(
                      duration: Duration(minutes: 45), callback: callback),
                  DurationNum(duration: Duration(hours: 1), callback: callback),
                ],
              ),
            ),
          ],
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
          margin: EdgeInsets.only(top: size.height * 0.015),
          child: Text(
            "I confirm to the best of my knowledge the session lasted the duration mentioned above.",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: kGreen.withOpacity(0.9),
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }
}

class DurationNum extends StatelessWidget {
  final Duration duration;
  final Function callback;
  DurationNum({required this.callback, required this.duration});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => callback(duration),
      child: Container(
        margin: EdgeInsets.all(7),
        // padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        // height: MediaQuery.of(context).size.height * 0.03,
        // width: MediaQuery.of(context).size.width * 0.1,
        decoration: duration.inMinutes == pickedDuration
            ? BoxDecoration(
                color: Color(0xff34A853).withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: Container(
          padding: EdgeInsets.all(5),
          child: Text(
            "${duration.inMinutes} mins",
            // textAlign: TextAlign.center,
            style: TextStyle(
              color: duration.inMinutes == pickedDuration
                  ? Colors.white
                  : Colors.black.withOpacity(0.8),
              fontWeight: duration.inMinutes == pickedDuration
                  ? FontWeight.w700
                  : FontWeight.w600,
              fontSize: 14,
            ),
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
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 20),
          height: 1,
          width: size.width,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: Color(0xff003670).withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FootNotesWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Text(
            "Remarks",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 25,
              color: Colors.black.withOpacity(0.7),
            ),
          ),
          FootNotesData(),
        ],
      ),
    );
  }
}

class FootNotesData extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 13),
      height: size.height * 0.25,
      width: size.width * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kLightBlue.withOpacity(0.8), width: 3),
        boxShadow: [
          BoxShadow(
            color: kLightBlue.withOpacity(0.7),
            blurRadius: 6,
          ),
        ],
      ),
      child: TextField(
        controller: remarkController,
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        expands: true,
        maxLines: null,
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class TimeDatePickerWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Time",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 16),
            ),
            Container(
              width: size.width * 0.4,
              margin: EdgeInsets.symmetric(vertical: 10),
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                formatTimeOfDay(pickedTime),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withOpacity(0.65),
                    fontFamily: 'Montserrat'),
              ),
            )
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Date",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 16),
            ),
            Container(
              width: size.width * 0.4,
              margin: EdgeInsets.symmetric(vertical: 10),
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                DateFormat('EEE, d MMM').format(pickedDate),
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withOpacity(0.65),
                    fontFamily: 'Montserrat'),
              ),
            )
          ],
        ),
      ],
    );
  }
}

class MenteeLessonWrapper extends StatelessWidget {
  final String mentorName;
  MenteeLessonWrapper({required this.mentorName});
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Mentor",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 16),
            ),
            Container(
              width: size.width * 0.4,
              margin: EdgeInsets.symmetric(vertical: 10),
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                mentorName,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withOpacity(0.65),
                    fontFamily: 'Montserrat'),
              ),
            )
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Lessons",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 16),
            ),
            Container(
              width: size.width * 0.4,
              margin: EdgeInsets.symmetric(vertical: 10),
              padding: EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Lesson $pickedLesson',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withOpacity(0.65),
                    fontFamily: 'Montserrat'),
              ),
            )
          ],
        ),
      ],
    );
  }
}

class TitleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(left: 20),
            child: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: SvgPicture.asset(
                "assets/icons/back-tb.svg",
                height: size.height * 0.07,
              ),
            ),
          ),
          SizedBox(
            width: size.width * 0.05,
            height: size.height * 0.12,
          ),
          Container(
            child: Text(
              "Post Session Survey",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black.withOpacity(0.5),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
