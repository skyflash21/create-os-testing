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
    self.name = "websocket" -- nom du module (doit etre unique)
    self.session_id = 0 -- id de la session courante
    self.version = nil -- version du module

    self.registered = false
    self.socket_id = nil
    self.channel = "presence-computer"
    self.ws = nil

    self.members = {}
    self.user = nil

    

    self.virtual_screen = false
    self.screenBuffer = {}
    self.color_palette = {{0,0,0}}

    return self
end

--[[
    Methode qui est execute lors de l'initialisation du modules
    @return void
]]--
function module:init()
    -- Recuperation du modele de message websocket
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

    print("Initialisation du module websocket")

    self.ws = http.websocket("ws://127.0.0.1:8080/app/7axlwwvifanpbi53vh1z")

    print("Connexion au serveur websocket")

    self:switch_to_virtual_screen()

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
        elseif event == "redstone" then
            print("Redstone event")
        end

        -- {"event":"SendMessage","data":"{\"message\":\"Hello from client\"}","channel":"presence"}
        
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
            return
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
        print("Inscription reussie")
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


    elseif message.event == "pusher_internal:member_added" then
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
    else
        print("Message inconnu : " .. message.event)
        print(textutils.serializeJSON(message))
    end
end

function module:switch_to_virtual_screen()

    self.virtual_screen = true

    -- Conversion des couleurs en 4 bits
    local colorsMap = {
        [1] = 0, [2] = 1, [4] = 2, [8] = 3,
        [16] = 4, [32] = 5, [64] = 6, [128] = 7,
        [256] = 8, [512] = 9, [1024] = 10, [2048] = 11,
        [4096] = 12, [8192] = 13, [16384] = 14, [32768] = 15
    }

    -- Fonction pour mettre à jour le tableau
    local function updateScreenBuffer(x, y, char, textColor, bgColor)
        local term_x, term_y = term.getSize()

        if x < 1 or x > term_x or y < 1 or y > term_y then
            error("Invalid coordinates")
        end

        self.screenBuffer[y] = self.screenBuffer[y]
        local text_rgb = {term.getPaletteColor(textColor)}
        local bg_rgb = {term.getPaletteColor(bgColor)}

        -- search if self.color_palette contains the colors
        local text_color_index = 0
        local bg_color_index = 0

        for i = 1, #self.color_palette do
            if self.color_palette[i][1] == text_rgb[1] and self.color_palette[i][2] == text_rgb[2] and self.color_palette[i][3] == text_rgb[3] then
                text_color_index = i
            end

            if self.color_palette[i][1] == bg_rgb[1] and self.color_palette[i][2] == bg_rgb[2] and self.color_palette[i][3] == bg_rgb[3] then
                bg_color_index = i
            end
        end

        if text_color_index == 0 then
            text_color_index = #self.color_palette + 1
            table.insert(self.color_palette, text_rgb)
        end

        if bg_color_index == 0 then
            bg_color_index = #self.color_palette + 1
            table.insert(self.color_palette, bg_rgb)
        end

        self.screenBuffer[y][x] = {char:byte(), text_color_index, bg_color_index}

    end

    -- Sauvegarde de la fonction originale term.write
    local originalWrite = term.write
    _G.global_originalWrite = originalWrite

    -- Remplacement de term.write
    term.write = function(str_to_write)
        local x, y = term.getCursorPos()
        local textColor = term.getTextColor()
        local bgColor = term.getBackgroundColor()

        for i = 1, #str_to_write do
            local char = str_to_write:sub(i, i)
            updateScreenBuffer(x, y, char, textColor, bgColor)
            x = x + 1
        end

        originalWrite(str_to_write)

        if not self.ws then
            return
        end

        local value_to_send = textutils.serializeJSON({
            event = "client-computer_message",
            data = {
                screen = self.screenBuffer,
                color_palette = self.color_palette,
            },
            channel = self.channel
        })

        self.ws.send( value_to_send )
    end

    local screen_x, screen_y = term.getSize()
    for y = 1, screen_y do
        for x = 1, screen_x do
            self.screenBuffer[y] = self.screenBuffer[y] or {}
            self.screenBuffer[y][x] = {string.byte(" "), 0, 0}
        end
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