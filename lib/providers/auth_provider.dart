import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _firebaseUser != null;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;

    if (user == null) {
      _userModel = null;
    } else {
      _userModel = await _userService.getUser(user.uid);
    }

    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String email = identifier;

      // Agar '@' nahi hai to treat as Employee ID
      if (!identifier.contains('@')) {
        final resolvedEmail = await _userService.getEmailByEmployeeId(
          identifier,
        );
        if (resolvedEmail == null) {
          _errorMessage = 'No account found for this Employee ID';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        email = resolvedEmail;
      }

      await _authService.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Login failed';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Something went wrong: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 👇 NAYA METHOD — Password reset
  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordReset(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Failed to send reset email';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 👇 NAYA METHOD — Admin Signup
  Future<bool> signUpAdmin({
    required String name,
    required String email,
    required String password,
    required String employeeId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final credential = await _authService.createAccount(
        email: email,
        password: password,
      );

      final newUser = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        employeeId: employeeId,
        role: 'admin',
        isActive: true,
      );

      await _userService.createUser(newUser);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Signup failed';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.signOut();
  }
}
