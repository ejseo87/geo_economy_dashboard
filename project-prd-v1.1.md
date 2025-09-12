# PRD for Claude Code Input (Geo Economy Dashboard)

version 1.1

# 1. 프로젝트 개요

- **프로젝트 이름**: OECD 38개국 경제지표 (가칭)
- **프로젝트 배경 및 필요성**:
  - 한국의 경제지표를 OECD 38개국과 비교하여 사용자가 한국의 현 상황을 쉽게 이해할 수 있게 함
  - 경제지표를 친숙하게 제공하여 데이터 리터러시 강화
  - "우물 안 개구리"식 사고를 넘어 글로벌 시각 확보
- **목표**:
  - OECD 38개국의 20개 핵심 지표를 국가별, 지표별로 시각화
  - 국가별 경제상황 요약
  - 지표별 정의·해석과 국가 간 비교
  - 지표 갱신 시 자동 업데이트
  - 사용자 피드백 수용 및 개선 반영
- **결과물**:
  - iOS 앱
  - Android 앱
  - Chrome 웹
- **타깃 사용자** : 공공데이터 관심 사용자, 교사/학생, 언론인, 정책·리서치 보조 인력
- **사용자 욕구** :
  - “한국이 OECD에서 어느 위치인지”를 10초 안에 확인
  - 1분 안에 1~2개 지표 비교 및 공유 가능한 차트/이미지 획득

# 2. 서비스 범위

## 2.1 **데이터 소스**

- World Bank Indicators API(https://api.worldbank.org/v2) : 주요 16,000 지표 중 20개 선정
- 필요 시 OECD 및 각국 중앙은행 데이터 병행

## 2.2 **핵심 기능**

1. 로그인/가입 없이 바로 접근 가능한 홈 화면
   - 홈화면에 10초–1분–5분 규칙을 적용
   - 홈 화면은 상단에 3개의 탭을 갖는 탭바가 있다.
   - 홈 화면은 사용자가 선택한 국가(미 선택 시 한국)에 대한를 보여준다.
   - 첫번째 탭 : 10초, 국가 요약 카드, Top 5 지표
   - 두번째 탭 : 1분, 아래의 두 가지 방식으로 비교
     - 방식1 : 선택된 국가 vs 비교국(사용자가 선택할 수 있어야 하고 기본은 미국)과의 모든 지표 비교.
     - 방식2 : 사용자가 특정 지표를 선택하면 해당 지표에 대한 모든 국가 비교
   - 세번째 탭 : 10분, 선택한 국가의 핵심 20 지표 + QoQ/YoY 변화 화살표.
2. 국가별 경제 상세 화면 (20개 지표 카드, 스파크라인)
3. 지표별 상세 화면 : 국가 비교 (랭킹, OECD 평균 vs 선택한 국가)
4. 검색 및 필터 기능 (국가, 지표, 기간)
5. 데이터 자동 갱신 (World Bank API 연동)
6. 공유 기능 (이미지, csv, 링크)
7. 로그인한 사용자가 admin인 경우에는 관리자 모드 실행
8. 오프라인 캐시(최근 본 나라/지표) : 지하철, 비행기에서도 확인 가능
9. 다국어 : 한국어, 영어 (ko/en)
10. 접근성 : 폰트 크기, 색맹 팔레트

# 3. 사용자 시나리오

1. 앱 실행하면 바로 홈 화면 접속
2. 원하면 가입, 로그인 할 수 있도록 홈 화면에 우상단에 로그인 아이콘 표시
3. 홈 화면의 좌상단에 국가를 선택할 수 있는 아이콘 표시
4. 홈화면에서 선택한 국가의 현 상황을 파악
5. 현재 보고 있는 이미지, 링크를 북마크로 저장할 수 있다. 단 로그인해야 한다
6. 현재 보고 있는 이미지를 png, jpeg 형식으로 내려 받기할 수 있다. 단 로그인해야만 한다.
7. 지표이름과 국가이름으로 검색할 수 있다.

# 4. 데이터 수집 및 저장

## 4.1 데이터 수집 및 저장 개요

- OECD 38개국 주요 경제지표를 World Bank API에서 수집하여 Firebase Firestore에 다음과 같이 저장한다.

### 4.1.1 원본(정규화) : 지표 중심

- /indicators/{indicatorCode}/series/{countryCode}
- 지표별로 모든 국가의 시계열을 보관하여 국가간 비교에 사용한다.
- 시계열 데이터, 단위, 최신값
- 시계열 데이터는 year, value로 이루어진 map의 list로 저장한다.

### 4.1.2 조회 가속 뷰(비정규화): 국가 중심

- /countries/{countryCode}/indicators/{indicatorCode}
- 국가별 대시보시 카드 렌더링을 빠르게 하기 위해 사용한다.
- 한 국가의 여러 지표를 한 번에 조회하여 화면에 표시하기 위해 사용한다
- 최신값, 최근 10년 데이터, OECD 내 랭킹

### 4.1.3 동기화 전략

Phase 1. **앱에서 이중 쓰기(간단)**

- World Bank에서 끌어올 때 `/indicators/...`에 쓰고, 바로 `/countries/...`에도 써줌.
- 장점: 구현 쉬움. 단점: 실패 시 불일치 가능 → 배치 쓰기/재시도 권장.
  Phase 2. **Cloud Functions (권장)**
- 트리거: `/indicators/{indicatorId}/series/{iso3}` onCreate/onUpdate
- 작업: 해당 값으로 `/countries/{iso3}/indicators/{indicatorId}` 갱신 + 랭킹 계산 시 반영.
- 장점: 일관성↑, 클라이언트 단순화.

### 4.1.4 수집 원칙

- 최신년도는 현재년도(예, 2025년)의 직전년도(예, 2024년)을 기준으로 하되, 직전년도의 데이터가 worldbank에 없다면 2년 전(예, 2023년)의 데이터를 가져온다.
  또한 가져온 데이터의 년도를 화면에 뱃지로 표시해주어야 한다.

## 4.2 Local caching

- sqllite DB를 사용
- ios/android 앱 내부에 캐싱
- 앱 조회 순서 : sqllite → Firestore → World Bank API
- 중복 제거 및 자동 삭제 정책 → 항상 최신 데이터 유지

## 4.3 데이터 조회 우선순위

1. sqllite Database (앱 local cache)
2. Firebase Firestore
3. World Bank API

## 4.4. 데이터 설계(초판 기준)

- **핵심 20지표 추천(예시)**  
   GDP per capita(PPP), 실업률, 물가상승률, 정부부채/GDP, 경상수지/GDP, 출산율, 기대수명, 교육지출/GDP, R&D지출/GDP, CO₂/인구, 에너지소비/인구, 재생에너지 비중, 빈곤율(가능시), 노동참여율, 청년실업률, 가계부채/처분가능소득(대체지표 가능), 교역의존도, 정부지출/GDP, 제조업 부가가치 비중, 인터넷 보급률.  
   → 각 지표에 `indicator_id`, 단위, 변환(원시→PPP/인구당), 최신연도, 업데이트주기 메타를 붙여 **정의/출처/갱신일 툴팁** 자동 생성.
- **집계 규칙:** OECD **미디안·IQR** 사전 계산(앱 최초 실행 시 캐시) → 비교 표시 즉시 응답.

# 5. 관리자(Admin) 기능

## 5.1 Admin 유저 권한

- 로그인한 사용자 role이 admin이면 관리자 모드로 진입한다.
- 관리자 모드는 4개의 탭으로 구성된 대시보드:
  1.  Overview: 시스템 현황 및 통계
  2.  Data Collection: World Bank API 데이터 수집
  3.  Data Management: Firestore 감사 및 정리
  4.  Settings: 관리자 계정 관리, 관리자 모든 나가기

## 5.2 Adming 기능

### 5.2.1 최신 데이터 수집 (World Bank API)

- OECD 38개국 20개 핵심 지표 자동 수집
- 배치 처리 및 진행률 추적
- API 호출 제한 및 재시도 로직
- Firestore 저장 및 기존 데이터 overwrite

### 5.2.2 Firestore 데이터 중복 Audit

- 전체 컬렉션 스캔 및 중복 탐지
- 데이터 정합성 검사
- 고아 문서 식별
- 상세한 감사 리포트 생성

### 5.2.3 중복/오래된 데이터 삭제

- 2년 이상 오래된 데이터 정리
- 중복 문서 자동 제거 (최신 버전 보존)
- 배치 삭제 작업으로 성능 최적화
- 안전한 삭제 확인 절차

### 5.2.4 World Bank DB 신규 데이터 체크

- 각 지표별, 국가별 데이터의 최신값의 년도와 worldbank api의 데이터의 최신값의 년도의 비교표를 작성하고 두 데이터의 최신값의 년도가 다르면 데이터 수집 버튼을 활성화한다.
- 활성화된 데이터 수집 버튼을 누르면, 해당 지표-국가의 최신데이터를 수집하여 firebase firestore에 저장한다.

# 6. 가입자 관리

## 6.1 가입

- 가입하려는 사용자의 이메일은 다른 사용자와 중복되어서는 안된다.

## 6.2 사용자의 프로필 관리

- 설정화면에서 로그인 사용자의 프로필을 변경할 수 있게 한다.
- 이메일은 변경할 수 없다.
- 아바타를 변경할 수 있다. 초기 아바타는 null이다. 아바타 이미지는 firebase storage에 저장한다.
- 사용자 nickname을 변경할 수 있다. 초기 nickname은 anon이다.

## 6.3 사용자 비밀번호 변경 기능

- 로그인한 사용자는 자신의 비밀번호 변경할 수 있다.

## 6.4 관리자 권한을 가진 유저 식별 방법

- 사용자의 role이 admin이면 관리자이다

# 7. 성공 요인

- 직관적인 시각화 (스파크라인, 지표별로 정확한 순위를 표시하는 랭킹)
- **카드 공유·한 줄 요약**
  - 기자/교사/창작자가 _즉시 써먹을_ 포맷 제공
  - 한 줄 요약은 인공지능으로 생성할 예정
- 자동화된 데이터 동기화 및 갱신
- **오프라인 캐시 & 알림**: 반복 사용 끌어올리는 트리거.
- 최소한의 사용자 진입 장벽 (무가입/무료 시작)
- 신뢰성 있는 데이터 소스 (World Bank, OECD)

# 8. 사용자 시나리오

1. 앱 실행하면 바로 홈 화면 접속
2. 원하면 가입, 로그인 할 수 있도록 홈 화면에 우상단에 로그인 아이콘 표시
3. 홈 화면의 좌상단에 국가를 선택할 수 있는 아이콘 표시
4. 홈화면에서 선택한 국가의 현 상황을 파악
5. 현재 보고 있는 이미지, 링크를 북마크로 저장할 수 있다. 단 로그인해야 한다
6. 현재 보고 있는 이미지를 png, jpeg 형식으로 내려 받기할 수 있다. 단 로그인해야만 한다
7. 지표이름과 국가이름으로 검색

# 9. 비기능 요구사항

- 플랫폼: Flutter (iOS, Android), 웹 확장 가능
- 백엔드: Firebase cloud store, storage, authentication
- 성능: 응답 시간 < 2초
- 보안: HTTPS 필수, 사용자 데이터 암호화

# 10. 지표 (Success Metrics)

- **활성화:** 첫 세션에 **즐겨찾기 1개 이상 + 카드 공유 1회** 비율 ≥ 30%.
- **핵심행동:** “국가 요약→지표 상세→비교 저장” 퍼널 전환 ≥ 25%
- **리텐션(D7):** ≥ 15% (알림/공유가 있으면 20%+도 가능).
- **실험 예시(A/B):**
  1. 첫 화면: “한국 요약” vs “지표 검색” 시작.
  2. 비교 기본값: 미디안만 vs 미디안+IQR 배경.
  3. 알림 CTA 위치: 상세 상단 vs 하단.

# 11.과금/성장(선택)

- **무료:** 핵심 20지표, 카드 공유, 즐겨찾기 5개, 알림 2개.
- **프로(월 2,000~3,000원):** 커스텀 지표팩, 즐겨찾기 무제한, 알림 무제한, CSV/PNG 고해상도.

# 12. 향후 확장 계획

- OECD 외 신흥국 그룹(브릭스, 아세안 등) 추가
- 기관/학교 단체용 라이선스
- 웹 대시보드

# 첨부1. UI/UX Requirements

- **10s–1min–5min Rule**:
  - 10s: Country summary card (Top 5 indicators, badges, colors)
  - 1min: Compare selected indicators vs OECD median (±IQR) + 3 similar countries
  - 5min: Detailed view with 20 core indicators
- **Colors/Badges**:
  - Positive indicators ↑: Blue
  - Negative indicators ↑: Red/Orange
  - Neutral: Purple/Teal
  - Missing data: Gray
- **Accessibility**:
  - Font scaling, color-blind palette, WCAG contrast
- **Usability**:
  - Swipe/tab gestures, long-press for favorites, tooltips with indicator definitions
- **Feedback**:
  - Loading spinners, friendly error messages
- **Sharing**:
  - Export cards/charts as PNG/JPEG, share links, save bookmarks
- **UI Style Guide**:
  - Color: Primary #0055A4, Accent #00A86B, Warning #FFD700, Background #F5F5F5, Text Primary #222222, Text Secondary #666666.
  - Font: Noto Sans KR(한글), Roboto(영문·숫자).
  - Button: rounded corner 8px, Primary(background Primary Color/Text White), Secondary(Border Primary Color/Background White).
  - Card: shadow 2dp, corner 12px, padding 16px.

# 첨부2. screen design guideline

- 첨부2-1 plash / Intro
  - background : blue(#0055A4) gradient
  - logo: assets/images/logo.png
  - text: App name, slogan
  - animation: fade in → home screen
- 첨부2-2 login / join
  - input fields: email, password
  - button: login(Primary), join(Secondary)
  - SNS login: Google, Apple, kakaotalk, github
  - guest mode: link in the bottom
- 첨부2-3 home(dashboard)
  - appbar: globe icon with dropdown menu to select counties, setting icon and app name
  - tab bar navigation on the top of home screen
  - 첫번째 탭 : 10초, 국가 요약 카드, Top 5 지표
  - 두번째 탭 : 1분, 아래의 두 가지 방식으로 비교
    - 방식1 : 선택된 국가 vs 비교국(사용자가 선택할 수 있어야 하고 기본은 미국)과의 모든 지표 비교.
    - 방식2 : 사용자가 특정 지표를 선택하면 해당 지표에 대한 모든 국가 비교
  - 세번째 탭 : 10분, 선택한 국가의 핵심 20 지표 + QoQ/YoY 변화 화살표.
  - chart preview: 선택 지표 최근 5년 추이
  - bottom navagation bar : home, search, favorates(bookmarks), settings
- 첨부2-4 search
  - appbar : search field(country name or keyword of Indicators )
  - recommanded tags like GDP, unemployment rate, etc.
  - result list : a list of country name with flag or indicator with gesture detector to go the detail view screen
- 첨부2-5 a detail view of country
  - header : country name with flag and the updated date
  - the fist section is the summary cards just same like the first tab of home
  - the second section is line charts of country summary cards during for the last 10 years
  - the third section is bar charts of the summary cards to compare between OECD average and the selected country
  - the last section is the others indicators button grid
- 첨부2-6 a detail view of indicator
  - header : indicator name with unit and the updated date
  - description : the meaning of indicator with worldbank link of the indicator
  - ranking by country : a bar chart
  - the selected country trends: line chart

# 첨부3. 핵심 20지표 세트 (OECD 비교 친화 + 세계은행 API 가용성 중심)

> 원칙: WB Indicators API로 안정적으로 가져올 수 있고, 갱신 주기가 비교적 분명하며, OECD 38개국 간 비교의 핵심 문답(성장·물가·고용·재정·대외·분배·환경·인구/사회)을 커버.

#### 성장/활동

1. 실질 GDP 성장률(연%) – `NY.GDP.MKTP.KD.ZG`
2. 1인당 GDP(PPP, 현재국제달러) – `NY.GDP.PCAP.PP.CD`
3. 산업부가가치 비중(제조업, %GDP) – `NV.IND.MANF.ZS`
4. 고정자본형성(총고정자본형성, %GDP) – `NE.GDI.FPRV.ZS`

#### 물가/통화

5. CPI 인플레이션(연%) – `FP.CPI.TOTL.ZG`
6. M2(통화+준통화, %GDP) – `FM.LBL.MQMY.GD.ZS` (대체 가능 지표. 필요시 제외/교체)

#### 고용/노동

7. 실업률(ILO, %) – `SL.UEM.TOTL.ZS
8. 노동참가율(총, %) – `SL.TLF.CACT.ZS
9. 고용률(15+, %) – `SL.EMP.TOTL.SP.ZS

#### 재정/정부

10. 일반정부 최종소비지출(%GDP) – `NE.CON.GOVT.ZS`
11. 조세수입(%GDP) – `GC.TAX.TOTL.GD.ZS`
12. 정부부채(중앙정부, %GDP) – `GC.DOD.TOTL.GD.ZS` (국가별 가용성 확인 필요)

#### 대외/거시건전성

13. 경상수지(%GDP) – `BN.CAB.XOKA.GD.ZS`
14. 상품·서비스 수출액(%GDP) – `NE.EXP.GNFS.ZS`
15. 상품·서비스 수입액(%GDP) – `NE.IMP.GNFS.ZS`
16. 외환보유액(개월수입대비, 월) – `FI.RES.TOTL.MO`

#### 분배/사회

17. 지니계수 – `SI.POV.GINI`
18. 빈곤율(국가기준, %) – `SI.POV.NAHC` (대체로 최신치 커버리지 편차 有 → 보조지표로 설정)

#### 환경/에너지

19. CO₂ 배출(1인당, t) – `EN.ATM.CO2E.PC`
20. 재생에너지 비중(최종에너지소비 중, %) – `EG.FEC.RNEW.ZS`

> 비고
>
> - 일부 국가는 10·11·12·18 같은 재정/분배 지표의 공란이 발생할 수 있으니 **결측 허용 전략**(fallback/숨김/보조지표로 대체)을 같이 설계.
> - OECD 38 필터는 앱 레벨에서 국가 리스트를 고정(ISO2/ISO3)하고, 동일 지표를 OECD 세트에만 랭킹/백분위 집계.

# 첨부4. 색상/배지 규칙

#### 색상(의미 일관성)

- **긍정적(상승=좋음)**: 성장률, 경상수지, 1인당 GDP, 고용률, 노동참가율, 재생에너지 비중 → **파랑 계열**
- **부정적(상승=나쁨)**: 인플레이션, 실업률, 정부부채, CO₂, 빈곤율 → **주황/빨강 계열**
- **중립(양면)**: 수출/수입 비중, 정부지출 비중, 제조업 비중, 고정자본형성 → **보라/청록 중성계열**
- **결측/확신낮음**: 회색

> 색상 팔레트 예시
>
> - Positive: `#1E88E5`(기본), `#90CAF9`(연한), `#0D47A1`(강조)
> - Negative: `#E53935`/`#FF7043`
> - Neutral: `#26A69A`/`#7E57C2`
> - Missing: `#BDBDBD`

#### 배지(Badge) 규칙

- **TrendBadge**: 전년 대비(연간)/전월 대비(월간) 증감
  - ↑ 파랑(긍정), ↑ 빨강(부정) — 지표의 “좋음/나쁨” 정의에 따라 색 반전
  - ↓ 파랑/빨강 동일 원칙
- **PercentileBadge (OECD)**:
  - 상위 10%: 금색 테두리 + “Top 10%” + 검은색 글씨
  - 상위 25%: 파랑 테두리 + “Q1”
  - 하위 25%: 빨강 테두리 + “Q4”
  - 나머지: 회색 테두리 + “Q2~Q3”
- **FreshnessBadge**:
  - 최신치가 12개월 이내: “Up to date” (파랑)
  - 12~24개월: “Stale” (주황)
  - 24개월+: “Outdated” (빨강)
- **AnomalyBadge(옵션)**:
  - 표준편차 2σ 이상 급변: ⚠︎ 노란 배지(툴팁에 변화율/기저연도 표기)
