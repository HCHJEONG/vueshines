package com.vueshines.backend.course

import org.springframework.data.repository.findByIdOrNull
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.web.server.ResponseStatusException

@Service
class CourseService(
	private val courseRepository: CourseRepository,
) {
	fun findCourses(): List<CourseResponse> =
		courseRepository.findAll()
			.sortedBy { it.id ?: Long.MAX_VALUE }
			.map(CourseResponse::from)

	fun findCourse(courseId: Long): CourseResponse {
		val course = courseRepository.findByIdOrNull(courseId)
			?: throw ResponseStatusException(HttpStatus.NOT_FOUND, "Course not found: $courseId")

		return CourseResponse.from(course)
	}
}
