package com.vueshines.backend.lecture

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api")
class LectureController(
	private val lectureService: LectureService,
) {
	@GetMapping("/courses/{courseId}/lectures")
	fun listLectures(@PathVariable courseId: Long): List<LectureResponse> =
		lectureService.findLecturesByCourse(courseId)

	@GetMapping("/lectures/{lectureId}")
	fun getLecture(@PathVariable lectureId: Long): LectureResponse =
		lectureService.findLecture(lectureId)
}
