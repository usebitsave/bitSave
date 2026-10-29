import 'package:bitSave/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import '../../../state.dart';
import '../../common/app_colors.dart';
import '../../common/ui_helpers.dart';
import '../../dialogs/add_naira_dialog.dart';
import '../../dialogs/bottom_sheets/save_bitcoin_sheet.dart';
import '../../dialogs/bottom_sheets/nostr_transfer_sheet.dart';
import '../transactions/all_transactions_view.dart';
import 'dashboard_viewmodel.dart';

class DashboardView extends StackedView<DashboardViewModel> {
DashboardView({Key? key}) : super(key: key);

  @override
  Widget builder(BuildContext context, DashboardViewModel viewModel, Widget? child) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: _buildBody(context, viewModel),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DashboardViewModel viewModel) {
    return RefreshIndicator(
      onRefresh: () => viewModel.refreshData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        // Add extra padding at the bottom so the floating pill bottom nav doesn't cover content
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildWelcomeHeader(),
            const SizedBox(height: 24),
            _buildUnifiedBitcoinBalanceCard(context, viewModel),
            const SizedBox(height: 20),
            _buildPromoBanner(),
            const SizedBox(height: 32),
            _buildTransactionsSection(context, viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return ValueListenableBuilder(
      valueListenable: profile,
      builder: (context, currentUser, _) {
        // Try firstName first, fall back to fullName, then to the part before @ in the email
        String name = 'Guest';
        if (currentUser.firstName?.isNotEmpty == true) {
          name = currentUser.firstName!;
        } else if (currentUser.username?.isNotEmpty == true) {
          name = currentUser.username!;
        } else if (currentUser.email?.isNotEmpty == true) {
          name = currentUser.email!.split('@').first;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Hi, $name 👋",
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
      },
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

  Widget _buildUnifiedBitcoinBalanceCard(BuildContext context, DashboardViewModel viewModel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      // Dark rounded glassy rectangle
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A22), 
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Background Icon watermark
          Positioned(
            right: -10,
            bottom: 20,
            child: Opacity(
              opacity: 0.03,
              child: Icon(Icons.shopping_bag, size: 140, color: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Flag and Bitcoin pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Naira Wallet',
                      style: GoogleFonts.redHatDisplay(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Account balance text + eye
              Row(
                children: [
                  Text(
                    'Account balance',
                    style: GoogleFonts.redHatDisplay(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.remove_red_eye, color: Colors.white.withValues(alpha: 0.6), size: 18),
                ],
              ),
              const SizedBox(height: 8),
              
              // Balance amount
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₦ ${viewModel.totalBalance.toStringAsFixed(2)}',
                    style: GoogleFonts.redHatDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Builder(
                    builder: (context) {
                      final isPositive = viewModel.todayChange >= 0;
                      final sign = isPositive ? '+' : '';
                      final color = isPositive ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
                      final bgColor = isPositive ? const Color(0xFF1B4D2E) : const Color(0xFF4D1B1B);
                      final icon = isPositive ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: color, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              '$sign${viewModel.todayChange.toStringAsFixed(2)}%',
                              style: GoogleFonts.redHatDisplay(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                         showDialog(
                          context: context,
                          builder: (dialogContext) {
                            final TextEditingController amountController = TextEditingController();
                            return AlertDialog(
                              title: Text(
                                'Add Funds with Paystack',
                                style: GoogleFonts.redHatDisplay(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              content: TextField(
                                controller: amountController,
                                decoration: const InputDecoration(
                                  labelText: 'Amount (NGN)',
                                  prefixText: '₦ ',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final amount = double.tryParse(amountController.text);
                                    if (amount != null && amount > 0) {
                                      Navigator.of(dialogContext).pop();
                                      viewModel.initiatePaystackPayment(amount, context);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B4EE6), foregroundColor: Colors.white),
                                  child: const Text('Continue'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        'Top Up',
                        style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4EE6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        SaveBitcoinSheet.show(context, viewModel);
                      },
                      icon: const Icon(Icons.lock_outline, size: 15),
                      label: Text(
                        'Save',
                        style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38, width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        NostrTransferSheet.show(context, viewModel);
                      },
                      icon: const Icon(Icons.bolt, size: 16, color: Colors.orangeAccent),
                      label: Text(
                        'Send',
                        style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF28243D),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF6B4EE6), width: 1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 16, color: Colors.white),
              const SizedBox(width: 4),
              Container(width: 10, height: 26, color: Colors.blueAccent),
              const SizedBox(width: 4),
              Container(width: 10, height: 36, color: Colors.white),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite friends and earn \$\$\$!',
                  style: GoogleFonts.redHatDisplay(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Refer bitSave to your friends\nand earn rewards',
                  style: GoogleFonts.redHatDisplay(
                    color: Colors.white60,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF6B4EE6), size: 16),
        ],
      ),
    );
  }

  Widget _buildTransactionsSection(BuildContext context, DashboardViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transactions',
              style: GoogleFonts.redHatDisplay(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AllTransactionsView(
                      transactions: viewModel.transactions,
                    ),
                  ),
                );
              },
              child: Text(
                'See all',
                style: GoogleFonts.redHatDisplay(
                  color: const Color(0xFF6B4EE6),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (viewModel.transactions.isEmpty)
          _buildEmptyTransactions()
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: viewModel.transactions.length,
            itemBuilder: (context, index) {
              final transaction = viewModel.transactions[index];
              return _buildTransactionItem(transaction);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
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
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 32,
              color: Color(0xFF6B4EE6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: GoogleFonts.redHatDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your activity will show up here.',
            style: GoogleFonts.redHatDisplay(
              fontSize: 13,
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final bool isNegative = transaction.amount < 0;
    final Color amountColor = isNegative ? const Color(0xFFFF3B30) : const Color(0xFF34C759);

    final String initial = transaction.recipient.isNotEmpty 
        ? transaction.recipient.substring(0, 1).toUpperCase() 
        : "U";

    return InkWell(
      onTap: () => _showTransactionDetails(transaction),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Circular Avatar with small badge
            Stack(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6B4EE6), 
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: GoogleFonts.redHatDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: isNegative ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0F0A1E), width: 2),
                    ),
                    child: Icon(
                      isNegative ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isNegative ? 'Sent to ${transaction.recipient}' : 'Received from ${transaction.recipient}',
                    style: GoogleFonts.redHatDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.date}, ${transaction.time}',
                    style: GoogleFonts.redHatDisplay(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '${isNegative ? '-' : '+'}₦${transaction.amount.abs().toStringAsFixed(2)}',
              style: GoogleFonts.redHatDisplay(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    // Implement transaction details dialog
  }

  void _showSaveDialog(BuildContext context, DashboardViewModel viewModel) {
    SaveBitcoinSheet.show(context, viewModel);
  }

  @override
  DashboardViewModel viewModelBuilder(BuildContext context) => DashboardViewModel();

  @override
  void onViewModelReady(DashboardViewModel viewModel) {
    viewModel.refreshData();
    super.onViewModelReady(viewModel);
  }
}

class _AnimatedAccountTabBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final double borderRadius;

  const _AnimatedAccountTabBar({
    required this.currentIndex,
    required this.onTabChanged,
    this.borderRadius = 30,
  });

  @override
  State<_AnimatedAccountTabBar> createState() => __AnimatedAccountTabBarState();
}

class __AnimatedAccountTabBarState extends State<_AnimatedAccountTabBar> {
  late List<bool> isHoverList = [false, false];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        2,
            (index) {
          return InkWell(
            onTap: () {
              widget.onTabChanged(index);
            },
            onHover: (value) {
              setState(() {
                isHoverList[index] = value;
              });
            },
            child: AnimatedContainer(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.center,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeIn,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                color: widget.currentIndex == index || isHoverList[index]
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300],
              ),
              child: Text(
                ['Fiat Accounts', 'Bitcoin Accounts'][index],
                style: GoogleFonts.redHatDisplay(
                  color: widget.currentIndex == index ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}