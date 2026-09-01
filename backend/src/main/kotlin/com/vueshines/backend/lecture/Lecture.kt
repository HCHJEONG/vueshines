package com.vueshines.backend.lecture

import com.vueshines.backend.course.Course
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

@Entity
@Table(
	name = "lectures",
	uniqueConstraints = [UniqueConstraint(name = "uk_lectures_course_sequence", columnNames = ["course_id", "sequence"])],
)
class Lecture(
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	var id: Long? = null,

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "course_id", nullable = false)
	var course: Course? = null,

	@Column(nullable = false, length = 200)
	var title: String = "",

	@Column(nullable = false)
	var durationSeconds: Int = 0,

	@Column(nullable = false)
	var sequence: Int = 0,
)
