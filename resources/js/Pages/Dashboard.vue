<template>
    <AppLayout title="Dashboard">
        <template #header></template>
        <div
            class="sidebar"
            :class="{ 'sidebar-visible': sidebarVisible, 'sidebar-hidden': !sidebarVisible }"
            @transitionend="onSidebarTransitionEnd"
            v-show="true">
            <div class="sidebar-content">
                <p>Contenu de la barre latérale.</p>
            </div>

            <!-- Languette cliquable pour ouvrir/fermer la sidebar -->
            <div class="sidebar-tab" @click="toggleSidebar" :disabled="sidebarAnimating">
                <img :src="computer_icon" alt="Computer" />
            </div>
        </div>
    </AppLayout>
</template>

<script setup>
import { ref } from 'vue';
import { usePage } from "@inertiajs/vue3";
import AppLayout from '@/Layouts/AppLayout.vue';

const page = usePage();
const sidebarVisible = ref(false); // État de la visibilité de la sidebar
const sidebarAnimating = ref(false); // Suivi du statut de l'animation (utilisé pour la transition)

const toggleSidebar = () => {
    sidebarAnimating.value = true;
    sidebarVisible.value = !sidebarVisible.value;
};

// Fonction appelée lorsque la transition se termine
const onSidebarTransitionEnd = () => {
    sidebarAnimating.value = false;
};

const computer_icon = ref('/storage/Documentation/computer.png');
</script>

<style scoped>
@media (max-width: 768px) {
    .btn {
        right: 1em;
    }
}

/* Style de base pour le layout */
.content {
    padding: 20px;
}

/* Sidebar */
.sidebar {
    position: fixed;
    right: 0;
    width: 300px;
    height: 100%;
    background-color: #f4f4f4;
    box-shadow: -2px 0 5px rgba(0, 0, 0, 0.1);
    transition: transform 0.3s ease-in-out;
    transform: translateX(100%); /* Par défaut, la sidebar est hors écran */
}

/* Afficher la sidebar */
.sidebar-visible {
    transform: translateX(0%);
}

/* Cacher la sidebar, mais garder la languette à 5% */
.sidebar-hidden {
    transform: translateX(100%);
}

/* Languette pour ouvrir/fermer la sidebar */
.sidebar-tab {
    position: absolute;
    top: 50%;
    right: 100%; /* Positionne la languette juste à côté de la sidebar */
    width: 60px;
    height: 60px;
    background-color: #ccc;
    color: #000;
    text-align: center;
    line-height: 60px;
    cursor: pointer;
    transform: translateY(-50%);
    border-radius: 5px 0 0 5px;
    box-shadow: -2px 0 5px rgba(0, 0, 0, 0.1);
    padding: 10px;

    display: flex;
    justify-content: center;

}

.sidebar-tab:hover {
    background-color: #aaa;
}
</style>
