--[[
    Cette classe est un exemple de module.

    Les modules sont des classes qui permettent de gérer des fonctionnalités,
    un modules ne doit couvrir qu'une seule fonctionnalité.

    Les modules sont chargé par le bootstrap et sont ensuite executé en parallèle avec le thread_manager.

    Les modules sont des classes qui doivent implémenter les méthodes suivantes:
        - new() -> constructeur
        - init() -> méthode qui est executé lors de l'initialisation du modules
        - run() -> méthode qui est executé elle contient une boucle infinie qui permet de gérer les événements
        - command_run(type, arguments) -> méthode qui est executé lors de l'appel de la commande run
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

    -- Initialisation des variables inhérentes au module
    
    return self
end

--[[
    Méthode qui est executé lors de l'initialisation du modules
    @return void
]]--
function module:init()
end

--[[
    Méthode qui est executé lors de l'appel de la commande run
    @param int current_session_id string id de la session courante
    @return void
]]--
function module:run(current_session_id)
    -- Vérification de la variable current_session_id
    if current_session_id == nil or type(current_session_id) ~= "number" then
        error("current_session_id must be a number, current type is " .. type(current_session_id))
    end

    -- On mets à jour la variable session_id
    self.session_id = current_session_id

    -- Boucle infinie pour gérer les événements
    while true do
        -- Récupération des événements
        local event, arg1, arg2, arg3 = os.pullEvent()

        -- Nettoyage des valeurs
        arg1 = arg1 or "nil"
        arg2 = arg2 or "nil"
        arg3 = arg3 or "nil"

        -- Gestion des événements obligatoires
        if event == "stop_module" and arg1 == self.session_id then

            return
        elseif event == "complete_websocket_message" then
            self:handle_websocket_message(arg1)
        end

        -- Gestion des événements inhérents au module

    end
end

--[[
    Méthode qui permet de gérer les messages websocket
    @param string message message websocket
    @return void
]]--
function module:handle_websocket_message(message)
end

--[[
    Méthode qui est executé lors de l'appel de la commande run
    @param string type type de la commande
    @param table arguments arguments de la commande
    @return void
]]--
function module:command_run(type, arguments)
end

return module