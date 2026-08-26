# Vueshines LMS Practice — Implementation Plan

## 0. 목적

이 프로젝트는 Vue 3 프론트엔드와 Kotlin/Spring Boot 백엔드를 연결하여
전형적인 온라인 교육 서비스(LMS)의 핵심 데이터 흐름을 구현하는 실습 프로젝트다.

목표는 기능이 많은 서비스를 만드는 것이 아니다.

다음 흐름을 실제 코드로 끝까지 관통하여 이해하는 것이 핵심이다.

Vue 3
→ REST API
→ Spring Boot / Kotlin
→ Redis
→ MySQL

특히 다음 기술을 실제 사용 맥락에서 확인한다.

- Vue 3
- TypeScript
- Vue Router
- Pinia
- Vite
- Kotlin
- Spring Boot
- REST API
- MySQL
- Redis
- Docker Compose

동영상 스트리밍 자체는 구현하지 않는다.

실제 동영상 플레이어 대신
`Video Playback Simulator`를 만들어 재생 시간과 진도 이벤트를 발생시킨다.

다만 이 앱이 나중에 실제 동영상 파일을 다루게 될 경우의 목표 구조는
미리 분명히 해 둔다.

- 동영상 파일 또는 동영상 접근 정보는 backend가 관리한다.
- 사용자는 Vue에서 강의를 선택하고, Spring Boot가 제공하는 lecture video endpoint를 통해 동영상을 제공받는다.
- 시청 중 발생하는 progress event는 먼저 Redis에 저장한다.
- Redis에 쌓인 progress는 적당한 시점에 MySQL progress table로 옮겨 영속화한다.

현재 구현 단계에서는 실제 동영상 파일 제공 대신 simulator를 사용하되,
진도 처리 구조는 실제 동영상 플레이어로 바꿔도 유지될 수 있게 설계한다.

---

# 1. 가장 중요한 개발 원칙

## 1.1 과도하게 확장하지 않는다

이 프로젝트는 학습용 작은 LMS이다.

다음 기술은 추가하지 않는다.

- Kafka
- RabbitMQ
- Kubernetes
- Elasticsearch
- Neo4j
- MongoDB
- WebSocket
- GraphQL
- Microservices
- AI / LLM / RAG
- 실제 video streaming server
- 실제 payment gateway
- 복잡한 인증 시스템

필요하지 않은 infrastructure를 추가하지 않는다.

---

## 1.2 문제를 먼저 구현한다

기술을 사용하기 위해 기능을 만들지 않는다.

예:

Redis를 사용하기 위해 아무 데이터나 Redis에 저장하지 않는다.

Redis는 다음과 같이 실제 이유가 있는 곳에서만 사용한다.

1. Course 조회 cache
2. Video progress의 빈번한 update buffering

---

## 1.3 Frontend와 Backend의 경계를 명확하게 유지한다

Frontend:

- 화면
- 사용자 interaction
- local UI state
- shared client state
- REST API 호출

Backend:

- business rule
- validation
- persistence
- transaction
- cache
- progress processing

Frontend에서 DB에 직접 접근하지 않는다.

---

# 2. Repository Structure

현재 Vue 프로젝트가 repository root에 이미 존재한다고 가정한다.

다음 구조를 사용한다.

vueshines/
├── src/                     # Vue 3 frontend
│   ├── components/
│   ├── views/
│   ├── router/
│   ├── stores/
│   ├── services/
│   ├── types/
│   ├── App.vue
│   └── main.ts
│
├── backend/
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   └── src/
│       ├── main/
│       │   ├── kotlin/
│       │   └── resources/
│       └── test/
│
├── compose.yaml
├── README.md
└── IMPLEMENTATION_PLAN.md

Frontend와 Backend를 별도 repository로 분리하지 않는다.

이 프로젝트는 하나의 monorepo 형태로 유지한다.

---

# 3. Runtime Architecture

전체 구조:

Browser
   │
   ▼
Vue 3
localhost:5173
   │
   │ REST / JSON
   ▼
Spring Boot
localhost:8080
   │
   ├───────────────┐
   │               │
   ▼               ▼
Redis             MySQL
:6379             :3306

개발환경에서는 Docker Compose로 전체 runtime을 한 번에 실행한다.

- Vue: frontend container
- Spring Boot: backend container
- MySQL: mysql container
- Redis: redis container

각 역할은 하나의 container에만 둔다.

- frontend container는 Vue/Vite 개발 서버를 실행한다.
- backend container는 Spring Boot 애플리케이션을 실행한다.
- mysql container는 영속 데이터 저장소만 담당한다.
- redis container는 cache와 progress buffer만 담당한다.

Compose 내부 통신에서는 service name을 사용한다.

- backend → mysql: `mysql:3306`
- backend → redis: `redis:6379`
- frontend → backend: browser 기준으로는 `http://localhost:8080`, container 내부 기준으로는 `http://backend:8080`

개발 편의를 위해 frontend와 backend source directory는 bind mount할 수 있다.
단, node_modules나 Gradle cache처럼 container 내부에서 관리해야 하는 디렉터리는 별도 volume을 사용한다.

실제 동영상 제공 단계로 확장할 때도 browser가 동영상 저장소에 직접 접근하는 구조를 기본값으로 삼지 않는다.
Vue는 Spring Boot의 lecture video API를 호출하고,
Spring Boot가 파일 경로, 접근 권한, range request, content type 같은 제공 책임을 갖는다.
이 프로젝트의 1차 목표에서는 이 책임을 문서화만 하고,
실제 video streaming server나 별도 media service는 만들지 않는다.

---

# 4. Domain Model

최소 domain만 구현한다.

## User

필드 예시:

- id
- email
- name
- createdAt

---

## Course

필드 예시:

- id
- title
- description
- instructor
- createdAt

---

## Lecture

필드 예시:

- id
- courseId
- title
- durationSeconds
- sequence

1차 구현에서는 실제 video file을 저장하지 않는다.

실제 동영상 제공 단계로 확장할 경우 Lecture에는 다음과 같은 backend 관리용 필드를 추가할 수 있다.

- videoStorageKey
- videoContentType
- videoByteSize
- videoDurationSeconds

이 필드는 frontend가 임의로 조합하는 값이 아니라
backend가 저장 위치와 제공 정책을 해석하기 위한 값이다.

---

## Enrollment

사용자가 어떤 Course를 수강하는지 나타낸다.

필드 예시:

- id
- userId
- courseId
- enrolledAt

---

## Progress

사용자가 Lecture를 어디까지 시청했는지 나타낸다.

필드 예시:

- id
- userId
- lectureId
- watchedSeconds
- completed
- updatedAt

---

# 5. MySQL Schema

최소 다음 table을 만든다.

users

courses

lectures

enrollments

progress

관계:

User
  │
  └── Enrollment
          │
          └── Course
                 │
                 └── Lecture

User
  │
  └── Progress
          │
          └── Lecture

외래키와 unique constraint를 적절히 사용한다.

예:

한 사용자가 동일 Course를 중복 수강신청할 수 없도록 한다.

UNIQUE(user_id, course_id)

Progress도:

UNIQUE(user_id, lecture_id)

를 사용한다.

---

# 6. Backend Technology

Backend:

- Kotlin
- Spring Boot
- Spring Web
- Spring Data JPA
- MySQL Driver
- Spring Data Redis
- Validation

가능하면 현재 안정 버전을 사용한다.

Java version은 현재 로컬 환경과 호환되는 LTS를 사용한다.

불필요한 dependency를 추가하지 않는다.

---

# 7. Backend Package Structure

예:

com.vueshines.lms

├── course
│   ├── Course.kt
│   ├── CourseRepository.kt
│   ├── CourseService.kt
│   └── CourseController.kt
│
├── lecture
│
├── enrollment
│
├── progress
│
├── user
│
├── common
│
└── config

거대한 추상화 framework를 만들지 않는다.

Domain별 package 구조를 우선한다.

---

# 8. API

최소 API만 구현한다.

## Course

GET /api/courses

GET /api/courses/{courseId}

---

## Enrollment

POST /api/enrollments

Request:

{
  "userId": 1,
  "courseId": 1
}

GET /api/users/{userId}/enrollments

---

## Lecture

GET /api/courses/{courseId}/lectures

GET /api/lectures/{lectureId}

실제 동영상 제공 단계에서 추가할 수 있는 API:

GET /api/lectures/{lectureId}/video

이 API는 backend가 관리하는 동영상 파일을 사용자에게 제공한다.
초기에는 simulator를 사용하므로 이 endpoint를 구현하지 않는다.
나중에 구현할 때는 HTTP range request, content type, 접근 권한,
파일 경로 노출 방지를 함께 고려한다.

---

## Progress

PUT /api/lectures/{lectureId}/progress

Request:

{
  "userId": 1,
  "watchedSeconds": 120
}

GET /api/lectures/{lectureId}/progress?userId=1

---

# 9. Redis — Course Cache

Redis를 사용하는 첫 번째 이유는 Course 조회 cache이다.

Flow:

GET /api/courses
       │
       ▼
Redis cache 확인
       │
   ┌───┴────┐
   │        │
 HIT       MISS
   │        │
   │        ▼
   │      MySQL
   │        │
   │        ▼
   │   Redis cache 저장
   │        │
   └────┬───┘
        ▼
     Response

Cache key 예:

courses:all

course:{courseId}

TTL을 설정한다.

예:

5분

Course 데이터 변경 API를 나중에 추가한다면
관련 cache를 evict한다.

로그를 통해 반드시 다음을 확인할 수 있어야 한다.

CACHE MISS

CACHE HIT

---

# 10. Video Playback Simulator

실제 video streaming은 구현하지 않는다.

Vue에서 VideoPlaybackSimulator.vue를 만든다.

UI 예:

--------------------------------

Lecture 1
Introduction to Mathematics

Duration: 10:00

[ Play ] [ Pause ] [ Reset ]

████████████░░░░░░░░

03:24 / 10:00

--------------------------------

실제 video element를 사용할 필요는 없다.

JavaScript timer를 사용한다.

상태:

- currentSeconds
- durationSeconds
- playing

Play 클릭:

1초마다 currentSeconds 증가

Pause:

timer 중지

Reset:

0으로 초기화

이 simulator는 최종 목표가 아니다.
역할은 실제 동영상 플레이어 없이도 다음 흐름을 먼저 검증하는 것이다.

Vue lecture screen
→ 재생 시간 변화
→ progress event
→ Spring Boot
→ Redis progress buffer
→ MySQL persistence

실제 backend 저장 동영상을 제공하는 단계에서는 simulator를 HTML video element로 교체할 수 있다.
이때도 progress event API와 Redis/MySQL 저장 전략은 그대로 유지한다.

---

# 11. Progress Event

Video simulator는 일정 간격으로 backend에 progress를 전송한다.

예:

5초 또는 10초마다

PUT /api/lectures/{lectureId}/progress

{
  "userId": 1,
  "watchedSeconds": 125
}

매 1초마다 HTTP request를 보내지 않는다.

---

# 12. Redis — Progress Buffer

Video progress는 빈번하게 변경될 수 있다.

모든 update를 즉시 MySQL에 저장하지 않고
Redis를 임시 progress store로 사용한다.

Flow:

Video Simulator
      │
      │ progress event
      ▼
Spring Boot
      │
      ▼
Redis

key:

progress:{userId}:{lectureId}

value 예:

{
  "watchedSeconds": 125,
  "updatedAt": "..."
}

이 단계에서는 Redis update가 성공하면
frontend에 성공 응답을 반환할 수 있다.

---

# 13. Progress Persistence

Redis progress를 MySQL에 영속화하는 간단한 전략을 구현한다.

초기 버전에서는 지나치게 복잡하게 만들지 않는다.

다음 중 단순한 방식을 선택한다.

권장:

Spring @Scheduled job

예:

30초마다 Redis progress 데이터를 확인하고
MySQL progress table에 upsert한다.

Flow:

Redis
   │
   │ scheduled flush
   ▼
Spring
   │
   ▼
MySQL

MySQL 저장 성공 후 필요한 Redis state를 정리한다.

Flush 시점은 처음부터 정교하게 만들지 않는다.

기본 판단:

1. 정기 flush: 30초마다 Redis progress를 MySQL에 upsert한다.
2. 종료성 flush: completed = true가 되는 progress는 가능한 한 빨리 MySQL에 반영한다.
3. 보수적 조회: progress 조회 시 Redis 값이 있으면 MySQL 값보다 Redis 값을 우선 표시한다.

이렇게 하면 사용자는 최신 진도를 빠르게 볼 수 있고,
MySQL은 최종 영속 저장소 역할을 유지한다.

Redis는 임시 저장소이므로 Redis 값만 믿고 장기 상태를 판단하지 않는다.
최종 수강 이력, 완료 여부, 장애 복구 후 기준 데이터는 MySQL의 progress table을 기준으로 한다.

---

# 14. 중요한 장애 시나리오

이 프로젝트의 학습 목적상 다음을 생각하고 README에 기록한다.

## Case 1

Redis가 죽으면 progress update는 어떻게 되는가?

## Case 2

Spring Boot가 죽으면 Redis의 progress는 남아 있는가?

## Case 3

Redis container가 재시작되면 progress가 사라지는가?

## Case 4

동일 progress event가 두 번 들어오면 어떻게 되는가?

## Case 5

watchedSeconds가 현재 값보다 작은 값으로 들어오면 어떻게 할 것인가?

예:

현재:

watchedSeconds = 300

새 event:

watchedSeconds = 250

기본 정책:

MAX(current, incoming)

를 고려한다.

---

# 15. Completed Rule

Lecture completion rule을 하나 정의한다.

예:

watchedSeconds >= durationSeconds * 0.9

이면:

completed = true

이 계산은 frontend가 아니라 backend에서 한다.

Frontend는 backend가 반환한 completed 값을 표시한다.

---

# 16. Frontend Structure

예:

src/

├── components/
│   ├── CourseCard.vue
│   ├── LectureList.vue
│   └── VideoPlaybackSimulator.vue
│
├── views/
│   ├── CourseListView.vue
│   ├── CourseDetailView.vue
│   └── LectureView.vue
│
├── stores/
│   ├── course.ts
│   └── progress.ts
│
├── services/
│   └── api.ts
│
├── router/
│   └── index.ts
│
└── types/
    ├── course.ts
    └── lecture.ts

---

# 17. Vue State Rules

모든 상태를 Pinia에 넣지 않는다.

다음 기준을 따른다.

Component 내부 UI state:

ref / reactive

예:

playing
currentSeconds
dialogOpen

Parent → Child:

props

Child → Parent:

emit

여러 화면에서 공유해야 하는 상태:

Pinia

예:

course list
current user
enrollment
progress

---

# 18. Vue Router

최소 route:

/

→ CourseListView

/courses/:courseId

→ CourseDetailView

/lectures/:lectureId

→ LectureView

---

# 19. API Client

API 호출을 component 안에 무분별하게 작성하지 않는다.

src/services/api.ts

또는 domain별 service file을 사용한다.

예:

courseApi.ts

progressApi.ts

Axios가 반드시 필요한 것은 아니다.

가능하면 우선 browser fetch를 사용한다.

새 dependency를 추가하기 전에 이유가 있어야 한다.

---

# 20. CORS

개발환경:

Vue

localhost:5173

Spring Boot

localhost:8080

따라서 backend에서 개발용 CORS 설정을 구성한다.

허용 origin:

http://localhost:5173

production wildcard CORS는 사용하지 않는다.

---

# 21. Docker Compose

compose.yaml에는 다음 네 service를 둔다.

services:

  frontend:
    build:
      context: .
      dockerfile: Dockerfile.frontend
    ports:
      - "5173:5173"
    environment:
      VITE_API_BASE_URL: http://localhost:8080
    depends_on:
      - backend

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/vueshines
      SPRING_DATASOURCE_USERNAME: vueshines
      SPRING_DATASOURCE_PASSWORD: vueshines
      SPRING_DATA_REDIS_HOST: redis
      SPRING_DATA_REDIS_PORT: 6379
    depends_on:
      - mysql
      - redis

  mysql:
    image: mysql:8.4
    ports:
      - "3306:3306"
    environment:
      MYSQL_DATABASE: vueshines
      MYSQL_USER: vueshines
      MYSQL_PASSWORD: vueshines
      MYSQL_ROOT_PASSWORD: root
    volumes:
      - mysql-data:/var/lib/mysql

  redis:
    image: redis:7.4
    ports:
      - "6379:6379"

volumes:

  mysql-data:
  frontend-node-modules:
  backend-gradle-cache:

Frontend와 Backend도 container로 실행하되,
프로젝트를 Microservices 구조로 확장한다는 뜻은 아니다.

이 프로젝트는 여전히 하나의 monorepo 안에서
Vue application과 Spring Boot application을 각각 하나의 runtime container로 실행한다.

실제 구현 시 image version은 명시적으로 고정한다.

비밀번호는 학습용 local environment에 한정한다.

production credential pattern으로 오해되지 않도록 README에 명시한다.

backend는 MySQL과 Redis가 완전히 준비되기 전에 먼저 뜰 수 있으므로,
초기 연결 실패를 고려해 Spring Boot datasource retry 또는 Compose healthcheck를 단순하게 구성한다.

AWS demo 배포 스크립트는 이 단계에서 만들지 않는다.

이 단계의 Docker 작업은 local development runtime을 안정화하는 것이 목적이다.
원격 배포 파일은 Spring Boot, Vue static serving, MySQL, Redis runtime 구성이
실제로 동작한 뒤 작성한다.

---

# 22. Seed Data

개발 편의를 위해 최소 seed data를 만든다.

User:

1
student@example.local
Student

Course:

1
중등 수학 기초

Lectures:

1
수와 연산
duration 600 seconds

2
방정식
duration 900 seconds

3
함수
duration 1200 seconds

실제 교육 콘텐츠는 필요 없다.

---

# 23. UI

디자인 작업에 시간을 과도하게 사용하지 않는다.

깔끔하고 읽기 쉬운 수준이면 충분하다.

필요 화면:

## Course List

강좌 목록

## Course Detail

강좌 정보
강의 목록
수강 신청 버튼

## Lecture

강의 제목
Video Playback Simulator
현재 진도
완료 여부

---

# 24. Logging

Backend에서는 최소한 다음 로그를 확인할 수 있어야 한다.

COURSE CACHE HIT

COURSE CACHE MISS

PROGRESS RECEIVED

PROGRESS REDIS UPDATED

PROGRESS FLUSHED TO MYSQL

ENROLLMENT CREATED

에러를 숨기지 않는다.

---

# 25. Implementation Order

반드시 아래 순서로 구현한다.

## Phase 1 — Infrastructure

1. compose.yaml
2. Dockerfile.frontend
3. backend/Dockerfile
4. MySQL 실행
5. Redis 실행
6. backend container 실행
7. frontend container 실행
8. service 간 connection 확인

완료 조건:

Docker Compose로 frontend / backend / MySQL / Redis가 정상 실행된다.

다음 endpoint와 port가 host에서 확인된다.

- Vue: http://localhost:5173
- Spring Boot: http://localhost:8080/api/health
- MySQL: localhost:3306
- Redis: localhost:6379

---

## Phase 2 — Spring Boot Skeleton

1. backend 프로젝트 생성
2. Kotlin
3. Spring Web
4. JPA
5. MySQL 연결
6. Redis 연결
7. Compose 환경변수로 connection 설정

완료 조건:

GET /api/health

응답:

{
  "status": "ok"
}

---

## Phase 3 — Course

1. Course entity
2. repository
3. service
4. controller
5. seed data

완료 조건:

GET /api/courses

가 MySQL 데이터를 JSON으로 반환한다.

---

## Phase 4 — Vue Course UI

1. CourseListView
2. CourseCard
3. API 호출
4. 화면 표시

완료 조건:

Browser
→ Vue
→ Spring
→ MySQL
→ Spring
→ Vue

전체 흐름이 동작한다.

이 시점에서 반드시 첫 milestone commit을 만든다.

---

## Phase 5 — Redis Course Cache

Course 조회에 Redis cache를 추가한다.

완료 조건:

첫 요청:

CACHE MISS

두 번째 요청:

CACHE HIT

로그에서 확인된다.

---

## Phase 6 — Enrollment

수강신청 구현.

완료 조건:

Vue에서 수강신청 클릭
→ POST API
→ MySQL enrollment 저장
→ UI 반영

---

## Phase 7 — Video Simulator

VideoPlaybackSimulator.vue 구현.

완료 조건:

Play
Pause
Reset

이 동작하고 currentSeconds가 증가한다.

---

## Phase 8 — Progress Redis

Video simulator가 일정 간격으로 progress event를 전송한다.

완료 조건:

Vue
→ Spring
→ Redis

progress key가 Redis에 생성된다.

---

## Phase 9 — MySQL Progress Persistence

Scheduled flush 구현.

완료 조건:

Redis progress
→ Spring scheduled job
→ MySQL progress

흐름을 확인한다.

---

## Phase 10 — Failure Experiment

최소 다음 실험을 수행하고 README에 기록한다.

Redis 장애:

1. Redis container stop
2. progress 전송
3. 결과 관찰

Spring Boot 재시작:

1. Spring stop
2. restart
3. Redis state 확인

MySQL 장애:

1. MySQL stop
2. Redis에는 progress가 들어오는지 확인
3. MySQL 복구
4. flush 가능한지 확인

---

## Phase 11 — Backend Stored Video Extension

이 단계는 1차 LMS 흐름의 필수 구현 범위가 아니다.

실제 backend 저장 동영상을 사용자에게 제공하는 기능은
다음 조건을 먼저 만족한 뒤 진행한다.

1. Course, Lecture, Enrollment, Progress 기본 API가 동작한다.
2. Video simulator 기반 progress event가 Redis에 저장된다.
3. Redis progress가 MySQL로 flush된다.
4. 장애 실험을 통해 Redis와 MySQL의 역할 차이를 확인했다.

그 다음에 다음 항목을 작은 확장 단계로 구현한다.

1. backend가 관리하는 동영상 파일 저장 위치 결정
2. Lecture video metadata 추가
3. GET /api/lectures/{lectureId}/video 구현
4. HTTP range request 지원 여부 판단
5. Vue simulator를 실제 video element로 교체
6. video timeupdate 이벤트를 기존 progress API에 연결

판단:

Turn 1부터 Turn 14까지는 실제 동영상 파일 제공을 넣지 않는다.
실제 동영상 제공은 Turn 15 이후의 확장 작업으로 둔다.
이 순서를 지키면 video serving 문제와 progress persistence 문제를 분리해서 확인할 수 있다.

---

# 26. Turn-Based Execution Plan

실제 구현은 한 턴에 하나의 작동 가능한 단위를 끝내는 방식으로 진행한다.

너무 큰 단위로 묶으면 디버깅 범위가 흐려지고,
너무 작은 단위로 쪼개면 전체 흐름이 끊기므로
아래 턴 단위를 기본 작업 단위로 사용한다.

## Turn 1 — Docker 기반 뼈대

구현 항목:

1. compose.yaml
2. Dockerfile.frontend
3. backend/Dockerfile

완료 기준:

docker compose up으로 다음 네 container가 실행된다.

- frontend
- backend
- mysql
- redis

Spring 기능은 최소 health check 수준이면 충분하다.

---

## Turn 2 — Spring Boot Skeleton

backend/에 Kotlin Spring Boot 프로젝트를 만든다.

구현 항목:

1. GET /api/health
2. Compose 환경변수 기반 MySQL 연결 설정
3. Compose 환경변수 기반 Redis 연결 설정

완료 기준:

http://localhost:8080/api/health

응답:

{
  "status": "ok"
}

---

## Turn 3 — DB 모델과 Seed Data

구현 항목:

1. User entity
2. Course entity
3. Lecture entity
4. Enrollment entity
5. Progress entity
6. table constraint
7. 최소 seed data

완료 기준:

Spring Boot 부팅 시 MySQL에 기본 사용자, 강좌, 강의 데이터가 들어간다.

---

## Turn 4 — Course API

구현 항목:

1. GET /api/courses
2. GET /api/courses/{courseId}

이 단계에서는 Redis cache를 붙이지 않는다.
MySQL에서 바로 조회한다.

완료 기준:

curl 또는 browser에서 강좌 JSON을 확인할 수 있다.

---

## Turn 5 — Vue Course 목록 화면

기존 Vue 앱을 LMS 화면 구조로 정리한다.

구현 항목:

1. CourseListView
2. CourseCard
3. API client
4. Spring API 호출

완료 기준:

Browser
→ Vue
→ Spring
→ MySQL
→ Spring
→ Vue

흐름으로 강좌 목록이 표시된다.

---

## Turn 6 — Course 상세와 Lecture 목록

구현 항목:

1. GET /api/courses/{courseId}/lectures
2. GET /api/lectures/{lectureId}
3. CourseDetailView
4. LectureView route 연결

Route:

- /courses/:courseId
- /lectures/:lectureId

완료 기준:

강좌를 클릭하면 강좌 상세와 강의 목록으로 이동할 수 있다.

---

## Turn 7 — Redis Course Cache

Course 조회에 Redis cache를 추가한다.

완료 기준:

같은 Course API를 두 번 호출했을 때 로그에서 다음을 확인할 수 있다.

첫 요청:

CACHE MISS

두 번째 요청:

CACHE HIT

---

## Turn 8 — Enrollment

구현 항목:

1. POST /api/enrollments
2. GET /api/users/{userId}/enrollments
3. 수강신청 UI
4. 중복 수강신청 방지

중복 수강신청은 DB constraint로도 막는다.

UNIQUE(user_id, course_id)

완료 기준:

Vue에서 수강신청 클릭
→ POST API
→ MySQL enrollment 저장
→ UI 반영

---

## Turn 9 — Video Playback Simulator

Vue에 VideoPlaybackSimulator.vue를 만든다.

구현 항목:

1. Play
2. Pause
3. Reset
4. progress bar
5. 현재 시간 표시

이 단계에서는 backend API와 연결하지 않는다.

완료 기준:

브라우저에서 재생 시간이 정상 증가한다.

---

## Turn 10 — Progress API + Redis Buffer

구현 항목:

1. PUT /api/lectures/{lectureId}/progress
2. simulator의 주기적 progress event 전송
3. Redis progress buffer 저장

Progress key:

progress:{userId}:{lectureId}

완료 기준:

Redis에 progress key가 생성된다.

---

## Turn 11 — Progress 조회와 완료 판정

구현 항목:

1. GET /api/lectures/{lectureId}/progress?userId=1
2. backend completed 계산
3. Vue 현재 진도 표시
4. Vue 완료 여부 표시

완료 기준:

watchedSeconds >= durationSeconds * 0.9

이면 backend가 completed = true를 반환하고,
Vue가 완료 여부를 표시한다.

---

## Turn 12 — Redis to MySQL Flush

Spring @Scheduled job으로 Redis progress를 주기적으로 MySQL에 upsert한다.

기본 정책:

MAX(current, incoming)

완료 기준:

Redis에 있던 진도가 일정 시간 후 MySQL progress table에 반영된다.

---

## Turn 13 — Failure Experiment

Redis, Spring Boot, MySQL을 일부러 멈춰보며 결과를 README에 기록한다.

확인 항목:

1. Redis가 죽으면 progress update가 어떻게 실패하는가?
2. Spring Boot 재시작 후 Redis state가 남아 있는가?
3. MySQL 장애 중 Redis buffer는 유지되는가?
4. MySQL 복구 후 flush가 가능한가?

완료 기준:

실험 결과와 관찰 내용이 README에 기록된다.

---

## Turn 14 — README와 마무리 검증

README에 다음을 정리한다.

1. 실행법
2. architecture
3. Redis를 쓰는 이유
4. MySQL을 쓰는 이유
5. Kafka를 쓰지 않는 이유
6. simulated video를 쓰는 이유
7. failure observation

완료 기준:

docker compose up부터 Vue 화면 동작까지 전체 흐름을 한 번 통과시킨다.

---

## Turn 15 — Backend Stored Video 제공 확장

이 턴은 기본 LMS 실습 완료 후 진행하는 선택 확장이다.

구현 항목:

1. backend 내부 또는 runtime volume에 동영상 파일을 둘 위치를 정한다.
2. Lecture에 video metadata를 추가한다.
3. GET /api/lectures/{lectureId}/video endpoint를 만든다.
4. 필요한 경우 HTTP range request를 지원한다.
5. Vue의 VideoPlaybackSimulator를 실제 video element 기반 컴포넌트로 교체한다.
6. video playback event를 기존 PUT /api/lectures/{lectureId}/progress API에 연결한다.

완료 기준:

사용자가 Vue 강의 화면에서 backend가 제공하는 동영상을 재생할 수 있고,
시청 진도가 Redis에 먼저 저장된 뒤 scheduled flush 또는 완료 시점에 MySQL로 반영된다.

주의:

이 단계에서도 별도 video streaming server는 만들지 않는다.
Spring Boot가 학습용 demo 수준의 파일 제공 책임만 맡는다.

---

Turn 1부터 Turn 6까지는 Redis 없는 기본 LMS 흐름을 먼저 완성한다.

그 다음 Turn 7부터 Redis를 붙인다.

이 순서를 따르면 문제가 생겼을 때 API/DB 문제인지 Redis 문제인지 분리해서 확인하기 쉽다.

실제 backend 저장 동영상 제공은 Turn 15 이후에 붙인다.

즉, 현재 단계 판단은 다음과 같다.

1. 먼저 simulator로 progress pipeline을 완성한다.
2. Redis가 progress의 1차 저장소 역할을 하는지 확인한다.
3. MySQL flush가 안정적으로 동작하는지 확인한다.
4. 그 뒤 simulator를 실제 backend video 제공 방식으로 교체한다.

---

# 27. Manual AWS Deployment Preparation

AWS 배포는 항상 수동으로만 수행한다.

이 프로젝트에서는 원격 배포 파일을 초반에 만들지 않는다.

초반에 배포 파일을 먼저 만들면 아직 확정되지 않은 구조를 기준으로
임시 Dockerfile, 임시 reverse proxy, 임시 port 정책이 생기기 쉽다.
따라서 `.fordeploy/`의 실제 shell script는 Spring Boot 기반 runtime이
확정된 뒤 작성한다.

## 27.1 기본 원칙

- AWS 배포는 CI/CD나 자동 배포가 아니라 수동 shell script로만 수행한다.
- AWS ALB가 외부 HTTPS, host routing, health check, load balancing을 담당한다.
- 기본 AWS demo 배포 전략에서는 Nginx를 별도 application layer로 두지 않는다.
- Spring Boot가 production-like application server 역할을 한다.
- Spring Boot는 `/api/*`와 Vue build 정적 파일을 함께 제공한다.
- MySQL과 Redis는 application container와 lifecycle을 분리한다.
- application redeploy는 DB/Redis volume을 삭제하거나 재생성하지 않는다.

## 27.2 .fordeploy 작성 시점

`.fordeploy/` 아래의 실제 배포 shell script는 Turn 14 직전 또는
Turn 14 이후에 작성한다.

권장 위치:

Turn 14 — README와 마무리 검증

또는 별도 후속 단계:

Turn 14.5 — Manual AWS Demo Deployment Preparation

작성 대상 예:

1. .fordeploy/README.md
2. .fordeploy/deploy-aws-demo.sh
3. .fordeploy/configure-aws-demo-alb.sh
4. 필요한 경우 .fordeploy/bootstrap-aws-demo-runtime.sh

이 파일들은 다음이 확정된 뒤 작성한다.

1. Spring Boot Dockerfile
2. Vue dist를 Spring Boot image에 포함하는 방식
3. `/api/health` endpoint
4. Spring profile
5. MySQL connection environment
6. Redis connection environment
7. application container port
8. MySQL/Redis container 또는 외부 runtime 전략
9. seed/migration 방식
10. persistent volume 이름

## 27.3 .fordeploy/aws-backup 작성 시점

`.fordeploy/aws-backup/` 폴더는 미리 만들어둘 수 있다.

하지만 그 안에 실제 환경변수 파일과 runtime file 템플릿은
Turn 12 이후에 작성한다.

권장 위치:

Turn 12 — Redis to MySQL Flush 완료 후

또는:

Turn 13 — Failure Experiment 진행 중

작성 대상 예:

1. .fordeploy/aws-backup/.env.example
2. .fordeploy/aws-backup/env-file.example
3. .fordeploy/aws-backup/runtime-layout.md

실제 secret 값은 repository에 commit하지 않는다.

로컬 DB dump나 로컬 DB 파일을 AWS로 전송하는 전략은 사용하지 않는다.
AWS database state는 migration, seed data, 또는 AWS host 내부의
database administration 절차로 관리한다.

## 27.4 최종 AWS demo 형태

최종적으로 목표하는 AWS demo runtime은 다음과 같다.

ALB
   │
   ▼
Spring Boot app container
   ├── /api/*
   └── Vue static files
   │
   ├── MySQL
   └── Redis

개발환경에서는 Vue dev server와 Spring Boot를 분리해 빠르게 개발하고,
production-like AWS demo에서는 Spring Boot app container가
API와 frontend 정적 파일을 함께 제공한다.

---

# 28. README

README에는 단순 설치법뿐 아니라 다음을 기록한다.

## Architecture

Vue
→ Spring Boot
→ Redis / MySQL

## Why MySQL?

영속적인 business data 저장.

## Why Redis?

1. Course cache
2. 빈번한 progress update buffering

## Why not Kafka?

현재 규모와 문제에서는 필요하지 않음.

## Why simulated video?

목표는 streaming 기술이 아니라
학습 진도 데이터의 frontend/backend 처리 흐름을 이해하는 것이기 때문.

## Future Backend Stored Video

기본 구현이 끝난 뒤에는 backend가 저장한 동영상을
GET /api/lectures/{lectureId}/video 형태로 제공하는 확장을 고려한다.

이때도 진도 저장 전략은 유지한다.

Vue video element
→ Progress API
→ Redis progress buffer
→ MySQL progress table

Redis는 빠르게 바뀌는 시청 위치의 1차 저장소이고,
MySQL은 최종 수강 이력과 완료 여부의 영속 저장소이다.

## Failure Observations

Redis/MySQL/Spring을 실제로 중지시켜 본 결과 기록.

---

# 29. Definition of Done

프로젝트는 다음이 가능하면 완료다.

1. Vue에서 강좌 목록을 조회할 수 있다.
2. 강좌를 선택할 수 있다.
3. 수강신청할 수 있다.
4. 강의 목록을 볼 수 있다.
5. simulated video를 재생할 수 있다.
6. 진도가 주기적으로 backend로 전달된다.
7. 진도가 Redis에 저장된다.
8. Redis의 진도가 scheduled job을 통해 MySQL에 반영된다.
9. Course 조회 cache의 HIT/MISS를 로그로 확인할 수 있다.
10. Docker Compose로 frontend, backend, MySQL, Redis를 함께 실행할 수 있다.
11. 주요 장애 실험 결과가 README에 기록되어 있다.
12. Spring Boot 기반 AWS demo 수동 배포 전략이 문서화되어 있다.
13. 실제 backend 저장 동영상 제공은 기본 완료 이후 확장 단계로 판단되어 문서화되어 있다.
