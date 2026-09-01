package com.vueshines.backend.progress

import org.springframework.data.jpa.repository.JpaRepository

interface ProgressRepository : JpaRepository<Progress, Long>
