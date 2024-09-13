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
    self.name = "websocket_private" -- nom du module (doit etre unique)
    self.session_id = 0 -- id de la session courante
    self.version = nil -- version du module

    self.registered = false
    self.socket_id = nil
    self.channel = "private-computer-" .. os.getComputerID()
    self.ws = nil

    self.mode = "real"

    -- Sauvegarde des méthodes originales du terminal
    self.original_term = {}
    self.original_term.write = term.write
    self.original_term.blit = term.blit
    self.original_term.clear = term.clear
    self.original_term.clearLine = term.clearLine
    self.original_term.getCursorPos = term.getCursorPos
    self.original_term.setCursorPos = term.setCursorPos
    self.original_term.scroll = term.scroll

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
    self.ws = http.websocket("ws://127.0.0.1:8080/app/oqybjzsxnkzwqbzhpsg6")

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
            local response, fail_string, http_failing_response = api.post("auth_computer_private", auth_data)

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

            -- Envoyer le changement de mode via WebSocket
            local value_to_send = textutils.serializeJSON({
                event = "client-computer_switchToRealScreen",
                data = {
                    computer_id = os.getComputerID()
                },
                channel = self.channel
            })

            self.ws.send(value_to_send)

            local value_to_send = textutils.serializeJSON({
                event = "client-computer_connected",
                data = {
                    computer_id = os.getComputerID()
                },
                channel = self.channel
            })

            self.ws.send(value_to_send)

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
        elseif event == "terminate" then
            if self.mode ~= "real" then
                self:switch_to_real_screen()

                -- Envoyer le changement de mode via WebSocket
                local value_to_send = textutils.serializeJSON({
                    event = "client-computer_switchToRealScreen",
                    data = {
                        computer_id = os.getComputerID()
                    },
                    channel = self.channel
                })

                self.ws.send(value_to_send)
            end
        elseif event == "char" then
            term.write(arg1)
        elseif event == "websocket_closed" then
            error("Connexion " .. self.name .. " fermee")
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

    if message.data and message.data.computerId and message.data.computerId ~= os.getComputerID() then
        return
    end
    
    if message.event == "pusher:ping" then
        self.ws.send(textutils.serializeJSON({
            event = "pusher:pong",
            data = {}
        }))
    elseif message.event == "client-switch_screen" then
        self:switch_screen(message.data)
    elseif message.event == "client-user_input" then
        self:input_event(message.data)
    elseif message.event == "client-redstone_event" then
        self:redstone_event(message.data)
    elseif message.event == "client-computer_connected" then
        local value_to_send = textutils.serializeJSON({
            event = "client-computer_connected",
            data = {
                computer_id = os.getComputerID()
            },
            channel = self.channel
        })

        self.ws.send(value_to_send)

        api.post("double_computer_connected", {
            computer_id = os.getComputerID()
        })
        
        error("Un autre ordinateur est connecté avec le même identifiant")

        
    else 
        print("Message inconnu : " .. message.event)
    end
end

function module:redstone_event(event_data)
    local event_type = event_data.type
    if event_type == "redstone_changed" then
        local side = event_data.side
        local value_string = event_data.value

        local value = tonumber(value_string)
        

        redstone.setAnalogOutput(side, value)

        local value_to_send = textutils.serializeJSON({
            event = "client-redstone_update",
            data = {
                side = side,
                value = value,
                computer_id = os.getComputerID()
            },
            channel = self.channel
        })

        self.ws.send(value_to_send)
    end
end

function module:input_event(event_data)
    local event_type = event_data.type
    if event_type == "char" then
        os.queueEvent("char", event_data.char)
    elseif event_type == "key" then
        os.queueEvent("key", event_data.key)
    elseif event_type == "key_up" then
        os.queueEvent("key_up", event_data.key)
    elseif event_type == "mouse_click" then
        os.queueEvent("mouse_click", event_data.button, event_data.x, event_data.y)
    elseif event_type == "mouse_up" then
        os.queueEvent("mouse_up", event_data.button, event_data.x, event_data.y)
    elseif event_type == "mouse_scroll" then
        os.queueEvent("mouse_scroll", event_data.direction, event_data.x, event_data.y)
    elseif event_type == "mouse_drag" then
        os.queueEvent("mouse_drag", event_data.button, event_data.x, event_data.y)
    end
end

function module:switch_screen(event_data)
    if event_data.screen == "real" then
        self:switch_to_real_screen()

        term.clear()
        term.setCursorPos(1, 1)
        os.queueEvent("redraw_screen")
    elseif event_data.screen == "virtual" then
        self:switch_to_virtual_screen()

        term.clear()
        term.setCursorPos(1, 1)
        os.queueEvent("redraw_screen")
    elseif event_data.screen == "hybrid" then
        self:switch_to_hybrid_screen()

        term.clear()
        term.setCursorPos(1, 1)
        os.queueEvent("redraw_screen")
    end
end

function module:switch_to_real_screen()
    -- Restaure les méthodes originales du terminal
    term.write = self.original_term.write
    term.blit = self.original_term.blit
    term.clear = self.original_term.clear
    term.clearLine = self.original_term.clearLine
    term.getCursorPos = self.original_term.getCursorPos
    term.setCursorPos = self.original_term.setCursorPos
    term.scroll = self.original_term.scroll

    term.clear()
    term.setCursorPos(1, 1)

    self.mode = "real"
end

function module:switch_to_hybrid_screen()

    self:switch_to_real_screen()

    self.mode = "hybrid"

    local width, height = term.getSize()

    -- Initialisation des variables
    local cursorX, cursorY = 1, 1

    term.write = function(text)
        text = tostring(text)
        expect(1, text, "string")

        -- Obtenir les couleurs actuelles du texte et du fond
        local textColor = {term.getPaletteColor(term.getTextColor())}
        local backgroundColor = {term.getPaletteColor(term.getBackgroundColor())}

        -- Affichage local
        self.original_term.write(text)

        -- Envoi de la mise à jour via WebSocket
        local value_to_send = textutils.serializeJSON({
            event = "client-computer_write",
            data = {
                text = text,
                cursorX = cursorX,
                cursorY = cursorY,
                textColor = textColor,
                backgroundColor = backgroundColor,
                computer_id = os.getComputerID()
            },
            channel = self.channel
        })

        self.ws.send(value_to_send)

        -- Mettre à jour la position du curseur
        cursorX = cursorX + #text
    end

    term.blit = function(text, fg, bg)
        expect(1, text, "string")
        expect(2, fg, "string")
        expect(3, bg, "string")

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

        -- Affichage local
        self.original_term.blit(text, fg, bg)

        -- Envoi de la mise à jour via WebSocket
        local value_to_send = textutils.serializeJSON({
            event = "client-computer_blit",
            data = {
                text = text,
                fg = fgColors,
                bg = bgColors,
                cursorX = cursorX,
                cursorY = cursorY,
                computer_id = os.getComputerID()
            },
            channel = self.channel
        })

        self.ws.send(value_to_send)
    end

    term.clear = function()
        -- Affichage local
        self.original_term.clear()

        -- Envoi de la mise à jour via WebSocket
        local value_to_send = textutils.serializeJSON({
            event = "client-computer_clear",
            data = {
                computer_id = os.getComputerID()
            },
            channel = self.channel
        })

        self.ws.send(value_to_send)
    end

    term.clearLine = function()
        -- Affichage local
        self.original_term.clearLine()

        -- Envoi de la mise à jour via WebSocket
        local value_to_send = textutils.serializeJSON({
            event = "client-computer_clearLine",
            data = {
                cursorY = cursorY,
                computer_id = os.getComputerID()
            },
            channel = self.channel
        })

        self.ws.send(value_to_send)
    end

    term.getCursorPos = function()
        return cursorX, cursorY
    end

    term.setCursorPos = function(x, y)
        expect(1, x, "number")
        expect(2, y, "number")
        cursorX, cursorY = math.floor(x), math.floor(y)

        -- Affichage local
        self.original_term.setCursorPos(x, y)
    end

    term.scroll = function(n)
        expect(1, n, "number")

        -- Affichage local
        self.original_term.scroll(n)

        -- Envoi de la mise à jour via WebSocket
        local value_to_send = textutils.serializeJSON({
            event = "client-computer_scroll",
            data = {
                n = n,
                computer_id = os.getComputerID()
            },
            channel = self.channel
        })

        self.ws.send(value_to_send)
    end
end

function module:switch_to_virtual_screen()
    
    self:switch_to_real_screen()

    self.mode = "virtual"

    local width, height = term.getSize()

    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.clear()
    
    local text_to_center = "Switched to virtual screen"
    local x = math.floor(width / 2 - #text_to_center / 2)
    local y = 6
    term.setCursorPos(x, y)
    print(text_to_center)

    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)

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

    -- Redéfinition des méthodes du terminal pour le mode "virtual screen"
    term.write = function(text)
        text = tostring(text)
        expect(1, text, "string")

        local textColor = {term.getPaletteColor(term.getTextColor())}
        local backgroundColor = {term.getPaletteColor(term.getBackgroundColor())}

        -- Envoi de la mise à jour via websocket
        local value_to_send = textutils.serializeJSON({
            event = "client-computer_write",
            data = {
                text = text,
                cursorX = cursorX,
                cursorY = cursorY,
                textColor = textColor,
                backgroundColor = backgroundColor,
                computer_id = os.getComputerID()
            },
            channel = self.channel
        })

        self.ws.send(value_to_send)

        -- Mettre à jour la position du curseur
        cursorX = cursorX + #text
    end

    term.blit = function(text, fg, bg)
        expect(1, text, "string")
        expect(2, fg, "string")
        expect(3, bg, "string")

        local textLen = #text
        if #fg < textLen then fg = fg .. fg:sub(-1):rep(textLen - #fg) end
        if #bg < textLen then bg = bg .. bg:sub(-1):rep(textLen - #bg) end

        local fgColors = {}
        local bgColors = {}

        for i = 1, #text do
            table.insert(fgColors, {term.getPaletteColor(2 ^ (string.byte(fg, i) - 1))})
            table.insert(bgColors, {term.getPaletteColor(2 ^ (string.byte(bg, i) - 1))})
        end

        local value_to_send = textutils.serializeJSON({
            event = "client-computer_blit",
            data = {
                text = text,
                fg = fgColors,
                bg = bgColors,
                cursorX = cursorX,
                cursorY = cursorY,
                computer_id = os.getComputerID()
            },
            channel = self.channel
        })

        self.ws.send(value_to_send)
    end

    term.clear = function()
        for y = 1, height do
            screenBuffer[y], foregroundBuffer[y] = (" "):rep(width), string.char(0xF0):rep(width)
        end

        local value_to_send = textutils.serializeJSON({
            event = "client-computer_clear",
            data = {
                computer_id = os.getComputerID()
            },
            channel = self.channel
        })

        self.ws.send(value_to_send)
    end

    term.clearLine = function()
        if cursorY >= 1 and cursorY <= height then
            screenBuffer[cursorY], foregroundBuffer[cursorY] = (" "):rep(width), string.char(0xF0):rep(width)
        end

        local value_to_send = textutils.serializeJSON({
            event = "client-computer_clearLine",
            data = {
                cursorY = cursorY,
                computer_id = os.getComputerID()
            },
            channel = self.channel
        })

        self.ws.send(value_to_send)
    end

    term.getCursorPos = function()
        return cursorX, cursorY
    end

    term.setCursorPos = function(x, y)
        expect(1, x, "number")
        expect(2, y, "number")
        cursorX, cursorY = math.floor(x), math.floor(y)
    end

    term.scroll = function(n)
        expect(1, n, "number")

        if n > 0 then
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

        local value_to_send = textutils.serializeJSON({
            event = "client-computer_scroll",
            data = {
                n = n
            ,
computer_id = os.getComputerID()
            },
            channel = self.channel
        })

        self.ws.send(value_to_send)
    end
end

return module