import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/config/supabase_config.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/user_account_service.dart';
import 'procurement/procurement_dashboard.dart';
import 'seller/seller_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignUp = false;
  UserRole _selectedPortal = UserRole.procurement;

  // Form Controllers
  final _emailController = TextEditingController(text: 'procurement.onionsmart@gmail.com');
  final _passwordController = TextEditingController(text: 'Password123!');
  final _confirmPasswordController = TextEditingController(text: 'Password123!');
  final _nameController = TextEditingController(text: 'Procurement Officer');
  UserRole _selectedRole = UserRole.procurement;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onTextChanged);
    _passwordController.addListener(_onTextChanged);
    _confirmPasswordController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onTextChanged);
    _passwordController.removeListener(_onTextChanged);
    _confirmPasswordController.removeListener(_onTextChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _switchPortal(UserRole portal) {
    setState(() {
      _selectedPortal = portal;
      _selectedRole = portal;
      if (!_isSignUp) {
        if (portal == UserRole.procurement) {
          _emailController.text = 'procurement.onionsmart@gmail.com';
          _passwordController.text = 'Password123!';
        } else {
          _emailController.text = 'seller.mandi@gmail.com';
          _passwordController.text = 'Password123!';
        }
      }
    });
  }

  void _toggleMode(bool isSignUp) {
    setState(() {
      _isSignUp = isSignUp;
      if (isSignUp) {
        // Clear demo pre-fills when switching to Create Account so user has clean slate
        _emailController.clear();
        _nameController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
      } else {
        // Switching to Sign In: restore appropriate portal demo credentials
        if (_selectedPortal == UserRole.procurement) {
          _emailController.text = 'procurement.onionsmart@gmail.com';
          _passwordController.text = 'Password123!';
        } else {
          _emailController.text = 'seller.mandi@gmail.com';
          _passwordController.text = 'Password123!';
        }
      }
    });
  }

  bool get _isGmailValid => AuthProvider.isGmail(_emailController.text);
  bool get _isNonGmailDomain {
    final text = _emailController.text.trim().toLowerCase();
    return text.contains('@') && !text.endsWith('@gmail.com');
  }

  void _navigateToDashboard(UserRole role) {
    if (role == UserRole.procurement) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProcurementDashboard()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SellerDashboard()),
      );
    }
  }

  Future<void> _handleAuth(AuthProvider auth) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both your Gmail address and password.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Strict Domain Enforcement: Gmail Only
    if (!AuthProvider.isGmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: Only @gmail.com accounts are permitted. Non-Gmail domains cannot log in or register.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (_isSignUp) {
      final name = _nameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your full name for registration.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password must be at least 6 characters long.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final confirm = _confirmPasswordController.text;
      if (password != confirm) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match. Please verify your password confirmation.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final success = await auth.signUpWithSupabase(
        email: email,
        password: password,
        fullName: name,
        role: _selectedPortal,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Account created for $email! Entering ${_selectedPortal == UserRole.procurement ? "Procurement" : "Seller"} Portal.')),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 3),
          ),
        );
        _navigateToDashboard(_selectedPortal);
      } else if (mounted && auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(auth.errorMessage!)),
              ],
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      final success = await auth.signInWithSupabase(
        email: email,
        password: password,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Welcome back, ${auth.userName}! Entering ${_selectedPortal == UserRole.procurement ? "Procurement" : "Seller"} Portal.')),
              ],
            ),
            backgroundColor: const Color(0xFF059669),
            duration: const Duration(seconds: 2),
          ),
        );
        _navigateToDashboard(_selectedPortal);
      } else if (mounted && auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.lock_clock_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(auth.errorMessage!)),
              ],
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            const Text('OnionSmart Supabase Portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.onionAmber : AppColors.primaryDark,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand Header with Official App Symbol
                Center(
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B192C),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.appName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: isDark ? Colors.white : AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Smart Onion Quality & Procurement System',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                // Supabase Status Pill
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF132A20) : const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          SupabaseConfig.isConfigured
                              ? '⚡ Supabase Cloud Backend (Auth & DB Active)'
                              : '⚡ Supabase Database & Auth Ready',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Strict Gmail Domain Policy Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A1C15) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE65100).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.mark_email_read_rounded, size: 20, color: Color(0xFFE65100)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Strict Policy: Only @gmail.com accounts are permitted. No other domain can log in or create an account.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE65100),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Dedicated Portal Selector (Procurement Portal Login vs Seller Login)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF132A20) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _switchPortal(UserRole.procurement),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: _selectedPortal == UserRole.procurement
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedPortal == UserRole.procurement
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.business_center_rounded,
                                  size: 16,
                                  color: _selectedPortal == UserRole.procurement
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'PROCUREMENT PORTAL',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: _selectedPortal == UserRole.procurement
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: InkWell(
                          onTap: () => _switchPortal(UserRole.seller),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: _selectedPortal == UserRole.seller
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _selectedPortal == UserRole.seller
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.storefront_rounded,
                                  size: 16,
                                  color: _selectedPortal == UserRole.seller
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'SELLER LOGIN',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                    color: _selectedPortal == UserRole.seller
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Auth Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Mode Selector (Sign In vs Create Account)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F1A15) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _toggleMode(false),
                                borderRadius: BorderRadius.circular(9),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: !_isSignUp ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: !_isSignUp
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.login_rounded,
                                        size: 16,
                                        color: !_isSignUp ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'SIGN IN',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: !_isSignUp ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => _toggleMode(true),
                                borderRadius: BorderRadius.circular(9),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _isSignUp ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                    boxShadow: _isSignUp
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_add_alt_1_rounded,
                                        size: 16,
                                        color: _isSignUp ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'CREATE ACCOUNT',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _isSignUp ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Form Title & Instructions
                      const SizedBox(height: 18),
                      Text(
                        _isSignUp
                            ? (_selectedPortal == UserRole.procurement
                                ? 'Create Procurement Center Account'
                                : 'Create Market Seller Account')
                            : (_selectedPortal == UserRole.procurement
                                ? 'Sign In to Procurement Portal'
                                : 'Sign In to Seller Portal'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isSignUp
                            ? 'Register your official @gmail.com for ${_selectedPortal == UserRole.procurement ? "Procurement Center" : "Seller"} access.'
                            : 'Enter your registered @gmail.com to access ${_selectedPortal == UserRole.procurement ? "Procurement Intake & Inspection" : "Mandi Seller Hub"}.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),

                      if (auth.errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  auth.errorMessage!,
                                  style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 18),

                      // Fields for Create Account
                      if (_isSignUp) ...[
                        Text(
                          'Full Name',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.badge_outlined, size: 20),
                            hintText: 'e.g. Ramesh Patil',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select Account Role',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                avatar: Icon(
                                  Icons.business_center_rounded,
                                  size: 16,
                                  color: _selectedRole == UserRole.procurement ? Colors.white : AppColors.primary,
                                ),
                                label: const Text('Procurement Officer'),
                                selected: _selectedRole == UserRole.procurement,
                                onSelected: (_) => setState(() => _selectedRole = UserRole.procurement),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                avatar: Icon(
                                  Icons.store_rounded,
                                  size: 16,
                                  color: _selectedRole == UserRole.seller ? Colors.white : AppColors.primary,
                                ),
                                label: const Text('Market Seller'),
                                selected: _selectedRole == UserRole.seller,
                                onSelected: (_) => setState(() => _selectedRole = UserRole.seller),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Gmail Address Field with Live Validator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Gmail Address',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '@gmail.com only',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                          hintText: 'yourname@gmail.com',
                          suffixIcon: _isGmailValid
                              ? const Tooltip(
                                  message: 'Valid Gmail Address',
                                  child: Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 20),
                                )
                              : (_isNonGmailDomain
                                  ? const Tooltip(
                                      message: 'Non-Gmail domain is rejected',
                                      child: Icon(Icons.cancel_rounded, color: Colors.red, size: 20),
                                    )
                                  : (!_emailController.text.contains('@') && _emailController.text.isNotEmpty
                                      ? TextButton(
                                          onPressed: () {
                                            _emailController.text = '${_emailController.text.trim()}@gmail.com';
                                            _emailController.selection = TextSelection.fromPosition(
                                              TextPosition(offset: _emailController.text.length),
                                            );
                                          },
                                          child: const Text('@gmail.com', style: TextStyle(fontSize: 11)),
                                        )
                                      : null)),
                        ),
                      ),

                      // Live domain warning / confirmation
                      if (_isNonGmailDomain) ...[
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Only @gmail.com accounts are permitted. Other domains cannot log in.',
                                style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ] else if (_isGmailValid) ...[
                        const SizedBox(height: 6),
                        const Row(
                          children: [
                            Icon(Icons.verified_rounded, size: 14, color: Color(0xFF059669)),
                            SizedBox(width: 4),
                            Text(
                              'Authorized Google Gmail domain confirmed',
                              style: TextStyle(color: Color(0xFF059669), fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Password Field
                      Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          hintText: _isSignUp ? 'Create strong password (min 6 chars)' : 'Enter password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                      ),

                      // Real-time Password Strength Meter (During Account Creation)
                      if (_isSignUp && _passwordController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final strength = PasswordStrength.evaluate(_passwordController.text);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Row(
                                          children: List.generate(4, (i) {
                                            final isFilled = i < strength.score;
                                            return Expanded(
                                              child: Container(
                                                height: 4,
                                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                                color: isFilled ? strength.color : (isDark ? Colors.white12 : Colors.black12),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      strength.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: strength.color,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _buildRuleBadge('6+ Chars', strength.hasMinLength, isDark),
                                    _buildRuleBadge('Letters & Numbers', strength.hasLetters && strength.hasDigits, isDark),
                                    _buildRuleBadge('Special Symbol', strength.hasSpecial, isDark),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],

                      // Confirm Password (Only for Create Account)
                      if (_isSignUp) ...[
                        const SizedBox(height: 14),
                        Text(
                          'Confirm Password',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                            hintText: 'Re-enter your password',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                              },
                            ),
                          ),
                        ),
                        if (_confirmPasswordController.text.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                _passwordController.text == _confirmPasswordController.text
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                size: 14,
                                color: _passwordController.text == _confirmPasswordController.text
                                    ? const Color(0xFF059669)
                                    : Colors.redAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _passwordController.text == _confirmPasswordController.text
                                    ? 'Passwords match'
                                    : 'Passwords do not match',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _passwordController.text == _confirmPasswordController.text
                                      ? const Color(0xFF059669)
                                      : Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],

                      const SizedBox(height: 24),

                      // Primary Action Button
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : () => _handleAuth(auth),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_isSignUp ? Icons.how_to_reg_rounded : Icons.login_rounded, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isSignUp ? 'CREATE ACCOUNT WITH SUPABASE' : 'SIGN IN WITH SUPABASE',
                                    style: const TextStyle(letterSpacing: 0.8, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 14),

                      // Switch mode toggle link
                      Center(
                        child: TextButton(
                          onPressed: () => _toggleMode(!_isSignUp),
                          child: Text(
                            _isSignUp
                                ? 'Already have an account? Sign In here'
                                : "Don't have an account? Create Account here",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 1-Click Verified Access Section (Gmail Only)
                Text(
                  _selectedPortal == UserRole.procurement
                      ? '1-CLICK VERIFIED PROCUREMENT OFFICER ACCESS'
                      : '1-CLICK VERIFIED MARKET SELLER ACCESS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
                const SizedBox(height: 12),

                if (_selectedPortal == UserRole.procurement)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.business_center_rounded, size: 18, color: AppColors.primary),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    label: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Procurement Officer (Intake & Quality)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('procurement.onionsmart@gmail.com', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                        Icon(Icons.bolt_rounded, size: 18, color: AppColors.primary),
                      ],
                    ),
                    onPressed: () {
                      auth.quickDemoLogin(UserRole.procurement);
                      _navigateToDashboard(UserRole.procurement);
                    },
                  )
                else
                  OutlinedButton.icon(
                    icon: const Icon(Icons.storefront_rounded, size: 18, color: AppColors.primary),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    label: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Apex Wholesale Mandi Seller', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('seller.mandi@gmail.com', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                        Icon(Icons.bolt_rounded, size: 18, color: AppColors.primary),
                      ],
                    ),
                    onPressed: () {
                      auth.quickDemoLogin(UserRole.seller);
                      _navigateToDashboard(UserRole.seller);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRuleBadge(String text, bool met, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: met
            ? const Color(0xFF059669).withValues(alpha: 0.15)
            : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_rounded : Icons.circle_outlined,
            size: 11,
            color: met ? const Color(0xFF059669) : (isDark ? Colors.white54 : Colors.black45),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: met ? const Color(0xFF059669) : (isDark ? Colors.white54 : Colors.black45),
            ),
          ),
        ],
      ),
    );
  }
}
