import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pawlytics/views/admin/model/donation-model.dart';
import 'package:pawlytics/views/admin/controllers/donation-controller.dart';
// import '../../controllers/donation_controller.dart';
// import '../../models/donation_model.dart';

class ManualDonation extends StatefulWidget {
  const ManualDonation({super.key});

  @override
  State<ManualDonation> createState() => _ManualDonationState();
}

class _ManualDonationState extends State<ManualDonation> {
  late DonationController controller;

  @override
  void initState() {
    super.initState();
    controller = DonationController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _save() {
    FocusScope.of(context).unfocus();
    final donation = controller.buildDonation();
    final issues = donation.validate();

    if (issues.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(issues.join('\n'))));
      return;
    }

    final map = donation.toMap();
    debugPrint('Admin Donation saved: $map');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Donation saved successfully!')),
    );
    Navigator.pop(context, map);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Record Donation",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            tooltip: 'Switch Type',
            icon: Icon(
              controller.donationType == DonationType.cash
                  ? Icons.inventory_2_outlined
                  : Icons.payments_outlined,
            ),
            onPressed: () => setState(controller.toggleType),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Donor Info",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              Icons.person,
              "Enter Name",
              controller.nameCtl,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              Icons.phone,
              "Enter Number",
              controller.phoneCtl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
              ],
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 20),
            const Text(
              "Date of Donation",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => controller.pickDate(context, () => setState(() {})),
              child: _buildDropdownField(
                Icons.calendar_today,
                controller.formattedDate,
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "Donation Type",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<DonationType>(
              value: controller.donationType,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.volunteer_activism,
                  color: Colors.black54,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: const [
                DropdownMenuItem(value: DonationType.cash, child: Text("Cash")),
                DropdownMenuItem(
                  value: DonationType.inKind,
                  child: Text("In Kind"),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  controller.donationType = value;
                  if (value == DonationType.cash) {
                    controller.itemCtl.clear();
                    controller.qtyCtl.clear();
                  } else {
                    controller.amountCtl.clear();
                    controller.selectedPaymentMethod = null;
                  }
                });
              },
            ),

            const SizedBox(height: 20),

            if (controller.donationType == DonationType.cash) ...[
              const Text(
                "Payment Method",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: controller.selectedPaymentMethod,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.credit_card,
                    color: Colors.black54,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: controller.paymentOptions
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => controller.selectedPaymentMethod = value),
                hint: const Text('Select Payment'),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                Icons.attach_money,
                "Enter Amount",
                controller.amountCtl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                Icons.note,
                "Notes (Optional)",
                controller.notesCtl,
              ),
            ] else ...[
              _buildTextField(
                Icons.inventory_2,
                "Item",
                controller.itemCtl,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                Icons.numbers,
                "Quantity",
                controller.qtyCtl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                Icons.note,
                "Notes (Optional)",
                controller.notesCtl,
              ),
            ],

            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2C47),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _save,
              child: const Text(
                "Save",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    IconData icon,
    String hint,
    TextEditingController ctl, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
  }) {
    return TextField(
      controller: ctl,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black54),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildDropdownField(IconData icon, String label) {
    return InputDecorator(
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: Colors.black54),
        ],
      ),
    );
  }
}
