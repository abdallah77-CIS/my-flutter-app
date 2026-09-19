import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/auth_state.dart';
import 'core/theme.dart';
import 'screens/donor_shell.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const HematixApp());
}

class HematixApp extends StatelessWidget {
  const HematixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthState(),
      child: MaterialApp(
        title: 'Hematix — Donor',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _Root(),
      ),
    );
  }
}

/// Swaps between the login screen and the donor shell based on session state.
/// A stored JWT is restored on launch, so a returning donor skips login.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();

    if (auth.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return auth.isLoggedIn ? const DonorShell() : const LoginScreen();
  }
}
