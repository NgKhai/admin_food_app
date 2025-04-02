import 'package:admin_food_app/screens/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/admin_auth_service.dart';
import 'package:lottie/lottie.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> with SingleTickerProviderStateMixin {
  // Color scheme
  final Color mainColor = Color(0xFF162F4A); // Deep blue - primary
  final Color accentColor = Color(0xFF3A5F82); // Medium blue - secondary
  final Color lightColor = Color(0xFF718EA4); // Light blue - tertiary
  final Color ultraLightColor = Color(0xFFD0DCE7); // Very light blue - background

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AdminAuthService();
  final _formKey = GlobalKey<FormState>();

  final _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animationController.forward();

    _authService.authStateChanges.listen((user) {
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AdminDashboard()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? errorMessage = await _authService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (errorMessage == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminDashboard()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;

    return Scaffold(
      backgroundColor: ultraLightColor,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
            _handleLogin();
          }
        },
        child: Container(
          color: ultraLightColor,
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double cardWidth = constraints.maxWidth < 600 ? constraints.maxWidth * 0.95 : 450;

                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - _animationController.value)),
                          child: Opacity(
                            opacity: _animationController.value,
                            child: child,
                          ),
                        );
                      },
                      child: Card(
                        elevation: 8,
                        shadowColor: mainColor.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: accentColor.withOpacity(0.2), width: 1),
                        ),
                        color: Colors.white,
                        child: Container(
                          width: cardWidth,
                          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 40),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/logo.png',
                                      height: isSmallScreen ? 120 : 150,
                                      fit: BoxFit.contain,
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: mainColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            "Admin",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15),

                                Text(
                                  "Quản lý Crunch n Dash",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 22 : 26,
                                    fontWeight: FontWeight.bold,
                                    color: mainColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                                SizedBox(height: 8),

                                Text(
                                  "Đăng nhập để quản lý hệ thống",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    color: lightColor,
                                  ),
                                ),

                                SizedBox(height: 30),

                                // Username Field
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: InputDecoration(
                                    labelText: "Tài khoản",
                                    labelStyle: TextStyle(color: accentColor),
                                    hintText: "Nhập tên tài khoản",
                                    hintStyle: TextStyle(color: lightColor.withOpacity(0.7)),
                                    prefixIcon: Icon(Icons.person_outline, color: accentColor),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: accentColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: lightColor.withOpacity(0.5)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: mainColor, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: ultraLightColor.withOpacity(0.3),
                                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập tài khoản';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: 20),

                                // Password Field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_isPasswordVisible,
                                  decoration: InputDecoration(
                                    labelText: "Mật khẩu",
                                    labelStyle: TextStyle(color: accentColor),
                                    hintText: "Nhập mật khẩu",
                                    hintStyle: TextStyle(color: lightColor.withOpacity(0.7)),
                                    prefixIcon: Icon(Icons.lock_outline, color: accentColor),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                        color: lightColor,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible = !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: accentColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: lightColor.withOpacity(0.5)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: mainColor, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: ultraLightColor.withOpacity(0.3),
                                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Vui lòng nhập mật khẩu';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: 30),

                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 55,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: mainColor,
                                      disabledBackgroundColor: mainColor.withOpacity(0.6),
                                      elevation: 4,
                                      shadowColor: mainColor.withOpacity(0.4),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                        : Text(
                                      "Đăng nhập",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: 20),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shield, size: 16, color: accentColor),
                                    SizedBox(width: 5),
                                    Text(
                                      "Khu vực quản trị bảo mật",
                                      style: TextStyle(
                                        color: lightColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}