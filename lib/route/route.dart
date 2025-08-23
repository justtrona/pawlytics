import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/admin-dashboard.dart';
import 'package:pawlytics/views/admin/admin_widgets/navigation-buttons.dart';
import 'package:pawlytics/views/get_start/get_started.dart';
import 'package:pawlytics/views/get_start/login_page.dart';
import 'package:pawlytics/views/get_start/sign_up.dart';

// route navigation list

const String landing = '/';
const String login = 'login';
const String signup = 'signup';
const String adminDashboard = 'admin-dashboard';
const String navigationButtonAdmin = 'navigation-button-admin';

Route<dynamic> controller(RouteSettings settings) {
  switch (settings.name) {
    case landing:
      return MaterialPageRoute(builder: (context) => GetStartedPage());
    case login:
      return MaterialPageRoute(builder: (context) => LoginPage());
    case signup:
      return MaterialPageRoute(builder: (context) => SignUp());
    case adminDashboard:
      return MaterialPageRoute(builder: (context) => AdminDashboard());
    case navigationButtonAdmin:
      return MaterialPageRoute(builder: (context) => NavigationButtonAdmin());

    default:
      return MaterialPageRoute(builder: (_) => const NavigationButtonAdmin());
  }
}
