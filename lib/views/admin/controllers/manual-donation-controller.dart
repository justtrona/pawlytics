import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../model/manual-donation-model.dart';

class ManualDonationController {
  final nameCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final amountCtl = TextEditingController();
  final itemCtl = TextEditingController();
  final qtyCtl = TextEditingController();
  final notesCtl = TextEditingController();

  ManualDonationType donationType = ManualDonationType.cash;
  String? selectedPaymentMethod;
  DateTime donationDate = DateTime.now();

  final List<String> paymentOptions = ["Cash", "GCash", "Bank Transfer"];

  void dispose() {
    nameCtl.dispose();
    phoneCtl.dispose();
    amountCtl.dispose();
    itemCtl.dispose();
    qtyCtl.dispose();
    notesCtl.dispose();
  }

  String get formattedDate => DateFormat("MMM dd, yyyy").format(donationDate);

  void pickDate(BuildContext context, VoidCallback onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: donationDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      donationDate = picked;
      onPicked();
    }
  }

  void toggleType() {
    donationType = donationType == ManualDonationType.cash
        ? ManualDonationType.inKind
        : ManualDonationType.cash;
  }

  ManualDonation buildDonation() {
    return ManualDonation(
      donorName: nameCtl.text.trim(),
      donorPhone: phoneCtl.text.trim().isEmpty ? null : phoneCtl.text.trim(),
      donationType: donationType,
      donationDate: donationDate,
      paymentMethod: donationType == ManualDonationType.cash
          ? selectedPaymentMethod
          : null,
      amount: donationType == ManualDonationType.cash
          ? double.tryParse(amountCtl.text.trim())
          : null,
      item: donationType == ManualDonationType.inKind
          ? itemCtl.text.trim()
          : null,
      quantity: donationType == ManualDonationType.inKind
          ? int.tryParse(qtyCtl.text.trim())
          : null,
      notes: notesCtl.text.trim().isEmpty ? null : notesCtl.text.trim(),
    );
  }

  /// Save to Supabase
  Future<void> saveDonation() async {
    final donation = buildDonation();
    final issues = donation.validate();
    if (issues.isNotEmpty) {
      throw Exception(issues.join("\n"));
    }

    final supabase = Supabase.instance.client;
    await supabase.from('manual_donations').insert(donation.toMap());
  }
}
