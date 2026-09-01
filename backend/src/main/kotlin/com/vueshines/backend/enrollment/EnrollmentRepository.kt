package com.vueshines.backend.enrollment

import org.springframework.data.jpa.repository.JpaRepository

interface EnrollmentRepository : JpaRepository<Enrollment, Long>
