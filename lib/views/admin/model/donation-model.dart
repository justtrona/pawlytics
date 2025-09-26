// lib/models/donation_model.dart
import 'package:flutter/foundation.dart';

enum DonationType { cash, inKind }

@immutable
class DonationModel {
  final String donorName;
  final String phone;
  final DateTime date;
  final DonationType type;

  // Cash
  final String? paymentMethod;
  final double? amount;

  // In-Kind
  final String? item;
  final int? quantity;

  // Common
  final String? notes;

  const DonationModel({
    required this.donorName,
    required this.phone,
    required this.date,
    required this.type,
    this.paymentMethod,
    this.amount,
    this.item,
    this.quantity,
    this.notes,
  });

  /// Basic validation rules for admin form
  List<String> validate() {
    final issues = <String>[];

    if (donorName.trim().isEmpty) issues.add('Donor name is required.');
    if (phone.trim().isEmpty) issues.add('Phone number is required.');

    // date sanity
    if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      issues.add('Date cannot be in the future.');
    }

    if (type == DonationType.cash) {
      if ((paymentMethod ?? '').isEmpty) {
        issues.add('Payment method is required for Cash donations.');
      }
      if ((amount ?? 0) <= 0) {
        issues.add('Amount must be greater than 0 for Cash donations.');
      }
    } else {
      if ((item ?? '').trim().isEmpty) {
        issues.add('Item is required for In-Kind donations.');
      }
      if ((quantity ?? 0) <= 0) {
        issues.add('Quantity must be greater than 0 for In-Kind donations.');
      }
    }

    return issues;
  }

  Map<String, dynamic> toMap() => {
    'donorName': donorName,
    'phone': phone,
    'date': date.toIso8601String(),
    'type': describeEnum(type),
    'paymentMethod': paymentMethod,
    'amount': amount,
    'item': item,
    'quantity': quantity,
    'notes': notes,
  };

  DonationModel copyWith({
    String? donorName,
    String? phone,
    DateTime? date,
    DonationType? type,
    String? paymentMethod,
    double? amount,
    String? item,
    int? quantity,
    String? notes,
  }) {
    return DonationModel(
      donorName: donorName ?? this.donorName,
      phone: phone ?? this.phone,
      date: date ?? this.date,
      type: type ?? this.type,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amount: amount ?? this.amount,
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }
}
