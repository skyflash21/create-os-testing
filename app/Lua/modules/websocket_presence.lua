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
    self.name = "websocket_presence" -- nom du module (doit etre unique)
    self.session_id = 0 -- id de la session courante
    self.version = nil -- version du module
    self.path = nil -- chemin du module

    self.registered = false
    self.socket_id = nil
    self.channel = "presence-computer"
    self.ws = nil

    self.members = {}
    self.user = nil

    return self
end

--[[
    Methode qui est execute lors de l'initialisation du modules
    @return void
]]--
function module:init(current_session_id)
    -- Vérification de la variable current_session_id
    if current_session_id == nil or type(current_session_id) ~= "number" then
        error("current_session_id must be a number, current type is " .. type(current_session_id))
    end

    -- On met à jour la variable session_id
    self.session_id = current_session_id

    -- Recuperation du modele de message websocket
    print("Initialisation du module websocket_presence")
    local erreur_ws = nil
    self.ws, erreur_ws = http.websocket("ws://127.0.0.1:8080/app/oqybjzsxnkzwqbzhpsg6")

    if self.ws then
        print("Connection initie, en attente de la reponse.")
    else
        error("Erreur lors de la connexion au serveur websocket : " .. erreur_ws)
    end

    while self.registered == false do
        local event, url, response = os.pullEvent("websocket_message")
        
        local message = textutils.unserializeJSON(response)
    
        if message.event == "pusher:connection_established" then
            local data = textutils.unserializeJSON(message.data)
            self.socket_id = data["socket_id"]

            local auth_data = {
                channel_name = self.channel,
                socket_id = self.socket_id
            }

            print("Authentification en cours")
            local response, fail_string, http_failing_response = api.post("auth_computer", auth_data)

            if response == nil then
                print("Erreur lors de l'authentification")
                print(fail_string)
                _G.status = "critical_error"
                _G.error_detail = http_failing_response
                sleep(0)
            end

            response = textutils.unserializeJSON(response)
            local auth = response["auth"]
            local channel_data = response["channel_data"]
            self.channel = response["channel_name"]

            self.ws.send(textutils.serializeJSON({
                event = "pusher:subscribe",
                data = {
                    channel = self.channel,
                    auth = auth,
                    channel_data = channel_data
                }
            }))

            print("Demande d'inscription : " .. self.channel)
        elseif message.event == "pusher:subscription_succeeded" or message.event == "pusher_internal:subscription_succeeded" then
            print("Inscription reussie : " .. self.channel)
            self.registered = true

            -- Reinitialiser les membres pour eviter les doublons
            self.members = {}

            local data = textutils.unserializeJSON(message.data)
            local presence = data["presence"]
            
            for key, value in pairs(presence["hash"]) do
                if value.isUser then
                    print("Utilisateur : " .. value.name)
                    self.user = value
                else
                    print("Ordinateur : " .. value.name)
                    self.members[value.id] = value
                end
            end
        else
            term.setTextColor(colors.red)
            print("Non inscrit : " .. message.event)
            print(message.data)
            term.setTextColor(colors.white)
        end
    end
end



--[[
    Methode qui est execute lors de l'appel de la commande run
    @param int current_session_id string id de la session courante
    @return void
]]--
function module:run(current_session_id)
    -- Vérification de la variable current_session_id
    if current_session_id == nil or type(current_session_id) ~= "number" then
        error("current_session_id must be a number, current type is " .. type(current_session_id))
    end

    -- On met à jour la variable session_id
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
        elseif event == "websocket_message" then
            self:handle_websocket_message(arg2)
        elseif event == "websocket_closed" then
            error("Connexion " .. self.name .. " fermee")
        end
    end
end

--[[
    Methode qui permet de s'inscrire à un evenement
    @param string event nom de l'evenement
    @return void
]]--
function module:register_event(event)
    
end

--[[
    Methode qui permet de gerer les messages websocket
    @param string message message websocket
    @return void
]]--
function module:handle_websocket_message(message)
    message = textutils.unserializeJSON(message)
    
    if message.event == "pusher_internal:member_added" then
        local user_info = message.data.user_info
        if user_info.isUser then
            print("Utilisateur ajoute : " .. user_info.name)
            self.user = user_info
        else
            print("Ordinateur ajoute : " .. user_info.name)
            self.members[user_info.id] = user_info
        end
    elseif message.event == "pusher_internal:member_removed" then
        local user_id = message.data.user_id
        if user_id == "-1" then
            print("Utilisateur supprime")
            self.user = nil
        else
            print("Ordinateur supprime " .. user_id)
            self.members[user_id] = nil
        end
    elseif message.event == "pusher:ping" then
        self.ws.send(textutils.serializeJSON({
            event = "pusher:pong",
            data = {}
        }))
    elseif not self.registered then
        print("Non inscrit : " .. message.event)
        return
    end
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