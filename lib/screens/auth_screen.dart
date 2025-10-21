import 'package:flutter/material.dart';
import 'dart:math';
import '../services/auth_service.dart';
import '../widgets/google_signin_button.dart';
import '../widgets/homescreen_header_clipper.dart';

// Handles user registration and login. The authentication gateway to the app.

class AuthScreen extends StatefulWidget {
    const AuthScreen({super.key});

    @override
    State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
    final _formKey = GlobalKey<FormState>();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();

    late AnimationController _waveController;
    late Animation<double> _waveAnimation; 

    // UI state variables
    bool _obscure = true;
    bool _isLogin = true; // Toggles login/signup view       
    bool _working = false; // Disables button during API calls

    @override
    void initState() {
        super.initState();
        
        // Inits the wave animation
        _waveController = AnimationController(
            vsync: this,
            duration: const Duration(seconds: 4), 
        )..repeat(); 
        _waveAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(_waveController);
    }

    @override
    void dispose() {
        _emailController.dispose();
        _passwordController.dispose();
        _waveController.dispose();
        super.dispose();
    }

    /* SPRINT 1 GOAL: As a new user, I want to create a profile and log in, so that I can save my progress and personalize my
       experience. 
       
    Handles submission for login/signup */
    Future<void> _submit() async {
        if (!_formKey.currentState!.validate()) return;
        setState(() => _working = true);

        try {
            if (_isLogin) {
                await AuthService.instance.signInWithEmail(
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim()
                );
            } else {
                await AuthService.instance.signUpWithEmail(
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim()
                );
            }
        } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.toString())));
        }   finally {
            if (mounted) setState(() => _working = false);
        }
    }

    // Google login method
    Future<void> _google() async {
        setState(() => _working = true);
        try {
            await AuthService.instance.signInWithGoogle();
        } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.toString())));
        } finally {
            if (mounted) setState(() => _working = false);
        }
    }

    // Build for auth_screen UI
    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);
        final size = MediaQuery.of(context).size;

        return Scaffold(
            backgroundColor: const Color(0xFFF0F8FF), 
            body: Stack(
                children: [
                    AnimatedBuilder(
                        animation: _waveAnimation,
                        builder: (context, child) {
                            return _buildWavyBackground(theme, _waveAnimation.value, size);
                        },
                    ),

                    SafeArea(
                        child: Center(
                            child: SingleChildScrollView(
                                padding: const EdgeInsets.all(24),
                                child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 420),
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                            SizedBox(height: size.height * 0.30), 
                                        
                                            Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(20),
                                                    boxShadow: [
                                                        BoxShadow(
                                                            color: Colors.black.withAlpha(36), 
                                                            blurRadius: 10,
                                                            spreadRadius: 2,
                                                            offset: const Offset(0, 4),
                                                        ),
                                                    ],
                                                ),
                                                child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                                    children: [
                                                        SegmentedButton<bool>(
                                                            segments: const [
                                                                ButtonSegment(value: true, label: Text('Log In')),
                                                                ButtonSegment(value: false, label: Text('Sign Up')),
                                                            ],
                                                            selected: {_isLogin},
                                                            onSelectionChanged: (v) => setState(() => _isLogin = v.first),
                                                            showSelectedIcon: false,
                                                        ),
                                                        const SizedBox(height: 16),

                                                        Form(
                                                            key: _formKey,
                                                            child: Column(
                                                                children: [
                                                                    TextFormField(
                                                                        controller: _emailController,
                                                                        keyboardType: TextInputType.emailAddress,
                                                                        decoration: const InputDecoration(
                                                                            labelText: 'Email',
                                                                            prefixIcon: Icon(Icons.email_outlined),
                                                                        ),
                                                                        validator: (v) {
                                                                            if (v == null || v.isEmpty) return 'Email required';
                                                                            final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                                                                            if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
                                                                            return null;
                                                                        },
                                                                    ),
                                                                    const SizedBox(height: 12),
                                                                    TextFormField(
                                                                        controller: _passwordController,
                                                                        obscureText: _obscure,
                                                                        decoration: InputDecoration(
                                                                            labelText: 'Password',
                                                                            prefixIcon: const Icon(Icons.lock_outline),
                                                                            suffixIcon: IconButton(
                                                                                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                                                                onPressed: () => setState(() => _obscure = !_obscure),
                                                                            ),
                                                                        ),
                                                                        validator: (v) {
                                                                            if (v == null || v.isEmpty) return 'Password required';
                                                                            if (v.length < 8) return 'Password must be at least 8 characters';
                                                                            if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(v)) return 'Include at least one letter and one number';
                                                                            return null;
                                                                        },
                                                                    ),
                                                                    const SizedBox(height: 16),
                                                                    SizedBox(
                                                                        width: double.infinity,
                                                                        child: FilledButton(
                                                                            onPressed: _working ? null : _submit,
                                                                            child: Padding(
                                                                                padding: const EdgeInsets.symmetric(vertical: 14.0),
                                                                                child: Text(_isLogin ? 'Log in' : 'Create account'),
                                                                            ),
                                                                        ),
                                                                    ),
                                                                ],
                                                            ),
                                                        ),
                                                        const SizedBox(height: 16),
                                                        Row(
                                                            children: const [
                                                                Expanded(child: Divider()),
                                                                Padding(
                                                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                                                    child: Text('or'),
                                                                ),
                                                                Expanded(child: Divider()),
                                                            ],
                                                        ),
                                                        const SizedBox(height: 16),
                                                        GoogleSignInButton(onPressed: _working ? () {} : _google),
                                                    ],
                                                ),
                                            ),
                                            const SizedBox(height: 12),
                                        ],
                                    ),
                                ),
                            ),
                        ),
                    ),
                ],
            ),
        );
    }
    
    Widget _buildWavyBackground(ThemeData theme, double wavePhase, Size size) {
        final Color primaryColor = theme.colorScheme.primary;
        
        return Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.35, 
            child: ClipPath(
                clipper: WaveClipper(wavePhase: wavePhase), 
                child: Container(
                    padding: const EdgeInsets.only(top: 80, left: 24, right: 24), 
                    decoration: BoxDecoration(
                        color: primaryColor,
                        boxShadow: [
                            BoxShadow(
                                color: primaryColor.withAlpha(102),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                            ),
                        ],
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                            // TODO: Put future logo
                            Text(
                                'Water Safety for Parents',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                                _isLogin
                                    ? 'Welcome back! Log in to continue your water safety education.'
                                    : 'Create a new account',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white70, 
                                )
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}