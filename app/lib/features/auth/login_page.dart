import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/session.dart';
import '../../core/ui.dart';
import '../../data/api.dart';
import '../../l10n/generated/app_localizations.dart';
import 'auth_widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  bool _needsVerification = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _fillDemo(String email, String password) {
    setState(() {
      _email.text = email;
      _password.text = password;
      _error = null;
    });
  }

  Future<void> _submit() async {
    final localizations = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _needsVerification = false;
    });
    try {
      final session = await ref.read(apiProvider).login(
            _email.text.trim(),
            _password.text,
          );
      await ref.read(sessionProvider.notifier).signIn(session.token, session.user);
      if (!mounted) {
        return;
      }
      final from =
          GoRouterState.of(context).uri.queryParameters['from'] ?? '/';
      context.go(from.startsWith('/') ? from : '/');
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      final message = switch (error.statusCode) {
        401 => localizations.invalidCredentials,
        403 => localizations.emailNotVerified,
        _ => errorText(context, error),
      };
      setState(() {
        _submitting = false;
        _needsVerification = error.statusCode == 403;
        _error = message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _error = localizations.somethingWentWrong;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return AuthShell(
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                title: localizations.welcomeBack,
                subtitle: localizations.loginSubtitle,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: localizations.email,
                  prefixIcon: const Icon(Icons.mail_outline),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) {
                    return localizations.requiredField;
                  }
                  if (!email.contains('@') || !email.contains('.')) {
                    return localizations.invalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: localizations.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscure
                        ? localizations.showPassword
                        : localizations.hidePassword,
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? localizations.requiredField
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                AuthErrorBanner(message: _error!),
              ],
              if (_needsVerification) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _submitting
                      ? null
                      : () {
                          final from = GoRouterState.of(context)
                                  .uri
                                  .queryParameters['from'] ??
                              '/';
                          context.push(
                            Uri(
                              path: '/verify',
                              queryParameters: {
                                'email': _email.text.trim(),
                                if (from.startsWith('/')) 'from': from,
                              },
                            ).toString(),
                          );
                        },
                  icon: const Icon(Icons.mark_email_read_outlined),
                  label: Text(localizations.verifyPrompt),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(localizations.login),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text(localizations.noAccountPrompt)),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => context.push('/register'),
                    child: Text(localizations.register),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                localizations.demoCredentials,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.vpn_key_outlined, size: 18),
                    label: Text(localizations.demoOwner),
                    onPressed: () => _fillDemo('owner@aqar.app', 'Demo@12345'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.vpn_key_outlined, size: 18),
                    label: Text(localizations.demoRenter),
                    onPressed: () => _fillDemo('renter@aqar.app', 'Demo@12345'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
