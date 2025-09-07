// lib/screens/home_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:typocalypse/core/fade_page_route.dart';
import 'package:typocalypse/data/sentences.dart'; // Assuming you have sentence lists here
import 'package:typocalypse/screens/auth_screen.dart';
import 'package:typocalypse/screens/leaderboard_screen.dart';
import 'package:typocalypse/screens/profile_screen.dart';
import 'package:typocalypse/screens/typing_game_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTime = 30;
  final List<int> _timeOptions = [15, 30, 45, 60, 90, 120];
  int? _customTime;

  // UPDATED: Add difficultyLevel parameter to function definition
  void startGame(BuildContext context, List<String> sentences, String difficultyLevel) {
    Navigator.push(
      context,
      FadePageRoute(
        child: TypingGameScreen(
          sentences: sentences..shuffle(),
          durationInSeconds: _selectedTime,
          difficultyLevel: difficultyLevel, // UPDATED: Pass the difficulty level here
        ),
      ),
    );
  }

  Future<void> _showCustomTimeDialog() async {
    final TextEditingController customTimeController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Enter Custom Time', style: Theme.of(context).textTheme.headlineSmall),
        content: TextField(
          controller: customTimeController,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: const InputDecoration(hintText: "Seconds (min 15)"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, customTimeController.text);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final int? time = int.tryParse(result);
      if (time != null) {
        if (time >= 15) {
          setState(() {
            _customTime = time;
            _selectedTime = time;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Minimum custom time is 15 seconds."),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = FirebaseAuth.instance.currentUser != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'TYPOCALYPSE',
          style: GoogleFonts.eduNswActFoundation(
            fontWeight: FontWeight.bold,
            fontSize: 36,
          ),
        ),
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: "Profile",
              onPressed: () {
                Navigator.push(context, FadePageRoute(child: const ProfileScreen()));
              },
            ),
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: "Logout",
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    FadePageRoute(child: const AuthScreen()),
                        (route) => false,
                  );
                }
              },
            ),
          if (!isLoggedIn)
            IconButton(
              icon: const Icon(Icons.login),
              tooltip: "Login or Sign Up",
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  FadePageRoute(child: const AuthScreen()),
                      (route) => false,
                );
              },
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Select Time Limit',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                alignment: WrapAlignment.center,
                children: [
                  ..._timeOptions.map((time) {
                    final isSelected = _selectedTime == time && _customTime == null; // Ensure custom time deselects standard times
                    return ChoiceChip(
                      label: Text('$time s'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedTime = time;
                            _customTime = null;
                          });
                        }
                      },
                    );
                  }).toList(),
                  ChoiceChip(
                    label: Text(_customTime != null ? 'Custom (${_customTime}s)' : 'Custom'),
                    selected: _customTime != null,
                    onSelected: (selected) => _showCustomTimeDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              const Text(
                'Select Difficulty',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // --- UPDATED: Pass difficulty string on press ---
              ElevatedButton(
                onPressed: () => startGame(context, easySentences, "Easy"), // Pass "Easy"
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Easy"),
              ).animate().fade(duration: 500.ms).slideY(begin: 0.5),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => startGame(context, mediumSentences, "Medium"), // Pass "Medium"
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text("Medium"),
              ).animate().fade(delay: 200.ms, duration: 500.ms).slideY(begin: 0.5),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => startGame(context, hardSentences, "Hard"), // Pass "Hard"
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Hard"),
              ).animate().fade(delay: 400.ms, duration: 500.ms).slideY(begin: 0.5),
              const SizedBox(height: 24),
              const Divider(indent: 80, endIndent: 80),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.leaderboard),
                label: const Text("View Leaderboard"),
                onPressed: () {
                  Navigator.push(
                    context,
                    FadePageRoute(child: const LeaderboardScreen()),
                  );
                },
              ).animate().fade(delay: 600.ms, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}