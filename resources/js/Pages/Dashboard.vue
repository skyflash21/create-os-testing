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
            <h2 class="font-semibold text-xl text-gray-800 leading-tight">
                Console ComputerCraft
            </h2>
        </template>
    </AppLayout>

    
</template>

<style scoped>

.image-container {
  width: 100%;
  height: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
}
</style>
