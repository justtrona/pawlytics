import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/manage-usermodel.dart';

class ManageUserController extends ChangeNotifier {
  ManageUserController({this.currentAdminId, this.useMocks = false});

  /// ⚠️ Change if your table is not `users`
  static const String tableName = 'users';

  final String? currentAdminId;
  bool useMocks;

  final TextEditingController searchCtl = TextEditingController();

  bool _loading = false;
  UiRole? _roleFilter; // null = all
  List<AdminUser> _users = [];

  bool get loading => _loading;
  UiRole? get roleFilter => _roleFilter;
  List<AdminUser> get users => List.unmodifiable(_users);

  SupabaseClient get _sb => Supabase.instance.client;

  // ---------------- Mock helpers ----------------
  final List<AdminUser> _mockDb = [
    AdminUser(
      id: 'u1',
      fullName: 'Juan Dela Cruz',
      email: 'juan@example.com',
      phoneNumber: '09171234567',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      role: UiRole.donor,
    ),
    AdminUser(
      id: 'u2',
      fullName: 'Maria Santos',
      email: 'maria@example.com',
      phoneNumber: '09181234567',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      role: UiRole.staff,
    ),
    AdminUser(
      id: 'u3',
      fullName: 'Admin Alpha',
      email: 'alpha@example.com',
      phoneNumber: '09191234567',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      role: UiRole.admin,
    ),
  ];

  void addMockUser() {
    final id = 'u${_mockDb.length + 1}';
    _mockDb.add(
      AdminUser(
        id: id,
        fullName: 'New User $id',
        email: 'user$id@example.com',
        phoneNumber: '09${id.padLeft(9, '0')}',
        createdAt: DateTime.now(),
        role: UiRole.donor,
      ),
    );
    load(); // refresh view
  }

  void toggleMockMode() {
    useMocks = !useMocks;
    load();
  }

  // ---------------- Load ----------------
  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final q = searchCtl.text.trim().toLowerCase();

      if (useMocks) {
        // Client-side filtering/sorting on mock data
        List<AdminUser> list = [..._mockDb];

        if (q.isNotEmpty) {
          list = list.where((u) {
            return u.fullName.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q);
          }).toList();
        }

        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (_roleFilter != null) {
          list = list.where((u) => u.role == _roleFilter).toList();
        }

        _users = list;
        return;
      }

      // --- Real Supabase load ---
      var builder = _sb
          .from(tableName)
          .select('id, fullName, email, phone_number, role, created_at');

      if (q.isNotEmpty) {
        builder = builder.or('fullName.ilike.%$q%,email.ilike.%$q%');
      }

      final List<dynamic> rows = await builder.order(
        'created_at',
        ascending: false,
      );

      var list = rows
          .map((m) => AdminUser.fromMap(m as Map<String, dynamic>))
          .toList();

      if (_roleFilter != null) {
        list = list.where((u) => u.role == _roleFilter).toList();
      }

      _users = list;
    } catch (e) {
      debugPrint('Load users error: $e');
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setRoleFilter(UiRole? role) {
    _roleFilter = role;
    load();
  }

  Future<void> changeRole(AdminUser user, UiRole target) async {
    if (currentAdminId != null &&
        user.id != null &&
        user.id == currentAdminId &&
        user.role == UiRole.admin &&
        target != UiRole.admin) {
      throw StateError('You cannot remove your own admin role.');
    }

    if (useMocks) {
      final idx = _mockDb.indexWhere((u) => u.id == user.id);
      if (idx != -1) {
        // Use map: take the old map, overwrite role, reconstruct AdminUser
        final updated = AdminUser.fromMap({
          ..._mockDb[idx].toMap(),
          'role': roleToString(target),
        });
        _mockDb[idx] = updated;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await load();
      return;
    }

    await _sb
        .from(tableName)
        .update({'role': roleToString(target)})
        .eq('id', user.id!);

    await load();
  }

  @override
  void dispose() {
    searchCtl.dispose();
    super.dispose();
  }
}
