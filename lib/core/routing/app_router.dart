import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../core/constants/roles.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/admin/presentation/user_management_screen.dart';
import '../../features/admin/presentation/property_management_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/payroll/presentation/payroll_screen.dart';
import '../../features/dashboard/presentation/cleanings_screen.dart';
import '../../features/dashboard/presentation/inspections_screen.dart';
import '../../features/dashboard/presentation/assignments_screen.dart';
import '../../features/dashboard/presentation/earnings_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/company/presentation/company_management_screen.dart';
import '../../features/company/presentation/company_subscription_screen.dart';
import '../../features/dashboard/presentation/owner_dashboard.dart';
import '../../features/dashboard/presentation/advanced_reports_screen.dart';
import '../../features/inbox/presentation/team_inbox_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isAtRoot = state.matchedLocation == '/';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/';
      }

      if (isAtRoot) {
        final role = authState.role;
        if (role == AppRole.owner) {
          return '/owner';
        }
        if (role == AppRole.cleaner || role == AppRole.inspector) {
          return '/assignments';
        }
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/assignments',
        builder: (context, state) => const AssignmentsScreen(),
      ),
      GoRoute(
        path: '/owner',
        builder: (context, state) => const OwnerDashboard(),
      ),
      GoRoute(
        path: '/earnings',
        builder: (context, state) => const EarningsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UserManagementScreen(),
      ),
      GoRoute(
        path: '/admin/properties',
        builder: (context, state) {
          final companyId = state.uri.queryParameters['companyId'];
          return PropertyManagementScreen(companyId: companyId);
        },
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/admin/payroll',
        builder: (context, state) => const PayrollScreen(),
      ),
      GoRoute(
        path: '/admin/cleanings',
        builder: (context, state) => const CleaningsScreen(),
      ),
      GoRoute(
        path: '/admin/inspections',
        builder: (context, state) => const InspectionsScreen(),
      ),
      GoRoute(
        path: '/admin/companies',
        builder: (context, state) => const CompanyManagementScreen(),
      ),
      GoRoute(
        path: '/admin/subscription',
        builder: (context, state) => const CompanySubscriptionScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) => const AdvancedReportsScreen(),
      ),
      GoRoute(
        path: '/inbox',
        builder: (context, state) => const TeamInboxScreen(),
      ),
    ],
  );
});
