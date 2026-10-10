import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/auth/auth_screen.dart';
import '../../screens/auth/welcome_screen.dart';
import '../../screens/exchanges/exchange_detail_screen.dart';
import '../../screens/exchanges/exchanges_screen.dart';
import '../../screens/home/home_shell.dart';
import '../../screens/home/splash_screen.dart';
import '../../screens/matches/match_detail_screen.dart';
import '../../screens/matches/matches_screen.dart';
import '../../screens/matches/send_request_screen.dart';
import '../../screens/messages/chat_screen.dart';
import '../../screens/messages/conversations_screen.dart';
import '../../screens/profile/add_skill_screen.dart';
import '../../screens/profile/availability_screen.dart';
import '../../screens/profile/change_password_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/sessions/propose_reschedule_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/ratings/rate_session_screen.dart';
import '../../screens/ratings/user_ratings_screen.dart';
import '../../screens/sessions/session_detail_screen.dart';

/// Bridges Riverpod's AuthState into a Listenable so go_router can react to
/// login/logout by re-running `redirect`.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }
  final Ref _ref;
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = _AuthListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final onAuthScreens =
          loc == '/welcome' || loc == '/login' || loc == '/register';
      final onSplash = loc == '/splash';

      if (auth.status == AuthStatus.initial) {
        return onSplash ? null : '/splash';
      }
      if (!auth.isAuthenticated) {
        return onAuthScreens ? null : '/welcome';
      }
      // Authenticated.
      if (onAuthScreens || onSplash) return '/matches';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const AuthScreen(startOnSignup: true),
      ),

      // Detail screens: full-screen with a back button, no bottom nav.
      GoRoute(
        path: '/users/:userId/ratings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => UserRatingsScreen(
          userId: int.parse(state.pathParameters['userId']!),
        ),
      ),
      GoRoute(
        path: '/sessions/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SessionDetailScreen(
          sessionId: int.parse(state.pathParameters['id']!),
        ),
        routes: [
          GoRoute(
            path: 'rate',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => RateSessionScreen(
              sessionId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: 'reschedule',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => ProposeRescheduleScreen(
              sessionId: int.parse(state.pathParameters['id']!),
            ),
          ),
        ],
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => HomeShell(navigationShell: navigationShell),
        branches: [
          // 0 · Discover
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/matches',
              builder: (context, state) => const MatchesScreen(),
              routes: [
                GoRoute(
                  path: ':userId',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => MatchDetailScreen(
                    userId: int.parse(state.pathParameters['userId']!),
                  ),
                  routes: [
                    GoRoute(
                      path: 'request',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => SendRequestScreen(
                        userId: int.parse(state.pathParameters['userId']!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          // 1 · Search
          StatefulShellBranch(routes: [
            GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
          ]),
          // 2 · Swaps (exchanges + sessions)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/requests',
              builder: (context, state) => const ExchangesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => ExchangeDetailScreen(
                    exchangeId: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
          ]),
          // 3 · Chats
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/messages',
              builder: (context, state) => const ConversationsScreen(),
              routes: [
                GoRoute(
                  path: ':userId',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => ChatScreen(
                    otherUserId: int.parse(state.pathParameters['userId']!),
                  ),
                ),
              ],
            ),
          ]),
          // 4 · Me
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'edit',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const EditProfileScreen(),
                ),
                GoRoute(
                  path: 'skills/add',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const AddSkillScreen(),
                ),
                GoRoute(
                  path: 'availability',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const AvailabilityScreen(),
                ),
                GoRoute(
                  path: 'change-password',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => const ChangePasswordScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
