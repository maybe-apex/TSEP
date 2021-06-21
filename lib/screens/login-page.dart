import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tsep/local-data/constants.dart';

import '../logic/authentication.dart';
import '../components/loading.dart';
import '../screens/signup-page.dart';
import 'mentor-profile.dart';

class LoginPage extends StatefulWidget {
  static String route = "LoginPage";
  @override
  _LoginPageState createState() => _LoginPageState();
}

TextEditingController emailController = TextEditingController();
TextEditingController passwordController = TextEditingController();
final GlobalKey<FormState> formKey = GlobalKey<FormState>();

class _LoginPageState extends State<LoginPage> {
  bool loading = false;

  void loginCallback() async {
    final auth = Authentication();
    try {
      setState(() {
        loading = true;
      });
      final newUser =
          await auth.loginUser(emailController.text, passwordController.text);
      if (newUser != null) Navigator.pushNamed(context, MentorProfile.route);
    } catch (e) {
      setState(() {
        loading = false;
      });
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return loading
        ? Loading()
        : Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: size.width * 0.12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      mainLogo(),
                      SignupWrapper(),
                      MntrMenteeWrapper(),
                      SizedBox(height: size.height * 0.025),
                      EmailInputForm(),
                      SizedBox(height: size.height * 0.0125),
                      PasswordInputForm(),
                      frgtPassWrapper(),
                      LoginWrapper(callback: loginCallback),
                      FooterText(),
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}

class FooterText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Made in India with "),
        Icon(Icons.favorite, color: Colors.grey, size: 15),
      ],
    );
  }
}

class LoginWrapper extends StatelessWidget {
  final VoidCallback callback;
  LoginWrapper({required this.callback});
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(size.width * 0.6, size.height * 0.06),
              primary: kRed.withOpacity(0.65),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }
              callback();
            },
            child: Text('Login'),
          ),
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(
              "assets/icons/google-login.svg",
              height: 40,
            ),
          )
        ],
      ),
    );
  }
}

class frgtPassWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Forgot Password ? /',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Open Sans',
            color: Color(0xffAFAFAD),
          ),
        ),
        TextButton(
          onPressed: () => showSnackBar(context),
          child: Text(
            "Reset",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Open Sans',
              color: Color(0xff6D6D6D),
            ),
          ),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
          ),
        )
      ],
    );
  }
}

class MntrMenteeWrapper extends StatefulWidget {
  @override
  _MntrMenteeWrapperState createState() => _MntrMenteeWrapperState();
}

class _MntrMenteeWrapperState extends State<MntrMenteeWrapper> {
  String active = 'mentor';
  void onTap(String who) {
    setState(() {
      active = who;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        MentorMenteeButton(
          icon: "assets/icons/mentee.svg",
          who: 'mentee',
          active: active,
          ontap: onTap,
        ),
        MentorMenteeButton(
          icon: "assets/icons/mentor.svg",
          who: 'mentor',
          active: active,
          ontap: onTap,
        ),
      ],
    );
  }
}

class MentorMenteeButton extends StatelessWidget {
  final String icon, who, active;
  final Function ontap;
  MentorMenteeButton(
      {required this.icon,
      required this.who,
      required this.active,
      required this.ontap});
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      padding: EdgeInsets.all(5),
      decoration: active == who
          ? BoxDecoration(
              color: kBlue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8))
          : null,
      child: InkWell(
        onTap: () => ontap(who),
        child: SvgPicture.asset(
          icon,
          height: size.height * 0.05,
        ),
      ),
    );
  }
}

class SignupWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: EdgeInsets.symmetric(vertical: size.height * 0.025),
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Lets get started\nLog in.",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    child: Text(
                      'If you are new /',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xffAFAFAD),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, SignUp.route);
                    },
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xff6D6D6D),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SvgPicture.asset(
            "assets/tsep-logo.svg",
            height: MediaQuery.of(context).size.height * 0.11,
          ),
        ],
      ),
    );
  }
}

class mainLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.06),
      child: SvgPicture.asset(
        "assets/Kotak_Mahindra_Bank_logo.svg",
        height: MediaQuery.of(context).size.height * 0.25,
      ),
    );
  }
}

class EmailInputForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: TextFormField(
        controller: emailController,
        validator: (String? val) {
          String value = val ?? 'test';
          if (value.isNotEmpty && value.length > 5 && value != 'test')
            return null;
          else
            return 'Invalid Input';
        },
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: kBlue.withOpacity(0.7),
          // border: OutlineInputBorder(),
          hintText: 'Email',
          hintStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            borderSide: BorderSide(color: Color(0x00003670), width: 0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
            borderSide: BorderSide(color: Color(0x00003670), width: 0),
          ),
        ),
      ),
    );
  }
}

class PasswordInputForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: passwordController,
      obscureText: true,
      style: TextStyle(
        color: Color(0xffAFAFAD),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Color(0xffF5F5F5),
        // border: OutlineInputBorder(),
        hintText: 'Password',
        hintStyle: TextStyle(
          color: Color(0xffAFAFAD),
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(12.0),
          ),
          borderSide: BorderSide(color: Color(0x00003670), width: 0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(12.0),
          ),
          borderSide: BorderSide(color: Color(0x00003670), width: 0),
        ),
      ),
    );
  }
}

void showSnackBar(BuildContext context) {
  final scaffold = ScaffoldMessenger.of(context);
  scaffold.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 3,
      backgroundColor: kRed.withOpacity(0.7),
      content: const Text(
        'Please enter your email address.',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      action: SnackBarAction(
        label: 'OK',
        onPressed: scaffold.hideCurrentSnackBar,
        textColor: Colors.black54,
      ),
    ),
  );
}
