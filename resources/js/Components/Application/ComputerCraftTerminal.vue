<script setup>
import {
  ref,
  onMounted,
  onUnmounted,
  computed,
  defineProps,
  defineEmits,
  watch,
  nextTick,
} from 'vue';
import * as THREE from 'three';

// Définir les props
const props = defineProps({
  computerId: {
    type: Number,
    required: true,
  },
  is_advanced: {
    type: Number,
    required: true,
  },
});

// Définir les événements émis
const emit = defineEmits(['close']);
function close() {
  emit('close');
}

// Gestion des touches (votre mapping existant)
const all_key = {
    a: 65,
    c: 67,
    b: 66,
    e: 69,
    d: 68,
    g: 71,
    f: 70,
    numpad3: 323,
    f10: 299,
    period: 46,
    j: 74,
    m: 77,
    l: 76,
    o: 79,
    n: 78,
    minus: 45,
    f1: 290,
    s: 83,
    return: 257,
    slash: 47,
    seven: 55,
    eight: 56,
    v: 86,
    f22: 311,
    x: 88,
    numpad6: 326,
    z: 90,
    f18: 307,
    rightbracket: 93,
    f9: 298,
    left: 263,
    numpadsubtract: 333,
    f3: 292,
    f20: 309,
    numpadequal: 336,
    pagedown: 267,
    leftctrl: 341,
    rightctrl: 345,
    numpad2: 322,
    zero: 48,
    delete: 261,
    comma: 44,
    six: 54,
    leftalt: 342,
    numpad8: 328,
    numlock: 282,
    semicolon: 59,
    menu: 348,
    insert: 260,
    f23: 312,
    space: 32,
    f16: 305,
    down: 264,
    pause: 284,
    f11: 300,
    f5: 294,
    printscreen: 283,
    rightshift: 344,
    f19: 308,
    h: 72,
    f15: 304,
    nine: 57,
    f2: 291,
    scrolllock: 281,
    two: 50,
    leftbracket: 91,
    home: 268,
    capslock: 280,
    f14: 303,
    up: 265,
    rightalt: 346,
    one: 49,
    equals: 61,
    numpadadd: 334,
    pageup: 266,
    f7: 296,
    apostrophe: 39,
    numpadenter: 335,
    f8: 297,
    y: 89,
    w: 87,
    u: 85,
    four: 52,
    t: 84,
    p: 80,
    tab: 258,
    q: 81,
    r: 82,
    f21: 310,
    numpad1: 321,
    right: 262,
    numpaddecimal: 330,
    f25: 314,
    leftshift: 340,
    backspace: 259,
    grave: 96,
    end: 269,
    three: 51,
    numpadmultiply: 332,
    f24: 313,
    k: 75,
    numpad7: 327,
    numpad4: 324,
    f13: 302,
    numpad0: 320,
    f17: 306,
    i: 73,
    leftsuper: 343,
    f6: 295,
    enter: 257,
    numpaddivide: 331,
    numpad5: 325,
    f12: 301,
    backslash: 92,
    numpad9: 329,
    five: 53,
    f4: 293
};

// Dimensions de la grille
const rows = 19;
const cols = 51;

// Variable pour la taille des cellules (un seul curseur)
const cellSize = ref(8); // Taille initiale de la largeur de la cellule

// Les ratios pour conserver le ratio 8/16
const widthRatio = 1;
const heightRatio = 2;

// Calcul de la largeur et de la hauteur des cellules en fonction de cellSize
const cellWidth = computed(() => cellSize.value * widthRatio);
const cellHeight = computed(() => cellSize.value * heightRatio);

// Références aux éléments DOM
const gridElement = ref(null);
const threeContainer = ref(null);

// Variables Three.js
let scene, camera, renderer;
let characterMesh;
let canvasTexture;

// Données de la grille
const gridData = ref(createGrid());

// Créer la grille de données
function createGrid() {
  const grid = [];
  for (let i = 0; i < rows * cols; i++) {
    grid.push({
      char: ' ', // Caractère par défaut
      textColor: '#FFFFFF', // Couleur du texte
      backgroundColor: '#111111', // Couleur de fond
    });
  }
  return grid;
}

// Fonction pour initialiser Three.js
function initThree() {
  // Créer la scène
  scene = new THREE.Scene();

  // Créer la caméra orthographique
  camera = new THREE.OrthographicCamera(
    0,
    cols * cellWidth.value,
    rows * cellHeight.value,
    0,
    -1,
    1
  );
  camera.position.z = 1;

  // Créer le renderer
  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(cols * cellWidth.value, rows * cellHeight.value);
  threeContainer.value.appendChild(renderer.domElement);

  // Créer le canvas pour dessiner la grille
  const canvas = document.createElement('canvas');
  canvas.width = cols * cellWidth.value;
  canvas.height = rows * cellHeight.value;

  // Créer la texture à partir du canvas
  canvasTexture = new THREE.CanvasTexture(canvas);
  canvasTexture.magFilter = THREE.NearestFilter;
  canvasTexture.minFilter = THREE.NearestFilter;

  // Créer un plan pour afficher la texture
  const geometry = new THREE.PlaneGeometry(
    cols * cellWidth.value,
    rows * cellHeight.value
  );
  const material = new THREE.MeshBasicMaterial({ map: canvasTexture });

  characterMesh = new THREE.Mesh(geometry, material);
  characterMesh.position.x = (cols * cellWidth.value) / 2;
  characterMesh.position.y = (rows * cellHeight.value) / 2;
  scene.add(characterMesh);

  // Dessiner la grille initiale
  updateTexture();

  // Démarrer la boucle d'animation
  animate();
}

// Fonction pour mettre à jour la texture en fonction de gridData
function updateTexture() {
  const canvas = canvasTexture.image;
  const context = canvas.getContext('2d');

  // Effacer le canvas
  context.clearRect(0, 0, canvas.width, canvas.height);

  // Parcourir les données de la grille et dessiner chaque caractère
  for (let y = 0; y < rows; y++) {
    for (let x = 0; x < cols; x++) {
      const cell = gridData.value[y * cols + x];

      // Dessiner le fond
      context.fillStyle = cell.backgroundColor;
      context.fillRect(
        x * cellWidth.value,
        y * cellHeight.value,
        cellWidth.value,
        cellHeight.value
      );

      // Dessiner le caractère
      context.fillStyle = cell.textColor;
      context.font = `${cellHeight.value}px 'CustomFont', monospace`;
      context.textAlign = 'left';
      context.textBaseline = 'top';
      context.fillText(
        cell.char,
        x * cellWidth.value,
        y * cellHeight.value
      );
    }
  }

  // Mettre à jour la texture du matériel
  canvasTexture.needsUpdate = true;
}

// Fonction d'animation
function animate() {
  requestAnimationFrame(animate);
  renderer.render(scene, camera);
}

// Surveiller les changements de gridData pour mettre à jour la texture
watch(
  gridData,
  () => {
    updateTexture();
  },
  { deep: true }
);

// Surveiller les changements de taille des cellules
watch(cellSize, () => {
  updateSizes();
});

// Fonction pour mettre à jour les paramètres lors du changement de taille des cellules
function updateSizes() {
  // Mettre à jour la caméra
  camera.left = 0;
  camera.right = cols * cellWidth.value;
  camera.top = rows * cellHeight.value;
  camera.bottom = 0;
  camera.updateProjectionMatrix();

  // Mettre à jour la taille du renderer
  renderer.setSize(cols * cellWidth.value, rows * cellHeight.value);

  // Créer un nouveau canvas
  const canvas = document.createElement('canvas');
  canvas.width = cols * cellWidth.value;
  canvas.height = rows * cellHeight.value;

  // Créer une nouvelle texture à partir du nouveau canvas
  const newCanvasTexture = new THREE.CanvasTexture(canvas);
  newCanvasTexture.magFilter = THREE.NearestFilter;
  newCanvasTexture.minFilter = THREE.NearestFilter;

  // Libérer l'ancienne texture
  if (canvasTexture) {
    canvasTexture.dispose();
  }

  // Mettre à jour la référence de la texture
  canvasTexture = newCanvasTexture;

  // Mettre à jour le matériau pour utiliser la nouvelle texture
  characterMesh.material.map = canvasTexture;
  characterMesh.material.needsUpdate = true;

  // Mettre à jour la géométrie du plan
  characterMesh.geometry.dispose();
  characterMesh.geometry = new THREE.PlaneGeometry(
    cols * cellWidth.value,
    rows * cellHeight.value
  );

  // Mettre à jour la position du mesh
  characterMesh.position.x = (cols * cellWidth.value) / 2;
  characterMesh.position.y = (rows * cellHeight.value) / 2;

  // Redessiner la texture avec le nouveau canvas
  updateTexture();
}

// Gestion des événements de la souris
const mousePosition = ref({ x: 0, y: 0 });
function updateMousePosition(event) {
  const rect = gridElement.value.getBoundingClientRect();
  const x = ((event.clientX - rect.left) / rect.width) * cols;
  const y = ((event.clientY - rect.top) / rect.height) * rows;
  mousePosition.value = {
    x: Math.floor(x) + 1,
    y: Math.floor(y) + 1,
  };
}

function handleMouseClick(event) {
  updateMousePosition(event);
  const { x, y } = mousePosition.value;

  window.Echo.private(`computer-${props.computerId}`).whisper('user_input', {
    type: 'mouse_click',
    x: x,
    y: y,
    computer_id: props.computerId,
  });
}

function handleMouseUp(event) {
  updateMousePosition(event);
  const { x, y } = mousePosition.value;

  window.Echo.private(`computer-${props.computerId}`).whisper('user_input', {
    type: 'mouse_up',
    x: x,
    y: y,
    computer_id: props.computerId,
  });
}

function handleMouseDrag(event) {
  if (event.buttons === 1) {
    updateMousePosition(event);
    const { x, y } = mousePosition.value;

    window.Echo.private(`computer-${props.computerId}`).whisper('user_input', {
      type: 'mouse_drag',
      x: x,
      y: y,
      button: 1,
      computer_id: props.computerId,
    });
  }
}

function handleMouseScroll(event) {
  updateMousePosition(event);
  const { x, y } = mousePosition.value;

  window.Echo.private(`computer-${props.computerId}`).whisper('user_input', {
    type: 'mouse_scroll',
    x: x,
    y: y,
    direction: Math.sign(event.deltaY),
    computer_id: props.computerId,
  });
}

// Gestion des événements clavier
function handleKeydown(event) {
    // On vérifie si event.key est présent dans all_key lower
    if (event.key.toLowerCase() in all_key) {
        // On empêche le comportement par défaut
        event.preventDefault();
        // On envoie l'événement au serveur
        window.Echo.private(`computer-${props.computerId}`).whisper('user_input', {
            type: "key",
            key: all_key[event.key.toLowerCase()],
            computer_id: props.computerId
        });

        console.log("Key pressed: ", all_key[event.key.toLowerCase()]);

        // si la clé entrée est un char simple on l'envoie avec le type char
        if (event.key.length === 1) {
            window.Echo.private(`computer-${props.computerId}`).whisper('user_input', {
                type: "char",
                char: event.key,
                computer_id: props.computerId
            });

            console.log("Char pressed: ", event.key);
        }
    }else{
        console.log("Key not found in all_key: ", event.key);
        event.preventDefault();
    }
}

function handleKeyup(event) {
  // Gestion si nécessaire
}

function handlePaste(event) {
  const paste = (event.clipboardData || window.clipboardData).getData('text');
  console.log('Paste event:', paste);
}

// Lifecycle hooks
onMounted(() => {
  nextTick(() => {
    initThree();

    // Écoute des événements du serveur via Echo
    window.Echo.private(`computer-${props.computerId}`)
      .listenForWhisper('computer_write', (event) => {
        const data = event;

        if (data.computer_id !== props.computerId) {
          return;
        }

        const { text, cursorX, cursorY, textColor, backgroundColor } = data;

        if (
          cursorX < 1 ||
          cursorX > cols ||
          cursorY < 1 ||
          cursorY > rows
        ) {
          return;
        }

        const converted_textColor = `rgb(${textColor
          .map((c) => Math.round(c * 255))
          .join(',')})`;
        const converted_backgroundColor = `rgb(${backgroundColor
          .map((c) => Math.round(c * 255))
          .join(',')})`;

        // Mettre à jour la grille
        for (let i = 0; i < text.length; i++) {
          const x = cursorX + i - 1;
          const y = cursorY - 1;
          if (x < cols) {
            const index = y * cols + x;
            gridData.value[index] = {
              char: text[i],
              textColor: converted_textColor,
              backgroundColor: converted_backgroundColor,
            };
          }
        }
      })
      .listenForWhisper('computer_blit', (event) => {
        const data = event;

        if (data.computer_id !== props.computerId) {
          return;
        }

        const { text, fg, bg, cursorX, cursorY } = data;

        for (let i = 0; i < text.length; i++) {
          const x = cursorX + i - 1;
          const y = cursorY - 1;
          if (x < cols) {
            const fgColor = `rgb(${fg[i]
              .map((c) => Math.round(c * 255))
              .join(',')})`;
            const bgColor = `rgb(${bg[i]
              .map((c) => Math.round(c * 255))
              .join(',')})`;

            const index = y * cols + x;
            gridData.value[index] = {
              char: text[i],
              textColor: fgColor,
              backgroundColor: bgColor,
            };
          }
        }
      })
      .listenForWhisper('computer_clear', (event) => {
        const { computer_id } = event;

        if (computer_id !== props.computerId) {
          return;
        }

        // Effacer toute la grille
        gridData.value = createGrid();
      })
      .listenForWhisper('computer_clearLine', (event) => {
        const { cursorY, computer_id } = event;

        if (computer_id !== props.computerId) {
          return;
        }

        const y = cursorY - 1;
        for (let x = 0; x < cols; x++) {
          const index = y * cols + x;
          gridData.value[index] = {
            char: ' ',
            textColor: '#FFFFFF',
            backgroundColor: '#111111',
          };
        }
      })
      .listenForWhisper('computer_scroll', (event) => {
        const { n, computer_id } = event;

        if (computer_id !== props.computerId) {
          return;
        }

        if (n > 0) {
          // Scroll up
          gridData.value.splice(0, n * cols);
          for (let i = 0; i < n * cols; i++) {
            gridData.value.push({
              char: ' ',
              textColor: '#FFFFFF',
              backgroundColor: '#111111',
            });
          }
        } else if (n < 0) {
          // Scroll down
          gridData.value.splice(n * cols);
          for (let i = 0; i < -n * cols; i++) {
            gridData.value.unshift({
              char: ' ',
              textColor: '#FFFFFF',
              backgroundColor: '#111111',
            });
          }
        }
      })
      .listenForWhisper('computer_switchToRealScreen', (event) => {
        const { computer_id } = event;

        if (computer_id !== props.computerId) {
          return;
        }

        switchToRealScreen(false);
        console.log('Switched to real screen');
      });

    // Initialisation du message de bienvenue
    const welcome = 'Veuillez sélectionner un mode d\'affichage';

    const start_i = cols * 5 + Math.floor((cols - welcome.length) / 2);
    for (let i = 0; i < welcome.length; i++) {
      gridData.value[start_i + i].char = welcome[i];
    }
  });
});

onUnmounted(() => {
  window.Echo.leave(`computer-${props.computerId}`);

  window.Echo.private(`computer-${props.computerId}`).whisper(
    'switchToRealScreen',
    {}
  );

  console.log('ComputerCraft terminal unmounted');
});

// Fonctions pour changer le mode d'affichage
const display_mode = ref('Real Screen');

function switchToRealScreen(warn_client = true) {
  if (warn_client) {
    window.Echo.private(`computer-${props.computerId}`).whisper(
      'switch_screen',
      {
        screen: 'real',
      }
    );
  }

  gridData.value = createGrid();

  display_mode.value = 'Real Screen';

  const welcome = 'Écran désactivé, real screen activé';
  const start_i = cols * 5 + Math.floor((cols - welcome.length) / 2);
  for (let i = 0; i < welcome.length; i++) {
    gridData.value[start_i + i].char = welcome[i];
  }
}

function switchToVirtualScreen() {
  window.Echo.private(`computer-${props.computerId}`).whisper('switch_screen', {
    screen: 'virtual',
  });

  display_mode.value = 'Virtual Screen';
}

function switchToHybridScreen() {
  window.Echo.private(`computer-${props.computerId}`).whisper('switch_screen', {
    screen: 'hybrid',
  });

  display_mode.value = 'Hybrid Screen';
}

// Style dynamique pour le conteneur de la grille
const gridContainerStyle = computed(() => {
  return {
    border: `10px solid ${props.is_advanced ? '#C5C66D' : '#C3C3C3'}`,
  };
});

const gridWidth = computed(() => cols * cellWidth.value);
const gridHeight = computed(() => rows * cellHeight.value);
</script>

<template>
  <div class="terminal-container">
    <!-- Bouton de fermeture -->
    <button class="close-button" @click="close">X</button>

    <div class="info_text">Computer ID: {{ computerId }}</div>

    <!-- Conteneur pour Three.js -->
    <div class="grid-container" :style="gridContainerStyle">
      <div
        class="grid"
        :style="{ width: gridWidth + 'px', height: gridHeight + 'px' }"
        @keydown="handleKeydown"
        @keyup="handleKeyup"
        @mousedown="handleMouseClick"
        @mouseup="handleMouseUp"
        @mousemove="handleMouseDrag"
        @wheel="handleMouseScroll"
        @paste="handlePaste"
        tabindex="0"
        ref="gridElement"
      >
        <!-- Le rendu Three.js sera injecté ici -->
        <div ref="threeContainer"></div>
      </div>
    </div>

    <!-- Contrôles pour changer le mode d'affichage -->
    <div>
      <div class="info_text">
        Mouse Position: X = {{ mousePosition.x }}, Y = {{ mousePosition.y }}
      </div>
      <div class="info_text">Display Mode: {{ display_mode }}</div>

      <div class="controls">
        <button @click="switchToRealScreen" class="select_button">
          Real Screen
        </button>
        <button @click="switchToVirtualScreen" class="select_button">
          Virtual Screen
        </button>
        <button @click="switchToHybridScreen" class="select_button">
          Hybrid Screen
        </button>
      </div>

      <!-- Contrôle pour ajuster la taille des cellules -->
      <div class="controls">
        <label>
          Cell Size:
          <input
            type="range"
            v-model="cellSize"
            min="4"
            max="16"
            step="1"
          />
        </label>
      </div>
    </div>
  </div>
</template>

<style scoped>
.terminal-container {
  position: relative;
  padding: 20px;
  border-radius: 8px;
  background-color: #333;
}

/* Styles pour le bouton de fermeture */
.close-button {
  position: absolute;
  top: 10px;
  right: 10px;
  background: none;
  border: none;
  color: white;
  font-size: 20px;
  cursor: pointer;
}

.close-button:hover {
  color: #ff5c5c; /* Couleur de survol */
}

.grid-container {
  margin-top: 20px;
  overflow: hidden;
  width: fit-content;
  height: fit-content;
  border-radius: 5px;
  padding: 5px;
}

.grid {
  outline: none;
  user-select: none;
  position: relative;
}

.controls {
  display: flex;
  margin-top: 20px;
  justify-content: center;
  gap: 20px;
}

.controls label {
  color: white;
  font-size: 14px;
}

.select_button {
  background-color: #4caf50;
  border: none;
  color: white;
  padding: 10px 20px;
  text-align: center;
  font-size: 14px;
  cursor: pointer;
  border-radius: 5px;
}

.select_button:hover {
  background-color: #45a049;
}

.info_text {
  margin-top: 10px;
  font-size: 16px;
  color: #ffffff;
  text-align: center;
}
</style>
