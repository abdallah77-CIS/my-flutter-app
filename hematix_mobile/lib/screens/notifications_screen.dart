import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/eligibility.dart';
import '../core/theme.dart';
import '../services/donor_api.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await DonorApi.notifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
        _error = null;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  bool _isRead(Map<String, dynamic> n) =>
      n['read'] == true || n['isRead'] == true;

  Future<void> _markRead(Map<String, dynamic> n) async {
    try {
      await DonorApi.markRead(n['notificationId'] ?? n['id']);
      _load();
    } on ApiError catch (e) {
      if (!mounted) return;
      showSnack(context, e.message, error: true);
    }
  }

  Future<void> _markAll() async {
    try {
      await DonorApi.markAllRead();
      if (!mounted) return;
      showSnack(context, 'All notifications marked as read');
      _load();
    } on ApiError catch (e) {
      if (!mounted) return;
      showSnack(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final hasUnread = _items.any((n) => !_isRead(n));

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: _items.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * .65,
                  child: StateBlock(
                    icon: Icons.notifications_none,
                    title: _error ?? 'No notifications',
                    message: _error == null
                        ? 'Updates about your appointments and donations will appear here.'
                        : null,
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                if (hasUnread)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _markAll,
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Mark all as read'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                ..._items.map((n) {
                  final read = _isRead(n);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: read
                                    ? AppColors.border
                                    : AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (n['message'] ??
                                            n['content'] ??
                                            n['title'] ??
                                            '—')
                                        .toString(),
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      height: 1.4,
                                      fontWeight: read
                                          ? FontWeight.w500
                                          : FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    formatDateTime(
                                      n['createdAt'] ?? n['sentAt'],
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.inkFaint,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!read)
                              IconButton(
                                tooltip: 'Mark as read',
                                onPressed: () => _markRead(n),
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
