import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/auth_state.dart';
import '../core/eligibility.dart';
import '../core/theme.dart';
import '../services/donor_api.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_phone, _location, _age, _weight]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await DonorApi.getProfile();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
        _error = null;
        _phone.text = (p['phone'] ?? '').toString();
        _location.text = (p['location'] ?? '').toString();
        _age.text = (p['age'] ?? '').toString();
        _weight.text = (p['weight'] ?? '').toString();
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      // Only the fields the backend's update endpoint accepts.
      await DonorApi.updateProfile(
        phone: _phone.text.trim(),
        location: _location.text.trim(),
        age: int.parse(_age.text.trim()),
        weight: num.parse(_weight.text.trim()),
      );
      if (!mounted) return;
      showSnack(context, 'Profile updated successfully');
      setState(() => _editing = false);
      await _load();
    } on ApiError catch (e) {
      if (!mounted) return;
      showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_profile == null) {
      return StateBlock(
        icon: Icons.error_outline,
        title: 'Could not load profile',
        message: _error,
        action: ElevatedButton(onPressed: _load, child: const Text('Retry')),
      );
    }

    final p = _profile!;
    final nextEligible = computeNextEligibleDate(p['lastDonationDate']);

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (!_editing)
                TextButton.icon(
                  onPressed: () => setState(() => _editing = true),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _editing ? _buildForm() : _buildView(p, nextEligible),
            ),
          ),
          const SizedBox(height: 18),
          if (!_editing)
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Log out'),
                    content:
                        const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Log out',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  context.read<AuthState>().logout();
                }
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Log out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildView(Map<String, dynamic> p, DateTime? nextEligible) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoRow(label: 'Username', value: p['username']?.toString()),
        const Divider(height: 1),
        InfoRow(label: 'Full name', value: p['fullName']?.toString()),
        const Divider(height: 1),
        InfoRow(label: 'Email', value: p['email']?.toString()),
        const Divider(height: 1),
        InfoRow(label: 'Phone', value: p['phone']?.toString()),
        const Divider(height: 1),
        InfoRow(label: 'Location', value: p['location']?.toString()),
        const Divider(height: 1),
        InfoRow(
          label: 'Blood group',
          value: fromApiBloodGroup(p['bloodGroup']?.toString()),
        ),
        const Divider(height: 1),
        InfoRow(label: 'Age', value: p['age']?.toString()),
        const Divider(height: 1),
        InfoRow(label: 'Weight (kg)', value: p['weight']?.toString()),
        const Divider(height: 1),
        InfoRow(
          label: 'Donor status',
          child: Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge((p['donorStatus'] ?? p['status'])?.toString()),
          ),
        ),
        const Divider(height: 1),
        InfoRow(
          label: 'Last donation date',
          value: p['lastDonationDate'] == null
              ? 'No donations yet'
              : formatDate(p['lastDonationDate']),
        ),
        const Divider(height: 1),
        InfoRow(
          label: 'Next eligible date',
          value:
              nextEligible == null ? 'Eligible now' : formatDate(nextEligible),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: (v) => (v ?? '').trim().isEmpty
                  ? 'Phone number is required.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(labelText: 'Location'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Location is required.' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n < 18 || n > 65) {
                  return 'Age must be between 18 and 65.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _weight,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              validator: (v) {
                final n = num.tryParse((v ?? '').trim());
                if (n == null || n < minDonationWeightKg) {
                  return 'Weight must be at least ${minDonationWeightKg}kg to donate safely.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save changes'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _saving
                  ? null
                  : () {
                      setState(() => _editing = false);
                      _load();
                    },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
