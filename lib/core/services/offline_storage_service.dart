import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../../features/cart/models/cart_item_model.dart';
import '../../features/order/models/order_model.dart';

/// 오프라인 데이터 저장 서비스
class OfflineStorageService {
  static SharedPreferences? _prefs;

  /// 서비스 초기화
  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('📱 오프라인 저장소 초기화 완료');
  }

  /// SharedPreferences 인스턴스 확인
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception(
          'OfflineStorageService가 초기화되지 않았습니다. initialize()를 먼저 호출하세요.');
    }
    return _prefs!;
  }

  // ==================== 장바구니 데이터 ====================

  /// 장바구니 데이터 로컬 저장
  static Future<bool> saveCartData(List<CartItemModel> items) async {
    try {
      final jsonData = items.map((item) => item.toJson()).toList();
      final success =
          await prefs.setString('offline_cart', jsonEncode(jsonData));
      debugPrint('🛒 장바구니 오프라인 저장: ${items.length}개 아이템');
      return success;
    } catch (e) {
      debugPrint('⚠️ 장바구니 저장 실패: $e');
      return false;
    }
  }

  /// 장바구니 데이터 로컬 로드
  static Future<List<CartItemModel>> loadCartData() async {
    try {
      final jsonString = prefs.getString('offline_cart');
      if (jsonString == null) return [];

      final List<dynamic> jsonData = jsonDecode(jsonString);
      final items =
          jsonData.map((json) => CartItemModel.fromJson(json)).toList();
      debugPrint('🛒 장바구니 오프라인 로드: ${items.length}개 아이템');
      return items;
    } catch (e) {
      debugPrint('⚠️ 장바구니 로드 실패: $e');
      return [];
    }
  }

  /// 장바구니 데이터 삭제
  static Future<bool> clearCartData() async {
    try {
      final success = await prefs.remove('offline_cart');
      debugPrint('🛒 장바구니 오프라인 데이터 삭제');
      return success;
    } catch (e) {
      debugPrint('⚠️ 장바구니 삭제 실패: $e');
      return false;
    }
  }

  /// 주문한 상품들을 오프라인 장바구니에서 제거
  static Future<bool> removeOrderedItemsFromCart(
      List<String> productIds) async {
    try {
      if (productIds.isEmpty) return true;

      final currentItems = await loadCartData();
      final updatedItems = currentItems
          .where((item) => !productIds.contains(item.productId))
          .toList();

      final success = await saveCartData(updatedItems);
      debugPrint('🛒 주문한 상품 ${productIds.length}개를 오프라인 장바구니에서 제거');
      return success;
    } catch (e) {
      debugPrint('⚠️ 주문한 상품 제거 실패: $e');
      return false;
    }
  }

  // ==================== 주문 데이터 ====================

  /// 임시 주문 데이터 저장 (오프라인 시)
  static Future<bool> savePendingOrder(OrderModel order) async {
    try {
      final jsonData = order.toMap();
      final key = 'pending_order_${order.orderId}';
      final success = await prefs.setString(key, jsonEncode(jsonData));

      // 임시 주문 목록에 추가
      await _addToPendingOrdersList(order.orderId);

      debugPrint('📦 임시 주문 저장: ${order.orderId}');
      return success;
    } catch (e) {
      debugPrint('⚠️ 임시 주문 저장 실패: $e');
      return false;
    }
  }

  /// 임시 주문 데이터 로드
  static Future<OrderModel?> loadPendingOrder(String orderId) async {
    try {
      final jsonString = prefs.getString('pending_order_$orderId');
      if (jsonString == null) return null;

      final jsonData = jsonDecode(jsonString);
      final order = OrderModel.fromMap(jsonData);
      debugPrint('📦 임시 주문 로드: $orderId');
      return order;
    } catch (e) {
      debugPrint('⚠️ 임시 주문 로드 실패: $e');
      return null;
    }
  }

  /// 모든 임시 주문 ID 목록 가져오기
  static Future<List<String>> getPendingOrderIds() async {
    try {
      final jsonString = prefs.getString('pending_orders_list');
      if (jsonString == null) return [];

      final List<dynamic> jsonData = jsonDecode(jsonString);
      return jsonData.cast<String>();
    } catch (e) {
      debugPrint('⚠️ 임시 주문 목록 로드 실패: $e');
      return [];
    }
  }

  /// 임시 주문 삭제
  static Future<bool> removePendingOrder(String orderId) async {
    try {
      final success = await prefs.remove('pending_order_$orderId');
      await _removeFromPendingOrdersList(orderId);
      debugPrint('📦 임시 주문 삭제: $orderId');
      return success;
    } catch (e) {
      debugPrint('⚠️ 임시 주문 삭제 실패: $e');
      return false;
    }
  }

  // ==================== 주문 내역 캐시 ====================

  /// 주문 내역 캐시 저장
  static Future<bool> cacheOrderHistory(List<OrderModel> orders) async {
    try {
      final jsonData = orders.map((order) => order.toMap()).toList();
      final cacheData = {
        'orders': jsonData,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      };

      final success =
          await prefs.setString('cached_order_history', jsonEncode(cacheData));
      debugPrint('📋 주문 내역 캐시 저장: ${orders.length}개');
      return success;
    } catch (e) {
      debugPrint('⚠️ 주문 내역 캐시 저장 실패: $e');
      return false;
    }
  }

  /// 주문 내역 캐시 로드
  static Future<List<OrderModel>> loadCachedOrderHistory({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    try {
      final jsonString = prefs.getString('cached_order_history');
      if (jsonString == null) return [];

      final cacheData = jsonDecode(jsonString);
      final cachedAt =
          DateTime.fromMillisecondsSinceEpoch(cacheData['cachedAt']);

      // 캐시 만료 확인
      if (DateTime.now().difference(cachedAt) > maxAge) {
        debugPrint('📋 주문 내역 캐시 만료');
        return [];
      }

      final List<dynamic> ordersJson = cacheData['orders'];
      final orders =
          ordersJson.map((json) => OrderModel.fromMap(json)).toList();
      debugPrint('📋 주문 내역 캐시 로드: ${orders.length}개');
      return orders;
    } catch (e) {
      debugPrint('⚠️ 주문 내역 캐시 로드 실패: $e');
      return [];
    }
  }

  /// 주문 내역 캐시 삭제
  static Future<bool> clearOrderHistoryCache() async {
    try {
      final success = await prefs.remove('cached_order_history');
      debugPrint('📋 주문 내역 캐시 삭제');
      return success;
    } catch (e) {
      debugPrint('⚠️ 주문 내역 캐시 삭제 실패: $e');
      return false;
    }
  }

  // ==================== 사용자 설정 ====================

  /// 오프라인 모드 설정 저장
  static Future<bool> setOfflineModeEnabled(bool enabled) async {
    try {
      final success = await prefs.setBool('offline_mode_enabled', enabled);
      debugPrint('⚙️ 오프라인 모드 설정: ${enabled ? "활성화" : "비활성화"}');
      return success;
    } catch (e) {
      debugPrint('⚠️ 오프라인 모드 설정 실패: $e');
      return false;
    }
  }

  /// 오프라인 모드 설정 로드
  static bool isOfflineModeEnabled() {
    try {
      return prefs.getBool('offline_mode_enabled') ?? false;
    } catch (e) {
      debugPrint('⚠️ 오프라인 모드 설정 로드 실패: $e');
      return false;
    }
  }

  // ==================== 동기화 관련 ====================

  /// 동기화가 필요한 데이터가 있는지 확인
  static Future<bool> hasPendingSync() async {
    final pendingOrders = await getPendingOrderIds();
    return pendingOrders.isNotEmpty;
  }

  /// 마지막 동기화 시간 저장
  static Future<bool> setLastSyncTime(DateTime time) async {
    try {
      final success =
          await prefs.setInt('last_sync_time', time.millisecondsSinceEpoch);
      debugPrint('🔄 마지막 동기화 시간 저장: $time');
      return success;
    } catch (e) {
      debugPrint('⚠️ 동기화 시간 저장 실패: $e');
      return false;
    }
  }

  /// 마지막 동기화 시간 로드
  static DateTime? getLastSyncTime() {
    try {
      final timestamp = prefs.getInt('last_sync_time');
      if (timestamp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      debugPrint('⚠️ 동기화 시간 로드 실패: $e');
      return null;
    }
  }

  // ==================== 내부 헬퍼 메서드 ====================

  /// 임시 주문 목록에 추가
  static Future<void> _addToPendingOrdersList(String orderId) async {
    try {
      final currentList = await getPendingOrderIds();
      if (!currentList.contains(orderId)) {
        currentList.add(orderId);
        await prefs.setString('pending_orders_list', jsonEncode(currentList));
      }
    } catch (e) {
      debugPrint('⚠️ 임시 주문 목록 추가 실패: $e');
    }
  }

  /// 임시 주문 목록에서 제거
  static Future<void> _removeFromPendingOrdersList(String orderId) async {
    try {
      final currentList = await getPendingOrderIds();
      currentList.remove(orderId);
      await prefs.setString('pending_orders_list', jsonEncode(currentList));
    } catch (e) {
      debugPrint('⚠️ 임시 주문 목록 제거 실패: $e');
    }
  }

  /// 모든 오프라인 데이터 삭제
  static Future<bool> clearAllOfflineData() async {
    try {
      final keys = [
        'offline_cart',
        'cached_order_history',
        'pending_orders_list',
        'offline_mode_enabled',
        'last_sync_time',
      ];

      bool allSuccess = true;
      for (final key in keys) {
        final success = await prefs.remove(key);
        if (!success) allSuccess = false;
      }

      // 임시 주문들도 삭제
      final pendingOrders = await getPendingOrderIds();
      for (final orderId in pendingOrders) {
        await prefs.remove('pending_order_$orderId');
      }

      debugPrint('🗑️ 모든 오프라인 데이터 삭제');
      return allSuccess;
    } catch (e) {
      debugPrint('⚠️ 오프라인 데이터 삭제 실패: $e');
      return false;
    }
  }
}
