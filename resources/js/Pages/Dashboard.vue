<script setup>
import AppLayout from '@/Layouts/AppLayout.vue';
import Welcome from '@/Components/Welcome.vue';

const test_wisper = () => {
    console.log('test_wisper');
    Echo.private(`presence-presence`)
    .whisper('typing', {
        name: "this.user.name"
    });
}
</script>

<template>
    <AppLayout title="Dashboard">
        <template #header>
            <h2 class="font-semibold text-xl text-gray-800 dark:text-gray-200 leading-tight">
                Dashboard
            </h2>
        </template>

        <div class="flex justify-center mt-8">
            <button class="px-4 py-2 text-white bg-blue-500 rounded-md" @click="test_wisper">Test Wisper</button>
        </div>
    </AppLayout>
</template>
