import 'package:flutter/material.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String selectedMethod = "GCash"; // default
  final List<String> methods = ["GCash", "PayMaya", "Bank Transfer"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Payment Method",
          style: TextStyle(color: Color(0xFF1F2C47)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            // Description (justified like in screenshot)
            const Text(
              "Select your preferred payout method from the available options. "
              "This will be used for future donation disbursements.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF1F2C47),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 40),

            // Dropdown with fixed width like screenshot
            SizedBox(
              width: double.infinity, // makes it like a textfield width
              child: DropdownButtonFormField<String>(
                value: selectedMethod,
                items: methods
                    .map(
                      (method) => DropdownMenuItem(
                        value: method,
                        child: Text(
                          method,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMethod = value!;
                  });
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
              ),
            ),

            const Spacer(),

            // Save button (responsive, no function yet)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // no function yet
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1F2C47),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
