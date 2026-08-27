package com.vueshines.backend.web

import jakarta.servlet.FilterChain
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.stereotype.Component
import org.springframework.web.filter.OncePerRequestFilter

@Component
@ConditionalOnProperty(
	name = ["app.search-indexing-enabled"],
	havingValue = "false",
	matchIfMissing = true,
)
class NoIndexHeaderFilter : OncePerRequestFilter() {

	override fun doFilterInternal(
		request: HttpServletRequest,
		response: HttpServletResponse,
		filterChain: FilterChain,
	) {
		response.setHeader("X-Robots-Tag", "noindex, nofollow, noarchive")
		filterChain.doFilter(request, response)
	}
}
