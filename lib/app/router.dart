import 'package:checkplan/core/time/current_day.dart';
import 'package:checkplan/core/widgets/empty_view.dart';
import 'package:checkplan/features/checklists/presentation/archived_checklists_screen.dart';
import 'package:checkplan/features/checklists/presentation/checklists_screen.dart';
import 'package:checkplan/features/tasks/presentation/checklist_detail_screen.dart';
import 'package:checkplan/features/today/presentation/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Builds the app's router: a two-tab [StatefulShellRoute] bottom-nav shell
/// (Lists | Today), with the checklist detail nested under the Lists branch so
/// it keeps the nav bar and its back button returns to Lists.
///
/// Returns a fresh instance per call so each `CheckPlanApp` owns and disposes
/// its own router instead of sharing a global; this also isolates widget tests
/// that mount the app. [initialLocation] seeds the starting route so tests can
/// deep-link a branch (e.g. `/today`).
GoRouter createAppRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _ScaffoldWithNavBar(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const ChecklistsScreen(),
              routes: [
                GoRoute(
                  path: 'checklist/:id',
                  builder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '');
                    if (id == null) return const _NotFoundScreen();
                    return ChecklistDetailScreen(checklistId: id);
                  },
                ),
                GoRoute(
                  path: 'archived',
                  builder: (context, state) => const ArchivedChecklistsScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/today',
              builder: (context, state) => const TodayScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

/// The bottom-nav scaffold wrapping the two branches.
///
/// A `ConsumerStatefulWidget` so it can invalidate [currentDayProvider] when
/// the app resumes from the background as the midnight timer may have been
/// suspended across a day boundary while backgrounded.
class _ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const _ScaffoldWithNavBar({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<_ScaffoldWithNavBar> createState() =>
      _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<_ScaffoldWithNavBar> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(currentDayProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: widget.navigationShell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.checklist), label: 'Lists'),
          NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
        ],
      ),
    );
  }
}

/// Shown when a checklist route's id parameter is not a valid integer.
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Not found')),
    body: const EmptyView(
      message: 'That checklist does not exist',
      icon: Icons.search_off,
    ),
  );
}
