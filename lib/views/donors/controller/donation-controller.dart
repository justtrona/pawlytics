// lib/views/donors/controller/donation_controller.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pawlytics/views/donors/model/donation-model.dart';

class DonationController {
  final nameCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final amountCtl = TextEditingController();
  final itemCtl = TextEditingController();
  final qtyCtl = TextEditingController();
  final notesCtl = TextEditingController();

  DonationType donationType = DonationType.cash;
  DateTime? selectedDate;
  String? selectedPaymentMethod;
  String? selectedLocation;

  /// FK → donations.opex_id
  int? selectedOpexId;

  final paymentOptions = const ['GCash', 'Maya'];

  void dispose() {
    nameCtl.dispose();
    phoneCtl.dispose();
    amountCtl.dispose();
    itemCtl.dispose();
    qtyCtl.dispose();
    notesCtl.dispose();
  }

  void reset() {
    nameCtl.clear();
    phoneCtl.clear();
    amountCtl.clear();
    itemCtl.clear();
    qtyCtl.clear();
    notesCtl.clear();
    donationType = DonationType.cash;
    selectedDate = null;
    selectedPaymentMethod = null;
    selectedLocation = null;
    selectedOpexId = null;
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

  String get formattedDate => selectedDate == null
      ? 'Select Date'
      : DateFormat.yMMMMd().format(selectedDate!);

  void setOpexId(int? id) => selectedOpexId = id;
  void clearOpexId() => selectedOpexId = null;

  DonationModel buildDonation() {
    final date = selectedDate ?? DateTime.now();
    final donorName = nameCtl.text.trim().isEmpty
        ? "Anonymous"
        : nameCtl.text.trim();
    final donorPhone = phoneCtl.text.trim().isEmpty
        ? "N/A"
        : phoneCtl.text.trim();

    if (donationType == DonationType.cash) {
      final amt =
          double.tryParse(amountCtl.text.trim().replaceAll(',', '')) ?? 0;
      return DonationModel.cash(
        donorName: donorName,
        donorPhone: donorPhone,
        donationDate: date,
        amount: amt,
        paymentMethod: (selectedPaymentMethod ?? '').trim().isEmpty
            ? null
            : selectedPaymentMethod!.trim(),
        notes: notesCtl.text.trim().isEmpty ? null : notesCtl.text.trim(),
        opexId: selectedOpexId, // <-- here
      );
    } else {
      final qty = int.tryParse(qtyCtl.text.trim());
      final fairValue = double.tryParse(
        amountCtl.text.trim().replaceAll(',', ''),
      );
      return DonationModel.inKind(
        donorName: donorName,
        donorPhone: donorPhone,
        donationDate: date,
        item: itemCtl.text.trim(),
        quantity: qty,
        fairValueAmount: fairValue,
        dropOffLocation: (selectedLocation ?? '').trim().isEmpty
            ? null
            : selectedLocation!.trim(),
        notes: notesCtl.text.trim().isEmpty ? null : notesCtl.text.trim(),
        opexId: selectedOpexId, // <-- here
      );
    }
  }

  List<String> validateCurrent() => buildDonation().validate();
}
