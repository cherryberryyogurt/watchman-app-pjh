# 1. 완전 클린
flutter clean

flutter pub cache clean

flutter pub get



cd ios
rm -rf Pods Podfile.lock .symlinks

# 2. Firebase iOS SDK 버전 고정

pod install
cd ..

flutter clean

flutter doctor

flutter analyze

dart run build_runner build --delete-conflicting-outputs # g.dart 파일 생성하는 코드

flutter run -d 00008120-001C49563EC3A01E

# # 1. Flutter 프로젝트 클린
# flutter clean

# # 2. iOS 폴더의 Pod 관련 파일 및 Xcode 빌드 캐시 삭제
# cd ios
# rm -rf Pods Podfile.lock ~/Library/Developer/Xcode/DerivedData/
# pod deintegrate

# # 3. Pod 재설치
# flutter pub get
# pod install --repo-update
# cd ..

# # 4. Flutter 패키지 다시 가져오기

# # 5. 빌드 시도
# flutter run
