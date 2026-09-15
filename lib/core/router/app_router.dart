import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/contacts/presentation/contacts_page.dart';
import '../../features/contacts/presentation/import_contacts_page.dart';
import '../../features/campaigns/presentation/campaigns_page.dart';
import '../../features/campaigns/presentation/create_campaign_page.dart';
import '../../features/templates/presentation/templates_page.dart';
import '../../features/templates/presentation/template_editor_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/contacts',
            builder: (context, state) => const ContactsPage(),
            routes: [
              GoRoute(
                path: 'import/:listId',
                builder: (context, state) => ImportContactsPage(
                  listId: state.pathParameters['listId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/campaigns',
            builder: (context, state) => const CampaignsPage(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CreateCampaignPage(),
              ),
            ],
          ),
          GoRoute(
            path: '/templates',
            builder: (context, state) => const TemplatesPage(),
            routes: [
              GoRoute(
                path: 'edit/:id',
                builder: (context, state) => TemplateEditorPage(
                  templateId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});
