import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gonggoo_app/features/auth/screens/login_screen.dart';
import 'package:gonggoo_app/features/auth/screens/register_screen.dart';
import 'package:gonggoo_app/features/auth/providers/auth_state.dart';

// Custom Auth class for testing - override the build method
class TestAuth extends Auth {
  @override
  Stream<AuthState> build() {
    return Stream.value(const AuthState());
  }

  // Mock methods for testing
  final signInCalls = <({String email, String password, bool rememberMe})>[];
  final signUpCalls = <({String email, String password, String name, String? phone})>[];

  @override
  Future<void> signInWithEmailAndPassword(
    String email, 
    String password, 
    bool rememberMe
  ) async {
    signInCalls.add((email: email, password: password, rememberMe: rememberMe));
  }

  @override
  Future<void> signUpWithEmailAndPassword(
    String email, 
    String password, 
    String name, 
    String? phone
  ) async {
    signUpCalls.add((email: email, password: password, name: name, phone: phone));
  }
}

void main() {
  late TestAuth testAuth;

  setUp(() {
    testAuth = TestAuth();
  });

  group('로그인 화면 테스트', () {
    testWidgets('로그인 폼이 올바르게 렌더링되어야 함', (WidgetTester tester) async {
      // 준비
      // 필요한 Provider 오버라이드
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => testAuth),
          ],
          child: MaterialApp(
            home: const LoginScreen(),
          ),
        ),
      );

      // 화면이 완전히 빌드될 때까지 기다림
      await tester.pumpAndSettle();

      // 검증
      expect(find.text('로그인'), findsWidgets);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(2)); // 이메일과 비밀번호 필드
      expect(find.byType(ElevatedButton), findsOneWidget); // 로그인 버튼
      expect(find.text('회원가입'), findsOneWidget); // 회원가입 링크
    });

    testWidgets('유효하지 않은 이메일 주소로 폼 검증이 작동해야 함', (WidgetTester tester) async {
      // 준비
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => testAuth),
          ],
          child: MaterialApp(
            home: const LoginScreen(),
          ),
        ),
      );

      // 화면이 완전히 빌드될 때까지 기다림
      await tester.pumpAndSettle();

      // 잘못된 이메일 입력
      await tester.enterText(find.byType(TextFormField).at(0), 'invalid-email');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      // 로그인 버튼 탭
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // 이메일 유효성 검사 오류 메시지가 표시되는지 확인
      expect(find.text('올바른 이메일 형식이 아닙니다'), findsOneWidget);
    });

    testWidgets('유효한 정보로 로그인 시도시 Auth 프로바이더 호출되어야 함', (WidgetTester tester) async {
      // 준비
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => testAuth),
          ],
          child: MaterialApp(
            home: const LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 유효한 이메일과 비밀번호 입력
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      // 로그인 버튼 탭
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // signInWithEmailAndPassword 호출 확인
      expect(testAuth.signInCalls.length, 1);
      expect(testAuth.signInCalls.first.email, 'test@example.com');
      expect(testAuth.signInCalls.first.password, 'password123');
      expect(testAuth.signInCalls.first.rememberMe, true);
    });
  });

  group('회원가입 화면 테스트', () {
    testWidgets('회원가입 폼이 올바르게 렌더링되어야 함', (WidgetTester tester) async {
      // 준비
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => testAuth),
          ],
          child: MaterialApp(
            home: const RegisterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 검증
      expect(find.text('회원가입'), findsWidgets);
      expect(find.byType(TextFormField), findsAtLeastNWidgets(4)); // 이름, 이메일, 비밀번호, 비밀번호 확인
      expect(find.byType(ElevatedButton), findsOneWidget); // 회원가입 버튼
    });

    testWidgets('비밀번호 불일치 시 폼 검증이 작동해야 함', (WidgetTester tester) async {
      // 준비
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => testAuth),
          ],
          child: MaterialApp(
            home: const RegisterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 이름, 이메일 입력
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');

      // 서로 다른 비밀번호 입력
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password456');

      // 회원가입 버튼 탭
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // 비밀번호 불일치 오류 메시지가 표시되는지 확인
      expect(find.text('비밀번호가 일치하지 않습니다'), findsOneWidget);
    });

    testWidgets('유효한 정보로 회원가입 시도시 Auth 프로바이더 호출되어야 함', (WidgetTester tester) async {
      // 준비
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(() => testAuth),
          ],
          child: MaterialApp(
            home: const RegisterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 유효한 정보 입력
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'password123');

      // 회원가입 버튼 탭
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // signUpWithEmailAndPassword 호출 확인
      expect(testAuth.signUpCalls.length, 1);
      expect(testAuth.signUpCalls.first.email, 'test@example.com');
      expect(testAuth.signUpCalls.first.password, 'password123');
      expect(testAuth.signUpCalls.first.name, 'Test User');
      expect(testAuth.signUpCalls.first.phone, null);
    });
  });
} 