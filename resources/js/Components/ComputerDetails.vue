<template>
  <div class="w-2/3 p-4 bg-gray-800 rounded-lg detail-container">
    <h2 class="text-lg font-semibold mb-4 border-b pb-2 text-white">
      Détails de l'ordinateur [{{ selectedComputer.computer_id }}:{{ selectedComputer.computer_name }}] 
    </h2>
    <div v-if="selectedComputer" class="info-box">
      
      <!-- Utilisation du FunctionalitySelector avec espace réservé -->
      <div class="rounded-lg p-4 mb-4">
        <FunctionalitySelector 
          :selectedComputer="selectedComputer" 
          @connectComputer="connectComputer" 
          @openComputerInformation="informationComputer" 
        />
      </div>
      
      <!-- Formulaire pour les détails de l'ordinateur -->
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
import { ref, watchEffect } from 'vue';
import { useForm } from '@inertiajs/vue3';
import CustomButton from '@/Components/CustomButton.vue';
import InputLabel from '@/Components/InputLabel.vue';
import TextInput from '@/Components/TextInput.vue';
import InputError from '@/Components/InputError.vue';
import FunctionalitySelector from '@/Components/AppSelector.vue';

const props = defineProps({
  selectedComputer: Object,
});

const emit = defineEmits(['connectComputer', 'updateComputer', 'deleteComputer' , 'openComputerInformation']);

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

const informationComputer = () => {
  emit('openComputerInformation');
};
</script>
