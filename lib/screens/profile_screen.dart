import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';

// Data Model
class UserStats {
  final String uid;
  final String username;
  final String email;
  final String? profileImageUrl;
  final Timestamp? profileLastUpdated;
  final double bestWpm;
  final double avgAccuracy;
  final int gamesPlayed;
  final List<QueryDocumentSnapshot> recentScores;

  UserStats({
    required this.uid,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.profileLastUpdated,
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
    if (user == null) throw Exception("User not logged in");

    final userDocSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDocSnapshot.data() ?? {};

    final scoresSnapshot = await FirebaseFirestore.instance.collection('scores').where('userId', isEqualTo: user.uid).orderBy('timestamp', descending: true).limit(20).get();
    final scores = scoresSnapshot.docs;

    double bestWpm = 0;
    double totalAccuracy = 0;
    for (var doc in scores) {
      final data = doc.data();
      bestWpm = max(bestWpm, (data['wpm'] ?? 0.0).toDouble());
      totalAccuracy += (data['accuracy'] ?? 0.0).toDouble();
    }

    return UserStats(
      uid: user.uid,
      username: userData['username'] ?? user.email?.split('@')[0] ?? 'Guest',
      email: user.email ?? '',
      profileImageUrl: userData['profileImageUrl'],
      profileLastUpdated: userData['profileLastUpdated'],
      bestWpm: bestWpm,
      avgAccuracy: scores.isEmpty ? 0 : totalAccuracy / scores.length,
      gamesPlayed: scores.length,
      recentScores: scores,
    );
  }

  void _showEditProfileSheet(BuildContext context, UserStats currentStats) {
    final usernameController = TextEditingController(text: currentStats.username);
    File? newImageFile;
    Uint8List? newImageBytes;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (modalContext, setModalState) {
          Future<void> pickImage() async {
            final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 150);
            if (pickedImage == null) return;

            if (kIsWeb) {
              final bytes = await pickedImage.readAsBytes();
              setModalState(() => newImageBytes = bytes);
            } else {
              setModalState(() => newImageFile = File(pickedImage.path));
            }
          }

          ImageProvider? getImageProvider() {
            if (newImageBytes != null) return MemoryImage(newImageBytes!);
            if (newImageFile != null) return FileImage(newImageFile!);
            if (currentStats.profileImageUrl != null) {
              final lastUpdated = currentStats.profileLastUpdated?.millisecondsSinceEpoch ?? '';
              return NetworkImage("${currentStats.profileImageUrl!}?v=$lastUpdated");
            }
            return null;
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Edit Profile", style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: getImageProvider(),
                    backgroundColor: Theme.of(context).cardColor,
                    child: getImageProvider() == null ? Icon(Icons.person, size: 40, color: Colors.grey[600]) : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(controller: usernameController, decoration: const InputDecoration(labelText: "Username")),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (!mounted) return;
                    setModalState(() => isLoading = true);

                    try {
                      String? finalImageUrl = currentStats.profileImageUrl;

                      // Only attempt to upload if a new image was actually selected
                      if (newImageFile != null || newImageBytes != null) {
                        final storageRef = FirebaseStorage.instance.ref().child('user_images').child(currentStats.uid);
                        if (kIsWeb) {
                          await storageRef.putData(newImageBytes!);
                        } else {
                          await storageRef.putFile(newImageFile!);
                        }
                        finalImageUrl = await storageRef.getDownloadURL();
                      }

                      // Prepare data for Firestore update
                      final updateData = {
                        'username': usernameController.text.trim(),
                        'profileImageUrl': finalImageUrl,
                        'profileLastUpdated': FieldValue.serverTimestamp(),
                      };

                      await FirebaseFirestore.instance.collection('users').doc(currentStats.uid).update(updateData);

                      if (mounted) {
                        Navigator.pop(modalContext);
                        setState(() { _userStatsFuture = _fetchUserStats(); });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update: ${e.toString()}")));
                      }
                    } finally {
                      // This GUARANTEES the loading indicator will stop, even if an error occurs.
                      if (mounted) {
                        setModalState(() => isLoading = false);
                      }
                    }
                  },
                  child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Save Changes"),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        });
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        actions: [
          FutureBuilder<UserStats>(
            future: _userStatsFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: "Edit Profile",
                  onPressed: () => _showEditProfileSheet(context, snapshot.data!),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
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
          if (!snapshot.hasData) {
            return const Center(child: Text("Could not load user data."));
          }
          final stats = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: _buildProfileHeader(stats.username, stats.email, stats.profileImageUrl, stats.profileLastUpdated),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.2, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  delegate: SliverChildListDelegate([
                    _StatCard(title: 'Best WPM', value: stats.bestWpm.toStringAsFixed(0), icon: Icons.speed, color: Theme.of(context).colorScheme.primary),
                    _StatCard(title: 'Avg Accuracy', value: '${stats.avgAccuracy.toStringAsFixed(1)}%', icon: Icons.track_changes, color: Colors.greenAccent),
                    _StatCard(title: 'Games Played', value: stats.gamesPlayed.toString(), icon: Icons.gamepad_outlined, color: Theme.of(context).colorScheme.secondary),
                  ]),
                ),
              ),
              if (stats.recentScores.isNotEmpty) ...[
                SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0), child: Text("Performance History", style: Theme.of(context).textTheme.titleLarge))),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(height: 200, padding: const EdgeInsets.only(top: 16, right: 16), decoration: BoxDecoration(color: Theme.of(context).cardColor.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                      child: _ProgressChart(scores: stats.recentScores, bestWpm: stats.bestWpm),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0), child: Text("Recent Games", style: Theme.of(context).textTheme.titleLarge))),
                SliverList(delegate: SliverChildBuilderDelegate((context, index) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: _buildHistoryTile(stats.recentScores[index].data() as Map<String, dynamic>, context)), childCount: stats.recentScores.length)),
              ] else SliverToBoxAdapter(child: const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("Play a game to see your stats!")))),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24.0)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String username, String email, String? imageUrl, Timestamp? lastUpdated) {
    ImageProvider? backgroundImage;
    if (imageUrl != null) {
      final cacheBustingUrl = "$imageUrl?v=${lastUpdated?.millisecondsSinceEpoch ?? ''}";
      backgroundImage = NetworkImage(cacheBustingUrl);
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: backgroundImage,
            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            child: backgroundImage == null
                ? Text(username.isNotEmpty ? username[0].toUpperCase() : "?", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(Map<String, dynamic> scoreData, BuildContext context) {
    final timestamp = scoreData['timestamp'] as Timestamp?;
    final wpm = (scoreData['wpm'] ?? 0.0).toDouble();
    final accuracy = (scoreData['accuracy'] ?? 0.0).toDouble();
    final dateString = timestamp != null ? "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}" : "No date";
    return Card(margin: const EdgeInsets.only(bottom: 8.0), elevation: 0, color: Theme.of(context).cardColor.withOpacity(0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), leading: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(wpm.toStringAsFixed(0), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)), Text("WPM", style: TextStyle(fontSize: 12, color: Colors.grey[400]))]), title: Text('Accuracy: ${accuracy.toStringAsFixed(1)}%'), subtitle: Text(dateString), trailing: Icon(Icons.keyboard_arrow_right, color: Colors.grey[600])));
  }

  Widget _StatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).cardColor.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 24, color: color), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)), Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[400]), overflow: TextOverflow.ellipsis)])]));
  }
}

class _ProgressChart extends StatelessWidget {
  final List<QueryDocumentSnapshot> scores;
  final double bestWpm;

  const _ProgressChart({Key? key, required this.scores, required this.bestWpm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reversedScores = scores.reversed.toList();
    final List<FlSpot> spots = [];
    for (int i = 0; i < reversedScores.length; i++) {
      final wpm = (reversedScores[i].data() as Map<String, dynamic>)['wpm'] ?? 0.0;
      spots.add(FlSpot(i.toDouble(), wpm.toDouble()));
    }
    final double calculatedMaxY = ((bestWpm + 5.0) / 10).ceil() * 10.0;
    final double chartMaxY = max(calculatedMaxY, 40);
    return LineChart(
      LineChartData(
        gridData: _buildGridData(),
        titlesData: _buildTitlesData(chartMaxY),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.2))),
        minX: 0,
        maxX: spots.isNotEmpty ? spots.length.toDouble() - 1 : 0,
        minY: 0,
        maxY: chartMaxY,
        lineBarsData: _buildLineBarsData(context, spots),
      ),
    );
  }

  FlGridData _buildGridData() {
    return FlGridData(
      show: true, drawVerticalLine: true, horizontalInterval: 10, verticalInterval: 1,
      getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
      getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
    );
  }

  FlTitlesData _buildTitlesData(double chartMaxY) {
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true, reservedSize: 44, interval: 10,
          getTitlesWidget: (value, meta) {
            if (value == 0 || value > chartMaxY) return Container();
            return Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            );
          },
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData(BuildContext context, List<FlSpot> spots) {
    return [
      LineChartBarData(
        spots: spots, isCurved: true,
        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary]),
        barWidth: 4, isStrokeCapRound: true, dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary.withOpacity(0.3), Theme.of(context).colorScheme.secondary.withOpacity(0.1)]),
        ),
      ),
    ];
  }
}

