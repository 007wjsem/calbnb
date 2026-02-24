import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user.dart';
import '../../calendar/presentation/calendar_dashboard.dart';
import 'cleaner_dashboard.dart';
import 'inspector_dashboard.dart';
import '../../../core/constants/roles.dart';
import '../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardWrapper(isAssignmentsView: false);
  }
}

class DashboardWrapper extends ConsumerWidget {
  final bool isAssignmentsView;
  const DashboardWrapper({super.key, this.isAssignmentsView = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Text('All In 1 Home - ${user.role.displayName} Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: isDesktop ? null : Drawer(
        child: _buildSidebar(context, user, isDesktop: false),
      ),
      body: isDesktop
          ? Row(
              children: [
                _buildSidebar(context, user, isDesktop: true),
                Expanded(
                  child: _buildMainContent(user),
                ),
              ],
            )
          : _buildMainContent(user),
    );
  }

  Widget _buildMainContent(User user) {
    if (isAssignmentsView) {
      if (user.role == AppRole.cleaner) {
        return const CleanerDashboard();
      } else if (user.role == AppRole.inspector) {
        return const InspectorDashboard();
      }
    }
    return const CalendarDashboard();
  }
  Widget _buildSidebar(BuildContext context, User user, {required bool isDesktop}) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    
    return Container(
      width: isDesktop ? 260 : null,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF0D2E63), width: 1)),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 36,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'All In 1 Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.amber,
                    radius: 18,
                    child: Text(
                      user.username.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: AppColors.primaryDark, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.role.displayName,
                          style: const TextStyle(color: AppColors.sidebarMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'MAIN MENU',
                style: TextStyle(color: AppColors.sidebarMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.4),
              ),
            ),
          ),
          if (user.role == AppRole.cleaner || user.role == AppRole.inspector) ...[
            _SidebarItem(
              icon: Icons.assignment_rounded,
              title: 'Assignments',
              isSelected: currentRoute == '/assignments',
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                context.go('/assignments');
              },
            ),
          ],
          _SidebarItem(
            icon: Icons.calendar_today_rounded,
            title: 'Calendar',
            isSelected: currentRoute == '/' || currentRoute == '/calendar',
            onTap: () {
              if (!isDesktop) Navigator.pop(context);
              context.go('/calendar');
            },
          ),
          _SidebarItem(
            icon: Icons.person_outline_rounded,
            title: 'My Profile',
            isSelected: currentRoute == '/profile',
            onTap: () {
              if (!isDesktop) Navigator.pop(context);
              context.go('/profile');
            },
          ),
          if (user.role.displayName == 'Super Admin' || user.role.displayName == 'Administrator') ...[
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ADMINISTRATION',
                  style: TextStyle(color: AppColors.sidebarMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.4),
                ),
              ),
            ),
            _SidebarItem(
              icon: Icons.cleaning_services_rounded,
              title: 'Cleanings',
              isSelected: currentRoute == '/admin/cleanings',
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                context.go('/admin/cleanings');
              },
            ),
            _SidebarItem(
              icon: Icons.fact_check_rounded,
              title: 'Inspections',
              isSelected: currentRoute == '/admin/inspections',
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                context.go('/admin/inspections');
              },
            ),
            _SidebarItem(
              icon: Icons.payments_rounded,
              title: 'Payroll',
              isSelected: currentRoute == '/admin/payroll',
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                context.go('/admin/payroll');
              },
            ),
            _SidebarItem(
              icon: Icons.settings_rounded,
              title: 'Settings',
              isSelected: currentRoute == '/admin/settings',
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                context.go('/admin/settings');
              },
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MANAGEMENT',
                  style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
            ),
            _SidebarItem(
              icon: Icons.people_alt_rounded,
              title: 'Users',
              isSelected: currentRoute == '/admin/users',
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                context.go('/admin/users');
              },
            ),
            _SidebarItem(
              icon: Icons.home_work_rounded,
              title: 'Properties',
              isSelected: currentRoute == '/admin/properties',
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                context.go('/admin/properties');
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.sidebarActive : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.amber : AppColors.sidebarText,
                  size: 20,
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.sidebarText,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
