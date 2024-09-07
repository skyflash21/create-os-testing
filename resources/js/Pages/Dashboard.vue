<script setup>
import AppLayout from '@/Layouts/AppLayout.vue';

// Définition des données de tâches dans le script setup
// Niveau de priorité: "Haute", "Moyenne", "Basse"
const tasks = [
  { 
    name: 'Anti Piratage', 
    description: `Terminer le système de prévention de double connection et trouver un moyen de le faire coté serveur.`, 
    priority: 'Haute' 
  }
];

// Fonction pour obtenir la classe CSS en fonction de la priorité
const getPriorityClass = (priority) => {
  if (priority === 'Haute') {
    return 'high-priority';
  } else if (priority === 'Moyenne') {
    return 'medium-priority';
  } else {
    return 'low-priority';
  }
};
</script>

<template>
  <AppLayout title="Liste de Tâches">
    <div>
      <h1 class="text-2xl font-bold m-4 text-center text-white">Liste de Tâches</h1>
      <div v-for="task in tasks" :key="task.name" class="task border rounded text-sm text-white bg-gray-800">
        <h2>{{ task.name }}</h2>
        <p>{{ task.description }}</p>
        <p>Priorité: 
          <span :class="getPriorityClass(task.priority)">
            {{ task.priority }}
          </span>
        </p>
      </div>
    </div>
  </AppLayout>
</template>

<style scoped>
.task {
  border: 1px solid #ddd;
  padding: 10px;
  margin: 15px;
}

.high-priority {
  color: red;
}

.medium-priority {
  color: orange;
}

.low-priority {
  color: green;
}
</style>
