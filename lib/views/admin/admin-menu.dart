import 'package:flutter/material.dart';
import 'package:pawlytics/route/route.dart' as route;
import 'package:supabase_flutter/supabase_flutter.dart';

const brand = Color(0xFF27374D);
const sectionBg = Color(0xFFCFD6DE);
const itemBg = Color(0xFF8F9AA7);
const textGrey = Color(0xFF5F6B78);

class menuBar extends StatefulWidget {
  const menuBar({super.key});

  @override
  State<menuBar> createState() => _menuBarState();
}

class _menuBarState extends State<menuBar> {
  double _contentMaxWidth(double w) {
    if (w >= 1400) return 920;
    if (w >= 1100) return 840;
    if (w >= 800) return 720;
    if (w >= 520) return 520;
    return w;
  }

  //confirm first before succesfully logout
  Future<void> _confirmAndLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // logout logic sa admin menu
    try {
      await Supabase.instance.client.auth.signOut();

      // Optional: notify
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Signed out successfully')));

      // Go to login and clear history
      Navigator.of(context).pushNamedAndRemoveUntil(route.login, (r) => false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final maxW = _contentMaxWidth(w);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18, // was 20
                          backgroundImage: AssetImage(
                            'assets/images/avatar.png',
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Super Admin',
                          style: TextStyle(
                            color: textGrey,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Image.asset(
                          'assets/images/small_logo.png',
                          width: 32,
                          height: 32,
                        ),
                      ],
                    ),
                  ),

                  const _SectionTitle('Home'),
                  _SectionCard(
                    children: [
                      _MenuItem(
                        icon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        onTap: () => Navigator.pushNamed(
                          context,
                          route.navigationButtonAdmin,
                        ),
                        // onTap: () => Navigator.pushNamed(
                        //   context,
                        //   route.navigationButtonAdmin,
                        // ),
                      ),
                    ],
                  ),

                  // const _SectionTitle('Manage Donations'),
                  // _SectionCard(
                  //   children: [
                  //     _MenuItem(
                  //       icon: Icons.history_rounded,
                  //       label: 'Donation History',
                  //       onTap: () =>
                  //           Navigator.pushNamed(context, route.donationHistory),
                  //     ),
                  //     // _MenuItem(
                  //     //   icon: Icons.savings_rounded,
                  //     //   label: 'Donation Sources',
                  //     // ),
                  //     _MenuItem(
                  //       icon: Icons.receipt_long_rounded,
                  //       label: 'Fund Usage',
                  //       onTap: () =>
                  //           Navigator.pushNamed(context, route.usageFund),
                  //     ),
                  //   ],
                  // ),
                  const _SectionTitle('Fundraising Tools'),
                  _SectionCard(
                    children: [
                      _MenuItem(
                        icon: Icons.campaign_rounded,
                        label: 'Campaigns',
                        onTap: () =>
                            Navigator.pushNamed(context, route.createCampaign),
                      ),
                      _MenuItem(
                        icon: Icons.pets_rounded,
                        label: 'Pet Profiles',
                        onTap: () =>
                            Navigator.pushNamed(context, route.petProfiles),
                      ),

                      _MenuItem(
                        icon: Icons.money_rounded,
                        label: 'Operational Expense',
                        onTap: () => Navigator.pushNamed(
                          context,
                          route.operationalExpenseModule,
                        ),
                      ),

                      _MenuItem(
                        icon: Icons.money_rounded,
                        label: 'Manual Donation',
                        onTap: () =>
                            Navigator.pushNamed(context, route.manualDonation),
                      ),

                      // _MenuItem(
                      //   icon: Icons.power_rounded,
                      //   label: 'Utilities',
                      //   onTap: () =>
                      //       Navigator.pushNamed(context, route.utilitiesMain),
                      // ),
                      _MenuItem(
                        icon: Icons.location_on_rounded,
                        label: 'Location',
                        onTap: () =>
                            Navigator.pushNamed(context, route.dropoffLocation),
                      ),
                      _MenuItem(
                        icon: Icons.location_on_rounded,
                        label: 'In-Kind ',
                        onTap: () =>
                            Navigator.pushNamed(context, route.inkindpage),
                      ),
                    ],
                  ),

                  const _SectionTitle('Reports and Analytics'),
                  _SectionCard(
                    children: [
                      _MenuItem(
                        icon: Icons.local_atm_rounded,
                        label: 'Donation Reports',
                        onTap: () =>
                            Navigator.pushNamed(context, route.donationReports),
                      ),
                      // _MenuItem(
                      //   icon: Icons.bar_chart_rounded,
                      //   label: 'Campaigns Reports',
                      //   onTap: () =>
                      //       Navigator.pushNamed(context, route.campaignreports),
                      // ),
                      // _MenuItem(
                      //   icon: Icons.track_changes_rounded,
                      //   label: 'Goal Performance Reports',
                      // ),
                      // _MenuItem(
                      //   icon: Icons.receipt_rounded,
                      //   label: 'Expense Reports',
                      //   onTap: () =>
                      //       Navigator.pushNamed(context, route.expensereports),
                      // ),
                      // _MenuItem(
                      //   icon: Icons.feedback_rounded,
                      //   label: 'Feedbacks',
                      // ),
                      _MenuItem(
                        icon: Icons.analytics_rounded,
                        label: 'Donors Behavior Analytics',
                        onTap: () =>
                            Navigator.pushNamed(context, route.donorsAnalytics),
                      ),
                      _MenuItem(
                        icon: Icons.emoji_events_rounded,
                        label: 'Rewards & Certifications',
                        onTap: () => Navigator.pushNamed(
                          context,
                          route.rewardsCertification,
                        ),
                      ),
                    ],
                  ),

                  const _SectionTitle('Payment Integration'),
                  _SectionCard(
                    children: [
                      _MenuItem(
                        icon: Icons.tune_rounded,
                        label: 'Payment Configurations',
                        onTap: () => Navigator.pushNamed(
                          context,
                          route.paymentConfiguration,
                        ),
                      ),
                      // _MenuItem(
                      //   icon: Icons.hub_rounded,
                      //   label: 'Gateway Configurations',
                      // ),
                    ],
                  ),

                  const _SectionTitle('Settings'),
                  _SectionCard(
                    children: [
                      _MenuItem(
                        icon: Icons.rule_folder_rounded,
                        label: 'Audit Log',
                        onTap: () =>
                            Navigator.pushNamed(context, route.auditLog),
                      ),
                      _MenuItem(
                        icon: Icons.feedback_rounded,
                        label: 'Feedbacks',
                        onTap: () =>
                            Navigator.pushNamed(context, route.feedback),
                      ),
                      _MenuItem(
                        icon: Icons.admin_panel_settings_rounded,
                        label: 'Admin Settings',
                        onTap: () =>
                            Navigator.pushNamed(context, route.adminSettings),
                      ),
                      _MenuItem(
                        icon: Icons.person_2_outlined,
                        label: "Manage User",
                        onTap: () =>
                            Navigator.pushNamed(context, route.userManage),
                      ),
                    ],
                  ),

                  const _SectionTitle('User'),
                  _SectionCard(
                    children: [
                      _MenuItem(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        onTap: () =>
                            Navigator.pushNamed(context, route.adminProfile),
                      ),
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        label: 'Logout',
                        onTap: _confirmAndLogout,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6D7884),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<_MenuItem> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        //color: const Color(0xFF6D7884),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            // each item takes full width (top -> bottom)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 46),
              child: children[i],
            ),
            if (i != children.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _MenuItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF5E6B7F),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () {},
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 0),
                Icon(icon, color: const Color(0xFFEC8C69), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
