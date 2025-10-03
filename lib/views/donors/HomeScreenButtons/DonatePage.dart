// lib/views/donors/HomeScreenButtons/Transaction Process/DonatePage.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/donors/HomeScreenButtons/Transaction Process/DonationSuccessPage.dart';
import 'package:pawlytics/views/donors/HomeScreenButtons/Transaction Process/PayQrCodePage.dart';
import 'package:pawlytics/views/donors/model/donation-model.dart';

class DonatePage extends StatefulWidget {
  final String? petId;
  final int? campaignId;
  final int? opexId; // still the incoming prop
  final bool autoAssignOpex;
  final String? campaignTitle;
  final bool allowInKind;

  const DonatePage({
    super.key,
    this.petId,
    this.campaignId,
    this.opexId,
    this.campaignTitle,
    this.allowInKind = true,
    this.autoAssignOpex = false,
  }) : assert(
         petId != null ||
             campaignId != null ||
             opexId != null ||
             autoAssignOpex == true,
         'Provide petId, campaignId, opexId, or set autoAssignOpex to true.',
       );

  @override
  State<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage>
    with SingleTickerProviderStateMixin {
  final _sb = Supabase.instance.client;
  final TextEditingController _amount = TextEditingController(text: '0.00');
  final TextEditingController _quantity = TextEditingController();
  final TextEditingController _notes = TextEditingController();

  String? _item;
  String? _dropOff;
  DateTime? _date;

  late TabController _tabs;

  final quick = const [
    '5',
    '20',
    '50',
    '100',
    '200',
    '300',
    '400',
    '500',
    '1000',
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: widget.allowInKind ? 2 : 1, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _amount.dispose();
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Ensure we write to the right target columns.
  Map<String, dynamic> _payloadForTarget(Map<String, dynamic> base) {
    final m = Map<String, dynamic>.from(base)
      ..remove('opex_allocation_id')
      ..remove('opex_id')
      ..remove('allocation_id')
      ..remove('pet_id')
      ..remove('campaign_id')
      ..remove('is_operational');

    if ((widget.petId ?? '').isNotEmpty) {
      m['pet_id'] = widget.petId;
      m['campaign_id'] = null;
      m['allocation_id'] = null;
      m['is_operational'] = false;
    } else if (widget.campaignId != null) {
      m['pet_id'] = null;
      m['campaign_id'] = widget.campaignId;
      m['allocation_id'] = null;
      m['is_operational'] = false;
    } else if (widget.opexId != null) {
      m['pet_id'] = null;
      m['campaign_id'] = null;
      m['allocation_id'] = widget.opexId; // <— IMPORTANT
      m['is_operational'] = true;
    } else {
      // fallback: untargeted donation
      m['pet_id'] = null;
      m['campaign_id'] = null;
      m['allocation_id'] = null;
      m['is_operational'] = false;
    }
    return m;
  }

  Future<void> _saveDonation(DonationModel donation) async {
    try {
      final base = donation.toInsertMap();
      final payload = _payloadForTarget(base);

      // Debug: verify allocation_id is present for operational donations
      // Example print: { ..., allocation_id: 1 }
      // ignore: avoid_print
      print('Saving donation with payload: $payload');

      // IMPORTANT: call .select() if you want returned rows
      final response = await _sb.from('donations').insert(payload).select();

      // Supabase v2 throws on error; explicit check for completeness:
      if (response.isEmpty) {
        throw PostgrestException(message: 'Insert returned no rows');
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DonationSuccessPage()),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('DB error: ${e.code ?? ''} ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving donation: $e')));
    }
  }

  void _addQuick(String v) {
    final cur = double.tryParse(_amount.text.replaceAll(',', '')) ?? 0.0;
    final add = double.tryParse(v) ?? 0.0;
    final next = (cur + add).clamp(0, 999999999).toDouble();
    setState(() => _amount.text = next.toStringAsFixed(2));
  }

  /* -------------------- Cash tab -------------------- */

  Widget _buildCashTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.campaignTitle != null) ...[
            Text(
              widget.campaignTitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
          ],
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Input Amount',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Text(
                  '₱ ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: TextField(
                    controller: _amount,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quick.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemBuilder: (_, i) {
                final v = quick[i];
                if (v == '1000') {
                  return OutlinedButton(
                    onPressed: () => setState(() => _amount.text = '0.00'),
                    child: const Text('Clear'),
                  );
                }
                return OutlinedButton(
                  onPressed: () => _addQuick(v),
                  child: Text(v),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PayQrCodePage()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: const [
                    Icon(Icons.qr_code, size: 36, color: Colors.black87),
                    SizedBox(height: 6),
                    Text(
                      'Scan QR Code',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    final amount =
                        double.tryParse(_amount.text.replaceAll(',', '')) ??
                        0.0;

                    final donation = DonationModel.cash(
                      donorName: 'Anonymous',
                      donorPhone: 'N/A',
                      donationDate: DateTime.now(),
                      amount: amount,
                      paymentMethod: 'QR',
                      notes: _notes.text.isEmpty ? null : _notes.text,
                      // If you also pass a target at the page level, wire it into the controller/model.
                      opexId: widget.opexId,
                    );

                    final issues = donation.validate();
                    if (amount <= 0)
                      issues.add('Amount must be greater than 0.');
                    if (issues.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(issues.join('\n'))),
                      );
                      return;
                    }

                    _saveDonation(donation);
                    setState(() => _amount.text = '0.00');
                    _notes.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2C47),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Send Donation',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* -------------------- In-Kind tab -------------------- */

  Widget _buildInKindTab() {
    Future<void> pickDate() async {
      final d = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );
      if (d != null) setState(() => _date = d);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.campaignTitle != null) ...[
              Text(
                widget.campaignTitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
            ],
            const Text('Item'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              items: const [
                'Dog Food',
                'Cat Food',
                'Medicine',
                'Others',
              ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
              onChanged: (v) => setState(() => _item = v),
            ),
            const SizedBox(height: 12),
            const Text('Quantity'),
            const SizedBox(height: 6),
            TextField(
              controller: _quantity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Input Quantity',
              ),
            ),
            const SizedBox(height: 12),
            const Text('Drop-Off Location'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              items: const [
                'Shelter A',
                'Shelter B',
                'Main Office',
              ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
              onChanged: (v) => setState(() => _dropOff = v),
            ),
            const SizedBox(height: 12),
            const Text('Date'),
            const SizedBox(height: 6),
            InkWell(
              onTap: pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Text(
                  _date == null
                      ? 'Select Date'
                      : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Notes (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter notes',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();

                  final qty = int.tryParse(_quantity.text) ?? 0;
                  final issues = <String>[];
                  if ((_item ?? '').isEmpty)
                    issues.add('Please select an item.');
                  if (qty <= 0) issues.add('Quantity must be greater than 0.');
                  if ((_dropOff ?? '').isEmpty)
                    issues.add('Please select a drop-off location.');
                  if (issues.isNotEmpty) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(issues.join('\n'))));
                    return;
                  }

                  final donation = DonationModel.inKind(
                    donorName: 'Anonymous',
                    donorPhone: 'N/A',
                    donationDate: _date ?? DateTime.now(),
                    item: _item ?? '',
                    quantity: qty,
                    fairValueAmount: null, // set if you compute fair value
                    dropOffLocation: _dropOff ?? '',
                    notes: _notes.text.isEmpty ? null : _notes.text,
                    opexId: widget.opexId,
                  );

                  _saveDonation(donation);
                  setState(() {
                    _item = null;
                    _dropOff = null;
                    _date = null;
                  });
                  _quantity.clear();
                  _notes.clear();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2C47),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Confirm',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = widget.allowInKind
        ? const [Tab(text: 'Cash'), Tab(text: 'In-Kind')]
        : const [Tab(text: 'Cash')];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Donate',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFF1F2C47),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1F2C47),
          labelStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          tabs: tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: widget.allowInKind
            ? [_buildCashTab(), _buildInKindTab()]
            : [_buildCashTab()],
      ),
    );
  }
}
