import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gonggoo_app/main.dart';
import 'package:gonggoo_app/features/auth/screens/login_screen.dart';
import 'package:gonggoo_app/features/auth/screens/register_screen.dart';
import 'package:gonggoo_app/features/auth/screens/edit_profile_screen.dart';
import 'package:gonggoo_app/features/home/screens/home_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('인증 통합 테스트', () {
    testWidgets('전체 인증 흐름: 로그인 → 로그아웃', (WidgetTester tester) async {
      // 앱 실행
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      // 로그인 화면으로 이동 (앱 시작 후 로그인 화면이 표시되지 않는 경우)
      if (find.byType(LoginScreen).evaluate().isEmpty) {
        // 홈 화면에서 프로필 탭으로 이동
        await tester.tap(find.byIcon(Icons.person_outline));
        await tester.pumpAndSettle();

        // 로그아웃 버튼을 찾아서 탭
        await tester.tap(find.byIcon(Icons.logout));
        await tester.pumpAndSettle();

        // 확인 다이얼로그에서 '로그아웃' 버튼 탭
        await tester.tap(find.text('로그아웃').last);
        await tester.pumpAndSettle();
      }

      // 이제 로그인 화면에 있어야 함
      expect(find.byType(LoginScreen), findsOneWidget);

      // 이메일과 비밀번호 입력
      await tester.enterText(
        find.byType(TextFormField).first, 
        'test@example.com'
      );
      await tester.enterText(
        find.byType(TextFormField).at(1), 
        'password123'
      );

      // 로그인 버튼 탭
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(const Duration(seconds: 3)); // 네트워크 요청 대기

      // 로그인 성공 시 홈 화면으로 이동해야 함
      // 주의: 실제 테스트에서는 유효한 계정이 필요합니다
      expect(find.byType(HomeScreen), findsOneWidget);

      // 프로필 탭으로 이동
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // 로그아웃 버튼 탭
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // 확인 다이얼로그에서 '로그아웃' 버튼 탭
      await tester.tap(find.text('로그아웃').last);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 로그아웃 후 로그인 화면으로 돌아가야 함
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('회원가입 화면 이동 및 폼 테스트', (WidgetTester tester) async {
      // 앱 실행
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      // 로그인 화면으로 이동 (앱 시작 후 로그인 화면이 표시되지 않는 경우)
      if (find.byType(LoginScreen).evaluate().isEmpty) {
        // 홈 화면에서 프로필 탭으로 이동
        await tester.tap(find.byIcon(Icons.person_outline));
        await tester.pumpAndSettle();

        // 로그아웃 버튼을 찾아서 탭
        await tester.tap(find.byIcon(Icons.logout));
        await tester.pumpAndSettle();

        // 확인 다이얼로그에서 '로그아웃' 버튼 탭
        await tester.tap(find.text('로그아웃').last);
        await tester.pumpAndSettle();
      }

      // 회원가입 링크 탭
      await tester.tap(find.text('회원가입'));
      await tester.pumpAndSettle();

      // 회원가입 화면으로 이동했는지 확인
      expect(find.byType(RegisterScreen), findsOneWidget);

      // 회원가입 폼 검증
      // 유효하지 않은 데이터로 회원가입 시도
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), 'invalid-email');
      await tester.enterText(find.byType(TextFormField).at(2), 'pass');
      await tester.enterText(find.byType(TextFormField).at(3), 'pass123');

      // 회원가입 버튼 탭
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // 유효성 검사 오류 메시지가 표시되어야 함
      expect(find.text('올바른 이메일 형식이 아닙니다'), findsOneWidget);
      expect(find.text('비밀번호는 최소 6자 이상이어야 합니다'), findsOneWidget);
      expect(find.text('비밀번호가 일치하지 않습니다'), findsOneWidget);

      // 뒤로 가기 버튼 탭
      await tester.tap(find.text('로그인'));
      await tester.pumpAndSettle();

      // 로그인 화면으로 돌아왔는지 확인
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('프로필 수정 화면 접근 및 기능 테스트', (WidgetTester tester) async {
      // 앱 실행
      await tester.pumpWidget(const ProviderScope(child: MyApp()));
      await tester.pumpAndSettle();

      // 로그인되어 있지 않다면 로그인
      if (find.byType(LoginScreen).evaluate().isNotEmpty) {
        // 이메일과 비밀번호 입력
        await tester.enterText(
          find.byType(TextFormField).first, 
          'test@example.com'
        );
        await tester.enterText(
          find.byType(TextFormField).at(1), 
          'password123'
        );

        // 로그인 버튼 탭
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // 홈 화면에서 프로필 탭으로 이동
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // 프로필 수정 버튼 찾기 (text가 '수정'인 버튼)
      await tester.tap(find.text('수정'));
      await tester.pumpAndSettle();

      // 프로필 수정 화면으로 이동했는지 확인
      expect(find.byType(EditProfileScreen), findsOneWidget);

      // 현재 이름 확인 및 수정
      final nameField = find.byType(TextFormField).first;
      final currentName = tester.widget<TextFormField>(nameField).controller!.text;
      await tester.enterText(nameField, '$currentName Test');

      // 전화번호 수정
      await tester.enterText(find.byType(TextFormField).at(1), '010-1234-5678');

      // 주소 수정
      await tester.enterText(find.byType(TextFormField).at(2), '서울시 강남구 테스트로');

      // 저장 버튼 탭
      await tester.tap(find.text('저장하기'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 홈 화면으로 돌아갔는지 확인
      expect(find.byType(HomeScreen), findsOneWidget);

      // 프로필 탭으로 다시 이동하여 변경사항 확인
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle();

      // 변경된 정보가 표시되는지 확인
      expect(find.textContaining('$currentName Test'), findsOneWidget);
      expect(find.text('010-1234-5678'), findsOneWidget);
      expect(find.text('서울시 강남구 테스트로'), findsOneWidget);
    });
  });
} 