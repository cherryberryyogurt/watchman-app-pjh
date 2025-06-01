import 'package:flutter/material.dart';

/// 🧪 텍스트 입력 문제 디버깅을 위한 간단한 테스트 화면
class TextInputTestScreen extends StatefulWidget {
  static const routeName = '/text-input-test';

  const TextInputTestScreen({super.key});

  @override
  State<TextInputTestScreen> createState() => _TextInputTestScreenState();
}

class _TextInputTestScreenState extends State<TextInputTestScreen> {
  final _testController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _displayText = '';
  int _rebuildCount = 0;

  @override
  void initState() {
    super.initState();
    _testController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _testController.removeListener(_onTextChanged);
    _testController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _displayText = _testController.text;
    });
  }

  // 🔥 추가: 버튼 활성화 로직 테스트
  bool get _isButtonEnabled => _testController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    _rebuildCount++;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('텍스트 입력 & 버튼 활성화 테스트'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 디버깅 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔄 Rebuild Count: $_rebuildCount'),
                    Text('📝 Controller Text: "${_testController.text}"'),
                    Text('💾 Display Text: "$_displayText"'),
                    Text('📱 Text Length: ${_testController.text.length}'),
                    Text('🔘 Button Enabled: $_isButtonEnabled', 
                         style: TextStyle(
                           color: _isButtonEnabled ? Colors.green : Colors.red,
                           fontWeight: FontWeight.bold,
                         )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // 테스트 입력 필드
              TextFormField(
                controller: _testController,
                decoration: const InputDecoration(
                  labelText: '테스트 입력',
                  hintText: '여기에 텍스트를 입력해보세요',
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '텍스트를 입력해주세요';
                  }
                  return null;
                },
                onChanged: (value) {
                  print('🔤 onChanged: "$value", controller: "${_testController.text}"'); // TODO: 디버깅용
                  print('🔘 Button enabled: $_isButtonEnabled'); // TODO: 디버깅용
                  setState(() {
                    // 항상 UI 업데이트 (RegisterScreen과 동일한 패턴)
                  });
                },
              ),
              const SizedBox(height: 20),
              
              // 🔥 추가: 활성화 상태 테스트를 위한 버튼
              ElevatedButton(
                onPressed: _isButtonEnabled ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('버튼이 활성화되어 클릭됨: ${_testController.text}'),
                    ),
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isButtonEnabled ? Colors.blue : Colors.grey,
                ),
                child: Text(_isButtonEnabled ? '활성화됨 - 클릭 가능' : '비활성화됨'),
              ),
              const SizedBox(height: 10),
              
              // 테스트 버튼들
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _testController.text = 'Controller로 설정된 텍스트';
                      },
                      child: const Text('Controller 텍스트 설정'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _testController.clear();
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('입력된 텍스트: ${_testController.text}'),
                      ),
                    );
                  }
                },
                child: const Text('Validate & Submit'),
              ),
              
              const SizedBox(height: 20),
              
              // 현재 상태 정보
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📋 수정된 상태:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('• onChanged에서 항상 setState 호출'),
                    Text('• 버튼 활성화 조건: text.trim().isNotEmpty'),
                    Text('• InputConnection 유지됨'),
                    Text('• 실시간 버튼 상태 업데이트'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 