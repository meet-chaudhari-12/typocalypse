// lib/screens/typing_game_over_screen.dart

import 'package:flutter/material.dart';
import 'package:typocalypse/screens/home_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';

class TypingGameOverScreen extends StatelessWidget {
  final double accuracy;
  final double wpm;
  final int inaccuracies;
  final int correctChars;
  final int totalChars;
  final bool isNewBest;

  const TypingGameOverScreen({
    super.key,
    required this.accuracy,
    required this.wpm,
    required this.inaccuracies,
    required this.correctChars,
    required this.totalChars,
    required this.isNewBest,
  });

  void _shareResults(BuildContext context) {
    final String wpmText = wpm.toStringAsFixed(0);
    final String accuracyText = accuracy.toStringAsFixed(1);
    final String shareText = "I just scored $wpmText WPM with $accuracyText% accuracy in Typocalypse! 🔥 Can you beat my score?";
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "RESULTS",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (isNewBest)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 30),
                      const SizedBox(width: 8),
                      Text(
                        "New Personal Best!",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.amber),
                      ),
                    ],
                  ),
                ).animate().scale(delay: 300.ms, duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMainStat(context, wpm.toStringAsFixed(0), "WPM"),
                  _buildMainStat(context, "${accuracy.toStringAsFixed(1)}%", "Accuracy"),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              _buildDetailRow(context, Icons.check_circle_outline, Colors.green, "Correct Characters", "$correctChars"),
              _buildDetailRow(context, Icons.highlight_off, Colors.redAccent, "Mistakes", "$inaccuracies"),
              _buildDetailRow(context, Icons.keyboard, Colors.grey, "Total Characters", "$totalChars"),

              const SizedBox(height: 60),

              // --- UPDATED: Action Buttons Layout ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                // --- THIS IS THE FIX ---
                // This tells the Row to shrink its width to fit its children,
                // preventing the infinite width error.
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text("Play Again"),
                    // We remove the infinite width from the button style and let the theme handle it
                    // The theme's button style might have infinite width, so we override it here
                    // to have a more contained size.
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 50), // Let width be determined by content
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                    },
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () => _shareResults(context),
                    // Let the button size itself based on the icon
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Icon(Icons.share),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              TextButton.icon(
                icon: const Icon(Icons.home_outlined),
                label: const Text("Back to Home"),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (Route<dynamic> route) => false,
                  );
                },
              )

            ].animate(interval: 100.ms).fadeIn(duration: 200.ms).slideY(begin: 0.5),
          ),
        ),
      ),
    );
  }

  // Helper Widgets (no changes needed here)
  Widget _buildMainStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}