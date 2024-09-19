local function execute(user_interface)
    local function check_for_update()
        user_interface:print_to_buffer("    Recuperation des versions", colors.lightBlue)
        local latest_version = api.get_code_version("\\Base\\startup.lua") or "erreur"
        user_interface:print_to_buffer("        Version serveur  : "..latest_version, colors.white)
        local current_version = settings.get("version") or "erreur"
        user_interface:print_to_buffer("        Version actuelle : "..current_version, colors.white)

        if latest_version == current_version then
            user_interface:print_to_buffer("        Aucune mise a jour disponible", colors.green)
            return
        elseif latest_version > current_version then
            user_interface:print_to_buffer("        Mise a jour disponible", colors.yellow)
        else
            user_interface:print_to_buffer("        Version actuelle plus recente que la version serveur", colors.red)
            user_interface:print_to_buffer("        WTF BRO ???", colors.red)
        end
    end
    
    local function get_latest_version()
        user_interface:print_to_buffer("    Recuperation de latest_version_code", colors.lightBlue)
    end
    
    local function get_latest_version_code()
        user_interface:print_to_buffer("    Recuperation de latest_version_code", colors.lightBlue)
    end

    user_interface:print_to_buffer("Mise a jour en cours :", colors.lightBlue)
    check_for_update()
    get_latest_version()
    get_latest_version_code()
end




return {
    execute = execute
}