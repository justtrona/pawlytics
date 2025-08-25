import 'package:flutter/material.dart';
import 'package:pawlytics/route/route.dart' as route;

const brand = Color(0xFF27374D);
const sectionBg = Color(0xFFCFD6DE); // soft grey like the mock
const itemBg = Color(0xFF8F9AA7); // darker grey buttons
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
    return w; // phones use full width
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
                          width: 32, // was 36
                          height: 32,
                        ),
                      ],
                    ),
                  ),

                  // Sections
                  const _SectionTitle('Home'),
                  _SectionCard(
                    children: [
                      _MenuItem(
                        icon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        onTap: () {},
                      ),
                    ],
                  ),

                  const _SectionTitle('Manage Donations'),
                  _SectionCard(
                    children: const [
                      _MenuItem(
                        icon: Icons.history_rounded,
                        label: 'Donation History',
                      ),
                      _MenuItem(
                        icon: Icons.savings_rounded,
                        label: 'Donation Sources',
                      ),
                      _MenuItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'Donation Usage',
                      ),
                    ],
                  ),

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
                      // _MenuItem(
                      //   icon: Icons.flag_rounded,
                      //   label: 'Goals Settings',
                      // ),
                      _MenuItem(
                        icon: Icons.power_rounded,
                        label: 'Utilities',
                        onTap: () =>
                            Navigator.pushNamed(context, route.utilitiesMain),
                      ),
                      _MenuItem(
                        icon: Icons.location_on_rounded,
                        label: 'Location',
                      ),
                    ],
                  ),

                  const _SectionTitle('Reports and Analytics'),
                  _SectionCard(
                    children: const [
                      _MenuItem(
                        icon: Icons.local_atm_rounded,
                        label: 'Donation Reports',
                      ),
                      _MenuItem(
                        icon: Icons.bar_chart_rounded,
                        label: 'Campaigns Reports',
                      ),
                      _MenuItem(
                        icon: Icons.track_changes_rounded,
                        label: 'Goal Performance Reports',
                      ),
                      _MenuItem(
                        icon: Icons.receipt_rounded,
                        label: 'Expense Reports',
                      ),
                      _MenuItem(
                        icon: Icons.feedback_rounded,
                        label: 'Feedbacks',
                      ),
                      _MenuItem(
                        icon: Icons.analytics_rounded,
                        label: 'Donors Behavior Analytics',
                      ),
                      _MenuItem(
                        icon: Icons.emoji_events_rounded,
                        label: 'Rewards & Certifications',
                      ),
                    ],
                  ),

                  const _SectionTitle('Payment Integration'),
                  _SectionCard(
                    children: const [
                      _MenuItem(
                        icon: Icons.tune_rounded,
                        label: 'Payment Configurations',
                      ),
                      _MenuItem(
                        icon: Icons.hub_rounded,
                        label: 'Gateway Configurations',
                      ),
                    ],
                  ),

                  const _SectionTitle('Settings'),
                  _SectionCard(
                    children: const [
                      _MenuItem(
                        icon: Icons.rule_folder_rounded,
                        label: 'Audit Log',
                      ),
                      _MenuItem(
                        icon: Icons.admin_panel_settings_rounded,
                        label: 'Admin Settings',
                      ),
                    ],
                  ),

                  const _SectionTitle('User'),
                  _SectionCard(
                    children: const [
                      _MenuItem(icon: Icons.person_rounded, label: 'Profile'),
                      _MenuItem(icon: Icons.logout_rounded, label: 'Logout'),
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

/// Title like "Manage Donations"
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

  int _colsForWidth(double w) {
    if (w >= 1100) return 4; // large screens
    if (w >= 800) return 3; // tablets / small desktop
    if (w >= 520) return 2; // big phones
    return 1; // small phones
  }

  double _targetItemHeight(double w) {
    // Compact heights per breakpoint (in px)
    if (w >= 1100) return 48;
    if (w >= 800) return 46;
    if (w >= 520) return 44;
    return 42;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFF6D7884),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = _colsForWidth(constraints.maxWidth);
          const spacing = 10.0;
          final colWidth = (constraints.maxWidth - (cols - 1) * spacing) / cols;
          final itemHeight = _targetItemHeight(constraints.maxWidth);
          final ratio = colWidth / itemHeight; // width / height

          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: ratio,
            children: children,
          );
        },
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _MenuItem({required this.icon, required this.label, this.onTap});

  double _scale(double w) {
    // Slight scale-down for compact UI
    if (w >= 1100) return 1.0;
    if (w >= 800) return 0.95;
    if (w >= 520) return 0.92;
    return 0.90;
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final s = _scale(w);

    return Material(
      color: Color(0xFF6D7884),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () {},
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 10 * s),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20 * s), // was 22
              SizedBox(width: 8 * s),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13 * s, // was 13.5
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
