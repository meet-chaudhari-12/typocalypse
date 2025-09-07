// lib/screens/typing_game_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:typocalypse/screens/game_over_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

class TypingGameScreen extends StatefulWidget {
  final List<String> sentences;
  final int durationInSeconds;
  final String difficultyLevel;

  const TypingGameScreen({
    Key? key,
    required this.sentences,
    required this.durationInSeconds,
    required this.difficultyLevel,
  }) : super(key: key);

  @override
  State<TypingGameScreen> createState() => _TypingGameScreenState();
}

class _TypingGameScreenState extends State<TypingGameScreen>
    with TickerProviderStateMixin {
  // ... (all existing variable declarations and initState/dispose/startGame/onInputChange methods remain the same) ...
  // [No changes needed in the first part of the file]

  // --- State Variables ---
  int sentenceIndex = 0;
  String get targetSentence =>
      widget.sentences.isEmpty ? "Loading sentence..." : widget.sentences[sentenceIndex];
  String userInput = "";
  late int timeLeft;
  int _totalCharsTypedInSession = 0;
  int _correctCharsTypedInSession = 0;
  int _inaccuracies = 0;
  Timer? timer;
  bool isGameStarted = false;
  final TextEditingController _controller = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _timerAnimationController;
  late Animation<Color?> _colorAnimation;
  late AnimationController _shakeController;
  bool _showCursor = true;
  Timer? _cursorTimer;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.release);
    timeLeft = widget.durationInSeconds;
    _timerAnimationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _colorAnimation = ColorTween(begin: Colors.white, end: Colors.redAccent).animate(_timerAnimationController);
    _timerAnimationController.repeat(reverse: true);
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _showCursor = !_showCursor);
    });
    startGame();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  void startGame() {
    setState(() {
      isGameStarted = true;
      sentenceIndex = 0;
      userInput = "";
      _totalCharsTypedInSession = 0;
      _correctCharsTypedInSession = 0;
      _inaccuracies = 0;
      timeLeft = widget.durationInSeconds;
      _controller.clear();
      _focusNode.requestFocus();
    });
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          timeLeft--;
          if (timeLeft <= 0) {
            t.cancel();
            endGame();
          }
        });
      } else {
        t.cancel();
      }
    });
  }

  void onInputChange(String newInput) {
    if (!isGameStarted || targetSentence.isEmpty) return;
    if (newInput.length > userInput.length) {
      int lastCharIndex = newInput.length - 1;
      if (lastCharIndex < targetSentence.length &&
          newInput[lastCharIndex] != targetSentence[lastCharIndex]) {
        _shakeController.forward(from: 0.0);
      }
    }
    if (newInput.length >= targetSentence.length) {
      final finalInput = newInput.substring(0, targetSentence.length);
      for (int i = 0; i < targetSentence.length; i++) {
        if (finalInput[i] == targetSentence[i]) {
          _correctCharsTypedInSession++;
        } else {
          _inaccuracies++;
        }
      }
      _totalCharsTypedInSession += targetSentence.length;
      int nextSentenceIndex = sentenceIndex + 1;
      if (nextSentenceIndex >= widget.sentences.length) nextSentenceIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller.clear());
      setState(() {
        sentenceIndex = nextSentenceIndex;
        userInput = "";
      });
      return;
    }
    setState(() => userInput = newInput);
  }

  @override
  void dispose() {
    timer?.cancel();
    _cursorTimer?.cancel();
    _timerAnimationController.dispose();
    _shakeController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- UPDATED endGame Function ---
  void endGame() async {
    timer?.cancel();
    if (!mounted) return;
    setState(() => isGameStarted = false);

    // --- Calculate final stats ---
    for (int i = 0; i < userInput.length; i++) {
      if (i < targetSentence.length && userInput[i] == targetSentence[i]) {
        _correctCharsTypedInSession++;
      }
    }
    _totalCharsTypedInSession += userInput.length;

    double wpm = (_correctCharsTypedInSession / 5) / (widget.durationInSeconds / 60.0);
    double totalCharsForAccCalc = (_correctCharsTypedInSession + _inaccuracies).toDouble();
    double acc = totalCharsForAccCalc == 0 ? 100 : (_correctCharsTypedInSession / totalCharsForAccCalc) * 100;
    acc = acc.isNaN ? 0 : max(0, acc);
    wpm = wpm.isNaN ? 0 : max(0, wpm);

    // --- Personal Best Check & Save Score ---
    final user = FirebaseAuth.instance.currentUser;
    bool isNewBest = false;
    if (user != null) {
      // 1. Query for the user's previous best score under these conditions
      final bestScoreQuery = await FirebaseFirestore.instance
          .collection('scores')
          .where('userId', isEqualTo: user.uid)
          .where('duration', isEqualTo: widget.durationInSeconds)
          .where('difficulty', isEqualTo: widget.difficultyLevel)
          .orderBy('wpm', descending: true)
          .limit(1)
          .get();

      // 2. Check if the current score is a new best
      if (bestScoreQuery.docs.isEmpty || wpm > (bestScoreQuery.docs.first.data()['wpm'] ?? 0)) {
        isNewBest = true;
      }

      // 3. Save the new score
      await FirebaseFirestore.instance.collection('scores').add({
        'userId': user.uid, 'wpm': wpm, 'accuracy': acc, 'inaccuracies': _inaccuracies,
        'duration': widget.durationInSeconds, 'difficulty': widget.difficultyLevel,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    // --- Navigate to the enhanced game over screen ---
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TypingGameOverScreen(
            accuracy: acc,
            wpm: wpm,
            inaccuracies: _inaccuracies,
            correctChars: _correctCharsTypedInSession,
            totalChars: _totalCharsTypedInSession,
            isNewBest: isNewBest,
          ),
        ),
      );
    }
  }

  // ... (getColoredTextSpans and build methods remain the same) ...
  List<TextSpan> getColoredTextSpans() {
    List<TextSpan> spans = [];
    if (targetSentence.isEmpty) return spans;
    for (int i = 0; i < targetSentence.length; i++) {
      Color color;
      if (i < userInput.length) {
        color = userInput[i] == targetSentence[i] ? Colors.greenAccent : Colors.redAccent;
      } else {
        color = Colors.white54;
      }
      spans.add(TextSpan(
          text: targetSentence[i],
          style: GoogleFonts.robotoMono(color: color, fontSize: 26, letterSpacing: 1.2)));
    }
    if (userInput.length < targetSentence.length && isGameStarted) {
      spans.insert(
        userInput.length,
        TextSpan(
          text: '|',
          style: GoogleFonts.robotoMono(
            color: _showCursor ? Colors.white : Colors.transparent,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _colorAnimation,
                  builder: (context, child) {
                    return Text(
                      "⏳ Time Left: $timeLeft sec",
                      style: TextStyle(
                        fontSize: 22,
                        color: timeLeft < 10 ? _colorAnimation.value : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 1, height: 1,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        autofocus: true,
                        onChanged: onInputChange,
                        enabled: isGameStarted,
                        keyboardType: TextInputType.text,
                        autocorrect: false,
                        enableSuggestions: false,
                        style: const TextStyle(color: Colors.transparent),
                        decoration: const InputDecoration(border: InputBorder.none, fillColor: Colors.transparent, filled: true),
                        showCursor: false,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(children: getColoredTextSpans()),
                      ).animate(controller: _shakeController).shakeX(hz: 8, amount: 8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}