<template>
  <div class="terminal-container">
    <button class="close-button" @click="close">X</button>
  </div>
</template>

<script setup>
import { ref } from 'vue';
import { defineProps, defineEmits } from 'vue';

const props = defineProps({
  computerId: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['close']);

function close() {
  emit('close');
}
</script>

<style scoped>
.terminal-container {
  position: relative;
  padding: 20px;
  border-radius: 20px;
  background-color: #333;
  width: 90vh;
  height: 90vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-start;
  color: white;
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
  color: #ff5c5c;
}

/* Champ d'entrée pour le texte et le canal */
input[type="number"],
input[type="text"] {
  width: 80%;
  padding: 10px;
  margin: 10px 0;
  border: none;
  border-radius: 10px;
  background-color: #555;
  color: white;
}

button {
  padding: 10px 20px;
  margin-top: 10px;
  border: none;
  border-radius: 10px;
  background-color: #4CAF50;
  color: white;
  cursor: pointer;
}

button:hover {
  background-color: #45a049;
}

/* Conteneur des messages */
.messages-container {
  width: 100%;
  height: 60%;
  background-color: #222;
  padding: 10px;
  margin-top: 20px;
  border-radius: 10px;
  overflow-y: auto;
}

.message {
  background-color: #444;
  padding: 10px;
  margin: 5px 0;
  border-radius: 10px;
  color: white;
}
</style>
