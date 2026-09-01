package com.vueshines.backend.enrollment

import com.vueshines.backend.course.Course
import com.vueshines.backend.user.User
import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.JoinColumn
import jakarta.persistence.ManyToOne
import jakarta.persistence.Table
import jakarta.persistence.UniqueConstraint
import java.time.Instant

@Entity
@Table(
	name = "enrollments",
	uniqueConstraints = [UniqueConstraint(name = "uk_enrollments_user_course", columnNames = ["user_id", "course_id"])],
)
class Enrollment(
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	var id: Long? = null,

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "user_id", nullable = false)
	var user: User? = null,

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "course_id", nullable = false)
	var course: Course? = null,

	@Column(nullable = false)
	var enrolledAt: Instant = Instant.now(),
)
