# 🧩 Flutter 개발 환경 구성 (Windows)

이 문서는 Windows 환경에서 Flutter SDK를 설치하고 Android Studio와 연동하여 프로젝트를 생성하는 방법을 안내합니다.  
모든 과정은 공식 Flutter 문서를 기반으로 작성되었습니다. ([공식 설치 페이지](https://docs.flutter.dev/get-started/install/windows))

---

## ⚙️ 1. Flutter SDK 설치

잠깐. JDK는 17권장합니다 그 이상은 호환 잘 안됨

1. [Flutter 공식 설치 페이지](https://docs.flutter.dev/get-started/install/windows)에서 최신 버전의 `flutter_windows_[버전]-stable.zip` 파일을 다운로드합니다.  
2. 압축을 원하는 폴더(예: `C:\src\flutter`)에 풉니다.  
   > ⚠️ **주의:** `C:\Program Files` 폴더는 관리자 권한 문제로 피하세요.

---

## 🧭 2. 환경 변수(Path) 등록

1. Windows 검색창에 **"환경 변수"** 입력 → **"시스템 환경 변수 편집"** 클릭  
2. **"환경 변수"** 버튼 클릭 → "사용자 변수" 항목에서 **Path** 선택 후 **"편집"** 클릭  
3. **"새로 만들기"** 클릭 → 다음 경로 추가 후 **확인**
C:\src\flutter\bin
4. 모든 창을 닫고, 새 명령 프롬프트(cmd)를 열어 아래 명령어로 설정 확인:
flutter --version

---

## 💡 3. Android Studio 설치 및 설정

1. [Android Studio 공식 사이트](https://developer.android.com/studio)에서 설치 파일을 내려받아 실행  
2. 설치 중 **"Android Virtual Device"**도 함께 체크하여 설치  
3. 실행 후 상단 메뉴에서:  
- **File → Settings → Plugins**  
- `Flutter`, `Dart` 플러그인 검색 및 설치 → **Android Studio 재시작**
4. **Settings → Appearance & Behavior → System Settings → Android SDK** →  
**SDK Tools 탭 → "Android SDK Command-line Tools" 체크 후 설치**

> 💬 **팁:** SDK 경로는 기본적으로 `C:\Users\<사용자명>\AppData\Local\Android\Sdk`에 설치됩니다.  
> Flutter가 해당 경로를 자동으로 인식하지 못할 경우,  
> 명령어로 수동 설정할 수 있습니다:
> ```
> flutter config --android-sdk <SDK 경로>
> ```

---

## 🩺 4. Flutter Doctor로 환경 점검

1. 명령 프롬프트(cmd)에서 다음 명령 실행:
flutter doctor
2. 출력되는 항목 중 **모두 초록색 체크(✓)** 표시가 되면 정상 설치 완료입니다.  
3. 만약 빨간색(X) 또는 느낌표(!)가 나타나면 안내에 따라 추가 설치나 동의를 진행하세요.  
4. Android 라이선스 동의 필요 시:
flutter doctor --android-licenses
- 모든 항목에 대해 `y` 입력하여 동의합니다.

---

## 🚀 5. 새 Flutter 프로젝트 생성

### Android Studio에서
1. **"New Flutter Project"** 클릭  
2. Flutter SDK 경로: 압축 해제한 `C:\src\flutter` 지정  
3. 프로젝트 이름과 저장 경로 입력 후 **Finish** 클릭  

### 명령어로 생성하고 싶다면 다음 명령어 사용
flutter create my_app
cd my_app
flutter run

---

## 🧠 추가 팁

- **Visual Studio Code** 사용 시: Flutter & Dart 확장 설치 후 바로 실행 가능  
- Flutter 최신 버전으로 업데이트:
flutter upgrade
- 의존성 패키지 설치 및 갱신:
flutter pub get
- 자세한 환경 점검을 위해:
flutter doctor -v
- Flutter를 권한 문제 없이 설치하려면,  
`C:\Program Files`가 아닌 권한이 낮은 디렉터리를 사용하세요.  
- Android SDK 인식 문제 발생 시 아래 명령어로 SDK 경로를 명시적으로 설정 가능:
flutter config --android-sdk <SDK 경로>
---

이제 준비 끝. 레지고

> 작성일: 2025-10-23
> 업데이트 기준: Flutter stable 최신 버전 (공식 문서 기준)

