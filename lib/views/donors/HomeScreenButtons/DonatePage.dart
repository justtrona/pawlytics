import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawlytics/views/donors/HomeScreenButtons/Transaction Process/DonationSuccessPage.dart';
import 'package:pawlytics/views/donors/HomeScreenButtons/Transaction Process/PayQrCodePage.dart';
import 'package:pawlytics/views/donors/model/donation-model.dart'; // ✅ Donation model

class DonatePage extends StatefulWidget {
  /// REQUIRED: campaign id to attach this donation to
  final int campaignId;

  /// Optional: show campaign title somewhere in this page if you want
  final String? campaignTitle;

  /// Whether to show the In-Kind tab
  final bool allowInKind;

  const DonatePage({
    super.key,
    required this.campaignId,
    this.campaignTitle,
    this.allowInKind = true,
  });

  @override
  State<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _amountController = TextEditingController();
  late TabController _tabController;

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String? selectedItem;
  String? selectedLocation;
  DateTime? selectedDate;

  final List<String> amounts = [
    "5",
    "20",
    "50",
    "100",
    "200",
    "300",
    "400",
    "500",
    "1000",
  ];

  @override
  void initState() {
    super.initState();
    assert(widget.campaignId != 0, 'campaignId must be provided');
    _amountController.text = "0.00";
    _tabController = TabController(
      length: widget.allowInKind ? 2 : 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// ✅ Save donation to Supabase (always injects campaign_id)
  Future<void> _saveDonation(DonationModel donation) async {
    final supabase = Supabase.instance.client;
    try {
      final payload = {
        ...donation.toMap(),
        'campaign_id': widget.campaignId, // 👈 CRITICAL
      };

      await supabase.from('donations').insert(payload);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DonationSuccessPage()),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving donation: $error")));
    }
  }

  void _updateAmount(String value) {
    final current =
        double.tryParse(_amountController.text.replaceAll(",", "")) ?? 0.0;
    final add = double.tryParse(value) ?? 0.0;
    final next = (current + add).clamp(0, 999999999).toDouble();
    setState(() => _amountController.text = next.toStringAsFixed(2));
  }

  void _clearAmount() {
    setState(() => _amountController.text = "0.00");
  }

  void _resetCashFields() {
    setState(() {
      _amountController.text = "0.00";
      _notesController.clear();
    });
  }

  void _resetInKindFields() {
    setState(() {
      selectedItem = null;
      selectedLocation = null;
      selectedDate = null;
      _quantityController.clear();
      _notesController.clear();
    });
  }

  Widget _buildCashTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (widget.campaignTitle != null) ...[
            Text(
              widget.campaignTitle!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Input Amount",
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
                  "₱ ",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: TextField(
                    controller: _amountController,
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
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: amounts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemBuilder: (context, index) {
                final value = amounts[index];
                if (value == "1000") {
                  return ElevatedButton(
                    onPressed: _clearAmount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Clear", style: TextStyle(fontSize: 16)),
                  );
                }
                return ElevatedButton(
                  onPressed: () => _updateAmount(value),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(value, style: const TextStyle(fontSize: 16)),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PayQrCodePage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: const [
                    Icon(Icons.qr_code, size: 36, color: Colors.black87),
                    SizedBox(height: 6),
                    Text(
                      "Scan QR Code",
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
                        double.tryParse(
                          _amountController.text.replaceAll(",", ""),
                        ) ??
                        0.0;

                    final donation = DonationModel.cash(
                      donorName: "Anonymous",
                      donorPhone: "N/A",
                      donationDate: DateTime.now(),
                      amount: amount,
                      paymentMethod: "QR", // or map from your flow
                      notes: _notesController.text.isEmpty
                          ? null
                          : _notesController.text,
                    );

                    final issues = donation.validate();
                    if (amount <= 0) {
                      issues.add("Amount must be greater than 0.");
                    }
                    if (issues.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(issues.join("\n"))),
                      );
                      return;
                    }

                    _saveDonation(
                      donation,
                    ); // ✅ Save to Supabase with campaign_id
                    _resetCashFields();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2C47),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Send Donation",
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

  Widget _buildInKindTab() {
    Future<void> _pickDate(BuildContext context) async {
      final DateTime? date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );
      if (date != null) setState(() => selectedDate = date);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.campaignTitle != null) ...[
              Text(
                widget.campaignTitle!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            const Text("Item", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              hint: const Text("Select Item"),
              value: selectedItem,
              items: ["Dog Food", "Cat Food", "Medicine", "Others"]
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selectedItem = value),
            ),
            const SizedBox(height: 16),
            const Text(
              "Quantity",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Input Quantity",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Drop-Off Location",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              hint: const Text("Select Drop-Off Location"),
              value: selectedLocation,
              items: ["Shelter A", "Shelter B", "Main Office"]
                  .map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
                  .toList(),
              onChanged: (value) => setState(() => selectedLocation = value),
            ),
            const SizedBox(height: 16),
            const Text(
              "Select Date",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async => _pickDate(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  selectedDate == null
                      ? "Select Date"
                      : "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    color: selectedDate == null ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Notes (Optional)",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: "Enter notes",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final quantity = int.tryParse(_quantityController.text) ?? 0;

                  final donation = DonationModel.inKind(
                    donorName: "Anonymous",
                    donorPhone: "N/A",
                    donationDate: selectedDate ?? DateTime.now(),
                    item: selectedItem ?? "",
                    quantity: quantity,
                    notes: _notesController.text.isEmpty
                        ? null
                        : _notesController.text,
                    dropOffLocation: selectedLocation ?? "",
                  );

                  final issues = donation.validate();
                  if ((selectedItem ?? '').isEmpty) {
                    issues.add("Please select an item.");
                  }
                  if (quantity <= 0) {
                    issues.add("Quantity must be greater than 0.");
                  }
                  if ((selectedLocation ?? '').isEmpty) {
                    issues.add("Please select a drop-off location.");
                  }

                  if (issues.isNotEmpty) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(issues.join("\n"))));
                    return;
                  }

                  _saveDonation(
                    donation,
                  ); // ✅ Save to Supabase with campaign_id
                  _resetInKindFields();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2C47),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Confirm",
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
        ? const [Tab(text: "Cash"), Tab(text: "In-Kind")]
        : const [Tab(text: "Cash")];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Donate",
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
          controller: _tabController,
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
        controller: _tabController,
        children: widget.allowInKind
            ? [_buildCashTab(), _buildInKindTab()]
            : [_buildCashTab()],
      ),
    );
  }
}
