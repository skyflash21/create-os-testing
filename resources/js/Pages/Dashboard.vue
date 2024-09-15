<template>
  <div class="computer-container">
    <!-- Boîtier de l'ordinateur -->
    <div class="computer-case">
      <!-- Écran de l'ordinateur -->
      <div class="computer-screen" ref="screenContainer"></div>
      <!-- Boutons -->
      <div class="button power-button" @click="powerToggle"></div>
      <div class="button terminate-button" @click="terminateProgram"></div>
    </div>
  </div>
</template>

<script>
import * as THREE from 'three';
import { ref, onMounted, onUnmounted } from 'vue';

export default {
  name: 'ComputercraftComputer',
  setup() {
    const screenContainer = ref(null);
    let scene, camera, renderer;
    const gridWidth = 51; // Nombre de colonnes
    const gridHeight = 19; // Nombre de lignes
    const cellWidth = 1;
    const cellHeight = 1;
    const cells = [];
    let cursorPosition = { x: 0, y: 0 };
    let cursorInterval;
    let computerOn = ref(true);

    onMounted(() => {
      initScene();
      animate();
    });

    onUnmounted(() => {
      window.removeEventListener('keydown', onKeyDown);
      clearInterval(cursorInterval);
    });

    const initScene = () => {
      // Créer la scène
      scene = new THREE.Scene();
      scene.background = new THREE.Color(0x000000); // Fond noir

      // Configurer la caméra orthographique
      camera = new THREE.OrthographicCamera(
        0,
        gridWidth * cellWidth,
        0,
        -gridHeight * cellHeight,
        0.1,
        1000
      );
      camera.position.z = 10;

      // Configurer le renderer
      renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
      renderer.setSize(306, 114); // Taille de l'écran en pixels
      screenContainer.value.appendChild(renderer.domElement);

      // Ajouter les cellules à la scène
      const geometry = new THREE.PlaneGeometry(cellWidth, cellHeight);

      for (let y = 0; y < gridHeight; y++) {
        for (let x = 0; x < gridWidth; x++) {
          // Créer un canvas pour chaque caractère
          const canvas = document.createElement('canvas');
          canvas.width = 6; // Largeur en pixels
          canvas.height = 6; // Hauteur en pixels
          const context = canvas.getContext('2d');

          // Dessiner le caractère initial (espace vide)
          drawCharacter(context, ' ', '#FFFFFF', '#000000');

          const texture = new THREE.CanvasTexture(canvas);
          texture.magFilter = THREE.NearestFilter; // Pour un rendu pixelisé
          const material = new THREE.MeshBasicMaterial({ map: texture, transparent: true });

          const cell = new THREE.Mesh(geometry, material);
          cell.position.x = x * cellWidth + cellWidth / 2;
          cell.position.y = - (y * cellHeight + cellHeight / 2);
          cell.userData = {
            x: x,
            y: y,
            char: ' ',
            fgColor: '#FFFFFF',
            bgColor: '#000000',
            canvas: canvas,
            context: context,
          };
          scene.add(cell);
          cells.push(cell);
        }
      }

      // Écouter les événements clavier
      window.addEventListener('keydown', onKeyDown);

      // Initialiser le curseur clignotant
      startCursorBlink();
    };

    // Fonction pour dessiner un caractère sur le canvas
    const drawCharacter = (context, char, fgColor, bgColor) => {
      context.clearRect(0, 0, context.canvas.width, context.canvas.height);
      // Dessiner le fond
      context.fillStyle = bgColor;
      context.fillRect(0, 0, context.canvas.width, context.canvas.height);
      // Dessiner le caractère
      context.font = '6px "Minecraftia", monospace';
      context.fillStyle = fgColor;
      context.textAlign = 'left';
      context.textBaseline = 'top';
      context.fillText(char, 0, 0);
    };

    const updateCell = (cell) => {
      drawCharacter(cell.userData.context, cell.userData.char, cell.userData.fgColor, cell.userData.bgColor);
      cell.material.map.needsUpdate = true;
    };

    const writeChar = (char, x, y, fgColor = '#FFFFFF', bgColor = '#000000') => {
      if (x >= 0 && x < gridWidth && y >= 0 && y < gridHeight) {
        const cellIndex = y * gridWidth + x;
        const cell = cells[cellIndex];
        cell.userData.char = char;
        cell.userData.fgColor = fgColor;
        cell.userData.bgColor = bgColor;
        updateCell(cell);
      }
    };

    const writeString = (str, x, y, fgColor = '#FFFFFF', bgColor = '#000000') => {
      for (let i = 0; i < str.length; i++) {
        writeChar(str[i], x + i, y, fgColor, bgColor);
      }
    };

    // Gestion du curseur clignotant
    let cursorVisible = true;

    const startCursorBlink = () => {
      cursorInterval = setInterval(() => {
        cursorVisible = !cursorVisible;
        const { x, y } = cursorPosition;
        const cellIndex = y * gridWidth + x;
        const cell = cells[cellIndex];
        if (cell) {
          cell.userData.bgColor = cursorVisible ? '#FFFFFF' : '#000000';
          cell.userData.fgColor = cursorVisible ? '#000000' : '#FFFFFF';
          updateCell(cell);
        }
      }, 500);
    };

    const stopCursorBlink = () => {
      clearInterval(cursorInterval);
    };

    // Gestion de l'entrée clavier
    const onKeyDown = (event) => {
      if (!computerOn.value) return;
      const key = event.key;

      // Empêcher les actions par défaut
      event.preventDefault();

      if (key.length === 1) {
        // Caractère imprimable
        writeChar(key, cursorPosition.x, cursorPosition.y);
        moveCursorRight();
      } else if (key === 'Backspace') {
        moveCursorLeft();
        writeChar(' ', cursorPosition.x, cursorPosition.y);
      } else if (key === 'Enter') {
        cursorPosition.x = 0;
        moveCursorDown();
      } else if (key === 'ArrowLeft') {
        moveCursorLeft();
      } else if (key === 'ArrowRight') {
        moveCursorRight();
      } else if (key === 'ArrowUp') {
        moveCursorUp();
      } else if (key === 'ArrowDown') {
        moveCursorDown();
      }
    };

    const moveCursorLeft = () => {
      if (cursorPosition.x > 0) {
        cursorPosition.x--;
      }
    };

    const moveCursorRight = () => {
      if (cursorPosition.x < gridWidth - 1) {
        cursorPosition.x++;
      }
    };

    const moveCursorUp = () => {
      if (cursorPosition.y > 0) {
        cursorPosition.y--;
      }
    };

    const moveCursorDown = () => {
      if (cursorPosition.y < gridHeight - 1) {
        cursorPosition.y++;
      }
    };

    // Fonctions pour les boutons
    const powerToggle = () => {
      computerOn.value = !computerOn.value;
      if (computerOn.value) {
        // Rallumer l'ordinateur
        startCursorBlink();
        window.addEventListener('keydown', onKeyDown);
      } else {
        // Éteindre l'ordinateur
        stopCursorBlink();
        window.removeEventListener('keydown', onKeyDown);
        // Effacer l'écran
        cells.forEach(cell => {
          cell.userData.char = ' ';
          cell.userData.fgColor = '#000000';
          cell.userData.bgColor = '#000000';
          updateCell(cell);
        });
      }
    };

    const terminateProgram = () => {
      // Réinitialiser le curseur
      cursorPosition = { x: 0, y: 0 };
      // Effacer l'écran
      cells.forEach(cell => {
        cell.userData.char = ' ';
        cell.userData.fgColor = '#FFFFFF';
        cell.userData.bgColor = '#000000';
        updateCell(cell);
      });
    };

    const animate = () => {
      requestAnimationFrame(animate);
      renderer.render(scene, camera);
    };

    return {
      screenContainer,
      powerToggle,
      terminateProgram,
    };
  },
};
</script>

<style scoped>
@font-face {
  font-family: 'Minecraftia';
  src: url('@/assets/fonts/Minecraftia.ttf') format('truetype');
}

.computer-container {
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: #8b8b8b; /* Couleur du fond de la page */
  width: 100vw;
  height: 100vh;
}

.computer-case {
  position: relative;
  width: 350px;
  height: 250px;
  background-color: #2b2b2b; /* Couleur du boîtier */
  border: 5px solid #1e1e1e;
  box-shadow: inset 0 0 10px #000;
}

.computer-screen {
  position: absolute;
  top: 20px;
  left: 22px;
  width: 306px;
  height: 114px;
  background-color: #000; /* Fond de l'écran */
  overflow: hidden;
}

.button {
  position: absolute;
  width: 24px;
  height: 24px;
  background-color: #3e3e3e;
  border: 2px solid #1e1e1e;
  cursor: pointer;
}

.power-button {
  top: 150px;
  left: 22px;
  background-image: url('@/assets/textures/power_button.png');
  background-size: cover;
}

.terminate-button {
  top: 150px;
  left: 52px;
  background-image: url('@/assets/textures/terminate_button.png');
  background-size: cover;
}
</style>
