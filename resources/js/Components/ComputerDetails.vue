<template>
  <div class="w-2/3 p-4 bg-gray-800 rounded-lg detail-container">
    <h2 class="text-lg font-semibold mb-4 border-b pb-2 text-white">Détails de l'ordinateur</h2>
    <div v-if="selectedComputer" class="info-box">
      <div class="mb-6 text-white">
        <div class="flex justify-between">
          <div>
            <p class="text-lg font-medium">ID de l'ordinateur: {{ selectedComputer.computer_id }}</p>
            <p class="text-sm font-medium">Nom: {{ selectedComputer.computer_name }}</p>
            <p class="text-sm font-medium">Description: {{ selectedComputer.computer_description }}</p>
            <p class="text-sm font-medium">Type: {{ selectedComputer.type }}</p>
            <p class="text-sm font-medium">Avancé: {{ selectedComputer.is_advanced ? "Oui" : "Non" }}</p>
            <p class="text-sm font-medium">Côté Modem Sans Fil: {{ selectedComputer.wireless_modem_side }}</p>
            <p class="text-sm font-medium">Dernière Utilisation: {{ new Date(selectedComputer.last_used_at).toLocaleDateString() }}</p>
            <p class="text-sm font-medium">Créé le: {{ new Date(selectedComputer.created_at).toLocaleDateString() }}</p>
          </div>
          <div>
            <CustomButton type="primary" :disabled="!selectedComputer.isConnected" @click="connectComputer">Connecter</CustomButton>
          </div>
        </div>
        <div class="mt-6">
          <p class="text-lg font-medium">Espace disque utilisé: {{ selectedComputer.used_disk_space }} / {{ selectedComputer.total_disk_space }} bytes</p>
          <div class="h-4 bg-gray-300 rounded">
            <div class="h-full bg-green-500" :style="{ width: diskUsagePercentage + '%' }"></div>
          </div>
          <p class="mt-2 text-sm">{{ diskUsagePercentage.toFixed(2) }}%</p>
        </div>
      </div>
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
          <CustomButton type="primary" :disabled="form.processing" @click="handleSubmit">Mettre à jour l'ordinateur</CustomButton>
          <CustomButton type="danger" :disabled="deleteForm.processing" @click="initiateDelete">Supprimer l'ordinateur</CustomButton>
        </div>
      </form>
    </div>
    <div v-else class="text-white">
      <p>Aucun ordinateur sélectionné. Cliquez sur un ordinateur dans la liste pour voir les détails.</p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watchEffect } from 'vue';
import { useForm } from '@inertiajs/vue3';
import CustomButton from '@/Components/CustomButton.vue';
import InputLabel from '@/Components/InputLabel.vue';
import TextInput from '@/Components/TextInput.vue';
import InputError from '@/Components/InputError.vue';

const props = defineProps({
  selectedComputer: Object,
});

const emit = defineEmits(['connectComputer', 'updateComputer', 'deleteComputer']);

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

watchEffect(() => {
  if (props.selectedComputer) {
    form.id = props.selectedComputer.computer_id;
    form.name = props.selectedComputer.computer_name;
    form.description = props.selectedComputer.computer_description;
  }
});

const handleSubmit = () => {
  emit('updateComputer', form);
};

const initiateDelete = () => {
  emit('deleteComputer', form.id);
};

const connectComputer = () => {
  emit('connectComputer');
};

const diskUsagePercentage = computed(() => {
  if (!props.selectedComputer) return 0;
  return (props.selectedComputer.used_disk_space / props.selectedComputer.total_disk_space) * 100;
});
</script>
