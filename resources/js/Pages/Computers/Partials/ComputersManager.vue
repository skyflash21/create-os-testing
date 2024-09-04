<template>
  <div class="flex h-screen p-6 bg-gray-900">
    <ComputerList
      :computers="computers"
      :selectedComputer="selectedComputer"
      :connectedComputers="connectedComputers"
      :computer_logo="computer_logo"
      :advanced_computer_logo="advanced_computer_logo"
      @selectComputer="selectComputer"
      @sortBy="sortBy"
      @toggleSortOrder="toggleSortOrder"
    />
    <ComputerDetails
      :selectedComputer="selectedComputer"
      @connectComputer="connectComputer"
      @openComputerInformation="openComputerInformation"
      @updateComputer="handleSubmit"
      @deleteComputer="initiateDelete"
    />
    <Overlay
      class="overlay"
      v-if="showTerminal"
      :computerId="selectedComputer?.computer_id"
      :showTerminal="showTerminal"
      :terminalType="interfaceType"
      :computer="selectedComputer"
      @closeTerminal="showTerminal = false"
    />
    <ConfirmationModal v-model:show="showModal" max-width="sm" @close="cancelDelete">
      <template #title> Confirmation de la suppression </template>
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

<script setup>
import { ref, onMounted } from 'vue';
import ComputerList from '@/Components/ComputerList.vue';
import ComputerDetails from '@/Components/ComputerDetails.vue';
import Overlay from '@/Components/Overlay.vue';
import ConfirmationModal from '@/Components/ConfirmationModal.vue';

const props = defineProps({
  computers: Array,
});

const computer_logo = ref('/storage/Documentation/computer.png');
const advanced_computer_logo = ref('/storage/Documentation/advanced_computer.png');
const showTerminal = ref(false);
const interfaceType = ref('terminal');
const showModal = ref(false);
const selectedComputer = ref(null);
const connectedComputers = ref([]);
const sortKey = ref('id');
const sortOrder = ref('asc');

const selectComputer = (computer) => {
  selectedComputer.value = computer;
};

const handleSubmit = (form) => {
  form.put(route('computers.update', form.id), {
    onSuccess: () => {
      selectedComputer.value = { ...selectedComputer.value, ...form };
    },
    onError: () => {
      console.error('Form submission error:', form.errors);
    },
  });
};

const initiateDelete = (id) => {
  showModal.value = true;
};

const cancelDelete = () => {
  showModal.value = false;
};

const confirmDelete = () => {
  deleteForm.delete(route('computers.destroy', selectedComputer.value.id), {
    onSuccess: () => {
      selectedComputer.value = null;
      props.computers = props.computers.filter((computer) => computer.computer_id !== selectedComputer.value.id);
      showModal.value = false;
    },
    onError: () => {
      console.error('Form submission error:', deleteForm.errors);
    },
  });
};

const connectComputer = () => {
  if (selectedComputer.value) {
    showTerminal.value = true;
    interfaceType.value = "terminal";
  }
};

const openComputerInformation = () => {
  if (selectedComputer.value) {
    showTerminal.value = true;
    interfaceType.value = "information";
    console.log('Computer information opened');
  }
};

const sortBy = (key) => {
  sortKey.value = key;
};

const toggleSortOrder = () => {
  sortOrder.value = sortOrder.value === 'asc' ? 'desc' : 'asc';
};

onMounted(() => {
  window.addEventListener('computer_list', (event) => {
    let $computerList = event.detail;
    connectedComputers.value = $computerList.filter((computer) => !computer.isUser).map((computer) => computer.id);
  });

  window.addEventListener('computer_add', (event) => {
    if (!event.detail.isUser) {
      connectedComputers.value = [...connectedComputers.value, event.detail.id];
    }
  });

  window.addEventListener('computer_remove', (event) => {
    if (!event.detail.isUser) {
      connectedComputers.value = connectedComputers.value.filter((id) => id !== event.detail.id);
    }

    if (selectedComputer.value && selectedComputer.value.computer_id === event.detail.id) {
      selectedComputer.value = null;
      showTerminal.value = false;
      alert(`L'ordinateur ${event.detail.id} a été déconnecté.`);
    }
  });

  window.addEventListener('computer_registered', () => {
    window.location.reload();
  });

  const temp_connectedComputers = JSON.parse(localStorage.getItem('connectedComputers'));
  if (temp_connectedComputers) {
    for (let i = 0; i < temp_connectedComputers.length; i++) {
      connectedComputers.value = [...connectedComputers.value, temp_connectedComputers[i].id];
    }
  }
});
</script>

<style scoped>
.overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
  z-index: 1000;
}
</style>