import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/manage-usermodel.dart';

class ManageUserController extends ChangeNotifier {
  ManageUserController({required this.currentAdminId});

  final String? currentAdminId;

  // UI state
  final TextEditingController searchCtl = TextEditingController();
  UiRole? roleFilter;
  bool loading = false;

  // Data
  List<AdminUser> _all = [];

  // Computed getter for visible users
  List<AdminUser> get users {
    final q = searchCtl.text.trim().toLowerCase();
    Iterable<AdminUser> result = _all;

    if (roleFilter != null) {
      result = result.where((u) => u.role == roleFilter);
    }

    if (q.isNotEmpty) {
      result = result.where(
        (u) =>
            u.fullName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q),
      );
    }

    return result.toList();
  }

  // ------------------- Load users -------------------
  Future<void> load() async {
    loading = true;
    notifyListeners();

    try {
      final sb = Supabase.instance.client;

      // Start query builder
      PostgrestFilterBuilder query = sb
          .from('registration')
          .select('id, fullName, email, role');

      // Apply filters
      final q = searchCtl.text.trim();
      if (q.isNotEmpty) {
        query = query.or('fullName.ilike.%$q%,email.ilike.%$q%');
      }

      if (roleFilter != null) {
        query = query.eq('role', roleToString(roleFilter!));
      }

      // Sort and execute
      final List rows = await query.order('fullName', ascending: true);

      _all = rows.map((r) {
        return AdminUser(
          id: r['id'] as String,
          fullName: (r['fullName'] ?? '') as String,
          email: (r['email'] ?? '') as String,
          role: roleFromString((r['role'] ?? 'donor') as String),
        );
      }).toList();
    } catch (e) {
      debugPrint('Load users error: $e');
      _all = [];
    }

    loading = false;
    notifyListeners();
  }

  // ------------------- Change role -------------------
  Future<void> changeRole(AdminUser user, UiRole newRole) async {
    final sb = Supabase.instance.client;

    // Prevent demoting last admin
    if (user.role == UiRole.admin && newRole != UiRole.admin) {
      final admins = await sb.from('registration').select().eq('role', 'admin');
      if ((admins as List).length <= 1) {
        throw Exception('Cannot demote the last admin');
      }
      if (user.id == currentAdminId) {
        throw Exception('Cannot change your own admin role');
      }
    }

    // Update in Supabase
    await sb
        .from('registration')
        .update({'role': roleToString(newRole)})
        .eq('id', user.id!);

    // Update local list
    _all = _all
        .map((u) => u.id == user.id ? u.copyWith(role: newRole) : u)
        .toList();

    notifyListeners();
  }

  // ------------------- Filter Setter -------------------
  void setRoleFilter(UiRole? value) {
    roleFilter = value;
    notifyListeners();
  }

  @override
  void dispose() {
    searchCtl.dispose();
    super.dispose();
  }
}
