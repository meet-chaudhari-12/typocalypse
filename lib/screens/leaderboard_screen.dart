import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Leaderboard")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('scores')
            .orderBy('wpm', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final scores = snapshot.data!.docs;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            final index = scores.indexWhere((s) => s['userId'] == user?.uid);
            if (index != -1) {
              _scrollController.animateTo(
                index * 72.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          });

          return ListView.builder(
            controller: _scrollController,
            itemCount: scores.length,
            itemBuilder: (context, index) {
              final data = scores[index];
              final isCurrentUser = data['userId'] == user?.uid;
              return Container(
                color: isCurrentUser ? Colors.yellow.withOpacity(0.3) : Colors.transparent,
                child: ListTile(
                  title: Text(data['email'] ?? "Unknown"),
                  subtitle: Text("WPM: ${data['wpm'].toStringAsFixed(2)}, Accuracy: ${data['accuracy'].toStringAsFixed(2)}%"),
                  trailing: Text("${index + 1}"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}