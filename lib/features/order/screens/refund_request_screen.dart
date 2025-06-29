import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../models/order_enums.dart';
import '../services/order_service.dart';
import '../../../core/theme/index.dart';

/// 환불 요청 화면
///
/// 사용자가 주문에 대한 환불을 요청할 수 있는 화면입니다.
/// 전액/부분 환불, 환불 사유 선택, 가상계좌 환불 시 계좌 정보 입력을 지원합니다.
class RefundRequestScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const RefundRequestScreen({
    super.key,
    required this.order,
  });

  @override
  ConsumerState<RefundRequestScreen> createState() =>
      _RefundRequestScreenState();
}

class _RefundRequestScreenState extends ConsumerState<RefundRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customReasonController = TextEditingController();
  final _refundAmountController = TextEditingController();

  // 가상계좌 환불용 입력 필드
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();

  bool _isFullRefund = true;
  String? _selectedReason;
  bool _isLoading = false;
  String? _selectedBank;

  // 환불 사유 옵션들
  final List<String> _refundReasons = [
    '단순 변심',
    '상품 불량',
    '배송 지연',
    '상품 설명과 다름',
    '기타',
  ];

  // 은행 목록 (한국 주요 은행)
  final List<String> _bankList = [
    'KB국민은행',
    '신한은행',
    '우리은행',
    '하나은행',
    'SC제일은행',
    '농협은행',
    '기업은행',
    '산업은행',
    '새마을금고',
    '신협',
    '우체국',
    '카카오뱅크',
    '케이뱅크',
    '토스뱅크',
  ];

  // 통화 포맷팅 함수
  String _formatCurrency(int amount) {
    final formatter = NumberFormat('#,###');
    return '${formatter.format(amount)}원';
  }

  @override
  void initState() {
    super.initState();
    final maxAmount = widget.order.paymentInfo?.balanceAmount ?? 0;
    _refundAmountController.text = _formatCurrency(maxAmount);
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    _refundAmountController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentInfo = widget.order.paymentInfo;
    final maxRefundAmount = paymentInfo?.balanceAmount ?? 0;
    final isVirtualAccount = paymentInfo?.method?.value == '가상계좌';

    return Scaffold(
      appBar: AppBar(
        title: const Text('환불 요청'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 주문 정보
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '주문 정보',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('주문번호', widget.order.orderId),
                          _buildInfoRow('결제수단',
                              paymentInfo?.method?.displayName ?? '알 수 없음'),
                          _buildInfoRow('결제금액',
                              _formatCurrency(paymentInfo?.totalAmount ?? 0)),
                          _buildInfoRow(
                              '환불가능금액', _formatCurrency(maxRefundAmount)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 환불 타입
                  const Text(
                    '환불 타입',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<bool>(
                    title: Text('전액 환불 (${_formatCurrency(maxRefundAmount)})'),
                    value: true,
                    groupValue: _isFullRefund,
                    onChanged: (value) {
                      setState(() {
                        _isFullRefund = value!;
                        if (_isFullRefund) {
                          _refundAmountController.text =
                              _formatCurrency(maxRefundAmount);
                        }
                      });
                    },
                  ),
                  RadioListTile<bool>(
                    title: const Text('부분 환불'),
                    value: false,
                    groupValue: _isFullRefund,
                    onChanged: (value) {
                      setState(() {
                        _isFullRefund = value!;
                        if (!_isFullRefund) {
                          _refundAmountController.clear();
                        }
                      });
                    },
                  ),

                  if (!_isFullRefund) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _refundAmountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '환불 금액',
                        hintText: '환불받을 금액을 입력하세요',
                        suffixText: '원',
                        border: const OutlineInputBorder(),
                        helperText: '최대 ${_formatCurrency(maxRefundAmount)}',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '환불 금액을 입력해주세요';
                        }
                        final amount = int.tryParse(
                            value.replaceAll(',', '').replaceAll('원', ''));
                        if (amount == null || amount <= 0) {
                          return '올바른 금액을 입력해주세요';
                        }
                        if (amount > maxRefundAmount) {
                          return '환불 가능한 금액을 초과했습니다';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),

                  // 환불 사유
                  const Text(
                    '환불 사유',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _refundReasons.map((reason) {
                      final isSelected = _selectedReason == reason;
                      return FilterChip(
                        label: Text(reason),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedReason = selected ? reason : null;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  if (_selectedReason == '기타') ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _customReasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: '상세 사유',
                        hintText: '환불 사유를 상세히 입력해주세요',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_selectedReason == '기타' &&
                            (value == null || value.trim().isEmpty)) {
                          return '상세 사유를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                  ],

                  // 가상계좌 환불 계좌 정보
                  if (isVirtualAccount) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ColorPalette.info.withAlpha(25), // 0.1 * 255
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ColorPalette.info.withAlpha(76), // 0.3 * 255
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance,
                                size: 20,
                                color: ColorPalette.info,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '환불 받을 계좌 정보',
                                style: TextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: ColorPalette.info,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // 은행명
                          Text(
                            '은행명',
                            style: TextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedBank,
                            decoration: const InputDecoration(
                              hintText: '은행을 선택해주세요',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: _bankList.map((bank) {
                              return DropdownMenuItem(
                                value: bank,
                                child: Text(bank),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedBank = value;
                                _bankNameController.text = value ?? '';
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '은행을 선택해주세요';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // 계좌번호
                          Text(
                            '계좌번호',
                            style: TextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _accountNumberController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '계좌번호를 입력해주세요 (- 제외)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '계좌번호를 입력해주세요';
                              }
                              if (value.length < 10 || value.length > 20) {
                                return '올바른 계좌번호를 입력해주세요';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // 예금주명
                          Text(
                            '예금주명',
                            style: TextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _accountHolderController,
                            decoration: const InputDecoration(
                              hintText: '예금주명을 입력해주세요',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '예금주명을 입력해주세요';
                              }
                              if (value.length < 2) {
                                return '올바른 예금주명을 입력해주세요';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // 환불 요청 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _selectedReason == null ? null : _submitRefundRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('환불 요청'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 로딩 오버레이
          if (_isLoading)
            Container(
              color: Colors.black.withAlpha(127), // 0.5 * 255
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRefundRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 가상계좌 환불 시 추가 검증
    final isVirtualAccount =
        widget.order.paymentInfo?.method == PaymentMethod.virtualAccount;
    if (isVirtualAccount) {
      if (_selectedBank == null || _selectedBank!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('은행을 선택해주세요'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_accountNumberController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계좌번호를 입력해주세요'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_accountHolderController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예금주명을 입력해주세요'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final orderService = ref.read(orderServiceProvider);

      // 환불 금액 계산
      int? cancelAmount;
      if (!_isFullRefund) {
        final amountText = _refundAmountController.text
            .replaceAll(',', '')
            .replaceAll('원', '');
        cancelAmount = int.tryParse(amountText);
      }

      // 환불 사유
      String cancelReason = _selectedReason!;
      if (_selectedReason == '기타' &&
          _customReasonController.text.trim().isNotEmpty) {
        cancelReason = _customReasonController.text.trim();
      }

      // 가상계좌 환불 계좌 정보
      Map<String, dynamic>? refundReceiveAccount;
      if (isVirtualAccount) {
        refundReceiveAccount = {
          'bank': _bankNameController.text.trim(),
          'accountNumber': _accountNumberController.text.trim(),
          'holderName': _accountHolderController.text.trim(),
        };

        debugPrint('🏦 가상계좌 환불 정보: $refundReceiveAccount');
      }

      // 환불 요청
      await orderService.requestRefund(
        orderId: widget.order.orderId,
        cancelReason: cancelReason,
        cancelAmount: cancelAmount,
        refundReceiveAccount: refundReceiveAccount,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cancelAmount == null
                  ? '전액 환불 요청이 완료되었습니다.'
                  : '부분 환불 요청이 완료되었습니다.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('환불 요청 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
