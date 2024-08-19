<script setup>
import { ref } from 'vue';
import { useForm } from '@inertiajs/vue3';
import PrimaryButton from '@/Components/PrimaryButton.vue';
import InputError from '@/Components/InputError.vue';
import InputLabel from '@/Components/InputLabel.vue';
import TextInput from '@/Components/TextInput.vue';
import ActionMessage from '@/Components/ActionMessage.vue';

const props = defineProps({
  computers: Array
});

// Initialize the form with empty values
let form = useForm({
  personal_access_token_id: '2'  // Initialize with an empty string
});

// Handle form submission
const handleSubmit = () => {
  console.log('Current Input Value:', form.personal_access_token_id);  // Log the current value
  form.post(route('computers.store'), {
    onSuccess: () => {
      form.reset();
    },
    onError: () => {
      console.error('Form submission error:', form.errors);
    },
  });
};

</script>

<template>
  <div>
    <h1>Computers Manager</h1>

    <!-- Display existing computers -->
    <div v-if="props.computers.length > 0">
      <ul>
        <li v-for="computer in props.computers" :key="computer.id">
          Computer ID: {{ computer.id }}
        </li>
      </ul>
    </div>
    <div v-else>
      No computers found.
    </div>

    <!-- Form to add a new computer -->
    <div class="mt-6">
      <h2 class="text-lg font-semibold">Add a New Computer</h2>
      <form @submit.prevent="handleSubmit">
        <div class="mb-4">
          <InputLabel for="personal_access_token_id" value="Personal Access Token ID" />
          <TextInput
            id="personal_access_token_id"
            type="text"
            v-model="form.personal_access_token_id"
            class="mt-1 block w-full"
            autofocus
          />
          <InputError :message="form.errors.personal_access_token_id" class="mt-2" />
        </div>
        <ActionMessage :on="form.recentlySuccessful" class="mt-4">
          Computer added successfully.
        </ActionMessage>
        <PrimaryButton :class="{ 'opacity-25': form.processing }" :disabled="form.processing">
          Add Computer
        </PrimaryButton>
      </form>
    </div>
  </div>
</template>
