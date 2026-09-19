import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/eligibility.dart';
import '../core/theme.dart';
import '../services/donor_api.dart';
import '../widgets/common.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
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
      final items = await DonorApi.myAppointments();
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

  Future<void> _cancel(Map<String, dynamic> appt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel appointment'),
        content: const Text(
            'Are you sure you want to cancel this donation appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Cancel it',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await DonorApi.cancelAppointment(appt['id'] ?? appt['appointmentId']);
      if (!mounted) return;
      showSnack(context, 'Appointment cancelled');
      _load();
    } on ApiError catch (e) {
      if (!mounted) return;
      showSnack(context, e.message, error: true);
    }
  }

  Future<void> _book() async {
    // Enforce the donation protocol before booking, exactly as the web app
    // does — so an ineligible donor can't schedule a visit that would just
    // be blocked at completion time.
    late Map<String, dynamic> profile;
    try {
      profile = await DonorApi.getProfile();
    } on ApiError catch (e) {
      if (!mounted) return;
      showSnack(context, e.message, error: true);
      return;
    }

    final result = getDonationEligibility(profile);
    if (!result.eligible) {
      if (!mounted) return;
      showSnack(context, result.reasons.join(' '), error: true);
      return;
    }

    if (!mounted) return;
    final booked = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BookSheet(),
    );
    if (booked == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _book,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Book'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: _items.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * .6,
                          child: StateBlock(
                            icon: Icons.event_note_outlined,
                            title: _error ?? 'No appointments yet',
                            message: _error == null
                                ? 'Book a donation appointment and it will appear here.'
                                : null,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final a = _items[i];
                        final status =
                            (a['appointmentStatus'] ?? '').toString().toUpperCase();
                        final canCancel =
                            status == 'PENDING' || status == 'CONFIRMED';
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        formatDateTime(a['appointmentDate']),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    StatusBadge(status),
                                  ],
                                ),
                                if ((a['notes'] ?? '').toString().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    a['notes'].toString(),
                                    style: const TextStyle(
                                      color: AppColors.inkFaint,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                                if (canCancel) ...[
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _cancel(a),
                                      icon: const Icon(Icons.close, size: 17),
                                      label: const Text('Cancel'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

/// Bottom sheet for picking a date + time and submitting the booking.
class _BookSheet extends StatefulWidget {
  const _BookSheet();

  @override
  State<_BookSheet> createState() => _BookSheetState();
}

class _BookSheetState extends State<_BookSheet> {
  DateTime? _date;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  final _notes = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: _date ?? now.add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (_date == null) {
      showSnack(context, 'Please choose a date.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await DonorApi.bookAppointment(
        date: DateTime(
          _date!.year,
          _date!.month,
          _date!.day,
          _time.hour,
          _time.minute,
        ),
        notes: _notes.text.trim(),
      );
      if (!mounted) return;
      showSnack(context, 'Appointment booked successfully');
      Navigator.pop(context, true);
    } on ApiError catch (e) {
      if (!mounted) return;
      showSnack(context, e.message, error: true);
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Book a donation appointment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      _date == null ? 'Pick date' : formatDate(_date),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Confirm booking'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
