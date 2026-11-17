import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/format.dart';
import '../../core/session.dart';
import '../../core/settings.dart';
import '../../core/ui.dart';
import '../../data/api.dart';
import '../../data/models.dart';
import '../../l10n/generated/app_localizations.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final session = ref.watch(sessionProvider);
    final settings = ref.watch(settingsProvider);

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(localizations.navProfile)),
        body: Column(
          children: [
            Expanded(
              child: EmptyView(
                icon: Icons.person_outline,
                title: localizations.loginToContinue,
                body: localizations.loginSubtitle,
                actionLabel: localizations.login,
                onAction: () => context.go('/login?from=%2Fme'),
              ),
            ),
            if (kIsWeb)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: TextButton.icon(
                  onPressed: _openApkDownload,
                  icon: const Icon(Icons.android),
                  label: Text(localizations.downloadAndroidApp),
                ),
              ),
          ],
        ),
      );
    }

    final user = session.user;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.navProfile)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: colors.primaryContainer,
                    child: Text(
                      initialOf(user.fullName),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        if (user.role == UserRole.admin) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.tertiaryContainer,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              localizations.admin,
                              style: TextStyle(
                                color: colors.onTertiaryContainer,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: ListTile(
              leading: const Icon(Icons.home_work_outlined),
              title: Text(localizations.myListings),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/listings'),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: ListTile(
              leading: const Icon(Icons.contact_phone_outlined),
              title: Text(localizations.ownerContact),
              subtitle: Text(
                user.phone ?? '',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editContact(context, ref, user),
            ),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colors.outlineVariant),
              ),
              child: ListTile(
                leading: const Icon(Icons.android),
                title: Text(localizations.downloadAndroidApp),
                subtitle: Text(
                  localizations.downloadAndroidAppBody,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.download_outlined),
                onTap: _openApkDownload,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.translate, color: colors.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        localizations.language,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      expandedInsets: EdgeInsets.zero,
                      segments: [
                        ButtonSegment(
                          value: 'en',
                          label: Text(localizations.english),
                        ),
                        ButtonSegment(
                          value: 'ar',
                          label: Text(localizations.arabic),
                        ),
                      ],
                      selected: {settings.localeCode},
                      onSelectionChanged: (selection) => ref
                          .read(settingsProvider.notifier)
                          .setLocale(selection.first),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, color: colors.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        localizations.theme,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      expandedInsets: EdgeInsets.zero,
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(localizations.themeSystem),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(localizations.themeLight),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(localizations.themeDark),
                        ),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (selection) => ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(selection.first),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: Text(localizations.logout),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.error,
              side: BorderSide(color: colors.error.withValues(alpha: 0.6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              await ref.read(sessionProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/');
              }
            },
          ),
        ],
      ),
    );
  }
}

Future<void> _editContact(BuildContext context, WidgetRef ref, User user) async {
  final updated = await showDialog<User>(
    context: context,
    builder: (dialogContext) => _ContactDialog(user: user),
  );
  if (updated == null) {
    return;
  }
  await ref.read(sessionProvider.notifier).updateUser(updated);
  if (context.mounted) {
    showMessageSnack(context, AppLocalizations.of(context).profileUpdated);
  }
}

class _ContactDialog extends ConsumerStatefulWidget {
  const _ContactDialog({required this.user});

  final User user;

  @override
  ConsumerState<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends ConsumerState<_ContactDialog> {
  static final _phonePattern = RegExp(r'^\+?[0-9][0-9\s-]{6,19}$');
  static final _urlPattern = RegExp(r'^https?://.+');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName =
      TextEditingController(text: widget.user.fullName);
  late final TextEditingController _phone =
      TextEditingController(text: widget.user.phone ?? '');
  late final TextEditingController _whatsapp =
      TextEditingController(text: widget.user.whatsapp ?? '');
  late final TextEditingController _facebook =
      TextEditingController(text: widget.user.facebookUrl ?? '');
  bool _saving = false;
  String? _error;
  String? _confirmedPhone;

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _facebook.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final api = ref.read(apiProvider);
      final targetPhone = normalizePhone(_phone.text);
      if (_confirmedPhone != targetPhone &&
          targetPhone != normalizePhone(widget.user.phone ?? '')) {
        final phone = await api.startPhoneChange(targetPhone);
        if (!mounted) {
          return;
        }
        final code = await showDialog<String>(
          context: context,
          builder: (dialogContext) => _CodeDialog(phone: phone),
        );
        if (code == null) {
          setState(() => _saving = false);
          return;
        }
        await api.confirmPhoneChange(phone, code);
        _confirmedPhone = phone;
      }
      final updated = await api.updateProfile(
        fullName: _fullName.text.trim(),
        whatsapp: _whatsapp.text,
        facebookUrl: _facebook.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(updated);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = errorText(context, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(localizations.ownerContact),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _fullName,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(labelText: localizations.fullName),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? localizations.requiredField
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: localizations.phone,
                    helperText: localizations.phoneChangeHint,
                    helperMaxLines: 2,
                  ),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) {
                      return localizations.phoneRequired;
                    }
                    return _phonePattern.hasMatch(phone)
                        ? null
                        : localizations.invalidPhone;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _whatsapp,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: localizations.whatsappNumber,
                  ),
                  validator: (value) {
                    final phone = value?.trim() ?? '';
                    if (phone.isEmpty) {
                      return null;
                    }
                    return _phonePattern.hasMatch(phone)
                        ? null
                        : localizations.invalidPhone;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _facebook,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: localizations.facebookUrl,
                  ),
                  validator: (value) {
                    final url = value?.trim() ?? '';
                    if (url.isEmpty) {
                      return null;
                    }
                    return _urlPattern.hasMatch(url)
                        ? null
                        : localizations.invalidUrl;
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      _error!,
                      style: TextStyle(color: colors.error),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(localizations.saveChanges),
        ),
      ],
    );
  }
}

class _CodeDialog extends StatefulWidget {
  const _CodeDialog({required this.phone});

  final String phone;

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  static final _codePattern = RegExp(r'^[0-9]{6}$');

  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_code.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(localizations.verifyNewNumber),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(localizations.codeSentToNumber(widget.phone)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _code,
                autofocus: true,
                maxLength: 6,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: localizations.verificationCode,
                  counterText: '',
                ),
                validator: (value) => _codePattern.hasMatch(value?.trim() ?? '')
                    ? null
                    : localizations.codeLength,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(localizations.verify),
        ),
      ],
    );
  }
}

Future<void> _openApkDownload() =>
    launchUrl(Uri.base.resolve('/download/aqar.apk'));
