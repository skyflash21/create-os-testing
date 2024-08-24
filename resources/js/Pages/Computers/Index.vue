<script setup>
import ComputerManager from '@/Pages/Computers/Partials/ComputersManager.vue';
import AppLayout from '@/Layouts/AppLayout.vue';

// Get props from the server-side
const props = defineProps({
  computers: Array,
  user: Object,
});
</script>

<template>
    <AppLayout title="Computers">
        <template #header>
            <h2 class="font-semibold text-xl text-gray-800 dark:text-gray-200 leading-tight">
                Computers Manager
            </h2>
        </template>

        <div class="max-w-7xl mx-auto py-10 sm:px-6 lg:px-8">
            <ComputerManager :computers="computers" :user="user" />
        </div>

        
    </AppLayout>
</template>
