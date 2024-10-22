<template>
    <div
        class="sidebar"
        :class="{
            'sidebar-visible': sidebarVisible,
            'sidebar-hidden': !sidebarVisible,
        }"
        @transitionend="onSidebarTransitionEnd"
        v-show="true"
    >
        <div class="sidebar-content">
            <h2 class="text-lg font-semibold mt-4 pb-2 text-white text-center">
                Liste des ordinateurs
            </h2>
            <div class="mb-4 flex p-2 border-b border-t">
                <div class="flex items-center space-x-2">
                    <button @click="sortBy('id')" :class="getButtonClass('id')">
                        Trier par ID
                    </button>
                    <button @click="sortBy('name')" :class="getButtonClass('name')" >
                        Trier par Nom
                    </button>
                </div>
                <div class="flex items-center space-x-2 flex-grow justify-end">
                    <button
                        @click="toggleSortOrder"
                        :class="getButtonClassOrder()"
                    >
                        {{ sort_type }}
                    </button>
                </div>
            </div>
            <div
                class="grid grid-cols-3 p-2 gap-5 overflow-y-auto overflow-x-hidden scrollbar-custom max-h-[calc(100vh-10rem)]"
            >
                <div
                    v-for="computer in sortedComputers"
                    :key="computer.computer_id"
                    @click="selectComputer(computer)"
                    :class="[
                        'relative flex flex-col items-center space-y-2 transition-transform duration-150 hover:scale-105 cursor-pointer p-2 rounded-lg shadow-lg',
                        {
                            'bg-gray-600 border-orange-500 border-4':
                                selectedComputer &&
                                selectedComputer.computer_id ===
                                    computer.computer_id,
                            'bg-gray-700 border-gray-700 border-4': !(
                                selectedComputer &&
                                selectedComputer.computer_id ===
                                    computer.computer_id
                            ),
                        },
                    ]"
                >
                    <img
                        :src="
                            computer.is_advanced
                                ? advanced_computer_logo
                                : computer_logo
                        "
                        alt="Computer"
                        class="w-16 h-16"
                    />
                    <span class="text-sm font-semibold text-center text-white">
                        {{ computer.computer_id }} :
                        {{ computer.truncated_name }}
                    </span>
                    <div
                        class="absolute bottom-2 right-2 w-3 h-3 rounded-full"
                        :class="{
                            'bg-green-500': computer.isConnected,
                            'bg-red-500': !computer.isConnected,
                        }"
                    ></div>
                </div>
            </div>
        </div>

        <!-- Languette cliquable pour ouvrir/fermer la sidebar -->
        <div
            class="sidebar-tab"
            @click="toggleSidebar"
            :disabled="sidebarAnimating"
        >
            <img :src="computer_icon" alt="Computer" />
        </div>
    </div>
</template>

<script setup>
import { computed, ref } from "vue";

const props = defineProps({
    computers: Array,
    selectedComputer: Object,
    connectedComputers: Array,
    computer_logo: String,
    advanced_computer_logo: String,
});

const emit = defineEmits(["selectComputer", "sortBy", "toggleSortOrder"]);

const sidebarVisible = ref(false); // État de la visibilité de la sidebar
const sidebarAnimating = ref(false); // Suivi du statut de l'animation (utilisé pour la transition)

const toggleSidebar = () => {
    sidebarAnimating.value = true;
    sidebarVisible.value = !sidebarVisible.value;
};

// Fonction appelée lorsque la transition se termine
const onSidebarTransitionEnd = () => {
    sidebarAnimating.value = false;
};

const computer_icon = ref("/storage/Documentation/computer.png");

const sortKey = ref("id");
const sortOrder = ref("asc");
let sort_type = "Croissant";

const sortedComputers = computed(() => {
    const sorted = [...props.computers].sort((a, b) => {
        if (sortKey.value === "id") {
            return sortOrder.value === "asc"
                ? a.computer_id - b.computer_id
                : b.computer_id - a.computer_id;
        } else if (sortKey.value === "name") {
            return sortOrder.value === "asc"
                ? a.computer_name.localeCompare(b.computer_name)
                : b.computer_name.localeCompare(a.computer_name);
        }
    });

    return sorted.map((computer) => ({
        ...computer,
        truncated_name:
            computer.computer_name.length > 9
                ? `${computer.computer_name.slice(0, 6)}...`
                : computer.computer_name,
        isConnected: props.connectedComputers.includes(computer.computer_id),
    }));
});

const selectComputer = (computer) => {
    emit("selectComputer", computer);

    if (sidebarVisible.value) {
        toggleSidebar();
    }
};

const sortBy = (key) => {
    sortKey.value = key;
    emit("sortBy", key);
};

const toggleSortOrder = () => {
    sortOrder.value = sortOrder.value === "asc" ? "desc" : "asc";
    emit("toggleSortOrder");
};

const getButtonClassOrder = () => {
    if (sortOrder.value === "desc") {
        sort_type = "Décroissant";
        return "px-3 py-1 text-gray-400 hover:text-white border-none rounded text-gray-400";
    } else {
        sort_type = "Croissant";
        return "px-3 py-1 text-gray-400 hover:text-white border-none rounded text-gray-400";
    }
};

const getButtonClass = (key) => {
    return sortKey.value === key
        ? "px-3 py-1 text-gray-400 hover:text-white border-none rounded text-white"
        : "px-3 py-1 text-gray-400 hover:text-white border-none rounded text-gray-400";
};
</script>

<style scoped>
@media (max-width: 768px) {
    .btn {
        right: 1em;
    }
}

/* Style de base pour le layout */
.content {
    padding: 20px;
}

/* Sidebar */
.sidebar {
    position: fixed;
    right: 0;
    width: 500px;
    height: 100%;
    background-color: #353b48;
    box-shadow: -2px 0 5px rgba(0, 0, 0, 0.1);
    transition: transform 0.3s ease-in-out;
    transform: translateX(100%); /* Par défaut, la sidebar est hors écran */
}

/* Afficher la sidebar */
.sidebar-visible {
    transform: translateX(0%);
}

/* Cacher la sidebar, mais garder la languette à 5% */
.sidebar-hidden {
    transform: translateX(100%);
}

/* Languette pour ouvrir/fermer la sidebar */
.sidebar-tab {
    position: absolute;
    top: 50%;
    right: 100%; /* Positionne la languette juste à côté de la sidebar */
    width: 60px;
    height: 60px;
    background-color: #353b48;
    color: #000;
    text-align: center;
    line-height: 60px;
    cursor: pointer;
    transform: translateY(-50%);
    border-radius: 5px 0 0 5px;
    box-shadow: -2px 0 5px rgba(0, 0, 0, 0.1);
    padding: 10px;

    display: flex;
    justify-content: center;

    /* Ajouter une couleur sur les bordures */
    border: 5px solid #718093;
}

.sidebar-tab:hover {
    background-color: #aaa;
}
</style>
