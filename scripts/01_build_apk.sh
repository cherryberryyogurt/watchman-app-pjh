# 빌드 환경 확인
flutter doctor

# 진행할건지 물어보기
read -p "빌드를 진행하시겠습니까? (y/n): " answer
if [ "$answer" != "y" ]; then
    echo "빌드를 취소합니다."
    exit 1
fi

# apk 빌드 (release가 더 가벼움)
flutter build apk --debug
# flutter build apk --release

# 빌드 파일 위치
# android/app/build/outputs/apk/debug/app-debug.apk
# android/app/build/outputs/apk/release/app-release.apk

# USB로 연결된 디바이스에 설치
# flutter install -d <device_id>

# 또는 adb로 직접 설치
# adb install -r build/app/outputs/flutter-apk/app-release.apk
adb install -r build/app/outputs/flutter-apk/app-debug.apk