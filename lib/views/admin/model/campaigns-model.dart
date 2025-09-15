// lib/models/campaign_model.dart

enum CampaignStatus { active, ended }

class Campaign {
  final String title;
  final int raised;
  final int goal;
  final DateTime deadline;
  final DateTime createdAt;
  final String image;
  final CampaignStatus status;

  Campaign({
    required this.title,
    required this.raised,
    required this.goal,
    required this.deadline,
    required this.createdAt,
    required this.image,
    required this.status,
  });
}
