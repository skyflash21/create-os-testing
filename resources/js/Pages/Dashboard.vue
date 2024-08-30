<script setup>
import { usePage } from "@inertiajs/vue3";
import Echo from 'laravel-echo';
import AppLayout from '@/Layouts/AppLayout.vue';

const page = usePage();

const test_wisper = () => {
    window.Echo.join('presence')
        .whisper('TypingEvent', {
            name: page.props.auth.user.name // Assuming this is how you access the authenticated user's name
        });
    console.log('test_wisper');
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
