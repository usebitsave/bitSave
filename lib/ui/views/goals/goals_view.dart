import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import '../../../core/data/models/api_models.dart';
import 'goals_viewmodel.dart';

class GoalsView extends StackedView<GoalsViewModel> {
  const GoalsView({Key? key}) : super(key: key);

  @override
  GoalsViewModel viewModelBuilder(BuildContext context) => GoalsViewModel();

  @override
  void onViewModelReady(GoalsViewModel viewModel) => viewModel.init();

  @override
  Widget builder(BuildContext context, GoalsViewModel viewModel, Widget? child) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0A1E),
      body: RefreshIndicator(
        onRefresh: viewModel.refresh,
        color: const Color(0xFF6B4EE6),
        child: CustomScrollView(
          slivers: [
            _AppBar(viewModel: viewModel),
            if (viewModel.isBusy)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF6B4EE6)),
                ),
              )
            else if (viewModel.goals.isEmpty)
              SliverFillRemaining(child: _EmptyState(viewModel: viewModel))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _GoalCard(
                      goal: viewModel.goals[i],
                      viewModel: viewModel,
                    ),
                    childCount: viewModel.goals.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGoalSheet(context, viewModel),
        backgroundColor: const Color(0xFF6B4EE6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Goal',
          style: GoogleFonts.redHatDisplay(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── App Bar ──────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final GoalsViewModel viewModel;
  const _AppBar({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF0F0A1E),
      elevation: 0,
      pinned: true,
      expandedHeight: 130,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Savings Goals',
              style: GoogleFonts.redHatDisplay(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${viewModel.goals.length} active goal${viewModel.goals.length == 1 ? '' : 's'}',
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

// ── Empty State ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final GoalsViewModel viewModel;
  const _EmptyState({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
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
                Icons.savings_outlined,
                color: Color(0xFF6B4EE6),
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No savings goals yet',
              style: GoogleFonts.redHatDisplay(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "New Goal" to set a target and track your progress.',
              textAlign: TextAlign.center,
              style: GoogleFonts.redHatDisplay(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _showGoalSheet(context, viewModel),
              icon: const Icon(Icons.add),
              label: const Text('Create your first goal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EE6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Goal Card ─────────────────────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final BitSaveSavingsGoal goal;
  final GoalsViewModel viewModel;
  const _GoalCard({required this.goal, required this.viewModel});

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'emergency':
        return Icons.health_and_safety_outlined;
      case 'education':
        return Icons.school_outlined;
      case 'car':
        return Icons.directions_car_outlined;
      case 'housing':
        return Icons.home_outlined;
      case 'business':
        return Icons.business_center_outlined;
      default:
        return Icons.savings_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'emergency':
        return const Color(0xFFE57373);
      case 'education':
        return const Color(0xFF4FC3F7);
      case 'car':
        return const Color(0xFFFFB74D);
      case 'housing':
        return const Color(0xFF81C784);
      case 'business':
        return const Color(0xFFBA68C8);
      default:
        return const Color(0xFF9D84F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(goal.category);
    final days = viewModel.daysLeft(goal.deadline);
    final isExpired = days == 0 && goal.deadline != null &&
        goal.deadline!.isBefore(DateTime.now());
    
    // Progress is based on actual saved vs target, fallback to time progress if saved is 0
    final savingsProgress = goal.progressPercent;
    final displayProgress = savingsProgress > 0 ? savingsProgress : viewModel.timeProgress(goal);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpired
              ? Colors.redAccent.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge + 3-dot menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_categoryIcon(goal.category), color: catColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      goal.category,
                      style: GoogleFonts.redHatDisplay(
                        color: catColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: const Color(0xFF1C1A2E),
                icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                onSelected: (val) async {
                  if (val == 'edit') {
                    viewModel.prefillForm(goal);
                    _showGoalSheet(context, viewModel, editId: goal.id);
                  } else if (val == 'delete') {
                    _confirmDelete(context, viewModel, goal);
                  } else if (val == 'deposit') {
                    _showDepositSheet(context, viewModel, goal);
                  }
                },
                itemBuilder: (_) => [
                  _menuItem('deposit', Icons.add_circle_outline, 'Add Funds'),
                  _menuItem('edit', Icons.edit_outlined, 'Edit'),
                  _menuItem('delete', Icons.delete_outline, 'Delete',
                      color: Colors.redAccent),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Goal name
          Text(
            goal.name,
            style: GoogleFonts.redHatDisplay(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Saved vs Target row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₦${_fmt(goal.savedAmountDouble)}',
                style: GoogleFonts.redHatDisplay(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ₦${_fmt(goal.targetAmountDouble)}',
                style: GoogleFonts.redHatDisplay(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '${(goal.progressPercent * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.redHatDisplay(
                  color: const Color(0xFF9D84F6),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: displayProgress,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                isExpired ? Colors.redAccent : const Color(0xFF6B4EE6),
              ),
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 14),

          // Bottom row: deadline + quick deposit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    goal.deadline != null
                        ? _formatDate(goal.deadline!)
                        : 'No deadline',
                    style: GoogleFonts.redHatDisplay(
                        color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•  ${isExpired ? 'Expired' : '$days days left'}',
                    style: GoogleFonts.redHatDisplay(
                      color: isExpired ? Colors.redAccent : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _showDepositSheet(context, viewModel, goal),
                icon: const Icon(Icons.bolt, size: 14, color: Color(0xFF6B4EE6)),
                label: Text(
                  'Save',
                  style: GoogleFonts.redHatDisplay(
                    color: const Color(0xFF9D84F6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF6B4EE6), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label,
      {Color color = Colors.white}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.redHatDisplay(color: color, fontSize: 14)),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v >= 1000000
          ? '${(v / 1000000).toStringAsFixed(2)}M'
          : v >= 1000
              ? '${(v / 1000).toStringAsFixed(1)}K'
              : v.toStringAsFixed(2);

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ── Create / Edit Bottom Sheet ─────────────────────────────────────────────────
void _showGoalSheet(
  BuildContext context,
  GoalsViewModel viewModel, {
  String? editId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _GoalFormSheet(
      viewModel: viewModel,
      editId: editId,
    ),
  );
}

class _GoalFormSheet extends StatefulWidget {
  final GoalsViewModel viewModel;
  final String? editId;
  const _GoalFormSheet({required this.viewModel, this.editId});

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.editId != null;

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              _isEdit ? 'Edit Goal' : 'New Savings Goal',
              style: GoogleFonts.redHatDisplay(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Name field
            _field(
              label: 'Goal name',
              hint: 'e.g. New Laptop',
              controller: vm.nameController,
              validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            // Amount field
            _field(
              label: 'Target amount (₦)',
              hint: '0.00',
              controller: vm.amountController,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                final d = double.tryParse(v.replaceAll(',', ''));
                if (d == null || d <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Category selector
            Text(
              'Category',
              style: GoogleFonts.redHatDisplay(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: vm.categories.map((cat) {
                  final isSel = vm.selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSel,
                      onSelected: (_) => setState(() => vm.setCategory(cat)),
                      selectedColor: const Color(0xFF6B4EE6),
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      labelStyle: GoogleFonts.redHatDisplay(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSel ? const Color(0xFF6B4EE6) : Colors.white12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Frequency selector
            Text(
              'Saving Frequency',
              style: GoogleFonts.redHatDisplay(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: vm.frequencies.map((freq) {
                  final isSel = vm.selectedFrequency == freq;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(freq),
                      selected: isSel,
                      onSelected: (_) => setState(() => vm.setFrequency(freq)),
                      selectedColor: const Color(0xFF6B4EE6),
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      labelStyle: GoogleFonts.redHatDisplay(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSel ? const Color(0xFF6B4EE6) : Colors.white12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Deadline picker
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: vm.selectedDeadline ??
                      DateTime.now().add(const Duration(days: 90)),
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFF6B4EE6),
                        surface: Color(0xFF1C1A2E),
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) {
                  setState(() => vm.setDeadline(picked));
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Colors.white54, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      vm.selectedDeadline != null
                          ? '${vm.selectedDeadline!.day}/${vm.selectedDeadline!.month}/${vm.selectedDeadline!.year}'
                          : 'Pick a deadline',
                      style: GoogleFonts.redHatDisplay(
                        color: vm.selectedDeadline != null
                            ? Colors.white
                            : Colors.white38,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: vm.isBusy
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        if (vm.selectedDeadline == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            _snackbar('Please select a deadline', isError: true),
                          );
                          return;
                        }
                        bool ok;
                        if (_isEdit) {
                          ok = await vm.updateGoal(widget.editId!);
                        } else {
                          ok = await vm.createGoal(context);
                        }
                        if (ok && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            _snackbar(
                              _isEdit
                                  ? 'Goal updated!'
                                  : 'Goal created! 🎯',
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B4EE6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: vm.isBusy
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEdit ? 'Save Changes' : 'Create Goal',
                        style: GoogleFonts.redHatDisplay(
                          fontSize: 16, fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.redHatDisplay(
              color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          inputFormatters: inputFormatters,
          style: GoogleFonts.redHatDisplay(color: Colors.white, fontSize: 15),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.redHatDisplay(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6B4EE6)),
            ),
            errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

// ── Deposit Sheet ─────────────────────────────────────────────────────────────
void _showDepositSheet(
  BuildContext context,
  GoalsViewModel viewModel,
  BitSaveSavingsGoal goal,
) {
  final amountCtrl = TextEditingController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setSheet) {
        bool loading = false;
        return Container(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF1C1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Add funds to "${goal.name}"',
                style: GoogleFonts.redHatDisplay(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Target: ₦${goal.targetAmountDouble.toStringAsFixed(2)}',
                style: GoogleFonts.redHatDisplay(
                    color: Colors.white38, fontSize: 13),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.redHatDisplay(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '₦ ',
                  prefixStyle: GoogleFonts.redHatDisplay(
                      color: Colors.white54, fontSize: 22),
                  hintText: '0.00',
                  hintStyle: GoogleFonts.redHatDisplay(
                      color: Colors.white24, fontSize: 22),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF6B4EE6)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '⚡ Deposit is mocked — BTC amounts will be simulated.',
                style: GoogleFonts.redHatDisplay(
                    color: Colors.white24, fontSize: 11),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final amount = double.tryParse(
                              amountCtrl.text.replaceAll(',', ''));
                          if (amount == null || amount <= 0) return;
                          setSheet(() => loading = true);
                          final tx = await viewModel.depositToGoal(
                            amountNgn: amount,
                            goalId: goal.id,
                          );
                          setSheet(() => loading = false);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              _snackbar(tx != null
                                  ? '₦${amount.toStringAsFixed(2)} deposited! Status: ${tx.status}'
                                  : 'Deposit failed. Try again.', isError: tx == null),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EE6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text('Deposit',
                          style: GoogleFonts.redHatDisplay(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

// ── Confirm Delete Dialog ─────────────────────────────────────────────────────
void _confirmDelete(
    BuildContext context, GoalsViewModel viewModel, BitSaveSavingsGoal goal) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF1C1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Delete Goal',
          style: GoogleFonts.redHatDisplay(
              color: Colors.white, fontWeight: FontWeight.bold)),
      content: Text(
        'Are you sure you want to delete "${goal.name}"? This cannot be undone.',
        style: GoogleFonts.redHatDisplay(color: Colors.white70, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: GoogleFonts.redHatDisplay(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final ok = await viewModel.deleteGoal(goal.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                _snackbar(ok ? 'Goal deleted.' : 'Delete failed.', isError: !ok),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('Delete',
              style: GoogleFonts.redHatDisplay(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────
SnackBar _snackbar(String msg, {bool isError = false}) => SnackBar(
      content: Text(msg,
          style: GoogleFonts.redHatDisplay(color: Colors.white)),
      backgroundColor:
          isError ? Colors.redAccent : const Color(0xFF6B4EE6),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
