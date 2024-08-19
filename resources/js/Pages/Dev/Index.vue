<script setup>
import Todo from '@/Pages/Dev/Partials/Todo.vue';
import AppLayout from '@/Layouts/AppLayout.vue';

// Get props from the server-side
const props = defineProps({
  todos: Array // Get todos from the server
});
</script>

<template>
    <AppLayout title="Dev">
        <template #header>
            <h2 class="font-semibold text-xl text-gray-800 dark:text-gray-200 leading-tight">
                Dev Area
            </h2>
        </template>

        <div class="max-w-7xl mx-auto py-10 sm:px-6 lg:px-8">
            <Todo :todos="props.todos" /> <!-- Pass todos to the Todo component -->
        </div>
    </AppLayout>
</template>
