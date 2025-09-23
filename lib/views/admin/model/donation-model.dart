class DonationModel {
  final String? donorName;
  final double amount;
  final DateTime date;

  DonationModel({
    this.donorName,
    required this.amount,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  
}