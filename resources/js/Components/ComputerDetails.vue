<template>
  <div class="w-full h-screen bg-gray-800">
    <!-- Titre centré -->
    <h2 v-if="selectedComputer" class="text-2xl font-bold text-white mb-4 mt-4 text-center uppercase">
      {{ selectedComputer.computer_name }} [{{ selectedComputer.computer_id }}]
    </h2>
    <h2 v-else class="text-2xl font-bold text-white mb-4 mt-4 text-center uppercase">
      Sélectionnez un ordinateur
    </h2>

    <!-- Zone de sélection d'application centré, 15%:vide 70%:application 15%:vide -->
    <div class="flex h-full">
      <!-- Espace vide à gauche (15%) -->
      <div class="w-1/6"></div>
      
      <!-- Zone principale avec FunctionalitySelector (70%) -->
      <div v-if="selectedComputer" class="w-4/6 flex justify-center items-center h-5/6">
        <FunctionalitySelector 
          :selectedComputer="selectedComputer"
          @connectComputer="connectComputer"
          @openComputerInformation="informationComputer"
          class="w-full h-full"
        />
      </div>
      
      <!-- Espace vide à droite (15%) -->
      <div class="w-1/6"></div>
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

const emit = defineEmits(['connectComputer', 'updateComputer', 'deleteComputer', 'openComputerInformation']);

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

<style scoped>
/* Styles pour rendre les icônes ergonomiques */
.FunctionalitySelector .icon {
  width: 100px;
  height: 100px;
  background-color: #4A5568;
  border-radius: 10px;
  display: flex;
  justify-content: center;
  align-items: center;
}

.icon img {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
}
</style>
