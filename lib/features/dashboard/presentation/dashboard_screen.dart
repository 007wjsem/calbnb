import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user.dart';
import '../../calendar/presentation/calendar_dashboard.dart';
import 'cleaner_dashboard.dart';
import 'cleaner_earnings_view.dart';
import 'inspector_dashboard.dart';
import '../../../core/constants/roles.dart';
import '../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:calbnb/l10n/app_localizations.dart';
import '../../company/presentation/company_switcher.dart';
import '../../settings/presentation/locale_provider.dart';
import '../../company/data/company_repository.dart';
import '../../company/domain/subscription.dart';
import '../../inbox/data/inbox_repository.dart';
import '../../onboarding/data/lead_repository.dart';
import '../../support/data/support_repository.dart';
import 'dart:convert';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardWrapper(isAssignmentsView: false);
  }
}

class DashboardWrapper extends ConsumerWidget {
  final bool isAssignmentsView;
  final bool isEarningsView;
  const DashboardWrapper({super.key, this.isAssignmentsView = false, this.isEarningsView = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Builder(builder: (context) {
          // Diamond White-Label: render custom logo if available
          if (user.role != AppRole.superAdmin) {
            final companyId = user.activeCompanyId;
            if (companyId != null && companyId.isNotEmpty) {
              final companyAsync = ref.watch(companyProvider(companyId));
              final company = companyAsync.valueOrNull;
              final logoBase64 = company?.companyLogoBase64;
              if (company?.tier == SubscriptionTier.diamond && logoBase64 != null && logoBase64.isNotEmpty) {
                return Image.memory(base64Decode(logoBase64), height: 36, fit: BoxFit.contain);
              }
            }
          }
          return Text('${user.role == AppRole.superAdmin ? 'System' : l10n.appTitle} - ${user.role.displayName} Dashboard');
        }),
        actions: [
          _DashboardInboxBadge(user: user),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
            },
            tooltip: l10n.logoutButton,
          ),
        ],
      ),
      drawer: isDesktop ? null : Drawer(
        child: _buildSidebar(context, ref, user, isDesktop: false),
      ),
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  _buildSidebar(context, ref, user, isDesktop: true),
                  Expanded(
                    child: _buildMainContent(user),
                  ),
                ],
              )
            : _buildMainContent(user),
      ),
    );
  }

  Widget _buildMainContent(User user) {
    if (isAssignmentsView) {
      if (user.role == AppRole.cleaner) {
        return const CleanerDashboard();
      } else if (user.role == AppRole.inspector) {
        return const InspectorDashboard();
      }
    } else if (isEarningsView) {
      if (user.role == AppRole.cleaner) {
        return const CleanerEarningsView();
      }
    }
    return const CalendarDashboard();
  }
  Widget _buildSidebar(BuildContext context, WidgetRef ref, User user, {required bool isDesktop}) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final l10n = AppLocalizations.of(context)!;
    
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
                if (user.role != AppRole.superAdmin) ...[
                  Image.asset(
                    'assets/images/logo.png',
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    user.role == AppRole.superAdmin ? l10n.systemAdministration : l10n.appTitle,
                    style: const TextStyle(
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
          const CompanySwitcher(),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.mainMenu,
                style: const TextStyle(color: AppColors.sidebarMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.4),
              ),
            ),
          ),
          if (user.role == AppRole.cleaner || user.role == AppRole.inspector) ...[
            _SidebarItem(
              icon: Icons.assignment_rounded,
              title: l10n.assignments,
              isSelected: currentRoute == '/assignments',
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                context.go('/assignments');
              },
            ),
          ],
          _SidebarItem(
            icon: Icons.calendar_today_rounded,
            title: l10n.calendarTab,
            isSelected: currentRoute == '/' || currentRoute == '/calendar',
            onTap: () {
              if (!isDesktop) Navigator.pop(context);
              context.go('/calendar');
            },
          ),
          _SidebarItem(
            icon: Icons.person_outline_rounded,
            title: l10n.myProfile,
            isSelected: currentRoute == '/profile',
            onTap: () {
              if (!isDesktop) Navigator.pop(context);
              context.go('/profile');
            },
          ),
          _SidebarItem(
            icon: Icons.support_agent_rounded,
            title: l10n.supportTitle,
            isSelected: currentRoute == '/support',
            onTap: () {
              if (!isDesktop) Navigator.pop(context);
              context.push('/support');
            },
          ),
          // ── Team Inbox (Silver+) ─────────────────────────────────────
          Builder(builder: (context) {
            final companyId = user.activeCompanyId;
            if (companyId == null || companyId.isEmpty) return const SizedBox.shrink();
            final companyAsync = ref.watch(companyProvider(companyId));
            final company = companyAsync.valueOrNull;
            if (company == null || company.tier.index < SubscriptionTier.silver.index) return const SizedBox.shrink();
            // Show unread count badge
            final unreadAsync = ref.watch(totalUnreadCountProvider((companyId: companyId, user: user)));
            final unread = unreadAsync.valueOrNull ?? 0;
            return _SidebarItem(
              icon: Icons.chat_bubble_outline_rounded,
              title: l10n.teamInbox, // Which is now "Inbox" in .arb
              isSelected: currentRoute == '/inbox',
              badge: unread > 0 ? unread.toString() : null,
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                context.go('/inbox');
              },
            );
          }),
          if (user.role == AppRole.cleaner) ...[
            _SidebarItem(
              icon: Icons.monetization_on_outlined,
              title: l10n.myEarnings,
              isSelected: currentRoute == '/earnings',
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                context.go('/earnings');
              },
            ),
            _SidebarItem(
              icon: Icons.account_balance_wallet_outlined,
              title: l10n.myPaymentsTitle,
              isSelected: currentRoute == '/cleaner_payments',
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                context.push('/cleaner_payments');
              },
            ),
          ],
          if (user.role.displayName == 'Super Admin' || user.role.displayName == 'Administrator') ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.administration,
                  style: const TextStyle(color: AppColors.sidebarMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.4),
                ),
              ),
            ),
            _SidebarItem(
              icon: Icons.cleaning_services_rounded,
              title: l10n.cleanings,
              isSelected: currentRoute == '/admin/cleanings',
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                context.go('/admin/cleanings');
              },
            ),
            _SidebarItem(
              icon: Icons.fact_check_rounded,
              title: l10n.inspections,
              isSelected: currentRoute == '/admin/inspections',
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                context.go('/admin/inspections');
              },
            ),
            if (user.role != AppRole.superAdmin)
              _SidebarItem(
                icon: Icons.payments_rounded,
                title: l10n.payroll,
                isSelected: currentRoute == '/admin/payroll',
                onTap: () {
                  if (!isDesktop) Navigator.pop(context);
                  context.go('/admin/payroll');
                },
              ),
            _SidebarItem(
              icon: Icons.settings_rounded,
              title: l10n.settingsTab,
              isSelected: currentRoute == '/admin/settings',
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                context.go('/admin/settings');
              },
            ),
            _SidebarItem(
              icon: Icons.credit_card_outlined,
              title: l10n.billingAndPlan,
              isSelected: currentRoute == '/admin/subscription',
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                context.go('/admin/subscription');
              },
            ),
            // Advanced Reports (Diamond only)
            Builder(builder: (context) {
              final companyId = user.activeCompanyId;
              if (user.role == AppRole.superAdmin || companyId == null || companyId.isEmpty) return const SizedBox.shrink();
              final companyAsync = ref.watch(companyProvider(companyId));
              final company = companyAsync.valueOrNull;
              if (company?.tier != SubscriptionTier.diamond) return const SizedBox.shrink();
              return _SidebarItem(
                icon: Icons.analytics_outlined,
                title: l10n.advancedReports,
                isSelected: currentRoute == '/admin/reports',
                badge: '💎',
                onTap: () {
                  if (!isDesktop) Navigator.pop(context);
                  context.go('/admin/reports');
                },
              );
            }),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.management,
                  style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
            ),
            if (user.role == AppRole.superAdmin) ...[
              _SidebarItem(
                icon: Icons.insights_rounded,
                title: 'Global Subscriptions',
                isSelected: currentRoute == '/superadmin/subscriptions',
                onTap: () {
                  if (!isDesktop) Navigator.pop(context);
                  context.go('/superadmin/subscriptions');
                },
              ),
              _SidebarItem(
                icon: Icons.business_center_rounded,
                title: l10n.companiesTab,
                isSelected: currentRoute == '/admin/companies',
                onTap: () {
                  if (!isDesktop) Navigator.pop(context);
                  context.go('/admin/companies');
                },
              ),
              Builder(builder: (context) {
                final leadsCountAsync = ref.watch(newLeadsCountProvider);
                final count = leadsCountAsync.valueOrNull ?? 0;
                return _SidebarItem(
                  icon: Icons.person_add_alt_1_rounded,
                  title: l10n.superAdminLeadsMenu,
                  isSelected: currentRoute == '/admin/leads',
                  badge: count > 0 ? count.toString() : null,
                  onTap: () {
                    if (!isDesktop) Navigator.pop(context);
                    context.go('/admin/leads');
                  },
                );
              }),
              Builder(builder: (context) {
                final ticketsCountAsync = ref.watch(openTicketsCountProvider);
                final count = ticketsCountAsync.valueOrNull ?? 0;
                return _SidebarItem(
                  icon: Icons.support_agent_outlined,
                  title: l10n.superAdminSupportMenu,
                  isSelected: currentRoute.startsWith('/admin/support'),
                  badge: count > 0 ? count.toString() : null,
                  onTap: () {
                    if (!isDesktop) Navigator.pop(context);
                    context.go('/admin/support');
                  },
                );
              }),
            ],
            _SidebarItem(
              icon: Icons.people_alt_rounded,
              title: l10n.users,
              isSelected: currentRoute == '/admin/users',
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                context.go('/admin/users');
              },
            ),
            _SidebarItem(
              icon: Icons.home_work_rounded,
              title: l10n.properties,
              isSelected: currentRoute == '/admin/properties',
              onTap: () {
                if (!isDesktop) Navigator.pop(context);
                context.go('/admin/properties');
              },
            ),
          ],
                ],
              ),
            ),
          ),
          
          // Language Switcher (Bottom)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Consumer(
              builder: (context, ref, _) {
                final locale = ref.watch(localeProvider);
                final isSpanish = locale.languageCode == 'es';
                
                return InkWell(
                  onTap: () {
                    final newLocale = Locale(isSpanish ? 'en' : 'es');
                    ref.read(localeProvider.notifier).setLocale(newLocale);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.language, color: isSpanish ? AppColors.amber : Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isSpanish ? l10n.englishToggle : l10n.spanishToggle,
                          style: TextStyle(
                            color: isSpanish ? AppColors.amber : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
  final String? badge;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.badge,
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
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.sidebarText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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

// ── Global Inbox Badge for AppBar ───────────────────────────────────────────
class _DashboardInboxBadge extends ConsumerWidget {
  final User user;
  const _DashboardInboxBadge({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user.role == AppRole.superAdmin) return const SizedBox.shrink();
    final companyId = user.activeCompanyId;
    if (companyId == null || companyId.isEmpty) return const SizedBox.shrink();

    // Re-watch company to check tier
    final companyAsync = ref.watch(companyProvider(companyId));
    final company = companyAsync.valueOrNull;
    if (company == null || company.tier.index < SubscriptionTier.silver.index) return const SizedBox.shrink();

    final countAsync = ref.watch(totalUnreadCountProvider((companyId: companyId, user: user)));
    final count = countAsync.valueOrNull ?? 0;

    return IconButton(
      onPressed: () => context.go('/inbox'),
      tooltip: AppLocalizations.of(context)!.teamInboxTitle,
      icon: Badge(
        label: Text(count.toString()),
        isLabelVisible: count > 0,
        backgroundColor: Colors.red,
        child: const Icon(Icons.chat_bubble_outline_rounded),
      ),
    );
  }
}
