import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
    final VoidCallback onPressed;
    const GoogleSignInButton({super.key, required this.onPressed});

    @override
    Widget build(BuildContext context) {
        final SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
                style: OutlinedButton.sytleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg',
                    height: 20,
                ),
                label: const Text(
                    'Continue with Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: onPressed,
            ),
        );
    }
}