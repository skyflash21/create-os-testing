<script setup>
import { ref, onMounted } from "vue";

const rows = 19;
const cols = 51;

function createGrid() {
    const grid = [];
    for (let i = 0; i < rows * cols; i++) {
        grid.push({
            char: String.fromCharCode(0x00), // Utilisez ici le code du caractère spécifique que vous souhaitez
            textColor: "#FFFFFF", // Couleur du texte
            backgroundColor: "#000000", // Couleur de fond
        });
    }
    return grid;
}

const grid = ref(createGrid());
const currentIndex = ref(0);
const selectedColorType = ref("text");

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
    const validChars = /^[a-zA-Z0-9\s!"#$%&'()*+,-./:;<=>?@[\\\]^_{|}~]$/;

    if (validChars.test(event.key)) {
        if (currentIndex.value >= 0 && currentIndex.value < grid.value.length) {
            grid.value[currentIndex.value].char = event.key;
            grid.value[currentIndex.value].textColor = textColor.value;
            grid.value[currentIndex.value].backgroundColor =
                backgroundColor.value;

            // Move to the next cell, or to the beginning of the next line if at the end of a row
            if ((currentIndex.value + 1) % cols !== 0) {
                currentIndex.value += 1;
            } else if (currentIndex.value + 1 < grid.value.length) {
                currentIndex.value += 1;
            }
        }
    } else {
        event.preventDefault();
    }
}

const mousePosition = ref({ x: 0, y: 0 });

function updateMousePosition(event) {
    const { x, y } = getGridCoordinates(event);
    mousePosition.value = { x, y };
}

function handleKeyup(event) {
    console.log("Keyup event:", event.key);
}

function handleMouseClick(event) {
    const { x, y } = getGridCoordinates(event);
    console.log("Mouse click event at grid:", x, y);
}

function handleMouseUp(event) {
    const { x, y } = getGridCoordinates(event);
    console.log("Mouse up event at grid:", x, y);
}

function handleMouseDrag(event) {
    if (event.buttons === 1) {
        // Only log if the left mouse button is held down
        const { x, y } = getGridCoordinates(event);
        console.log("Mouse drag event at grid:", x, y);
    }

    updateMousePosition(event);
}

function handleMouseScroll(event) {
    const { x, y } = getGridCoordinates(event);
    console.log(
        "Mouse scroll event at grid:",
        x,
        y,
        "Scroll delta:",
        event.deltaY
    );
}

function handlePaste(event) {
    const paste = (event.clipboardData || window.clipboardData).getData("text");
    console.log("Paste event:", paste);
}

onMounted(() => {
    window.addEventListener("resize", handleTermResize);

    window.addEventListener("computer_write", (event) => {
        const data = event.detail;
        const { text, cursorX, cursorY, textColor, backgroundColor } = data;

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
    });

    window.addEventListener("computer_blit", (event) => {
        const data = event.detail;
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
    });

    window.addEventListener("computer_clear", () => {
        // Clear the entire grid
        grid.value.forEach((cell) => {
            cell.char = String.fromCharCode(0x00);
            cell.textColor = "#FFFFFF";
            cell.backgroundColor = "#000000";
        });
    });

    window.addEventListener("computer_clearLine", (event) => {
        const { cursorY } = event.detail;

        // Clear the specified line
        const startIndex = (cursorY - 1) * cols;
        for (let i = 0; i < cols; i++) {
            grid.value[startIndex + i].char = String.fromCharCode(0x00);
            grid.value[startIndex + i].textColor = "#FFFFFF";
            grid.value[startIndex + i].backgroundColor = "#000000";
        }
    });

    window.addEventListener("computer_scroll", (event) => {
        const { n } = event.detail;

        if (n > 0) {
            // Scroll up
            grid.value.splice(0, n * cols);
            for (let i = 0; i < n * cols; i++) {
                grid.value.push({
                    char: String.fromCharCode(0x00),
                    textColor: "#FFFFFF",
                    backgroundColor: "#000000"
                });
            }
        } else if (n < 0) {
            // Scroll down
            grid.value.splice(n * cols);
            for (let i = 0; i < -n * cols; i++) {
                grid.value.unshift({
                    char: String.fromCharCode(0x00),
                    textColor: "#FFFFFF",
                    backgroundColor: "#000000"
                });
            }
        }
    });

    function handleTermResize(event) {
        console.log("Term resize event:", window.innerWidth, window.innerHeight);
    }
});
</script>

<template>
    <div>
        <div class="grid-container">
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

        <div class="mouse-position">
            Mouse Position: X = {{ mousePosition.x }}, Y = {{ mousePosition.y }}
        </div>
    </div>
</template>

<style scoped>
.grid-container {
    margin-top: 20px;
    overflow: hidden;
    width: fit-content; /* Adjust to the content */
    height: fit-content; /* Adjust to the content */
    border-radius: 5px;
    border: 10px solid #b0b03f;
}

@font-face {
    font-family: "CustomFont";
    src: url("/storage/fonts/HDfont.ttf") format("truetype");
}

.grid {
    display: grid;
    grid-template-columns: repeat(51, 10px);
    grid-template-rows: repeat(19, 16px);
    margin: 0; /* Remove any default margins */
    background-color: #000000;
    outline: none;
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.5);
    user-select: none; /* Disable text selection */
    overflow: hidden; /* Ensure content does not overflow */
}

.cell {
    width: 10px; /* Correspond à la largeur d'un caractère */
    height: 16px; /* Ajustement de la hauteur pour éliminer le gap */
    display: flex;
    justify-content: center;
    align-items: center;
    font-size: 16px; /* Ajustez cette valeur pour que le caractère remplisse mieux la cellule */
    font-family: "CustomFont", monospace;
    color: #ffffff;
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
    color: #ffffff;
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
    border-color: #ffd700;
    transform: scale(1.1);
}

.selected {
    border: 1px solid #ffd700; /* Fine border with a gold color */
}
.mouse-position {
    margin-top: 10px;
    font-size: 16px;
    color: #ffffff;
    text-align: center;
}
</style>
