import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../core/theme/index.dart';

// Import home screen
import '../../home/screens/home_screen.dart'; // This will be created later

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // AuthProvider 생성자에서 authStateChanges 스트림을 구독하므로 
    // 여기서는 별도의 초기화 로직이 필요없음
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final status = authProvider.status;

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? '인증 오류가 발생했습니다'),
              backgroundColor: ColorPalette.error,
            ),
          );
        });
        return const LoginScreen();
      default:
        return const LoginScreen();
    }
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