import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../models/user.dart';
import '../screens/auth/login_screen.dart';

class ProfileDrawer extends StatelessWidget {
  final User? user;

  const ProfileDrawer({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          // Get current user from auth state
          final currentUser = state is AuthAuthenticated ? state.user : user;
          final isLoggedIn = currentUser != null;

          final fullName = currentUser?.fullName ?? '';
          final initials = fullName.isNotEmpty ? fullName.substring(0, 1).toUpperCase() : 'G';

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.green,
                ),
                accountName: Text(currentUser?.fullName ?? 'Guest'),
                accountEmail: Text(currentUser?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
              if (isLoggedIn) ...[
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to profile screen
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to settings screen
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    // Dispatch logout event
                    context.read<AuthBloc>().add(const LogoutEvent());
                    // Navigate to login screen and clear navigation stack
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Login'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

