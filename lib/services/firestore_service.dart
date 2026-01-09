import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user has entered surgery details
  Future<bool> hasSurgeryData() async {
    if (currentUserId == null) return false;
    final doc = await _db.collection('users').doc(currentUserId).get();
    return doc.exists && doc.data() != null && doc.data()!.containsKey('surgeryDate');
  }

  // Save surgery details
  Future<void> saveSurgeryData({
    required String name,
    required DateTime date,
    required String type,
  }) async {
    if (currentUserId == null) throw Exception("User not logged in");
    await _db.collection('users').doc(currentUserId).set({
      'name': name,
      'surgeryDate': Timestamp.fromDate(date),
      'surgeryType': type,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get user name and surgery date for Home Screen
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUserId == null) return null;
    final doc = await _db.collection('users').doc(currentUserId).get();
    return doc.data();
  }

  // Check if survey for today is already done
  Future<bool> isDailySurveyDone() async {
    if (currentUserId == null) return false;
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final doc = await _db
        .collection('users')
        .doc(currentUserId)
        .collection('surveys')
        .doc(todayStr)
        .get();
    return doc.exists;
  }

  // Get total survey count
  Future<int> getSurveyCount() async {
    if (currentUserId == null) return 0;
    final snapshot = await _db
        .collection('users')
        .doc(currentUserId)
        .collection('surveys')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // Save daily survey
  Future<void> saveDailySurvey({
    required int painLevel,
    required List<String> symptoms,
    required String note,
  }) async {
    if (currentUserId == null) throw Exception("User not logged in");
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    
    await _db
        .collection('users')
        .doc(currentUserId)
        .collection('surveys')
        .doc(todayStr)
        .set({
      'painLevel': painLevel,
      'symptoms': symptoms,
      'note': note,
      'date': Timestamp.now(),
    });
  }

  // Get surveys for the last 7 days
  Future<List<Map<String, dynamic>>> getWeeklySurveys() async {
    if (currentUserId == null) return [];
    
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final snapshot = await _db
        .collection('users')
        .doc(currentUserId)
        .collection('surveys')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
