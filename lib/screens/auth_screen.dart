import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/google_signin_button.dart';

class AuthScreen extends StatefulWidget {
    const AuthScreen({super.key});

    @override
    State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
    final _formKey = GlobalKey<FormState>();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();


    bool _obscure = true;
    bool _isLogin = true;       // login/signup
    bool _working = false;

    @override
    void dispose() {
        _emailController.dispose();
        _passwordController.dispose();
        super.dispose();
    }

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

    @override
    Widget build(BuildContext context) {
        final theme = Theme.of(context);

        return Scaffold(
            body: SafeArea(
                child: Center(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                    // APP HEADER - TITLE
                                    Text(
                                        'Title',
                                        textAlign: TextAlign.center,
                                        style: theme.textTheme.headlineMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                        ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                        _isLogin
                                            ? 'Welcome back! Log in to continue your lesson.'
                                            : 'Create an account ####.',
                                        textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),

                                    //buttons for toggle
                                    SegmentedButton<bool>(
                                        segments: const [
                                            ButtonSegment(value: true, label: Text('Log In')),
                                            ButtonSegment(value: false, label: Text('Sign Up')),
                                        ],
                                        selected: {_isLogin},
                                        onSelectionChanged: (v) => setState(() => _isLogin = v.first),
                                    ),
                                    const SizedBox(height: 16),


                                    // email/password form
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
                                                        if (!RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$')
                                                            .hasMatch(v)) {
                                                            return 'Enter a valid email';
                                                        }
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
                                                            icon: Icon(_obscure
                                                                ? Icons.visibility
                                                                : Icons.visibility_off),
                                                            onPressed: () =>
                                                                setState(() => _obscure = !_obscure),
                                                        ),
                                                    ),
                                                    validator: (v) {
                                                        if (v == null || v.length < 6) {
                                                            return 'Minimum of 6 characters';
                                                        }
                                                        return null;
                                                    },
                                                ),
                                                const SizedBox(height: 16),
                                                SizedBox(
                                                    width: double.infinity,
                                                    child: FilledButton(
                                                        onPressed: _working ? null : _submit,
                                                        child: Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(vertical: 14.0),
                                                            child: Text(_isLogin ? 'Log in' : 'Create account'),
                                                        ),
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                    const SizedBox(height: 16),

                                    // divider
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

                                    //Google SignIn Button
                                    GoogleSignInButton(onPressed: _working ? () {} : _google),

                                    const SizedBox(height: 12),
                                ],
                            ),
                        ),
                    ),
                ),
            ),
        );
    }
}