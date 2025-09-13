import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pawlytics/views/donors/model/donation-model.dart';

class DonationController {
  // ----- Text Controllers -----
  final nameCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final amountCtl = TextEditingController();
  final itemCtl = TextEditingController();
  final qtyCtl = TextEditingController();
  final notesCtl = TextEditingController();

  // Dropdown
  String donationType = "Cash"; // "Cash" or "In Kind"
  DateTime? selectedDate;
  String? selectedPaymentMethod;

  final paymentOptions = const [
    // 'Cash on Hand',
    // 'Bank Transfer',
    // 'Card',
    'Gcash',
    'Maya',
    // 'Check',
    // 'Other',
  ];

  // Helpers
  void dispose() {
    nameCtl.dispose();
    phoneCtl.dispose();
    amountCtl.dispose();
    itemCtl.dispose();
    qtyCtl.dispose();
    notesCtl.dispose();
  }

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

  String get formattedDate {
    if (selectedDate == null) return 'Select Date';
    return DateFormat.yMMMMd().format(selectedDate!);
  }

  DonationModel _typeFromUi() =>
      donationType == 'Cash' ? DonationModel.cash : DonationModel.inKind;

  Donation buildDonation() {
    final date = selectedDate ?? DateTime.now();

    return _typeFromUi() == DonationModel.cash
        ? Donation.cash(
            donorName: nameCtl.text,
            donorPhone: phoneCtl.text,
            donationDate: date,
            amount: double.tryParse(amountCtl.text) ?? 0,
            paymentMethod: selectedPaymentMethod,
            notes: notesCtl.text.isEmpty ? null : notesCtl.text,
          )
        : Donation.inKind(
            donorName: nameCtl.text,
            donorPhone: phoneCtl.text,
            donationDate: date,
            item: itemCtl.text,
            quantity: int.tryParse(qtyCtl.text) ?? 0,
            notes: notesCtl.text.isEmpty ? null : notesCtl.text,
          );
  }
}
