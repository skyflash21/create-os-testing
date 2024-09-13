local module = {}
module.__index = module

--[[ 
    Constructeur de la classe, retourne une instance
    return self 
]]--
function module.new()
    local self = setmetatable({}, module)

    -- Initialisation des variables obligatoires
    self.name = "user_interface"
    self.session_id = 0
    self.version = "1.0.0"

    -- Initialisation des variables inhérentes au module
    self.username = "user"       -- Nom d'utilisateur affiché dans le prompt
    self.command_history = {}    -- Historique des commandes
    self.history_index = 0       -- Index pour naviguer dans l'historique
    self.current_input = ""      -- Commande en cours de saisie
    self.max_history = 100       -- Limite d'historique

    return self
end

--[[ 
    Méthode qui est exécutée lors de l'initialisation du module
    @return void 
]]--
function module:init()
end

--[[ 
    Méthode qui est exécutée lors de l'appel de la commande run
    @param int current_session_id string id de la session courante 
    @return void 
]]--
function module:run(current_session_id)
    if current_session_id == nil or type(current_session_id) ~= "number" then
        error("current_session_id must be a number, current type is " .. type(current_session_id))
    end

    self.session_id = current_session_id

    -- Affiche un message de bienvenue
    self:print_colored("Bienvenue dans la console interactive!", colors.yellow)
    self:print_colored("Tapez 'help' pour afficher les commandes disponibles.", colors.yellow)

    while true do
        self:display_prompt()
        local input, interrupted = self:read_input()

        if interrupted then
            return
        end

        -- Ajoute la commande à l'historique et réinitialise l'index de l'historique
        if input ~= "" then
            table.insert(self.command_history, input)
            if #self.command_history > self.max_history then
                table.remove(self.command_history, 1)  -- Supprime les vieilles commandes si on dépasse la limite
            end
            self.history_index = #self.command_history + 1
        end

        -- Exécute la commande
        self:execute_command(input)
    end
end

--[[ 
    Affiche le prompt avec le username
]]--
function module:display_prompt()
    term.setTextColor(colors.green)
    term.write(self.username .. "> ")
    term.setTextColor(colors.white)
end

--[[ 
    Lit l'entrée de l'utilisateur caractère par caractère
    @return string input La commande complète
]]--
function module:read_input()
    local input = ""
    local key

    while true do
        local event, param = os.pullEvent()

        if event == "char" then
            -- Ajouter un caractère à la commande
            input = input .. param
            term.write(param)  -- Affiche le caractère

        elseif event == "key" then
            key = param
            if key == keys.enter then
                -- Retourne la commande complète quand "Enter" est pressé
                print("")  -- Nouvelle ligne après le prompt
                return input, false

            elseif key == keys.backspace then
                -- Supprime le dernier caractère
                if #input > 0 then
                    input = input:sub(1, -2)
                    local cursor_x, cursor_y = term.getCursorPos()
                    term.setCursorPos(cursor_x - 1, cursor_y)
                    term.write(" ")  -- Efface le caractère
                    term.setCursorPos(cursor_x - 1, cursor_y)
                end

            elseif key == keys.up then
                -- Flèche "haut" pour naviguer dans l'historique
                if self.history_index > 1 then
                    self.history_index = self.history_index - 1
                    input = self.command_history[self.history_index] or ""
                    self:clear_line()
                    term.setTextColor(colors.green)
                    term.write(self.username .. "> " )
                    term.setTextColor(colors.white)
                    term.write(input)
                end

            elseif key == keys.down then
                -- Flèche "bas" pour naviguer vers les commandes plus récentes
                if self.history_index < #self.command_history then
                    self.history_index = self.history_index + 1
                    input = self.command_history[self.history_index] or ""
                    self:clear_line()
                    term.setTextColor(colors.green)
                    term.write(self.username .. "> " )
                    term.setTextColor(colors.white)
                    term.write(input)
                end
            elseif key == keys.right or key == keys.left then
                -- On retire l'input et on remet l'historique a un index ou il n'y a pas de commandes
                self.history_index = #self.command_history + 1
                input = ""
                self:clear_line()
                term.setTextColor(colors.green)
                term.write(self.username .. "> " )
                term.setTextColor(colors.white)
                term.write(input)
            end
        end

        -- Gère l'événement de stop si nécessaire
        if event == "stop_module" and param == self.session_id then
            return "", true
        end
    end
end

--[[ 
    Efface la ligne actuelle (utile pour rafraîchir l'entrée utilisateur)
]]--
function module:clear_line()
    local _, y = term.getCursorPos()
    term.setCursorPos(1, y)
    term.clearLine()
end

--[[ 
    Exécute une commande saisie par l'utilisateur
    @param string command La commande saisie 
    @return void 
]]--
function module:execute_command(command)
    if command == "help" then
        self:print_help()
    elseif command == "clear" then
        self:clear_console()
    elseif command == "exit" then
        self:exit_console()
    else
        self:print_colored("Commande inconnue: " .. command, colors.red)
    end
end

--[[ 
    Affiche les commandes disponibles 
]]--
function module:print_help()
    self:print_colored("Commandes disponibles :", colors.white)
    self:print_colored("help  - Affiche cette aide.", colors.white)
    self:print_colored("clear - Efface la console.", colors.white)
    self:print_colored("exit  - Quitte la console.", colors.white)
end

--[[ 
    Efface l'affichage de la console 
]]--
function module:clear_console()
    term.clear()
    term.setCursorPos(1, 1)
end

--[[ 
    Quitte la console 
]]--
function module:exit_console()
    self:print_colored("Fermeture de la console...", colors.yellow)
    os.shutdown()  -- Dans ComputerCraft, ceci simule la sortie
end

--[[ 
    Méthode pour imprimer du texte coloré
    @param string text Le texte à imprimer
    @param number color La couleur (en utilisant les constantes de `colors`)
]]--
function module:print_colored(text, color)
    term.setTextColor(color)
    print(text)
    term.setTextColor(colors.white)
end

--[[ 
    Méthode qui est exécutée lors de l'appel de la commande run
    @param string type type de la commande
    @param table arguments arguments de la commande
    @return void 
]]--
function module:command_run(type, arguments)
    print("Commande de type '" .. type .. "' exécutée avec les arguments : " .. table.concat(arguments, ", "))
end

return module
