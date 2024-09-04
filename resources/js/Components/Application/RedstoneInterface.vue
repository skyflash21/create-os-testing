<script setup>
import { computed, defineProps, defineEmits, ref } from 'vue';
import PrimaryButton from '@/Components/PrimaryButton.vue';

const props = defineProps({
    computerId: Number,
});

const emit = defineEmits(['close']);

function close() {
  emit('close');
}

const test = () => {
    console.log('Test');
};

const sides = ['Face', 'Arrière', 'Gauche', 'Droite', 'Haut', 'Bas']; // Les 6 côtés du cube
const sliderValue = ref(0); // Valeur du curseur
</script>

<template>
    <div class="terminal-container">
        <!-- Bouton de fermeture -->
        <button class="close-button" @click="close">X</button>

        <!-- Titre -->
        <h1 class="title">Redstone Interface</h1>

        <!-- Boutons pour choisir les côtés du cube -->
        <div class="buttons-container">
            <PrimaryButton v-for="(side, index) in sides" :key="index" @click="test">{{ side }}</PrimaryButton>
        </div>

        <!-- Curseur avec la valeur indiquée -->
        <div class="slider-container">
            <input type="range" min="0" max="15" v-model="sliderValue" class="slider" />
            <div class="slider-value">Valeur : {{ sliderValue }}</div>
        </div>
    </div>
</template>

<style scoped>
.terminal-container {
    position: relative;
    padding: 20px;
    border-radius: 20px;
    background-color: #333;
    width: 80%;
    height: 90%;
    margin: auto;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
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

/* Styles pour le titre */
.title {
    color: white;
    margin-bottom: 20px;
}

/* Conteneur des boutons pour les côtés */
.buttons-container {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 10px;
    margin-bottom: 20px;
}

/* Styles du conteneur du slider */
.slider-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    margin-top: 20px;
}

/* Styles pour le slider */
.slider {
    width: 300px;
    margin-bottom: 10px;
}

/* Affichage de la valeur du slider */
.slider-value {
    color: white;
    font-size: 18px;
}
</style>
