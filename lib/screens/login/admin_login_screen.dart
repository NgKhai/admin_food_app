import 'package:admin_food_app/screens/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for keyboard listener
import '../../services/admin_auth_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AdminAuthService();
  final FocusNode _focusNode = FocusNode(); // Focus node for keyboard events

  void _handleLogin() async {
    await _authService.login(_usernameController.text, _passwordController.text);
    final isLoggedIn = await _authService.isLoggedIn();
    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminDashboard()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng nhập lại")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode, // Assign focus node
        autofocus: true, // Ensure it gets focus
        onKeyEvent: (event) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _handleLogin(); // Call login when Enter is pressed
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlue.shade100],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView( // Prevents overflow
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Responsive padding
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double cardWidth = constraints.maxWidth < 600 ? constraints.maxWidth * 0.9 : 400; // Adjust width dynamically

                    return Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: constraints.maxWidth < 600 ? 150 : 200, // Adjust image size
                                fit: BoxFit.contain,
                              ),
                            ),
                            Center(
                              child: Text(
                                "Quản lý Crunch n Dash",
                                style: TextStyle(
                                  fontSize: constraints.maxWidth < 600 ? 22 : 26, // Responsive font size
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFD0000),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 30),

                            // Username Field
                            TextField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: "Tài khoản",
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                            SizedBox(height: 15),

                            // Password Field
                            TextField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: "Mật khẩu",
                                prefixIcon: Icon(Icons.lock),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                              obscureText: true,
                            ),
                            SizedBox(height: 25),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text("Đăng nhập", style: TextStyle(fontSize: 18, color: Colors.white)),
                              ),
                            ),
                          ],
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
