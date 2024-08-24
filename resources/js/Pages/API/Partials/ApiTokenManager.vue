<script setup>
import { ref, computed } from 'vue';
import { useForm } from '@inertiajs/vue3';
import ActionMessage from '@/Components/ActionMessage.vue';
import ActionSection from '@/Components/ActionSection.vue';
import Checkbox from '@/Components/Checkbox.vue';
import ConfirmationModal from '@/Components/ConfirmationModal.vue';
import DangerButton from '@/Components/DangerButton.vue';
import DialogModal from '@/Components/DialogModal.vue';
import FormSection from '@/Components/FormSection.vue';
import InputError from '@/Components/InputError.vue';
import InputLabel from '@/Components/InputLabel.vue';
import SecondaryButton from '@/Components/SecondaryButton.vue';
import SectionBorder from '@/Components/SectionBorder.vue';
import TextInput from '@/Components/TextInput.vue';
import CustomButton from '@/Components/CustomButton.vue';

const props = defineProps({
    tokens: Array,
    availablePermissions: Array,
    defaultPermissions: Array,
});

const createApiTokenForm = useForm({
    name: '',
    permissions: props.defaultPermissions,
});

const updateApiTokenForm = useForm({
    permissions: [],
});

const deleteApiTokenForm = useForm({});

const displayingToken = ref(false);
const managingPermissionsFor = ref(null);
const apiTokenBeingDeleted = ref(null);

const createApiToken = () => {
    createApiTokenForm.post(route('api-tokens.store'), {
        preserveScroll: true,
        onSuccess: () => {
            displayingToken.value = true;
            createApiTokenForm.reset();
        },
    });
};

const copyToken = () => {
    const tokenField = document.getElementById('token_field');
    const range = document.createRange();
    range.selectNode(tokenField);
    window.getSelection().removeAllRanges();
    window.getSelection().addRange(range);
    document.execCommand('copy');
    window.getSelection().removeAllRanges();
    
    const copyTokenButton = document.getElementById('copy_token_button');
    copyTokenButton.innerText = 'Token copié';
    setTimeout(() => {
        copyTokenButton.innerText = 'Copier le token';
    }, 2000);
};

const copyCommand = () => {
    const commandField = document.getElementById('command_field');
    const range = document.createRange();
    range.selectNode(commandField);
    window.getSelection().removeAllRanges();
    window.getSelection().addRange(range);
    document.execCommand('copy');
    window.getSelection().removeAllRanges();
    
    const copyCommandButton = document.getElementById('copy_command_button');
    copyCommandButton.innerText = 'Commande copiée';
    setTimeout(() => {
        copyCommandButton.innerText = 'Copier la commande';
    }, 2000);
};

const manageApiTokenPermissions = (token) => {
    updateApiTokenForm.permissions = token.abilities;
    managingPermissionsFor.value = token;
};

const updateApiToken = () => {
    updateApiTokenForm.put(route('api-tokens.update', managingPermissionsFor.value), {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => (managingPermissionsFor.value = null),
    });
};

const confirmApiTokenDeletion = (token) => {
    apiTokenBeingDeleted.value = token;
};

const deleteApiToken = () => {
    deleteApiTokenForm.delete(route('api-tokens.destroy', apiTokenBeingDeleted.value), {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => (apiTokenBeingDeleted.value = null),
    });
};

// Fonction pour catégoriser dynamiquement les permissions
const categorizedPermissions = computed(() => {
    const categories = {};

    props.availablePermissions.forEach(permission => {
        const [category, action] = permission.split(':');
        if (!categories[category]) {
            categories[category] = [];
        }
        categories[category].push(permission);
    });

    return categories;
});

// Fonction pour cocher toutes les permissions d'une catégorie
const checkAllPermissions = (category) => {
    const permissionsToCheck = categorizedPermissions.value[category];
    permissionsToCheck.forEach(permission => {
        if (!createApiTokenForm.permissions.includes(permission)) {
            createApiTokenForm.permissions.push(permission);
        }
    });
};

// Fonction pour décocher toutes les permissions d'une catégorie
const uncheckAllPermissions = (category) => {
    createApiTokenForm.permissions = createApiTokenForm.permissions.filter(permission => {
        return !categorizedPermissions.value[category].includes(permission);
    });
};

// Fonction pour cocher toutes les permissions dans le modal
const checkAllModalPermissions = (category) => {
    const permissionsToCheck = categorizedPermissions.value[category];
    permissionsToCheck.forEach(permission => {
        if (!updateApiTokenForm.permissions.includes(permission)) {
            updateApiTokenForm.permissions.push(permission);
        }
    });
};

// Fonction pour décocher toutes les permissions dans le modal
const uncheckAllModalPermissions = (category) => {
    updateApiTokenForm.permissions = updateApiTokenForm.permissions.filter(permission => {
        return !categorizedPermissions.value[category].includes(permission);
    });
};
const imageUrl = ref('/storage/images/computer_craft_token.png');
</script>

<template>
  <div>
    <!-- Explication de comment utiliser les jetons API -->
    <div class="mb-4">
      <div class="flex flex-row space-x-4">
        <div class="w-1/2">
          <h2 class="text-lg font-medium text-gray-900 dark:text-white">Utiliser les jetons API dans ComputerCraft</h2>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
            Les jetons API permettent aux ordinateurs dans Minecraft (mod ComputerCraft) de s'authentifier auprès de notre application en votre nom.
            <br><br>
            Une fois un ordinateur chargé il va demander un jeton API pour pouvoir communiquer avec l'application.
            <br>
            Sans Jeton API, l'ordinateur ne démarera pas.
            <br><br>
            Pour obtenir un jeton API, cliquez sur le bouton "Créer un jeton API" ci-dessous.
            <br>
            Une fois le jeton créé, copiez-le et collez-le dans l'ordinateur.
            <br>
            Vous pouvez également gérer les jetons existants ci-dessous.
            <br><br>
            <span class="text-red-500">Attention: Ne partagez jamais votre jeton API avec quiconque !</span>
            <br>
            <br>
            Sur la droite, vous pouvez voir l'image que l'ordinateur de ComputerCraft affichera lorsqu'il demandera un jeton API.
          </p>
        </div>
        <div class="w-1/2">
          <div class="image-container">
            <img :src="imageUrl" alt="ComputerCraft Image">
          </div>
        </div>
      </div>
    </div>

    <SectionBorder />

    <!-- Générer un jeton API -->
    <FormSection @submitted="createApiToken">
      <template #title>
        Créer un jeton API
      </template>

      <template #description>
        Les jetons sont des clés permettant à des services tiers de s'authentifier auprès de l'application.
        <br><br>
        Ils sont uniques et possèdent des permissions spécifiques.
        <br><br>
        Le menu sur la droite permet de créer un jeton avec des permissions spécifiques.
      </template>

      <template #form>
        <!-- Nom du jeton -->
        <div class="col-span-6 sm:col-span-4">
          <InputLabel for="name" value="Nom" />
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">Attention, le nom du jeton ne peut pas être modifié.</p>

          <TextInput
            id="name"
            v-model="createApiTokenForm.name"
            type="text"
            class="mt-1 block w-full"
            autofocus
          />
          <InputError :message="createApiTokenForm.errors.name" class="mt-2" />
        </div>

        <!-- Permissions du jeton -->
        <div v-if="availablePermissions.length > 0" class="col-span-6">
          <InputLabel for="permissions" value="Permissions" />

          <div class="mt-2">
            <div v-for="(permissions, category) in categorizedPermissions" :key="category" class="mb-4">
              <div class="flex justify-between items-center">
                <h3 class="text-lg font-medium text-gray-900 dark:text-white capitalize">
                  {{ category.replace('_', ' ') }}
                </h3>
                <div>
                  <button type="button" class="text-sm text-blue-500 underline mr-2" @click="checkAllPermissions(category)">
                    Tout cocher
                  </button>
                  <button type="button" class="text-sm text-blue-500 underline" @click="uncheckAllPermissions(category)">
                    Tout décocher
                  </button>
                </div>
              </div>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div v-for="permission in permissions" :key="permission">
                  <label class="flex items-center">
                    <Checkbox v-model:checked="createApiTokenForm.permissions" :value="permission" />
                    <span class="ms-2 text-sm text-gray-600 dark:text-gray-400">{{ permission.split(':')[1] }}</span>
                  </label>
                </div>
              </div>
            </div>
          </div>
        </div>
      </template>

      <template #actions>
        <ActionMessage :on="createApiTokenForm.recentlySuccessful" class="me-3">
          Créé.
        </ActionMessage>

        <CustomButton
          type="primary"
          :disabled="createApiTokenForm.processing"
          @click="createApiToken"
          class="ms-auto"
        >
            Créer un jeton API
        </CustomButton>
      </template>
    </FormSection>

    <div v-if="tokens.length > 0">
      <SectionBorder />

      <!-- Gérer les jetons API -->
      <div class="mt-10 sm:mt-0">
        <ActionSection>
          <template #title>
            Gérer les jetons API
          </template>

          <template #description>
            Chaque jeton que vous créez peut être supprimé à tout moment si vous pensez qu'il a été compromis ou s'il n'est plus nécessaire.
          </template>

          <!-- Liste des jetons API -->
          <template #content>
            <div class="space-y-6">
              <div v-for="token in tokens" :key="token.id" class="flex items-center justify-between">
                <div class="break-all dark:text-white">
                  {{ token.name }}
                </div>

                <div class="flex items-center ms-2">
                  <div v-if="token.last_used_ago" class="text-sm text-gray-400">
                    Dernière utilisation {{ token.last_used_ago }}
                  </div>

                  <button
                    v-if="availablePermissions.length > 0"
                    class="cursor-pointer ms-6 text-sm text-gray-400 underline"
                    @click="manageApiTokenPermissions(token)"
                  >
                    Permissions
                  </button>

                  <button class="cursor-pointer ms-6 text-sm text-red-500" @click="confirmApiTokenDeletion(token)">
                    Supprimer
                  </button>
                </div>
              </div>
            </div>
          </template>
        </ActionSection>
      </div>
    </div>

    <!-- Modal de valeur du jeton -->
    <DialogModal :show="displayingToken" @close="displayingToken = false">
      <template #title>
        Jeton API
      </template>

      <template #content>
        <div>
          <p class="text-sm text-gray-500 dark:text-gray-400">Voici votre nouveau jeton API.</p>
          <br>
          <p class="text-red-500">Pour votre sécurité, il ne sera plus affiché.<br>Assurez-vous de le copier maintenant.</p>
        </div>

        <label class="block font-medium text-sm text-gray-700 dark:text-gray-200 mt-4">Token</label>
        <div v-if="$page.props.jetstream.flash.token" class=" bg-gray-100 dark:bg-gray-900 px-4 py-2 rounded font-mono text-sm text-gray-500 break-all" id="token_field">
          {{ $page.props.jetstream.flash.token }}
        </div>
        <CustomButton @click="copyToken" id="copy_token_button" type="primary">
          Copier le token
        </CustomButton>

        <label class="block font-medium text-sm text-gray-700 dark:text-gray-200 mt-4">Commande wget</label>
        <div v-if="$page.props.jetstream.flash.token" class=" bg-gray-100 dark:bg-gray-900 px-4 py-2 rounded font-mono text-sm text-gray-500 break-all" id="command_field">
          wget run http://127.0.0.1:8000/api/startup {{ $page.props.jetstream.flash.token }}
        </div>
        <CustomButton @click="copyCommand" id="copy_command_button" type="primary">
          Copier la commande    
        </CustomButton>
      </template>

      <template #footer>
        <SecondaryButton @click="displayingToken = false">
          Fermer
        </SecondaryButton>
      </template>
    </DialogModal>

    <!-- Modal de permissions du jeton API -->
    <DialogModal :show="managingPermissionsFor != null" @close="managingPermissionsFor = null">
      <template #title>
        Permissions du Jeton API
      </template>

      <template #content>
        <div v-for="(permissions, category) in categorizedPermissions" :key="category" class="mb-4">
          <div class="flex justify-between items-center">
            <h3 class="text-lg font-medium text-gray-900 dark:text-white capitalize">
              {{ category.replace('_', ' ') }}
            </h3>
            <div>
              <button type="button" class="text-sm text-blue-500 underline mr-2" @click="checkAllModalPermissions(category)">
                Tout cocher
              </button>
              <button type="button" class="text-sm text-blue-500 underline" @click="uncheckAllModalPermissions(category)">
                Tout décocher
              </button>
            </div>
          </div>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div v-for="permission in permissions" :key="permission">
              <label class="flex items-center">
                <Checkbox v-model:checked="updateApiTokenForm.permissions" :value="permission" />
                <span class="ms-2 text-sm text-gray-600 dark:text-gray-400">{{ permission.split(':')[1] }}</span>
              </label>
            </div>
          </div>
        </div>
      </template>

      <template #footer>
        <SecondaryButton @click="managingPermissionsFor = null">
          Annuler
        </SecondaryButton>

        <CustomButton
          type="primary"
          :disabled="updateApiTokenForm.processing"
          @click="updateApiToken"
          class="ms-3"
        >
            Mettre à jour
        </CustomButton>
      </template>
    </DialogModal>

    <!-- Modal de confirmation de suppression de jeton -->
    <ConfirmationModal :show="apiTokenBeingDeleted != null" @close="apiTokenBeingDeleted = null">
      <template #title>
        Supprimer le Jeton API
      </template>

      <template #content>
        Êtes-vous sûr de vouloir supprimer ce jeton API ?
      </template>

      <template #footer>
        <SecondaryButton @click="apiTokenBeingDeleted = null">
          Annuler
        </SecondaryButton>

        <DangerButton
          class="ms-3"
          :class="{ 'opacity-25': deleteApiTokenForm.processing }"
          :disabled="deleteApiTokenForm.processing"
          @click="deleteApiToken"
        >
          Supprimer
        </DangerButton>
      </template>
    </ConfirmationModal>
  </div>
</template>

<style scoped>
.image-container {
  width: 100%;
  height: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
}
</style>