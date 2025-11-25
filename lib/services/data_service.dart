// lib/data_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class DataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream for Announcements
  Stream<QuerySnapshot> getAnnouncements() {
    return _firestore.collection('announcements').snapshots();
  }

  // Stream for Barangay Officials
  Stream<QuerySnapshot> getOfficials() {
    return _firestore
        .collection('brgyOfficials')
        .orderBy('position', descending: false)
        .snapshots();
  }

  // Stream for Emergency Hotlines
  Stream<QuerySnapshot> getHotlines() {
    return _firestore.collection('emergencyHotlines').snapshots();
  }
}
