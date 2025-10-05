// lib/views/donors/controller/donation_controller.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pawlytics/views/donors/model/donation-model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DonationController {
  final supabase = Supabase.instance.client;

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
        opexId: selectedOpexId,
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
        opexId: selectedOpexId,
      );
    }
  }

  /// ✅ Save donation with user info from registration
  Future<bool> saveDonation() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ No logged-in user.');
        return false;
      }

      debugPrint('🧠 Current user: ${user.email} (${user.id})');

      // ✅ Correct join to registration using auth_user_id
      final profile = await supabase
          .from('registration')
          .select('"fullName", phone_number')
          .eq('id', user.id)
          .maybeSingle();

      debugPrint('📦 Registration result: $profile');

      // Use values from registration or fallback
      final donorName = profile?['fullName'] ?? 'Anonymous';
      final donorPhone = profile?['phone_number'] ?? 'N/A';

      debugPrint('✅ Using donor info: $donorName | $donorPhone');

      final donation = buildDonation();

      // ✅ Let the trigger handle donor_name and donor_phone if missing
      final data = {
        'user_id': user.id, // ✅ Correct foreign key reference
        'donor_name': donorName, // ✅ Add this
        'donor_phone': donorPhone, // ✅ Add this
        'donation_type': donation.donationType.name,
        'donation_date': donation.donationDate.toIso8601String(),
        'amount': donation.amount,
        'quantity': donation.quantity,
        'payment_method': donation.paymentMethod,
        'drop_off_location': donation.dropOffLocation,
        'notes': donation.notes,
        'opex_id': donation.opexId,
        'is_operation_expense': donation.opexId != null,
      };

      debugPrint('📤 Saving donation with payload: $data');

      final response = await supabase.from('donations').insert(data).select();

      debugPrint('✅ Donation inserted: $response');
      return true;
    } catch (e, st) {
      debugPrint('❌ Error saving donation: $e');
      debugPrint(st.toString());
      return false;
    }
  }
}
