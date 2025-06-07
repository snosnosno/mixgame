# PL OMAHA 연습

PL OMAHA 학습을 위한 두 가지 게임을 제공하는 Flutter 웹 애플리케이션입니다.

## 게임 소개

### 1. 승자 맞추기 게임
- 2-6명의 플레이어 중에서 실제 승자를 맞추는 게임
- PLO(Pot Limit Omaha) 규칙 적용
- 60초 제한 시간
- 정확도와 하이스코어 기록

### 2. Pot Limit 계산 게임
- 2-6명의 플레이어가 참여
- 랜덤 SB/BB 설정
- 실시간 액션 표시 (레이즈, 폴드, 콜)
- 60초 제한 시간
- POT! 외치면 정확한 팟 금액 계산

## 주요 기능
- 플레이어 수 선택 (2-6명)
- 실시간 타이머
- 점수 시스템
- 정확도 추적
- 하이스코어 기록

## 기술 스택
- Flutter
- Dart
- GitHub Pages

## 온라인 플레이
[여기](https://snosnosno.github.io/PLO_Practice)에서 게임을 플레이할 수 있습니다.

## 개발 환경 설정
1. Flutter SDK 설치
2. 저장소 클론
```bash
git clone https://github.com/snosnosno/PLO_Practice.git
```
3. 의존성 설치
```bash
flutter pub get
```
4. 실행
```bash
flutter run -d chrome
```
