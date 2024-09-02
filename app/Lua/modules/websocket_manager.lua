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
local expect = dofile("/rom/modules/main/cc/expect.lua").expect

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

    local redstone_int = 0

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
            print("Redstone event : " .. redstone_int)
            redstone_int = redstone_int + 1
        elseif event == "terminate" then
            term.setTextColor(colors.red)
            print("Passage de la couleur du texte en rouge")
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
    local width, height = term.getSize()
    local scaleX, scaleY = 1, 1

    -- Initialisation des variables
    local cursorX, cursorY = 1, 1
    local screenBuffer = {}
    local foregroundBuffer = {}
    local backgroundBuffer = {}
    
    -- Initialiser les tampons (buffers) pour chaque ligne de l'écran
    for y = 1, height do
        screenBuffer[y] = (" "):rep(width)
        foregroundBuffer[y] = ("\xF0"):rep(width)
        backgroundBuffer[y] = ("\xF0"):rep(width)
    end

    function term.write(text)
        text = tostring(text)
        expect(1, text, "string")
    
        -- Obtenir les couleurs actuelles du texte et du fond
        local textColor = {term.getPaletteColor(term.getTextColor())}
        local backgroundColor = {term.getPaletteColor(term.getBackgroundColor())}
    
        -- Logique pour écrire du texte à l'écran
        -- Envoi de la mise à jour via websocket
        local value_to_send = textutils.serializeJSON({
            event = "client-computer_write",
            data = {
                text = text,
                cursorX = cursorX,
                cursorY = cursorY,
                textColor = textColor,
                backgroundColor = backgroundColor
            },
            channel = self.channel
        })
    
        self.ws.send(value_to_send)
    
        -- Mettre à jour la position du curseur
        cursorX = cursorX + #text
    end
    

    function term.blit(text, fg, bg)
        expect(1, text, "string")
        expect(2, fg, "string")
        expect(3, bg, "string")
    
        -- Vérifier et ajuster la longueur des arguments
        local textLen = #text
        if #fg < textLen then fg = fg .. fg:sub(-1):rep(textLen - #fg) end
        if #bg < textLen then bg = bg .. bg:sub(-1):rep(textLen - #bg) end
    
        -- Préparer les couleurs pour l'envoi
        local fgColors = {}
        local bgColors = {}
    
        for i = 1, #text do
            table.insert(fgColors, {term.getPaletteColor(2 ^ (string.byte(fg, i) - 1))})
            table.insert(bgColors, {term.getPaletteColor(2 ^ (string.byte(bg, i) - 1))})
        end
    
        -- Envoi de la mise à jour via websocket
        local value_to_send = textutils.serializeJSON({
            event = "client-computer_blit",
            data = {
                text = text,
                fg = fgColors,
                bg = bgColors,
                cursorX = cursorX,
                cursorY = cursorY
            },
            channel = self.channel
        })
    
        self.ws.send(value_to_send)
    end

    function term.clear()
        for y = 1, height do
            screenBuffer[y], foregroundBuffer[y] = (" "):rep(width), string.char(0xF0):rep(width)
        end
        

        -- Envoi de la mise à jour via websocket
        local value_to_send = textutils.serializeJSON({
            event = "client-computer_clear",
            data = {},
            channel = self.channel
        })

        self.ws.send( value_to_send )
    end

    function term.clearLine()
        if cursorY >= 1 and cursorY <= height then
            screenBuffer[cursorY], foregroundBuffer[cursorY] = (" "):rep(width), string.char(0xF0):rep(width)
        end
        

        -- Envoi de la mise à jour via websocket
        local value_to_send = textutils.serializeJSON({
            event = "client-computer_clearLine",
            data = {
                cursorY = cursorY
            },
            channel = self.channel
        })

        self.ws.send( value_to_send )
    end

    function term.getCursorPos()
        return cursorX, cursorY
    end

    function term.setCursorPos(x, y)
        expect(1, x, "number")
        expect(2, y, "number")
        cursorX, cursorY = math.floor(x), math.floor(y)
    end

    function term.scroll(n)
        expect(1, n, "number")
    
        -- Logique pour faire défiler l'écran de n lignes
        if n > 0 then
            -- Supprimer les premières n lignes et ajouter n nouvelles lignes vides en bas
            for i = 1, height - n do
                screenBuffer[i] = screenBuffer[i + n]
                foregroundBuffer[i] = foregroundBuffer[i + n]
                backgroundBuffer[i] = backgroundBuffer[i + n]
            end
            for i = height - n + 1, height do
                screenBuffer[i] = (" "):rep(width)
                foregroundBuffer[i] = ("\xF0"):rep(width)
                backgroundBuffer[i] = ("\xF0"):rep(width)
            end
        elseif n < 0 then
            -- Supprimer les dernières n lignes et ajouter n nouvelles lignes vides en haut
            for i = height, 1 - n, -1 do
                screenBuffer[i] = screenBuffer[i + n]
                foregroundBuffer[i] = foregroundBuffer[i + n]
                backgroundBuffer[i] = backgroundBuffer[i + n]
            end
            for i = 1, -n do
                screenBuffer[i] = (" "):rep(width)
                foregroundBuffer[i] = ("\xF0"):rep(width)
                backgroundBuffer[i] = ("\xF0"):rep(width)
            end
        end
    
        -- Envoi de la mise à jour via WebSocket
        local value_to_send = textutils.serializeJSON({
            event = "client-computer_scroll",
            data = {
                n = n
            },
            channel = self.channel
        })
    
        self.ws.send(value_to_send)
    end
    

    term.clear()
    term.setCursorPos(1, 1)
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