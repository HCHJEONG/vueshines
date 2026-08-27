package com.vueshines.backend.web

import kotlin.test.Test
import kotlin.test.assertEquals

class SpaForwardControllerTests {

	@Test
	fun `frontend routes forward to the Vue entry point`() {
		assertEquals("forward:/index.html", SpaForwardController().forwardFrontendRoute())
	}
}
