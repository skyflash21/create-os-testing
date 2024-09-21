local function execute(user_interface)
    user_interface:print_to_buffer("Liste des commandes disponibles:", colors.yellow)
    user_interface:print_to_buffer("  help: Affiche la liste des commandes disponibles", colors.yellow)
    user_interface:print_to_buffer("  clear: Efface le contenu de l'écran", colors.yellow)
    user_interface:print_to_buffer("  exit: Quitte la console interactive", colors.yellow)
    user_interface:print_to_buffer("  echo <texte>: Affiche le texte spécifié", colors.yellow)
    user_interface:print_to_buffer("  ls: Liste les fichiers et dossiers du répertoire courant", colors.yellow)
end

return {
    execute = execute
}