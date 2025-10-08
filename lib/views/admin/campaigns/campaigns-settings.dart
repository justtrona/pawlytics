import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CampaignSettingsScreen extends StatefulWidget {
  const CampaignSettingsScreen({super.key});

  @override
  State<CampaignSettingsScreen> createState() => _CampaignSettingsScreenState();
}

class _CampaignSettingsScreenState extends State<CampaignSettingsScreen> {
  static const brand = Color(0xFF27374D);

  static const double kSectionGap = 20;
  static const double kFieldGap = 12;
  static const double kControlHeight = 48;
  static const EdgeInsets kScreenPadding = EdgeInsets.fromLTRB(16, 12, 16, 24);

  // Program
  String _program = 'Shelters Improvement';
  bool _useCustomProgram = false; // toggle to use custom name
  final _programCtrl = TextEditingController(); // custom program input

  String _category = 'Urgent';
  String _currency = 'PHP';
  bool _notifyAt75 = true;

  // editable status (Active/Inactive). "Due" is computed from deadline.
  String _status = 'Active'; // Active | Inactive

  final _goalCtrl = TextEditingController(text: '12,500.00');
  final _deadlineCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  DateTime? _deadline;

  @override
  void dispose() {
    _goalCtrl.dispose();
    _deadlineCtrl.dispose();
    _descCtrl.dispose();
    _programCtrl.dispose();
    super.dispose();
  }

  OutlineInputBorder _border([Color? c]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c ?? Colors.blueGrey.shade200, width: 1),
  );

  InputDecoration _dec({
    String? label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Widget? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      prefix: prefix,
      filled: true,
      fillColor: Colors.blueGrey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: _border(),
      focusedBorder: _border(Colors.blueGrey.shade400),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    ),
  );

  ButtonStyle get _primaryBtn => ElevatedButton.styleFrom(
    backgroundColor: brand,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    minimumSize: const Size(120, kControlHeight),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      initialDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: brand)),
        child: child!,
      ),
    );
    if (picked != null) {
      _deadline = picked;
      _deadlineCtrl.text = DateFormat('MM/dd/yyyy').format(picked);
      setState(() {});
    }
  }

  SizedBox get _vGap => const SizedBox(height: kSectionGap);
  SizedBox get _hGap => const SizedBox(width: kFieldGap);

  String get _computedStatus {
    if (_deadline != null && _deadline!.isBefore(DateTime.now())) return 'Due';
    return _status; // Active/Inactive from dropdown
  }

  Future<void> _postCampaign() async {
    // Resolve chosen program (custom or preset)
    final String resolvedProgram = _useCustomProgram
        ? _programCtrl.text.trim()
        : _program;

    // basic validations
    if (resolvedProgram.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a program name.')),
      );
      return;
    }

    final goal = double.tryParse(_goalCtrl.text.replaceAll(',', '')) ?? 0;
    if (goal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a valid fundraising goal.')),
      );
      return;
    }
    if (_deadline == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please pick a deadline.')));
      return;
    }

    try {
      final isActive = (_status == 'Active'); // what we persist
      final response = await Supabase.instance.client.from('campaigns').insert({
        'program': resolvedProgram, // saves either custom or preset
        'category': _category,
        'fundraising_goal': goal,
        'deadline': _deadline!.toIso8601String(),
        'currency': _currency,
        'description': _descCtrl.text,
        'notify_at_75': _notifyAt75,
        'is_active': isActive,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Campaign posted successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post campaign.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error posting campaign: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStatus = _computedStatus; // Active / Inactive / Due

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Campaign'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: ListView(
          padding: kScreenPadding,
          children: [
            // -------- Program (input first, toggle below) --------
            _sectionLabel('Program'),
            // Control (TextField if custom, otherwise Dropdown)
            if (_useCustomProgram)
              TextField(
                controller: _programCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: _dec(
                  hint: 'Type program name (e.g., Community Vet Care)',
                  prefixIcon: const Icon(Icons.edit_outlined),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _program,
                borderRadius: BorderRadius.circular(12),
                decoration: _dec(),
                items: const [
                  DropdownMenuItem(
                    value: 'Shelters Improvement',
                    child: Text('Shelters Improvement'),
                  ),
                  DropdownMenuItem(value: 'Surgery', child: Text('Surgery')),
                  DropdownMenuItem(
                    value: 'Dog Pound',
                    child: Text('Dog Pound'),
                  ),
                  DropdownMenuItem(value: 'Rescue', child: Text('Rescue')),
                  DropdownMenuItem(
                    value: 'Stray Animals',
                    child: Text('Stray Animals'),
                  ),
                  DropdownMenuItem(
                    value: 'Vaccination',
                    child: Text('Vaccination'),
                  ),
                  DropdownMenuItem(
                    value: 'Spay/Neuter',
                    child: Text('Spay/Neuter'),
                  ),
                  DropdownMenuItem(value: 'Pet Food', child: Text('Pet Food')),
                  DropdownMenuItem(
                    value: 'Medical Supplies',
                    child: Text('Medical Supplies'),
                  ),
                  DropdownMenuItem(
                    value: 'Outreach and Awareness',
                    child: Text('Outreach and Awareness'),
                  ),
                ],
                onChanged: (v) => setState(() => _program = v!),
              ),
            const SizedBox(height: 8),
            // Toggle BELOW the input
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Use custom program name',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              value: _useCustomProgram,
              onChanged: (v) {
                setState(() {
                  _useCustomProgram = v;
                  // Initialize custom field with current preset when toggled on
                  if (v && _programCtrl.text.isEmpty) {
                    _programCtrl.text = _program;
                  }
                });
              },
            ),

            _vGap,

            _sectionLabel('Category'),
            DropdownButtonFormField<String>(
              value: _category,
              borderRadius: BorderRadius.circular(12),
              decoration: _dec(),
              items: const [
                DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                DropdownMenuItem(
                  value: 'Medical Care',
                  child: Text('Medical Care'),
                ),
                DropdownMenuItem(
                  value: 'Food and Care',
                  child: Text('Food and Care'),
                ),
                DropdownMenuItem(
                  value: 'Emergency Care',
                  child: Text('Emergency Care'),
                ),
                DropdownMenuItem(
                  value: 'Community and Advocacy',
                  child: Text('Community and Advocacy'),
                ),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),

            _vGap,

            // Status field
            _sectionLabel('Status'),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: _dec(
                      hint: 'Select status',
                      prefixIcon: const Icon(Icons.flag_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'Inactive',
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _status = v!),
                  ),
                ),
                _hGap,
                // shows computed effective status including "Due"
                Container(
                  height: kControlHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueGrey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: brand),
                      const SizedBox(width: 8),
                      Text(
                        'Current: $effectiveStatus',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: brand,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            _vGap,

            _sectionLabel('Fundraising Goal'),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: kControlHeight,
                    child: TextField(
                      controller: _goalCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _dec(
                        prefixIcon: const Icon(Icons.payments_outlined),
                        prefix: Padding(
                          padding: const EdgeInsets.only(left: 8, right: 4),
                          child: Text(
                            '$_currency ',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _hGap,
                ElevatedButton(
                  style: _primaryBtn,
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Goal set to $_currency ${_goalCtrl.text}'),
                    ),
                  ),
                  child: const Text('Set Goal'),
                ),
              ],
            ),

            _vGap,

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: kControlHeight,
                    child: TextField(
                      controller: _deadlineCtrl,
                      readOnly: true,
                      onTap: _pickDeadline,
                      decoration: _dec(
                        label: 'Deadline',
                        hint: 'MM/DD/YYYY',
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ),
                ),
                _hGap,
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    borderRadius: BorderRadius.circular(12),
                    decoration: _dec(label: 'Currency'),
                    items: const [
                      DropdownMenuItem(value: 'PHP', child: Text('PHP')),
                      DropdownMenuItem(value: 'USD', child: Text('USD')),
                      DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                    ],
                    onChanged: (v) => setState(() => _currency = v!),
                  ),
                ),
              ],
            ),

            _vGap,

            _sectionLabel('Description'),
            TextField(
              controller: _descCtrl,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              decoration: _dec(
                hint: 'Tell donors what this campaign is about…',
                prefixIcon: const Icon(Icons.description_outlined),
              ),
            ),

            _vGap,

            Container(
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progress Tracker',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _notifyAt75,
                    onChanged: (v) => setState(() => _notifyAt75 = v ?? false),
                    title: const Text(
                      'Notify When 75% Goal Reached: Enable goal notifications',
                      style: TextStyle(height: 1.2),
                    ),
                  ),
                ],
              ),
            ),

            _vGap,

            SizedBox(
              height: kControlHeight,
              child: ElevatedButton(
                style: _primaryBtn,
                onPressed: _postCampaign,
                child: const Text('Post Campaign'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// class CampaignSettingsScreen extends StatefulWidget {
//   const CampaignSettingsScreen({super.key});

//   @override
//   State<CampaignSettingsScreen> createState() => _CampaignSettingsScreenState();
// }

// class _CampaignSettingsScreenState extends State<CampaignSettingsScreen> {
//   static const brand = Color(0xFF27374D);

//   static const double kSectionGap = 20;
//   static const double kFieldGap = 12;
//   static const double kControlHeight = 48;
//   static const EdgeInsets kScreenPadding = EdgeInsets.fromLTRB(16, 12, 16, 24);

//   String _program = 'Shelters Improvement';
//   String _category = 'Urgent';
//   String _currency = 'PHP';
//   bool _notifyAt75 = true;

//   // NEW: editable status (Active/Inactive). "Due" is computed from deadline.
//   String _status = 'Active'; // Active | Inactive

//   final _goalCtrl = TextEditingController(text: '12,500.00');
//   final _deadlineCtrl = TextEditingController();
//   final _descCtrl = TextEditingController();

//   DateTime? _deadline;

//   @override
//   void dispose() {
//     _goalCtrl.dispose();
//     _deadlineCtrl.dispose();
//     _descCtrl.dispose();
//     super.dispose();
//   }

//   OutlineInputBorder _border([Color? c]) => OutlineInputBorder(
//     borderRadius: BorderRadius.circular(12),
//     borderSide: BorderSide(color: c ?? Colors.blueGrey.shade200, width: 1),
//   );

//   InputDecoration _dec({
//     String? label,
//     String? hint,
//     Widget? prefixIcon,
//     Widget? suffixIcon,
//     Widget? prefix,
//   }) {
//     return InputDecoration(
//       labelText: label,
//       hintText: hint,
//       prefixIcon: prefixIcon,
//       suffixIcon: suffixIcon,
//       prefix: prefix,
//       filled: true,
//       fillColor: Colors.blueGrey.shade50,
//       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//       enabledBorder: _border(),
//       focusedBorder: _border(Colors.blueGrey.shade400),
//     );
//   }

//   Widget _sectionLabel(String text) => Padding(
//     padding: const EdgeInsets.only(bottom: 8),
//     child: Text(
//       text,
//       style: const TextStyle(
//         fontWeight: FontWeight.w700,
//         color: Colors.black87,
//       ),
//     ),
//   );

//   ButtonStyle get _primaryBtn => ElevatedButton.styleFrom(
//     backgroundColor: brand,
//     foregroundColor: Colors.white,
//     elevation: 0,
//     padding: const EdgeInsets.symmetric(horizontal: 18),
//     minimumSize: const Size(120, kControlHeight),
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//   );

//   Future<void> _pickDeadline() async {
//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       firstDate: now,
//       lastDate: DateTime(now.year + 5),
//       initialDate: now,
//       builder: (context, child) => Theme(
//         data: Theme.of(
//           context,
//         ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: brand)),
//         child: child!,
//       ),
//     );
//     if (picked != null) {
//       _deadline = picked;
//       _deadlineCtrl.text = DateFormat('MM/dd/yyyy').format(picked);
//       setState(() {});
//     }
//   }

//   SizedBox get _vGap => const SizedBox(height: kSectionGap);
//   SizedBox get _hGap => const SizedBox(width: kFieldGap);

//   String get _computedStatus {
//     if (_deadline != null && _deadline!.isBefore(DateTime.now())) return 'Due';
//     return _status; // Active/Inactive from dropdown
//   }

//   Future<void> _postCampaign() async {
//     // basic validations
//     final goal = double.tryParse(_goalCtrl.text.replaceAll(',', '')) ?? 0;
//     if (goal <= 0) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please set a valid fundraising goal.')),
//       );
//       return;
//     }
//     if (_deadline == null) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Please pick a deadline.')));
//       return;
//     }

//     try {
//       final isActive = (_status == 'Active'); // what we persist
//       final response = await Supabase.instance.client.from('campaigns').insert({
//         'program': _program,
//         'category': _category,
//         'fundraising_goal': goal,
//         'deadline': _deadline!.toIso8601String(),
//         'currency': _currency,
//         'description': _descCtrl.text,
//         'notify_at_75': _notifyAt75,
//         'is_active': isActive, // NEW: persist status
//         'created_at': DateTime.now().toIso8601String(),
//       }).select();

//       if (response.isNotEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Campaign posted successfully!')),
//         );
//         Navigator.pop(context);
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Failed to post campaign.')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error posting campaign: $e')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final effectiveStatus = _computedStatus; // Active / Inactive / Due

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         leading: const BackButton(),
//         title: const Text('Campaign'),
//         centerTitle: true,
//         elevation: 0,
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black87,
//       ),
//       body: SafeArea(
//         child: ListView(
//           padding: kScreenPadding,
//           children: [
//             _sectionLabel('Default Program'),
//             DropdownButtonFormField<String>(
//               value: _program,
//               borderRadius: BorderRadius.circular(12),
//               decoration: _dec(),
//               items: const [
//                 DropdownMenuItem(
//                   value: 'Shelters Improvement',
//                   child: Text('Shelters Improvement'),
//                 ),
//                 DropdownMenuItem(value: 'Surgery', child: Text('Surgery')),
//                 DropdownMenuItem(value: 'Dog Pound', child: Text('Dog Pound')),
//                 DropdownMenuItem(value: 'Rescue', child: Text('Rescue')),
//                 DropdownMenuItem(
//                   value: 'Stray Animals',
//                   child: Text('Stray Animals'),
//                 ),
//                 DropdownMenuItem(
//                   value: 'Vaccination',
//                   child: Text('Vaccination'),
//                 ),
//                 DropdownMenuItem(
//                   value: 'Spay/Neuter',
//                   child: Text('Spay/Neuter'),
//                 ),
//                 DropdownMenuItem(value: 'Pet Food', child: Text('Pet Food')),
//                 DropdownMenuItem(
//                   value: 'Medical Supplies',
//                   child: Text('Medical Supplies'),
//                 ),
//                 DropdownMenuItem(
//                   value: 'Outreach and Awareness',
//                   child: Text('Outreach and Awareness'),
//                 ),
//               ],
//               onChanged: (v) => setState(() => _program = v!),
//             ),

//             _vGap,

//             _sectionLabel('Category'),
//             DropdownButtonFormField<String>(
//               value: _category,
//               borderRadius: BorderRadius.circular(12),
//               decoration: _dec(),
//               items: const [
//                 DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
//                 DropdownMenuItem(
//                   value: 'Medical Care',
//                   child: Text('Medical Care'),
//                 ),
//                 DropdownMenuItem(
//                   value: 'Food and Care',
//                   child: Text('Food and Care'),
//                 ),
//                 DropdownMenuItem(
//                   value: 'Emergency Care',
//                   child: Text('Emergency Care'),
//                 ),
//                 DropdownMenuItem(
//                   value: 'Community and Advocacy',
//                   child: Text('Community and Advocacy'),
//                 ),
//               ],
//               onChanged: (v) => setState(() => _category = v!),
//             ),

//             _vGap,

//             // NEW: status field
//             _sectionLabel('Status'),
//             Row(
//               children: [
//                 Expanded(
//                   child: DropdownButtonFormField<String>(
//                     value: _status,
//                     decoration: _dec(
//                       hint: 'Select status',
//                       prefixIcon: const Icon(Icons.flag_outlined),
//                     ),
//                     items: const [
//                       DropdownMenuItem(value: 'Active', child: Text('Active')),
//                       DropdownMenuItem(
//                         value: 'Inactive',
//                         child: Text('Inactive'),
//                       ),
//                     ],
//                     onChanged: (v) => setState(() => _status = v!),
//                   ),
//                 ),
//                 _hGap,
//                 // shows computed effective status including "Due"
//                 Container(
//                   height: kControlHeight,
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   decoration: BoxDecoration(
//                     color: Colors.blueGrey.shade50,
//                     borderRadius: BorderRadius.circular(12),
//                     border: Border.all(color: Colors.blueGrey.shade200),
//                   ),
//                   child: Row(
//                     children: [
//                       const Icon(Icons.info_outline, size: 18, color: brand),
//                       const SizedBox(width: 8),
//                       Text(
//                         'Current: $effectiveStatus',
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w600,
//                           color: brand,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),

//             _vGap,

//             _sectionLabel('Fundraising Goal'),
//             Row(
//               children: [
//                 Expanded(
//                   child: SizedBox(
//                     height: kControlHeight,
//                     child: TextField(
//                       controller: _goalCtrl,
//                       keyboardType: const TextInputType.numberWithOptions(
//                         decimal: true,
//                       ),
//                       decoration: _dec(
//                         prefixIcon: const Icon(Icons.payments_outlined),
//                         prefix: Padding(
//                           padding: const EdgeInsets.only(left: 8, right: 4),
//                           child: Text(
//                             '$_currency ',
//                             style: const TextStyle(fontWeight: FontWeight.w600),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 _hGap,
//                 ElevatedButton(
//                   style: _primaryBtn,
//                   onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                       content: Text('Goal set to $_currency ${_goalCtrl.text}'),
//                     ),
//                   ),
//                   child: const Text('Set Goal'),
//                 ),
//               ],
//             ),

//             _vGap,

//             Row(
//               children: [
//                 Expanded(
//                   child: SizedBox(
//                     height: kControlHeight,
//                     child: TextField(
//                       controller: _deadlineCtrl,
//                       readOnly: true,
//                       onTap: _pickDeadline,
//                       decoration: _dec(
//                         label: 'Deadline',
//                         hint: 'MM/DD/YYYY',
//                         prefixIcon: const Icon(Icons.calendar_today_outlined),
//                       ),
//                     ),
//                   ),
//                 ),
//                 _hGap,
//                 SizedBox(
//                   width: 140,
//                   child: DropdownButtonFormField<String>(
//                     value: _currency,
//                     borderRadius: BorderRadius.circular(12),
//                     decoration: _dec(label: 'Currency'),
//                     items: const [
//                       DropdownMenuItem(value: 'PHP', child: Text('PHP')),
//                       DropdownMenuItem(value: 'USD', child: Text('USD')),
//                       DropdownMenuItem(value: 'EUR', child: Text('EUR')),
//                     ],
//                     onChanged: (v) => setState(() => _currency = v!),
//                   ),
//                 ),
//               ],
//             ),

//             _vGap,

//             _sectionLabel('Description'),
//             TextField(
//               controller: _descCtrl,
//               minLines: 3,
//               maxLines: 6,
//               maxLength: 500,
//               decoration: _dec(
//                 hint: 'Tell donors what this campaign is about…',
//                 prefixIcon: const Icon(Icons.description_outlined),
//               ),
//             ),

//             _vGap,

//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.blueGrey.shade50,
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: Colors.blueGrey.shade100),
//               ),
//               padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Progress Tracker',
//                     style: TextStyle(fontWeight: FontWeight.w700),
//                   ),
//                   const SizedBox(height: 12),
//                   CheckboxListTile(
//                     contentPadding: EdgeInsets.zero,
//                     dense: true,
//                     controlAffinity: ListTileControlAffinity.leading,
//                     value: _notifyAt75,
//                     onChanged: (v) => setState(() => _notifyAt75 = v ?? false),
//                     title: const Text(
//                       'Notify When 75% Goal Reached: Enable goal notifications',
//                       style: TextStyle(height: 1.2),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             _vGap,

//             SizedBox(
//               height: kControlHeight,
//               child: ElevatedButton(
//                 style: _primaryBtn,
//                 onPressed: _postCampaign,
//                 child: const Text('Post Campaign'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
