import 'package:flutter/material.dart';
import 'package:typocalypse/screens/home_screen.dart';

class TypingGameOverScreen extends StatelessWidget {
  final double accuracy;
  final double wpm;
  final int inaccuracies;

  const TypingGameOverScreen({
    super.key,
    required this.accuracy,
    required this.wpm,
    required this.inaccuracies,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("RESULTS", style: TextStyle(fontSize: 32, color: Colors.redAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              Text("Accuracy: ${accuracy.toStringAsFixed(2)}%", style: const TextStyle(fontSize: 20, color: Colors.white)),
              const SizedBox(height: 10),
              Text("WPM: ${wpm.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, color: Colors.white)),
              const SizedBox(height: 10),
              Text("Inaccuracies: $inaccuracies", style: const TextStyle(fontSize: 20, color: Colors.white)),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => HomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                child: const Text("Play Again"),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                        (Route<dynamic> route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(minimumSize: const Size(200, 50)),
                child: const Text("Back to Home"),
              )
            ],
          ),
        ),
      ),
    );
  }
}