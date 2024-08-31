<script setup>
import { ref, computed, onMounted } from 'vue';
import { useForm } from '@inertiajs/vue3';
import PrimaryButton from '@/Components/PrimaryButton.vue';
import DangerButton from '@/Components/DangerButton.vue';
import InputError from '@/Components/InputError.vue';
import InputLabel from '@/Components/InputLabel.vue';
import TextInput from '@/Components/TextInput.vue';
import CustomButton from '@/Components/CustomButton.vue';
import ConfirmationModal from '@/Components/ConfirmationModal.vue';

const props = defineProps({
  computers: Array,
});

const selectedComputer = ref(null);
const showModal = ref(false);

const connectedComputers = ref([]); // State to manage connected computers

const form = useForm({
  _method: 'PUT',
  id: '',
  name: '',
  description: '',
});

const deleteForm = useForm({
  _method: 'DELETE',
  id: '',
});

const selectComputer = (computer) => {
  selectedComputer.value = computer;
  form.id = computer.computer_id;
  form.name = computer.computer_name;
  form.description = computer.computer_description;
};

const handleSubmit = () => {
  form.put(route('computers.update', form.id), {
    onSuccess: () => {
      selectedComputer.value = { ...selectedComputer.value, ...form };
    },
    onError: () => {
      console.error('Form submission error:', form.errors);
    },
  });
};

const initiateDelete = () => {
  showModal.value = true;
};

const confirmDelete = () => {
  deleteForm.delete(route('computers.destroy', form.id), {
    onSuccess: () => {
      selectedComputer.value = null;
      props.computers = props.computers.filter(computer => computer.computer_id !== form.id);
      form.reset();
      showModal.value = false;
    },
    onError: () => {
      console.error('Form submission error:', deleteForm.errors);
    },
  });
};

const cancelDelete = () => {
  showModal.value = false;
};

// State for sorting
const sortKey = ref('id');
const sortOrder = ref('asc');

// Computed property to sort computers
const sortedComputers = computed(() => {
  const sorted = [...props.computers].sort((a, b) => {
    if (sortKey.value === 'id') {
      return sortOrder.value === 'asc' ? a.computer_id - b.computer_id : b.computer_id - a.computer_id;
    } else if (sortKey.value === 'name') {
      return sortOrder.value === 'asc'
        ? a.computer_name.localeCompare(b.computer_name)
        : b.computer_name.localeCompare(a.computer_name);
    }
  });

  return sorted.map(computer => ({
    ...computer,
    truncated_name: computer.computer_name.length > 9 
      ? `${computer.computer_name.slice(0, 6)}...` 
      : computer.computer_name,
    isConnected: connectedComputers.value.includes(computer.computer_id) // Check if the computer is connected
  }));
});

const sortBy = (key) => {
  if (sortKey.value === key) {
    // No change in sortOrder if same key is selected
  } else {
    sortKey.value = key;
  }
};

const toggleSortOrder = () => {
  sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
};

const getButtonClass = (key) => {
  return {
    'px-3 py-1 text-gray-400 hover:text-white border-none rounded': true,
    'text-white': sortKey.value === key,
  };
};


// Listen to the global events
onMounted(() => {
  window.addEventListener('computer_list', (event) => {
    let $computerList = event.detail;
    // Only include computers where isUser is false
    connectedComputers.value = $computerList.filter(computer => !computer.isUser).map(computer => computer.id);
  });

  window.addEventListener('computer_add', (event) => {
    console.log('Computer added:', event.detail);

    // If isUser is false, add the computer to the connectedComputers list
    if (!event.detail.isUser) {
      connectedComputers.value = [...connectedComputers.value, event.detail.id];
    }
  });

  window.addEventListener('computer_remove', (event) => {
    console.log('Computer removed:', event.detail);

    // If isUser is false, remove the computer from the connectedComputers list
    if (!event.detail.isUser) {
      connectedComputers.value = connectedComputers.value.filter(id => id !== event.detail.id);
    }
  });
});
</script>




<style scope>

/* Style pour les zones des ordinateurs et des détails */
.bg-gray-800 {
  background-color: #2d3748; /* Couleur de fond gris foncé */
}

.bg-gray-700 {
  background-color: #4a5568; /* Couleur de fond gris encore plus foncé */
}

.border-r {
  border-right: 1px solid #4a5568; /* Bordure droite gris foncé */
}

.rounded-lg {
  border-radius: 0.75rem; /* Coins plus arrondis */
}

.shadow-lg {
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.5); /* Ombre plus marquée pour effet moderne */
}

.max-h-[calc(100vh-8rem)] {
  max-height: calc(100vh - 8rem); /* Hauteur maximale pour les détails */
}

.overflow-y-auto {
  overflow-y: auto; /* Défilement vertical automatique */
}

/* Styles spécifiques pour les zones */
.list-container {
  background: linear-gradient(180deg, rgba(45, 51, 72, 0.8) 0%, rgba(45, 51, 72, 0.5) 100%);
  border: 1px solid #4a5568;
}

.detail-container {
  background: linear-gradient(180deg, rgba(45, 51, 72, 0.8) 0%, rgba(45, 51, 72, 0.5) 100%);
  border: 1px solid #4a5568;
}

/* Styles pour les zones d'info avec des bordures arrondies */
.info-box {
  background-color: #1a202c; /* Arrière-plan très sombre */
  border: 1px solid #2d3748; /* Bordure légèrement plus claire */
  border-radius: 0.75rem; /* Coins arrondis */
  padding: 1.5rem;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.3); /* Ombre subtile */
}

.scrollbar-custom {
  scrollbar-width: thin; /* Taille de la barre de défilement (pour Firefox) */
  scrollbar-color: #4a5568 #2d3748; /* Couleur de la barre et de la piste (pour Firefox) */
}

/* Pour Webkit (Chrome, Safari) */
.scrollbar-custom::-webkit-scrollbar {
  width: 8px; /* Largeur de la barre de défilement */
}

.scrollbar-custom::-webkit-scrollbar-track {
  background: #2d3748; /* Couleur de la piste de défilement */
  border-radius: 10px; /* Coins arrondis de la piste */
}

.scrollbar-custom::-webkit-scrollbar-thumb {
  background: #4a5568; /* Couleur de la barre de défilement */
  border-radius: 10px; /* Coins arrondis de la barre */
}

.scrollbar-custom::-webkit-scrollbar-thumb:hover {
  background: #6b7280; /* Couleur de la barre au survol */
}

/* Badge pour l'état des ordinateurs */
.computer-badge {
  position: absolute;
  bottom: 8px;
  right: 8px;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background-color: #00ff00; /* Couleur par défaut pour connecté */
}

.computer-badge.disconnected {
  background-color: #ff0000; /* Couleur pour déconnecté */
}

.computer-badge.selected {
  background-color: #ffa500; /* Couleur pour sélectionné */
}



</style>

<template>
  <div class="flex h-screen p-6 bg-gray-900">
    <!-- Liste des ordinateurs -->
    <div class="w-1/2 p-2 border-r bg-gray-800 rounded-lg">
      <h2 class="text-lg font-semibold mb-4 border-b pb-2 text-white">Liste des ordinateurs</h2>

      <!-- Contrôles de tri -->
      <div class="mb-4 flex space-x-2">
        <button 
          @click="sortBy('id')" 
          :class="getButtonClass('id')">
          Trier par ID
        </button>
        <button 
          @click="sortBy('name')" 
          :class="getButtonClass('name')">
          Trier par Nom
        </button>
        <button 
          @click="toggleSortOrder" 
          class="px-3 py-1 text-gray-400 hover:text-white border-none rounded">
          {{ sortOrder.value === 'asc' ? 'Croissant' : 'Décroissant' }}
        </button>
      </div>

      <div class="grid grid-cols-3 p-2 gap-5 overflow-y-auto overflow-x-hidden scrollbar-custom max-h-[calc(100vh-10rem)]">
        <div
          v-for="computer in sortedComputers"
          :key="computer.computer_id"
          @click="selectComputer(computer)"
          :class="[
            'relative flex flex-col items-center space-y-2 transition-transform duration-150 hover:scale-105 cursor-pointer p-2 rounded-lg shadow-lg',
            {
              'bg-gray-600 border-orange-500 border-4': selectedComputer && selectedComputer.computer_id === computer.computer_id,
              'bg-gray-700 border-gray-700 border-4': !(selectedComputer && selectedComputer.computer_id === computer.computer_id)
            }
          ]"
        >
          <img src="/storage/Documentation/ComputerLogo.png" class="w-10 h-10" alt="Computer Icon" />
          <span class="text-sm font-semibold text-center text-white">
            {{ computer.computer_id }} : {{ computer.truncated_name }}
          </span>
          
          <!-- Badge pour l'état de l'ordinateur -->
          <div 
            class="absolute bottom-2 right-2 w-3 h-3 rounded-full"
            :class="{
              'bg-green-500': computer.isConnected,
              'bg-red-500': !computer.isConnected,
            }"
          ></div>
        </div>
      </div>
    </div>

    <!-- Détails et modification -->
    <!-- Détails et modification -->
    <div class="w-2/3 p-4 bg-gray-800 rounded-lg detail-container">
      <h2 class="text-lg font-semibold mb-4 border-b pb-2 text-white">Détails de l'ordinateur</h2>

      <div v-if="selectedComputer" class="info-box">
        <!-- Détails non modifiables -->
        <div class="mb-6 text-white">
          <p class="text-lg font-medium">ID de l'ordinateur: {{ selectedComputer.computer_id }}</p>
          <p class="text-sm font-medium">Nom: {{ selectedComputer.computer_name }}</p>
          <p class="text-sm font-medium">Description: {{ selectedComputer.computer_description }}</p>
          <p class="text-sm font-medium">Type: {{ selectedComputer.type }}</p>
          <p class="text-sm font-medium">Avancé: {{ selectedComputer.is_advanced ? 'Oui' : 'Non' }}</p>
          <p class="text-sm font-medium">Côté Modem Sans Fil: {{ selectedComputer.wireless_modem_side }}</p>
          <p class="text-sm font-medium">Dernière Utilisation: {{ new Date(selectedComputer.last_used_at).toLocaleDateString() }}</p>
          <p class="text-sm font-medium">Créé le: {{ new Date(selectedComputer.created_at).toLocaleDateString() }}</p>
          
          <!-- Progress bar -->
          <div class="mt-6">
            <p class="text-lg font-medium">Espace disque utilisé: {{ selectedComputer.used_disk_space }} / {{ selectedComputer.total_disk_space }} bytes</p>
            <div class="h-4 bg-gray-300 rounded">
              <div class="h-full bg-green-500" :style="{ width: (selectedComputer.used_disk_space / selectedComputer.total_disk_space) * 100 + '%' }"></div>
            </div>
            <p class="mt-2 text-sm">{{ ((selectedComputer.used_disk_space / selectedComputer.total_disk_space) * 100).toFixed(2) }}%</p>
          </div>
        </div>

        <!-- Formulaire modifiable -->
        <form @submit.prevent="handleSubmit">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <InputLabel for="name" value="Nom" />
              <TextInput v-model="form.name" id="name" type="text" class="mt-1 block w-full" required />
              <InputError :message="form.errors.name" class="mt-2 text-red-500" />
            </div>
            <div>
              <InputLabel for="description" value="Description" />
              <TextInput v-model="form.description" id="description" type="text" class="mt-1 block w-full" />
              <InputError :message="form.errors.description" class="mt-2 text-red-500" />
            </div>
          </div>
          <div class="mt-6 flex justify-end space-x-4">
            <!-- Bouton de mise à jour -->
            <CustomButton type="primary" :disabled="form.processing">
              Mettre à jour l'ordinateur
            </CustomButton>

            <!-- Bouton de suppression -->
            <CustomButton type="danger" :disabled="deleteForm.processing" @click="initiateDelete">
              Supprimer l'ordinateur
            </CustomButton>
          </div>
        </form>
      </div>

      <div v-else class="text-white">
        <p>Aucun ordinateur sélectionné. Cliquez sur un ordinateur dans la liste pour voir les détails.</p>
      </div>
    </div>

    <!-- Confirmation Modal -->
    <ConfirmationModal
      v-model:show="showModal"
      max-width="sm"
      @close="cancelDelete"
    >
      <template #title>
        Confirmation de la suppression
      </template>
      <template #content>
        <p>Êtes-vous sûr de vouloir supprimer cet ordinateur ? Cette action est irréversible.</p>
      </template>
      <template #footer>
        <button @click="cancelDelete" class="px-4 py-2 bg-gray-500 text-white rounded ml-2">Annuler</button>
        <button @click="confirmDelete" class="px-4 py-2 bg-red-600 text-white rounded ml-2">Supprimer</button>
      </template>
    </ConfirmationModal>
  </div>
</template>
