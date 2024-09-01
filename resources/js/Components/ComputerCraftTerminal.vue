<template>
  <div>
    <div class="grid-container">
      <div
        class="grid"
        @keydown="handleKeydown"
        tabindex="0"
      >
        <div
          v-for="(cell, index) in grid"
          :key="index"
          :style="{ backgroundColor: cell.backgroundColor, color: cell.textColor }"
          class="cell"
        >
          {{ cell.char }}
        </div>
      </div>
    </div>
    
    <div class="controls">
      <div class="color-control" @click="selectTextColor">
        <span>Text Color</span>
        <div class="color-preview" :style="{ backgroundColor: textColor }"></div>
      </div>
      <div class="color-control" @click="selectBackgroundColor">
        <span>Background Color</span>
        <div class="color-preview" :style="{ backgroundColor: backgroundColor }"></div>
      </div>
    </div>

    <div class="palette">
      <div
        v-for="color in paletteColors"
        :key="color"
        :style="{ backgroundColor: color }"
        class="color-swatch"
        @click="changeColor(color)"
      ></div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';

const rows = 19;
const cols = 51;

function createGrid() {
  const grid = [];
  for (let i = 0; i < rows * cols; i++) {
    grid.push({
      char: String.fromCharCode(0x9f),  // Utilisez ici le code du caractère spécifique que vous souhaitez
      textColor: '#FFFFFF', // Couleur du texte
      backgroundColor: '#000000', // Couleur de fond
    });
  }
  return grid;
}

const grid = ref(createGrid());
const currentIndex = ref(0);

const textColor = ref('#FFFFFF');
const backgroundColor = ref('#000000');
const selectedColorType = ref('text');

const paletteColors = ref([
  '#FFFFFF', '#000000', '#FF0000', '#00FF00', '#0000FF',
  '#FFFF00', '#FF00FF', '#00FFFF', '#808080', '#800000'
]);

function handleKeydown(event) {
  const validChars = /^[a-zA-Z0-9\s!"#$%&'()*+,-./:;<=>?@[\\\]^_`{|}~]$/;

  if (validChars.test(event.key)) {
    if (currentIndex.value >= 0 && currentIndex.value < grid.value.length) {
      grid.value[currentIndex.value].char = event.key;
      grid.value[currentIndex.value].textColor = textColor.value;
      grid.value[currentIndex.value].backgroundColor = backgroundColor.value;

      // Move to the next cell
      if ((currentIndex.value + 1) % cols !== 0) {
        currentIndex.value += 1;
      } else {
        currentIndex.value += cols - ((currentIndex.value + 1) % cols);
      }
    }
  } else {
    event.preventDefault();
  }
}

function selectTextColor() {
  selectedColorType.value = 'text';
}

function selectBackgroundColor() {
  selectedColorType.value = 'background';
}

function changeColor(color) {
  if (selectedColorType.value === 'text') {
    textColor.value = color;
  } else if (selectedColorType.value === 'background') {
    backgroundColor.value = color;
  }
}
</script>

<style scoped>
.grid-container {
  margin-top: 20px;
  overflow: hidden;
  width: fit-content; /* Adjust to the content */
  height: fit-content; /* Adjust to the content */
}

@font-face {
  font-family: 'CustomFont';
  src: url('/storage/fonts/HDfont.ttf') format('truetype');
}

.grid {
  display: grid;
  grid-template-columns: repeat(51, 10px);
  grid-template-rows: repeat(19, 16px);
  margin: 0; /* Remove any default margins */
  border: 10px solid #B0B03F;
  background-color: #000000;
  outline: none;
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
  border-radius: 5px;
  user-select: none; /* Disable text selection */
  overflow: hidden; /* Ensure content does not overflow */
}


.cell {
  width: 10px;  /* Correspond à la largeur d'un caractère */
  height: 16px; /* Ajustement de la hauteur pour éliminer le gap */
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 16px;  /* Ajustez cette valeur pour que le caractère remplisse mieux la cellule */
  font-family: 'CustomFont', monospace;
  color: #FFFFFF;
  background-color: #000000;
  line-height: 16px; /* Alignement de la hauteur de ligne à celle de la cellule */
  padding: 0;
  margin: 0;
  vertical-align: middle; /* Assure un alignement vertical au centre */
}



.controls {
  display: flex;
  margin-top: 20px;
  justify-content: center;
  gap: 20px;
}

.color-control {
  display: flex;
  align-items: center;
  cursor: pointer;
}

.color-control span {
  margin-right: 10px;
  font-size: 16px;
  font-weight: bold;
  color: #FFFFFF;
}

.color-preview {
  width: 30px;
  height: 30px;
  border: 2px solid #888;
  border-radius: 5px;
}

.palette {
  display: flex;
  flex-wrap: wrap;
  margin-top: 20px;
  justify-content: center;
  gap: 10px;
}

.color-swatch {
  width: 40px;
  height: 40px;
  cursor: pointer;
  border-radius: 5px;
  border: 2px solid transparent;
  transition: transform 0.3s ease, border-color 0.3s ease;
}

.color-swatch:hover {
  border-color: #FFD700;
  transform: scale(1.1);
}
</style>
