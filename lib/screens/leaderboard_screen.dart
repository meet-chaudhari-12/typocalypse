// lib/screens/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Data Model (no changes) ---
class LeaderboardEntry {
  final String username;
  final String? profileImageUrl;
  final double wpm;
  final double accuracy;
  final String userId;

  LeaderboardEntry({
    required this.username,
    this.profileImageUrl,
    required this.wpm,
    required this.accuracy,
    required this.userId,
  });
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  // --- Filter State Variables ---
  final List<int> _timeFilters = [15, 30, 45, 60, 120];
  late int _selectedDuration;

  // NEW: Difficulty filter state
  final List<String> _difficultyFilters = ["Easy", "Medium", "Hard"];
  late String _selectedDifficulty;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedDuration = _timeFilters[0];
    _selectedDifficulty = _difficultyFilters[0]; // Default to "Easy"
    _tabController = TabController(length: _timeFilters.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- UPDATED: Function to fetch with both filters ---
  Future<List<LeaderboardEntry>> _fetchLeaderboard() async {
    final scoresSnapshot = await FirebaseFirestore.instance
        .collection('scores')
        .where('duration', isEqualTo: _selectedDuration)
        .where('difficulty', isEqualTo: _selectedDifficulty) // NEW: Filter by difficulty
        .orderBy('wpm', descending: true)
        .limit(20)
        .get();

    if (scoresSnapshot.docs.isEmpty) return [];

    final userIds = scoresSnapshot.docs.map((doc) => doc['userId'] as String).toSet().toList();

    final Map<String, Map<String, dynamic>> usersMap = {};
    for (var i = 0; i < userIds.length; i += 10) {
      final chunk = userIds.sublist(i, i + 10 > userIds.length ? userIds.length : i + 10);
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (var doc in usersSnapshot.docs) {
        usersMap[doc.id] = doc.data();
      }
    }

    final List<LeaderboardEntry> leaderboardEntries = [];
    for (var scoreDoc in scoresSnapshot.docs) {
      final scoreData = scoreDoc.data();
      final userId = scoreData['userId'];
      final userData = usersMap[userId];

      leaderboardEntries.add(
        LeaderboardEntry(
          userId: userId,
          username: userData?['username'] ?? 'Anonymous',
          profileImageUrl: userData?['profileImageUrl'],
          wpm: (scoreData['wpm'] as num).toDouble(),
          accuracy: (scoreData['accuracy'] as num).toDouble(),
        ),
      );
    }
    return leaderboardEntries;
  }

  // ... _buildMedal method (no changes) ...
  Widget _buildMedal(int index) {
    if (index == 0) return const Text("🥇", style: TextStyle(fontSize: 24));
    if (index == 1) return const Text("🥈", style: TextStyle(fontSize: 24));
    if (index == 2) return const Text("🥉", style: TextStyle(fontSize: 24));
    return Text("${index + 1}", style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold));
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Leaderboard"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _timeFilters.map((duration) => Tab(text: "$duration seconds")).toList(),
          onTap: (index) {
            setState(() {
              _selectedDuration = _timeFilters[index];
            });
          },
        ),
      ),
      body: Column(
        children: [
          // --- NEW: Difficulty Filter Chips ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Wrap(
              spacing: 8.0,
              alignment: WrapAlignment.center,
              children: _difficultyFilters.map((difficulty) {
                return ChoiceChip(
                  label: Text(difficulty),
                  selected: _selectedDifficulty == difficulty,
                  onSelected: (isSelected) {
                    if (isSelected) {
                      setState(() {
                        _selectedDifficulty = difficulty;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // --- Body with FutureBuilder ---
          Expanded(
            child: FutureBuilder<List<LeaderboardEntry>>(
              future: _fetchLeaderboard(),
              // UPDATED: Key now depends on both filters to trigger a refetch
              key: ValueKey('$_selectedDuration-$_selectedDifficulty'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}", textAlign: TextAlign.center));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("No scores found for $_selectedDifficulty - $_selectedDuration seconds."));
                }

                final leaderboard = snapshot.data!;

                return ListView.builder(
                  itemCount: leaderboard.length,
                  itemBuilder: (context, index) {
                    final entry = leaderboard[index];
                    final bool isCurrentUser = entry.userId == currentUser?.uid;

                    return Card(
                      elevation: isCurrentUser ? 4 : 1,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: isCurrentUser ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Theme.of(context).cardColor,
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMedal(index),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: entry.profileImageUrl != null ? NetworkImage(entry.profileImageUrl!) : null,
                              backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                              child: entry.profileImageUrl == null
                                  ? Text(entry.username.isNotEmpty ? entry.username[0].toUpperCase() : "?", style: const TextStyle(fontWeight: FontWeight.bold))
                                  : null,
                            ),
                          ],
                        ),
                        title: Text(entry.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Accuracy: ${entry.accuracy.toStringAsFixed(1)}%"),
                        trailing: Text("${entry.wpm.toStringAsFixed(1)} WPM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}