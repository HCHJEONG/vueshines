package com.vueshines.backend.course

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.Instant

@Entity
@Table(name = "courses")
class Course(
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	var id: Long? = null,

	@Column(nullable = false, length = 200)
	var title: String = "",

	@Column(nullable = false, columnDefinition = "TEXT")
	var description: String = "",

	@Column(nullable = false, length = 100)
	var instructor: String = "",

	@Column(nullable = false)
	var createdAt: Instant = Instant.now(),
)
