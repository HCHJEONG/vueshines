package com.vueshines.backend.course

import java.time.Instant

data class CourseResponse(
	val id: Long,
	val title: String,
	val description: String,
	val instructor: String,
	val createdAt: Instant,
) {
	companion object {
		fun from(course: Course): CourseResponse =
			CourseResponse(
				id = requireNotNull(course.id) { "Course id must not be null in API responses." },
				title = course.title,
				description = course.description,
				instructor = course.instructor,
				createdAt = course.createdAt,
			)
	}
}
