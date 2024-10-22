local module = {}
module.__index = module

function module.new()
    local self = setmetatable({}, module)

    -- Initialisation des variables
    self.name = "user_interface"
    self.session_id = 0
    self.version = nil
    self.path = nil -- chemin du module

    -- Initialisation des variables inhérentes au module
    self.domain = "user"
    self.command_history = {}
    self.history_index = 0
    self.current_input = ""
    self.max_history = 100

    -- Buffer d'affichage
    self.display_buffer = {}  -- Contient tout le contenu affiché
    self.visible_start_index = 1  -- L'index de la première ligne visible à l'écran
    self.screen_width, self.screen_height = term.getSize()  -- Taille de l'écran
    self.scroll_offset = 0  -- Décalage de défilement

    return self
end

function module:init()
    -- Initialisation du module
end

function module:run(current_session_id)
    if current_session_id == nil or type(current_session_id) ~= "number" then
        error("current_session_id must be a number, current type is " .. type(current_session_id))
    end

    self.session_id = current_session_id

    -- Attente de l'événement "computer_ready" ou "stop_module"
    local event, param = os.pullEvent()
    while event ~= "computer_ready" and (event ~= "stop_module" or param ~= self.session_id) do
        event, param = os.pullEvent()
    end

    if event == "stop_module" and param == self.session_id then
        return
    end

    -- Affiche un message de bienvenue
    self:print_to_buffer("Bienvenue dans la console interactive!", colors.yellow)
    self:print_to_buffer("Tapez 'help' pour afficher les commandes.", colors.yellow)

    while true do
        self:display_prompt()
        local input, interrupted = self:read_input()

        if interrupted then
            return
        end

        -- Ajoute la commande dans le buffer pour l'afficher
        if input ~= "" then
            table.insert(self.command_history, input)
            if #self.command_history > self.max_history then
                table.remove(self.command_history, 1)
            end
            self.history_index = #self.command_history + 1

            -- Affiche la commande avant de l'exécuter
            self:print_to_buffer(self.domain .. "> " .. input, colors.green)
        end

        -- Exécute la commande
        self:execute_command(input)
    end
end

function module:display_prompt()
    local _, screen_height = term.getSize()
    term.setCursorPos(1, screen_height)  -- Positionner le curseur en bas de l'écran
    term.setTextColor(colors.green)
    term.setBackgroundColor(colors.gray)
    term.clearLine()
    term.write(self.domain .. "> ")
    term.setTextColor(colors.white)
    term.write(self.current_input)
    term.setBackgroundColor(colors.black)
end

-- Lit l'entrée de l'utilisateur et gère les événements de la molette
function module:read_input()
    local input = ""
    local key

    while true do
        local event, param = os.pullEvent()

        if event == "char" then
            input = input .. param
            self.current_input = input
            self:display_prompt()

        elseif event == "key" then
            key = param
            if key == keys.enter then
                print("")
                self.current_input = ""
                return input, false
            elseif key == keys.backspace then
                if #input > 0 then
                    input = input:sub(1, -2)
                    self.current_input = input
                    self:display_prompt()
                end
            end
        elseif event == "mouse_scroll" then
            -- Gère le défilement avec la molette
            self:scroll_screen(param)
        end

        if event == "redraw_screen" then
            -- Rafraîchit l'écran si nécessaire
            self:render_screen()
        end

        if event == "stop_module" and param == self.session_id then
            return "", true
        end
    end
end

-- Fonction de défilement de l'écran
function module:scroll_screen(direction)
    -- Direction est 1 pour descendre et -1 pour monter
    self.scroll_offset = self.scroll_offset - direction
    if self.scroll_offset < 0 then
        self.scroll_offset = 0  -- Empêche le défilement en dehors du contenu
    elseif self.scroll_offset > #self.display_buffer - (self.screen_height - 2) then
        self.scroll_offset = #self.display_buffer - (self.screen_height - 2)
    end
    self:render_screen()
end

-- Rendu de l'écran (affiche seulement la portion visible du buffer)
function module:render_screen()
    term.clear()
    term.setCursorPos(1, 1)

    for i = 1, self.screen_height - 1 do  -- Moins 1 pour laisser de la place pour le prompt
        local line_index = i + self.scroll_offset
        if self.display_buffer[line_index] then
            local line = self.display_buffer[line_index]
            term.setTextColor(line.color)
            term.write(line.text)
            local cursor_x, cursor_y = term.getCursorPos()
            term.setCursorPos(1, cursor_y + 1)
            
            -- Si on sort de l'écran, on scroll de 1 ligne
            if cursor_y > self.screen_height - 1 then
                term.scroll(1)
            end
        end
    end

    -- Réaffiche le prompt en bas
    self:display_prompt()

    -- On envoie l'écran au serveur via un calcul du différenciel ici --[[ IDEE DE FONCTION A AJOUTER ]]--
end

-- Ajoute une ligne au buffer d'affichage et rend l'écran
function module:print_to_buffer(text, color, centered)
    centered = centered or false

    -- Si le text est plus grand que la largeur de l'écran, on le tronque et on le print en plusieurs lignes
    if string.len(text) > self.screen_width then
        local text_length = string.len(text)
        local start_index = 1
        local end_index = self.screen_width
        while start_index < text_length do
            local line = text:sub(start_index, end_index)
            self:print_to_buffer(line, color, centered)
            start_index = end_index + 1
            end_index = end_index + self.screen_width
        end
        return
    end

    if centered then
        local width = self.screen_width
        local text_length = string.len(text)
        local padding = math.floor((width - text_length) / 2)
        text = string.rep(" ", padding) .. text
    end

    color = color or colors.white
    table.insert(self.display_buffer, {text = text, color = color})

    -- Si le buffer dépasse la taille de l'écran, on ajuste l'offset
    if #self.display_buffer > self.screen_height - 2 then  -- Moins 2 pour laisser de la place pour le prompt et une ligne supplémentaire
        self.scroll_offset = #self.display_buffer - (self.screen_height - 2)
    end

    self:render_screen()
end

function module:print_line_to_buffer(color)
    local width = self.screen_width

    local line = string.rep("-", width)
    color = color or colors.white
    self:print_to_buffer(line, color)
end

-- Exécute une commande saisie par l'utilisateur
function module:execute_command(...)
    local args = {...}
    local command = args[1]
    table.remove(args, 1)

    --remove all space and lower
    command = command:lower():gsub("%s+", "")

    local code, version = api.get_code("\\Commands\\" .. self.domain .. "\\" .. command .. ".lua", false)

    if code == nil then
        self:print_to_buffer("Commande invalide " .. command, colors.red)
        return
    end

    _G.parallel:waitfor(function() 
        local successed, returnedData = xpcall(function()
            code.execute(self,args)
        end, function( error )
            self:print_to_buffer("Erreur lors de l'execution de " .. command, colors.red)
            self:print_to_buffer(error, colors.red)
        end)
    end)

    code = nil
end

-- Efface l'affichage de la console
function module:clear_console()
    term.clear()
    term.setCursorPos(1, 1)
    self.display_buffer = {}  -- Vide le buffer
    self.scroll_offset = 0
end

-- Quitte la console
function module:exit_console()
    self:print_to_buffer("Fermeture de la console...", colors.yellow)
    os.shutdown()
end

return module
