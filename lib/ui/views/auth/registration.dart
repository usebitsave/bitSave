import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import '../../common/app_colors.dart';
import '../../../app/app.locator.dart';
import '../../../app/app.router.dart';
import 'auth_view.dart';
import 'auth_viewmodel.dart';

class RegisterScreen extends StatefulWidget {
  final Function(AuthType, {String? email}) onSwitch;

  const RegisterScreen({super.key, required this.onSwitch});

  @override
  State<RegisterScreen> createState() => _RegisterState();
}

class _RegisterState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _confirmObscure = true;

  // Dark field colour used across all inputs
  static const Color _fieldBg = Color(0xFF1A1226);
  static const Color _fieldBorder = Color(0xFF2D2542);
  static const Color _hintColor = Color(0xFF7B7A8E);
  static const Color _labelColor = Color(0xFF9E9DB5);

  @override
  void dispose() {
    _dobController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<AuthViewModel>.reactive(
      viewModelBuilder: () => AuthViewModel(),
      builder: (context, model, child) {
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
                stops: [0.0, 0.6],
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
                    child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // ── Header row: back arrow + progress bar ──────────
                            GestureDetector(
                              onTap: () => widget.onSwitch(AuthType.login),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),

                        const SizedBox(height: 40),

                        // ── Title ──────────────────────────────────────────
                        Text(
                          'Tell us about yourself',
                          style: GoogleFonts.redHatDisplay(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'we need this information to verify your identity',
                          style: GoogleFonts.redHatDisplay(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── Full Name field ────────────────────────────────
                        _buildInputField(
                          label: 'Full name',
                          hint: 'Enter name here',
                          controller: model.firstname,
                          keyboardType: TextInputType.name,
                          validator: (v) =>
                              (v?.isEmpty ?? true) ? 'Full name is required' : null,
                        ),

                        const SizedBox(height: 12),

                        // ── Email field ────────────────────────────────────
                        _buildInputField(
                          label: 'Email',
                          hint: 'Enter email here',
                          controller: model.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email is required';
                            if (!RegExp(
                                    r'^[\w-]+(\.[\\w-]+)*@[\w-]+(\.[\w-]+)+$')
                                .hasMatch(v)) {
                              return 'Invalid email address';
                            } 

                            return null;
                          },
                        ),

                        const SizedBox(height: 12),

                        // ── Date of Birth field ────────────────────────────
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime(1991, 1, 1),
                              firstDate: DateTime(1920),
                              lastDate: DateTime.now(),
                              builder: (ctx, child) => Theme(
                                data: ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: kcPrimaryColor,
                                    surface: Color(0xFF1A1226),
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (picked != null) {
                              setState(() {
                                _dobController.text =
                                    '${picked.day.toString().padLeft(2, '0')}/'
                                    '${picked.month.toString().padLeft(2, '0')}/'
                                    '${picked.year}';
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: _buildInputField(
                              label: 'Date of Birth',
                              hint: '01/01/1991',
                              controller: _dobController,
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: Icon(
                                  Icons.calendar_today_outlined,
                                  color: _hintColor,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Password field ─────────────────────────────────
                        _buildInputField(
                          label: 'Password',
                          hint: '••••••••',
                          controller: model.password,
                          obscure: model.obscure,
                          suffixIcon: GestureDetector(
                            onTap: model.toggleObscure,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: Icon(
                                model.obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: _hintColor,
                                size: 20,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Password is required';
                            }
                            if (v.length < 8) {
                              return 'At least 8 characters';
                            }
                            return null;
                          },
                        ),

                        // ── Confirm Password field ─────────────────────────
                        const SizedBox(height: 12),
                        StatefulBuilder(
                          builder: (ctx, setInner) => _buildInputField(
                            label: 'Confirm Password',
                            hint: '••••••••',
                            controller: _confirmPasswordController,
                            obscure: _confirmObscure,
                            suffixIcon: GestureDetector(
                              onTap: () => setInner(() => _confirmObscure = !_confirmObscure),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 14),
                                child: Icon(
                                  _confirmObscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _hintColor,
                                  size: 20,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please confirm your password';
                              if (v != model.password.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ── Continue button ────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: model.isBusy
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      model.register(
                                        fullName: model.firstname.text.trim(),
                                        dob: _dobController.text.trim(),
                                        onSuccess: () {
                                          locator<NavigationService>().clearStackAndShow(Routes.homeView);
                                        },
                                      );
                                    }
                                  },
                                  
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kcPrimaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  kcPrimaryColor.withValues(alpha: 0.6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
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
                                    'Continue',
                                    style: GoogleFonts.redHatDisplay(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Already have account ───────────────────────────
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Have an account? ',
                                style: GoogleFonts.redHatDisplay(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    widget.onSwitch(AuthType.adminLogin),
                                child: Text(
                                  'Login here',
                                  style: GoogleFonts.redHatDisplay(
                                    color: kcPrimaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ), // Column
                    ), // Form
                  ), // ConstrainedBox
                ), // SingleChildScrollView
              ), // GestureDetector
            ), // SafeArea
          ), // gradient Container
        ); // Scaffold
      },
    );
  }

  // ── Reusable styled input field ──────────────────────────────────────────
  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _fieldBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.redHatDisplay(
              color: _labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscure,
                  style: GoogleFonts.redHatDisplay(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: GoogleFonts.redHatDisplay(
                      color: _hintColor,
                      fontSize: 15,
                    ),
                    errorStyle: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                    ),
                  ),
                  validator: validator,
                ),
              ),
              if (suffixIcon != null) suffixIcon,
            ],
          ),
        ],
      ),
    );
  }
}
