<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';

// Références pour la scène, la caméra, le renderer et le cube
const container = ref(null);
let scene, camera, renderer, cube, controls;
let selectedFace = ref('');

// Fonction pour créer le cube avec des matériaux pour chaque face
const createCube = () => {
  const geometry = new THREE.BoxGeometry(1, 1, 1);
  
  // Créer des matériaux différents pour chaque face
  const materials = [
    new THREE.MeshBasicMaterial({ color: 0xff0000, name: 'front' }),  // Front
    new THREE.MeshBasicMaterial({ color: 0x00ff00, name: 'back' }),   // Back
    new THREE.MeshBasicMaterial({ color: 0x0000ff, name: 'top' }),    // Top
    new THREE.MeshBasicMaterial({ color: 0xffff00, name: 'bottom' }), // Bottom
    new THREE.MeshBasicMaterial({ color: 0x00ffff, name: 'left' }),   // Left
    new THREE.MeshBasicMaterial({ color: 0xff00ff, name: 'right' })   // Right
  ];

  // Créer un mesh avec les géométries et les matériaux
  cube = new THREE.Mesh(geometry, materials);
  scene.add(cube);
};

// Fonction pour initialiser la scène
const init = () => {
  scene = new THREE.Scene();
  camera = new THREE.PerspectiveCamera(75, container.value.clientWidth / container.value.clientHeight, 0.1, 1000);
  camera.position.z = 3;

  renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setSize(container.value.clientWidth, container.value.clientHeight);
  container.value.appendChild(renderer.domElement);

  controls = new OrbitControls(camera, renderer.domElement);

  // Créer et ajouter le cube
  createCube();

  // Ajouter un rayon pour la détection des faces
  const raycaster = new THREE.Raycaster();
  const mouse = new THREE.Vector2();

  const onMouseMove = (event) => {
  const rect = renderer.domElement.getBoundingClientRect(); // On récupère la taille du canvas
  
  // Ajuster les coordonnées de la souris en fonction de la position et taille du canvas
  mouse.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
  mouse.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;

  raycaster.setFromCamera(mouse, camera);
  const intersects = raycaster.intersectObject(cube);

  // Si une face est touchée, on met à jour l'étiquette
  if (intersects.length > 0) {
    const faceIndex = intersects[0].face.materialIndex;
    selectedFace.value = cube.material[faceIndex].name;

    // Appliquer un contour à la face sélectionnée
    cube.material.forEach((mat, index) => {
      mat.wireframe = index === faceIndex;
    });
  } else {
    selectedFace.value = '';
    cube.material.forEach(mat => mat.wireframe = false);
  }
};


  window.addEventListener('mousemove', onMouseMove);

  // Animation de la scène
  const animate = () => {
    requestAnimationFrame(animate);
    controls.update();
    renderer.render(scene, camera);
  };

  animate();
};

onMounted(() => {
  init();
});

onUnmounted(() => {
  if (renderer) {
    container.value.removeChild(renderer.domElement);
    window.removeEventListener('mousemove', onMouseMove);
  }
});
</script>

<template>
  <div>
    <div ref="container" style="width: 100%; height: 500px;"></div>
    <p v-if="selectedFace">Face sélectionnée : {{ selectedFace }}</p>
  </div>
</template>

<style scoped>
div {
  position: relative;
}
p {
  position: absolute;
  top: 10px;
  left: 10px;
  color: white;
  font-size: 18px;
  font-weight: bold;
}
</style>
