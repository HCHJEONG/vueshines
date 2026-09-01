package com.vueshines.backend.lecture

import com.vueshines.backend.course.CourseRepository
import org.springframework.data.repository.findByIdOrNull
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.web.server.ResponseStatusException

@Service
class LectureService(
	private val courseRepository: CourseRepository,
	private val lectureRepository: LectureRepository,
) {
	fun findLecturesByCourse(courseId: Long): List<LectureResponse> {
		if (!courseRepository.existsById(courseId)) {
			throw ResponseStatusException(HttpStatus.NOT_FOUND, "Course not found: ")
		}

		return lectureRepository.findByCourse_IdOrderBySequenceAsc(courseId)
			.map(LectureResponse::from)
	}

	fun findLecture(lectureId: Long): LectureResponse {
		val lecture = lectureRepository.findByIdOrNull(lectureId)
			?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "Lecture not found: ")

		return LectureResponse.from(lecture)
	}
}
