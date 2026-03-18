import 'package:flutter/material.dart';

import 'app_update_service.dart';

class AutoUpdateGate extends StatefulWidget {
  const AutoUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<AutoUpdateGate> createState() => _AutoUpdateGateState();
}

class _AutoUpdateGateState extends State<AutoUpdateGate> {
  bool _hasChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasChecked) {
      return;
    }

    _hasChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _checkAndPrompt(context);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class UpdateActionButton extends StatefulWidget {
  const UpdateActionButton({super.key});

  @override
  State<UpdateActionButton> createState() => _UpdateActionButtonState();
}

class _UpdateActionButtonState extends State<UpdateActionButton> {
  bool _isChecking = false;

  Future<void> _handlePressed() async {
    if (_isChecking) {
      return;
    }

    setState(() {
      _isChecking = true;
    });

    try {
      final info = await AppUpdateService.instance.checkForUpdate();
      if (!mounted) {
        return;
      }

      if (info == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aplikasi sudah memakai versi terbaru.'),
          ),
        );
        return;
      }

      await _showUpdateDialog(context, info);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memeriksa update: $error'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Periksa Update',
      onPressed: _handlePressed,
      icon: _isChecking
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.system_update_alt),
    );
  }
}

Future<void> _checkAndPrompt(BuildContext context) async {
  try {
    final info = await AppUpdateService.instance.checkForUpdate();
    if (info == null || !context.mounted) {
      return;
    }

    await _showUpdateDialog(context, info);
  } catch (_) {
    // Auto-check failure should not block the app on startup.
  }
}

Future<void> _showUpdateDialog(BuildContext context, AppUpdateInfo info) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: !info.mandatory,
    builder: (dialogContext) {
      return PopScope(
        canPop: !info.mandatory,
        child: AlertDialog(
          title: const Text('Update aplikasi tersedia'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Versi ${info.targetLabel} tersedia. '
                  'Versi saat ini ${info.currentVersion}+${info.currentBuildNumber}.',
                ),
                if (info.publishedAt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Rilis: ${info.publishedAt!.toLocal()}',
                    style: TextStyle(
                      color: Theme.of(
                        dialogContext,
                      ).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (info.notes != null && info.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Catatan update',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(info.notes!.trim()),
                ],
                if (info.mandatory) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Update ini wajib dipasang sebelum aplikasi dipakai lagi.',
                    style: TextStyle(
                      color: Theme.of(dialogContext).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (!info.mandatory)
              TextButton(
                onPressed: () async {
                  await AppUpdateService.instance.dismiss(info);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text('Nanti'),
              ),
            FilledButton.icon(
              onPressed: () async {
                final opened = await AppUpdateService.instance.openUpdate(info);
                if (!dialogContext.mounted) {
                  return;
                }

                if (!opened) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: const Text('Link update tidak bisa dibuka.'),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop();
              },
              icon: const Icon(Icons.download),
              label: Text(info.mandatory ? 'Update Sekarang' : 'Unduh Update'),
            ),
          ],
        ),
      );
    },
  );
}
