import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app.locator.dart';
import '../../../app/app.logger.dart';
import '../../../app/app.router.dart';
import '../../../core/utils/local_store_dir.dart';
import '../../../core/utils/local_stotage.dart';
import '../../../services/authentication_service.dart';
import '../../../state.dart';
import '../../../core/data/models/user_model.dart';
import '../../dialogs/bottom_sheets/nostr_transfer_sheet.dart';
import '../dashboard/dashboard_viewmodel.dart';
import '../auth/auth_view.dart';

// ── ViewModel ────────────────────────────────────────────────────────────────
class ProfileViewModel extends BaseViewModel {
  final log = getLogger('ProfileViewModel');
  final _authService = locator<AuthenticationService>();
  final _snackbar = locator<SnackbarService>();
  final _navigation = locator<NavigationService>();

  String get userEmail =>
      _authService.apiProfile?.email ??
      _authService.currentUser?.email ??
      '—';

  String get displayName {
    final name = _authService.currentUser?.fullName ?? '';
    if (name.isNotEmpty) return name;
    final email = userEmail;
    return email.contains('@') ? email.split('@').first : email;
  }

  String get memberSince {
    final dt = _authService.apiProfile?.createdAt ??
        _authService.currentUser?.createdAt;
    if (dt == null) return '—';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  void copyEmail() {
    Clipboard.setData(ClipboardData(text: userEmail));
    _snackbar.showSnackbar(
      message: 'Email copied to clipboard.',
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> launchSupport() async {
    final uri = Uri.parse('mailto:support@bitsave.io');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _snackbar.showSnackbar(message: 'Could not open mail app.');
    }
  }

  Future<void> launchPrivacyPolicy() async {
    final uri = Uri.parse('https://bitsave.io/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> launchTerms() async {
    final uri = Uri.parse('https://bitsave.io/terms');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> logout() async {
    setBusy(true);
    try {
      await _authService.logout();
      final ls = locator<LocalStorage>();
      await ls.delete(LocalStorageDir.authUser);
      await ls.delete(LocalStorageDir.authToken);
      profile.value = User();
      userLoggedIn.value = false;
      _navigation.clearStackAndShow(
        Routes.authView,
        arguments: const AuthViewArguments(authType: AuthType.login),
      );
    } catch (e) {
      _snackbar.showSnackbar(message: 'Logout failed. Try again.');
    } finally {
      setBusy(false);
    }
  }
}

// ── View ─────────────────────────────────────────────────────────────────────
class ProfileView extends StackedView<ProfileViewModel> {
  const ProfileView({super.key});

  @override
  ProfileViewModel viewModelBuilder(BuildContext context) => ProfileViewModel();

  @override
  Widget builder(
      BuildContext context, ProfileViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              const SizedBox(height: 12),
              Text(
                'Profile',
                style: GoogleFonts.redHatDisplay(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 28),

              // ── Avatar + Name card ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1A22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6B4EE6),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          viewModel.displayName.isNotEmpty
                              ? viewModel.displayName[0].toUpperCase()
                              : 'U',
                          style: GoogleFonts.redHatDisplay(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            viewModel.displayName,
                            style: GoogleFonts.redHatDisplay(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            viewModel.userEmail,
                            style: GoogleFonts.redHatDisplay(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Member since ${viewModel.memberSince}',
                            style: GoogleFonts.redHatDisplay(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded,
                          size: 18, color: Colors.white38),
                      onPressed: viewModel.copyEmail,
                      tooltip: 'Copy email',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Account Settings ──
              _sectionTitle('Account'),
              const SizedBox(height: 12),
              _SettingsCard(items: [
                _SettingsItem(
                  icon: Icons.lock_outline_rounded,
                  label: 'Security',
                  sublabel: 'Password & PIN settings',
                  onTap: () => _comingSoon(context),
                ),
                _SettingsItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  sublabel: 'Manage alerts and reminders',
                  onTap: () => _comingSoon(context),
                ),
              ]),

              const SizedBox(height: 24),

              // ── Wallet Info ──
              _sectionTitle('Wallet'),
              const SizedBox(height: 12),
              _SettingsCard(items: [
                _SettingsItem(
                  icon: Icons.bolt_rounded,
                  label: 'Nostr & Lightning Transfer',
                  sublabel: 'Send Bitcoin to any address or Nostr npub',
                  onTap: () {
                    final vm = DashboardViewModel();
                    NostrTransferSheet.show(context, vm);
                  },
                ),
                _SettingsItem(
                  icon: Icons.currency_bitcoin_rounded,
                  label: 'Bitcoin Wallet Info',
                  sublabel: 'Powered by Breez SDK Liquid',
                  onTap: () => _comingSoon(context),
                ),
                _SettingsItem(
                  icon: Icons.backup_rounded,
                  label: 'Wallet Backup',
                  sublabel: 'Keep your recovery phrase safe',
                  onTap: () => _showWalletBackupInfo(context),
                ),
              ]),

              const SizedBox(height: 24),

              // ── Support & Legal ──
              _sectionTitle('Support & Legal'),
              const SizedBox(height: 12),
              _SettingsCard(items: [
                _SettingsItem(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  sublabel: 'Contact the bitSave team',
                  onTap: viewModel.launchSupport,
                ),
                _SettingsItem(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: viewModel.launchPrivacyPolicy,
                ),
                _SettingsItem(
                  icon: Icons.article_outlined,
                  label: 'Terms of Service',
                  onTap: viewModel.launchTerms,
                ),
              ]),

              const SizedBox(height: 28),

              // ── Logout ──
              GestureDetector(
                onTap: viewModel.isBusy ? null : viewModel.logout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (viewModel.isBusy)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.redAccent),
                        )
                      else ...[
                        const Icon(Icons.logout_rounded,
                            color: Colors.redAccent, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Log Out',
                          style: GoogleFonts.redHatDisplay(
                            color: Colors.redAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: Text(
                  'bitSave v1.0.0 • Hackathon Build',
                  style: GoogleFonts.redHatDisplay(
                    color: Colors.white24,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.redHatDisplay(
        color: Colors.white60,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1C1A22),
        content: Text(
          'Coming soon.',
          style: GoogleFonts.redHatDisplay(color: Colors.white70),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showWalletBackupInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1A22),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Wallet Backup',
          style: GoogleFonts.redHatDisplay(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Your Bitcoin wallet is managed by the Breez SDK Liquid. '
          'During wallet setup, a 12-word recovery phrase will be generated.\n\n'
          'Write it down on paper and store it somewhere safe. '
          'Anyone with this phrase can access your Bitcoin.\n\n'
          'bitSave does not store or have access to your recovery phrase.',
          style: GoogleFonts.redHatDisplay(
            color: Colors.white70,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4EE6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Got it',
              style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Settings Card ─────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<_SettingsItem> items;
  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B4EE6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon,
                      color: const Color(0xFF6B4EE6), size: 18),
                ),
                title: Text(
                  item.label,
                  style: GoogleFonts.redHatDisplay(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: item.sublabel != null
                    ? Text(
                        item.sublabel!,
                        style: GoogleFonts.redHatDisplay(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      )
                    : null,
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white24, size: 14),
                onTap: () => item.onTap(),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
              ),
              if (i < items.length - 1)
                Divider(
                  color: Colors.white.withValues(alpha: 0.06),
                  height: 1,
                  indent: 68,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final String? sublabel;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.sublabel,
    required this.onTap,
  });
}