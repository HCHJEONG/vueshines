<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { RouterLink } from 'vue-router'
import { fetchCourse, fetchLecture } from '@/services/courses'
import type { Course } from '@/types/course'
import type { Lecture } from '@/types/lecture'

const props = defineProps<{
  lectureId: number
}>()

const lecture = ref<Lecture | null>(null)
const course = ref<Course | null>(null)
const isLoading = ref(true)
const errorMessage = ref('')

const progressPercent = computed(() => 0)

function formatDuration(totalSeconds: number): string {
  const minutes = Math.floor(totalSeconds / 60)
  const seconds = totalSeconds % 60
  return String(minutes) + ':' + String(seconds).padStart(2, '0')
}

async function loadLecture() {
  if (!Number.isFinite(props.lectureId)) {
    errorMessage.value = '올바르지 않은 강의 주소입니다.'
    isLoading.value = false
    return
  }

  isLoading.value = true
  errorMessage.value = ''

  try {
    const lectureResult = await fetchLecture(props.lectureId)
    lecture.value = lectureResult
    course.value = await fetchCourse(lectureResult.courseId)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '강의 정보를 불러오지 못했습니다.'
  } finally {
    isLoading.value = false
  }
}

onMounted(loadLecture)
watch(() => props.lectureId, loadLecture)
</script>

<template>
  <main class="lecture-view">
    <RouterLink
      v-if="lecture"
      class="lecture-view__back"
      :to="{ name: 'course-detail', params: { courseId: lecture.courseId } }"
    >
      강좌 상세
    </RouterLink>
    <RouterLink v-else class="lecture-view__back" to="/">강좌 목록</RouterLink>

    <section v-if="isLoading" class="lecture-view__state" aria-live="polite">
      강의 정보를 불러오는 중입니다.
    </section>

    <section v-else-if="errorMessage" class="lecture-view__state lecture-view__state--error">
      {{ errorMessage }}
    </section>

    <template v-else-if="lecture">
      <section class="lecture-view__header" aria-labelledby="lecture-title">
        <span>Lecture {{ lecture.sequence }}</span>
        <h1 id="lecture-title">{{ lecture.title }}</h1>
        <p v-if="course">{{ course.title }} · {{ course.instructor }}</p>
      </section>

      <section class="lecture-panel" aria-label="강의 학습 상태">
        <div class="lecture-panel__screen">
          <strong>샘플 영상은 Turn 10에서 연결됩니다.</strong>
          <span>{{ formatDuration(lecture.durationSeconds) }} 강의</span>
        </div>

        <div class="lecture-panel__progress" aria-label="진도">
          <div>
            <span>현재 진도</span>
            <strong>{{ progressPercent }}%</strong>
          </div>
          <div class="lecture-panel__bar">
            <span :style="{ width: progressPercent + '%' }"></span>
          </div>
        </div>
      </section>
    </template>
  </main>
</template>

<style scoped>
.lecture-view {
  display: grid;
  gap: 24px;
}

.lecture-view__back {
  width: fit-content;
  color: #006f6f;
  font-weight: 800;
  text-decoration: none;
}

.lecture-view__header {
  display: grid;
  gap: 8px;
  padding-bottom: 20px;
  border-bottom: 1px solid #e0e0e0;
}

.lecture-view__header span {
  color: #008080;
  font-size: 14px;
  font-weight: 800;
}

h1 {
  color: #27313d;
  font-size: 32px;
  font-weight: 900;
  line-height: 1.25;
}

p {
  color: #596673;
  line-height: 1.7;
}

.lecture-panel {
  display: grid;
  gap: 18px;
}

.lecture-panel__screen {
  display: grid;
  place-items: center;
  gap: 8px;
  min-height: 320px;
  border: 1px solid #d9e1e5;
  border-radius: 8px;
  background: #27313d;
  color: #ffffff;
  text-align: center;
}

.lecture-panel__screen strong {
  padding: 0 18px;
  font-size: 20px;
  font-weight: 900;
}

.lecture-panel__screen span {
  color: #d8e5e7;
  font-variant-numeric: tabular-nums;
}

.lecture-panel__progress {
  display: grid;
  gap: 10px;
  padding: 18px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background: #ffffff;
}

.lecture-panel__progress div:first-child {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  color: #4d5965;
}

.lecture-panel__progress strong {
  color: #27313d;
  font-weight: 900;
  font-variant-numeric: tabular-nums;
}

.lecture-panel__bar {
  height: 10px;
  overflow: hidden;
  border-radius: 999px;
  background: #edf1f3;
}

.lecture-panel__bar span {
  display: block;
  height: 100%;
  border-radius: inherit;
  background: #008080;
}

.lecture-view__state {
  padding: 28px;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  background: #ffffff;
  color: #4d5965;
}

.lecture-view__state--error {
  border-color: #f1b8b8;
  background: #fff8f8;
  color: #b42318;
}

@media (max-width: 520px) {
  h1 {
    font-size: 27px;
  }

  .lecture-panel__screen {
    min-height: 240px;
  }
}
</style>
