import 'package:checkplan/features/checklists/presentation/checklists_screen.dart';
import 'package:checkplan/features/tasks/presentation/checklist_detail_screen.dart';
import 'package:go_router/go_router.dart';

/// Builds the app's router: a flat configuration with the Lists screen at the
/// root.
///
/// Returns a fresh instance per call so each `CheckPlanApp` owns and disposes
/// its own router instead of sharing a global; this also isolates widget tests
/// that mount the app. It grows into a `StatefulShellRoute` bottom-nav shell in
/// a later iteration.
GoRouter createAppRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const ChecklistsScreen()),
    GoRoute(
      path: '/checklist/:id',
      builder: (context, state) => ChecklistDetailScreen(
        checklistId: int.parse(state.pathParameters['id']!),
      ),
    ),
  ],
);
