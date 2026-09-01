package com.vueshines.backend.user

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.Instant

@Entity
@Table(name = "users")
class User(
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	var id: Long? = null,

	@Column(nullable = false, unique = true, length = 255)
	var email: String = "",

	@Column(nullable = false, length = 100)
	var name: String = "",

	@Column(nullable = false)
	var createdAt: Instant = Instant.now(),
)
