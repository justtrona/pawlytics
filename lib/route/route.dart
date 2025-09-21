import 'package:flutter/material.dart';
import 'package:pawlytics/views/admin/admin-dashboard.dart';
import 'package:pawlytics/views/admin/admin-profile/admin-profile.dart';
import 'package:pawlytics/views/admin/admin-settings.dart';
import 'package:pawlytics/views/admin/admin_widgets/navigation-buttons.dart';
import 'package:pawlytics/views/admin/audit/audit-log.dart';
import 'package:pawlytics/views/admin/campaigns/create-campaign.dart';
import 'package:pawlytics/views/admin/campaigns/reports-campaigns.dart';
import 'package:pawlytics/views/admin/donation/history-donation.dart';
import 'package:pawlytics/views/admin/donation/report-donation.dart';
// import 'package:pawlytics/views/admin/donation/usage-donation.dart';
import 'package:pawlytics/views/admin/donation/usage-fund.dart';
import 'package:pawlytics/views/admin/donors-analytics/rewards-certification.dart';
import 'package:pawlytics/views/admin/dropoff-location/create-dropoff.dart';
import 'package:pawlytics/views/admin/dropoff-location/dropoff-location.dart';
import 'package:pawlytics/views/admin/expense/expense-report.dart';
import 'package:pawlytics/views/admin/feedbacks/feedback.dart';
import 'package:pawlytics/views/admin/payment-config/payment-configuration.dart';
import 'package:pawlytics/views/admin/pet-profiles/add-petprofile.dart';
// import 'package:pawlytics/views/admin/utilities/addUtilities.dart';
// import 'package:pawlytics/views/admin/utilities/utilities-main.dart';
import 'package:pawlytics/views/donors/donor%20navigation%20func/RoutePage.dart';
import 'package:pawlytics/views/get_start/get_started.dart';
import 'package:pawlytics/views/get_start/get_started_main.dart';
import 'package:pawlytics/views/get_start/get_started_two.dart';
import 'package:pawlytics/views/get_start/login_page.dart';
import 'package:pawlytics/views/get_start/sign_up.dart';
import 'package:pawlytics/views/admin/campaigns/campaigns-settings.dart';
import 'package:pawlytics/views/admin/pet-profiles/pet-profiles.dart';
import 'package:pawlytics/views/admin/donors-analytics/donors-analytics.dart';
import 'package:pawlytics/views/landing_page.dart';

//donors imports
// import 'package:pawlytics/views/donors/donors navigation bar/HomePage.dart';

// route navigation list

const String landing = '/';
const String getStartedPage = '/getStartedPage';
const String getStartedPage2 = 'getStartedPage2';
const String login = 'login';
const String signup = 'signup';
const String adminDashboard = 'admin-dashboard';
const String navigationButtonAdmin = 'navigation-button-admin';
const String campaignSettings = 'campaigns-settings';
const String petProfiles = 'pet-profiles';
const String utilitiesMain = 'utilities-main';
const String createCampaign = 'create-campaign';
const String dropoffLocation = 'dropoff-location';
const String createDropoff = 'create-dropoff';
const String addPetProfile = 'add-pet-profile';
const String addUtilities = 'add-utilities';
const String donationHistory = 'donation-history';
const String usageFund = 'usage-donation';
const String donationReports = 'donation-reports';
const String campaignreports = 'campaigns-report';
const String expensereports = 'expense-report';
const String donorsAnalytics = 'donors-analytics';
const String rewardsCertification = 'rewards-certification';
const String paymentConfiguration = 'payment-configuration';
const String auditLog = 'audit-log';
const String feedback = 'feedback';
const String adminSettings = 'admin-settings';
const String adminProfile = 'admin-profile';

// donors
const String routePage = 'routePage';

Route<dynamic> controller(RouteSettings settings) {
  switch (settings.name) {
    case landing:
      return MaterialPageRoute(builder: (context) => GetStartedPage());
    case getStartedPage:
      return MaterialPageRoute(builder: (context) => GetStartedMain());
    case getStartedPage2:
      return MaterialPageRoute(builder: (context) => GetStartedPageTwo());
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
    // case utilitiesMain:
    //   return MaterialPageRoute(builder: (context) => UtilitiesMain());
    case createCampaign:
      return MaterialPageRoute(builder: (context) => CreateCampaign());
    case dropoffLocation:
      return MaterialPageRoute(builder: (context) => DropoffLocation());
    case createDropoff:
      return MaterialPageRoute(builder: (context) => CreateDropoff());
    case addPetProfile:
      return MaterialPageRoute(builder: (context) => AddPetProfile());
    // case addUtilities:
    //   return MaterialPageRoute(builder: (context) => AddUtilities());
    case donationHistory:
      return MaterialPageRoute(builder: (context) => DonationHistory());
    case usageFund:
      return MaterialPageRoute(builder: (context) => FundUsage());
    case donationReports:
      return MaterialPageRoute(builder: (context) => DonationReports());
    case campaignreports:
      return MaterialPageRoute(builder: (context) => ReportsCampaigns());
    case expensereports:
      return MaterialPageRoute(builder: (context) => ExpenseReport());
    case donorsAnalytics:
      return MaterialPageRoute(builder: (context) => DonorsAnalytics());
    case rewardsCertification:
      return MaterialPageRoute(builder: (context) => RewardsCertification());
    case paymentConfiguration:
      return MaterialPageRoute(
        builder: (context) => AdminPaymentConfiguration(),
      );
    case auditLog:
      return MaterialPageRoute(builder: (context) => AdminAuditLog());
    case feedback:
      return MaterialPageRoute(builder: (context) => FeedbackScreen());
    case adminSettings:
      return MaterialPageRoute(builder: (context) => AdminSettingsScreen());
    case adminProfile:
      return MaterialPageRoute(builder: (context) => AdminProfile());

    // donors
    case routePage:
      return MaterialPageRoute(builder: (context) => RoutePage());

    default:
      return MaterialPageRoute(builder: (_) => const NavigationButtonAdmin());
  }
}
