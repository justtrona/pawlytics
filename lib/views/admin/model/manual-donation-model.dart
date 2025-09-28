import 'package:intl/intl.dart';

enum ManualDonationType { cash, inKind }

class ManualDonation {
  final String donorName;
  final String? donorPhone;
  final ManualDonationType donationType;
  final DateTime donationDate;

  // cash
  final String? paymentMethod;
  final double? amount;

  // in-kind
  final String? item;
  final int? quantity;

  // common
  final String? notes;

  // system
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ManualDonation({
    required this.donorName,
    this.donorPhone,
    required this.donationType,
    required this.donationDate,
    this.paymentMethod,
    this.amount,
    this.item,
    this.quantity,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  /// Validation logic
  List<String> validate() {
    final issues = <String>[];
    if (donorName.isEmpty) issues.add("Donor name is required");
    if (donationType == ManualDonationType.cash) {
      if (paymentMethod == null || paymentMethod!.isEmpty) {
        issues.add("Payment method is required for cash donations");
      }
      if (amount == null || amount! <= 0) {
        issues.add("Amount must be greater than 0 for cash donations");
      }
    }
    if (donationType == ManualDonationType.inKind) {
      if (item == null || item!.isEmpty) {
        issues.add("Item is required for in-kind donations");
      }
      if (quantity == null || quantity! <= 0) {
        issues.add("Quantity must be greater than 0 for in-kind donations");
      }
    }
    return issues;
  }

  /// Convert to Supabase row
  Map<String, dynamic> toMap() {
    return {
      'donor_name': donorName,
      'donor_phone': donorPhone,
      'donation_type': donationType == ManualDonationType.cash
          ? 'cash'
          : 'in_kind',
      'donation_date': DateFormat('yyyy-MM-dd').format(donationDate),
      'payment_method': paymentMethod,
      'amount': amount,
      'item': item,
      'quantity': quantity,
      'notes': notes,
    };
  }

  /// Build from Supabase row
  factory ManualDonation.fromMap(Map<String, dynamic> map) {
    return ManualDonation(
      donorName: map['donor_name'],
      donorPhone: map['donor_phone'],
      donationType: map['donation_type'] == 'cash'
          ? ManualDonationType.cash
          : ManualDonationType.inKind,
      donationDate: DateTime.parse(map['donation_date']),
      paymentMethod: map['payment_method'],
      amount: (map['amount'] as num?)?.toDouble(),
      item: map['item'],
      quantity: map['quantity'],
      notes: map['notes'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }
}
