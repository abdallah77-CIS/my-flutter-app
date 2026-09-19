import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Colored status pill — the mobile version of statusBadge() in common.js,
/// so a donor's status reads the same on both clients.
class StatusBadge extends StatelessWidget {
  final String? status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final raw = (status ?? '').toUpperCase();
    if (raw.isEmpty) return const Text('—');

    Color fg;
    Color bg;
    switch (raw) {
      case 'APPROVED':
      case 'COMPLETED':
      case 'CONFIRMED':
      case 'FULFILLED':
        fg = AppColors.success;
        bg = AppColors.successBg;
        break;
      case 'PENDING':
        fg = AppColors.warning;
        bg = AppColors.warningBg;
        break;
      case 'REJECTED':
      case 'CANCELLED':
      case 'CANCELED':
      case 'NOT_ELIGIBLE':
        fg = AppColors.danger;
        bg = AppColors.dangerBg;
        break;
      default:
        fg = AppColors.info;
        bg = AppColors.infoBg;
    }

    final label = raw
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashboard metric tile.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(AppRadius.sm + 2),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 14),
            valueWidget ??
                Text(
                  value ?? '—',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.2,
                  ),
                ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.inkFaint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty / error placeholder.
class StateBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const StateBlock({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.inkFaint.withValues(alpha: .6)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.inkFaint,
                  height: 1.45,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

/// Labelled read-only row used in the profile view.
class InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;

  const InfoRow({super.key, required this.label, this.value, this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: .5,
              color: AppColors.inkFaint,
            ),
          ),
          const SizedBox(height: 4),
          child ??
              Text(
                (value == null || value!.isEmpty) ? '—' : value!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
        ],
      ),
    );
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm + 2),
        ),
      ),
    );
}
