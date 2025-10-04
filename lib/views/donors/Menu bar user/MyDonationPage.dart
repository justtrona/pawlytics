import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DonationHistoryPage extends StatefulWidget {
  const DonationHistoryPage({super.key});

  @override
  State<DonationHistoryPage> createState() => _DonationHistoryPageState();
}

class _DonationHistoryPageState extends State<DonationHistoryPage> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _donationsFuture;

  @override
  void initState() {
    super.initState();
    _donationsFuture = fetchDonationHistory();
  }

  Future<List<Map<String, dynamic>>> fetchDonationHistory() async {
    try {
      final response = await supabase.from('donations').select('*');

      debugPrint('✅ Raw donations response: $response');

      if (response.isEmpty) {
        debugPrint('⚠️ No rows found in donations table.');
        return [];
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching donations: $e');
      return [];
    }
  }

  String getDonationTarget(Map<String, dynamic> donation) {
    final campaign = donation['campaigns']?['title'];
    final pet = donation['pet_profiles']?['name'];
    final goal = donation['operational_expense_allocations']?['title'];

    if (campaign != null && campaign.isNotEmpty) {
      return 'Campaign: $campaign';
    } else if (pet != null && pet.isNotEmpty) {
      return 'Pet: $pet';
    } else if (goal != null && goal.isNotEmpty) {
      return 'Goal: $goal';
    } else {
      return 'General Donation';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation History'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _donationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No donations found.'));
          }

          final donations = snapshot.data!;
          final Map<String, double> totals = {};

          for (var donation in donations) {
            final name = donation['donor_name'] ?? 'Unknown Donor';
            final amount = (donation['amount'] ?? 0).toDouble();
            totals[name] = (totals[name] ?? 0) + amount;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Total Donations by Donor',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...totals.entries.map((entry) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(entry.key),
                    subtitle: Text('Total: ₱${entry.value.toStringAsFixed(2)}'),
                    leading: const Icon(Icons.volunteer_activism),
                  ),
                );
              }),
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Donation Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...donations.map((donation) {
                final target = getDonationTarget(donation);
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      '${donation['donor_name']} - ₱${donation['amount']}',
                    ),
                    subtitle: Text(
                      '$target\nType: ${donation['donation_type'] ?? 'N/A'}\nDate: ${donation['donation_date'] ?? ''}',
                    ),
                    isThreeLine: true,
                    leading: const Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
