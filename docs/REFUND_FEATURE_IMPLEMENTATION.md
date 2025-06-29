# Refund Feature Implementation Summary

## Overview
This document summarizes the implementation of the refund feature for the Gonggoo App, including both full and partial refunds with special support for virtual account (가상계좌) refunds.

## Architecture
- **Frontend**: Flutter with Riverpod state management
- **Backend**: Firebase (Firestore database, Cloud Functions for secure operations)  
- **Payment Gateway**: Toss Payments SDK v1

## Implementation Details

### 1. Virtual Account Refund UI (RefundRequestScreen)
Added complete UI for virtual account refunds with the following fields:
- **Bank Selection**: Dropdown with 14 Korean banks
- **Account Number**: Text field with digit-only validation (10-20 characters)
- **Account Holder Name**: Text field with minimum 2 character validation

### 2. Database Logic (OrderRepository)
Implemented `addRefundRecord` method that:
- Creates a refund subcollection under the order document
- Updates the payment balance amount after partial refunds
- Maintains refund history in the order document
- Uses Firestore transactions for data consistency

### 3. Order Service Integration
Updated `requestRefund` method to:
- Use the new `addRefundRecord` method for partial refunds
- Properly handle virtual account refund information
- Support both full and partial refunds

## Key Features

### Full Refund
- Updates order status to 'cancelled'
- Returns entire balance amount
- Automatically handled by Toss Payments

### Partial Refund
- Maintains order status
- Updates balance amount in payment info
- Records refund in subcollection
- Tracks refund history

### Virtual Account Refunds
- Collects bank account details
- Validates account information
- Passes refund account info to Toss Payments API

## Security Considerations
- All refund operations go through Firebase Cloud Functions
- No sensitive payment data is stored on the client
- Uses Toss Payments secure API for actual refund processing

## Testing Checklist
- [ ] Full refund for card payments
- [ ] Partial refund for card payments  
- [ ] Full refund for virtual account payments
- [ ] Partial refund for virtual account payments
- [ ] Multiple partial refunds on same order
- [ ] Refund validation (amount exceeds balance)
- [ ] Cross-platform testing (iOS, Android, Web)

## Future Enhancements
1. Add refund history view in order detail screen
2. Implement refund status tracking
3. Add push notifications for refund status updates
4. Support for other payment methods (mobile payments, etc.) 