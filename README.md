# Flutter 개발 환경 세팅 가이드 (Windows)

Flutter로 앱 개발을 시작하려면 아래 순서대로 환경을 세팅하세요.

---

## 1. Flutter SDK 설치
1. [Flutter 공식 설치 페이지](https://flutter.dev/docs/get-started/install/windows)에서 최신 버전의 `flutter_windows_[버전]-stable.zip` 파일 다운로드
2. 원하는 폴더에 압축 해제 (예: `C:\src\flutter`)  
   ⚠️ 권한 문제로 `C:\Program Files`는 피하세요.

---

## 2. 환경 변수(Path) 등록
1. 윈도우 검색창에서 **환경 변수** → **시스템 환경 변수 편집** 클릭
2. **환경 변수** 버튼 클릭 → **사용자 변수**에서 `Path` 선택 후 **편집**
3. **새로 만들기** → `C:\src\flutter\bin` 추가 → 확인

---

## 3. Android Studio 설치 및 세팅
1. [Android Studio 공식 사이트](https://developer.android.com/studio)에서 설치 파일 다운로드 후 설치
2. 설치 중 **Android Virtual Device (AVD)**도 함께 설치
3. 설치 후 Android Studio 실행 → **Plugins**에서 **Flutter**와 **Dart** 플러그인 설치 → 재시작
4. **More Actions → SDK Manager → SDK Tools**에서 **Command-line Tools** 체크 후 설치

---

## 4. Flutter 환경 점검
1. 명령 프롬프트(cmd) 실행 후:  
   ```bash
   flutter doctor
