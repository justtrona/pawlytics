import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawlytics/views/admin/controllers/manage-user-controller.dart';
import 'package:pawlytics/views/admin/model/manage-usermodel.dart';

class ManageUserPage extends StatelessWidget {
  const ManageUserPage({
    super.key,
    this.currentAdminId,
    this.startInMock = true,
  });
  final String? currentAdminId;
  final bool startInMock; // default true so it runs without backend immediately

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ManageUserController(
        currentAdminId: currentAdminId,
        useMocks: startInMock,
      )..load(),
      child: const _ManageUserBody(),
    );
  }
}

class _ManageUserBody extends StatelessWidget {
  const _ManageUserBody();

  Color _roleColor(UiRole r) {
    switch (r) {
      case UiRole.admin:
        return Colors.deepPurple;
      case UiRole.staff:
        return Colors.teal;
      case UiRole.donor:
      default:
        return Colors.grey;
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showRoleSheet(
    BuildContext context,
    ManageUserController ctrl,
    AdminUser user,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _roleTile(
              context,
              ctrl,
              user,
              UiRole.donor,
              Icons.volunteer_activism_outlined,
            ),
            _roleTile(context, ctrl, user, UiRole.staff, Icons.badge_outlined),
            _roleTile(
              context,
              ctrl,
              user,
              UiRole.admin,
              Icons.security_outlined,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  ListTile _roleTile(
    BuildContext context,
    ManageUserController ctrl,
    AdminUser user,
    UiRole target,
    IconData icon,
  ) {
    final selected = user.role == target;
    final label =
        roleToString(target)[0].toUpperCase() +
        roleToString(target).substring(1);
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: selected ? const Icon(Icons.check, color: Colors.green) : null,
      onTap: () async {
        Navigator.pop(context);
        try {
          await ctrl.changeRole(user, target);
          if (context.mounted) {
            _snack(context, 'Role updated to ${roleToString(target)}.');
          }
        } catch (e) {
          if (context.mounted) _snack(context, e.toString());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManageUserController>(
      builder: (context, ctrl, _) {
        final users = ctrl.users;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Manage Users'),
            centerTitle: true,
            leading: const BackButton(),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: ctrl.load,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Search
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: ctrl.searchCtl,
                    onSubmitted: (_) => ctrl.load(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search full name or email',
                      suffixIcon: ctrl.searchCtl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                ctrl.searchCtl.clear();
                                ctrl.load();
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                // Role chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: ctrl.roleFilter == null,
                        onSelected: (_) => ctrl.setRoleFilter(null),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Donor'),
                        selected: ctrl.roleFilter == UiRole.donor,
                        onSelected: (_) => ctrl.setRoleFilter(UiRole.donor),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Staff'),
                        selected: ctrl.roleFilter == UiRole.staff,
                        onSelected: (_) => ctrl.setRoleFilter(UiRole.staff),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Admin'),
                        selected: ctrl.roleFilter == UiRole.admin,
                        onSelected: (_) => ctrl.setRoleFilter(UiRole.admin),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: ctrl.loading
                      ? const Center(child: CircularProgressIndicator())
                      : users.isEmpty
                      ? const Center(
                          child: Text(
                            'No users found.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemCount: users.length,
                          itemBuilder: (_, i) {
                            final u = users[i];
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _roleColor(
                                    u.role,
                                  ).withOpacity(0.15),
                                  child: Icon(
                                    u.role == UiRole.admin
                                        ? Icons.security
                                        : u.role == UiRole.staff
                                        ? Icons.badge
                                        : Icons.person,
                                    color: _roleColor(u.role),
                                  ),
                                ),
                                title: Text(
                                  u.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(u.email),
                                trailing: PopupMenuButton<String>(
                                  tooltip: 'Actions',
                                  onSelected: (val) {
                                    if (val == 'role') {
                                      _showRoleSheet(context, ctrl, u);
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'role',
                                      child: Row(
                                        children: [
                                          Icon(Icons.manage_accounts, size: 18),
                                          SizedBox(width: 8),
                                          Text('Change Role'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => _showRoleSheet(context, ctrl, u),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Only show “Add Demo User” in mock mode
          floatingActionButton: ctrl.useMocks
              ? FloatingActionButton.extended(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Demo User'),
                  onPressed: ctrl.addMockUser,
                )
              : null,
        );
      },
    );
  }
}
