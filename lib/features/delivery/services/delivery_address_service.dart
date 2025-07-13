import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/delivery_address_model.dart';
import '../repositories/delivery_address_repository.dart';
import '../exceptions/delivery_address_exceptions.dart';
import '../../auth/models/user_model.dart';
import '../../auth/repositories/user_repository.dart';
import '../../../core/config/app_config.dart';

part 'delivery_address_service.g.dart';

/// DeliveryAddressService 인스턴스를 제공하는 Provider입니다.
@riverpod
DeliveryAddressService deliveryAddressService(Ref ref) {
  return DeliveryAddressService(
    ref.watch(deliveryAddressRepositoryProvider),
    ref.watch(userRepositoryProvider),
    ref,
  );
}

/// 배송 주소 관리 비즈니스 로직을 담당하는 Service 클래스입니다.
///
/// 주요 기능:
/// - 사용자의 배송 주소 관리
/// - 배송 주소 개수 제한 관리
/// - 사용자 모델과 배송 주소 연동
class DeliveryAddressService {
  final DeliveryAddressRepository _deliveryAddressRepository;
  final UserRepository _userRepository;
  final Ref _ref;

  // 사용자당 최대 배송 주소 개수
  static const int maxAddressesPerUser = AppConfig.maxAddressesPerUser;

  DeliveryAddressService(
    this._deliveryAddressRepository,
    this._userRepository,
    this._ref,
  );

  // 🔍 조회 및 검증
  // 🏠 사용자 배송 주소 관리

  /// 사용자의 모든 배송 주소 조회
  Future<List<DeliveryAddressModel>> getUserDeliveryAddresses(
      String userId) async {
    try {
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        throw DeliveryAddressException('사용자를 찾을 수 없습니다');
      }

      if (user.deliveryAddressIds.isEmpty) {
        return [];
      }

      return await _deliveryAddressRepository
          .getDeliveryAddressesByIds(user.deliveryAddressIds);
    } catch (e) {
      throw DeliveryAddressException('배송 주소 목록을 불러오는데 실패했습니다: $e');
    }
  }

  /// 사용자에게 새 배송 주소 추가
  Future<DeliveryAddressModel> addDeliveryAddressToUser(
    String userId,
    DeliveryAddressModel address,
  ) async {
    try {
      // 사용자 조회
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        throw DeliveryAddressException('사용자를 찾을 수 없습니다');
      }

      // 배송 주소 개수 제한 확인
      if (user.deliveryAddressIds.length >= maxAddressesPerUser) {
        throw DeliveryAddressLimitExceededException(
          '최대 $maxAddressesPerUser개까지 배송 주소를 등록할 수 있습니다',
        );
      }

      // 배송 주소 생성
      final addressId =
          await _deliveryAddressRepository.createDeliveryAddress(address);

      // 생성된 배송 주소 조회
      final createdAddress =
          await _deliveryAddressRepository.getDeliveryAddressById(addressId);
      if (createdAddress == null) {
        throw DeliveryAddressException('배송 주소 생성 확인에 실패했습니다');
      }

      // 사용자 모델에 배송 주소 ID 추가
      final updatedAddressIds = [...user.deliveryAddressIds, addressId];
      final updatedUser = user.copyWith(
        deliveryAddressIds: updatedAddressIds,
      );

      await _userRepository.updateUser(updatedUser);

      return createdAddress;
    } catch (e) {
      if (e is DeliveryAddressException) {
        rethrow;
      }
      throw DeliveryAddressException('배송 주소 추가에 실패했습니다: $e');
    }
  }

  /// 사용자의 배송 주소 수정
  Future<void> updateUserDeliveryAddress(
    String userId,
    DeliveryAddressModel address,
  ) async {
    try {
      // 사용자 조회
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        throw DeliveryAddressException('사용자를 찾을 수 없습니다');
      }

      // 해당 배송 주소가 사용자의 것인지 확인
      if (!user.deliveryAddressIds.contains(address.id)) {
        throw DeliveryAddressException('권한이 없는 배송 주소입니다');
      }

      // 배송 주소 업데이트
      await _deliveryAddressRepository.updateDeliveryAddress(address);
    } catch (e) {
      if (e is DeliveryAddressException) {
        rethrow;
      }
      throw DeliveryAddressException('배송 주소 수정에 실패했습니다: $e');
    }
  }

  /// 사용자의 배송 주소 삭제
  Future<void> deleteUserDeliveryAddress(
    String userId,
    String addressId,
  ) async {
    try {
      // 사용자 조회
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        throw DeliveryAddressException('사용자를 찾을 수 없습니다');
      }

      // 해당 배송 주소가 사용자의 것인지 확인
      if (!user.deliveryAddressIds.contains(addressId)) {
        throw DeliveryAddressException('권한이 없는 배송 주소입니다');
      }

      // 배송 주소 삭제
      await _deliveryAddressRepository.deleteDeliveryAddress(addressId);

      // 사용자 모델에서 배송 주소 ID 제거
      final updatedAddressIds =
          user.deliveryAddressIds.where((id) => id != addressId).toList();
      final updatedUser = user.copyWith(
        deliveryAddressIds: updatedAddressIds,
      );

      await _userRepository.updateUser(updatedUser);
    } catch (e) {
      if (e is DeliveryAddressException) {
        rethrow;
      }
      throw DeliveryAddressException('배송 주소 삭제에 실패했습니다: $e');
    }
  }

  /// 사용자의 모든 배송 주소 삭제
  Future<void> deleteAllUserDeliveryAddresses(String userId) async {
    try {
      // 사용자 조회
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        throw DeliveryAddressException('사용자를 찾을 수 없습니다');
      }

      if (user.deliveryAddressIds.isEmpty) {
        return;
      }

      // 모든 배송 주소 삭제
      await _deliveryAddressRepository
          .deleteDeliveryAddresses(user.deliveryAddressIds);

      // 사용자 모델에서 모든 배송 주소 ID 제거
      final updatedUser = user.copyWith(
        deliveryAddressIds: [],
      );

      await _userRepository.updateUser(updatedUser);
    } catch (e) {
      if (e is DeliveryAddressException) {
        rethrow;
      }
      throw DeliveryAddressException('배송 주소 전체 삭제에 실패했습니다: $e');
    }
  }

  // 🔍 조회 및 검증

  /// 특정 배송 주소가 사용자의 것인지 확인
  Future<bool> isUserDeliveryAddress(String userId, String addressId) async {
    try {
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        return false;
      }

      return user.deliveryAddressIds.contains(addressId);
    } catch (e) {
      return false;
    }
  }

  /// 사용자가 추가할 수 있는 배송 주소 개수 확인
  Future<int> getAvailableAddressCount(String userId) async {
    try {
      final user = await _userRepository.getUserById(userId);
      if (user == null) {
        throw DeliveryAddressException('사용자를 찾을 수 없습니다');
      }

      return maxAddressesPerUser - user.deliveryAddressIds.length;
    } catch (e) {
      throw DeliveryAddressException('배송 주소 개수 확인에 실패했습니다: $e');
    }
  }

  /// 배송 주소 유효성 검증
  bool validateDeliveryAddress(DeliveryAddressModel address) {
    if (address.recipientName.trim().isEmpty) {
      throw DeliveryAddressValidationException('받는 분 이름을 입력해주세요');
    }

    if (address.recipientContact.trim().isEmpty) {
      throw DeliveryAddressValidationException('연락처를 입력해주세요');
    }

    if (address.postalCode.trim().isEmpty) {
      throw DeliveryAddressValidationException('우편번호를 입력해주세요');
    }

    if (address.recipientAddress.trim().isEmpty) {
      throw DeliveryAddressValidationException('주소를 입력해주세요');
    }

    if (address.recipientAddressDetail.trim().isEmpty) {
      throw DeliveryAddressValidationException('상세 주소를 입력해주세요');
    }

    // 전화번호 형식 검증 (한국 전화번호)
    final phoneRegex = RegExp(r'^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$');
    final cleanedPhone = address.recipientContact.replaceAll('-', '');
    if (!phoneRegex.hasMatch(cleanedPhone)) {
      throw DeliveryAddressValidationException('올바른 전화번호 형식이 아닙니다');
    }

    // 우편번호 형식 검증 (5자리 숫자)
    final postalCodeRegex = RegExp(r'^\d{5}$');
    if (!postalCodeRegex.hasMatch(address.postalCode)) {
      throw DeliveryAddressValidationException('우편번호는 5자리 숫자여야 합니다');
    }

    return true;
  }
}
