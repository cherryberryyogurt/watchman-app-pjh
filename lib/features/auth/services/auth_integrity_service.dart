import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for monitoring and maintaining integrity between Firebase Auth and Firestore
class AuthIntegrityService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  Timer? _integrityCheckTimer;
  
  // Singleton pattern
  static AuthIntegrityService? _instance;
  
  AuthIntegrityService._({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : 
    _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
    _firestore = firestore ?? FirebaseFirestore.instance;
    
  static AuthIntegrityService get instance {
    _instance ??= AuthIntegrityService._();
    return _instance!;
  }
  
  // Start periodic integrity checks (e.g., call from app initialization)
  void startPeriodicChecks({Duration interval = const Duration(hours: 24)}) {
    // Cancel any existing timer
    _integrityCheckTimer?.cancel();
    
    // Start a new timer for periodic checks
    _integrityCheckTimer = Timer.periodic(interval, (_) {
      performIntegrityCheck();
    });
    
    debugPrint('AuthIntegrityService: Started periodic integrity checks, interval: ${interval.inHours}h');
  }
  
  // Stop periodic integrity checks (e.g., call when app is terminated)
  void stopPeriodicChecks() {
    _integrityCheckTimer?.cancel();
    _integrityCheckTimer = null;
    debugPrint('AuthIntegrityService: Stopped periodic integrity checks');
  }
  
  // Log an authentication error
  Future<void> logAuthError({
    required String operation,
    required String errorMessage,
    String? userId,
    String? email,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final logEntry = {
        'operation': operation,
        'errorMessage': errorMessage,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
        'email': email,
        'platform': defaultTargetPlatform.toString(),
        'additionalData': additionalData,
      };
      
      await _firestore.collection('system_logs').doc('auth_errors').collection('errors')
        .add(logEntry);
      
      debugPrint('AuthIntegrityService: Logged auth error - $operation: $errorMessage');
    } catch (e) {
      debugPrint('AuthIntegrityService: Failed to log auth error - $e');
    }
  }
  
  // Perform integrity check between Firebase Auth and Firestore
  Future<Map<String, dynamic>> performIntegrityCheck({bool autoFix = true}) async {
    debugPrint('AuthIntegrityService: Starting integrity check');
    
    final result = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'orphanedAuthUsers': 0,
      'missingAuthUsers': 0,
      'autoFixed': 0,
      'errors': <String>[],
    };
    
    try {
      // This approach has limitations due to Firebase Auth ListUsers being admin-only
      // For a real app, this would use Firebase Admin SDK via a Cloud Function
      
      // For now, we'll check if the current user is consistent
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        await _checkUserIntegrity(currentUser.uid, autoFix, result);
      }
      
      // Log the integrity check result
      await _firestore.collection('system_logs').doc('integrity_checks')
        .collection('checks').add(result);
        
      debugPrint('AuthIntegrityService: Integrity check completed - ${result['autoFixed']} issues auto-fixed');
    } catch (e) {
      debugPrint('AuthIntegrityService: Error during integrity check - $e');
      (result['errors'] as List<String>).add(e.toString());
    }
    
    return result;
  }
  
  // Check integrity for a specific user
  Future<void> _checkUserIntegrity(
    String uid, 
    bool autoFix, 
    Map<String, dynamic> result
  ) async {
    try {
      // Check if Firebase Auth user exists
      firebase_auth.User? authUser;
      try {
        // Note: this is limited to checking the current user only
        // A full implementation would use Admin SDK to list all users
        authUser = _firebaseAuth.currentUser;
        if (authUser == null || authUser.uid != uid) {
          // This indicates the user doesn't exist in Firebase Auth
          result['missingAuthUsers']++;
          debugPrint('AuthIntegrityService: User exists in Firestore but not in Firebase Auth - $uid');
          return;
        }
      } catch (e) {
        result['missingAuthUsers']++;
        debugPrint('AuthIntegrityService: Error checking Firebase Auth user - $e');
        return;
      }
      
      // Check if Firestore document exists
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        result['orphanedAuthUsers']++;
        debugPrint('AuthIntegrityService: User exists in Firebase Auth but not in Firestore - $uid');
        
        if (autoFix) {
          // Attempt to create a Firestore document for this user
          await _createFirestoreUser(authUser);
          result['autoFixed']++;
          debugPrint('AuthIntegrityService: Auto-fixed - Created Firestore document for user - $uid');
        }
      }
    } catch (e) {
      debugPrint('AuthIntegrityService: Error checking user integrity - $e');
      (result['errors'] as List<String>).add(e.toString());
    }
  }
  
  // Create a Firestore document for a Firebase Auth user
  Future<void> _createFirestoreUser(firebase_auth.User authUser) async {
    final now = DateTime.now();
    
    final userData = {
      'uid': authUser.uid,
      'email': authUser.email ?? '',
      'name': authUser.displayName ?? authUser.email?.split('@')[0] ?? 'User',
      'isPhoneVerified': authUser.phoneNumber != null,
      'createdAt': now,
      'updatedAt': now,
      '_autoCreated': true,
    };
    
    await _firestore.collection('users').doc(authUser.uid).set(userData);
  }
  
  // Run more comprehensive check (for admin use)
  // This would be implemented via a Cloud Function in a real app
  Future<Map<String, dynamic>> adminCheckAllUsers() async {
    final result = {
      'timestamp': DateTime.now().toIso8601String(),
      'message': 'Full integrity check requires Admin SDK and should be run as a scheduled Cloud Function',
      'recommendation': 'Implement a Cloud Function that uses the Firebase Admin SDK to list all users',
    };
    
    debugPrint('AuthIntegrityService: Admin-level integrity check requires Cloud Functions with Admin SDK');
    return result;
  }
} 