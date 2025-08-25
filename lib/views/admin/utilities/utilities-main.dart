import 'package:flutter/material.dart';

class UtilitiesMain extends StatefulWidget {
  const UtilitiesMain({super.key});

  @override
  State<UtilitiesMain> createState() => _UtilitiesMainState();
}

class _UtilitiesMainState extends State<UtilitiesMain> {
  // Theme
  static const brand = Color(0xFF27374D);
  static const softGrey = Color(0xFFE9EEF3);
  static const textMuted = Color(0xFF6A7886);

  final _search = TextEditingController();

  final List<_Utility> _all = const [
    _Utility(
      name: 'Water',
      statusLeft: 'Paid',
      amount: 'PHP 1,500.00',
      rightNote: 'Due July 13',
      icon: Icons.water_drop_outlined,
    ),
    _Utility(
      name: 'Electricity',
      statusLeft: 'Due',
      amount: 'PHP 3,500.00',
      rightNote: 'Due July 18',
      icon: Icons.bolt_outlined,
    ),
    _Utility(
      name: 'Waste Collection',
      statusLeft: 'Paid',
      amount: 'PHP 400.00',
      rightNote: 'Paid',
      icon: Icons
          .recycling, // use Icons.delete_outline if recycling isn't available
    ),
    _Utility(
      name: 'Drinking Water',
      statusLeft: 'Stocked',
      amount: 'PHP 500.00',
      rightNote: '3–5 days remaining',
      icon: Icons.local_drink_outlined,
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_Utility> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((u) => u.name.toLowerCase().contains(q)).toList();
  }

  OutlineInputBorder _border([Color? c]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c ?? Colors.transparent, width: 0),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Utilities'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search Utility',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: softGrey,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  enabledBorder: _border(),
                  focusedBorder: _border(),
                ),
              ),
            ),

            // List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final u = _filtered[i];
                  return _UtilityTile(
                    data: u,
                    onTap: () {
                      // TODO: open details
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Open ${u.name}')));
                    },
                  );
                },
              ),
            ),

            // Manage button pinned at bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text('MANAGE'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Utility {
  final String name;
  final String statusLeft;
  final String amount;
  final String rightNote;
  final IconData icon;
  const _Utility({
    required this.name,
    required this.statusLeft,
    required this.amount,
    required this.rightNote,
    required this.icon,
  });
}

class _UtilityTile extends StatelessWidget {
  static const brand = Color(0xFF27374D);
  static const softGrey = Color(0xFFE9EEF3);
  static final borderColor = Colors.blueGrey.shade100;
  static const textMuted = Color(0xFF6A7886);

  final _Utility data;
  final VoidCallback? onTap;

  const _UtilityTile({required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // Icon bubble
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: softGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: brand, size: 22),
              ),
              const SizedBox(width: 12),

              // Title + left status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: brand,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.statusLeft,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Right amount + note
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data.amount,
                    style: const TextStyle(
                      color: brand,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.rightNote,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
