local function execute(user_interface)
    local storage_module = parallel:getModule("storage")
    if storage_module == nil then
        user_interface:print_to_buffer("Module de stockage non charge", colors.red)
        return
    end

    user_interface:print_to_buffer("Storage Refresh ...")
    storage_module.global_inventory.refreshStorage()
    user_interface:print_to_buffer("")
    user_interface:print_to_buffer("Liste des Items :", colors.white, true)
    local all_items = storage_module.global_inventory.listNames()
    user_interface:print_line_to_buffer()
    for name, item in pairs(all_items) do
        user_interface:print_to_buffer(item, colors.white,true)
    end
    user_interface:print_line_to_buffer()
end

return {
    execute = execute
}