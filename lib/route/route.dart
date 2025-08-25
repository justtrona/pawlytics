import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/admin-dashboard.dart';
import 'package:pawlytics/views/admin/admin_widgets/navigation-buttons.dart';
import 'package:pawlytics/views/admin/campaigns/create-campaign.dart';
import 'package:pawlytics/views/admin/utilities/utilities-main.dart';
import 'package:pawlytics/views/get_start/get_started.dart';
import 'package:pawlytics/views/get_start/login_page.dart';
import 'package:pawlytics/views/get_start/sign_up.dart';
import 'package:pawlytics/views/admin/campaigns/campaigns-settings.dart';
import 'package:pawlytics/views/admin/pet-profiles/pet-profiles.dart';

// route navigation list

const String landing = '/';
const String login = 'login';
const String signup = 'signup';
const String adminDashboard = 'admin-dashboard';
const String navigationButtonAdmin = 'navigation-button-admin';
const String campaignSettings = 'campaigns-settings';
const String petProfiles = 'pet-profiles';
const String utilitiesMain = 'utilities-main';
const String createCampaign = 'create-campaign';

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
    case campaignSettings:
      return MaterialPageRoute(builder: (context) => CampaignSettingsScreen());
    case petProfiles:
      return MaterialPageRoute(builder: (context) => PetProfiles());
    case utilitiesMain:
      return MaterialPageRoute(builder: (context) => UtilitiesMain());
    case createCampaign:
      return MaterialPageRoute(builder: (context) => CreateCampaign());

    default:
      return MaterialPageRoute(builder: (_) => const NavigationButtonAdmin());
  }
}
