/// 픽업 인증 모달 위젯
///
/// 픽업 완료를 인증하기 위해 이미지를 업로드하는 모달입니다.
/// Firebase Storage에 이미지를 업로드하고 주문 정보를 업데이트합니다.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/theme/index.dart';
import '../models/order_model.dart';
import '../models/order_enums.dart';
import '../repositories/order_repository.dart';

/// 픽업 인증 모달 위젯
class PickupVerificationModal extends ConsumerStatefulWidget {
  final OrderModel order;

  const PickupVerificationModal({
    super.key,
    required this.order,
  });

  @override
  ConsumerState<PickupVerificationModal> createState() => _PickupVerificationModalState();
}

class _PickupVerificationModalState extends ConsumerState<PickupVerificationModal> {
  final ImagePicker _imagePicker = ImagePicker();
  
  XFile? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  bool get _isAlreadyVerified => widget.order.isPickupVerified == true;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isAlreadyVerified ? Icons.check_circle : Icons.verified,
            color: _isAlreadyVerified ? ColorPalette.success : ColorPalette.primary,
            size: 24,
          ),
          const SizedBox(width: Dimensions.spacingSm),
          Text(_isAlreadyVerified ? '픽업 인증 완료' : '픽업 인증'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 안내 메시지
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSm),
              decoration: BoxDecoration(
                color: ColorPalette.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                border: Border.all(
                  color: ColorPalette.primary.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isAlreadyVerified ? '픽업 인증 완료' : '픽업 완료 인증',
                    style: TextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _isAlreadyVerified ? ColorPalette.success : ColorPalette.primary,
                    ),
                  ),
                  const SizedBox(height: Dimensions.spacingXs),
                  Text(
                    _isAlreadyVerified 
                        ? '픽업 인증이 완료되었습니다. 아래에서 인증 사진을 확인하실 수 있습니다.'
                        : '상품을 정상적으로 픽업하셨다면, 픽업한 상품의 사진을 촬영하여 인증해주세요.',
                    style: TextStyles.bodySmall.copyWith(
                      color: isDarkMode
                          ? ColorPalette.textSecondaryDark
                          : ColorPalette.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Dimensions.spacingMd),

            // 주문 정보 요약
            Text(
              '주문 정보',
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Dimensions.spacingXs),
            Text(
              '주문번호: ${widget.order.orderId}',
              style: TextStyles.bodySmall.copyWith(
                color: isDarkMode
                    ? ColorPalette.textSecondaryDark
                    : ColorPalette.textSecondaryLight,
              ),
            ),
            Text(
              '상품명: ${widget.order.representativeProductName ?? "상품명 없음"}',
              style: TextStyles.bodySmall.copyWith(
                color: isDarkMode
                    ? ColorPalette.textSecondaryDark
                    : ColorPalette.textSecondaryLight,
              ),
            ),

            const SizedBox(height: Dimensions.spacingMd),

            // 이미지 선택 섹션
            Text(
              _isAlreadyVerified ? '픽업 인증 사진' : '픽업 인증 사진',
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Dimensions.spacingSm),

            // 이미지 선택 버튼들 (이미 인증된 경우 비활성화)
            if (!_isAlreadyVerified) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, size: 20),
                      label: const Text('카메라'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDarkMode
                            ? ColorPalette.textSecondaryDark
                            : ColorPalette.textSecondaryLight,
                        side: BorderSide(
                          color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSm,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Dimensions.spacingSm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, size: 20),
                      label: const Text('갤러리'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDarkMode
                            ? ColorPalette.textSecondaryDark
                            : ColorPalette.textSecondaryLight,
                        side: BorderSide(
                          color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSm,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // 선택된 이미지 또는 저장된 인증 이미지 표시
            if (_selectedImage != null || (_isAlreadyVerified && widget.order.pickupImageUrl != null)) ...[
              const SizedBox(height: Dimensions.spacingSm),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                  child: Stack(
                    children: [
                      // 이미지 표시
                      Positioned.fill(
                        child: _isAlreadyVerified && widget.order.pickupImageUrl != null
                            ? Image.network(
                                widget.order.pickupImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.error),
                                  );
                                },
                              )
                            : _selectedImage != null
                                ? (kIsWeb
                                    ? Image.network(
                                        _selectedImage!.path,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.error),
                                          );
                                        },
                                      )
                                    : Image.file(
                                        File(_selectedImage!.path),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.error),
                                          );
                                        },
                                      ))
                                : Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.error),
                                  ),
                      ),
                      // 삭제 버튼 (이미 인증된 경우 비활성화)
                      if (!_isAlreadyVerified && _selectedImage != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                                _errorMessage = null;
                              });
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: ColorPalette.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      // 인증 완료 배지 (이미 인증된 경우)
                      if (_isAlreadyVerified)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ColorPalette.success,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '인증완료',
                                  style: TextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // 에러 메시지 표시
            if (_errorMessage != null) ...[
              const SizedBox(height: Dimensions.spacingSm),
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSm),
                decoration: BoxDecoration(
                  color: ColorPalette.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                  border: Border.all(
                    color: ColorPalette.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: ColorPalette.error,
                      size: 20,
                    ),
                    const SizedBox(width: Dimensions.spacingXs),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyles.bodySmall.copyWith(
                          color: ColorPalette.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        // 취소/닫기 버튼
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: Text(_isAlreadyVerified ? '닫기' : '취소'),
        ),
        // 인증 완료 버튼 (이미 인증된 경우 비활성화)
        if (!_isAlreadyVerified)
          ElevatedButton(
            onPressed: _isLoading || _selectedImage == null
                ? null
                : _submitVerification,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.primary,
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('인증 완료'),
          ),
      ],
    );
  }

  /// 이미지 선택 (이미 인증된 경우 비활성화)
  Future<void> _pickImage(ImageSource source) async {
    if (_isAlreadyVerified) return;
    
    try {
      setState(() {
        _errorMessage = null;
      });

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '이미지 선택 중 오류가 발생했습니다: $e';
      });
    }
  }

  /// 픽업 인증 제출 (이미 인증된 경우 비활성화)
  Future<void> _submitVerification() async {
    if (_isAlreadyVerified) return;
    
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = '픽업 인증을 위해 사진을 선택해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1️⃣ 이미지를 Firebase Storage에 업로드
      final imageUrl = await _uploadImage();

      // 2️⃣ 주문 정보 업데이트 (픽업 인증 정보 + 주문 상태 변경)
      final orderRepository = ref.read(orderRepositoryProvider);
      
      // 픽업 인증 정보 업데이트
      await orderRepository.updatePickupVerification(
        orderId: widget.order.orderId,
        pickupImageUrl: imageUrl,
      );
      
      // 주문 상태를 pickup_ready에서 picked_up으로 변경
      await orderRepository.updateOrderStatus(
        orderId: widget.order.orderId,
        newStatus: OrderStatus.pickedUp,
        reason: '픽업 인증 완료',
      );

      // 3️⃣ 성공 시 모달 닫기
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '픽업 인증에 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  /// 이미지를 Firebase Storage에 업로드
  Future<String> _uploadImage() async {
    if (_selectedImage == null) {
      throw Exception('업로드할 이미지가 없습니다.');
    }

    final storage = FirebaseStorage.instance;
    final fileName =
        'pickup_verification/${widget.order.orderId}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      late final UploadTask uploadTask;

      if (kIsWeb) {
        // 웹에서는 bytes 사용
        final bytes = await _selectedImage!.readAsBytes();
        uploadTask = storage.ref().child(fileName).putData(
              bytes,
              SettableMetadata(contentType: 'image/jpeg'),
            );
      } else {
        // 모바일에서는 파일 사용
        final file = File(_selectedImage!.path);
        uploadTask = storage.ref().child(fileName).putFile(
              file,
              SettableMetadata(contentType: 'image/jpeg'),
            );
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('✅ 픽업 인증 이미지 업로드 완료: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ 픽업 인증 이미지 업로드 실패: $e');
      throw Exception('이미지 업로드에 실패했습니다: $e');
    }
  }
}