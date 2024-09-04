<script setup>
import { defineProps, defineEmits, ref, computed } from 'vue';
import PrimaryButton from '@/Components/PrimaryButton.vue';

// Les applications sont définies ici
const applications = ref([
  {
    name: 'Connect SSH',
    icon: '/storage/images/icon_ssh.png',
    action: () => emit('connectComputer')
  },
  {
    name: 'Computer Info',
    icon: '/storage/images/icon_info.png',
    action: () => emit('openComputerInformation')
  },
  {
    name: 'Another App',
    icon: '/storage/images/icon_other.png',
    action: () => alert('Another application action')
  },
]);

const emit = defineEmits(['connectComputer', 'openComputerInformation']);

const searchQuery = ref('');
const currentPage = ref(1);
const itemsPerPage = 16;

const filteredApplications = computed(() => {
  return applications.value.filter(app => 
    app.name.toLowerCase().includes(searchQuery.value.toLowerCase())
  );
});

const paginatedApplications = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage;
  const end = start + itemsPerPage;
  return filteredApplications.value.slice(start, end);
});

const totalPages = computed(() => {
  return Math.ceil(filteredApplications.value.length / itemsPerPage);
});

const nextPage = () => {
  if (currentPage.value < totalPages.value) currentPage.value++;
};

const previousPage = () => {
  if (currentPage.value > 1) currentPage.value--;
};

const hoveredApp = ref('Sélectionnez une application');

const onMouseEnter = (app) => {
  hoveredApp.value = app.name;
};

const onMouseLeave = () => {
  hoveredApp.value = 'Sélectionnez une application';
};
</script>

<template>
  <div class="app-container p-4 bg-red rounded-lg min-h-full">
    <!-- Barre de recherche -->
    <div class="mb-4">
      <input 
        v-model="searchQuery" 
        type="text" 
        placeholder="Rechercher une application..." 
        class="w-full p-2 rounded bg-gray-700 text-white"
      />
    </div>

    <!-- Zone des applications, limitée en hauteur pour laisser de la place à la pagination -->
    <div class="app-grid-container mb-4 flex-grow overflow-auto" style="max-height: 70vh;">
      <div v-for="(app, index) in paginatedApplications" :key="index" class="app-item"
           @mouseenter="onMouseEnter(app)"
           @mouseleave="onMouseLeave"
           @click="app.action">
        <img v-if="app.icon" :src="app.icon" alt="App Icon" class="app-icon" />
        <div v-else class="placeholder-icon">?</div>
        <div class="app-name">{{ app.name }}</div>
      </div>
    </div>

    <!-- Pagination en bas de la page -->
    <div class="flex justify-between mt-4">
      <button 
      @click="previousPage" 
      :disabled="currentPage === 1" 
      class="px-4 py-2 bg-gray-700 text-white rounded hover:bg-gray-600 disabled:opacity-50"
      >
      &larr; Précédent
      </button>
      <button 
      @click="nextPage" 
      :disabled="currentPage === totalPages" 
      class="px-4 py-2 bg-gray-700 text-white rounded hover:bg-gray-600 disabled:opacity-50"
      >
      Suivant &rarr;
      </button>
    </div>
  </div>
</template>

<style scoped>
.app-container {
  background-color: #2d2d2d;
  margin-left: 15%;
  margin-right: 15%;
  display: flex;
  flex-direction: column;
}

.app-grid-container {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
  gap: 10px;
  /* Limite la hauteur de la grille pour permettre le défilement si trop d'applications */
  overflow-y: auto;
}

.app-item {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  background-color: #3a3a3a;
  border-radius: 10px;
  padding: 15px;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  cursor: pointer;
  width: 100px;
  height: 100px;
}

.app-item:hover {
  transform: translateY(-3px);
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
}

.app-icon {
  width: 30px;
  height: 30px;
}

.placeholder-icon {
  font-size: 24px;
  color: #ffffff;
}

.app-name {
  margin-top: 8px;
  font-size: 12px;
  color: #ffffff;
  text-align: center;
}
</style>

