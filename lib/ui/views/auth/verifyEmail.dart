
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import 'auth_viewmodel.dart';

class EmailVerificationView extends StatefulWidget {
  const EmailVerificationView({Key? key}) : super(key: key);

  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> {
  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AuthViewModel>.reactive(
      viewModelBuilder: () => AuthViewModel(),
      onViewModelReady: (model) {
        model.startVerificationCheckTimer(() {
          if (mounted) {
            locator<NavigationService>().clearStackAndShow(Routes.homeView);
          }
        });
      },
      onDispose: (model) {
        model.cancelVerificationTimer();
      },
      builder: (context, model, child) {
        final displayEmail = model.email.text.isNotEmpty
            ? model.email.text
            : "your email address";

        return Scaffold(
          backgroundColor: const Color(0xFF0F0A1E),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF3B2490), // deep purple top
                  Color(0xFF0F0A1E), // near-black bottom
                ],
                stops: [0.0, 0.4],
              ),
            ),
            child: SafeArea(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // ── Header row: back arrow + progress bar ──────────
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                // Clear stack back to the main login/auth route
                                locator<NavigationService>().clearStackAndShow(Routes.authView);
                              },
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: 0.8, // 80% progress
                                  minHeight: 5,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // ── Title ──────────────────────────────────────────
                        Text(
                          'Verify your Email',
                          style: GoogleFonts.redHatDisplay(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We\'ve sent a verification link to $displayEmail. Please click the link inside the email to activate your account.',
                          style: GoogleFonts.redHatDisplay(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // ── Verification Status Card / Illustration ────────
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.mark_email_unread_outlined,
                                  color: Color(0xFF8B6EF5),
                                  size: 72,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Awaiting Verification',
                                  style: GoogleFonts.redHatDisplay(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'The app will automatically log you in once your email is verified.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.redHatDisplay(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ── Resend Code ────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Didn't get the email? ",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                            GestureDetector(
                              onTap: model.isCountdownActive
                                  ? null
                                  : () async {
                                      await model.sendVerificationEmail();
                                      model.startCountdown();
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Verification link resent!"),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                              child: Text(
                                model.isCountdownActive
                                    ? "Resend in ${model.countdown}s"
                                    : "Resend it.",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8B6EF5), 
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // ── Check Status Button ────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: model.isBusy 
                                ? null
                                : () async {
                                    final isVerified = await model.checkEmailVerificationStatus();
                                    if (!mounted) return;
                                    if (isVerified) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Email verified successfully!"),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      locator<NavigationService>().clearStackAndShow(Routes.homeView);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Email is not verified yet. Please check your inbox."),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B4EE6),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFF6B4EE6).withValues(alpha: 0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: model.isBusy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Check Verification Status',
                                    style: GoogleFonts.redHatDisplay(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}