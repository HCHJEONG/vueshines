import type { Course } from '@/types/course'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8080'

export async function fetchCourses(): Promise<Course[]> {
  const response = await fetch(API_BASE_URL + '/api/courses')

  if (!response.ok) {
    throw new Error('강좌 목록을 불러오지 못했습니다. (' + response.status + ')')
  }

  return response.json() as Promise<Course[]>
}
