import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pawlytics/views/admin/model/donation-model.dart';

class DonationController {
  final nameCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final amountCtl = TextEditingController();
  final itemCtl = TextEditingController();
  final qtyCtl = TextEditingController();
  final notesCtl = TextEditingController();

  DateTime selectedDate = DateTime.now();
  DonationType donationType = DonationType.cash;
  String? selectedPaymentMethod;

  final List<String> paymentOptions = const [
    'Cash',
    // 'Bank Transfer',
    'GCash',
    // 'PayMaya',
    // 'Credit/Debit Card',
    // 'Other',
  ];

  String get formattedDate => DateFormat('MMM d, yyyy').format(selectedDate);

  Future<void> pickDate(BuildContext context, VoidCallback onPicked) async {
    final now = DateTime.now();
    final res = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (res != null) {
      selectedDate = res;
      onPicked();
    }
  }

  DonationModel buildDonation() {
    final amount = double.tryParse(amountCtl.text.replaceAll(',', ''));
    final qty = int.tryParse(qtyCtl.text);

    return DonationModel(
      donorName: nameCtl.text,
      phone: phoneCtl.text,
      date: selectedDate,
      type: donationType,
      paymentMethod: donationType == DonationType.cash
          ? selectedPaymentMethod
          : null,
      amount: donationType == DonationType.cash ? amount : null,
      item: donationType == DonationType.inKind ? itemCtl.text : null,
      quantity: donationType == DonationType.inKind ? qty : null,
      notes: notesCtl.text.isNotEmpty ? notesCtl.text : null,
    );
  }

  void toggleType() {
    donationType = donationType == DonationType.cash
        ? DonationType.inKind
        : DonationType.cash;
    if (donationType == DonationType.cash) {
      itemCtl.clear();
      qtyCtl.clear();
    } else {
      amountCtl.clear();
      selectedPaymentMethod = null;
    }
  }

  void dispose() {
    nameCtl.dispose();
    phoneCtl.dispose();
    amountCtl.dispose();
    itemCtl.dispose();
    qtyCtl.dispose();
    notesCtl.dispose();
  }
}
