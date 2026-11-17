import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';

/// Overridden in `main()` after `SharedPreferences.getInstance()` completes.
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('prefsProvider must be overridden'),
);

const String _sessionKey = 'session';

class SessionController extends Notifier<Session?> {
  @override
  Session? build() {
    final raw = ref.watch(prefsProvider).getString(_sessionKey);
    if (raw == null) {
      return null;
    }
    try {
      return Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> signIn(String token, User user) async {
    final session = Session(token: token, user: user);
    state = session;
    await ref.read(prefsProvider).setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> updateUser(User user) async {
    final session = state;
    if (session == null) {
      return;
    }
    final updated = Session(token: session.token, user: user);
    state = updated;
    await ref.read(prefsProvider).setString(_sessionKey, jsonEncode(updated.toJson()));
  }

  Future<void> signOut() async {
    if (state == null) {
      return;
    }
    state = null;
    await ref.read(prefsProvider).remove(_sessionKey);
  }
}

final sessionProvider = NotifierProvider<SessionController, Session?>(SessionController.new);

final isSignedInProvider = Provider<bool>((ref) => ref.watch(sessionProvider) != null);
