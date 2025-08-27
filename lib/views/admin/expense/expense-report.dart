import 'package:flutter/material.dart';

class ExpenseReport extends StatefulWidget {
  const ExpenseReport({super.key});

  @override
  State<ExpenseReport> createState() => _ExpenseReportState();
}

class _ExpenseReportState extends State<ExpenseReport> {
  // ---- Palette (close to your mock) ----
  static const Color navy = Color(0xFF27374D);
  static const Color chipShadow = Color(0x22000000);
  static const Color cardBorder = Color(0xFFB8C2CC);
  static const Color lightGrey = Color(0xFFE7EAEE);

  int _rangeIndex = 1; // 0=Weekly, 1=Monthly, 2=Yearly

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final maxW = w >= 520 ? 520.0 : w;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Shelter Update', // (your mock shows “Shetler”; corrected to "Shelter")
          style: TextStyle(
            color: navy,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Segmented range (Weekly / Monthly / Yearly) ----
                  Row(
                    children: [
                      Expanded(
                        child: _RangeChip(
                          label: 'Weekly',
                          selected: _rangeIndex == 0,
                          onTap: () => setState(() => _rangeIndex = 0),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RangeChip(
                          label: 'Monthly',
                          selected: _rangeIndex == 1,
                          onTap: () => setState(() => _rangeIndex = 1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RangeChip(
                          label: 'Yearly',
                          selected: _rangeIndex == 2,
                          onTap: () => setState(() => _rangeIndex = 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ---- Total Donations card ----
                  Container(
                    decoration: BoxDecoration(
                      color: lightGrey,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: chipShadow,
                          offset: Offset(0, 3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.savings_outlined,
                            size: 28,
                            color: navy,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Total Donations',
                                style: TextStyle(
                                  color: navy,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'PHP 12,000.00',
                                style: TextStyle(
                                  color: navy,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ---- Donation entries ----
                  DonationEntryCard(
                    highlighted: true,
                    petName: 'Peter',
                    fundPurposeLines: const ['Vaccination'],
                    fundType: 'PHP 1,500.00',
                    dateText: 'July 29, 2025',
                    timeText: '9:00 AM',
                  ),
                  const SizedBox(height: 12),
                  DonationEntryCard(
                    highlighted: false,
                    petName: 'Max',
                    fundPurposeLines: const ['1x Deworming Kit'],
                    fundType: 'In-Kind',
                    dateText: 'July 25, 2025',
                    timeText: '8:00 AM',
                  ),
                  const SizedBox(height: 12),
                  DonationEntryCard(
                    highlighted: false,
                    petName: 'Luna',
                    fundPurposeLines: const ['Vaccination', 'Antibiotics'],
                    fundType: '',
                    dateText: 'July 22, 2025',
                    timeText: '3:00 PM',
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

/// Segmented chip button
class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const Color navy = _ExpenseReportState.navy;
  static const Color chipShadow = _ExpenseReportState.chipShadow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? navy : Colors.white,
      elevation: selected ? 0 : 3,
      shadowColor: chipShadow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: selected ? null : Border.all(color: navy, width: 1.2),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : navy,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

/// A single donation entry card
class DonationEntryCard extends StatelessWidget {
  final bool highlighted;
  final String petName;
  final List<String> fundPurposeLines;
  final String fundType; // can be a string amount or "In-Kind"
  final String dateText;
  final String timeText;

  const DonationEntryCard({
    super.key,
    required this.highlighted,
    required this.petName,
    required this.fundPurposeLines,
    required this.fundType,
    required this.dateText,
    required this.timeText,
  });

  static const Color navy = _ExpenseReportState.navy;
  static const Color borderGrey = _ExpenseReportState.cardBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted ? navy : borderGrey,
          width: highlighted ? 2 : 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left labels
          const SizedBox(width: 110, child: _LabelColumn()),
          const SizedBox(width: 8),

          // Middle values
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ValueText(petName),
                const SizedBox(height: 6),
                ...fundPurposeLines.map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _ValueText(l),
                  ),
                ),
                const SizedBox(height: 6),
                if (fundType.isNotEmpty) _ValueText(fundType),
              ],
            ),
          ),

          // Right date/time
          SizedBox(
            width: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dateText,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeText,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Left-side labels (stacked)
class _LabelColumn extends StatelessWidget {
  const _LabelColumn();

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      color: Color(0xFF4C5A69),
      fontWeight: FontWeight.w800,
      fontSize: 13.2,
      height: 1.5,
    );
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pet Name', style: labelStyle),
        Text('Fund Purpose', style: labelStyle),
        Text('Fund Type', style: labelStyle),
      ],
    );
  }
}

/// Middle-column value text
class _ValueText extends StatelessWidget {
  final String text;
  const _ValueText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _ExpenseReportState.navy,
        fontWeight: FontWeight.w700,
        fontSize: 13.2,
        height: 1.25,
      ),
    );
  }
}
