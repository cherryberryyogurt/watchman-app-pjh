import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'core/theme/index.dart';
import 'core/theme/theme_notifier.dart';
import 'core/config/env_config.dart';
import 'features/auth/providers/auth_state.dart';
import 'features/auth/screens/auth_wrapper.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
// import 'features/auth/screens/password_reset_screen.dart'; // 전화번호 인증으로 변경되어 비밀번호 재설정 기능 제거
import 'features/auth/screens/edit_profile_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/products/screens/product_list_screen.dart';
import 'features/cart/screens/cart_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Riverpod 컨테이너를 전역으로 선언
final container = ProviderContainer();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    print('🚀 앱 시작: main() 호출');
    print('🚀 환경 설정 로드 시작...');
  }

  // 🔧 환경 설정 파일(.env) 로드 - 반드시 Firebase 초기화 전에 수행
  try {
    await EnvConfig.load();
    if (kDebugMode) {
      print('✅ 환경 설정 로드 완료!');
      EnvConfig.printEnvStatus();
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ 환경 설정 로드 실패 (기본값 사용): $e');
    }
  }

  if (kDebugMode) {
    print('🚀 Firebase 초기화 시작...');
  }

  try {
    // Firebase 초기화
    final app = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kDebugMode) {
      print('✅ Firebase 초기화 완료!');
      print('🔍 Firebase 앱 정보:');
      print('  - 앱 이름: ${app.name}');
      print('  - 프로젝트 ID: ${app.options.projectId}');
      print('  - API 키: ${app.options.apiKey.substring(0, 10)}...');
      print('  - App ID: ${app.options.appId}');

      // Firebase Auth 초기화 확인
      final auth = FirebaseAuth.instance;
      print('🔍 Firebase Auth 상태:');
      print('  - 현재 사용자: ${auth.currentUser?.uid ?? "없음"}');
      print('  - 앱 언어: ${auth.languageCode ?? "기본값"}');

      // Firestore 초기화 확인
      final firestore = FirebaseFirestore.instance;
      print('🔍 Firestore 설정:');
      print('  - 앱 인스턴스: ${firestore.app.name}');
      print('  - 설정 완료: ✅');
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Firebase 초기화 실패: $e');
    }
    // Firebase 초기화 실패해도 앱은 계속 실행
  }

  if (kDebugMode) {
    print('🚀 ProviderScope로 앱 실행...');
  }

  // 앱이 세로 방향으로만 동작하도록 제한 (회전 방향 제한)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 시스템 UI 오버레이 스타일 설정
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // 상태바 배경색을 투명하게
      statusBarIconBrightness: Brightness.light, // 상태바 아이콘을 밝은색으로
      systemNavigationBarColor:
          ColorPalette.backgroundDark, // 네비게이션바 배경색을 어두운색으로
      systemNavigationBarIconBrightness: Brightness.light, // 네비게이션바 아이콘을 밝은색으로
    ),
  );

  // 앱의 진입점
  runApp(
    // Riverpod 적용을 위해 ProviderScope 추가하되,
    // 미리 초기화한 container를 사용하도록 설정
    ProviderScope(
      // 앱 전체에서 Riverpod의 상태 관리 기능을 사용할 수 있게 해줌 (모든 Provider들이 이 범위 안에서 동작)
      parent: container, // 사전에 설정된 ProviderContainer를 상위 컨테이너로 지정
      child: const MyApp(), // 실제 앱의 위젯 트리가 시작되는 루트 위젯
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '와치맨',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const AuthWrapper(),
      routes: {
        LoginScreen.routeName: (context) => const LoginScreen(),
        RegisterScreen.routeName: (context) => const RegisterScreen(),
        EditProfileScreen.routeName: (context) => const EditProfileScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        ProductListScreen.routeName: (context) => const ProductListScreen(),
        CartScreen.routeName: (context) => const CartScreen(),
      },
    );
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('스타일 시스템'),
        actions: [
          IconButton(
            icon: Icon(
              themeState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(themeNotifierProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '와치맨 스타일 시스템',
                style: TextStyles.displaySmall,
              ),
              const SizedBox(height: Dimensions.spacingMd),
              Text(
                '다음은 와치맨 디자인을 기반으로 한 Flutter 스타일 시스템입니다.',
                style: TextStyles.bodyLarge,
              ),
              const SizedBox(height: Dimensions.spacingLg),

              // Typography section
              const _SectionTitle(title: '텍스트 스타일'),
              const SizedBox(height: Dimensions.spacingSm),
              _TextStyleItem(
                name: 'Display Large',
                style: TextStyles.displayLarge,
                text: '와치맨 스타일',
              ),
              _TextStyleItem(
                name: 'Display Medium',
                style: TextStyles.displayMedium,
                text: '와치맨 스타일',
              ),
              _TextStyleItem(
                name: 'Display Small',
                style: TextStyles.displaySmall,
                text: '와치맨 스타일',
              ),
              _TextStyleItem(
                name: 'Headline Large',
                style: TextStyles.headlineLarge,
                text: '와치맨 스타일',
              ),
              _TextStyleItem(
                name: 'Body Large',
                style: TextStyles.bodyLarge,
                text: '와치맨 스타일',
              ),
              _TextStyleItem(
                name: 'Body Medium',
                style: TextStyles.bodyMedium,
                text: '와치맨 스타일',
              ),
              _TextStyleItem(
                name: 'Label Large',
                style: TextStyles.labelLarge,
                text: '와치맨 스타일',
              ),
              _TextStyleItem(
                name: 'Price',
                style: TextStyles.price,
                text: '26,000원',
              ),
              const SizedBox(height: Dimensions.spacingLg),

              // Colors section
              const _SectionTitle(title: '컬러 팔레트'),
              const SizedBox(height: Dimensions.spacingSm),
              _ColorItem(
                name: 'Primary',
                color: ColorPalette.primary,
              ),
              _ColorItem(
                name: 'Secondary',
                color: ColorPalette.secondary,
              ),
              _ColorItem(
                name: 'Background',
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              _ColorItem(
                name: 'Surface',
                color: Theme.of(context).cardColor,
              ),
              _ColorItem(
                name: 'Text Primary',
                color: Theme.of(context).textTheme.bodyLarge!.color!,
              ),
              _ColorItem(
                name: 'Heart Icon',
                color: ColorPalette.heartIcon,
              ),
              const SizedBox(height: Dimensions.spacingLg),

              // Buttons section
              const _SectionTitle(title: '버튼'),
              const SizedBox(height: Dimensions.spacingSm),
              ElevatedButton(
                onPressed: () {},
                child: const Text('판매하기'),
              ),
              const SizedBox(height: Dimensions.spacingSm),
              OutlinedButton(
                onPressed: () {},
                child: const Text('문의하기'),
              ),
              const SizedBox(height: Dimensions.spacingSm),
              TextButton(
                onPressed: () {},
                child: const Text('더 보기'),
              ),
              const SizedBox(height: Dimensions.spacingLg),

              // Cards section
              const _SectionTitle(title: '카드'),
              const SizedBox(height: Dimensions.spacingSm),
              Container(
                decoration: themeState.isDarkMode
                    ? Styles.cardDecorationDark
                    : Styles.cardDecoration,
                padding: const EdgeInsets.all(Dimensions.padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: Dimensions.spacingSm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '와치맨',
                              style: TextStyles.titleMedium,
                            ),
                            Text(
                              '서울시 강남구',
                              style: TextStyles.bodySmall.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall!
                                    .color!
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.spacingSm),
                    Text(
                      '와치맨 스타일 시스템 구현 예시입니다.',
                      style: TextStyles.bodyMedium,
                    ),
                    const SizedBox(height: Dimensions.spacingSm),
                    Text(
                      '26,000원',
                      style: TextStyles.price,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.spacingLg),

              // Tags & Chips
              const _SectionTitle(title: '태그 & 칩'),
              const SizedBox(height: Dimensions.spacingSm),
              Wrap(
                spacing: Dimensions.spacingSm,
                runSpacing: Dimensions.spacingSm,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSm,
                      vertical: Dimensions.paddingXs,
                    ),
                    decoration: Styles.tagDecoration,
                    child: Text(
                      '인기',
                      style: TextStyles.tag.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingLg,
                      vertical: Dimensions.paddingSm,
                    ),
                    decoration: Styles.chipDecoration,
                    child: Text(
                      '동네생활',
                      style: TextStyles.labelMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingLg,
                      vertical: Dimensions.paddingSm,
                    ),
                    decoration: Styles.chipDecoration,
                    child: Text(
                      '추천',
                      style: TextStyles.labelMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyles.headlineSmall,
    );
  }
}

class _TextStyleItem extends StatelessWidget {
  final String name;
  final TextStyle style;
  final String text;

  const _TextStyleItem({
    required this.name,
    required this.style,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: TextStyles.labelMedium.copyWith(
              color: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .color!
                  .withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            text,
            style: style,
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class _ColorItem extends StatelessWidget {
  final String name;
  final Color color;

  const _ColorItem({
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        color.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.spacingSm),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 40,
            color: color,
            alignment: Alignment.center,
            child: Text(
              name,
              style: TextStyles.labelMedium.copyWith(
                color: textColor,
              ),
            ),
          ),
          const SizedBox(width: Dimensions.spacingSm),
          Text(
            color.value.toRadixString(16).toUpperCase().padLeft(8, '0'),
            style: TextStyles.labelMedium,
          ),
        ],
      ),
    );
  }
}
