/// 환불 요청 모달 위젯
///
/// 사용자가 환불을 요청할 때 사용하는 모달입니다.
/// 이미지 첨부와 환불 사유 입력이 가능합니다.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/theme/index.dart';
import '../models/order_model.dart';
import '../models/refund_model.dart';
import '../repositories/refund_repository.dart';
import '../models/order_enums.dart';

/// 환불 요청 모달 결과
class RefundRequestResult {
  final bool isSuccess;
  final String? errorMessage;
  final RefundModel? refundModel;

  const RefundRequestResult({
    required this.isSuccess,
    this.errorMessage,
    this.refundModel,
  });
}

/// 환불 요청 모달 위젯
class RefundRequestModal extends ConsumerStatefulWidget {
  final OrderModel order;

  const RefundRequestModal({
    super.key,
    required this.order,
  });

  @override
  ConsumerState<RefundRequestModal> createState() => _RefundRequestModalState();

  /// 모달 표시 헬퍼 메서드
  static Future<RefundRequestResult?> showModal({
    required BuildContext context,
    required OrderModel order,
  }) async {
    return await showModalBottomSheet<RefundRequestResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RefundRequestModal(order: order),
    );
  }
}

class _RefundRequestModalState extends ConsumerState<RefundRequestModal> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<XFile> _selectedImages = [];
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottomInset),
      duration: const Duration(milliseconds: 100),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? ColorPalette.backgroundDark
              : ColorPalette.backgroundLight,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(Dimensions.radius),
            topRight: Radius.circular(Dimensions.radius),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 모달 헤더
                _buildModalHeader(isDarkMode),

                const SizedBox(height: Dimensions.spacingLg),

                // 주문 정보 요약
                _buildOrderSummary(isDarkMode),

                const SizedBox(height: Dimensions.spacingLg),

                // 폼 영역
                Flexible(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 환불 사유 입력
                        _buildReasonInput(isDarkMode),

                        const SizedBox(height: Dimensions.spacingLg),

                        // 이미지 첨부 섹션
                        _buildImageSection(isDarkMode),

                        const SizedBox(height: Dimensions.spacingLg),

                        // 버튼 영역
                        _buildActionButtons(isDarkMode),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 모달 헤더 빌드
  Widget _buildModalHeader(bool isDarkMode) {
    return Row(
      children: [
        Icon(
          Icons.assignment_return,
          color: ColorPalette.primary,
          size: 24,
        ),
        const SizedBox(width: Dimensions.spacingSm),
        Expanded(
          child: Text(
            '환불 요청',
            style: TextStyles.titleLarge.copyWith(
              color: isDarkMode
                  ? ColorPalette.textPrimaryDark
                  : ColorPalette.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          icon: Icon(
            Icons.close,
            color: isDarkMode
                ? ColorPalette.textSecondaryDark
                : ColorPalette.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  /// 주문 정보 요약 빌드
  Widget _buildOrderSummary(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSm),
      decoration: BoxDecoration(
        color: isDarkMode
            ? ColorPalette.surfaceDark.withOpacity(0.5)
            : ColorPalette.surfaceLight,
        borderRadius: BorderRadius.circular(Dimensions.radiusSm),
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '주문 정보',
            style: TextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? ColorPalette.textPrimaryDark
                  : ColorPalette.textPrimaryLight,
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
          Text(
            '주문금액: ${widget.order.totalAmount}원',
            style: TextStyles.bodySmall.copyWith(
              color: isDarkMode
                  ? ColorPalette.textSecondaryDark
                  : ColorPalette.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  /// 환불 사유 입력 빌드
  Widget _buildReasonInput(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '환불 사유',
              style: TextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDarkMode
                    ? ColorPalette.textPrimaryDark
                    : ColorPalette.textPrimaryLight,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyles.bodyMedium.copyWith(
                color: ColorPalette.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: Dimensions.spacingSm),
        TextFormField(
          controller: _reasonController,
          enabled: !_isLoading,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: '환불을 요청하는 사유를 상세히 입력해주세요.\n(예: 상품 불량, 배송 지연, 단순 변심 등)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusSm),
              borderSide: const BorderSide(
                color: ColorPalette.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isDarkMode
                ? Colors.grey[800]?.withOpacity(0.3)
                : Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '환불 사유를 입력해주세요.';
            }
            if (value.trim().length < 10) {
              return '환불 사유를 10자 이상 입력해주세요.';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 이미지 섹션 빌드
  Widget _buildImageSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '첨부 이미지 (선택사항)',
          style: TextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: isDarkMode
                ? ColorPalette.textPrimaryDark
                : ColorPalette.textPrimaryLight,
          ),
        ),
        const SizedBox(height: Dimensions.spacingXs),
        Text(
          '상품 상태나 문제점을 보여주는 사진을 첨부하면 환불 처리가 더 빨라집니다.',
          style: TextStyles.bodySmall.copyWith(
            color: isDarkMode
                ? ColorPalette.textSecondaryDark
                : ColorPalette.textSecondaryLight,
          ),
        ),
        const SizedBox(height: Dimensions.spacingSm),

        // 이미지 추가 버튼들
        Row(
          children: [
            _buildImagePickerButton(
              icon: Icons.photo_library,
              label: '갤러리',
              onTap: () => _pickImages(ImageSource.gallery),
              isDarkMode: isDarkMode,
            ),
            const SizedBox(width: Dimensions.spacingSm),
            _buildImagePickerButton(
              icon: Icons.camera_alt,
              label: '카메라',
              onTap: () => _pickImages(ImageSource.camera),
              isDarkMode: isDarkMode,
            ),
          ],
        ),

        // 선택된 이미지 표시
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: Dimensions.spacingSm),
          _buildSelectedImagesGrid(isDarkMode),
        ],
      ],
    );
  }

  /// 이미지 피커 버튼 빌드
  Widget _buildImagePickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
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
    );
  }

  /// 선택된 이미지 그리드 빌드
  Widget _buildSelectedImagesGrid(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSm),
      decoration: BoxDecoration(
        color:
            isDarkMode ? Colors.grey[800]?.withOpacity(0.3) : Colors.grey[50],
        borderRadius: BorderRadius.circular(Dimensions.radiusSm),
        border: Border.all(
          color: isDarkMode ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '첨부된 이미지 (${_selectedImages.length}개)',
            style: TextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? ColorPalette.textSecondaryDark
                  : ColorPalette.textSecondaryLight,
            ),
          ),
          const SizedBox(height: Dimensions.spacingXs),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                final image = _selectedImages[index];
                return Container(
                  margin: const EdgeInsets.only(right: Dimensions.spacingSm),
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSm),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.grey[600]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSm),
                          child: kIsWeb
                              ? Image.network(
                                  image.path,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.error),
                                    );
                                  },
                                )
                              : Image.file(
                                  File(image.path),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.error),
                                    );
                                  },
                                ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: ColorPalette.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 액션 버튼 빌드
  Widget _buildActionButtons(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
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
            child: const Text('취소'),
          ),
        ),
        const SizedBox(width: Dimensions.spacingSm),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitRefundRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorPalette.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: Dimensions.paddingSm,
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('환불 요청'),
          ),
        ),
      ],
    );
  }

  /// 이미지 선택
  Future<void> _pickImages(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        // 갤러리에서 여러 이미지 선택 (최대 5개)
        final List<XFile> images = await _imagePicker.pickMultiImage(
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );

        if (images.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(images);
            // 최대 5개까지만 허용
            if (_selectedImages.length > 5) {
              _selectedImages = _selectedImages.take(5).toList();
            }
          });
        }
      } else {
        // 카메라로 단일 이미지 촬영
        final XFile? image = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _selectedImages.add(image);
            // 최대 5개까지만 허용
            if (_selectedImages.length > 5) {
              _selectedImages = _selectedImages.take(5).toList();
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 선택 중 오류가 발생했습니다: $e'),
            backgroundColor: ColorPalette.error,
          ),
        );
      }
    }
  }

  /// 이미지 제거
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// 환불 요청 제출
  Future<void> _submitRefundRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1️⃣ 이미지 업로드 (있는 경우)
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        setState(() {
          _isUploading = true;
        });

        imageUrls = await _uploadImages();
      }

      // 2️⃣ 환불 요청 생성
      final refundRepository = ref.read(refundRepositoryProvider);

      final refund = await refundRepository.createRefundRequest(
        orderId: widget.order.orderId,
        userId: widget.order.userId,
        refundAmount: widget.order.totalAmount,
        originalOrderAmount: widget.order.totalAmount,
        refundReason: _reasonController.text.trim(),
        paymentMethod:
            widget.order.paymentInfo?.method ?? PaymentMethod.unknown,
        paymentKey: widget.order.paymentInfo?.paymentKey,
        type: RefundType.full,
        clientInfo: {
          'attachedImages': imageUrls,
          'imageCount': imageUrls.length,
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
          'requestedAt': DateTime.now().toIso8601String(),
        },
      );

      // 3️⃣ 성공 결과 반환
      if (mounted) {
        Navigator.pop(
          context,
          RefundRequestResult(
            isSuccess: true,
            refundModel: refund,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ 환불 요청 실패: $e');

      if (mounted) {
        Navigator.pop(
          context,
          RefundRequestResult(
            isSuccess: false,
            errorMessage: '환불 요청에 실패했습니다: $e',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }

  /// 이미지들을 Firebase Storage에 업로드
  Future<List<String>> _uploadImages() async {
    final List<String> imageUrls = [];
    final storage = FirebaseStorage.instance;

    for (int i = 0; i < _selectedImages.length; i++) {
      final image = _selectedImages[i];
      final fileName =
          'refund_images/${widget.order.orderId}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

      try {
        late final UploadTask uploadTask;

        if (kIsWeb) {
          // 웹에서는 bytes 사용
          final bytes = await image.readAsBytes();
          uploadTask = storage.ref().child(fileName).putData(
                bytes,
                SettableMetadata(contentType: 'image/jpeg'),
              );
        } else {
          // 모바일에서는 파일 사용
          final file = File(image.path);
          uploadTask = storage.ref().child(fileName).putFile(
                file,
                SettableMetadata(contentType: 'image/jpeg'),
              );
        }

        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);

        debugPrint('✅ 이미지 업로드 완료 $i: $downloadUrl');
      } catch (e) {
        debugPrint('❌ 이미지 업로드 실패 $i: $e');
        // 일부 이미지 업로드 실패 시에도 계속 진행
      }
    }

    return imageUrls;
  }
}
