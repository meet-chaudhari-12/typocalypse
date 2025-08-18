import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class UserStats {
  final double bestWpm;
  final double avgAccuracy;
  final int gamesPlayed;
  final List<QueryDocumentSnapshot> recentScores;

  UserStats({
    required this.bestWpm,
    required this.avgAccuracy,
    required this.gamesPlayed,
    required this.recentScores,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<UserStats> _userStatsFuture;

  @override
  void initState() {
    super.initState();
    _userStatsFuture = _fetchUserStats();
  }

  Future<UserStats> _fetchUserStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('scores')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .get();

    final scores = querySnapshot.docs;
    if (scores.isEmpty) {
      return UserStats(bestWpm: 0, avgAccuracy: 0, gamesPlayed: 0, recentScores: []);
    }

    double bestWpm = 0;
    double totalAccuracy = 0;

    for (var doc in scores) {
      final data = doc.data();
      bestWpm = max(bestWpm, (data['wpm'] ?? 0.0).toDouble());
      totalAccuracy += (data['accuracy'] ?? 0.0).toDouble();
    }

    final avgAccuracy = totalAccuracy / scores.length;

    return UserStats(
      bestWpm: bestWpm,
      avgAccuracy: avgAccuracy,
      gamesPlayed: scores.length,
      recentScores: scores,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Your Profile'),
        backgroundColor: Colors.black,
      ),
      body: FutureBuilder<UserStats>(
        future: _userStatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.gamesPlayed == 0) {
            return const Center(child: Text("No games played yet."));
          }

          final stats = snapshot.data!;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _StatCard(title: 'Best WPM', value: stats.bestWpm.toStringAsFixed(1)),
                    _StatCard(title: 'Avg Accuracy', value: '${stats.avgAccuracy.toStringAsFixed(1)}%'),
                    _StatCard(title: 'Games Played', value: stats.gamesPlayed.toString()),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, indent: 16, endIndent: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text("Recent Games", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView.builder(
                    itemCount: stats.recentScores.length,
                    itemBuilder: (context, index) {
                      final score = stats.recentScores[index].data() as Map<String, dynamic>;
                      final timestamp = score['timestamp'] as Timestamp?;
                      return Card(
                        color: Colors.white.withOpacity(0.05),
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          leading: Icon(Icons.history, color: Theme.of(context).primaryColor),
                          title: Text('WPM: ${score['wpm']?.toStringAsFixed(1) ?? 'N/A'}'),
                          subtitle: Text('Accuracy: ${score['accuracy']?.toStringAsFixed(1) ?? 'N/A'}%'),
                          trailing: Text(
                              timestamp != null
                                  ? '${timestamp.toDate().toLocal().year}-${timestamp.toDate().toLocal().month.toString().padLeft(2, '0')}-${timestamp.toDate().toLocal().day.toString().padLeft(2, '0')}'
                                  : 'No date'
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}