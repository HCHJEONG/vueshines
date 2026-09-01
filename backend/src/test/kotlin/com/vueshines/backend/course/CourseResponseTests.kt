package com.vueshines.backend.course

import java.time.Instant
import kotlin.test.Test
import kotlin.test.assertEquals

class CourseResponseTests {

	@Test
	fun `response maps course fields`() {
		val createdAt = Instant.parse("2026-01-01T09:10:00Z")
		val course = Course(
			id = 1,
			title = "Vue 3와 Spring Boot로 배우는 LMS 기초",
			description = "강좌 조회부터 수강신청과 진도 저장까지 작은 LMS 흐름을 구현합니다.",
			instructor = "정하늘",
			createdAt = createdAt,
		)

		val response = CourseResponse.from(course)

		assertEquals(1, response.id)
		assertEquals("Vue 3와 Spring Boot로 배우는 LMS 기초", response.title)
		assertEquals("강좌 조회부터 수강신청과 진도 저장까지 작은 LMS 흐름을 구현합니다.", response.description)
		assertEquals("정하늘", response.instructor)
		assertEquals(createdAt, response.createdAt)
	}
}
