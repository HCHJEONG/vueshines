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

실제 video file은 저장하지 않는다.

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

Turn 1부터 Turn 6까지는 Redis 없는 기본 LMS 흐름을 먼저 완성한다.

그 다음 Turn 7부터 Redis를 붙인다.

이 순서를 따르면 문제가 생겼을 때 API/DB 문제인지 Redis 문제인지 분리해서 확인하기 쉽다.

---

# 27. README

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

## Failure Observations

Redis/MySQL/Spring을 실제로 중지시켜 본 결과 기록.

---

# 28. Definition of Done

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
