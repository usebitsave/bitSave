import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:stacked/stacked.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/models/api_models.dart';
import '../../../services/wallet_service.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.logger.dart';

// ── ViewModel ────────────────────────────────────────────────────────────────
class ActivityViewModel extends BaseViewModel {
  final log = getLogger('ActivityViewModel');
  final _walletService = locator<WalletService>();

  List<BitSaveTransaction> _transactions = [];
  List<BitSaveTransaction> get transactions => _transactions;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    setBusy(true);
    _errorMessage = null;
    try {
      _transactions = await _walletService.fetchTransactions();
    } catch (e) {
      _errorMessage = 'Could not load transactions. Pull to refresh.';
      log.e('ActivityViewModel.init error: $e');
    } finally {
      setBusy(false);
    }
  }

  Future<void> refresh() => init();

  /// Human-readable transaction type label
  String typeLabel(BitSaveTransaction tx) {
    switch (tx.type.toUpperCase()) {
      case 'DEPOSIT':
        return 'Deposit';
      case 'WITHDRAWAL':
        return 'Withdrawal';
      case 'SAVINGS':
        return 'Bitcoin Savings';
      case 'CONVERSION':
        return 'Conversion';
      default:
        return tx.type.isEmpty ? 'Transaction' : tx.type;
    }
  }

  /// Whether the transaction reduces the user's NGN balance
  bool isDebit(BitSaveTransaction tx) {
    return tx.type.toUpperCase() == 'WITHDRAWAL' ||
        tx.type.toUpperCase() == 'SAVINGS';
  }

  /// Status colour
  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF34C759);
      case 'pending':
      case 'awaiting_payment':
      case 'bitcoin_pending':
        return const Color(0xFFFFCC00);
      case 'failed':
      case 'cancelled':
        return const Color(0xFFFF3B30);
      default:
        return Colors.white54;
    }
  }

  /// Friendly status label
  String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'awaiting_payment':
        return 'Awaiting Payment';
      case 'bitcoin_pending':
        return 'BTC Pending';
      case 'payment_received':
        return 'Payment Received';
      case 'conversion_pending':
        return 'Converting';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.isEmpty ? 'Unknown' : status;
    }
  }

  String formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return DateFormat('d MMM yyyy, HH:mm').format(dt.toLocal());
  }

  String formatNgn(String amount) {
    final value = double.tryParse(amount) ?? 0.0;
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '₦${formatter.format(value)}';
  }

  String formatSats(int sats) {
    if (sats == 0) return '—';
    final formatter = NumberFormat('#,###', 'en_US');
    return '${formatter.format(sats)} sats';
  }
}

// ── View ─────────────────────────────────────────────────────────────────────
class ActivityView extends StackedView<ActivityViewModel> {
  const ActivityView({super.key});

  @override
  ActivityViewModel viewModelBuilder(BuildContext context) => ActivityViewModel();

  @override
  void onViewModelReady(ActivityViewModel viewModel) => viewModel.init();

  @override
  Widget builder(BuildContext context, ActivityViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1E),
      body: RefreshIndicator(
        onRefresh: viewModel.refresh,
        color: const Color(0xFF6B4EE6),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            if (viewModel.isBusy)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF6B4EE6)),
                ),
              )
            else if (viewModel.errorMessage != null)
              SliverFillRemaining(
                child: _ErrorState(message: viewModel.errorMessage!),
              )
            else if (viewModel.transactions.isEmpty)
              const SliverFillRemaining(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _TransactionTile(
                      tx: viewModel.transactions[i],
                      viewModel: viewModel,
                    ),
                    childCount: viewModel.transactions.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: const Color(0xFF0F0A1E),
      elevation: 0,
      pinned: true,
      expandedHeight: 110,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity',
              style: GoogleFonts.redHatDisplay(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'All your transactions',
              style: GoogleFonts.redHatDisplay(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction Tile ──────────────────────────────────────────────────────────
class _TransactionTile extends StatelessWidget {
  final BitSaveTransaction tx;
  final ActivityViewModel viewModel;
  const _TransactionTile({required this.tx, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final debit = viewModel.isDebit(tx);
    final amountColor =
        debit ? const Color(0xFFFF3B30) : const Color(0xFF34C759);
    final statusCol = viewModel.statusColor(tx.status);

    return InkWell(
      onTap: () => _showDetails(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: debit
                    ? const Color(0xFFFF3B30).withValues(alpha: 0.15)
                    : const Color(0xFF6B4EE6).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                debit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: debit ? const Color(0xFFFF3B30) : const Color(0xFF6B4EE6),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Label + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    viewModel.typeLabel(tx),
                    style: GoogleFonts.redHatDisplay(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    viewModel.formatDate(tx.createdAt),
                    style: GoogleFonts.redHatDisplay(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Amount + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${debit ? '-' : '+'}${viewModel.formatNgn(tx.fiatAmount)}',
                  style: GoogleFonts.redHatDisplay(
                    color: amountColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusCol.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    viewModel.statusLabel(tx.status),
                    style: GoogleFonts.redHatDisplay(
                      color: statusCol,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1A22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => _TransactionDetailSheet(tx: tx, viewModel: viewModel),
    );
  }
}

// ── Transaction Detail Sheet ──────────────────────────────────────────────────
class _TransactionDetailSheet extends StatelessWidget {
  final BitSaveTransaction tx;
  final ActivityViewModel viewModel;
  const _TransactionDetailSheet({required this.tx, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final debit = viewModel.isDebit(tx);
    final amountColor =
        debit ? const Color(0xFFFF3B30) : const Color(0xFF34C759);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Header
            Text(
              viewModel.typeLabel(tx),
              style: GoogleFonts.redHatDisplay(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${debit ? '-' : '+'}${viewModel.formatNgn(tx.fiatAmount)}',
              style: GoogleFonts.redHatDisplay(
                color: amountColor,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (tx.btcAmountSats > 0) ...[
              const SizedBox(height: 4),
              Text(
                viewModel.formatSats(tx.btcAmountSats),
                style: GoogleFonts.redHatDisplay(
                  color: Colors.white60,
                  fontSize: 15,
                ),
              ),
            ],
            const SizedBox(height: 28),
            _divider(),
            _row('Status', viewModel.statusLabel(tx.status),
                color: viewModel.statusColor(tx.status)),
            _divider(),
            _row('Date', viewModel.formatDate(tx.createdAt)),
            _divider(),
            if (tx.provider.isNotEmpty) ...[
              _row('Provider', tx.provider),
              _divider(),
            ],
            if (tx.providerTransactionId.isNotEmpty) ...[
              _row('Reference', tx.providerTransactionId),
              _divider(),
            ],
            if (tx.idempotencyKey != null &&
                tx.idempotencyKey!.isNotEmpty) ...[
              _row('Idempotency Key', tx.idempotencyKey!),
              _divider(),
            ],
            if (tx.goalId != null && tx.goalId!.isNotEmpty) ...[
              _row('Goal ID', tx.goalId!),
              _divider(),
            ],
            _row('Transaction ID', tx.id),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(color: Colors.white.withValues(alpha: 0.07));

  Widget _row(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.redHatDisplay(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.redHatDisplay(
                color: color ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF6B4EE6).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 40,
                color: Color(0xFF6B4EE6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No transactions yet',
              style: GoogleFonts.redHatDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make your first Bitcoin saving\nto see activity here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.redHatDisplay(
                fontSize: 14,
                color: Colors.white54,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error State ───────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 56, color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.redHatDisplay(
                  color: Colors.white60, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
