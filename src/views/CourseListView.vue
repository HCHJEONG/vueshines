<script setup lang="ts">
import { onMounted, ref } from 'vue'
import CourseCard from '@/components/CourseCard.vue'
import { fetchCourses } from '@/services/courses'
import type { Course } from '@/types/course'

const courses = ref<Course[]>([])
const isLoading = ref(true)
const errorMessage = ref('')

onMounted(async () => {
  try {
    courses.value = await fetchCourses()
  } catch (error) {
    errorMessage.value =
      error instanceof Error ? error.message : '강좌 목록을 불러오지 못했습니다.'
  } finally {
    isLoading.value = false
  }
})
</script>

<template>
  <main class="course-list">
    <section class="course-list__intro" aria-labelledby="course-list-title">
      <div>
        <span class="course-list__eyebrow">Penvot Education LMS</span>
        <h1 id="course-list-title">강좌 목록</h1>
        <p>Spring Boot API에서 가져온 학습 강좌를 확인하고 다음 학습 흐름을 준비합니다.</p>
      </div>

      <aside class="course-list__summary" aria-label="강좌 요약">
        <span>등록 강좌</span>
        <strong>{{ courses.length }}</strong>
      </aside>
    </section>

    <section v-if="isLoading" class="course-list__state" aria-live="polite">
      강좌 목록을 불러오는 중입니다.
    </section>

    <section v-else-if="errorMessage" class="course-list__state course-list__state--error">
      {{ errorMessage }}
    </section>

    <section v-else class="course-list__grid" aria-label="강좌">
      <CourseCard v-for="course in courses" :key="course.id" :course="course" />
    </section>
  </main>
</template>

<style scoped>
.course-list {
  width: 100%;
}

.course-list__intro {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 180px;
  gap: 24px;
  align-items: end;
  margin-bottom: 28px;
  padding-bottom: 24px;
  border-bottom: 1px solid #e0e0e0;
}

.course-list__eyebrow {
  color: #008080;
  font-size: 14px;
  font-weight: 800;
}

h1 {
  margin-top: 8px;
  color: #27313d;
  font-size: 34px;
  font-weight: 900;
  line-height: 1.25;
}

p {
  max-width: 720px;
  margin-top: 10px;
  color: #596673;
  line-height: 1.7;
}

.course-list__summary {
  display: grid;
  gap: 4px;
  padding: 18px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background: #f7fafb;
}

.course-list__summary span {
  color: #667085;
  font-size: 14px;
}

.course-list__summary strong {
  color: #27313d;
  font-size: 30px;
  font-weight: 900;
  font-variant-numeric: tabular-nums;
}

.course-list__grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 18px;
}

.course-list__state {
  padding: 28px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background: #ffffff;
  color: #4d5965;
}

.course-list__state--error {
  border-color: #f1b8b8;
  background: #fff8f8;
  color: #b42318;
}

@media (max-width: 900px) {
  .course-list__intro,
  .course-list__grid {
    grid-template-columns: 1fr;
  }

  .course-list__summary {
    max-width: 220px;
  }
}

@media (max-width: 520px) {
  h1 {
    font-size: 28px;
  }

  .course-list__intro {
    gap: 18px;
  }
}
</style>
