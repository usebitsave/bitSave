import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'onboarding_viewmodel.dart';

class OnboardingView extends StackedView<OnboardingViewModel> {
  const OnboardingView({Key? key}) : super(key: key);

  @override
  Widget builder(
    BuildContext context,
    OnboardingViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.45, 0.85],
            colors: [
              Color(0xFF2C1977),
              Color(0xFF130B30),
              Color(0xFF06030A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: viewModel.pageController,
                  onPageChanged: viewModel.setIndex,
                  children: const [
                    OnboardingPageItem(
                      imagePath: 'assets/images/save_smarter_btc.png',
                      normalText: "Save smarter with ",
                      highlightedText: "Bitcoin.",
                      subtitle:
                          "Turn your local currency into Bitcoin and build your savings for the long term.",
                    ),
                    OnboardingPageItem(
                      imagePath: 'assets/images/sats_growth.png',
                      normalText: "Save Today.\n",
                      highlightedText: "Grow for Tomorrow.",
                      subtitle:
                          "Turn your local currency into Bitcoin and build your savings for the long term.",
                    ),
                    OnboardingPageItem(
                      imagePath: 'assets/images/save_smarter_btc.png',
                      normalText: "Lock & Build\n",
                      highlightedText: "Your Wealth.",
                      subtitle:
                          "Secure your assets with confidence and track your portfolio growth effortlessly.",
                    ),
                  ],
                ),
              ),
              _buildPageIndicator(viewModel.currentIndex),
              const SizedBox(height: 32),
              _buildActionButtons(viewModel),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int currentIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = currentIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: isActive ? 28 : 6,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF7D5BFF) : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _buildActionButtons(OnboardingViewModel viewModel) {
    final isLastPage = viewModel.currentIndex == 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLastPage ? viewModel.navigateToSignup : viewModel.nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C32AD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                isLastPage ? 'Get Started' : 'Next',
                style: GoogleFonts.redHatDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLastPage ? viewModel.navigateToLogin : viewModel.skip,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2738),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                isLastPage ? 'Log In' : 'Skip',
                style: GoogleFonts.redHatDisplay(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  OnboardingViewModel viewModelBuilder(BuildContext context) =>
      OnboardingViewModel();
}

class OnboardingPageItem extends StatelessWidget {
  final String imagePath;
  final String normalText;
  final String highlightedText;
  final String subtitle;

  const OnboardingPageItem({
    Key? key,
    required this.imagePath,
    required this.normalText,
    required this.highlightedText,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 1),
          Center(
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              height: 260,
            ),
          ),
          const Spacer(flex: 1),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.redHatDisplay(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
              children: [
                TextSpan(
                  text: normalText,
                  style: const TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: highlightedText,
                  style: const TextStyle(color: Color(0xFF7D5BFF)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.redHatDisplay(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF9E9CA7),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
