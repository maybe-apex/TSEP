import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tsep/screens/edit_lecture.dart';
import '../logic/cached-data.dart';
import '../logic/firestore.dart';
import '../local-data/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestScreen extends StatefulWidget {
  final String menteeUID;
  TestScreen({required this.menteeUID});
  @override
  _TestScreenState createState() => _TestScreenState();
}

Mentee menteeData = Mentee(
    uid: '',
    firstName: '',
    latestLecture: -1,
    batchName: '',
    joiningDate: DateTime.now(),
    lastName: '',
    fullName: '',
    initialLevel: '',
    gender: '',
    organization: '',
    idNumber: -1,
    phoneNumber: -1);

List<Response> responses = List<Response>.generate(
    10, (index) => Response(score: 0, answer: '', question: questions[index]));
int questionIndex = 0, activeScore = 0, currentScored = 0, currentMax = 0;
TextEditingController responseFieldController = TextEditingController();
List<int> scores = List<int>.generate(10, (index) => 0);
List<bool> checked = List<bool>.generate(10, (index) => false);
String currentLevel = '-', menteeUID = '';

clearForm() {
  questionIndex = 0;
  activeScore = 0;
  currentScored = 0;
  currentMax = 0;
  responseFieldController.clear();
  scores = List<int>.generate(10, (index) => 0);
  checked = List<bool>.generate(10, (index) => false);
  currentLevel = '-';
}

class _TestScreenState extends State<TestScreen> {
  submitForm() {
    responses[questionIndex] = Response(
        score: scores[questionIndex],
        answer: responseFieldController.text,
        question: questions[questionIndex]);
    final firestore = FirebaseFirestore.instance;
    firestore
        .collection('MenteeInfo/$menteeUID/PreTestData')
        .doc('responses')
        .set({
      'Responses': responses
          .map((e) =>
              {'Question': e.question, 'Answer': e.answer, 'Score': e.score})
          .toList(),
    });
    firestore
        .collection('MenteeInfo')
        .doc(menteeUID)
        .update({'InitialLevel': currentLevel});
  }

  @override
  void initState() {
    super.initState();
    getMentee();
  }

  getMentee() {
    for (Mentee mentee in menteesList) {
      if (mentee.uid == widget.menteeUID) {
        menteeData = mentee;
        menteeUID = widget.menteeUID;
      }
    }
  }

  getLevel() {
    var fraction = currentScored / currentMax;
    currentLevel = fraction <= 1 / 3
        ? "NOVICE"
        : fraction <= 2 / 3
            ? "PRE-INTERMEDIATE"
            : "INTERMEDIATE";
  }

  void nextButtonCallback() {
    responses[questionIndex] = Response(
        score: scores[questionIndex],
        answer: responseFieldController.text,
        question: questions[questionIndex]);
    setState(() {
      updateTotalScores();
      questionIndex += questionIndex + 1 > 9 ? 0 : 1;
      if (checked[questionIndex]) {
        responseFieldController.text = responses[questionIndex].answer;
        activeScore = scores[questionIndex];
      } else {
        activeScore = 0;
        checked[questionIndex] = true;
        responseFieldController.clear();
      }
    });
  }

  void previousButtonCallback() {
    responses[questionIndex].answer = responseFieldController.text;
    setState(() {
      questionIndex--;
      if (questionIndex < 0) questionIndex = 0;
      activeScore = scores[questionIndex];
      responseFieldController.text = responses[questionIndex].answer;
    });
  }

  void updateScore(int score) {
    setState(() {
      scores[questionIndex] = score;
      checked[questionIndex] = true;
      activeScore = score;
      updateTotalScores();
    });
  }

  void updateTotalScores() {
    setState(() {
      currentScored = scores.reduce((a, b) => a + b);
      currentMax = checked.where((item) => item == true).length * 3;
      getLevel();
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              TitleBar(),
              MenteeProfileBanner(),
              BreakLine(),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    LevelCard(
                      currentMax: currentMax,
                      currentScored: currentScored,
                    ),
                    CurrentScoreCard(
                      totalScored: currentScored,
                      totalmax: currentMax,
                    )
                  ],
                ),
              ),
              BreakLine(),
              Container(
                child: Column(
                  children: [
                    QuestionCard(
                      index: questionIndex,
                    ),
                    SizedBox(
                      height: 25,
                    ),
                    ScoreCard(
                      active: activeScore,
                      updateScore: updateScore,
                    ),
                    SizedBox(
                      height: 25,
                    ),
                    AnsCard()
                  ],
                ),
              ),
              BreakLine(),
              PrevNxtBtn(
                previousCallback: previousButtonCallback,
                nextCallback: nextButtonCallback,
                questionIndex: questionIndex,
                submitCallback: submitForm,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AnsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.25,
      width: size.width * 0.85,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Color(0xff1F78B4).withOpacity(0.8), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: TextField(
          controller: responseFieldController,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          expands: true,
          maxLines: null,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintMaxLines: 5,
            hintText: "Mentee's Response",
            hintStyle: TextStyle(fontSize: 15),
          ),
        ),
      ),
    );
  }
}

class ScoreCard extends StatefulWidget {
  int active;
  final Function updateScore;
  ScoreCard({required this.active, required this.updateScore});

  @override
  _ScoreCardState createState() => _ScoreCardState();
}

class _ScoreCardState extends State<ScoreCard> {
  int active = 0;

  void callback(int index) {
    setState(() {
      widget.active = index;
      widget.updateScore(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Color(0xff1F78B4).withOpacity(0.3),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(6),
          ),
          height: size.height * 0.045,
          width: size.width * 0.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ScoreNum(num: 0, active: widget.active, callback: callback),
              ScoreNum(num: 1, active: widget.active, callback: callback),
              ScoreNum(num: 2, active: widget.active, callback: callback),
              ScoreNum(num: 3, active: widget.active, callback: callback),
            ],
          ),
        ),
        InkWell(
          onTap: () {},
          child: IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    child: SingleChildScrollView(
                      child: Container(
                        // margin: EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 25),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    "Marking Scheme",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.black.withOpacity(0.7),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 20),
                                      decoration: BoxDecoration(
                                        color: kRed.withOpacity(0.7),
                                        boxShadow: [
                                          BoxShadow(
                                            color: kRed.withOpacity(1),
                                            blurRadius: 10,
                                          ),
                                        ],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "GOT IT",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            InfoWrapper(0),
                            InfoWrapper(1),
                            InfoWrapper(2),
                            InfoWrapper(3),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            icon: SvgPicture.asset(
              "assets/icons/info-btn.svg",
              height: 30,
            ),
          ),
        ),
      ],
    );
  }
}

class InfoWrapper extends StatelessWidget {
  int index;
  InfoWrapper(this.index);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      padding: EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Color(0xff1F78B4),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Color(0xff1F78B4).withOpacity(0.8).withOpacity(1),
            blurRadius: 10,
          ),
        ],
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
                text: 'Award $index marks if:\n',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 17)),
            TextSpan(
                text: '${markingScheme[index]}',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class ScoreNum extends StatelessWidget {
  final int num, active;
  final Function callback;
  ScoreNum({required this.num, required this.active, required this.callback});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => callback(num),
      child: Container(
        // padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        height: MediaQuery.of(context).size.height * 0.03,
        width: MediaQuery.of(context).size.height * 0.03,
        decoration: active == num
            ? BoxDecoration(
                color: Color(0xff1F78B4).withOpacity(1),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        child: Center(
          child: Text(
            num.toString(),
            // textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  active == num ? Colors.white : Colors.black.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
        ),
      ),
    );
  }
}

class QuestionCard extends StatelessWidget {
  final int index;
  QuestionCard({required this.index});
  @override
  Widget build(BuildContext context) {
    // Question _question = Question();
    Size size = MediaQuery.of(context).size;
    return Row(
      children: [
        Container(
          height: 35,
          width: 40,
          margin: EdgeInsets.symmetric(horizontal: 17),
          decoration: BoxDecoration(
            color: Color(0xffD92136).withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Color(0xffD92136).withOpacity(0.7),
                blurRadius: 7,
              ),
            ],
          ),
          child: Center(
            child: Text(
              (index + 1).toString(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Container(
          constraints: BoxConstraints(maxWidth: size.width * 0.75),
          child: Text(
            questions[index],
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        )
      ],
    );
  }
}

class CurrentScoreCard extends StatelessWidget {
  final int totalScored, totalmax;
  CurrentScoreCard({required this.totalScored, required this.totalmax});
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      child: Column(
        children: [
          Text(
            "Current Score",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 6,
          ),
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Color(0xffD92136), width: 2),
                ),
                height: size.height * 0.05,
                width: size.width * 0.4,
              ),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xffD92136).withOpacity(1),
                          blurRadius: 10,
                        )
                      ],
                      color: Color(0xffD92136),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    height: size.height * 0.05,
                    width: totalmax == 0
                        ? 0
                        : size.width * 0.4 * totalScored / totalmax,
                  ),
                  CrntScrScore(
                    totalscored: totalScored,
                    totalmax: totalmax,
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}

class CrntScrScore extends StatelessWidget {
  final int totalscored, totalmax;
  CrntScrScore({required this.totalscored, required this.totalmax});
  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: totalscored / totalmax >= 7 / 18 ? true : false,
      child: Positioned(
        right: 8,
        child: Text(
          "$totalscored / $totalmax",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class LevelCard extends StatelessWidget {
  final int currentScored, currentMax;
  LevelCard({required this.currentMax, required this.currentScored});
  @override
  Widget build(BuildContext context) {
    var frac = currentScored / currentMax;
    Size size = MediaQuery.of(context).size;
    return Container(
      child: Column(
        children: [
          Text(
            "Current Level",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 6,
          ),
          Container(
            decoration: BoxDecoration(
              color: Color(0xff1F78B4).withOpacity(0.08),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Color(0xff1F78B4).withOpacity(0.4),
                  blurRadius: 4,
                )
              ],
            ),
            height: size.height * 0.05,
            width: size.width * 0.45,
            child: Center(
              child: Text(
                currentLevel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff003670),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class MenteeProfileBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text(
                menteeData.fullName,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              Text(
                "+91 ${menteeData.phoneNumber.toString()}",
                style: TextStyle(
                    color: kGreen, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          DetailsWidget(heading: "Batch", value: menteeData.batchName),
          DetailsWidget(
              heading: "ID Number", value: menteeData.idNumber.toString()),
        ],
      ),
    );
  }
}

class DetailsWidget extends StatelessWidget {
  final String heading, value;
  DetailsWidget({required this.heading, required this.value});
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Column(
      children: [
        Text(
          heading,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        SizedBox(
          height: size.height * 0.005,
        ),
        Text(
          value,
          style: TextStyle(
            color: kRed.withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class TitleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: SvgPicture.asset(
              "assets/icons/back-tb.svg",
              height: size.width * 0.07,
            ),
          ),
        ),
        Container(
          child: Text(
            "Test-Form",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black.withOpacity(0.5),
              fontSize: 16,
            ),
          ),
        ),
        SizedBox(
          width: size.width * 0.42,
          height: size.height * 0.12,
        ),
        IconButton(
          onPressed: () {},
          icon: SvgPicture.asset(
            "assets/icons/edit-tb.svg",
            height: size.height * 0.07,
          ),
        ),
      ],
    );
  }
}

class BreakLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20),
      height: 1,
      width: size.width,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: kBlue.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}

class PrevNxtBtn extends StatelessWidget {
  final VoidCallback previousCallback, nextCallback, submitCallback;
  final int questionIndex;
  PrevNxtBtn(
      {required this.previousCallback,
      required this.nextCallback,
      required this.questionIndex,
      required this.submitCallback});
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InkWell(
            onTap: questionIndex == 0
                ? () {
                    clearForm();
                    Navigator.pop(context);
                  }
                : previousCallback,
            child: Container(
              child: Center(
                child: Text(
                  questionIndex == 0 ? "EXIT" : "PREVIOUS",
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
                color: kRed.withOpacity(0.7),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: kRed.withOpacity(0.7),
                    blurRadius: 10,
                  )
                ],
              ),
            ),
          ),
          InkWell(
            onTap: questionIndex == 9
                ? () {
                    submitCallback();
                    Navigator.pop(context);
                  }
                : nextCallback,
            child: Container(
              child: Center(
                child: Text(
                  questionIndex == 9 ? "FINISH" : "NEXT",
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
                color: Color(0xff1F78B4),
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xff1F78B4),
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
