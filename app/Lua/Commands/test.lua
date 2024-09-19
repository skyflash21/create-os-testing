local function execute(user_interface)
    user_interface:print_to_buffer("Test Effectue correctement", colors.lightBlue)
end

return {
    execute = execute
}