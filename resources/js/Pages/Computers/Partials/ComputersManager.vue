<script setup>
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
  personal_access_token_id: ''  // Initialize with an empty string
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

// Handle computer deletion
const destroyComputer = (computerId) => {
  if (confirm('Are you sure you want to delete this computer?')) {
    form.delete(route('computers.destroy', computerId), {
      onSuccess: () => {
        console.log('Computer deleted successfully.');
      },
      onError: () => {
        console.error('Failed to delete the computer:', form.errors);
      },
    });
  }
};

</script>

<template>
  <div>
    <h1 class="text-2xl font-bold mb-6">Computers Manager</h1>

    <!-- Display existing computers with their associated tokens -->
    <div v-if="computers.length > 0" class="space-y-4">
      <div
        v-for="computer in computers"
        :key="computer.computer.id"
        class="flex justify-between items-center p-4 bg-gray-800 text-white rounded-md shadow-md"
      >
        <div>
          <p><strong>Computer ID:</strong> {{ computer.computer.id }}</p>
          <p><strong>Token ID:</strong> {{ computer.personal_access_token.id }}</p>
          <p><strong>Token Name:</strong> {{ computer.personal_access_token.name }}</p>
        </div>
        <div>
          <PrimaryButton @click="destroyComputer(computer.computer.id)" class="bg-red-500 hover:bg-red-600">
            Delete
          </PrimaryButton>
        </div>
      </div>
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
