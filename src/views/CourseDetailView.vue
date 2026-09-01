<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { fetchCourse, fetchCourseLectures } from '@/services/courses'
import type { Course } from '@/types/course'
import type { Lecture } from '@/types/lecture'

const props = defineProps<{
  courseId: number
}>()

const course = ref<Course | null>(null)
const lectures = ref<Lecture[]>([])
const isLoading = ref(true)
const errorMessage = ref('')

const totalDurationSeconds = computed(() =>
  lectures.value.reduce((total, lecture) => total + lecture.durationSeconds, 0),
)

function formatDuration(totalSeconds: number): string {
  const minutes = Math.floor(totalSeconds / 60)
  const seconds = totalSeconds % 60
  return String(minutes) + ':' + String(seconds).padStart(2, '0')
}

async function loadCourseDetail() {
  if (!Number.isFinite(props.courseId)) {
    errorMessage.value = '올바르지 않은 강좌 주소입니다.'
    isLoading.value = false
    return
  }

  isLoading.value = true
  errorMessage.value = ''

  try {
    const [courseResult, lectureResult] = await Promise.all([
      fetchCourse(props.courseId),
      fetchCourseLectures(props.courseId),
    ])
    course.value = courseResult
    lectures.value = lectureResult
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '강좌 상세를 불러오지 못했습니다.'
  } finally {
    isLoading.value = false
  }
}

onMounted(loadCourseDetail)
watch(() => props.courseId, loadCourseDetail)
</script>

<template>
  <main class="course-detail">
    <RouterLink class="course-detail__back" to="/">강좌 목록</RouterLink>

    <section v-if="isLoading" class="course-detail__state" aria-live="polite">
      강좌 상세를 불러오는 중입니다.
    </section>

    <section v-else-if="errorMessage" class="course-detail__state course-detail__state--error">
      {{ errorMessage }}
    </section>

    <template v-else-if="course">
      <section class="course-detail__title" aria-labelledby="course-detail-title">
        <span class="course-detail__tag">온라인 강좌</span>
        <h1 id="course-detail-title">{{ course.title }}</h1>
        <p>{{ course.description }}</p>
      </section>

      <section class="course-detail__overview" aria-label="강좌 정보">
        <div class="course-detail__visual">
          <span>VS</span>
          <strong>{{ course.instructor }}</strong>
        </div>

        <dl class="course-detail__meta">
          <div>
            <dt>강좌유형</dt>
            <dd>기초 LMS 실습</dd>
          </div>
          <div>
            <dt>강좌구성</dt>
            <dd>{{ lectures.length }}강</dd>
          </div>
          <div>
            <dt>총 학습시간</dt>
            <dd>{{ formatDuration(totalDurationSeconds) }}</dd>
          </div>
          <div>
            <dt>선생님</dt>
            <dd>{{ course.instructor }}</dd>
          </div>
        </dl>
      </section>

      <section class="lecture-section" aria-labelledby="lecture-section-title">
        <div class="lecture-section__header">
          <div>
            <span class="course-detail__tag">Curriculum</span>
            <h2 id="lecture-section-title">강의 목록</h2>
          </div>
          <strong>{{ lectures.length }}개 강의</strong>
        </div>

        <ol class="lecture-list">
          <li v-for="lecture in lectures" :key="lecture.id" class="lecture-list__item">
            <span class="lecture-list__sequence">{{ lecture.sequence }}</span>
            <div class="lecture-list__body">
              <h3>{{ lecture.title }}</h3>
              <span>{{ formatDuration(lecture.durationSeconds) }}</span>
            </div>
            <RouterLink
              class="lecture-list__action"
              :to="{ name: 'lecture-detail', params: { lectureId: lecture.id } }"
            >
              강의 보기
            </RouterLink>
          </li>
        </ol>
      </section>
    </template>
  </main>
</template>

<style scoped>
.course-detail {
  display: grid;
  gap: 26px;
}

.course-detail__back {
  width: fit-content;
  color: #006f6f;
  font-weight: 800;
  text-decoration: none;
}

.course-detail__title {
  display: grid;
  gap: 10px;
  padding-bottom: 22px;
  border-bottom: 1px solid #e0e0e0;
}

.course-detail__tag {
  color: #008080;
  font-size: 14px;
  font-weight: 800;
}

h1 {
  max-width: 860px;
  color: #27313d;
  font-size: 34px;
  font-weight: 900;
  line-height: 1.25;
}

p {
  max-width: 780px;
  color: #4d5965;
  line-height: 1.7;
}

.course-detail__overview {
  display: grid;
  grid-template-columns: minmax(220px, 320px) minmax(0, 1fr);
  gap: 24px;
  align-items: stretch;
}

.course-detail__visual {
  display: grid;
  place-items: center;
  gap: 10px;
  min-height: 220px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background: #f7fafb;
  color: #27313d;
  text-align: center;
}

.course-detail__visual span {
  display: grid;
  place-items: center;
  width: 76px;
  height: 76px;
  border-radius: 50%;
  background: #ffffff;
  color: #008080;
  font-size: 24px;
  font-weight: 900;
}

.course-detail__visual strong {
  font-size: 18px;
  font-weight: 900;
}

.course-detail__meta {
  display: grid;
  align-content: start;
  border-top: 1px solid #e0e0e0;
}

.course-detail__meta div {
  display: grid;
  grid-template-columns: 140px minmax(0, 1fr);
  gap: 18px;
  padding: 18px 0;
  border-bottom: 1px solid #e0e0e0;
}

dt {
  color: #667085;
  font-weight: 800;
}

dd {
  color: #27313d;
  font-weight: 800;
}

.lecture-section {
  display: grid;
  gap: 16px;
}

.lecture-section__header {
  display: flex;
  align-items: end;
  justify-content: space-between;
  gap: 18px;
}

h2 {
  margin-top: 4px;
  color: #27313d;
  font-size: 24px;
  font-weight: 900;
}

.lecture-section__header strong {
  color: #667085;
  font-weight: 800;
}

.lecture-list {
  display: grid;
  gap: 10px;
  padding: 0;
  list-style: none;
}

.lecture-list__item {
  display: grid;
  grid-template-columns: 42px minmax(0, 1fr) 104px;
  gap: 14px;
  align-items: center;
  min-height: 76px;
  padding: 14px 16px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background: #ffffff;
}

.lecture-list__sequence {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  border-radius: 6px;
  background: #edf7f7;
  color: #006f6f;
  font-weight: 900;
  font-variant-numeric: tabular-nums;
}

.lecture-list__body {
  min-width: 0;
}

h3 {
  color: #27313d;
  font-size: 17px;
  font-weight: 900;
  line-height: 1.4;
}

.lecture-list__body span {
  color: #667085;
  font-size: 14px;
  font-variant-numeric: tabular-nums;
}

.lecture-list__action {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 40px;
  border-radius: 6px;
  background: #27313d;
  color: #ffffff;
  font-weight: 800;
  text-decoration: none;
}

.course-detail__state {
  padding: 28px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background: #ffffff;
  color: #4d5965;
}

.course-detail__state--error {
  border-color: #f1b8b8;
  background: #fff8f8;
  color: #b42318;
}

@media (max-width: 768px) {
  .course-detail__overview,
  .course-detail__meta div,
  .lecture-list__item {
    grid-template-columns: 1fr;
  }

  .lecture-section__header {
    align-items: flex-start;
    flex-direction: column;
  }

  .lecture-list__action {
    width: 100%;
  }
}

@media (max-width: 520px) {
  h1 {
    font-size: 28px;
  }
}
</style>
