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
      final user = supabase.auth.currentUser;

      if (user == null) {
        debugPrint('❌ No user logged in.');
        return [];
      }

      debugPrint('🔎 Logged in user ID: ${user.id}');

      // TEMPORARY: Fetch all donations (no filter yet)
      final response = await supabase
          .from('donations')
          .select('*')
          .order('donation_date', ascending: false);

      debugPrint('🧾 All donations data: $response');

      if (response.isEmpty) {
        debugPrint('⚠️ No donations in table.');
        return [];
      }

      // Return all donations for now
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching donation history: $e');
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
          double totalAmount = 0;

          for (var donation in donations) {
            totalAmount += (donation['amount'] ?? 0).toDouble();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Colors.teal.shade100,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.teal,
                  ),
                  title: const Text(
                    'Total Donations (All Users)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('₱${totalAmount.toStringAsFixed(2)}'),
                ),
              ),
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
                      '₱${donation['amount']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${donation['donor_name'] ?? 'Unknown Donor'}\n$target\nType: ${donation['donation_type'] ?? 'N/A'}\nDate: ${donation['donation_date'] ?? ''}',
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
