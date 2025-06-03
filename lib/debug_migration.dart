// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'features/products/services/location_tag_migration_service.dart';
// import 'firebase_options.dart';

// /// 데이터 마이그레이션 실행용 디버그 스크립트
// ///
// /// 사용법:
// /// ```bash
// /// flutter run lib/debug_migration.dart
// /// ```
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   try {
//     // Firebase 초기화
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );

//     print('🔥 Firebase 초기화 완료');

//     // ProviderContainer 생성
//     final container = ProviderContainer();

//     // LocationTagMigrationService 인스턴스 생성
//     final migrationService =
//         container.read(locationTagMigrationServiceProvider);

//     print('🔄 마이그레이션 시작...');

//     // 전체 마이그레이션 실행
//     final result = await migrationService.executeFullMigration();

//     print('🎉 마이그레이션 완료!');
//     print('📊 결과:');
//     print('  - LocationTag 생성: ${result['locationTagsCreated']}개');
//     print('  - Product 업데이트: ${result['productsUpdated']}개');
//     print('  - User 업데이트: ${result['usersUpdated']}개');

//     if ((result['errors'] as List).isNotEmpty) {
//       print('⚠️ 오류 목록:');
//       for (final error in result['errors'] as List) {
//         print('  - $error');
//       }
//     }

//     // 정리
//     container.dispose();
//   } catch (e) {
//     print('❌ 마이그레이션 실행 중 오류 발생: $e');
//   }
// }
