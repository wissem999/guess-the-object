import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class EmailAuthPage extends ConsumerStatefulWidget {
  const EmailAuthPage({super.key});

  @override
  ConsumerState<EmailAuthPage> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends ConsumerState<EmailAuthPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _nameFocus = FocusNode();
  bool _isLogin = true;
  bool _loading = false;

  bool _nameChecking = false;
  bool? _nameAvailable;
  String? _nameMessage;
  Timer? _nameDebounce;

  String? _emailError;
  String? _passError;
  String? _nameError;
  String? _serverError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _nameFocus.dispose();
    _nameDebounce?.cancel();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _emailError = null;
      _passError = null;
      _nameError = null;
      _serverError = null;
    });
  }

  void _onNameChanged(String value) {
    _nameDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _nameAvailable = null;
        _nameMessage = null;
        _nameChecking = false;
        _nameError = null;
      });
      return;
    }
    if (trimmed.length < 3) {
      setState(() {
        _nameAvailable = null;
        _nameMessage = 'Name must be at least 3 characters';
        _nameChecking = false;
        _nameError = null;
      });
      return;
    }
    setState(() {
      _nameChecking = true;
      _nameAvailable = null;
      _nameMessage = null;
      _nameError = null;
    });
    _nameDebounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final ds = ref.read(firestoreDataSourceProvider);
        final taken = await ds.isUsernameTaken(trimmed);
        if (!mounted) return;
        setState(() {
          _nameChecking = false;
          _nameAvailable = !taken;
          _nameMessage = taken ? '"$trimmed" is already taken' : '"$trimmed" is available!';
          _nameError = null;
        });
      } catch (_) {
        if (mounted) {
          setState(() {
            _nameChecking = false;
            _nameAvailable = null;
          });
        }
      }
    });
  }

  Future<void> _submit() async {
    _clearErrors();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    bool hasError = false;

    if (!_isLogin && name.isEmpty) {
      setState(() => _nameError = 'Please enter your name');
      hasError = true;
    }

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email');
      hasError = true;
    } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      hasError = true;
    }

    if (pass.isEmpty) {
      setState(() => _passError = 'Please enter your password');
      hasError = true;
    } else if (pass.length < 6) {
      setState(() => _passError = 'Password must be at least 6 characters');
      hasError = true;
    }

    if (!_isLogin && name.isNotEmpty && _nameAvailable != true) {
      if (_nameAvailable == null) {
        final ds = ref.read(firestoreDataSourceProvider);
        try {
          final taken = await ds.isUsernameTaken(name);
          if (!mounted) return;
          if (taken) {
            setState(() {
              _nameError = '"$name" is already taken';
              _nameAvailable = false;
            });
            return;
          }
        } catch (e) {
          if (!mounted) return;
          setState(() => _nameError = 'Could not check name availability');
          return;
        }
      } else {
        setState(() => _nameError = 'Please choose an available name');
        hasError = true;
      }
    }

    if (hasError) return;

    setState(() {
      _loading = true;
      _serverError = null;
    });
    try {
      if (_isLogin) {
        await ref.read(authActionsProvider).signInWithEmail(email, pass);
      } else {
        await ref.read(authActionsProvider).registerWithEmail(email, pass, name);
      }
      if (mounted) context.go('/lobby');
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _serverError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _serverError = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => context.go('/login'),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0B0B1A),
              Color(0xFF120A2E),
              Color(0xFF0D0D2B),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF6C4EF8), Color(0xFF3B82F6)],
                      ),
                    ),
                    child: Icon(
                      _isLogin ? Icons.login_rounded : Icons.person_add_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isLogin ? 'Welcome Back' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLogin ? 'Sign in to continue playing' : 'Join the game',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_serverError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade700.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _serverError!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!_isLogin) ...[
                    _buildNameField(),
                    const SizedBox(height: 12),
                  ],
                  _buildEmailField(),
                  const SizedBox(height: 12),
                  _buildPasswordField(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      _clearErrors();
                      setState(() {
                        _isLogin = !_isLogin;
                        _nameAvailable = null;
                        _nameMessage = null;
                        _nameError = null;
                      });
                    },
                    child: Text(
                      _isLogin
                          ? "Don't have an account? Sign up"
                          : 'Already have an account? Sign in',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameCtrl,
          focusNode: _nameFocus,
          style: const TextStyle(color: Colors.white),
          textCapitalization: TextCapitalization.words,
          onChanged: _onNameChanged,
          decoration: InputDecoration(
            hintText: 'Choose a username',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: Icon(Icons.person_outline,
                color: _nameError != null
                    ? Colors.redAccent
                    : _nameAvailable == true
                        ? Colors.greenAccent
                        : Colors.white.withValues(alpha: 0.5)),
            suffixIcon: _nameChecking
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _nameAvailable != null
                    ? Icon(
                        _nameAvailable! ? Icons.check_circle : Icons.cancel,
                        color: _nameAvailable! ? Colors.greenAccent : Colors.redAccent,
                        size: 22,
                      )
                    : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _nameError != null
                    ? Colors.redAccent.withValues(alpha: 0.5)
                    : _nameAvailable == true
                        ? Colors.greenAccent.withValues(alpha: 0.5)
                        : Colors.transparent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _nameError != null
                    ? Colors.redAccent
                    : _nameAvailable == true
                        ? Colors.greenAccent
                        : const Color(0xFF6C4EF8),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_nameMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _nameMessage!,
              style: TextStyle(
                fontSize: 12,
                color: _nameAvailable == true ? Colors.greenAccent : Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (_nameError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _nameError!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _emailCtrl,
          focusNode: _emailFocus,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
          decoration: InputDecoration(
            hintText: 'Email',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: Icon(Icons.email_outlined,
                color: _emailError != null
                    ? Colors.redAccent
                    : Colors.white.withValues(alpha: 0.5)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _emailError != null
                    ? Colors.redAccent.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _emailError != null ? Colors.redAccent : const Color(0xFF6C4EF8),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_emailError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _emailError!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _passCtrl,
          focusNode: _passFocus,
          style: const TextStyle(color: Colors.white),
          obscureText: true,
          onChanged: (_) {
            if (_passError != null) setState(() => _passError = null);
          },
          decoration: InputDecoration(
            hintText: 'Password',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: Icon(Icons.lock_outline,
                color: _passError != null
                    ? Colors.redAccent
                    : Colors.white.withValues(alpha: 0.5)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _passError != null
                    ? Colors.redAccent.withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: _passError != null ? Colors.redAccent : const Color(0xFF6C4EF8),
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_passError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _passError!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C4EF8),
          foregroundColor: Colors.white,
          elevation: 0,
          disabledBackgroundColor: const Color(0xFF6C4EF8).withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                _isLogin ? 'Sign In' : 'Create Account',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
