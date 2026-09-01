<script setup lang="ts">
import { RouterLink } from 'vue-router'
import type { Course } from '@/types/course'

defineProps<{
  course: Course
}>()
</script>

<template>
  <article class="course-card">
    <div class="course-card__header">
      <span class="course-card__tag">온라인 강좌</span>
      <span class="course-card__instructor">{{ course.instructor }}</span>
    </div>

    <h2>{{ course.title }}</h2>
    <p>{{ course.description }}</p>

    <div class="course-card__meta">
      <span>강의 확인 가능</span>
      <span>진도 0%</span>
    </div>

    <RouterLink class="course-card__action" :to="{ name: 'course-detail', params: { courseId: course.id } }">
      강좌 보기
    </RouterLink>
  </article>
</template>

<style scoped>
.course-card {
  display: grid;
  gap: 14px;
  min-height: 260px;
  padding: 22px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background: #ffffff;
  box-shadow: 0 8px 24px rgb(35 44 54 / 6%);
}

.course-card__header,
.course-card__meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.course-card__tag {
  display: inline-flex;
  align-items: center;
  min-height: 28px;
  padding: 0 10px;
  border-radius: 6px;
  background: #edf7f7;
  color: #006f6f;
  font-size: 13px;
  font-weight: 700;
}

.course-card__instructor,
.course-card__meta {
  color: #667085;
  font-size: 14px;
}

h2 {
  color: #27313d;
  font-size: 22px;
  font-weight: 800;
  line-height: 1.35;
}

p {
  color: #4d5965;
  line-height: 1.7;
}

.course-card__meta {
  padding-top: 10px;
  border-top: 1px solid #e8ecef;
  font-variant-numeric: tabular-nums;
}

.course-card__action {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  min-height: 44px;
  border-radius: 6px;
  background: #008080;
  color: #ffffff;
  font-weight: 800;
  text-decoration: none;
  cursor: pointer;
}

.course-card__action:hover {
  background: #006f6f;
}
</style>
