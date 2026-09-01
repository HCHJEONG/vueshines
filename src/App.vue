<script setup lang="ts">
import { RouterLink, RouterView } from 'vue-router'
</script>

<template>
  <div class="app-shell">
    <header class="app-header">
      <RouterLink class="app-header__brand" to="/">Penvot Education</RouterLink>
      <nav>
        <RouterLink to="/">강좌</RouterLink>
      </nav>
    </header>

    <RouterView />
  </div>
</template>

<style scoped>
.app-shell {
  min-height: 100vh;
}

.app-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  margin-bottom: 34px;
  padding-bottom: 18px;
  border-bottom: 1px solid #e0e0e0;
}

.app-header__brand {
  color: #27313d;
  font-size: 22px;
  font-weight: 900;
  text-decoration: none;
}

nav {
  display: flex;
  gap: 10px;
}

nav a {
  min-height: 36px;
  padding: 8px 12px;
  border-radius: 6px;
  color: #4d5965;
  font-weight: 700;
  text-decoration: none;
}

nav a.router-link-exact-active {
  background: #edf7f7;
  color: #006f6f;
}

@media (max-width: 520px) {
  .app-header {
    align-items: flex-start;
    flex-direction: column;
    margin-bottom: 24px;
  }
}
</style>
