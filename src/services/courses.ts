import type { Course } from '@/types/course'
import type { Lecture } from '@/types/lecture'

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8080'

async function readJson<T>(path: string, message: string): Promise<T> {
  const response = await fetch(API_BASE_URL + path)

  if (!response.ok) {
    throw new Error(message + ' (' + response.status + ')')
  }

  return response.json() as Promise<T>
}

export async function fetchCourses(): Promise<Course[]> {
  return readJson<Course[]>('/api/courses', '강좌 목록을 불러오지 못했습니다.')
}

export async function fetchCourse(courseId: number): Promise<Course> {
  return readJson<Course>('/api/courses/' + courseId, '강좌 정보를 불러오지 못했습니다.')
}

export async function fetchCourseLectures(courseId: number): Promise<Lecture[]> {
  return readJson<Lecture[]>(
    '/api/courses/' + courseId + '/lectures',
    '강의 목록을 불러오지 못했습니다.',
  )
}

export async function fetchLecture(lectureId: number): Promise<Lecture> {
  return readJson<Lecture>('/api/lectures/' + lectureId, '강의 정보를 불러오지 못했습니다.')
}
