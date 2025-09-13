import 'package:flutter/material.dart';

class ManualDonationPage extends StatefulWidget {
  const ManualDonationPage({super.key});

  @override
  State<ManualDonationPage> createState() => _ManualDonationPageState();
}

class _ManualDonationPageState extends State<ManualDonationPage> {
  String _donationType = "Cash"; // default selected type

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Manual Donation",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_donationType == "In Kind") {
              // If user is in "In Kind", switch back to Cash instead of popping
              setState(() {
                _donationType = "Cash";
              });
            } else {
              // If already in Cash, go back to previous screen
              Navigator.pop(context);

              // Or if you want to redirect somewhere else later:
              // Navigator.pushReplacement(context, MaterialPageRoute(
              //   builder: (context) => SomeOtherPage(),
              // ));
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Donor Info
            const Text(
              "Donor Info",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildTextField(Icons.person, "Enter Name"),
            const SizedBox(height: 12),
            _buildTextField(
              Icons.phone,
              "Enter Number",
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),

            // Date of Donation
            const Text(
              "Date of Donation",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildDropdownField(Icons.calendar_today, "Select Date"),
            const SizedBox(height: 20),

            // Donation Type
            const Text(
              "Donation Type",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _donationType,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.volunteer_activism,
                  color: Colors.black54,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 10,
                ),
              ),
              items: const [
                DropdownMenuItem(value: "Cash", child: Text("Cash")),
                DropdownMenuItem(value: "In Kind", child: Text("In Kind")),
              ],
              onChanged: (value) {
                setState(() {
                  _donationType = value!;
                });
              },
            ),
            const SizedBox(height: 20),

            // Fields based on Donation Type
            if (_donationType == "Cash") ...[
              const Text(
                "Payment Method",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              _buildDropdownField(Icons.credit_card, "Select Payment"),
              const SizedBox(height: 12),
              _buildTextField(
                Icons.attach_money,
                "Enter Amount",
                keyboardType: TextInputType.number,
              ),
            ] else ...[
              _buildTextField(Icons.inventory_2, "Item"),
              const SizedBox(height: 12),
              _buildTextField(
                Icons.numbers,
                "Quantity",
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              _buildTextField(Icons.note, "Notes (Optional)"),
            ],

            const SizedBox(height: 30),

            // Save button
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2C47),
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // TODO: save logic
                },
                child: const Text(
                  "Save",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable input field
  Widget _buildTextField(
    IconData icon,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black54),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 10,
        ),
      ),
    );
  }

  // Reusable dropdown (static style only)
  Widget _buildDropdownField(IconData icon, String hint) {
    return InputDecorator(
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.black54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 10,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            hint,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const Icon(Icons.arrow_drop_down, color: Colors.black54),
        ],
      ),
    );
  }
}
