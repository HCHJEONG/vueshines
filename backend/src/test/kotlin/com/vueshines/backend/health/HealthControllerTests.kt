package com.vueshines.backend.health

import kotlin.test.Test
import kotlin.test.assertEquals

class HealthControllerTests {

	@Test
	fun `health returns ok status`() {
		assertEquals(mapOf("status" to "ok"), HealthController().health())
	}
}
