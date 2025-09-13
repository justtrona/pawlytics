import 'package:flutter/material.dart';

class ReportsCampaigns extends StatefulWidget {
  const ReportsCampaigns({super.key});

  @override
  State<ReportsCampaigns> createState() => _ReportsCampaignsState();
}

class _ReportsCampaignsState extends State<ReportsCampaigns> {
  // Palette
  static const Color brand = Color(0xFF27374D);
  static const Color navy = brand;
  static const Color chipBg = Color(0xFFE8EEF4);
  static const Color cardBorder = Color(0xFFCBD5E1);
  static const Color progressBg = Color(0xFFCED6DE);
  static const Color txtGrey = Color(0xFF6D7884);

  // Filters
  String _selectedCampaign = 'All Campaigns';
  String _selectedStatus = 'All Statuses';

  final _campaignOptions = const [
    'All Campaigns',
    'Adoption Medical Fund',
    'Pet Medical Support',
    'Emergency Care',
  ];
  final _statusOptions = const ['All Statuses', 'On Track', 'Completed'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Simple AppBar (no bottom:)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Campaign Reports',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 0.2,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),

      // Content (filters + cards + button) — ConstrainedBox removed
      body: SingleChildScrollView(
        // keep top padding minimal so chips sit right under the AppBar
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            Row(
              children: [
                Expanded(
                  child: _DropdownChip(
                    value: _selectedCampaign,
                    values: _campaignOptions,
                    onChanged: (v) => setState(() => _selectedCampaign = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DropdownChip(
                    value: _selectedStatus,
                    values: _statusOptions,
                    onChanged: (v) => setState(() => _selectedStatus = v),
                  ),
                ),
              ],
            ),

            // Tighten gap before first card
            const SizedBox(height: 8),

            // Cards
            const _CampaignCard(
              title: 'Adoption Medical Fund',
              priceRange: 'PHP 80.00 - PHP 150.00',
              statusText: 'On Track',
              progress: 0.70,
              leftCaption: 'Goal: 200 Pets',
              rightCaption: 'Reached: 141 Pets',
            ),
            const SizedBox(height: 16),
            const _CampaignCard(
              title: 'Pet Medical Support',
              priceRange: 'PHP 80.00 - PHP 150.00',
              statusText: 'Completed',
              progress: 0.90,
              leftCaption: 'Goal: 150 Pets',
              rightCaption: 'Reached: 160 Pets',
            ),
            const SizedBox(height: 16),
            const _CampaignCard(
              title: 'Emergency Care',
              priceRange: 'PHP 80.00 - PHP 150.00',
              statusText: 'On Track',
              progress: 0.60,
              leftCaption: 'Goal: 100 Pets',
              rightCaption: 'Reached: 67 Pets',
            ),

            const SizedBox(height: 24),

            // Manage button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () {},
                child: const Text(
                  'MANAGE',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// --- Small reusable dropdown chip -------------------------------------------------
class _DropdownChip extends StatelessWidget {
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  const _DropdownChip({
    required this.value,
    required this.values,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: _ReportsCampaignsState.chipBg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: const TextStyle(
            color: _ReportsCampaignsState.navy,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          items: values
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(v, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

/// --- Campaign Card ----------------------------------------------------------------
class _CampaignCard extends StatelessWidget {
  final String title;
  final String priceRange;
  final String statusText;
  final double progress;
  final String leftCaption;
  final String rightCaption;

  const _CampaignCard({
    required this.title,
    required this.priceRange,
    required this.statusText,
    required this.progress,
    required this.leftCaption,
    required this.rightCaption,
  });

  Color get _statusBg => const Color(0xFFDDE2E8);
  Color get _statusText => _ReportsCampaignsState.navy;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ReportsCampaignsState.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + status pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _ReportsCampaignsState.navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusBg,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x16000000),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: _statusText,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            priceRange,
            style: const TextStyle(
              color: _ReportsCampaignsState.navy,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 10),

          // Progress + percent
          Row(
            children: [
              Expanded(
                child: _ProgressBar(
                  value: progress,
                  height: 12,
                  bg: _ReportsCampaignsState.progressBg,
                  fg: _ReportsCampaignsState.navy,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$pct%',
                style: const TextStyle(
                  color: _ReportsCampaignsState.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Bottom captions
          Row(
            children: [
              Expanded(
                child: Text(
                  leftCaption,
                  style: const TextStyle(
                    color: _ReportsCampaignsState.txtGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  rightCaption,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: _ReportsCampaignsState.txtGrey,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// --- Progress Bar -----------------------------------------------------------------
class _ProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color bg;
  final Color fg;

  const _ProgressBar({
    required this.value,
    required this.height,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(height),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth * value.clamp(0.0, 1.0);
          return Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: w,
              height: height,
              decoration: BoxDecoration(
                color: fg,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          );
        },
      ),
    );
  }
}
