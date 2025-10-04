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
      donorName: nameCtl.text.trim().isEmpty
          ? 'Anonymous'
          : nameCtl.text.trim(),
      donorPhone: phoneCtl.text.trim().isEmpty ? 'N/A' : phoneCtl.text.trim(),
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

  /// Save to Supabase:
  /// 1) Insert into `manual_donations`, get its id.
  /// 2) Insert into `donations` (the table in your screenshot).
  ///    - Tries to include `manual_id` if that column exists; if not, retries without it.
  Future<void> saveDonation() async {
    final donation = buildDonation();
    final issues = donation.validate();
    if (issues.isNotEmpty) {
      throw Exception(issues.join("\n"));
    }

    final supabase = Supabase.instance.client;

    // 1) Insert into manual_donations and fetch id
    final manualRow = donation.toMap()
      ..putIfAbsent('created_at', () => DateTime.now().toIso8601String());

    final insertedManual = await supabase
        .from('manual_donations')
        .insert(manualRow)
        .select('id')
        .single();

    final int manualId = (insertedManual['id'] as num).toInt();

    // 2) Prepare row for donations table (per your schema screenshot)
    final bool isCash = donation.donationType == ManualDonationType.cash;

    String? itemValue;
    if (!isCash) {
      final item = donation.item ?? '';
      final qty = donation.quantity;
      itemValue = qty != null && qty > 0 ? '$item (x$qty)' : item;
      if (itemValue.trim().isEmpty) itemValue = null;
    }

    final donationsRow = <String, dynamic>{
      // optional link; will be removed and retried if column doesn't exist
      'manual_id': manualId,
      'donor_name': donation.donorName.isEmpty
          ? 'Anonymous'
          : donation.donorName,
      'donor_phone':
          (donation.donorPhone == null || donation.donorPhone!.isEmpty)
          ? 'N/A'
          : donation.donorPhone,
      'donation_date': donation.donationDate.toIso8601String(),
      'donation_type': isCash ? 'Cash' : 'In Kind',
      'payment_method': isCash ? donation.paymentMethod : null,
      'amount': isCash ? donation.amount : null,
      'item': isCash ? null : itemValue,
      // If you keep notes in donations too, add the column here:
      // 'notes': donation.notes,
      'created_at': DateTime.now().toIso8601String(),
    };

    try {
      await supabase.from('donations').insert(donationsRow);
    } on PostgrestException catch (e) {
      // If `manual_id` isn't a column in donations, remove and retry
      if (e.code == '42703' /* undefined_column */ ||
          (e.message.toLowerCase().contains('column') &&
              e.message.toLowerCase().contains('manual_id'))) {
        final retry = Map<String, dynamic>.from(donationsRow)
          ..remove('manual_id');
        await supabase.from('donations').insert(retry);
      } else {
        rethrow;
      }
    }
  }
}
