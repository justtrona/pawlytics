import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AdminPaymentConfiguration extends StatefulWidget {
  const AdminPaymentConfiguration({super.key});

  @override
  State<AdminPaymentConfiguration> createState() =>
      _AdminPaymentConfigurationState();
}

class _AdminPaymentConfigurationState extends State<AdminPaymentConfiguration> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  // Colors (matching Donors Analytics)
  static const navy = Color(0xFF0F2D50);
  static const subtitle = Color(0xFF6E7B8A);

  // Toggles
  bool gcashEnabled = true;
  // bool mayaEnabled = true;
  bool bankEnabled = true;
  bool usePayMongo = false;

  // GCash
  final gcashNumberCtrl = TextEditingController(text: '09XXXXXXXXX');
  File? gcashQr;

  // // Maya
  // final mayaNumberCtrl = TextEditingController();
  // File? mayaQr;

  // Bank Transfer
  final bankNameCtrl = TextEditingController(text: 'Bank of Flutter');
  final bankAcctNameCtrl = TextEditingController(text: 'PAWLYTICS PH');
  final bankAcctNumberCtrl = TextEditingController(text: '0000-0000-0000');
  File? bankQr;

  // PayMongo (future)
  final paymongoPubKeyCtrl = TextEditingController();
  final paymongoSecretKeyCtrl = TextEditingController();
  final paymongoWebhookSecretCtrl = TextEditingController();

  @override
  void dispose() {
    gcashNumberCtrl.dispose();
    // mayaNumberCtrl.dispose();
    bankNameCtrl.dispose();
    bankAcctNameCtrl.dispose();
    bankAcctNumberCtrl.dispose();
    paymongoPubKeyCtrl.dispose();
    paymongoSecretKeyCtrl.dispose();
    paymongoWebhookSecretCtrl.dispose();
    super.dispose();
  }

  // ---------- helpers ----------
  Future<File?> _pickImage() async {
    try {
      final x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      return x != null ? File(x.path) : null;
    } catch (e) {
      debugPrint("Image pick error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to pick image. Try again.")),
      );
      return null;
    }
  }

  InputDecoration _field(
    String label, {
    String? hint,
    Widget? prefix,
    bool obscure = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  Widget _qrPreview({
    required File? file,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
    String placeholder = 'Upload QR',
  }) {
    final has = file != null;
    return Row(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(14),
          ),
          clipBehavior: Clip.antiAlias,
          child: has
              ? Image.file(file!, fit: BoxFit.cover)
              : Icon(Icons.qr_code_2, size: 42, color: Colors.grey.shade400),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onUpload,
              icon: const Icon(Icons.upload),
              label: Text(has ? 'Change QR' : placeholder),
            ),
            const SizedBox(height: 6),
            if (has)
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
              ),
          ],
        ),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final config = {
      'gcash': {
        'enabled': gcashEnabled,
        'number': gcashNumberCtrl.text.trim(),
        'qrPath': gcashQr?.path,
      },
      // 'maya': {
      //   'enabled': mayaEnabled,
      //   'number': mayaNumberCtrl.text.trim(),
      //   'qrPath': mayaQr?.path,
      // },
      'bank_transfer': {
        'enabled': bankEnabled,
        'bank_name': bankNameCtrl.text.trim(),
        'account_name': bankAcctNameCtrl.text.trim(),
        'account_number': bankAcctNumberCtrl.text.trim(),
        'qrPath': bankQr?.path,
      },
      'paymongo_future': {
        'use_paymongo': usePayMongo,
        'public_key': paymongoPubKeyCtrl.text.trim(),
        'secret_key': paymongoSecretKeyCtrl.text.trim(),
        'webhook_secret': paymongoWebhookSecretCtrl.text.trim(),
      },
    };

    // TODO: persist config to Firestore/DB
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Saved'),
        content: const Text('Payment configuration updated successfully.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: navy)),
          ),
        ],
      ),
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Payment Configuration',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
          children: [
            _paymentSection(
              title: 'GCash',
              subtitle: 'Customers can send via GCash wallet',
              enabled: gcashEnabled,
              onToggle: (v) => setState(() => gcashEnabled = v),
              child: Column(
                children: [
                  TextFormField(
                    controller: gcashNumberCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _field(
                      'GCash Number',
                      hint: '09XXXXXXXXX',
                      prefix: const Icon(Icons.phone_iphone),
                    ),
                    validator: (v) {
                      if (!gcashEnabled) return null;
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length < 10) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _qrPreview(
                    file: gcashQr,
                    onUpload: () async {
                      final f = await _pickImage();
                      if (f != null) setState(() => gcashQr = f);
                    },
                    onRemove: () => setState(() => gcashQr = null),
                    placeholder: 'Upload GCash QR',
                  ),
                ],
              ),
            ),

            // _paymentSection(
            //   title: 'Maya',
            //   subtitle: 'Customers can send via Maya wallet',
            //   enabled: mayaEnabled,
            //   onToggle: (v) => setState(() => mayaEnabled = v),
            //   child: Column(
            //     children: [
            //       TextFormField(
            //         controller: mayaNumberCtrl,
            //         keyboardType: TextInputType.phone,
            //         decoration: _field(
            //           'Maya Number',
            //           hint: '09XXXXXXXXX',
            //           prefix: const Icon(Icons.phone_android),
            //         ),
            //         validator: (v) {
            //           if (!mayaEnabled) return null;
            //           if (v == null || v.trim().isEmpty) return 'Required';
            //           if (v.trim().length < 10) return 'Enter a valid number';
            //           return null;
            //         },
            //       ),
            //       const SizedBox(height: 12),
            //       _qrPreview(
            //         file: mayaQr,
            //         onUpload: () async {
            //           final f = await _pickImage();
            //           if (f != null) setState(() => mayaQr = f);
            //         },
            //         onRemove: () => setState(() => mayaQr = null),
            //         placeholder: 'Upload Maya QR',
            //       ),
            //     ],
            //   ),
            // ),
            _paymentSection(
              title: 'Bank Transfer',
              subtitle: 'Manual transfer to your bank account',
              enabled: bankEnabled,
              onToggle: (v) => setState(() => bankEnabled = v),
              child: Column(
                children: [
                  TextFormField(
                    controller: bankNameCtrl,
                    decoration: _field(
                      'Bank Name',
                      prefix: const Icon(Icons.account_balance),
                    ),
                    validator: (v) {
                      if (!bankEnabled) return null;
                      if (v == null || v.trim().isEmpty) return 'Required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bankAcctNameCtrl,
                    decoration: _field(
                      'Account Name',
                      prefix: const Icon(Icons.badge_outlined),
                    ),
                    validator: (v) {
                      if (!bankEnabled) return null;
                      if (v == null || v.trim().isEmpty) return 'Required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bankAcctNumberCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _field(
                      'Account Number',
                      prefix: const Icon(Icons.numbers),
                    ),
                    validator: (v) {
                      if (!bankEnabled) return null;
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length < 6) {
                        return 'Enter a valid account number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _qrPreview(
                    file: bankQr,
                    onUpload: () async {
                      final f = await _pickImage();
                      if (f != null) setState(() => bankQr = f);
                    },
                    onRemove: () => setState(() => bankQr = null),
                    placeholder: 'Upload Bank QR (optional)',
                  ),
                ],
              ),
            ),

            _paymentSection(
              title: 'PayMongo (future)',
              subtitle: 'Store keys now; enable gateway later',
              enabled: usePayMongo,
              onToggle: (v) => setState(() => usePayMongo = v),
              child: Column(
                children: [
                  TextFormField(
                    controller: paymongoPubKeyCtrl,
                    decoration: _field(
                      'Public Key (pk_live...)',
                      prefix: const Icon(Icons.vpn_key_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: paymongoSecretKeyCtrl,
                    obscureText: true,
                    decoration: _field(
                      'Secret Key (sk_live...)',
                      prefix: const Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: paymongoWebhookSecretCtrl,
                    obscureText: true,
                    decoration: _field(
                      'Webhook Secret',
                      prefix: const Icon(Icons.http_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Note: Gateway integration will be wired next. Keys are stored for later use.',
                      style: TextStyle(fontSize: 12, color: subtitle),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.save),
        label: const Text('Save'),
        backgroundColor: navy,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _paymentSection({
    required String title,
    required String subtitle,
    required bool enabled,
    required Function(bool) onToggle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: enabled, activeColor: navy, onChanged: onToggle),
            ],
          ),
          const SizedBox(height: 12),
          AbsorbPointer(
            absorbing: !enabled,
            child: Opacity(opacity: enabled ? 1 : 0.5, child: child),
          ),
        ],
      ),
    );
  }
}
