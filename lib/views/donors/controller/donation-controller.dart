import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pawlytics/views/donors/model/donation-model.dart';

class DonationController {
  // Text Controllers (reused in UI)
  final nameCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final amountCtl = TextEditingController();
  final itemCtl = TextEditingController();
  final qtyCtl = TextEditingController();
  final notesCtl = TextEditingController();

  // Dropdown + Selections
  String donationType = "Cash";
  DateTime? selectedDate;
  String? selectedPaymentMethod;
  String? selectedLocation;

  final paymentOptions = const ['Gcash', 'Maya'];

  // Dispose controllers
  void dispose() {
    nameCtl.dispose();
    phoneCtl.dispose();
    amountCtl.dispose();
    itemCtl.dispose();
    qtyCtl.dispose();
    notesCtl.dispose();
  }

  // Date picker
  Future<void> pickDate(BuildContext context, VoidCallback refresh) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      selectedDate = picked;
      refresh();
    }
  }

  // Date formatting
  String get formattedDate {
    if (selectedDate == null) return 'Select Date';
    return DateFormat.yMMMMd().format(selectedDate!);
  }

  // Build donation object (unified entry point)
  DonationModel buildDonation() {
    final date = selectedDate ?? DateTime.now();

    if (donationType == 'Cash') {
      return DonationModel.cash(
        donorName: nameCtl.text.isEmpty ? "Anonymous" : nameCtl.text,
        donorPhone: phoneCtl.text.isEmpty ? "N/A" : phoneCtl.text,
        donationDate: date,
        amount: double.tryParse(amountCtl.text) ?? 0,
        paymentMethod: selectedPaymentMethod ?? "",
        notes: notesCtl.text.isEmpty ? null : notesCtl.text,
      );
    } else {
      return DonationModel.inKind(
        donorName: nameCtl.text.isEmpty ? "Anonymous" : nameCtl.text,
        donorPhone: phoneCtl.text.isEmpty ? "N/A" : phoneCtl.text,
        donationDate: date,
        item: itemCtl.text,
        quantity: int.tryParse(qtyCtl.text) ?? 0,
        notes: notesCtl.text.isEmpty ? null : notesCtl.text,
      );
    }
  }
}
