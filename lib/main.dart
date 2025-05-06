import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/index.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/auth/screens/auth_wrapper.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/password_reset_screen.dart';
import 'features/auth/screens/edit_profile_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/products/providers/product_provider.dart';
import 'features/products/repositories/product_repository.dart';
import 'features/products/screens/product_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable Firebase debug logging
  if (!kIsWeb) {
    // Set to true to enable Firebase debug logs
    bool debugMode = true;
    if (debugMode) {
      print("Firebase debug logging enabled");
    }
  }
  
  // Firebase Web 플랫폼 오류 방지를 위한 코드
  if (!kIsWeb) {
    // Initialize Firebase only for non-web platforms
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Initialize Firebase App Check
      await FirebaseAppCheck.instance.activate(
        // 디버그 모드에서는 디버그 제공자 사용
        androidProvider: kDebugMode 
            ? AndroidProvider.debug 
            : AndroidProvider.playIntegrity,
        // iOS에서는 DeviceCheck 사용
        appleProvider: AppleProvider.deviceCheck,
      );
      
      // Android에서만 보안 프로바이더 설정
      if (Platform.isAndroid) {
        try {
          // Google Play Services Security Provider가 설치되어 있는지 확인하고 설치
          // 이 작업은 Firebase 작업 전에 수행하는 것이 좋지만, Firebase 초기화 후에도 가능합니다.
          // 필요한 패키지: import 'package:flutter/services.dart';
          const platform = MethodChannel('com.example.gonggoo_app/provider_installer');
          await platform.invokeMethod('installSecurityProvider');
        } catch (e) {
          // 실패해도 앱은 계속 실행될 수 있음
          print("Failed to install security provider: $e");
        }
      }
      
      print("Firebase initialized successfully");
    } catch (e) {
      print("Firebase initialization error: $e");
    }
  } else {
    // Skip Firebase initialization on web
    print('Web platform detected - skipping Firebase initialization');
  }
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: ColorPalette.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth repository
        Provider<AuthRepository>(
          create: (_) => AuthRepository(),
        ),
        
        // Auth provider
        ChangeNotifierProxyProvider<AuthRepository, AuthProvider>(
          create: (context) => AuthProvider(
            authRepository: context.read<AuthRepository>(),
          ),
          update: (context, repository, previous) => previous ?? AuthProvider(
            authRepository: repository,
          ),
        ),
        
        // Product repository
        Provider<ProductRepository>(
          create: (_) => ProductRepository(),
        ),
        
        // Product provider
        ChangeNotifierProxyProvider<ProductRepository, ProductProvider>(
          create: (context) => ProductProvider(
            productRepository: context.read<ProductRepository>(),
          ),
          update: (context, repository, previous) => previous ?? ProductProvider(
            productRepository: repository,
          ),
        ),
      ],
      child: MaterialApp(
        title: '와치맨',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        routes: {
          LoginScreen.routeName: (context) => const LoginScreen(),
          RegisterScreen.routeName: (context) => const RegisterScreen(),
          PasswordResetScreen.routeName: (context) => const PasswordResetScreen(),
          EditProfileScreen.routeName: (context) => const EditProfileScreen(),
          HomeScreen.routeName: (context) => const HomeScreen(),
          ProductListScreen.routeName: (context) => const ProductListScreen(),
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스타일 시스템'),
        actions: [
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
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
                decoration: Provider.of<ThemeProvider>(context).isDarkMode
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
                                color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.7),
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
              color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.7),
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
    final textColor = color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    
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
            '${color.value.toRadixString(16).toUpperCase().padLeft(8, '0')}',
            style: TextStyles.labelMedium,
          ),
        ],
      ),
    );
  }
} 