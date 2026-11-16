import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'core/session.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';
import 'features/auth/verify_page.dart';
import 'features/chats/chat_page.dart';
import 'features/chats/chats_page.dart';
import 'features/favorites/favorites_page.dart';
import 'features/home/home_page.dart';
import 'features/listings/listing_editor_page.dart';
import 'features/listings/my_listings_page.dart';
import 'features/profile/profile_page.dart';
import 'features/property/property_page.dart';
import 'features/shell/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authChanges = ValueNotifier<bool>(ref.read(isSignedInProvider));
  ref.listen<bool>(
    isSignedInProvider,
    (previous, next) => authChanges.value = next,
  );

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: authChanges,
    redirect: (context, state) {
      final signedIn = ref.read(isSignedInProvider);
      final location = state.matchedLocation;
      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/verify';
      final isPublic =
          location == '/' || location.startsWith('/property/');

      if (location == '/verify' &&
          (state.uri.queryParameters['email'] ?? '').isEmpty) {
        return '/login';
      }
      if (!signedIn && !isPublic && !isAuthRoute) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/login?from=$from';
      }
      if (signedIn && isAuthRoute) {
        return '/';
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                builder: (context, state) => const ChatsPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) =>
                        ChatPage(id: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/verify',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return VerifyPage(
            email: params['email'] ?? '',
            from: params['from'] ?? '/',
          );
        },
      ),
      GoRoute(
        path: '/property/:id',
        builder: (context, state) =>
            PropertyPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/listings',
        builder: (context, state) => const MyListingsPage(),
      ),
      GoRoute(
        path: '/listings/new',
        builder: (context, state) => const ListingEditorPage(),
      ),
      GoRoute(
        path: '/listings/:id/edit',
        builder: (context, state) =>
            ListingEditorPage(id: state.pathParameters['id']!),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authChanges.dispose();
  });
  return router;
});
