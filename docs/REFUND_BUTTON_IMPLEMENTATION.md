# Refund Button Implementation in Order List Item

## Overview
This document describes the implementation of refund functionality in `order_list_item.dart` to match the behavior of the refund button in the home screen's `_RecentOrderItem` widget.

## Changes Made

### 1. **Added Import Statement**
```dart
import '../screens/refund_request_screen.dart';
```
- Added import for `RefundRequestScreen` to enable navigation to the refund request flow.

### 2. **Updated Action Button Logic**
```dart
// 환불 신청 버튼 (confirmed 상태일 때)
if (_canRequestRefund(order.status)) ...[
  Expanded(
    child: OutlinedButton(
      onPressed: () => _showRefundRequestDialog(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorPalette.error,
        side: const BorderSide(color: ColorPalette.error),
      ),
      child: const Text('환불 신청'),
    ),
  ),
  const SizedBox(width: Dimensions.spacingSm),
]
// 주문 취소 버튼 (pending 상태일 때)
else if (order.isCancellable) ...[
  // ... cancel button logic
],
```

**Key Changes:**
- **Conditional Display**: Show "환불 신청" for `confirmed` orders, "주문 취소" for `pending` orders
- **Different Actions**: Refund button calls `_showRefundRequestDialog`, cancel button calls `_showCancelDialog`
- **Clear Separation**: Distinct logic for refund vs cancellation scenarios

### 3. **Added Refund Condition Check**
```dart
/// 환불 요청 가능 여부 확인
bool _canRequestRefund(OrderStatus status) {
  return status == OrderStatus.confirmed;
}
```
- **Refund Eligibility**: Only `confirmed` orders are eligible for refund requests
- **Matches Home Screen**: Same logic as `_RecentOrderItem` in home screen

### 4. **Implemented Refund Request Dialog**
```dart
/// 환불 요청 다이얼로그
void _showRefundRequestDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('반품'),
      content: const Text('반품을 신청하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RefundRequestScreen(order: order),
              ),
            );
          },
          child: const Text('신청'),
        ),
      ],
    ),
  );
}
```

**Dialog Features:**
- **Confirmation Dialog**: Shows before proceeding to refund screen
- **Navigation**: Routes to `RefundRequestScreen` with current order
- **Consistent UX**: Matches the exact behavior from home screen

### 5. **Updated Action Button Visibility**
```dart
/// 액션 버튼을 표시할지 여부
bool _shouldShowActionButtons() {
  return order.isCancellable || order.status.isInProgress || _canRequestRefund(order.status);
}
```
- **Enhanced Logic**: Now includes refund condition in button visibility logic
- **Multiple States**: Shows buttons for pending (cancel), confirmed (refund), and in-progress orders

### 6. **Improved Product Count Display**
```dart
/// 상품 개수 (실제 주문 상품 개수)
String _getProductCount() {
  return order.totalProductCount.toString();
}
```
- **Accurate Count**: Uses actual `totalProductCount` from OrderModel
- **No More Hardcoding**: Removed placeholder "1" value

## User Flow Comparison

### Before Changes
```
[확인된 주문] → [환불 신청 버튼] → [주문 취소 다이얼로그] → [기능 미구현 스낵바]
```

### After Changes
```
[확인된 주문] → [환불 신청 버튼] → [반품 확인 다이얼로그] → [RefundRequestScreen]
[대기 중 주문] → [주문 취소 버튼] → [주문 취소 다이얼로그] → [취소 기능]
```

## Benefits

1. **Consistent UX**: Refund flow now matches exactly with home screen behavior
2. **Clear Separation**: Distinct buttons and flows for refund vs cancellation
3. **Proper Navigation**: Directs users to the appropriate refund request screen
4. **Status-Aware**: Shows correct action based on order status
5. **Accurate Data**: Displays real product count instead of hardcoded values

## Testing

✅ **Refund Button Display**: Shows "환불 신청" for confirmed orders  
✅ **Cancel Button Display**: Shows "주문 취소" for pending orders  
✅ **Dialog Navigation**: Refund dialog navigates to RefundRequestScreen  
✅ **Status Logic**: Buttons appear based on correct order status conditions  
✅ **Product Count**: Displays actual product count from order data  

## Integration

This implementation seamlessly integrates with:
- **RefundRequestScreen**: Existing refund flow
- **Order Status System**: Uses OrderStatus enum properly
- **Theme System**: Consistent styling with ColorPalette
- **Navigation**: Standard MaterialPageRoute navigation 