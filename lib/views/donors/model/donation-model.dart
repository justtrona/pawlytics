// lib/models/donation.dart
import 'package:flutter/foundation.dart';

enum DonationModel { cash, inKind }

@immutable
class Donation {
  // Common
  final String donorName;
  final String
  donorPhone; // Keep as String to preserve formatting/leading zeros
  final DateTime donationDate;
  final DonationModel type;

  // Cash
  final String? paymentMethod; // e.g. "Bank Transfer", "Card", "Gcash", etc.
  final double? amount;

  // In-Kind
  final String? item;
  final int? quantity;
  final String? notes;

  const Donation({
    required this.donorName,
    required this.donorPhone,
    required this.donationDate,
    required this.type,
    this.paymentMethod,
    this.amount,
    this.item,
    this.quantity,
    this.notes,
  });

  /// Convenience constructors
  factory Donation.cash({
    required String donorName,
    required String donorPhone,
    required DateTime donationDate,
    required double amount,
    String? paymentMethod,
    String? notes,
  }) {
    return Donation(
      donorName: donorName,
      donorPhone: donorPhone,
      donationDate: donationDate,
      type: DonationModel.cash,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes,
    );
  }

  factory Donation.inKind({
    required String donorName,
    required String donorPhone,
    required DateTime donationDate,
    required String item,
    required int quantity,
    String? notes,
  }) {
    return Donation(
      donorName: donorName,
      donorPhone: donorPhone,
      donationDate: donationDate,
      type: DonationModel.inKind,
      item: item,
      quantity: quantity,
      notes: notes,
    );
  }

  /// Minimal sanity checks (optional to call before save)
  List<String> validate() {
    final issues = <String>[];
    if (donorName.trim().isEmpty) issues.add('Donor name is required.');
    if (donorPhone.trim().isEmpty) issues.add('Donor number is required.');

    if (type == DonationModel.cash) {
      if (amount == null || amount! <= 0) issues.add('Amount must be > 0.');
    } else {
      if (item == null || item!.trim().isEmpty) issues.add('Item is required.');
      if (quantity == null || quantity! <= 0) {
        issues.add('Quantity must be a positive integer.');
      }
    }
    return issues;
  }

  bool get isCash => type == DonationModel.cash;
  bool get isInKind => type == DonationModel.inKind;

  Donation copyWith({
    String? donorName,
    String? donorPhone,
    DateTime? donationDate,
    DonationModel? type,
    String? paymentMethod,
    double? amount,
    String? item,
    int? quantity,
    String? notes,
    // helpers when switching type:
    bool clearCashFields = false,
    bool clearInKindFields = false,
  }) {
    return Donation(
      donorName: donorName ?? this.donorName,
      donorPhone: donorPhone ?? this.donorPhone,
      donationDate: donationDate ?? this.donationDate,
      type: type ?? this.type,
      paymentMethod: clearCashFields
          ? null
          : (paymentMethod ?? this.paymentMethod),
      amount: clearCashFields ? null : (amount ?? this.amount),
      item: clearInKindFields ? null : (item ?? this.item),
      quantity: clearInKindFields ? null : (quantity ?? this.quantity),
      notes: notes ?? this.notes,
    );
  }

  /// Map serializers (no JSON). Date is ISO8601 string for API-friendliness.
  Map<String, dynamic> toMap() {
    return {
      'donorName': donorName,
      'donorPhone': donorPhone,
      'donationDate': donationDate.toIso8601String(),
      'type': _typeToString(type),
      'paymentMethod': paymentMethod,
      'amount': amount,
      'item': item,
      'quantity': quantity,
      'notes': notes,
    };
  }

  factory Donation.fromMap(Map<String, dynamic> map) {
    final typeStr = (map['type'] as String?) ?? 'Cash';
    final dateStr = (map['donationDate'] as String?) ?? '';
    return Donation(
      donorName: (map['donorName'] as String? ?? '').trim(),
      donorPhone: (map['donorPhone'] as String? ?? '').trim(),
      donationDate: DateTime.tryParse(dateStr) ?? DateTime.now(),
      type: _typeFromString(typeStr),
      paymentMethod: map['paymentMethod'] as String?,
      amount: _toDoubleOrNull(map['amount']),
      item: map['item'] as String?,
      quantity: _toIntOrNull(map['quantity']),
      notes: map['notes'] as String?,
    );
  }

  static String _typeToString(DonationModel t) =>
      t == DonationModel.cash ? 'Cash' : 'In Kind';

  static DonationModel _typeFromString(String s) {
    final n = s.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    return n == 'inkind' ? DonationModel.inKind : DonationModel.cash;
  }

  static double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  @override
  String toString() =>
      'Donation(${_typeToString(type)}, donor: $donorName, phone: $donorPhone)';
}
