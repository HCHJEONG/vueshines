package com.vueshines.backend.course

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/courses")
class CourseController(
	private val courseService: CourseService,
) {
	@GetMapping
	fun listCourses(): List<CourseResponse> =
		courseService.findCourses()

	@GetMapping("/{courseId}")
	fun getCourse(@PathVariable courseId: Long): CourseResponse =
		courseService.findCourse(courseId)
}
