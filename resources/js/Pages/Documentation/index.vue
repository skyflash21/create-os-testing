<script setup>
import ComputerFAQ from '@/Pages/Documentation/Partials/ComputerDOC.vue';
import AppLayout from '@/Layouts/AppLayout.vue';

</script>

<template>
    <AppLayout title="Computers">
        <template #header>
            <h2 class="font-semibold text-xl text-gray-800 dark:text-gray-200 leading-tight">
                Documentation
            </h2>
        </template>

        <div class="max-w-7xl mx-auto py-10 sm:px-6 lg:px-8">
            <ComputerFAQ/>
        </div>
    </AppLayout>
</template>
