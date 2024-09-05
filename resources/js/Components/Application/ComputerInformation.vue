<script setup>
import { computed, defineProps, defineEmits } from 'vue';

// Ajoutez une prop pour l'ID de l'ordinateur
const props = defineProps({
  computerId: {
    type: Number,
    required: true,
  },
  computer: Object,
});

// Définir l'événement `emit` pour déclencher l'événement `close`
const emit = defineEmits(['close']);

function close() {
  emit('close');
}

const diskUsagePercentage = computed(() => {
  if (!props.computer) return 0;
  return (props.computer.used_disk_space / props.computer.total_disk_space) * 100;
});

const progressBarColor = computed(() => {
  const percentage = diskUsagePercentage.value;
  if (percentage > 80) {
    return '#e74c3c'; // Rouge si l'utilisation est supérieure à 80%
  } else if (percentage > 50) {
    return '#f1c40f'; // Jaune si l'utilisation est entre 50% et 80%
  } else {
    return '#2ecc71'; // Vert si l'utilisation est inférieure à 50%
  }
});

function formatBytes(bytes) {
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
  if (bytes === 0) return '0 Byte';
  const i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)));
  return Math.round(bytes / Math.pow(1024, i), 2) + ' ' + sizes[i];
}

</script>

<template>
  <div class="terminal-container">
    <button class="close-button" @click="close" aria-label="Fermer">✕</button>
    <!-- En-tête avec le titre et le bouton de fermeture -->
    <div class="header">
      <h1 class="title">Informations sur l'ordinateur</h1>
    </div>

    <!-- Informations sur l'ordinateur -->
    <div class="computer-information">
      <!-- Catégorie ID et Nom -->
      <div class="info-category">
        <div class="info-item">
          <span class="info-label">ID de l'ordinateur:</span>
          <span>{{ props.computer.computer_id }}</span>
        </div>
        <div class="info-item">
          <span class="info-label">Nom:</span>
          <span>{{ props.computer.computer_name }}</span>
        </div>
      </div>

      <!-- Catégorie Type, Avancé, Côté Modem -->
      <div class="info-category">
        <div class="info-item">
          <span class="info-label">Type:</span>
          <span>{{ props.computer.type }}</span>
        </div>
        <div class="info-item">
          <span class="info-label">Avancé:</span>
          <span>{{ props.computer.is_advanced ? "Oui" : "Non" }}</span>
        </div>
        <div class="info-item">
          <span class="info-label">Côté Modem Sans Fil:</span>
          <span>{{ props.computer.wireless_modem_side }}</span>
        </div>
      </div>

      <!-- Catégorie Dates -->
      <div class="info-category">
        <div class="info-item">
          <span class="info-label">Dernière Utilisation:</span>
          <span>{{ new Date(props.computer.last_used_at).toLocaleDateString() }}</span>
        </div>
        <div class="info-item">
          <span class="info-label">Créé le:</span>
          <span>{{ new Date(props.computer.created_at).toLocaleDateString() }}</span>
        </div>
      </div>

      <!-- Catégorie Espace disque -->
      <div class="info-category">
        <div class="info-item">
          <span class="info-label">Espace disque utilisé:</span>
          <span>{{ formatBytes(props.computer.used_disk_space) }} / {{ formatBytes(props.computer.total_disk_space) }}</span>
        </div>
        <div class="progress-bar-container">
          <div class="progress-bar" :style="{ width: diskUsagePercentage + '%', backgroundColor: progressBarColor }"></div>
        </div>
        <p class="mt-2 text-sm">{{ diskUsagePercentage.toFixed(2) }}% utilisé</p>
      </div>

      <!-- Description -->
      <div class="info-item description">
        <span class="info-label">Description:</span>
        <p>{{ props.computer.computer_description }}</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.terminal-container {
  position: relative;
  padding: 24px;
  border-radius: 10px;
  background-color: #2c3e50;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
  max-width: 600px;
  margin: auto;
  color: #ecf0f1;
  font-family: 'Roboto', sans-serif;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  height: 80vh; /* Limite la hauteur de l'élément */
}

body {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background-color: #34495e;
  margin: 0;
  padding: 20px;
  box-sizing: border-box;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 10px;
  border: 2px solid #34495e;
  border-radius: 8px;
  background-color: #34495e;
  margin-bottom: 20px;
  margin-top: 20px;
}

.title {
  font-size: 20px;
  font-weight: bold;
}

.close-button {
  background: none;
  border: none;
  color: #ecf0f1;
  font-size: 18px;
  cursor: pointer;
  transition: color 0.3s ease;
  position: absolute;
  top: 10px;
  right: 10px;
}

.close-button:hover {
  color: #e74c3c;
}

/* modern scrollbar */
.computer-information {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding-right: 10px;
  max-height: 50vh; /* Limite la hauteur de la section des informations */
  overflow-y: auto; /* Barre de défilement seulement pour la section des informations */
  scrollbar-width: thin;
  scrollbar-color: #34495e #2c3e50;
}

.info-category {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 12px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 6px;
}

.info-item {
  display: flex;
  justify-content: space-between;
}

.info-label {
  font-weight: bold;
}

.progress-bar-container {
  height: 16px;
  background-color: #bdc3c7;
  border-radius: 8px;
  overflow: hidden;
  margin-top: 8px;
}

.progress-bar {
  height: 100%;
  border-radius: 8px;
  transition: width 0.3s ease;
}

.description {
  flex-direction: column;
  align-items: flex-start;
  background-color: rgba(255, 255, 255, 0.1);
  padding: 12px;
  border-radius: 6px;
}

.description p {
  margin-top: 8px;
  line-height: 1.5;
}

</style>
