<!-- src/Components/CustomButton.vue -->
<template>
  <button
    :class="buttonClass"
    :disabled="disabled"
    @click="$emit('click')"
  >
    <slot></slot>
  </button>
</template>

<script setup>
import { defineProps, computed } from 'vue';

const props = defineProps({
  type: {
    type: String,
    default: 'primary',
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});

const buttonClass = computed(() => {
  const baseClasses = 'px-4 py-2 border rounded transition-colors duration-300 focus:outline-none focus:ring-2 focus:ring-opacity-50';
  const colorClasses = props.type === 'danger'
    ? 'bg-red-500 text-white border-red-700 hover:bg-red-600 focus:ring-red-500'
    : 'bg-blue-500 text-white border-blue-700 hover:bg-blue-600 focus:ring-blue-500';

  return `${baseClasses} ${colorClasses} ${props.disabled ? 'opacity-50 cursor-not-allowed' : ''}`;
});
</script>

<style scoped>
button {
  @apply font-medium;
}
</style>