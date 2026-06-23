import 'package:checkplan/features/checklists/presentation/checklists_screen.dart';
import 'package:go_router/go_router.dart';

/// The app's router.
///
/// A flat configuration with the Lists screen at the root; it grows into a
/// `StatefulShellRoute` bottom-nav shell in a later iteration.
final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const ChecklistsScreen()),
  ],
);
