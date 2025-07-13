import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/delivery_address_model.dart';
import '../exceptions/delivery_address_exceptions.dart';

part 'delivery_address_repository.g.dart';

/// DeliveryAddressRepository 인스턴스를 제공하는 Provider입니다.
@riverpod
DeliveryAddressRepository deliveryAddressRepository(Ref ref) {
  return DeliveryAddressRepository(
    FirebaseFirestore.instance,
    ref,
  );
}

/// 배송 주소 관리를 담당하는 Repository 클래스입니다.
///
/// 주요 기능:
/// - 배송 주소 CRUD 작업
/// - 사용자별 배송 주소 목록 관리
/// - 기본 배송 주소 설정
class DeliveryAddressRepository {
  final FirebaseFirestore _firestore;
  final Ref _ref;

  DeliveryAddressRepository(this._firestore, this._ref);

  /// DeliveryAddress 컬렉션 참조
  CollectionReference get _deliveryAddressCollection =>
      _firestore.collection('deliveryAddress');

  // 📦 배송 주소 기본 CRUD

  /// 배송 주소 ID로 배송 주소 정보 조회
  Future<DeliveryAddressModel?> getDeliveryAddressById(String id) async {
    try {
      final doc = await _deliveryAddressCollection.doc(id).get();

      if (!doc.exists) {
        return null;
      }

      return DeliveryAddressModel.fromDocument(doc);
    } catch (e) {
      throw DeliveryAddressNotFoundException('배송 주소 정보를 불러오는데 실패했습니다: $e');
    }
  }

  /// 배송 주소 정보 생성
  Future<String> createDeliveryAddress(DeliveryAddressModel address) async {
    try {
      final docRef = _deliveryAddressCollection.doc();
      final newAddress = address.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await docRef.set(newAddress.toMap());
      return docRef.id;
    } catch (e) {
      throw DeliveryAddressException('배송 주소 생성에 실패했습니다: $e');
    }
  }

  /// 배송 주소 정보 업데이트
  Future<void> updateDeliveryAddress(DeliveryAddressModel address) async {
    try {
      final updatedAddress = address.copyWith(updatedAt: DateTime.now());
      await _deliveryAddressCollection
          .doc(address.id)
          .update(updatedAddress.toMap());
    } catch (e) {
      throw DeliveryAddressException('배송 주소 업데이트에 실패했습니다: $e');
    }
  }

  /// 배송 주소 삭제
  Future<void> deleteDeliveryAddress(String id) async {
    try {
      await _deliveryAddressCollection.doc(id).delete();
    } catch (e) {
      throw DeliveryAddressException('배송 주소 삭제에 실패했습니다: $e');
    }
  }

  // 📋 사용자별 배송 주소 관리

  /// 특정 ID 목록으로 배송 주소들 조회
  Future<List<DeliveryAddressModel>> getDeliveryAddressesByIds(
      List<String> ids) async {
    if (ids.isEmpty) {
      return [];
    }

    try {
      // Firestore에서는 한 번에 10개까지만 whereIn 쿼리 가능
      final List<DeliveryAddressModel> allAddresses = [];
      
      // 10개씩 나누어 쿼리
      for (int i = 0; i < ids.length; i += 10) {
        final batch = ids.skip(i).take(10).toList();
        final snapshot = await _deliveryAddressCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        final addresses = snapshot.docs
            .map((doc) => DeliveryAddressModel.fromDocument(doc))
            .toList();
        
        allAddresses.addAll(addresses);
      }

      // ID 순서대로 정렬
      final addressMap = {
        for (var address in allAddresses) address.id: address
      };
      
      return ids
          .where((id) => addressMap.containsKey(id))
          .map((id) => addressMap[id]!)
          .toList();
    } catch (e) {
      throw DeliveryAddressException('배송 주소 목록을 불러오는데 실패했습니다: $e');
    }
  }

  /// 배송 주소들 일괄 삭제
  Future<void> deleteDeliveryAddresses(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }

    try {
      // Batch 작업으로 여러 문서 동시 삭제
      final batch = _firestore.batch();
      
      for (final id in ids) {
        final docRef = _deliveryAddressCollection.doc(id);
        batch.delete(docRef);
      }
      
      await batch.commit();
    } catch (e) {
      throw DeliveryAddressException('배송 주소 일괄 삭제에 실패했습니다: $e');
    }
  }

  /// 배송 주소 ID가 존재하는지 확인
  Future<bool> existsDeliveryAddress(String id) async {
    try {
      final doc = await _deliveryAddressCollection.doc(id).get();
      return doc.exists;
    } catch (e) {
      throw DeliveryAddressException('배송 주소 존재 여부 확인에 실패했습니다: $e');
    }
  }
}