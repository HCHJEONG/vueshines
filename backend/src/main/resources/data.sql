INSERT IGNORE INTO users (id, email, name, created_at) VALUES
  (1, 'student@example.com', '학습자 김민준', '2026-01-01 09:00:00.000000');

INSERT IGNORE INTO courses (id, title, description, instructor, created_at) VALUES
  (1, 'Vue 3와 Spring Boot로 배우는 LMS 기초', '강좌 조회부터 수강신청과 진도 저장까지 작은 LMS 흐름을 구현합니다.', '정하늘', '2026-01-01 09:10:00.000000'),
  (2, 'Redis와 MySQL로 이해하는 학습 진도 처리', 'Redis buffering과 MySQL 영속화를 통해 자주 갱신되는 진도 데이터를 다룹니다.', '이서윤', '2026-01-01 09:20:00.000000');

INSERT IGNORE INTO lectures (id, course_id, title, duration_seconds, sequence) VALUES
  (1, 1, '프로젝트 구조와 개발 환경 살펴보기', 420, 1),
  (2, 1, 'Course API와 Vue 목록 화면 연결하기', 540, 2),
  (3, 1, '수강신청과 강의 라우팅 흐름 이해하기', 480, 3),
  (4, 2, 'Course Cache를 Redis에 저장하기', 510, 1),
  (5, 2, '진도 이벤트를 Redis Buffer로 다루기', 560, 2),
  (6, 2, 'Redis 데이터를 MySQL로 Flush하기', 530, 3);
