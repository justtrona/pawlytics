import 'package:pawlytics/views/admin/model/campaigns-model.dart';

class CampaignController {
  // Mock data
  final List<Campaign> allCampaigns = [
    Campaign(
      title: 'Medical Care for Peter',
      raised: 2500,
      goal: 5000,
      status: CampaignStatus.active,
      deadline: DateTime(2025, 7, 25),
      createdAt: DateTime(2025, 6, 6),
      image:
          'https://images.unsplash.com/photo-1543466835-00a7907e9de1?q=80&w=600&auto=format&fit=crop',
    ),
    Campaign(
      title: 'Food and Shelter for Strays',
      raised: 5500,
      goal: 8000,
      status: CampaignStatus.ended,
      deadline: DateTime(2025, 5, 25),
      createdAt: DateTime(2025, 4, 12),
      image:
          'https://images.unsplash.com/photo-1534361960057-19889db9621e?q=80&w=1200&auto=format&fit=crop',
    ),
    Campaign(
      title: 'Medical Care for Peter',
      raised: 8000,
      goal: 10000,
      status: CampaignStatus.ended,
      deadline: DateTime(2025, 4, 11),
      createdAt: DateTime(2025, 3, 2),
      image:
          'https://images.unsplash.com/photo-1518791841217-8f162f1e1131?q=80&w=1000&auto=format&fit=crop',
    ),
  ];

  // Filtering
  List<Campaign> filterCampaigns({
    required String statusFilter,
    required String sortBy,
  }) {
    var list = allCampaigns.where((c) {
      if (statusFilter == 'All Statuses') return true;
      if (statusFilter == 'Active') return c.status == CampaignStatus.active;
      if (statusFilter == 'Ended') return c.status == CampaignStatus.ended;
      return true;
    }).toList();

    switch (sortBy) {
      case 'Date Created':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Deadline':
        list.sort((a, b) => a.deadline.compareTo(b.deadline));
        break;
      case 'Amount Raised':
        list.sort((a, b) => (b.raised / b.goal).compareTo(a.raised / a.goal));
        break;
    }
    return list;
  }

  // Stats
  int getActiveCount() =>
      allCampaigns.where((c) => c.status == CampaignStatus.active).length;

  int getTotalCampaigns() => allCampaigns.length;

  num getTotalRaised() =>
      allCampaigns.fold<num>(0, (sum, c) => sum + (c.raised));

  // Formatters
  String formatMoney(num v) {
    final s = v.toStringAsFixed(0);
    final re = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return 'PHP ${s.replaceAllMapped(re, (m) => ',')}';
  }

  String formatDate(DateTime d) {
    const months = [
      '',
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }
}
