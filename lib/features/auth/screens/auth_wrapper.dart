import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_state.dart';
import 'login_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/theme/index.dart';

// Import home screen
import '../../home/screens/home_screen.dart'; // This will be created later

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Riverpod의 authProvider는 자동으로 초기화됨
    
    // 앱 시작 시 인증 상태 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).loadCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Riverpod authProvider 사용
    final authState = ref.watch(authProvider);
    
    // Handle different AsyncValue states
    return authState.when(
      data: (state) {
        // Now we can access properties on the inner state object
        final status = state.status;
        final errorMessage = state.errorMessage;

    switch (status) {
      case AuthStatus.authenticated:
        // User is authenticated, show home screen
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        // User is not authenticated, show login screen
        return const LoginScreen();
      case AuthStatus.initial:
      case AuthStatus.authenticating:
        // Loading state
        return _buildLoadingScreen();
      case AuthStatus.error:
        // Error state, show login screen with error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // 오류 메시지가 있으면 표시
          if (errorMessage != null && errorMessage.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: ColorPalette.error,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: '확인',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('인증 중 오류가 발생했습니다. 다시 시도해주세요.'),
                backgroundColor: ColorPalette.error,
              ),
            );
          }
        });
        return const LoginScreen();
      default:
        return const LoginScreen();
    }
      },
      loading: () {
        // Show loading screen while Auth is initializing or loading
        return _buildLoadingScreen();
      },
      error: (error, stackTrace) {
        // Show error and login screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: ColorPalette.error,
              duration: const Duration(seconds: 5),
            ),
          );
        });
        return const LoginScreen();
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '와치맨',
              style: TextStyles.displaySmall.copyWith(
                color: ColorPalette.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: Dimensions.spacingLg),
            const SpinKitDoubleBounce(
              color: ColorPalette.primary,
              size: 50.0,
            ),
          ],
        ),
      ),
    );
  }
} 