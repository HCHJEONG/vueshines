CREATE TABLE IF NOT EXISTS users (
  id BIGINT NOT NULL AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL,
  name VARCHAR(100) NOT NULL,
  created_at DATETIME(6) NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT uk_users_email UNIQUE (email)
);

CREATE TABLE IF NOT EXISTS courses (
  id BIGINT NOT NULL AUTO_INCREMENT,
  title VARCHAR(200) NOT NULL,
  description TEXT NOT NULL,
  instructor VARCHAR(100) NOT NULL,
  created_at DATETIME(6) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS lectures (
  id BIGINT NOT NULL AUTO_INCREMENT,
  course_id BIGINT NOT NULL,
  title VARCHAR(200) NOT NULL,
  duration_seconds INT NOT NULL,
  sequence INT NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_lectures_course FOREIGN KEY (course_id) REFERENCES courses (id),
  CONSTRAINT uk_lectures_course_sequence UNIQUE (course_id, sequence),
  CONSTRAINT ck_lectures_duration_positive CHECK (duration_seconds > 0),
  CONSTRAINT ck_lectures_sequence_positive CHECK (sequence > 0)
);

CREATE TABLE IF NOT EXISTS enrollments (
  id BIGINT NOT NULL AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  course_id BIGINT NOT NULL,
  enrolled_at DATETIME(6) NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_enrollments_user FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT fk_enrollments_course FOREIGN KEY (course_id) REFERENCES courses (id),
  CONSTRAINT uk_enrollments_user_course UNIQUE (user_id, course_id)
);

CREATE TABLE IF NOT EXISTS progress (
  id BIGINT NOT NULL AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  lecture_id BIGINT NOT NULL,
  watched_seconds INT NOT NULL,
  completed BOOLEAN NOT NULL,
  updated_at DATETIME(6) NOT NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_progress_user FOREIGN KEY (user_id) REFERENCES users (id),
  CONSTRAINT fk_progress_lecture FOREIGN KEY (lecture_id) REFERENCES lectures (id),
  CONSTRAINT uk_progress_user_lecture UNIQUE (user_id, lecture_id),
  CONSTRAINT ck_progress_watched_seconds_non_negative CHECK (watched_seconds >= 0)
);
