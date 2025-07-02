# Payment Failure Order Deletion Implementation

## Overview

This document describes the implementation of automatic pending order deletion when payment fails. This feature ensures that failed payments trigger cleanup of pending orders, including stock restoration and data cleanup.

**🔄 Architecture Update**: This feature is now implemented as a **Firebase Function** for enhanced security, reliability, and consistency with the existing payment architecture.

## Business Logic

When a payment fails, the following should happen:
1. **Order Validation**: Verify the order exists and is in 'pending' status
2. **Stock Restoration**: Restore inventory for all ordered products
3. **Data Cleanup**: Remove order document and sub-collections
4. **User Cleanup**: Remove order ID from user's order list
5. **Audit Logging**: Record deletion for audit trail
6. **Error Handling**: Graceful handling of cleanup failures

## Implementation Details

### 1. Firebase Functions (`functions/index.js`)

#### New Function: `deletePendingOrderOnPaymentFailure`

```javascript
exports.deletePendingOrderOnPaymentFailure = functions.https.onCall(async (data, context) => {
  // 🔐 Server-side implementation with:
  // - User authentication validation
  // - Order ownership verification
  // - Atomic transaction processing
  // - Comprehensive audit logging
  // - Stock restoration
  // - Data cleanup
});
```

**Key Features:**
- ✅ **Security**: Server-side validation prevents client manipulation
- ✅ **Atomicity**: Uses Firestore transactions for data consistency
- ✅ **Audit Trail**: Creates deletion logs in `order_deletion_logs` collection
- ✅ **Stock Recovery**: Automatically restores product inventory
- ✅ **Error Handling**: Comprehensive error handling with detailed logging

### 2. Payments Service (`TossPaymentsService`)

#### New Method: `deletePendingOrderOnPaymentFailure`

```dart
Future<Map<String, dynamic>> deletePendingOrderOnPaymentFailure({
  required String orderId,
  String? reason,
}) async {
  // Calls Firebase Function with retry logic
  // Handles authentication and error conversion
}
```

**Key Features:**
- ✅ **Retry Logic**: Automatic retry on network failures
- ✅ **Error Handling**: Converts Firebase exceptions to PaymentError
- ✅ **Authentication**: Ensures user is authenticated before calling
- ✅ **Logging**: Comprehensive logging for debugging

### 3. Order Service (`OrderService`)

#### Updated Method: `deletePendingOrderOnPaymentFailure`

```dart
Future<void> deletePendingOrderOnPaymentFailure(String orderId, {String? reason}) async {
  // Now delegates to TossPaymentsService instead of OrderRepository
  // Provides business logic wrapper with error handling
}
```

**Key Changes:**
- ❌ **Removed**: Direct repository access for security
- ✅ **Added**: Firebase Functions integration
- ✅ **Enhanced**: Better error handling and logging

### 4. Payment Screen Integration

#### Updated Method: `_handlePaymentFailureWithOrderCleanup`

```dart
Future<void> _handlePaymentFailureWithOrderCleanup(PaymentError error) async {
  try {
    await orderService.deletePendingOrderOnPaymentFailure(
      widget.order.orderId,
      reason: '결제 실패: ${error.code} - ${error.message}',
    );
  } catch (cleanupError) {
    // Graceful degradation - show payment error regardless
  }
  _showPaymentError(error);
}
```

**Integration Points:**
- ✅ **Web Payment Failures**: Handles URL-based failure detection
- ✅ **Mobile Payment Failures**: Handles WebView callback failures  
- ✅ **Payment Confirmation Failures**: Handles server-side confirmation errors
- ✅ **Network Failures**: Handles timeout and connectivity issues

## Architectural Benefits

### Why Firebase Functions?

1. **🔒 Security**: 
   - Server-side logic cannot be bypassed or manipulated
   - Consistent with existing payment confirmation architecture
   - Prevents unauthorized order deletions

2. **🔄 Reliability**:
   - Guaranteed execution regardless of client state
   - Works even if app crashes or loses network during payment
   - Handles webhook-based payment failures uniformly

3. **⚡ Performance**:
   - Server-side processing is faster and more efficient
   - Reduces client-side complexity and bundle size
   - Better error handling and retry mechanisms

4. **🔍 Observability**:
   - Centralized logging in Firebase Functions console
   - Better monitoring and alerting capabilities
   - Audit trail for compliance and debugging

## Error Handling

### Client-Side Error Handling

```dart
try {
  await orderService.deletePendingOrderOnPaymentFailure(orderId);
} catch (e) {
  if (e is PaymentError) {
    // Handle specific payment errors
  } else if (e is OrderServiceException) {
    // Handle order service errors
  }
  // Always show payment failure to user regardless of cleanup status
  _showPaymentError(originalPaymentError);
}
```

### Server-Side Error Handling

- **Authentication Errors**: Returns `unauthenticated` error
- **Permission Errors**: Returns `permission-denied` error
- **Validation Errors**: Returns `invalid-argument` error
- **System Errors**: Returns `internal` error with safe messages

## Testing

### Development Testing

The OrderService includes a test method for development environments:

```dart
Future<Map<String, dynamic>> testPendingOrderDeletion({
  required String orderId,
}) async {
  // Only available in debug mode
  // Tests the complete deletion flow
  // Returns detailed test results
}
```

### Integration Testing

- ✅ Test payment failure scenarios
- ✅ Test network timeout scenarios  
- ✅ Test authentication edge cases
- ✅ Test concurrent deletion attempts
- ✅ Test stock restoration accuracy

## Monitoring & Observability

### Firebase Functions Logs

Monitor the following in Firebase Console:

- `🗑️ 결제 실패로 인한 주문 삭제 시작`
- `✅ 결제 실패 주문 삭제 완료`
- `❌ 결제 실패 주문 삭제 실패`

### Client-Side Logs

Monitor the following in app logs:

- `💳 결제 실패로 인한 주문 정리 시작`
- `✅ 결제 실패 주문 정리 완료`
- `⚠️ 결제 실패 주문 정리 중 오류`

### Audit Trail

All deletions are logged in the `order_deletion_logs` collection:

```javascript
{
  orderId: "user123_1234567890",
  userId: "user123",
  reason: "결제 실패: PAYMENT_FAILED - 카드 정보가 올바르지 않습니다",
  originalOrderData: { /* complete order data */ },
  stockRestorations: [ /* stock restoration details */ ],
  deletedAt: Timestamp,
  deletedBy: "payment_failure_function"
}
```

## Deployment

### Firebase Functions Deployment

```bash
# Deploy the new function
firebase deploy --only functions:deletePendingOrderOnPaymentFailure

# Verify deployment
firebase functions:log --only deletePendingOrderOnPaymentFailure
```

### Client App Updates

- ✅ Update TossPaymentsService
- ✅ Update OrderService  
- ✅ Update PaymentScreen
- ✅ Test integration thoroughly
- ✅ Deploy to production

## Migration Notes

### From Client-Side to Server-Side

1. **Backwards Compatibility**: Old client versions will gracefully degrade
2. **Gradual Rollout**: Can be deployed independently of client updates
3. **Monitoring**: Enhanced logging helps track the migration
4. **Rollback Plan**: Can disable function and revert to client-side if needed

### Database Changes

- ✅ **New Collection**: `order_deletion_logs` for audit trail
- ✅ **Enhanced Logging**: Better error tracking and debugging
- ✅ **No Breaking Changes**: Existing data structures remain unchanged

## Conclusion

Moving the payment failure order deletion logic to Firebase Functions provides:

- **Enhanced Security**: Server-side validation and execution
- **Improved Reliability**: Guaranteed cleanup regardless of client state  
- **Better Observability**: Centralized logging and monitoring
- **Architectural Consistency**: Aligns with existing payment confirmation flow
- **Future-Proof**: Supports webhook-based payment failures and other server-side triggers

This implementation ensures that failed payments always result in proper order cleanup, providing a better user experience and maintaining data integrity. 