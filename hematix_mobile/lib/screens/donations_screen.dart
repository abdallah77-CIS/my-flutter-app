import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/eligibility.dart';
import '../core/theme.dart';
import '../services/donor_api.dart';
import '../widgets/common.dart';

class DonationsScreen extends StatefulWidget {
  const DonationsScreen({super.key});

  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen> {
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
      final items = await DonorApi.myDonations();
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: _items.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * .65,
                  child: StateBlock(
                    icon: Icons.volunteer_activism_outlined,
                    title: _error ?? 'No donations yet',
                    // A new donor legitimately has no records — explain that
                    // rather than looking like a failed load.
                    message: _error == null
                        ? "You haven't completed any donations yet. Once an appointment is marked complete, it will show up here."
                        : null,
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final d = _items[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTint,
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm + 2),
                          ),
                          child: const Icon(
                            Icons.water_drop,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formatDate(d['donationDate']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${d['units'] ?? '—'} unit(s)'
                                '${(d['notes'] ?? '').toString().isNotEmpty ? ' • ${d['notes']}' : ''}',
                                style: const TextStyle(
                                  color: AppColors.inkFaint,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
