import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/auth_state.dart';
import '../core/eligibility.dart';
import '../core/theme.dart';
import '../services/donor_api.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _appointments = [];
  int _unread = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Each call is guarded separately so one failing endpoint (e.g.
    // notifications) doesn't blank out the whole dashboard.
    Map<String, dynamic>? profile;
    List<Map<String, dynamic>> appointments = const [];
    int unread = 0;
    String? error;

    try {
      profile = await DonorApi.getProfile();
    } on ApiError catch (e) {
      error = e.message;
    }

    try {
      appointments = await DonorApi.myAppointments();
    } on ApiError catch (_) {
      // Non-fatal: the rest of the dashboard still renders.
    }

    try {
      unread = (await DonorApi.unreadNotifications()).length;
    } on ApiError catch (_) {
      // Non-fatal.
    }

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _appointments = appointments;
      _unread = unread;
      _error = error;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final p = _profile ?? {};
    final lastDonation = p['lastDonationDate'];
    final nextEligible = computeNextEligibleDate(lastDonation);
    final upcoming = _appointments.where((a) {
      final s = (a['appointmentStatus'] ?? '').toString().toUpperCase();
      return s == 'PENDING' || s == 'CONFIRMED';
    }).toList();
    final completed = _appointments
        .where((a) =>
            (a['appointmentStatus'] ?? '').toString().toUpperCase() ==
            'COMPLETED')
        .length;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const Text(
            'Welcome back,',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.inkFaint,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            auth.displayName,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 20),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(AppRadius.sm + 2),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          _EligibilityBanner(profile: p),
          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: .98,
            children: [
              StatCard(
                icon: Icons.water_drop_outlined,
                label: 'Blood Group',
                value: fromApiBloodGroup(p['bloodGroup']?.toString()).isEmpty
                    ? '—'
                    : fromApiBloodGroup(p['bloodGroup']?.toString()),
              ),
              StatCard(
                icon: Icons.verified_user_outlined,
                label: 'Donor Status',
                valueWidget: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(
                    (p['donorStatus'] ?? p['status'])?.toString(),
                  ),
                ),
              ),
              StatCard(
                icon: Icons.event_available_outlined,
                label: 'Last Donation',
                // A brand-new donor has no lastDonationDate at all; say so
                // explicitly instead of showing a bare dash.
                value: lastDonation == null
                    ? 'No donations yet'
                    : formatDate(lastDonation),
              ),
              StatCard(
                icon: Icons.schedule_outlined,
                label: 'Next Eligible Date',
                value: nextEligible == null
                    ? 'Eligible now'
                    : formatDate(nextEligible),
              ),
              StatCard(
                icon: Icons.volunteer_activism_outlined,
                label: 'Completed Donations',
                value: '$completed',
              ),
              StatCard(
                icon: Icons.notifications_none,
                label: 'Unread Notifications',
                value: '$_unread',
              ),
            ],
          ),

          const SizedBox(height: 22),
          const Text(
            'Upcoming appointment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: upcoming.isEmpty
                  ? const Row(
                      children: [
                        Icon(Icons.event_busy_outlined,
                            color: AppColors.inkFaint, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'No upcoming appointment',
                            style: TextStyle(
                              color: AppColors.inkFaint,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Text(
                            formatDateTime(upcoming.first['appointmentDate']),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        StatusBadge(
                          upcoming.first['appointmentStatus']?.toString(),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Surfaces the full donation protocol result right on the dashboard so the
/// donor knows whether they can book before they try.
class _EligibilityBanner extends StatelessWidget {
  final Map<String, dynamic> profile;
  const _EligibilityBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    final result = getDonationEligibility(profile);
    final eligible = result.eligible;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: eligible ? AppColors.successBg : AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: (eligible ? AppColors.success : AppColors.warning)
              .withValues(alpha: .3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            eligible ? Icons.check_circle_outline : Icons.access_time,
            color: eligible ? AppColors.success : AppColors.warning,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eligible
                      ? "You're eligible to donate"
                      : 'Not yet eligible',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color:
                        eligible ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  eligible
                      ? 'You can book a new donation appointment now.'
                      : result.reasons.join('\n'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.inkSoft,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
