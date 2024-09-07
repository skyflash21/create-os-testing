<script setup>
import { ref, onMounted, onUnmounted , defineProps, defineEmits } from 'vue';
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';

// Ajoutez une prop pour l'ID de l'ordinateur
const props = defineProps({
  computerId: {
    type: Number,
    required: true,
  },
  computer: Object,
});

// Références pour la scène, la caméra, le renderer et le cube
const container = ref(null);
let scene, camera, renderer, cube, controls;
let selectedFace = ref(null); // Face sélectionnée
let sliderValue = ref(0); // Valeur du slider

// Fonction pour fermer (ici cela peut être modifié pour cacher ou fermer le composant)
const emit = defineEmits(['close']);

function close() {
  emit('close');

  if (renderer && container.value) {
    container.value.removeChild(renderer.domElement);
    console.log('Unmounted');
  }
}

// Fonction pour créer le cube avec des matériaux pour chaque face
const createCube = () => {
  const geometry = new THREE.BoxGeometry(1, 1, 1);

  const textureLoader = new THREE.TextureLoader();

  // Load textures
  const computer_advanced_front = textureLoader.load("/storage/textures/advanced_computer/computer_advanced_front.png");
  const computer_advanced_side = textureLoader.load("/storage/textures/advanced_computer/computer_advanced_side.png");
  const computer_advanced_top = textureLoader.load("/storage/textures/advanced_computer/computer_advanced_top.png");

  computer_advanced_front.minFilter = THREE.LinearMipMapLinearFilter;
  computer_advanced_front.magFilter = THREE.NearestFilter;
  computer_advanced_side.minFilter = THREE.LinearMipMapLinearFilter;
  computer_advanced_side.magFilter = THREE.NearestFilter;
  computer_advanced_top.minFilter = THREE.LinearMipMapLinearFilter;
  computer_advanced_top.magFilter = THREE.NearestFilter;

  // Create materials for each face of the cube
  const materials = [
    new THREE.MeshBasicMaterial({ map: computer_advanced_front, name: 'front', side: THREE.DoubleSide }),
    new THREE.MeshBasicMaterial({ map: computer_advanced_side, name: 'back', side: THREE.DoubleSide }),
    new THREE.MeshBasicMaterial({ map: computer_advanced_top, name: 'top', side: THREE.DoubleSide }),
    new THREE.MeshBasicMaterial({ map: computer_advanced_top, name: 'bottom', side: THREE.DoubleSide }),
    new THREE.MeshBasicMaterial({ map: computer_advanced_side, name: 'left', side: THREE.DoubleSide }),
    new THREE.MeshBasicMaterial({ map: computer_advanced_side, name: 'right', side: THREE.DoubleSide }),
  ];

  // Create the cube mesh with the geometry and the materials
  cube = new THREE.Mesh(geometry, materials);

  // Add the cube to the scene
  scene.add(cube);
};

// Fonction pour initialiser la scène
const init = () => {
  scene = new THREE.Scene();
  camera = new THREE.PerspectiveCamera(75, container.value.clientWidth / container.value.clientHeight, 0.1, 1000);
  camera.position.z = 3;

  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.gammaOutput = true;
  renderer.gammaFactor = 2.2;

  renderer.setSize(container.value.clientWidth, container.value.clientHeight);
  container.value.appendChild(renderer.domElement);

  controls = new OrbitControls(camera, renderer.domElement);

  // Créer et ajouter le cube
  createCube();

  // Ajouter un rayon pour la détection des faces
  const raycaster = new THREE.Raycaster();
  const mouse = new THREE.Vector2();

  // Le fond du canvas est transparent
  renderer.setClearColor(0x000000, 0);

  const onClick = (event) => {
    const rect = renderer.domElement.getBoundingClientRect(); // On récupère la taille du canvas
  
    // Ajuster les coordonnées de la souris en fonction de la position et taille du canvas
    mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
    mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;

    raycaster.setFromCamera(mouse, camera);
    const intersects = raycaster.intersectObject(cube);

    // Si une face est cliquée, on met à jour l'étiquette
    if (intersects.length > 0) {
      const faceIndex = intersects[0].face.materialIndex;
      selectedFace.value = cube.material[faceIndex].name;
    }
  };

  window.addEventListener('click', onClick);

  // Animation de la scène
  const animate = () => {
    requestAnimationFrame(animate);
    controls.update();
    renderer.render(scene, camera);
  };

  camera.position.z = 1;
  camera.position.y = 1;
  camera.position.x = 1;

  controls.enableZoom = false;

  animate();
};

onMounted(() => {
  init();
  console.log('Mounted');

  window.Echo.private(`computer-${props.computerId}`).listen('redstone_update', (e) => {
    console.log(e);
  });
});

onUnmounted(() => {
  if (renderer && container.value) {
    container.value.removeChild(renderer.domElement);
    window.removeEventListener('click', onClick);
    console.log('Unmounted');
  }
});

const onSliderChange = (event) => {
  sliderValue.value = event.target.value;
  window.Echo.private(`computer-${props.computerId}`).whisper('redstone_event', { type: "redstone_changed", side: selectedFace.value, value: sliderValue.value });
};

</script>

<template>
  <div class="terminal-container">
    <button class="close-button" @click="close">X</button>

    <!-- Cube 3D et label pour la face sélectionnée -->
    <div ref="container" class="three-container"></div>
    
    <p v-if="selectedFace" class="face-label">Face sélectionnée : {{ selectedFace }}</p>
    <p v-else class="face-label">Cliquez sur une face pour la sélectionner</p>
    
    <!-- Slider pour contrôler une valeur entre 0 et 15 -->
    <input v-if="selectedFace" type="range" min="0" max="15" @input="onSliderChange" v-model="sliderValue" />
    <p v-if="selectedFace" class="face-label">Valeur du slider : {{ sliderValue }}</p>
  </div>
</template>

<style scoped>
.terminal-container {
  position: relative;
  padding: 20px;
  border-radius: 20px;
  background-color: #333;
  width: 90vh;
  height: 90vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-start;
}

/* Styles pour le container du cube 3D */
.three-container {
  width: 100%;
  height: 80%;
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
  color: #ff5c5c;
}

/* Styles pour l'étiquette de la face sélectionnée */
.face-label {
  color: white;
  font-size: 18px;
  font-weight: bold;
  margin-top: 10px;
}
</style>
