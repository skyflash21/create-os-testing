<script setup>
import { ref } from 'vue';
import { useForm } from '@inertiajs/vue3';
import PrimaryButton from '@/Components/PrimaryButton.vue';
import InputError from '@/Components/InputError.vue';
import InputLabel from '@/Components/InputLabel.vue';
import TextInput from '@/Components/TextInput.vue';
import ActionMessage from '@/Components/ActionMessage.vue';

const props = defineProps({
  todos: Array
});

let form = useForm({
  task: ''
});

const editingTask = ref(null); // Initialize editingTask as null

const handleSubmit = () => {
  if (editingTask.value) {
    form.put(route('todo.update', editingTask.value.id), {
      onSuccess: () => {
        form.reset();
        editingTask.value = null;
      },
      onError: () => {
        console.error('Form submission error:', form.errors);
      },
    });
  } else {
    form.post(route('todo.store'), {
      onSuccess: () => form.reset(),
      onError: () => console.error('Form submission error:', form.errors),
    });
  }
};

const editTask = (task) => {
  editingTask.value = task;
  form.task = task.task;
};

const removeTask = (task) => {
  if (confirm(`Are you sure you want to remove "${task.task}"?`)) {
    form.delete(route('todo.destroy', task.id), {
      onSuccess: () => console.log('Task removed successfully'),
      onError: () => console.error('Task removal error:', form.errors),
    });
  }
};

const moveTaskUp = (index) => {
  if (index > 0) {
    const temp = props.todos[index - 1];
    props.todos[index - 1] = props.todos[index];
    props.todos[index] = temp;
    // Persist the changes in the backend if needed
  }
};

const moveTaskDown = (index) => {
  if (index < props.todos.length - 1) {
    const temp = props.todos[index + 1];
    props.todos[index + 1] = props.todos[index];
    props.todos[index] = temp;
    // Persist the changes in the backend if needed
  }
};
</script>

<template>
  <div>
    <h2 class="text-lg font-semibold">Todo List</h2>

    <ul>
      <li v-for="(todo, index) in props.todos" :key="todo.id" class="mb-2">
        <span>{{ todo.task }}</span>
        <button @click="editTask(todo)" class="ml-2 text-blue-600">Edit</button>
        <button @click="removeTask(todo)" class="ml-2 text-red-600">Remove</button>
        <button @click="moveTaskUp(index)" class="ml-2 text-gray-600">Up</button>
        <button @click="moveTaskDown(index)" class="ml-2 text-gray-600">Down</button>
      </li>
    </ul>

    <div class="mt-6">
      <h2 class="text-lg font-semibold">
        {{ editingTask && editingTask.value ? 'Edit Task' : 'Add a New Task' }}
      </h2>
      <form @submit.prevent="handleSubmit">
        <div class="mb-4">
          <InputLabel for="task" value="Task" />
          <TextInput
            id="task"
            type="text"
            v-model="form.task"
            class="mt-1 block w-full"
            autofocus
          />
          <InputError :message="form.errors.task" class="mt-2" />
        </div>
        <ActionMessage :on="form.recentlySuccessful" class="mt-4">
          {{ editingTask && editingTask.value ? 'Task updated successfully.' : 'Task added successfully.' }}
        </ActionMessage>
        <PrimaryButton :class="{ 'opacity-25': form.processing }" :disabled="form.processing">
          {{ editingTask && editingTask.value ? 'Update Task' : 'Add Task' }}
        </PrimaryButton>
      </form>
    </div>
  </div>
</template>
