--[[
    Cette classe est un exemple de module.

    Les modules sont des classes qui permettent de gerer des fonctionnalites,
    un modules ne doit couvrir qu'une seule fonctionnalite.

    Les modules sont charge par le bootstrap et sont ensuite execute en parallele avec le thread_manager.

    Les modules sont des classes qui doivent implementer les methodes suivantes:
        - new() -> constructeur
        - init() -> methode qui est execute lors de l'initialisation du modules
        - run() -> methode qui est execute elle contient une boucle infinie qui permet de gerer les evenements
        - command_run(type, arguments) -> methode qui est execute lors de l'appel de la commande run
]]--

local module = {}
module.__index = module

--[[
    Constructeur de la classe, retourne une instance
    return self
]]--
function module.new()
    local self = setmetatable({}, module)

    -- Initialisation des variables obligatoires
    self.name = "storage" -- nom du module (doit être unique)
    self.session_id = 0 -- id de la session courante
    self.version = nil -- version du module
    self.path = nil -- chemin du module

    -- Initialisation des variables inherentes au module
    self.invlib = nil
    self.global_inventory = nil
    
    return self
end

--[[
    Methode qui est execute lors de l'initialisation du modules
    @return void
]]--
function module:init()
    print("Storage Manager en cours d'initialisation")
    self.invlib = api.get_code("\\Components\\abstractInvLib.lua")
    print("abstractInvLib charge")

    local all_peripheral = peripheral.getNames()

    local inventory_found = {}

    print("Recherche des inventaires")
    local done = 0
    local cursor_x, cursor_y = term.getCursorPos()
    for _, peripheral_name in pairs(all_peripheral) do
        if peripheral.hasType(peripheral_name, "inventory") then
            done = done + 1
            term.clearLine()
            term.write("Proportion d'inventaire " .. done .. " / " .. #all_peripheral)
            term.setCursorPos(cursor_x, cursor_y)
            table.insert(inventory_found, peripheral_name)
        end
    end
    print("")
    print("Inventaires trouves : " .. #inventory_found)
    print("Injections des inventaires dans la librairie")
    self.global_inventory = self.invlib(inventory_found)
    print("Inventaires injectes")
end

--[[
    Methode qui est execute lors de l'appel de la commande run
    @param int current_session_id string id de la session courante
    @return void
]]--
function module:run(current_session_id)
    -- Verification de la variable current_session_id
    if current_session_id == nil or type(current_session_id) ~= "number" then
        error("current_session_id must be a number, current type is " .. type(current_session_id))
    end

    -- On mets à jour la variable session_id
    self.session_id = current_session_id

    -- Boucle infinie pour gerer les evenements
    while true do
        -- Recuperation des evenements
        local event, arg1, arg2, arg3 = os.pullEvent()

        -- Nettoyage des valeurs
        arg1 = arg1 or "nil"
        arg2 = arg2 or "nil"
        arg3 = arg3 or "nil"

        -- Gestion des evenements obligatoires
        if event == "stop_module" and arg1 == self.session_id then

            return
        elseif event == "complete_websocket_message" then
            self:handle_websocket_message(arg1)
        end

        -- Gestion des evenements inherents au module

    end
end

--[[
    Methode qui permet de gerer les messages websocket
    @param string message message websocket
    @return void
]]--
function module:handle_websocket_message(message)
end

--[[
    Methode qui est execute lors de l'appel de la commande run
    @param string type type de la commande
    @param table arguments arguments de la commande
    @return void
]]--
function module:command_run(type, arguments)
end

return module