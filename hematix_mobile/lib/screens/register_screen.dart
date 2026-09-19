import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/eligibility.dart';
import '../core/theme.dart';
import '../services/donor_api.dart';
import '../widgets/common.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  final _age = TextEditingController();
  final _weight = TextEditingController();

  String? _bloodGroup;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  /// Field-level errors returned by the backend, keyed by field name —
  /// mirrors how the web form surfaces server validation.
  Map<String, String> _serverErrors = {};

  @override
  void dispose() {
    for (final c in [
      _username,
      _fullName,
      _email,
      _password,
      _phone,
      _location,
      _age,
      _weight
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await DonorApi.register({
        'username': _username.text.trim(),
        'fullName': _fullName.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'phone': _phone.text.trim(),
        'location': _location.text.trim(),
        'bloodGroup': toApiBloodGroup(_bloodGroup!),
        'age': int.parse(_age.text.trim()),
        'weight': num.parse(_weight.text.trim()),
      });

      if (!mounted) return;
      showSnack(context, 'Account created. Please log in.');
      Navigator.of(context).pop();
    } on ApiError catch (e) {
      setState(() {
        _serverErrors = e.fieldErrors;
        _error = e.message;
      });
      _formKey.currentState!.validate();
    } catch (_) {
      setState(() => _error = 'Registration failed. Please check your details.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm + 2),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    _field(
                      _username,
                      'Username',
                      Icons.person_outline,
                      validator: (v) => (v.length < 3)
                          ? 'Username must be at least 3 characters.'
                          : null,
                    ),
                    _field(
                      _fullName,
                      'Full name',
                      Icons.badge_outlined,
                      validator: (v) =>
                          v.isEmpty ? 'Full name is required.' : null,
                    ),
                    _field(
                      _email,
                      'Email',
                      Icons.mail_outline,
                      keyboard: TextInputType.emailAddress,
                      validator: (v) =>
                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)
                              ? null
                              : 'Enter a valid email address.',
                    ),
                    _passwordField(),
                    _field(
                      _phone,
                      'Phone',
                      Icons.phone_outlined,
                      keyboard: TextInputType.phone,
                      validator: (v) =>
                          v.isEmpty ? 'Phone number is required.' : null,
                    ),
                    _field(
                      _location,
                      'Location',
                      Icons.location_on_outlined,
                      validator: (v) =>
                          v.isEmpty ? 'Location is required.' : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DropdownButtonFormField<String>(
                        // `value` (not `initialValue`) keeps this compiling
                        // on Flutter 3.27–3.34 as well as newer releases.
                        value: _bloodGroup,
                        decoration: InputDecoration(
                          labelText: 'Blood group',
                          prefixIcon:
                              const Icon(Icons.water_drop_outlined, size: 20),
                          errorText: _serverErrors['bloodGroup'],
                        ),
                        items: bloodGroupToApi.keys
                            .map((g) =>
                                DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (v) => setState(() => _bloodGroup = v),
                        validator: (v) =>
                            v == null ? 'Select a blood group.' : null,
                      ),
                    ),
                    _field(
                      _age,
                      'Age',
                      Icons.cake_outlined,
                      keyboard: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v);
                        // Same bounds the web register form enforces.
                        if (n == null || n < 18 || n > 65) {
                          return 'Age must be between 18 and 65.';
                        }
                        return null;
                      },
                    ),
                    _field(
                      _weight,
                      'Weight (kg)',
                      Icons.monitor_weight_outlined,
                      keyboard: TextInputType.number,
                      validator: (v) {
                        final n = num.tryParse(v);
                        if (n == null || n < minDonationWeightKg) {
                          return 'Weight must be at least ${minDonationWeightKg}kg to donate safely.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create account'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    String? Function(String)? validator,
  }) {
    final key = _keyFor(label);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          errorText: _serverErrors[key],
        ),
        validator: (v) => validator?.call((v ?? '').trim()),
      ),
    );
  }

  Widget _passwordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _password,
        obscureText: _obscure,
        decoration: InputDecoration(
          labelText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline, size: 20),
          errorText: _serverErrors['password'],
          suffixIcon: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        validator: (v) => (v == null || v.length < 8)
            ? 'Password must be at least 8 characters.'
            : null,
      ),
    );
  }

  String _keyFor(String label) {
    switch (label) {
      case 'Username':
        return 'username';
      case 'Full name':
        return 'fullName';
      case 'Email':
        return 'email';
      case 'Phone':
        return 'phone';
      case 'Location':
        return 'location';
      case 'Age':
        return 'age';
      case 'Weight (kg)':
        return 'weight';
      default:
        return label.toLowerCase();
    }
  }
}
