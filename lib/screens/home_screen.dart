import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:typocalypse/data/sentences.dart';
import 'package:typocalypse/screens/auth_screen.dart';
import 'package:typocalypse/screens/leaderboard_screen.dart';
import 'package:typocalypse/screens/profile_screen.dart';
import 'package:typocalypse/screens/typing_game_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTime = 30;
  final List<int> _timeOptions = [15, 30, 45, 60, 90, 120];
  int? _customTime;

  void startGame(BuildContext context, List<String> sentences) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TypingGameScreen(
          sentences: sentences..shuffle(),
          durationInSeconds: _selectedTime,
        ),
      ),
    );
  }

  Future<void> _showCustomTimeDialog() async {
    final TextEditingController customTimeController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Enter Custom Time', style: GoogleFonts.ebGaramond(color: Colors.white)),
        content: TextField(
          controller: customTimeController,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              hintText: "Seconds",
              hintStyle: TextStyle(color: Colors.white38)
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
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
      if (time != null && time > 0) {
        setState(() {
          _customTime = time;
          _selectedTime = time;
        });
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
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                        (route) => false,
                  );
                }
              },
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/volcano_bg.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.7)),
          Center(
            child: SingleChildScrollView(
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
                        final isSelected = _selectedTime == time;
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
                          backgroundColor: Colors.grey.shade800,
                          selectedColor: Theme.of(context).colorScheme.secondary,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                        );
                      }).toList(),
                      ChoiceChip(
                        label: Text(_customTime != null ? 'Custom (${_customTime}s)' : 'Custom'),
                        selected: _customTime != null,
                        onSelected: (selected) {
                          _showCustomTimeDialog();
                        },
                        backgroundColor: Colors.grey.shade800,
                        selectedColor: Theme.of(context).colorScheme.secondary,
                        labelStyle: TextStyle(color: _customTime != null ? Colors.white : Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'Select Difficulty',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => startGame(context, easySentences),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                      backgroundColor: Colors.green,
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text("Easy"),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => startGame(context, mediumSentences),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                      backgroundColor: Colors.orange,
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text("Medium"),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => startGame(context, hardSentences),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                      backgroundColor: Colors.red,
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text("Hard"),
                  ),
                  const SizedBox(height: 24),
                  const Divider(indent: 80, endIndent: 80),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.leaderboard),
                    label: const Text("View Leaderboard"),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white70),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}