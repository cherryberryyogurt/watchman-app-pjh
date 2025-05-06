class Validators {
  // Private constructor to prevent instantiation
  Validators._();

  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }
    
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
    );
    
    if (!emailRegExp.hasMatch(value)) {
      return '올바른 이메일 형식이 아닙니다';
    }
    
    return null;
  }

  // Password validation - 최소 8자, 대소문자 조합, 특수문자 1개 이상
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    
    if (value.length < 8) {
      return '비밀번호는 최소 8자 이상이어야 합니다';
    }
    
    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(value);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(value);
    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);
    
    if (!hasUpperCase || !hasLowerCase) {
      return '비밀번호는 대문자와 소문자를 모두 포함해야 합니다';
    }
    
    if (!hasSpecialChar) {
      return '비밀번호는 최소 1개 이상의 특수문자를 포함해야 합니다';
    }
    
    return null;
  }

  // Password confirmation validation
  static String? validatePasswordConfirm(String? value, String password) {
    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요';
    }
    
    if (value != password) {
      return '비밀번호가 일치하지 않습니다';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return '이름을 입력해주세요';
    }
    
    if (value.length < 2) {
      return '이름은, 최소 2자 이상이어야 합니다';
    }
    
    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return '연락처를 입력해주세요';
    }
    
    final phoneRegExp = RegExp(r'^010-?[0-9]{4}-?[0-9]{4}$');
    
    if (!phoneRegExp.hasMatch(value)) {
      return '올바른 전화번호 형식이 아닙니다 (010-0000-0000)';
    }
    
    return null;
  }

  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return '주소를 입력해주세요';
    }
    
    return null;
  }

  // Address detail validation
  static String? validateAddressDetail(String? value) {
    if (value == null || value.isEmpty) {
      return '상세 주소를 입력해주세요';
    }
    
    return null;
  }
} 