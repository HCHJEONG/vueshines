package com.vueshines.backend.web

import org.springframework.stereotype.Controller
import org.springframework.web.bind.annotation.GetMapping

@Controller
class SpaForwardController {

	@GetMapping(
		value = [
			"/{path:^(?!api$|actuator$|assets$)[^.]+$}",
			"/{path:^(?!api$|actuator$|assets$)[^.]+$}/**",
		],
	)
	fun forwardFrontendRoute(): String = "forward:/index.html"
}
