local function execute(user_interface)
    local size_x, size_y = term.getSize()
    local module_list = _G.parallel.modules

    user_interface:print_to_buffer("Recuperation des versions des modules", colors.lightBlue)

    user_interface:print_to_buffer(string.rep("-", size_x), colors.lightBlue)
    user_interface:print_to_buffer("    l- : version local", colors.lightBlue)
    user_interface:print_to_buffer("    s- : version serveur", colors.lightBlue)

    user_interface:print_to_buffer(string.rep("-", size_x), colors.lightBlue)

    for i, module in ipairs(module_list) do
        local module_name  = module[2]
        local module_version  = module[3]

        local path = module[4]
        
        local latest_version = api.get_code_version(path) or "$"

        user_interface:print_to_buffer("    " .. module_name .. " l-" .. module_version .. " s-" .. latest_version, colors.lightBlue)
    end

    user_interface:print_to_buffer(string.rep("-", size_x), colors.lightBlue)
end

return {
    execute = execute
}