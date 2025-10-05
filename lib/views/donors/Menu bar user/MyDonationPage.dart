import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  /// 🧠 Fetch donation history from Supabase (for logged-in user only)
  Future<List<Map<String, dynamic>>> fetchDonationHistory() async {
    try {
      debugPrint('🚀 Running donation query...');

      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No logged-in user found.');
        return [];
      }

      // 🧩 Fetch only donations belonging to this specific user
      final response = await supabase
          .from('donations')
          .select(
            'id, donor_name, donation_type, donation_date, amount, opex_id, campaign_id, pet_id',
          )
          .eq('user_id', user.id)
          .order('donation_date', ascending: false);

      debugPrint('🧩 Raw Supabase response: $response');

      if (response.isEmpty) {
        debugPrint('⚠️ No rows returned by Supabase for user ${user.id}');
        return [];
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      debugPrint('❌ Error fetching donation history: $e');
      debugPrint(st.toString());
      return [];
    }
  }

  /// 🎯 Determine the donation’s target
  String getDonationTarget(Map<String, dynamic> donation) {
    if (donation['opex_id'] != null) {
      return 'Operation Expense (Opex ID: ${donation['opex_id']})';
    } else if (donation['campaign_id'] != null) {
      return 'Campaign ID: ${donation['campaign_id']}';
    } else if (donation['pet_id'] != null) {
      return 'Pet ID: ${donation['pet_id']}';
    } else {
      return 'General Donation';
    }
  }

  /// 💰 Safely parse amount
  double parseAmount(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0;
    }
    return 0;
  }

  /// 📅 Format date
  String formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Unknown Date';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat.yMMMMd().format(date);
    } catch (_) {
      return isoString;
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
            totalAmount += parseAmount(donation['amount']);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 💰 Total donations card
              Card(
                color: Colors.teal.shade100,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.teal,
                  ),
                  title: const Text(
                    'Total Donations',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '₱${NumberFormat('#,##0.00').format(totalAmount)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const Text(
                'Donation Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // 🧾 List of donations
              ...donations.map((donation) {
                final target = getDonationTarget(donation);
                final amount = parseAmount(donation['amount']);
                final date = formatDate(donation['donation_date']);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                    ),
                    title: Text(
                      '₱${NumberFormat('#,##0.00').format(amount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '$target\nType: ${donation['donation_type'] ?? 'N/A'}\nDate: $date',
                    ),
                    isThreeLine: true,
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
