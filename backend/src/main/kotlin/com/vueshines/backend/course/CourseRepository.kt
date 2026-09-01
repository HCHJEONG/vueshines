package com.vueshines.backend.course

import org.springframework.data.jpa.repository.JpaRepository

interface CourseRepository : JpaRepository<Course, Long>
