<script setup>
import { ref, onMounted, watch, computed } from "vue";
import { usePage } from "@inertiajs/vue3";

// Ajoutez une prop pour l'ID de l'ordinateur
const props = defineProps({
  computerId: {
    type: Number,
    required: true,
  }
});

// Définir l'événement `emit` pour déclencher l'événement `close`
const emit = defineEmits(['close']);

const page = usePage();

function close() {
    emit('close');
}

</script>

<template>
    <div class="terminal-container">
        <!-- Bouton de fermeture -->
        <button class="close-button" @click="close">X</button>
    </div>
</template>

<style scoped>
.terminal-container {
    position: relative;
    padding: 20px;
    border-radius: 8px;
  background-color: #333;
}

/* Styles pour le bouton de fermeture */
.close-button {
    position: absolute;
    top: 10px;
    right: 10px;
    background: none;
    border: none;
    color: white;
    font-size: 20px;
    cursor: pointer;
}

.close-button:hover {
    color: #ff5c5c; /* Couleur de survol */
}

</style>
