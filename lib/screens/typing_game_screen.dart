import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:typocalypse/screens/game_over_screen.dart';
import 'package:audioplayers/audioplayers.dart';

class TypingGameScreen extends StatefulWidget {
  final List<String> sentences;
  final int durationInSeconds;

  const TypingGameScreen({
    Key? key,
    required this.sentences,
    this.durationInSeconds = 30,
  }) : super(key: key);

  @override
  State<TypingGameScreen> createState() => _TypingGameScreenState();
}

class _TypingGameScreenState extends State<TypingGameScreen> with SingleTickerProviderStateMixin {
  int sentenceIndex = 0;
  String get targetSentence => widget.sentences.isEmpty ? "" : widget.sentences[sentenceIndex];
  String userInput = "";
  late int timeLeft;
  int _totalCharsTypedInSession = 0;
  int _correctCharsTypedInSession = 0;
  int _inaccuracies=0;
  Timer? timer;
  bool isGameStarted = false;
  final TextEditingController _controller = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setReleaseMode(ReleaseMode.release);
    timeLeft = widget.durationInSeconds;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _colorAnimation = ColorTween(begin: Colors.white, end: Colors.redAccent)
        .animate(_animationController);

    _animationController.repeat(reverse: true);

    startGame();
  }

  void startGame() {
    setState(() {
      isGameStarted = true;
      sentenceIndex = 0;
      userInput = "";
      _totalCharsTypedInSession = 0;
      _correctCharsTypedInSession = 0;
      timeLeft = widget.durationInSeconds;
      _controller.clear();
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

    if (newInput.length >= targetSentence.length) {
      final finalInput = newInput.substring(0, targetSentence.length);

      if (newInput.length > userInput.length) {
        int pos = newInput.length - 1;
        if (pos < targetSentence.length) {
          if (newInput[pos] != targetSentence[pos]) {
            _inaccuracies++;
          }
        } else {
          _inaccuracies++;
        }
      }

      for (int i = 0; i < targetSentence.length; i++) {
        if (finalInput[i] == targetSentence[i]) {
          _correctCharsTypedInSession++;
        }
      }
      _totalCharsTypedInSession += targetSentence.length;

      int nextSentenceIndex = sentenceIndex + 1;
      if (nextSentenceIndex >= widget.sentences.length) {
        nextSentenceIndex = 0;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.clear();
      });

      setState(() {
        sentenceIndex = nextSentenceIndex;
        userInput = "";
      });
      return;
    }

    setState(() {
      userInput = newInput;
    });
  }

  void endGame() async {
    timer?.cancel();
    if (!mounted) return;
    setState(() => isGameStarted = false);

    _audioPlayer.play(AssetSource('audio/game_over.mp3'));

    for (int i = 0; i < userInput.length; i++) {
      if (i < targetSentence.length && userInput[i] == targetSentence[i]) {
        _correctCharsTypedInSession++;
      }
    }
    _totalCharsTypedInSession += userInput.length;

    final double wpm = (_correctCharsTypedInSession / 5) / (widget.durationInSeconds / 60.0);
    final double acc = (_totalCharsTypedInSession + _inaccuracies) == 0 ? 0 : (_correctCharsTypedInSession / (_totalCharsTypedInSession + _inaccuracies)) * 100;
    final int inaccuracies =_inaccuracies;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('scores').add({
        'userId': user.uid,
        'email': user.email,
        'wpm': wpm,
        'accuracy': acc,
        'inaccuracies': inaccuracies,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TypingGameOverScreen(
            accuracy: acc,
            wpm: wpm,
            inaccuracies: inaccuracies,
          ),
        ),
      );
    }
  }

  List<TextSpan> getColoredTextSpans() {
    List<TextSpan> spans = [];
    if (targetSentence.isEmpty) return spans;
    for (int i = 0; i < targetSentence.length; i++) {
      Color color;
      if (i < userInput.length) {
        color = userInput[i] == targetSentence[i] ? Colors.greenAccent : Theme.of(context).colorScheme.error;
      } else {
        color = Colors.white54;
      }
      spans.add(
          TextSpan(
              text: targetSentence[i],
              style: GoogleFonts.ebGaramond(
                color: color,
                fontSize: 28,
                letterSpacing: 1.2,
              )
          )
      );
    }
    return spans;
  }

  @override
  void dispose() {
    _animationController.dispose();
    timer?.cancel();
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
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
                      color: _colorAnimation.value,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: _colorAnimation.value ?? Colors.white,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(children: getColoredTextSpans()),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: onInputChange,
                enabled: isGameStarted,
                style: GoogleFonts.ebGaramond(fontSize: 20, color: Colors.white),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Start typing...",
                  hintStyle: TextStyle(color: Colors.white24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}