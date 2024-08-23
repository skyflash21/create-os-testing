<script setup>
import { ref } from 'vue';

const computer_icon = ref('/storage/Documentation/ComputerLogo.png');
const create_icon = ref('/storage/Documentation/CreateLogo.png');
</script>

<template>
  <div class="flex flex-wrap justify-center mt-2">
    <div class="flex flex-col items-center space-y-1 mx-2 transition-transform duration-300 hover:scale-125">
      <img :src=computer_icon class="w-12 h-12" alt="Computer Icon" />
      <span class="text-sm font-semibold text-center text-white">Installation</span>
    </div>
    <div class="flex flex-col items-center space-y-1 mx-2 transition-transform duration-300 hover:scale-125">
      <img :src=create_icon class="w-12 h-12" alt="Computer Icon" />
      <span class="text-sm font-semibold text-center text-white">Create</span>
    </div>
  </div>
</template>

<style>
/* Si nécessaire, ajoute des styles spécifiques ici */
</style>
