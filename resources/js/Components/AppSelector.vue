<script setup>
import { defineProps, defineEmits, ref, computed } from 'vue';

const applications = ref([
  {
    name: 'Connection',
    icon: '/storage/Documentation/computer.png',
    action: () => emit('open_interface','openConnectComputer')
  },
  {
    name: 'Information',
    icon: '/storage/images/book.png',
    action: () => emit('open_interface','openComputerInformation')
  },
  {
    name: 'Redstone',
    icon: '/storage/images/redstone.png',
    action: () => emit('open_interface','openRedstoneInterface')
  },
  {
    name: 'Rednet',
    icon: '/storage/images/EnderModem.png',
    action: () => alert('open_interface')
  },
]);

const emit = defineEmits(['connectComputer', 'openComputerInformation']);

const searchQuery = ref('');

const filteredApplications = computed(() => {
  return applications.value.filter(app => 
    app.name.toLowerCase().includes(searchQuery.value.toLowerCase())
  );
});

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
    <div>
      <input 
        v-model="searchQuery" 
        type="text" 
        placeholder="Rechercher une application..." 
        class="w-full p-2 rounded bg-gray-700 text-white"
      />
    </div>

    <!-- Zone des applications avec scroll bar -->
    <div class="app-grid-container ">
      <div v-for="(app, index) in filteredApplications" :key="index" class="app-item"
           @mouseenter="onMouseEnter(app)"
           @mouseleave="onMouseLeave"
           @click="app.action">
        <img v-if="app.icon" :src="app.icon" alt="App Icon" class="app-icon" />
        <div v-else class="placeholder-icon">?</div>
        <div class="app-name">{{ app.name }}</div>
      </div>
    </div>
  </div>
</template>
<style scoped>
.app-container {
  background-color: #2d2d2d;
  margin-left: auto;
  margin-right: auto;
  display: flex;
  flex-direction: column;
  max-width: 80%; /* Limite la largeur à 80% de l'écran */
}

.app-grid-container {
  padding: 10px;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(90px, 1fr));
  grid-gap: 10px; /* Add a gap between the items for spacing */
  justify-items: center;
  align-items: center;
  overflow-y: auto;
  scrollbar-width: thin;
  scrollbar-color: #888 #2d2d2d; /* Thumb color and track color */
}

.app-item {
  width: 90px;
  height: 90px;
  flex-shrink: 0; /* Prevents shrinking of items */
  box-sizing: border-box; /* Ensures padding and border are included in width/height */
  background-color: #3a3a3a;
  border-radius: 10px;
}


.app-item:hover {
  transform: translateY(-3px);
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
  cursor: pointer;
}

.app-icon {
  width: 50px;
  height: 50px;
  display: block;
  margin-left: auto;
  margin-right: auto;
  margin-top: 10px;
  margin-bottom: 10px;

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
