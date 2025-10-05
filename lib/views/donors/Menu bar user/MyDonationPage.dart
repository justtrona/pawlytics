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

  Future<List<Map<String, dynamic>>> fetchDonationHistory() async {
    try {
      debugPrint('🚀 Running donation query...');
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No logged-in user found');
        return [];
      }

      final response = await supabase
          .from('donations')
          .select('''
            id,
            donor_name,
            donation_type,
            donation_date,
            amount,
            opex_id,
            campaign_id,
            pet_id,
            pet_profiles (name),
            campaigns (program)
          ''')
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

  String getDonationTarget(Map<String, dynamic> donation) {
    if (donation['pet_profiles'] != null &&
        donation['pet_profiles']['pet_name'] != null) {
      return 'Pet: ${donation['pet_profiles']['pet_name']}';
    } else if (donation['campaigns'] != null &&
        donation['campaigns']['program'] != null) {
      return 'Campaign: ${donation['campaigns']['program']}';
    } else if (donation['opex_id'] != null) {
      return 'Operation Expense (Opex ID: ${donation['opex_id']})';
    } else {
      return 'General Donation';
    }
  }

  double parseAmount(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0;
    }
    return 0;
  }

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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Donation History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        elevation: 2,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _donationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No donations found.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final donations = snapshot.data!;
          double totalAmount = donations.fold(
            0,
            (sum, item) => sum + parseAmount(item['amount']),
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                color: Colors.teal.shade50,
                margin: const EdgeInsets.only(bottom: 20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.teal,
                        child: const Icon(
                          Icons.volunteer_activism,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Donations',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₱${NumberFormat('#,##0.00').format(totalAmount)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Your Recent Donations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              ...donations.map((donation) {
                final target = getDonationTarget(donation);
                final amount = parseAmount(donation['amount']);
                final date = formatDate(donation['donation_date']);
                final type = donation['donation_type'] ?? 'N/A';

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.teal.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            type.toLowerCase() == 'cash'
                                ? Icons.payments
                                : Icons.card_giftcard,
                            color: Colors.teal.shade800,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                target,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '₱${NumberFormat('#,##0.00').format(amount)}',
                                style: const TextStyle(
                                  color: Colors.teal,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Type: $type',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    date,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
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
