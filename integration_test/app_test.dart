import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'auth_integration_test.dart' as auth_tests;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  auth_tests.main();
} 