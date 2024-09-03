<template>
  <div v-if="showTerminal" class="terminal-overlay">
    <div v-if="terminalType === 'terminal'">
      <ComputerCraftTerminal :computerId="computerId" @close="closeTerminal" />
    </div>
  </div>
</template>

<script setup>
import ComputerCraftTerminal from '@/Components/ComputerCraftTerminal.vue';

const props = defineProps({
  showTerminal: Boolean,
  terminalType: String,
  computerId: Number,
});

const emit = defineEmits(['closeTerminal']);

const closeTerminal = () => {
  emit('closeTerminal');
};

console.log('TerminalOverlay component loaded');
</script>

<style scoped>
.terminal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 100;
  display: flex;
  justify-content: center;
  align-items: center;
}

</style>