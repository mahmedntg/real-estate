import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/errors.dart';
import '../../core/session.dart';
import '../../core/ui.dart';
import '../../data/api.dart';
import '../../l10n/generated/app_localizations.dart';
import 'auth_widgets.dart';

class VerifyPage extends ConsumerStatefulWidget {
  const VerifyPage({
    super.key,
    required this.email,
    this.from = '/',
  });

  final String email;
  final String from;

  @override
  ConsumerState<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends ConsumerState<VerifyPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  bool _submitting = false;
  bool _resending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final localizations = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final session = await ref
          .read(apiProvider)
          .verifyEmail(widget.email, _code.text.trim());
      await ref.read(sessionProvider.notifier).signIn(session.token, session.user);
      if (!mounted) {
        return;
      }
      context.go(widget.from.startsWith('/') ? widget.from : '/');
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _error = error.statusCode == 400
            ? localizations.invalidCode
            : errorText(context, error);
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

  Future<void> _resend() async {
    final localizations = AppLocalizations.of(context);
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      await ref.read(apiProvider).resendCode(widget.email);
      if (!mounted) {
        return;
      }
      setState(() => _resending = false);
      showMessageSnack(context, localizations.codeSent);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _resending = false;
        _error = errorText(context, error);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _resending = false;
        _error = localizations.somethingWentWrong;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final busy = _submitting || _resending;

    return AuthShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHeader(
              title: localizations.verifyEmailTitle,
              subtitle: localizations.verifyEmailSubtitle(widget.email),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: InputDecoration(
                labelText: localizations.verificationCode,
                counterText: '',
                prefixIcon: const Icon(Icons.mark_email_read_outlined),
              ),
              validator: (value) => (value?.trim().length ?? 0) == 6
                  ? null
                  : localizations.codeLength,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              AuthErrorBanner(message: _error!),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: busy ? null : _verify,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(localizations.verify),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: busy ? null : _resend,
              child: _resending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(localizations.resendCode),
            ),
          ],
        ),
      ),
    );
  }
}
