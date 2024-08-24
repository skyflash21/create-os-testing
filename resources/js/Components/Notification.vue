<template>
  <transition-group name="fade" tag="div" class="fixed bottom-0 right-0 space-y-2 p-4">
    <div
      v-for="notification in notifications"
      :key="notification.id"
      class="bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-700 rounded-lg shadow-lg overflow-hidden relative"
    >
      <div class="flex items-center p-4">
        <img v-if="notification.imageUrl" :src="notification.imageUrl" alt="Computer" class="w-12 h-12 object-cover" />
        <div class="ms-4">
          <h4 class="text-lg font-semibold text-gray-800 dark:text-gray-200">{{ notification.computerName }}</h4>
          <p class="text-sm text-gray-600 dark:text-gray-400">{{ notification.message }}</p>
        </div>
        <button
          @click="removeNotification(notification.id)"
          class="absolute top-1 right-1 text-gray-500 dark:text-gray-300 hover:text-gray-700 dark:hover:text-gray-100"
        >
          <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
    </div>
  </transition-group>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch } from 'vue';

const props = defineProps({
  notifications: Array,
});

const emit = defineEmits(['close']);


const removeNotification = (id) => {
  emit('close', id);
};

watch(
  () => props.notifications
);
</script>

<style scope>
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.5s;
}
.fade-enter, .fade-leave-to {
  opacity: 0;
}
</style>
