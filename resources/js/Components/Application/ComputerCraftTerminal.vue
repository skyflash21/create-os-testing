<script setup>
import { ref, onMounted, onUnmounted,computed,nextTick,defineProps, defineEmits } from "vue";
import { usePage } from "@inertiajs/vue3";

// Ajoutez une prop pour l'ID de l'ordinateur
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

// Définir l'événement `emit` pour déclencher l'événement `close`
const emit = defineEmits(['close']);

const rows = 19;
const cols = 51;

function createGrid() {
    const grid = [];
    for (let i = 0; i < rows * cols; i++) {
        grid.push({
            char: String.fromCharCode(0x00), // Utilisez ici le code du caractère spécifique que vous souhaitez
            textColor: "#FFFFFF", // Couleur du texte
            backgroundColor: "rgb(17, 17, 17)", // Couleur de fond
        });
    }
    return grid;
}

const grid = ref(createGrid());

const gridElement = ref(null);

function getGridCoordinates(event) {
    const gridRect = gridElement.value.getBoundingClientRect();
    const cellWidth = gridRect.width / cols;
    const cellHeight = gridRect.height / rows;

    let x = Math.floor((event.clientX - gridRect.left) / cellWidth) + 1;
    let y = Math.floor((event.clientY - gridRect.top) / cellHeight) + 1;

    // Ensure x and y are within bounds
    if (x < 1) x = 1;
    if (y < 1) y = 1;
    if (x > cols) x = cols;
    if (y > rows) y = rows;

    return { x, y };
}

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
}

const mousePosition = ref({ x: 0, y: 0 });

function updateMousePosition(event) {
    const { x, y } = getGridCoordinates(event);
    mousePosition.value = { x, y };
}

function handleMouseClick(event) {
    const { x, y } = getGridCoordinates(event);
    
    window.Echo.private(`computer-${props.computerId}`).whisper('user_input', {
        type: "mouse_click",
        x: x,
        y: y,
        computer_id: props.computerId
    });
}

function handleMouseUp(event) {
    const { x, y } = getGridCoordinates(event);
    
    window.Echo.private(`computer-${props.computerId}`).whisper('user_input', {
        type: "mouse_up",
        x: x,
        y: y,
        computer_id: props.computerId
    });
}

function handleMouseDrag(event) {
    if (event.buttons === 1) {
        // Only log if the left mouse button is held down
        const { x, y } = getGridCoordinates(event);
        
        window.Echo.private(`computer-${props.computerId}`).whisper('user_input', {
            type: "mouse_drag",
            x: x,
            y: y,
            button: 1,
            computer_id: props.computerId
        });
    }

    updateMousePosition(event);
}

function handleMouseScroll(event) {
    const { x, y } = getGridCoordinates(event);
    
    window.Echo.private(`computer-${props.computerId}`).whisper('user_input', {
        type: "mouse_scroll",
        x: x,
        y: y,
        direction: Math.sign(event.deltaY),
        computer_id: props.computerId
    });
}

function handlePaste(event) {
    const paste = (event.clipboardData || window.clipboardData).getData("text");
    console.log("Paste event:", paste);
}

onMounted(() => {
    nextTick(() => {
        // Open the private channel for the computer
        window.Echo.private(`computer-` + props.computerId)
        .listenForWhisper('computer_write', (event) => {
            
            const data = event;

            if (data.computer_id !== props.computerId) {
                console.log("Ignoring write event for computer:", data.computer_id , "Current computer:", props.computerId);
                return;
            }
            
            const { text, cursorX, cursorY, textColor, backgroundColor } = data;

            if (cursorX < 1 || cursorX > cols || cursorY < 1 || cursorY > rows) {
                return;
            }

            const converted_textColor = `rgb(${textColor.map((c) => Math.round(c * 255)).join(",")})`;
            const converted_backgroundColor = `rgb(${backgroundColor.map((c) => Math.round(c * 255)).join(",")})`;

            // Calculate the start index in the grid
            const startIndex = (cursorY - 1) * cols + (cursorX - 1);

            // Update the grid with the text at the specified position
            for (let i = 0; i < text.length; i++) {
                if (startIndex + i < grid.value.length) {
                    grid.value[startIndex + i].char = text[i];
                    grid.value[startIndex + i].textColor = converted_textColor;
                    grid.value[startIndex + i].backgroundColor = converted_backgroundColor;
                }
            }
        })
        .listenForWhisper('computer_blit', (event) => {
            
            const data = event;

            if (data.computer_id !== props.computerId) {
                return;
            }

            const { text, fg, bg, cursorX, cursorY } = data;

            // Calculate the start index in the grid
            const startIndex = (cursorY - 1) * cols + (cursorX - 1);

            // Update the grid with the text, foreground, and background colors
            for (let i = 0; i < text.length; i++) {
                if (startIndex + i < grid.value.length) {
                    const fgColor = `rgb(${fg[i].map((c) => Math.round(c * 255)).join(",")})`;
                    const bgColor = `rgb(${bg[i].map((c) => Math.round(c * 255)).join(",")})`;

                    grid.value[startIndex + i].char = text[i];
                    grid.value[startIndex + i].textColor = fgColor;
                    grid.value[startIndex + i].backgroundColor = bgColor;
                }
            }
        })
        .listenForWhisper('computer_clear', (event) => {
            
            const { computer_id } = event;

            if (computer_id !== props.computerId) {
                return;
            }

            // Clear the entire grid
            grid.value.forEach((cell) => {
                cell.char = String.fromCharCode(0x00);
                cell.textColor = "#FFFFFF";
                cell.backgroundColor = "rgb(17, 17, 17)";
            });
        })
        .listenForWhisper('computer_clearLine', (event) => {
            
            const { cursorY, computer_id } = event;

            if (computer_id !== props.computerId) {
                return;
            }

            // Clear the specified line
            const startIndex = (cursorY - 1) * cols;
            for (let i = 0; i < cols; i++) {
                grid.value[startIndex + i].char = String.fromCharCode(0x00);
                grid.value[startIndex + i].textColor = "#FFFFFF";
                grid.value[startIndex + i].backgroundColor = "rgb(17, 17, 17)";
            }
        })
        .listenForWhisper('computer_scroll', (event) => {
            
            const { n, computer_id } = event;

            if (computer_id !== props.computerId) {
                return;
            }

            if (n > 0) {
                // Scroll up
                grid.value.splice(0, n * cols);
                for (let i = 0; i < n * cols; i++) {
                    grid.value.push({
                        char: String.fromCharCode(0x00),
                        textColor: "#FFFFFF",
                        backgroundColor: "rgb(17, 17, 17)"
                    });
                }
            } else if (n < 0) {
                // Scroll down
                grid.value.splice(n * cols);
                for (let i = 0; i < -n * cols; i++) {
                    grid.value.unshift({
                        char: String.fromCharCode(0x00),
                        textColor: "#FFFFFF",
                        backgroundColor: "rgb(17, 17, 17)"
                    });
                }
            }
        }).listenForWhisper('computer_switchToRealScreen', (event) => {
            
            const { n, computer_id } = event;

            if (computer_id !== props.computerId) {
                return;
            }

            switchToRealScreen(false);
            console.log("Switched to real screen");
        })

        // by default "welcome" is written on the grid at the top left corner only for the client side 
        const welcome = "Veuillez selectionner un mode d'affichage";

        const start_i = 51 * 5 + Math.floor((51 - welcome.length) / 2);
        for (let i = 0; i < welcome.length; i++) {
            grid.value[start_i+i].char = welcome[i];
        }
    });
});

onUnmounted(() => {

    // Close the private channel for the computer
    window.Echo.leave(`computer-${props.computerId}`);

    // Emit an event to switch to the real screen on the private chanel computer-{computerId}
    window.Echo.private(`computer-${props.computerId}`).whisper('switchToRealScreen', {});

    console.log("ComputerCraft terminal unmounted");
});

let display_mode = "Real Screen";

function switchToRealScreen(warn_client = true) {

    if (warn_client) {
        // Emit an event to switch to the real screen on the private chanel computer-{computerId}
        window.Echo.private(`computer-${props.computerId}`).whisper('switch_screen', {
            screen: "real"
        });
    }

    // Clear the grid without provoking a recursive call to switchToRealScreen
    grid.value.forEach((cell) => {
        cell.char = String.fromCharCode(0x00);
        cell.textColor = "#FFFFFF";
        cell.backgroundColor = "rgb(17, 17, 17)";
    });

    display_mode = "Real Screen";

    const welcome = "Ecran désactivé, real screen activé";
    const start_i = 51 * 5 + Math.floor((51 - welcome.length) / 2);
    for (let i = 0; i < welcome.length; i++) {
        grid.value[start_i+i].char = welcome[i];
    }
}

function switchToVirtualScreen() {
    window.Echo.private(`computer-${props.computerId}`).whisper('switch_screen', {
        screen: "virtual"
    });

    display_mode = "Virtual Screen";
}

function switchToHybridScreen() {
    window.Echo.private(`computer-${props.computerId}`).whisper('switch_screen', {
        screen: "hybrid"
    });

    display_mode = "Hybrid Screen";
}

function close() {
    emit('close');
}

const gridContainerStyle = computed(() => {
  return {
    border: `10px solid ${props.is_advanced ? '#C5C66D' : '#C3C3C3'}`,
  };
});

</script>

<template>
    <div class="terminal-container">
        <!-- Bouton de fermeture -->
        <button class="close-button" @click="close">X</button>
        
        <div class="info_text">Computer ID: {{ computerId }}</div>
        <div class="grid-container" :style="gridContainerStyle">
      <div
        class="grid"
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
        <div
          v-for="(cell, index) in grid"
          :key="index"
          :style="{
            backgroundColor: cell.backgroundColor,
            color: cell.textColor,
          }"
          class="cell"
        >
          {{ cell.char }}
        </div>
      </div>
    </div>

        <!-- Controls to switch between real, virtual, and hybrid screen -->
        <div>
            <div class="info_text">
                Mouse Position: X = {{ mousePosition.x }}, Y = {{ mousePosition.y }}
            </div>
            <div class="info_text">
                Display Mode: {{ display_mode }}
            </div>

            <div class="controls">
                <button @click="switchToRealScreen" class="select_button">Real Screen</button>
                <button @click="switchToVirtualScreen" class="select_button">Virtual Screen</button>
                <button @click="switchToHybridScreen" class="select_button">Hybrid Screen</button>
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

/* Autres styles existants */
.display_mode_label {
    font-size: 16px;
    color: #ffffff;
    text-align: center;
}

.select_button {
    background-color: #4CAF50;
    border: none;
    color: white;
    padding: 15px 32px;
    text-align: center;
    text-decoration: none;
    display: inline-block;
    font-size: 16px;
    margin: 4px 2px;
    cursor: pointer;
    border-radius: 12px;
}

.grid-container {
    margin-top: 20px;
    overflow: hidden;
    width: fit-content; /* Ajustez en fonction du contenu */
    height: fit-content; /* Ajustez en fonction du contenu */
    border-radius: 5px;
    border: 10px solid #b0b03f;
    padding: 5px;
}

@font-face {
    font-family: "CustomFont";
    src: url("/storage/fonts/HDfont.ttf") format("truetype");
}

.grid {
    display: grid;
    grid-template-columns: repeat(51, 10px);
    grid-template-rows: repeat(19, 16px);
    margin: 0; /* Enlevez les marges par défaut */
    background-color: #000000;
    outline: none;
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
    user-select: none; /* Désactive la sélection de texte */
    overflow: hidden; /* Assurez-vous que le contenu ne déborde pas */
}

.cell {
    width: 10px; /* Correspond à la largeur d'un caractère */
    height: 16px; /* Ajustez la hauteur pour éliminer l'espace */
    display: flex;
    justify-content: center;
    align-items: center;
    font-size: 16px; /* Ajustez cette valeur pour mieux remplir la cellule */
    font-family: "CustomFont", monospace;
    color: #ffffff;
    background-color: #000000;
    line-height: 16px; /* Aligne la hauteur de ligne avec celle de la cellule */
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

.selected {
    border: 1px solid #ffd700; /* Bordure fine de couleur or */
}
.info_text {
    margin-top: 10px;
    font-size: 16px;
    color: #ffffff;
    text-align: center;
}
</style>
