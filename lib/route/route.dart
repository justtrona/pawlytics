import 'package:flutter/material.dart';
import 'package:pawlytics/views/get_start/get_started.dart';
import 'package:pawlytics/views/get_start/login_page.dart';
import 'package:pawlytics/views/get_start/get_started_main.dart';
import 'package:pawlytics/views/get_start/sign_up.dart';

// route navigation list

const String landing = '/';
const String login = 'login';
const String signup = 'signup';

Route<dynamic> controller(RouteSettings settings) {
  switch (settings.name) {
    case landing:
      return MaterialPageRoute(builder: (context) => GetStartedPage());
    case login:
      return MaterialPageRoute(builder: (context) => LoginPage());
    case signup:
      return MaterialPageRoute(builder: (context) => SignUp());

    default:
      throw ('Page Does Not Exist');
  }
}
