package com.vueshines.backend.lecture

import org.springframework.data.jpa.repository.JpaRepository

interface LectureRepository : JpaRepository<Lecture, Long> {
	fun findByCourse_IdOrderBySequenceAsc(courseId: Long): List<Lecture>
}
