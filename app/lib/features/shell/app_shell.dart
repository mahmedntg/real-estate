import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/session.dart';
import '../../l10n/generated/app_localizations.dart';
import '../chats/chats_controller.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final signedIn = ref.watch(isSignedInProvider);
    final unread = signedIn
        ? (ref.watch(chatsProvider).value ?? const [])
            .fold<int>(0, (sum, conversation) => sum + conversation.unreadCount)
        : 0;

    Widget chatsIcon(IconData icon) => Badge(
          isLabelVisible: unread > 0,
          label: Text('$unread'),
          child: Icon(icon),
        );

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: localizations.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: localizations.navFavorites,
          ),
          NavigationDestination(
            icon: chatsIcon(Icons.chat_bubble_outline),
            selectedIcon: chatsIcon(Icons.chat_bubble),
            label: localizations.navChats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: localizations.navProfile,
          ),
        ],
      ),
    );
  }
}
