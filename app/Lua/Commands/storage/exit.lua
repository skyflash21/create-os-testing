local function execute(user_interface)
    user_interface:print_line_to_buffer()
    user_interface:print_to_buffer("Sortie de l'interface : Storage", colors.lightBlue, true)
    user_interface:print_line_to_buffer()
    user_interface.domain = "user"
end

return {
    execute = execute
}