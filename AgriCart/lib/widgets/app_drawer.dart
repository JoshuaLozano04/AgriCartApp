import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user.dart';

class AppDrawer extends StatelessWidget {
  final User? user;
  final VoidCallback? onLogout;
  final VoidCallback? onProfileTap;

  const AppDrawer({
    super.key,
    this.user,
    this.onLogout,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false, // allow header to paint under the top inset so no white strip shows
        child: Column(
          children: [
            // Header
            ClipRRect(
              borderRadius: const BorderRadius.only(topRight: Radius.circular(16)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.white,
                      child: Text(
                        (user?.fullName.isNotEmpty == true
                            ? user!.fullName.substring(0, 1).toUpperCase()
                            : 'U'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                      Text(
                        user?.fullName ?? 'User',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user?.email != null)
                        Text(
                          user!.email,
                          style: TextStyle(
                            color: AppTheme.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                    if (user?.isVerified == true)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: AppTheme.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (onProfileTap != null)
                    ListTile(
                      leading: const Icon(Icons.person, color: AppTheme.primaryGreen),
                      title: const Text('Profile'),
                      onTap: onProfileTap,
                    ),
                  ListTile(
                    leading: const Icon(Icons.settings, color: AppTheme.primaryGreen),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to settings
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline, color: AppTheme.primaryGreen),
                    title: const Text('Help & Support'),
                    onTap: () {
                      Navigator.pop(context);
                      // Navigate to help
                    },
                  ),
                  const Divider(),
                  if (onLogout != null)
                    ListTile(
                      leading: const Icon(Icons.logout, color: AppTheme.errorRed),
                      title: const Text(
                        'Logout',
                        style: TextStyle(color: AppTheme.errorRed),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        onLogout?.call();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

