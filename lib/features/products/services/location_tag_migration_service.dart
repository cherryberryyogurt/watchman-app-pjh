import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/location_tag_repository.dart';
import '../../auth/repositories/user_repository.dart';
import '../models/location_tag_model.dart';
import '../models/pickup_info_model.dart';

part 'location_tag_migration_service.g.dart';

/// LocationTagMigrationService 인스턴스를 제공하는 Provider입니다.
@riverpod
LocationTagMigrationService locationTagMigrationService(Ref ref) {
  return LocationTagMigrationService(
    FirebaseFirestore.instance,
    ref,
  );
}

/// LocationTag 시스템 마이그레이션을 담당하는 서비스 클래스입니다.
///
/// 주요 기능:
/// - 기존 locationTag 문자열 데이터를 새로운 LocationTag 구조로 마이그레이션
/// - 초기 LocationTag 데이터 생성
/// - 마이그레이션 상태 확인 및 복구
class LocationTagMigrationService {
  final FirebaseFirestore _firestore;
  final Ref _ref;

  LocationTagMigrationService(this._firestore, this._ref);

  /// 🔄 전체 마이그레이션 실행
  Future<Map<String, dynamic>> executeFullMigration() async {
    try {
      print('🔄 LocationTagMigrationService: executeFullMigration() - 시작');

      final migrationResult = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'locationTagsCreated': 0,
        'productsUpdated': 0,
        'usersUpdated': 0,
        'errors': <String>[],
      };

      // 1. 기본 LocationTag 데이터 생성
      final locationTagResult = await _createInitialLocationTags();
      migrationResult['locationTagsCreated'] = locationTagResult['created'];
      (migrationResult['errors'] as List<String>)
          .addAll(locationTagResult['errors'] as List<String>);

      // 2. Product 컬렉션 마이그레이션
      final productResult = await _migrateProducts();
      migrationResult['productsUpdated'] = productResult['updated'];
      (migrationResult['errors'] as List<String>)
          .addAll(productResult['errors'] as List<String>);

      // 3. User 컬렉션 마이그레이션
      final userResult = await _migrateUsers();
      migrationResult['usersUpdated'] = userResult['updated'];
      (migrationResult['errors'] as List<String>)
          .addAll(userResult['errors'] as List<String>);

      print('🔄 LocationTagMigrationService: 마이그레이션 완료');
      print('🔄 생성된 LocationTag: ${migrationResult['locationTagsCreated']}개');
      print('🔄 업데이트된 Product: ${migrationResult['productsUpdated']}개');
      print('🔄 업데이트된 User: ${migrationResult['usersUpdated']}개');

      return migrationResult;
    } catch (e) {
      print('🔄 LocationTagMigrationService: executeFullMigration() - 오류: $e');
      throw Exception('마이그레이션 실행에 실패했습니다: $e');
    }
  }

  /// 🏠 초기 LocationTag 데이터 생성
  Future<Map<String, dynamic>> _createInitialLocationTags() async {
    try {
      print(
          '🏠 LocationTagMigrationService: _createInitialLocationTags() - 시작');

      final result = <String, dynamic>{'created': 0, 'errors': <String>[]};

      // 기본 LocationTag 데이터 정의
      final initialLocationTags = [
        {
          'id': 'gangnam_dong',
          'name': '강남동',
          'description': '강남구 강남동 지역',
          'region': {
            'sido': '서울특별시',
            'sigungu': '강남구',
            'dong': '강남동',
          },
          'pickupInfos': [
            {
              'id': 'gangnam_pickup_001',
              'spotName': '강남역 3번 출구',
              'address': '서울특별시 강남구 강남대로 396',
              'pickupTimes': [
                DateTime.now()
                    .add(Duration(days: 1))
                    .copyWith(hour: 18, minute: 0), // 내일 6시
                DateTime.now()
                    .add(Duration(days: 1))
                    .copyWith(hour: 19, minute: 0), // 내일 7시
              ],
              'isActive': true,
              'createdAt': DateTime.now(),
              'updatedAt': DateTime.now(),
            }
          ],
          'isActive': true,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        },
        {
          'id': 'seocho_dong',
          'name': '서초동',
          'description': '서초구 서초동 지역',
          'region': {
            'sido': '서울특별시',
            'sigungu': '서초구',
            'dong': '서초동',
          },
          'pickupInfos': [
            {
              'id': 'seocho_pickup_001',
              'spotName': '서초역 2번 출구',
              'address': '서울특별시 서초구 서초대로 294',
              'pickupTimes': [
                DateTime.now()
                    .add(Duration(days: 1))
                    .copyWith(hour: 17, minute: 0), // 내일 5시
                DateTime.now()
                    .add(Duration(days: 1))
                    .copyWith(hour: 18, minute: 30), // 내일 6시 30분
              ],
              'isActive': true,
              'createdAt': DateTime.now(),
              'updatedAt': DateTime.now(),
            }
          ],
          'isActive': true,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        },
        {
          'id': 'songpa_dong',
          'name': '송파동',
          'description': '송파구 송파동 지역',
          'region': {
            'sido': '서울특별시',
            'sigungu': '송파구',
            'dong': '송파동',
          },
          'pickupInfos': [
            {
              'id': 'songpa_pickup_001',
              'spotName': '송파역 1번 출구',
              'address': '서울특별시 송파구 송파대로 28길',
              'pickupTimes': [
                DateTime.now()
                    .add(Duration(days: 1))
                    .copyWith(hour: 10, minute: 0), // 내일 10시
                DateTime.now()
                    .add(Duration(days: 1))
                    .copyWith(hour: 14, minute: 0), // 내일 2시
              ],
              'isActive': true,
              'createdAt': DateTime.now(),
              'updatedAt': DateTime.now(),
            }
          ],
          'isActive': true,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        },
        {
          'id': 'yeongdeungpo_dong',
          'name': '영등포동',
          'description': '영등포구 영등포동 지역',
          'region': {
            'sido': '서울특별시',
            'sigungu': '영등포구',
            'dong': '영등포동',
          },
          'pickupInfos': <Map<String, dynamic>>[],
          'isActive': true,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        },
        {
          'id': 'gangseo_dong',
          'name': '강서동',
          'description': '강서구 강서동 지역',
          'region': {
            'sido': '서울특별시',
            'sigungu': '강서구',
            'dong': '강서동',
          },
          'pickupInfos': <Map<String, dynamic>>[],
          'isActive': true,
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        },
      ];

      // LocationTag 생성
      for (final locationTagData in initialLocationTags) {
        try {
          final locationTagId = locationTagData['id'] as String;

          // 이미 존재하는지 확인
          final existingDoc = await _firestore
              .collection('locationTags')
              .doc(locationTagId)
              .get();

          if (existingDoc.exists) {
            print('🏠 LocationTag "$locationTagId"가 이미 존재함 - 건너뛰기');
            continue;
          }

          // Firestore에 저장할 데이터 변환
          final firestoreData = _convertToFirestoreFormat(locationTagData);

          await _firestore
              .collection('locationTags')
              .doc(locationTagId)
              .set(firestoreData);

          result['created'] = (result['created'] as int) + 1;
          print('🏠 LocationTag "$locationTagId" 생성 완료');
        } catch (e) {
          final error = 'LocationTag ${locationTagData['id']} 생성 실패: $e';
          print('🏠 $error');
          (result['errors'] as List<String>).add(error);
        }
      }

      print(
          '🏠 LocationTagMigrationService: ${result['created']}개 LocationTag 생성 완료');
      return result;
    } catch (e) {
      print(
          '🏠 LocationTagMigrationService: _createInitialLocationTags() - 오류: $e');
      throw Exception('초기 LocationTag 생성에 실패했습니다: $e');
    }
  }

  /// 🛍️ Product 컬렉션 마이그레이션
  Future<Map<String, dynamic>> _migrateProducts() async {
    try {
      print('🛍️ LocationTagMigrationService: _migrateProducts() - 시작');

      final result = <String, dynamic>{'updated': 0, 'errors': <String>[]};

      // 기존 locationTag 필드가 있는 상품들 조회
      final QuerySnapshot snapshot = await _firestore
          .collection('products')
          .where('locationTag', isNotEqualTo: null)
          .get();

      print('🛍️ 마이그레이션 대상 상품 ${snapshot.docs.length}개 발견');

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final oldLocationTag = data['locationTag'] as String?;

          // 이미 마이그레이션된 상품은 건너뛰기
          if (data.containsKey('locationTagId') &&
              data['locationTagId'] != null) {
            continue;
          }

          if (oldLocationTag != null) {
            final locationTagId = _convertLocationTagToId(oldLocationTag);

            // 업데이트 데이터 준비
            final updateData = {
              'locationTagId': locationTagId,
              'locationTagName': oldLocationTag,
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            };

            await doc.reference.update(updateData);
            result['updated'] = (result['updated'] as int) + 1;

            print(
                '🛍️ Product ${doc.id} 마이그레이션 완료: $oldLocationTag -> $locationTagId');
          }
        } catch (e) {
          final error = 'Product ${doc.id} 마이그레이션 실패: $e';
          print('🛍️ $error');
          (result['errors'] as List<String>).add(error);
        }
      }

      print(
          '🛍️ LocationTagMigrationService: ${result['updated']}개 Product 마이그레이션 완료');
      return result;
    } catch (e) {
      print('🛍️ LocationTagMigrationService: _migrateProducts() - 오류: $e');
      throw Exception('Product 마이그레이션에 실패했습니다: $e');
    }
  }

  /// 👤 User 컬렉션 마이그레이션
  Future<Map<String, dynamic>> _migrateUsers() async {
    try {
      print('👤 LocationTagMigrationService: _migrateUsers() - 시작');

      final result = <String, dynamic>{'updated': 0, 'errors': <String>[]};

      // 기존 locationTag 필드가 있는 사용자들 조회
      final QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('locationTag', isNotEqualTo: null)
          .get();

      print('👤 마이그레이션 대상 사용자 ${snapshot.docs.length}명 발견');

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final oldLocationTag = data['locationTag'] as String?;

          // 이미 마이그레이션된 사용자는 건너뛰기
          if (data.containsKey('locationTagId') &&
              data['locationTagId'] != null) {
            continue;
          }

          if (oldLocationTag != null) {
            final locationTagId = _convertLocationTagToId(oldLocationTag);

            // 업데이트 데이터 준비
            final updateData = {
              'locationTagId': locationTagId,
              'locationTagName': oldLocationTag,
              'locationStatus': 'active',
              'pendingLocationName': null,
              'updatedAt': Timestamp.fromDate(DateTime.now()),
            };

            await doc.reference.update(updateData);
            result['updated'] = (result['updated'] as int) + 1;

            print(
                '👤 User ${doc.id} 마이그레이션 완료: $oldLocationTag -> $locationTagId');
          }
        } catch (e) {
          final error = 'User ${doc.id} 마이그레이션 실패: $e';
          print('👤 $error');
          (result['errors'] as List<String>).add(error);
        }
      }

      print(
          '👤 LocationTagMigrationService: ${result['updated']}명 User 마이그레이션 완료');
      return result;
    } catch (e) {
      print('👤 LocationTagMigrationService: _migrateUsers() - 오류: $e');
      throw Exception('User 마이그레이션에 실패했습니다: $e');
    }
  }

  /// 🔍 마이그레이션 상태 확인
  Future<Map<String, dynamic>> checkMigrationStatus() async {
    try {
      print('🔍 LocationTagMigrationService: checkMigrationStatus() - 시작');

      final status = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'locationTags': <String, dynamic>{
          'total': 0,
          'active': 0,
        },
        'products': <String, dynamic>{
          'total': 0,
          'migrated': 0,
          'needsMigration': 0,
        },
        'users': <String, dynamic>{
          'total': 0,
          'migrated': 0,
          'needsMigration': 0,
        },
      };

      // LocationTag 상태 확인
      final locationTagSnapshot =
          await _firestore.collection('locationTags').get();
      (status['locationTags'] as Map<String, dynamic>)['total'] =
          locationTagSnapshot.docs.length;
      (status['locationTags'] as Map<String, dynamic>)['active'] =
          locationTagSnapshot.docs
              .where((doc) => (doc.data()['isActive'] as bool? ?? false))
              .length;

      // Product 상태 확인
      final productSnapshot = await _firestore.collection('products').get();
      (status['products'] as Map<String, dynamic>)['total'] =
          productSnapshot.docs.length;

      int productsMigrated = 0;
      int productsNeedsMigration = 0;

      for (final doc in productSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('locationTagId') &&
            data['locationTagId'] != null) {
          productsMigrated++;
        } else if (data.containsKey('locationTag') &&
            data['locationTag'] != null) {
          productsNeedsMigration++;
        }
      }

      (status['products'] as Map<String, dynamic>)['migrated'] =
          productsMigrated;
      (status['products'] as Map<String, dynamic>)['needsMigration'] =
          productsNeedsMigration;

      // User 상태 확인
      final userSnapshot = await _firestore.collection('users').get();
      (status['users'] as Map<String, dynamic>)['total'] =
          userSnapshot.docs.length;

      int usersMigrated = 0;
      int usersNeedsMigration = 0;

      for (final doc in userSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('locationTagId')) {
          usersMigrated++;
        } else if (data.containsKey('locationTag') &&
            data['locationTag'] != null) {
          usersNeedsMigration++;
        }
      }

      (status['users'] as Map<String, dynamic>)['migrated'] = usersMigrated;
      (status['users'] as Map<String, dynamic>)['needsMigration'] =
          usersNeedsMigration;

      print('🔍 마이그레이션 상태 확인 완료');
      return status;
    } catch (e) {
      print('🔍 LocationTagMigrationService: checkMigrationStatus() - 오류: $e');
      throw Exception('마이그레이션 상태 확인에 실패했습니다: $e');
    }
  }

  // 🔧 헬퍼 메서드들

  /// 기존 locationTag 문자열을 locationTagId로 변환
  String _convertLocationTagToId(String locationTag) {
    const locationTagMapping = {
      '강남동': 'gangnam_dong',
      '서초동': 'seocho_dong',
      '송파동': 'songpa_dong',
      '영등포동': 'yeongdeungpo_dong',
      '강서동': 'gangseo_dong',
    };

    return locationTagMapping[locationTag] ??
        locationTag.toLowerCase().replaceAll('동', '_dong');
  }

  /// LocationTag 데이터를 Firestore 형식으로 변환
  Map<String, dynamic> _convertToFirestoreFormat(Map<String, dynamic> data) {
    final pickupInfos = data['pickupInfos'] as List<dynamic>;

    return {
      'name': data['name'],
      'description': data['description'],
      'region': data['region'],
      'pickupInfos': pickupInfos
          .map((pickup) => {
                'id': pickup['id'],
                'spotName': pickup['spotName'],
                'address': pickup['address'],
                'pickupTimes': (pickup['pickupTimes'] as List<DateTime>)
                    .map((dateTime) => Timestamp.fromDate(dateTime))
                    .toList(),
                'isActive': pickup['isActive'],
                'createdAt':
                    Timestamp.fromDate(pickup['createdAt'] as DateTime),
                'updatedAt':
                    Timestamp.fromDate(pickup['updatedAt'] as DateTime),
              })
          .toList(),
      'isActive': data['isActive'],
      'createdAt': Timestamp.fromDate(data['createdAt'] as DateTime),
      'updatedAt': Timestamp.fromDate(data['updatedAt'] as DateTime),
    };
  }
}
