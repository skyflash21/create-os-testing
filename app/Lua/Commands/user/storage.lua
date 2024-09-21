local function execute(user_interface)
    user_interface:print_line_to_buffer()
    user_interface:print_to_buffer("Mise en route de l'interface du module :", colors.lightBlue, true)
    user_interface:print_to_buffer("Storage Manager", colors.lightBlue, true)
    user_interface:print_line_to_buffer()
    user_interface.domain = "Storage"
end

return {
    execute = execute
}