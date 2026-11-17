import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: AppColors.line),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class LoadingPanel extends StatelessWidget {
  const LoadingPanel({super.key, this.message = 'Cargando…'});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 18),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class EmptyPanel extends StatelessWidget {
  const EmptyPanel({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.pets_rounded,
    this.action,
  });
  final String title, message;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: AppColors.mint,
          child: Icon(icon, size: 32, color: const Color(0xFF008F73)),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, height: 1.5),
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_rounded, size: 34, color: AppColors.muted),
        const SizedBox(height: 14),
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Volver a intentar'),
          ),
        ],
      ],
    ),
  );
}

class InlineMessage extends StatelessWidget {
  const InlineMessage(this.message, {super.key, this.isError = true});
  final String message;
  final bool isError;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: isError
          ? Theme.of(context).colorScheme.errorContainer
          : AppColors.mint,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: TextStyle(
          color: isError
              ? Theme.of(context).colorScheme.onErrorContainer
              : AppColors.ink,
        ),
      ),
    ),
  );
}

class AnimalImage extends StatelessWidget {
  const AnimalImage({
    super.key,
    this.url,
    this.height = 180,
    this.width,
    this.label = 'Fotografía de la mascota',
  });
  final String? url;
  final double height;
  final double? width;
  final String label;
  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url ?? '');
    final placeholder = Container(
      color: AppColors.mint,
      alignment: Alignment.center,
      child: const Icon(Icons.pets_rounded, size: 44, color: Color(0xFF79BDA7)),
    );
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: uri?.scheme == 'https'
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                semanticLabel: label,
                errorBuilder: (_, _, _) => placeholder,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : placeholder,
              )
            : placeholder,
      ),
    );
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ) ??
    false;

String friendlyDate(BuildContext context, DateTime value) {
  final date = value.toLocal();
  final localizations = MaterialLocalizations.of(context);
  return '${localizations.formatMediumDate(date)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date))}';
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
