import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app.locator.dart';
import '../../../services/bitcoin_price_service.dart';
import '../../../services/nostr_bitcoin_service.dart';
import '../../views/dashboard/dashboard_viewmodel.dart';

class NostrTransferSheet extends StatefulWidget {
  final DashboardViewModel dashboardViewModel;

  const NostrTransferSheet({
    super.key,
    required this.dashboardViewModel,
  });

  static Future<void> show(BuildContext context, DashboardViewModel viewModel) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NostrTransferSheet(dashboardViewModel: viewModel),
    );
  }

  @override
  State<NostrTransferSheet> createState() => _NostrTransferSheetState();
}

class _NostrTransferSheetState extends State<NostrTransferSheet> {
  final _addressController = TextEditingController();
  final _satsController = TextEditingController();
  final _memoController = TextEditingController();

  final _nostrService = locator<NostrBitcoinService>();
  final _priceService = locator<BitcoinPriceService>();

  BitcoinAddressType _detectedType = BitcoinAddressType.unknown;
  NostrProfile? _resolvedProfile;
  bool _isResolvingProfile = false;
  bool _isLoading = false;
  NostrTransferResult? _transferResult;

  double _fiatAmountNgn = 0.0;

  @override
  void initState() {
    super.initState();
    _addressController.addListener(_onAddressChanged);
    _satsController.addListener(_onSatsChanged);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _satsController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _onAddressChanged() {
    final text = _addressController.text.trim();
    final type = _nostrService.detectAddressType(text);
    if (type != _detectedType) {
      setState(() {
        _detectedType = type;
        _resolvedProfile = null;
      });
    }

    if (type == BitcoinAddressType.nostrNpub && !_isResolvingProfile && _resolvedProfile == null) {
      _resolveNostrProfile(text);
    }
  }

  Future<void> _resolveNostrProfile(String npub) async {
    setState(() => _isResolvingProfile = true);
    final profile = await _nostrService.fetchNostrProfile(npub);
    if (mounted) {
      setState(() {
        _resolvedProfile = profile;
        _isResolvingProfile = false;
      });
    }
  }

  void _onSatsChanged() {
    final sats = int.tryParse(_satsController.text.replaceAll(',', '')) ?? 0;
    setState(() {
      _fiatAmountNgn = _priceService.satsToNgn(sats);
    });
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      _addressController.text = data.text!.trim();
    }
  }

  void _selectPresetSats(int sats) {
    _satsController.text = sats.toString();
    _onSatsChanged();
  }

  Future<void> _executeTransfer() async {
    final address = _addressController.text.trim();
    final sats = int.tryParse(_satsController.text.replaceAll(',', '')) ?? 0;

    if (address.isEmpty || _detectedType == BitcoinAddressType.unknown) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Bitcoin address, Lightning address, or Nostr npub.')),
      );
      return;
    }

    if (sats <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount of Satoshis to send.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _nostrService.sendBitcoin(
        destinationAddress: address,
        satsAmount: sats,
        memo: _memoController.text.trim().isNotEmpty ? _memoController.text.trim() : null,
      );

      if (mounted) {
        setState(() {
          _transferResult = result;
        });

        if (result.isSuccess) {
          // Refresh transactions and balances
          widget.dashboardViewModel.refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.errorMessage ?? 'Transfer failed')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
      child: _transferResult != null && _transferResult!.isSuccess
          ? _buildSuccessView()
          : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    final fmt = NumberFormat('#,##0', 'en_US');

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHandle(),
          const SizedBox(height: 16),

          // Header with Nostr Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transfer Bitcoin',
                style: GoogleFonts.redHatDisplay(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF9D84F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6B4EE6).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Color(0xFF9D84F6), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Nostr & Lightning',
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
          const SizedBox(height: 6),
          Text(
            'Send Bitcoin to any Bitcoin address, Lightning address, or Nostr npub.',
            style: GoogleFonts.redHatDisplay(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Recipient Address Field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recipient Address',
                style: GoogleFonts.redHatDisplay(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              _buildAddressTypeBadge(),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            style: GoogleFonts.redHatDisplay(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'bc1q..., satoshi@domain, or npub1...',
              hintStyle: GoogleFonts.redHatDisplay(color: Colors.white24, fontSize: 14),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              prefixIcon: const Icon(Icons.alternate_email, color: Colors.white38, size: 18),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_paste_rounded, color: Color(0xFF9D84F6), size: 20),
                onPressed: _pasteFromClipboard,
                tooltip: 'Paste from clipboard',
              ),
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

          // Resolved Nostr Profile Card
          if (_isResolvingProfile) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF9D84F6))),
                SizedBox(width: 8),
                Text('Looking up Nostr profile on relays...', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ] else if (_resolvedProfile != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF221D33),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6B4EE6).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF6B4EE6),
                    backgroundImage: _resolvedProfile?.picture != null && _resolvedProfile!.picture!.isNotEmpty
                        ? NetworkImage(_resolvedProfile!.picture!)
                        : null,
                    child: _resolvedProfile?.picture == null
                        ? const Icon(Icons.person, color: Colors.white, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _resolvedProfile?.displayName ?? _resolvedProfile?.name ?? 'Nostr User',
                          style: GoogleFonts.redHatDisplay(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (_resolvedProfile?.lud16 != null)
                          Text(
                            '⚡ ${_resolvedProfile!.lud16}',
                            style: GoogleFonts.redHatDisplay(color: Colors.orangeAccent, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // Amount in Satoshis
          Text(
            'Amount to Send',
            style: GoogleFonts.redHatDisplay(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _satsController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: GoogleFonts.redHatDisplay(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              suffixText: 'sats',
              suffixStyle: GoogleFonts.redHatDisplay(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold),
              hintText: '0',
              hintStyle: GoogleFonts.redHatDisplay(color: Colors.white24, fontSize: 24),
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '≈ ₦${fmt.format(_fiatAmountNgn)}',
                style: GoogleFonts.redHatDisplay(color: Colors.white54, fontSize: 13),
              ),
              Text(
                'Available: ${fmt.format(widget.dashboardViewModel.cryptoBalanceInSats.toInt())} sats',
                style: GoogleFonts.redHatDisplay(color: const Color(0xFF9D84F6), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Preset Sats
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [1000, 5000, 10000, 25000, 50000].map((sats) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text('${fmt.format(sats)} sats'),
                    onPressed: () => _selectPresetSats(sats),
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    labelStyle: GoogleFonts.redHatDisplay(color: Colors.white70, fontSize: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),

          // Memo / Nostr Note
          Text(
            'Memo / Nostr Note (Optional)',
            style: GoogleFonts.redHatDisplay(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _memoController,
            style: GoogleFonts.redHatDisplay(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'e.g. Thanks for dinner! 🍕',
              hintStyle: GoogleFonts.redHatDisplay(color: Colors.white24, fontSize: 14),
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
          const SizedBox(height: 24),

          // Transfer Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _executeTransfer,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _isLoading ? 'Broadcasting to Nostr...' : 'Send Bitcoin',
                style: GoogleFonts.redHatDisplay(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EE6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTypeBadge() {
    String label;
    Color color;
    IconData icon;

    switch (_detectedType) {
      case BitcoinAddressType.onChainBtc:
        label = 'Bitcoin On-Chain';
        color = const Color(0xFFFFA726);
        icon = Icons.currency_bitcoin;
        break;
      case BitcoinAddressType.lightningInvoice:
        label = 'Lightning Invoice';
        color = const Color(0xFFFFD54F);
        icon = Icons.bolt;
        break;
      case BitcoinAddressType.lightningAddress:
        label = 'Lightning Address';
        color = const Color(0xFF81C784);
        icon = Icons.electric_bolt;
        break;
      case BitcoinAddressType.nostrNpub:
        label = 'Nostr Pubkey';
        color = const Color(0xFFBA68C8);
        icon = Icons.hub_outlined;
        break;
      case BitcoinAddressType.unknown:
        label = 'Address Detected';
        color = Colors.white24;
        icon = Icons.help_outline;
        break;
    }

    if (_detectedType == BitcoinAddressType.unknown) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.redHatDisplay(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final res = _transferResult!;
    final fmt = NumberFormat('#,##0', 'en_US');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHandle(),
        const SizedBox(height: 24),
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 44),
        ),
        const SizedBox(height: 16),
        Text(
          'Bitcoin Sent Successfully!',
          style: GoogleFonts.redHatDisplay(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${fmt.format(res.satsSent)} sats (₦${fmt.format(res.fiatAmountNgn)}) transferred',
          style: GoogleFonts.redHatDisplay(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1A2D),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            children: [
              _detailRow('Recipient', _shorten(res.recipientAddress)),
              const Divider(color: Colors.white12, height: 20),
              _detailRow('Payment Type', res.addressType.name.toUpperCase()),
              const Divider(color: Colors.white12, height: 20),
              if (res.nostrEventId != null) ...[
                _detailRow('Nostr Event ID', _shorten(res.nostrEventId!)),
                const Divider(color: Colors.white12, height: 20),
              ],
              _detailRow('Transaction Hash', _shorten(res.txId ?? '—')),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            if (res.explorerUrl != null)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(res.explorerUrl!), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 16, color: Color(0xFF9D84F6)),
                  label: Text('Mempool', style: GoogleFonts.redHatDisplay(color: const Color(0xFF9D84F6))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6B4EE6)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            if (res.explorerUrl != null) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EE6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Done', style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.redHatDisplay(color: Colors.white54, fontSize: 13)),
        Text(value, style: GoogleFonts.redHatDisplay(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _shorten(String s) {
    if (s.length <= 16) return s;
    return '${s.substring(0, 8)}...${s.substring(s.length - 8)}';
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
