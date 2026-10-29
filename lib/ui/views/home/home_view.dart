import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import '../../common/app_colors.dart';
import 'home_viewmodel.dart';
import '../../../state.dart';


class HomeView extends StackedView<HomeViewModel> {
  const HomeView({Key? key}) : super(key: key);

  @override
  void onViewModelReady(HomeViewModel viewModel) {
    uiMode.value = AppUiModes.dark;
    super.onViewModelReady(viewModel);
  }

  @override
  Widget builder(BuildContext context, HomeViewModel viewModel, Widget? child) {

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF3B2490),
            Color(0xFF0F0A1E),
          ],
          stops: [0.0, 0.4],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true, // Crucial so content slips under floating nave
        body: PageView(
          controller: viewModel.pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: viewModel.pages,
        ),
        bottomNavigationBar: _buildFloatingBottomBar(viewModel),
      ),
    );
  }

  Widget _buildFloatingBottomBar(HomeViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: const Color(0xFF151126), // Dark capsule bg
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.home_filled, 'Home', 0, viewModel),
            _buildNavItem(Icons.savings_rounded, 'Goals', 1, viewModel),
            _buildNavItem(Icons.receipt_long_rounded, 'Activity', 2, viewModel),
            _buildNavItem(Icons.person_rounded, 'Profile', 3, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, HomeViewModel viewModel) {
    final isSelected = viewModel.selectedIndex == index;
    final color = isSelected ? const Color(0xFF6B4EE6) : Colors.grey.shade500;

    return GestureDetector(
      onTap: () => viewModel.changeSelectedPage(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.redHatDisplay(
                fontSize: 10,
                color: color,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ] else ...[
              const SizedBox(height: 8), // Keep uniform height
            ]
          ],
        ),
      ),
    );
  }

  @override
  HomeViewModel viewModelBuilder(BuildContext context) => HomeViewModel();
}