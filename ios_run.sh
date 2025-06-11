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
