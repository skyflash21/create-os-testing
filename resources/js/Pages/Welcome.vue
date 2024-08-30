<script setup>
import { Head, Link } from '@inertiajs/vue3';

defineProps({
    canLogin: {
        type: Boolean,
    },
    canRegister: {
        type: Boolean,
    },
    laravelVersion: {
        type: String,
        required: true,
    },
    phpVersion: {
        type: String,
        required: true,
    },
});
</script>

<template>
    <Head title="Welcome" />
    <nav v-if="canLogin" class="flex flex-1 justify-end space-x-4">
        <Link
            v-if="$page.props.auth.user"
            :href="route('dashboard')"
            class="rounded-md px-4 py-2 bg-gray-800 text-white transition-colors duration-200 hover:bg-gray-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#FF2D20] dark:bg-gray-900 dark:hover:bg-gray-700 dark:focus-visible:ring-white"
        >
            Dashboard
        </Link>

        <template v-else>
            <Link
                :href="route('login')"
                class="rounded-md px-4 py-2 bg-gray-800 text-white transition-colors duration-200 hover:bg-gray-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#FF2D20] dark:bg-gray-900 dark:hover:bg-gray-700 dark:focus-visible:ring-white"
            >
                Log in
            </Link>

            <Link
                v-if="canRegister"
                :href="route('register')"
                class="rounded-md px-4 py-2 bg-gray-800 text-white transition-colors duration-200 hover:bg-gray-700 focus:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 focus-visible:ring-[#FF2D20] dark:bg-gray-900 dark:hover:bg-gray-700 dark:focus-visible:ring-white"
            >
                Register
            </Link>
        </template>
    </nav>
</template>
