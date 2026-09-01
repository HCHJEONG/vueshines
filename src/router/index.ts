import { createRouter, createWebHistory } from 'vue-router'
import CourseListView from '@/views/CourseListView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'courses',
      component: CourseListView,
    },
  ],
})

export default router
