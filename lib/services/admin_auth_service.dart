import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bcrypt/bcrypt.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login attempt tracking for rate limiting
  static const int _maxLoginAttempts = 5;
  static const int _lockoutDurationMinutes = 15;
  static User? currentUser = FirebaseAuth.instance.currentUser;

  // Stream controller for auth state changes
  final StreamController<User?> _authStateController = StreamController<User?>.broadcast();

  // Constructor to set up auth state listening
  AdminAuthService() {
    _setupAuthStateListener();
  }

  void _setupAuthStateListener() {
    _auth.authStateChanges().listen((User? user) {
      _authStateController.add(user);
    });
  }

  // Get auth state changes stream
  Stream<User?> get authStateChanges => _authStateController.stream;

  // 🔹 Hash password with bcrypt before storing
  String hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt(logRounds: 12)); // Higher rounds for more security
  }

  // 🔹 Register a new admin with hashed password
  Future<String?> registerAdmin(String username, String password, {String? name, String? role = 'admin'}) async {
    try {
      // Password strength validation
      if (password.length < 8) {
        return 'Mật khẩu phải có ít nhất 8 ký tự';
      }

      // Check if username already exists
      DocumentSnapshot existingUser = await _firestore.collection('admins').doc(username).get();
      if (existingUser.exists) {
        return 'Tài khoản đã tồn tại';
      }

      // Hash password and store admin data
      String hashedPassword = hashPassword(password);
      await _firestore.collection('admins').doc(username).set({
        'username': username,
        'password': hashedPassword,
        'name': name ?? username,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': null,
      });

      // Create Firebase Auth account for this admin
      try {
        await _auth.createUserWithEmailAndPassword(
          email: "$username@crunchndash.admin", // Using username as email
          password: password,
        );
      } catch (authError) {
        // If Firebase Auth creation fails, clean up Firestore document
        await _firestore.collection('admins').doc(username).delete();
        return 'Lỗi tạo tài khoản: $authError';
      }

      return null; // Success
    } catch (e) {
      return 'Lỗi đăng ký: ${e.toString()}';
    }
  }

  // 🔹 Login with rate limiting and session tracking
  Future<String?> login(String username, String password) async {
    try {
      // Check for brute force attempts
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String attemptsKey = 'login_attempts_$username';
      String lockoutKey = 'login_lockout_$username';

      // Check if account is locked
      int? lockoutTime = prefs.getInt(lockoutKey);
      if (lockoutTime != null) {
        int currentTime = DateTime.now().millisecondsSinceEpoch;
        int remainingLockoutTime = lockoutTime + (_lockoutDurationMinutes * 60 * 1000) - currentTime;

        if (remainingLockoutTime > 0) {
          int remainingMinutes = (remainingLockoutTime / 60000).ceil();
          return 'Tài khoản tạm khóa. Vui lòng thử lại sau $remainingMinutes phút';
        } else {
          // Lockout period expired, reset counters
          prefs.remove(attemptsKey);
          prefs.remove(lockoutKey);
        }
      }

      // Get admin document
      DocumentSnapshot doc = await _firestore.collection('admins').doc(username).get();

      if (!doc.exists) {
        // Increment failed attempts even if username doesn't exist
        _incrementFailedAttempts(prefs, attemptsKey, lockoutKey);
        return 'Tài khoản hoặc mật khẩu không đúng';
      }

      // Verify password
      String storedHash = doc['password'];
      bool isPasswordValid = BCrypt.checkpw(password, storedHash);

      if (isPasswordValid) {
        // Reset failed attempts on successful login
        prefs.remove(attemptsKey);
        prefs.remove(lockoutKey);

        // Update last login timestamp
        await _firestore.collection('admins').doc(username).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });

        // Sign in with Firebase Auth
        try {
          await _auth.signInWithEmailAndPassword(
            email: "$username@crunchndash.admin",
            password: password,
          );
        } catch (authError) {
          // If Firebase Auth fails, continue with custom auth
        }

        return null; // Login successful
      } else {
        _incrementFailedAttempts(prefs, attemptsKey, lockoutKey);
        return 'Tài khoản hoặc mật khẩu không đúng';
      }
    } catch (e) {
      return 'Lỗi đăng nhập: ${e.toString()}';
    }
  }

  // Helper to track failed login attempts
  void _incrementFailedAttempts(SharedPreferences prefs, String attemptsKey, String lockoutKey) {
    int attempts = (prefs.getInt(attemptsKey) ?? 0) + 1;
    prefs.setInt(attemptsKey, attempts);

    // Lock account after too many attempts
    if (attempts >= _maxLoginAttempts) {
      prefs.setInt(lockoutKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  // 🔹 Log out
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 🔹 Change password
  Future<String?> changePassword(String username, String currentPassword, String newPassword) async {
    try {
      // Verify current password first
      DocumentSnapshot doc = await _firestore.collection('admins').doc(username).get();

      if (!doc.exists) {
        return 'Tài khoản không tồn tại';
      }

      String storedHash = doc['password'];
      if (!BCrypt.checkpw(currentPassword, storedHash)) {
        return 'Mật khẩu hiện tại không đúng';
      }

      // Validate new password
      if (newPassword.length < 8) {
        return 'Mật khẩu mới phải có ít nhất 8 ký tự';
      }

      // Hash and update new password
      String newHash = hashPassword(newPassword);
      await _firestore.collection('admins').doc(username).update({
        'password': newHash,
        'passwordChangedAt': FieldValue.serverTimestamp(),
      });

      // Update Firebase Auth password if user is signed in
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.updatePassword(newPassword);
      }

      return null; // Success
    } catch (e) {
      return 'Lỗi đổi mật khẩu: ${e.toString()}';
    }
  }

  // Clean up resources
  void dispose() {
    _authStateController.close();
  }
}