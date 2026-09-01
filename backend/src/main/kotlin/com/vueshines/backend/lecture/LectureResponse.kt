package com.vueshines.backend.lecture

data class LectureResponse(
	val id: Long,
	val courseId: Long,
	val title: String,
	val durationSeconds: Int,
	val sequence: Int,
) {
	companion object {
		fun from(lecture: Lecture): LectureResponse =
			LectureResponse(
				id = requireNotNull(lecture.id) { "Lecture id must not be null in API responses." },
				courseId = requireNotNull(lecture.course?.id) { "Lecture course id must not be null in API responses." },
				title = lecture.title,
				durationSeconds = lecture.durationSeconds,
				sequence = lecture.sequence,
			)
	}
}
