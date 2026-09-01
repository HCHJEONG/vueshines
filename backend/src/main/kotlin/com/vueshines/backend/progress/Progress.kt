package com.vueshines.backend.progress

import com.vueshines.backend.lecture.Lecture
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
	name = "progress",
	uniqueConstraints = [UniqueConstraint(name = "uk_progress_user_lecture", columnNames = ["user_id", "lecture_id"])],
)
class Progress(
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	var id: Long? = null,

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "user_id", nullable = false)
	var user: User? = null,

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "lecture_id", nullable = false)
	var lecture: Lecture? = null,

	@Column(nullable = false)
	var watchedSeconds: Int = 0,

	@Column(nullable = false)
	var completed: Boolean = false,

	@Column(nullable = false)
	var updatedAt: Instant = Instant.now(),
)
