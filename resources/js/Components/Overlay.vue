<template>
  <div v-if="showTerminal" class="terminal-overlay">
    <div v-if="terminalType === 'openConnectComputer'">
      <ComputerCraftTerminal :computerId="computerId" :is_advanced="computer.is_advanced" @close="closeTerminal" />
    </div>
    <div v-else-if="terminalType === 'openRedstoneInterface'">
      <RedstoneInterface :computerId="computerId" @close="closeTerminal" />
    </div>
    <div v-else-if="terminalType === 'openComputerInformation'">
      <ComputerInformation :computerId="computerId" :computer="computer" @close="closeTerminal" />
    </div>
    <div v-else-if="terminalType === 'openRedNetInterface'">
      <RedNet :computerId="computerId" :computer="computer" @close="closeTerminal" />
    </div>
  </div>
</template>

<script setup>
import ComputerCraftTerminal from '@/Components/Application/ComputerCraftTerminal.vue';
import RedstoneInterface from '@/Components/Application/RedstoneInterface.vue';
import ComputerInformation from '@/Components/Application/ComputerInformation.vue';
import RedNet from './Application/RedNet.vue';

const props = defineProps({
  showTerminal: Boolean,
  terminalType: String,
  computerId: Number,
  computer: Object,
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