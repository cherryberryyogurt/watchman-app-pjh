import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/index.dart';

/// SMS 인증번호 입력을 위한 위젯
class VerificationCodeInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onCompleted;
  final bool enabled;
  final int length;

  const VerificationCodeInput({
    super.key,
    required this.controller,
    this.onCompleted,
    this.enabled = true,
    this.length = 6,
  });

  @override
  State<VerificationCodeInput> createState() => _VerificationCodeInputState();
}

class _VerificationCodeInputState extends State<VerificationCodeInput> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  String?
      _lastCompletedValue; // Track the last completed value to prevent duplicate callbacks
  DateTime? _lastCallbackTime; // Track last callback time for debouncing
  static const Duration _callbackDebounce =
      Duration(milliseconds: 500); // Debounce duration

  @override
  void initState() {
    super.initState();

    // 각 자리수에 대한 포커스 노드와 컨트롤러 생성
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _controllers =
        List.generate(widget.length, (index) => TextEditingController());

    // 통합 컨트롤러의 변경 사항 감지
    widget.controller.addListener(_updateFieldsFromController);

    // 각 필드의 컨트롤러에 리스너 추가
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].addListener(() => _updateControllerFromFields());
    }
  }

  @override
  void dispose() {
    // 리소스 해제
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }

    for (var controller in _controllers) {
      controller.dispose();
    }

    super.dispose();
  }

  // 개별 필드의 값을 통합 컨트롤러에 반영
  void _updateControllerFromFields() {
    final combinedValue = _controllers.map((c) => c.text).join();

    if (widget.controller.text != combinedValue) {
      widget.controller.text = combinedValue;

      // 모든 자리가 입력되면 완료 콜백 호출 (단, 이전 완료값과 다를 때만)
      if (combinedValue.length == widget.length && widget.onCompleted != null) {
        print(
            '🔥 DEBUG: VerificationCodeInput - combinedValue: "$combinedValue", lastCompletedValue: "$_lastCompletedValue"');

        final now = DateTime.now();
        final shouldTriggerCallback = _lastCompletedValue != combinedValue &&
            (_lastCallbackTime == null ||
                now.difference(_lastCallbackTime!) > _callbackDebounce);

        if (shouldTriggerCallback) {
          print(
              '🔥 DEBUG: VerificationCodeInput - Triggering onCompleted callback for new value: "$combinedValue"');
          _lastCompletedValue = combinedValue;
          _lastCallbackTime = now;
          widget.onCompleted!(combinedValue);
        } else if (_lastCompletedValue == combinedValue) {
          print(
              '🔥 DEBUG: VerificationCodeInput - Skipping duplicate onCompleted for same value: "$combinedValue"');
        } else {
          print(
              '🔥 DEBUG: VerificationCodeInput - Skipping onCompleted due to debounce (${now.difference(_lastCallbackTime!).inMilliseconds}ms since last)');
        }
      } else if (combinedValue.length < widget.length) {
        print(
            '🔥 DEBUG: VerificationCodeInput - Resetting lastCompletedValue (incomplete: "${combinedValue}")');
        // 값이 불완전해지면 마지막 완료값 초기화
        _lastCompletedValue = null;
      }
    }
  }

  // 통합 컨트롤러의 값을 개별 필드에 반영
  void _updateFieldsFromController() {
    final value = widget.controller.text;

    for (int i = 0; i < widget.length; i++) {
      if (i < value.length) {
        _controllers[i].text = value[i];
      } else {
        _controllers[i].text = '';
      }
    }
  }

  // 다음 필드로 포커스 이동
  void _moveFocusToNextField(int currentIndex) {
    if (currentIndex < widget.length - 1) {
      _focusNodes[currentIndex + 1].requestFocus();
    } else {
      // 마지막 필드인 경우 포커스 해제
      _focusNodes[currentIndex].unfocus();
    }
  }

  // 이전 필드로 포커스 이동
  void _moveFocusToPreviousField(int currentIndex) {
    if (currentIndex > 0) {
      _focusNodes[currentIndex - 1].requestFocus();
    }
  }

  // 백스페이스 키 처리 함수
  void _handleBackspace(int index) {
    if (_controllers[index].text.isEmpty) {
      _moveFocusToPreviousField(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        widget.length,
        (index) => Container(
          width: 45,
          height: 55,
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
            borderRadius: BorderRadius.circular(Dimensions.radiusSm),
          ),
          child: KeyboardListener(
            focusNode: FocusNode(), // const 추가로 성능 개선
            onKeyEvent: (KeyEvent event) {
              // 백스페이스 키 처리
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace) {
                _handleBackspace(index);
              }
            },
            child: TextFormField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: TextStyles.titleLarge,
              decoration: const InputDecoration(
                // const 추가
                contentPadding: EdgeInsets.zero,
                counterText: '',
                border: InputBorder.none,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              enabled: widget.enabled,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _moveFocusToNextField(index);
                } else {
                  // 값이 지워진 경우에도 이전 필드로 이동
                  _handleBackspace(index);
                }
              },
              onTap: () {
                // 전체 선택하여 쉽게 값 변경 가능하도록
                _controllers[index].selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _controllers[index].text.length,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
