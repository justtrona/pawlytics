class DonationModel {
  final String donorName;
  final String donorPhone;
  final DateTime donationDate;
  final double? amount;
  final String? paymentMethod;
  final String? notes;
  final String? item;
  final int? quantity;
  final String? dropOffLocation;
  final String donationType; // "Cash" or "InKind"

  DonationModel.cash({
    required this.donorName,
    required this.donorPhone,
    required this.donationDate,
    required this.amount,
    required this.paymentMethod,
    this.notes,
  }) : item = null,
       quantity = null,
       dropOffLocation = null,
       donationType = "Cash";

  DonationModel.inKind({
    required this.donorName,
    required this.donorPhone,
    required this.donationDate,
    required this.item,
    required this.quantity,
    this.notes,
    this.dropOffLocation,
  }) : amount = null,
       paymentMethod = null,
       donationType = "InKind";

  Map<String, dynamic> toMap() {
    return {
      'donor_name': donorName,
      'donor_phone': donorPhone,
      'donation_date': donationDate.toIso8601String(),
      'amount': amount,
      'payment_method': paymentMethod,
      'notes': notes,
      'item': item,
      'quantity': quantity,
      'drop_off_location': dropOffLocation,
      'donation_type': donationType,
    };
  }

  // validations
  List<String> validate() {
    final issues = <String>[];
    if (donorName.isEmpty) issues.add("Donor name is required.");
    if (donationType == "Cash" && (amount == null || amount! <= 0)) {
      issues.add("Cash amount must be greater than zero.");
    }
    if (donationType == "InKind" && (item == null || item!.isEmpty)) {
      issues.add("In-kind donation item is required.");
    }
    return issues;
  }
}
