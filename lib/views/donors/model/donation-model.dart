// lib/views/donors/model/donation-model.dart
enum DonationType { cash, inKind }

extension DonationTypeDb on DonationType {
  String get db => this == DonationType.cash ? 'Cash' : 'InKind';

  static DonationType fromDb(String v) {
    switch (v.toLowerCase()) {
      case 'cash':
        return DonationType.cash;
      case 'inkind':
        return DonationType.inKind;
      default:
        throw ArgumentError('Invalid DonationType: $v');
    }
  }
}

class DonationModel {
  final String donorName;
  final String donorPhone;
  final DateTime donationDate;

  final double? amount; // cash or in-kind fair value
  final String? paymentMethod; // cash-only
  final String? item; // in-kind-only
  final int? quantity; // in-kind-only
  final String? dropOffLocation;
  final String? notes;

  final DonationType donationType;

  /// Keep the field name for minimal refactor, but this now maps to DB column:
  /// public.donations.allocation_id
  final int? opexId;

  DonationModel._({
    required this.donorName,
    required this.donorPhone,
    required this.donationDate,
    required this.donationType,
    this.amount,
    this.paymentMethod,
    this.item,
    this.quantity,
    this.dropOffLocation,
    this.notes,
    this.opexId,
  });

  // Cash donation
  factory DonationModel.cash({
    required String donorName,
    required String donorPhone,
    required DateTime donationDate,
    required double amount,
    String? paymentMethod,
    String? notes,
    int? opexId,
  }) {
    return DonationModel._(
      donorName: donorName,
      donorPhone: donorPhone,
      donationDate: donationDate,
      donationType: DonationType.cash,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes,
      opexId: opexId,
    );
  }

  // In-kind donation
  factory DonationModel.inKind({
    required String donorName,
    required String donorPhone,
    required DateTime donationDate,
    required String item,
    int? quantity,
    double? fairValueAmount,
    String? dropOffLocation,
    String? notes,
    int? opexId,
  }) {
    return DonationModel._(
      donorName: donorName,
      donorPhone: donorPhone,
      donationDate: donationDate,
      donationType: DonationType.inKind,
      item: item,
      quantity: quantity,
      amount: fairValueAmount,
      dropOffLocation: dropOffLocation,
      notes: notes,
      opexId: opexId,
    );
  }

  Map<String, dynamic> toMap() => {
    'donor_name': donorName,
    'donor_phone': donorPhone,
    'donation_date': donationDate.toIso8601String(),
    'donation_type': donationType.db,
    'amount': amount,
    'payment_method': paymentMethod,
    'item': item,
    'quantity': quantity,
    'drop_off_location': dropOffLocation,
    'notes': notes,
    // IMPORTANT: write to the new column name
    'allocation_id': opexId,
  };

  Map<String, dynamic> toInsertMap({bool stripNulls = true}) {
    final m = toMap();
    if (stripNulls) m.removeWhere((_, v) => v == null);
    return m;
  }

  List<String> validate() {
    final errs = <String>[];
    if (donationType == DonationType.cash) {
      if (amount == null || amount! <= 0) {
        errs.add('Cash amount must be greater than zero.');
      }
    } else if (donationType == DonationType.inKind) {
      if (item == null || item!.trim().isEmpty) {
        errs.add('In-kind item is required.');
      }
      if (quantity != null && quantity! < 0) {
        errs.add('Quantity cannot be negative.');
      }
      if (amount == null || amount! <= 0) {
        errs.add('In-kind donation must have a valid fair value.');
      }
    }
    return errs;
  }
}
