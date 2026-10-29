import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/app.locator.dart';
import '../../../core/data/models/api_models.dart';
import '../../../services/bitcoin_price_service.dart';
import '../../../services/goals_service.dart';
import '../../../services/wallet_service.dart';
import '../../views/dashboard/dashboard_viewmodel.dart';

class SaveBitcoinSheet extends StatefulWidget {
  final DashboardViewModel dashboardViewModel;
  final String? preselectedGoalId;

  const SaveBitcoinSheet({
    super.key,
    required this.dashboardViewModel,
    this.preselectedGoalId,
  });

  static Future<void> show(
    BuildContext context,
    DashboardViewModel viewModel, {
    String? goalId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SaveBitcoinSheet(
        dashboardViewModel: viewModel,
        preselectedGoalId: goalId,
      ),
    );
  }

  @override
  State<SaveBitcoinSheet> createState() => _SaveBitcoinSheetState();
}

enum _SaveStep { input, quote, success }

class _SaveBitcoinSheetState extends State<SaveBitcoinSheet> {
  final _amountController = TextEditingController();
  final _priceService = locator<BitcoinPriceService>();
  final _walletService = locator<WalletService>();
  final _goalsService = locator<GoalsService>();

  _SaveStep _currentStep = _SaveStep.input;
  int _selectedMonths = 3;
  String? _selectedGoalId;
  bool _isLoading = false;

  // Quote data
  BitSaveQuote? _quote;
  int _estimatedSats = 0;
  int _quoteCountdownSeconds = 60;
  Timer? _countdownTimer;

  // Success data
  BitSaveTransaction? _completedTx;

  @override
  void initState() {
    super.initState();
    _selectedGoalId = widget.preselectedGoalId;
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final amt = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    setState(() {
      _estimatedSats = _priceService.ngnToSats(amt);
    });
  }

  void _selectPreset(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
    _onAmountChanged();
  }

  Future<void> _proceedToQuote() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum savings amount is ₦500')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final q = await _walletService.getQuote(amountNgn: amount);
      _quote = q;
      _currentStep = _SaveStep.quote;
      _startQuoteCountdown();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate quote: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startQuoteCountdown() {
    _countdownTimer?.cancel();
    _quoteCountdownSeconds = 60;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_quoteCountdownSeconds <= 1) {
        timer.cancel();
        setState(() => _currentStep = _SaveStep.input);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote expired. Please review and refresh.')),
        );
      } else {
        setState(() => _quoteCountdownSeconds--);
      }
    });
  }

  Future<void> _confirmSave() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    setState(() => _isLoading = true);

    try {
      // 1. Initiate deposit via WalletService
      final tx = await _walletService.initiateDeposit(
        amountNgn: amount,
        quoteId: _quote?.id,
        goalId: _selectedGoalId,
      );

      // 2. Lock to Vault in Dashboard
      if (mounted) {
        await widget.dashboardViewModel.saveToBitcoin(
          amount,
          _selectedMonths,
          context,
        );
      }

      _countdownTimer?.cancel();
      _completedTx = tx;
      setState(() {
        _currentStep = _SaveStep.success;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm savings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFF161320),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentStep == _SaveStep.input
            ? _buildInputStep()
            : _currentStep == _SaveStep.quote
                ? _buildQuoteStep()
                : _buildSuccessStep(),
      ),
    );
  }

  // ── Step 1: Input ──────────────────────────────────────────────────────────
  Widget _buildInputStep() {
    final goals = _goalsService.goals.value;
    final btcRate = _priceService.btcPriceNgn.value;
    final fmt = NumberFormat('#,##0', 'en_US');

    return SingleChildScrollView(
      key: const ValueKey('input_step'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHandle(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Save to Bitcoin',
                style: GoogleFonts.redHatDisplay(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4EE6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Color(0xFF9D84F6), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Live Rate: ₦${fmt.format(btcRate)}',
                      style: GoogleFonts.redHatDisplay(
                        color: const Color(0xFF9D84F6),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Convert Naira into Bitcoin and grow your purchasing power.',
            style: GoogleFonts.redHatDisplay(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Amount Field
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
            style: GoogleFonts.redHatDisplay(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              prefixText: '₦ ',
              prefixStyle: GoogleFonts.redHatDisplay(color: Colors.white54, fontSize: 26),
              hintText: '0',
              hintStyle: GoogleFonts.redHatDisplay(color: Colors.white24, fontSize: 26),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF6B4EE6)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Estimated Sats Preview
          Row(
            children: [
              const Icon(Icons.currency_bitcoin, color: Colors.orangeAccent, size: 16),
              const SizedBox(width: 4),
              Text(
                '≈ ${fmt.format(_estimatedSats)} sats',
                style: GoogleFonts.redHatDisplay(
                  color: Colors.orangeAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Preset Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [5000.0, 10000.0, 25000.0, 50000.0, 100000.0].map((preset) {
                final currentAmount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
                final isSelected = (currentAmount - preset).abs() < 0.01;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _selectPreset(preset),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF6B4EE6) : const Color(0xFF262238),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF9D84F6)
                              : Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '₦${fmt.format(preset)}',
                        style: GoogleFonts.redHatDisplay(
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Lock Duration Selector
          Text(
            'Lock Duration (Vault)',
            style: GoogleFonts.redHatDisplay(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [3, 6, 12].map((m) {
              final isSel = _selectedMonths == m;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedMonths = m),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF6B4EE6) : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? const Color(0xFF6B4EE6) : Colors.white12,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$m Months',
                        style: GoogleFonts.redHatDisplay(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Optional Goal Linking
          if (goals.isNotEmpty) ...[
            Text(
              'Link to Goal (Optional)',
              style: GoogleFonts.redHatDisplay(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedGoalId,
                  dropdownColor: const Color(0xFF1C1A2E),
                  isExpanded: true,
                  hint: Text('Select a savings goal', style: GoogleFonts.redHatDisplay(color: Colors.white38)),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None (General Vault)', style: GoogleFonts.redHatDisplay(color: Colors.white)),
                    ),
                    ...goals.map((g) => DropdownMenuItem<String?>(
                          value: g.id,
                          child: Text('${g.name} (₦${g.targetAmountNgn})', style: GoogleFonts.redHatDisplay(color: Colors.white)),
                        )),
                  ],
                  onChanged: (val) => setState(() => _selectedGoalId = val),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _proceedToQuote,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EE6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Review Quote',
                      style: GoogleFonts.redHatDisplay(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Quote Review ───────────────────────────────────────────────────
  Widget _buildQuoteStep() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final sats = _quote?.btcAmountSats ?? _estimatedSats;
    final fmt = NumberFormat('#,##0', 'en_US');
    final maturity = DateTime.now().add(Duration(days: _selectedMonths * 30));

    return Column(
      key: const ValueKey('quote_step'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHandle(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Confirm Savings Quote',
              style: GoogleFonts.redHatDisplay(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.orangeAccent, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${_quoteCountdownSeconds}s',
                    style: GoogleFonts.redHatDisplay(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Locking in guaranteed exchange rate for 60 seconds.',
          style: GoogleFonts.redHatDisplay(color: Colors.white54, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // Conversion Spotlight Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1A2D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6B4EE6).withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Text(
                'You are locking',
                style: GoogleFonts.redHatDisplay(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                '${fmt.format(sats)} sats',
                style: GoogleFonts.redHatDisplay(
                  color: Colors.orangeAccent,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '≈ ₦${fmt.format(amount)}',
                style: GoogleFonts.redHatDisplay(color: Colors.white70, fontSize: 14),
              ),
              const Divider(color: Colors.white12, height: 28),
              _quoteDetailRow('Lock Duration', '$_selectedMonths Months'),
              const SizedBox(height: 8),
              _quoteDetailRow('Maturity Date', DateFormat('dd MMM yyyy').format(maturity)),
              const SizedBox(height: 8),
              _quoteDetailRow('Exchange Rate', '1 BTC = ₦${fmt.format(_priceService.btcPriceNgn.value)}'),
              const SizedBox(height: 8),
              _quoteDetailRow('Network Fee', '0.00 (Sponsored)'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _countdownTimer?.cancel();
                  setState(() => _currentStep = _SaveStep.input);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.redHatDisplay(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EE6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Confirm & Lock',
                        style: GoogleFonts.redHatDisplay(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 3: Success Confirmation ───────────────────────────────────────────
  Widget _buildSuccessStep() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final sats = _completedTx?.btcAmountSats ?? _estimatedSats;
    final fmt = NumberFormat('#,##0', 'en_US');

    return Column(
      key: const ValueKey('success_step'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHandle(),
        const SizedBox(height: 28),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 48),
        ),
        const SizedBox(height: 20),
        Text(
          'Bitcoin Locked Successfully!',
          style: GoogleFonts.redHatDisplay(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '₦${fmt.format(amount)} converted to ${fmt.format(sats)} sats and secured in your Bitcoin vault.',
          style: GoogleFonts.redHatDisplay(color: Colors.white60, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4EE6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'Done',
              style: GoogleFonts.redHatDisplay(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quoteDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.redHatDisplay(color: Colors.white54, fontSize: 13)),
        Text(
          value,
          style: GoogleFonts.redHatDisplay(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
