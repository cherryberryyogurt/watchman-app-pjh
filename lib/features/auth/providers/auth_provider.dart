import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  
  // 스트림 구독을 위한 변수
  StreamSubscription<firebase_auth.User?>? _authStateSubscription;
  
  AuthProvider({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository {
    // 생성자에서 즉시 인증 상태 변화 스트림 구독
    _initAuthStateListener();
  }
  
  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  
  // 인증 상태 스트림 리스너 초기화
  void _initAuthStateListener() {
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (firebase_auth.User? firebaseUser) async {
        if (firebaseUser == null) {
          // 사용자가 로그아웃했거나 인증되지 않은 상태
          _user = null;
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        } else {
          // 사용자가 인증됨
          // 이전 상태가 unauthenticated가 아닐 경우에만 authenticating 상태로 변경
          if (_status != AuthStatus.authenticating) {
            _status = AuthStatus.authenticating;
            notifyListeners();
          }
          
          // 작업을 백그라운드 스레드로 옮김
          await Future(() async {
            try {
              // 토큰 갱신 및 저장
              await _authRepository.getIdToken(true);
              
              // Firestore에서 사용자 정보 가져오기
              final userModel = await _authRepository.getUserModelFromFirestore(firebaseUser.uid);
              
              // UI 업데이트는 메인 스레드에서 수행
              if (userModel != null) {
                _user = userModel;
                _status = AuthStatus.authenticated;
              } else {
                // Firestore에 사용자 정보가 없는 경우
                _status = AuthStatus.error;
                _errorMessage = '사용자 정보를 찾을 수 없습니다.';
              }
              
              notifyListeners();
            } catch (e) {
              _status = AuthStatus.error;
              _errorMessage = e.toString();
              notifyListeners();
            }
          });
        }
      },
      onError: (error) {
        _status = AuthStatus.error;
        _errorMessage = error.toString();
        notifyListeners();
      }
    );
  }
  
  // 기존 loadCurrentUser 메서드는 유지하되, 내부 로직을 변경합니다
  Future<void> loadCurrentUser() async {
    try {
      final firebaseUser = _authRepository.getCurrentFirebaseUser();
      
      if (firebaseUser != null) {
        // 이미 인증된 사용자가 있으면 토큰 갱신 및 Firestore 조회
        await _authRepository.getIdToken(true);
        final userModel = await _authRepository.getUserModelFromFirestore(firebaseUser.uid);
        
        if (userModel != null) {
          _user = userModel;
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
      
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
  
  // Sign in with email and password
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();
      
      final user = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = user;
      _status = AuthStatus.authenticated;
      
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      
      // Re-throw for UI to handle
      rethrow;
    }
  }
  
  // Sign up with email and password
  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();
      
      final user = await _authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
      
      _user = user;
      _status = AuthStatus.authenticated;
      
      notifyListeners();
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      
      // Re-throw for UI to handle
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      
      // 스트림에서 자동으로 감지하므로 상태 변경 코드는 제거해도 됨
      // 하지만 UI 업데이트를 위해 임시로 설정
      _user = null;
      _status = AuthStatus.unauthenticated;
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      
      // Re-throw for UI to handle
      rethrow;
    }
  }
  
  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? address,
    String? addressDetail,
    String? profileImageUrl,
  }) async {
    try {
      if (_user == null) {
        throw Exception('로그인이 필요합니다');
      }
      
      final updatedUser = await _authRepository.updateUserProfile(
        uid: _user!.uid,
        name: name,
        phoneNumber: phoneNumber,
        address: address,
        addressDetail: addressDetail,
        profileImageUrl: profileImageUrl,
      );
      
      _user = updatedUser;
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      
      // Re-throw for UI to handle
      rethrow;
    }
  }
  
  // Set phone verified
  Future<void> setPhoneVerified({
    required String uid,
    required bool verified,
  }) async {
    try {
      final updatedUser = await _authRepository.setPhoneVerified(
        uid: uid,
        verified: verified,
      );
      
      _user = updatedUser;
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      
      // Re-throw for UI to handle
      rethrow;
    }
  }
  
  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      
      // Re-throw for UI to handle
      rethrow;
    }
  }
  
  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  // Update repository - AuthProvider 클래스에서 _authRepository 필드를 업데이트할 수 있는 메소드를 제공합니다.
  // main.dart에서 Provider.update 콜백에서 사용됩니다.
  void updateRepository(AuthRepository repository) {
    // _authRepository 필드는 final로 선언되어 있어서 변경할 수 없으므로, 이 메소드는 실제로 아무 작업도 수행하지 않습니다.
    // 필요하다면 나중에 _authRepository를 final이 아닌 필드로 변경하고 업데이트 기능을 구현할 수 있습니다.
  }
  
  // 리소스 해제
  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
} 