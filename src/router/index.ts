import { createRouter, createWebHistory } from 'vue-router'
import CourseListView from '@/views/CourseListView.vue'
import CourseDetailView from '@/views/CourseDetailView.vue'
import LectureView from '@/views/LectureView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'courses',
      component: CourseListView,
    },
    {
      path: '/courses/:courseId',
      name: 'course-detail',
      component: CourseDetailView,
      props: (route) => ({ courseId: Number(route.params.courseId) }),
    },
    {
      path: '/lectures/:lectureId',
      name: 'lecture-detail',
      component: LectureView,
      props: (route) => ({ lectureId: Number(route.params.lectureId) }),
    },
  ],
})

export default router
