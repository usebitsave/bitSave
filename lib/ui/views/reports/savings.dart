import 'package:bitSave/ui/common/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:bitSave/state.dart';
import 'package:intl/intl.dart';
import '../../../models/lock_plan_model.dart';
import '../../../core/data/models/mavapay_models.dart';
import 'Reports_viewmodel.dart';

class Savings extends StatelessWidget {
  const Savings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    uiMode.value = AppUiModes.dark; // Enforce dark

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherited background
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF6B4EE6),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: ViewModelBuilder<ReportsViewModel>.reactive(
        onViewModelReady: (model) => model.init(),
        viewModelBuilder: () => ReportsViewModel(),
        builder: (context, model, child) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildWelcomeHeader(),
                const SizedBox(height: 24),
                
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAccountPill(),
                        const SizedBox(height: 24),
                        _buildUnifiedBalanceCard(context, model),
                        const SizedBox(height: 32),
                        _buildRecommendationsSection(context, model, const Color(0xFF6B4EE6)),
                        const SizedBox(height: 32),
                        _buildOngoingSavingsSection(context, model, const Color(0xFF6B4EE6)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final currentUser = profile.value;
    final name = currentUser.firstName?.isNotEmpty == true
        ? currentUser.firstName
        : "Guest";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Hi, $name",
          style: GoogleFonts.redHatDisplay(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Row(
          children: [
            _buildCircularIconButton(Icons.search_rounded),
            const SizedBox(width: 12),
            _buildCircularIconButton(Icons.notifications_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildCircularIconButton(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildAccountPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.currency_bitcoin, color: Colors.white70, size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            'Bitcoin Account',
            style: GoogleFonts.redHatDisplay(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedBalanceCard(BuildContext context, ReportsViewModel model) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A22), // Matching dashboard card
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Opacity(
              opacity: 0.03,
              child: const Icon(Icons.currency_bitcoin, size: 150, color: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.currency_bitcoin, color: Colors.orange, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Sat',
                      style: GoogleFonts.redHatDisplay(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Account balance',
                    style: GoogleFonts.redHatDisplay(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.visibility_outlined, color: Colors.white38, size: 18),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  _buildBitcoinSavingsTotal(model),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline, color: Colors.greenAccent, size: 10),
                        const SizedBox(width: 2),
                        Text(
                          'Locked',
                          style: GoogleFonts.redHatDisplay(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showGeneralWithdrawDialog(context, model);
                  },
                  icon: const Icon(Icons.send_outlined, size: 18, color: Colors.white),
                  label: Text(
                    'Withdraw',
                    style: GoogleFonts.redHatDisplay(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EE6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(BuildContext context, ReportsViewModel model, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recommendations",
              style: GoogleFonts.redHatDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: () => model.showMoreOptions(),
              child: Row(
                children: [
                  Text(
                    "More options",
                    style: GoogleFonts.redHatDisplay(
                      fontSize: 14,
                      color: const Color(0xFF6B4EE6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF6B4EE6)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            children: [
              _buildRecommendationCard(context, model, "₦5000", "Buying Car", "3 MONTHS", "17 days left", const Color(0xFF6B4EE6), 5000.0, 3),
              const SizedBox(width: 12),
              _buildRecommendationCard(context, model, "₦5000", "Buying House", "6 MONTHS", "Tomorrow", Colors.orange, 5000.0, 6),
              const SizedBox(width: 12),
              _buildRecommendationCard(context, model, "₦5000", "Others", "3 MONTHS", "17 days left", Colors.blue, 5000.0, 3),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    ReportsViewModel model,
    String amountStr,
    String purpose,
    String durationStr,
    String subtext,
    Color color,
    double amount,
    int durationMonths,
  ) {
    return GestureDetector(
      onTap: () {
        _showRecommendationConfirmDialog(context, model, amount, purpose, durationMonths);
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  amountStr,
                  style: GoogleFonts.redHatDisplay(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purpose,
                  style: GoogleFonts.redHatDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      durationStr,
                      style: GoogleFonts.redHatDisplay(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtext,
                        style: GoogleFonts.redHatDisplay(
                          fontSize: 9,
                          color: Colors.white38,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOngoingSavingsSection(BuildContext context, ReportsViewModel model, Color primaryColor) {
    final filteredPlans = model.savingsPlans.where((plan) {
      final daysLeft = plan.targetMaturityDate.difference(DateTime.now()).inDays;
      if (model.selectedTab == 0) {
        return daysLeft > 0;
      } else {
        return daysLeft <= 0;
      }
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => model.setSelectedTab(0),
                child: Column(
                  children: [
                    Text(
                      "Ongoing",
                      style: GoogleFonts.redHatDisplay(
                        color: model.selectedTab == 0 ? const Color(0xFF6B4EE6) : Colors.white38,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 2,
                      color: model.selectedTab == 0 ? const Color(0xFF6B4EE6) : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => model.setSelectedTab(1),
                child: Column(
                  children: [
                    Text(
                      "Matured",
                      style: GoogleFonts.redHatDisplay(
                        color: model.selectedTab == 1 ? const Color(0xFF6B4EE6) : Colors.white38,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 2,
                      color: model.selectedTab == 1 ? const Color(0xFF6B4EE6) : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (filteredPlans.isEmpty)
          _buildEmptySavings(model.selectedTab)
        else
          Column(
            children: filteredPlans.map((plan) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSavingsCardFromPlan(context, model, plan),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildEmptySavings(int tabIndex) {
    final title = tabIndex == 0 ? 'No ongoing savings' : 'No matured savings';
    final desc = tabIndex == 0
        ? 'Tap a recommendation card or save from your dashboard to start saving in Bitcoin!'
        : 'Your active savings will appear here once they complete their lock duration.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF6B4EE6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.savings_outlined, size: 32, color: Color(0xFF6B4EE6)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.redHatDisplay(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: GoogleFonts.redHatDisplay(fontSize: 13, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildBitcoinSavingsTotal(ReportsViewModel model) {
    final formattedSats = NumberFormat.decimalPattern().format(model.totalSavingsSats);
    return Text(
      '$formattedSats sats',
      style: GoogleFonts.redHatDisplay(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSavingsCardFromPlan(BuildContext context, ReportsViewModel model, LockPlanModel plan) {
    final daysLeft = plan.targetMaturityDate.difference(DateTime.now()).inDays;
    final totalDays = plan.targetMaturityDate.difference(plan.createdAt).inDays;
    final progress = totalDays > 0 ? (1.0 - (daysLeft / totalDays)).clamp(0.0, 1.0) : 1.0;
    final months = (totalDays / 30).round();
    final formattedSats = NumberFormat.decimalPattern().format(plan.satsAllocated);

    return InkWell(
      onTap: () {
        if (daysLeft <= 0) {
          _showWithdrawDetailsDialog(context, model, plan);
        } else {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text('Savings Plan Details', style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.bold)),
              content: Text(
                'This plan is locked until ${DateFormat('yyyy-MM-dd HH:mm').format(plan.targetMaturityDate)}.\n\n'
                'Locked Amount: ₦${plan.fiatAmountNGN.toStringAsFixed(2)} ($formattedSats sats)\n'
                'Remaining Time: $daysLeft days left.',
                style: GoogleFonts.redHatDisplay(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF252136),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF6B4EE6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF6B4EE6).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.currency_bitcoin, color: Color(0xFF6B4EE6), size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$formattedSats sats',
                        style: GoogleFonts.redHatDisplay(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: daysLeft <= 0
                              ? Colors.green.withValues(alpha: 0.2)
                              : const Color(0xFF6B4EE6).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          daysLeft <= 0 ? 'Matured' : '$daysLeft days left',
                          style: GoogleFonts.redHatDisplay(
                            color: daysLeft <= 0 ? Colors.greenAccent : const Color(0xFF6B4EE6),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₦${plan.fiatAmountNGN.toStringAsFixed(0)}',
                        style: GoogleFonts.redHatDisplay(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Duration $months Months',
                        style: GoogleFonts.redHatDisplay(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% complete',
                        style: GoogleFonts.redHatDisplay(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      daysLeft <= 0 ? Colors.greenAccent : const Color(0xFF6B4EE6),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGeneralWithdrawDialog(BuildContext context, ReportsViewModel model) {
    final maturedPlans = model.savingsPlans
        .where((plan) => plan.targetMaturityDate.difference(DateTime.now()).inDays <= 0)
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        if (model.savingsPlans.isEmpty) {
          return AlertDialog(
            title: Text('Withdraw Savings', style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.bold)),
            content: Text('You have no savings plans to withdraw.', style: GoogleFonts.redHatDisplay()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        }

        if (maturedPlans.isEmpty) {
          return AlertDialog(
            title: Text('Withdraw Savings', style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.bold)),
            content: Text('You have no matured savings available for withdrawal. Only matured savings can be withdrawn.', style: GoogleFonts.redHatDisplay()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        }

        return AlertDialog(
          title: Text('Select Matured Plan', style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: maturedPlans.length,
              itemBuilder: (context, index) {
                final plan = maturedPlans[index];
                final formattedSats = NumberFormat.decimalPattern().format(plan.satsAllocated);
                return ListTile(
                  title: Text('$formattedSats sats (₦${plan.fiatAmountNGN.toStringAsFixed(0)})'),
                  subtitle: Text('Locked on ${DateFormat('yyyy-MM-dd').format(plan.createdAt)}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    _showWithdrawDetailsDialog(context, model, plan);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showWithdrawDetailsDialog(BuildContext context, ReportsViewModel model, LockPlanModel plan) {
    final accountController = TextEditingController();
    final bankCodeController = TextEditingController(text: "011"); // Default First Bank for test/demo

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Withdraw Details',
            style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter bank details to withdraw ₦${plan.fiatAmountNGN.toStringAsFixed(2)} (${NumberFormat.decimalPattern().format(plan.satsAllocated)} sats)',
                style: GoogleFonts.redHatDisplay(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: accountController,
                decoration: const InputDecoration(
                  labelText: 'Bank Account Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bankCodeController,
                decoration: const InputDecoration(
                  labelText: 'Bank Code (e.g. 011)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final accountNumber = accountController.text.trim();
                final bankCode = bankCodeController.text.trim();
                if (accountNumber.isNotEmpty && bankCode.isNotEmpty) {
                  Navigator.of(dialogContext).pop();
                  model.withdrawLockPlan(plan, accountNumber, bankCode, context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EE6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Withdraw'),
            ),
          ],
        );
      },
    );
  }

  void _showRecommendationConfirmDialog(
    BuildContext context,
    ReportsViewModel model,
    double amount,
    String purpose,
    int durationMonths,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            'Confirm Savings Plan',
            style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Do you want to save ₦${amount.toStringAsFixed(0)} for "$purpose" locked for $durationMonths months?',
            style: GoogleFonts.redHatDisplay(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                model.saveToBitcoin(amount, durationMonths, context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EE6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm & Save'),
            ),
          ],
        );
      },
    );
  }
}