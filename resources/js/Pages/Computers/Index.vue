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
        <ComputerManager :computers="computers" :user="user" />
    </AppLayout>
</template>
