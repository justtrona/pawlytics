import 'package:flutter/material.dart';

class AdminAuditLog extends StatefulWidget {
  const AdminAuditLog({super.key});

  @override
  State<AdminAuditLog> createState() => _AdminAuditLogState();
}

class _AdminAuditLogState extends State<AdminAuditLog> {
  static const navy = Color(0xFF0F2D50);
  static const subtitle = Color(0xFF6E7B8A);

  final List<Map<String, String>> _logs = [
    {
      "action": "Updated GCash Number",
      "user": "Admin",
      "timestamp": "Aug 31, 2025 • 10:45 AM",
    },
    {
      "action": "Uploaded QR Code for Maya",
      "user": "Admin",
      "timestamp": "Aug 30, 2025 • 3:12 PM",
    },
    {
      "action": "Deleted Pet Profile",
      "user": "John Admin",
      "timestamp": "Aug 29, 2025 • 11:20 AM",
    },
    {
      "action": "Added New Drop-off Location",
      "user": "Maria Admin",
      "timestamp": "Aug 28, 2025 • 8:32 AM",
    },
  ];

  String _searchQuery = "";
  String _selectedFilter = "All";

  final List<String> _filters = [
    "All",
    "Payments",
    "Profiles",
    "Campaigns",
    "Settings",
  ];

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _logs
        .where(
          (log) =>
              log["action"]!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              log["user"]!.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Audit Logs",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search & Filter Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search logs...",
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: _filters.map((String filter) {
                        return DropdownMenuItem<String>(
                          value: filter,
                          child: Text(filter),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() => _selectedFilter = value!);
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Logs Section
            Expanded(
              child: filteredLogs.isEmpty
                  ? const Center(
                      child: Text(
                        "No audit logs found",
                        style: TextStyle(
                          color: subtitle,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: navy.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.history_edu_outlined,
                                  color: navy,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Action Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      log["action"]!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: navy,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "By ${log["user"]}",
                                      style: TextStyle(
                                        color: subtitle,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Timestamp
                              Text(
                                log["timestamp"]!,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
