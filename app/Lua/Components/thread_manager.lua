local Thread_manager = {}
Thread_manager.__index = Thread_manager

--[[
Fonction : Permet de crée un nouvel objet Thread_manager
Paramètre : Aucun
Retour : Un objet Thread_manager
]]--
function Thread_manager.new()
    local self = setmetatable({}, Thread_manager)

    self.modules = {}          -- Liste des modules chargés
    self.modules_toAdd = {}    -- Liste unique pour les modules à ajouter
    self.coroutines = {}       -- Liste des coroutines en cours
    self.toAdd = {}            -- Liste unique pour les tâches à ajouter
    self.current_task_running = 0
    self.parallel_coroutines_limit = 250
    self.current_task_id = 0
    self.session_id = 0
    self.running = false

    return self
end

--#region External Fonctions - Task

--[[
Fonction : Permet d'ajouter une tâche à la liste des tâches à exécuter 
Paramètre : task (function) - La tâche à exécuter
Retour : task_id (number) - L'identifiant de la tâche
]]--
function Thread_manager:addTask(task)
    if type(task) ~= "function" then error("Task must be a function", 2) end

    self.current_task_id = self.current_task_id + 1
    local task_id = self.current_task_id
    table.insert(self.toAdd, { coroutine.create(task), task_id})

    return task_id
end

--[[
Fonction : Permet de stopper une tâche en cours
Paramètre : task_id (number) - L'identifiant de la tâche
Retour : Aucun
]]--
function Thread_manager:stopTask(task_id)
    if type(task_id) ~= "number" then error("Task id must be a number", 2) end

    -- Remove from toAdd list
    for i = 1, #self.toAdd do
        if self.toAdd[i][2] == task_id then
            table.remove(self.toAdd, i)
            return
        end
    end

    -- Remove from coroutines list
    for i = 1, #self.coroutines do
        if self.coroutines[i] and self.coroutines[i][2] == task_id then
            self.coroutines[i] = nil
            return
        end
    end
end

--[[
Fonction : Lance des tâches en parallèle et attend qu'elles soient toutes terminées avant de retourner
Paramètre : tasks (table) - Liste des tâches à exécuter
Retour : Aucun
]]--
function Thread_manager:waitForAll(tasks)
    if type(tasks) ~= "table" then error("Tasks must be a table, got " .. type(tasks), 2) end

    local remaining_tasks = #tasks
    for i = 1, remaining_tasks do
        if type(tasks[i]) ~= "function" then error("Task must be a function", 2) end
        self.current_task_id = self.current_task_id + 1
        local task_id = self.current_task_id
        local temp_func = function()
            tasks[i]()
            remaining_tasks = remaining_tasks - 1
            os.queueEvent("t_done")
        end
        table.insert(self.toAdd, { coroutine.create(temp_func), task_id})
    end

    while remaining_tasks > 0 do
    sleep(0)
    end
end

--[[
Fonction : Lance une tâche et attend qu'elle soit terminée avant de retourner
Paramètre : task (function) - La tâche à exécuter
Retour : Aucun
]]--
function Thread_manager:waitfor(task)
    if type(task) ~= "function" then error("Task must be a function, got " .. type(task), 2) end

    self.current_task_id = self.current_task_id + 1
    local task_id = self.current_task_id
    local done = false

    local temp_func = function()
        task()
        done = true
        os.queueEvent("t_done")
    end
    table.insert(self.toAdd, { coroutine.create(temp_func), task_id})

    os.queueEvent("waitfor", task_id)
    while not done do
        coroutine.yield()
    end
end

--#endregion External Fonctions - Task

--#region External Fonctions - Modules

--[[
Fonction : Permet de charger un module
Paramètre : module_name (string) - Le nom du module
Paramètre : version (number) - La version du module
Paramètre : module (table) - Le module à charger
Retour : Aucun
]]--
function Thread_manager:loadModule(module_name, version, module, path)
    if type(module_name) ~= "string" then error("Module name must be a string", 2) end
    if type(version) ~= "number" then error("Version must be a number", 2) end
    if type(module) ~= "table" then error("Module must be a table", 2) end
    if type(path) ~= "string" then error("Path must be a string", 2) end

    local module_function = function()
        module:run(self.session_id)
    end

    module:init(self.session_id)

    table.insert(self.modules_toAdd, { coroutine.create(module_function), module_name, version, path , module})
end

--[[
Fonction : Permet de recuperer un module
Paramètre : module_name (string) - Le nom du module
Retour : Module (table) - Le module
]]--
function Thread_manager:getModule(module_name)
    if type(module_name) ~= "string" then error("Module name must be a string", 2) end

    for i = 1, #self.modules do
        if self.modules[i][2] == module_name then
            return self.modules[i][5]
        end
    end

    return nil
end

--#endregion External Fonctions - Modules

--#region Internal Fonctions

--[[
Fonction : Permet de vérifier si des tâches ou des modules doivent être ajoutés
Paramètre : Aucun
Retour : Aucun
]]--
function Thread_manager:checkToAdd()
    -- Add new modules
    while #self.modules_toAdd > 0 and self.current_task_running < self.parallel_coroutines_limit do
        local next_module = table.remove(self.modules_toAdd, 1)
        table.insert(self.modules, next_module)
        self.current_task_running = self.current_task_running + 1
    end

    -- Add new tasks
    while #self.toAdd > 0 and self.current_task_running < self.parallel_coroutines_limit do
        local next_task = table.remove(self.toAdd, 1)
        table.insert(self.coroutines, next_task)
        self.current_task_running = self.current_task_running + 1
    end
end

--[[
Fonction : Permet de vérifier si une erreur critique est survenue
Paramètre : Aucun
Retour : Aucun
]]--
function Thread_manager:checkForErrors()
    if _G.status == "critical_error" then
        term.clear()
        term.setCursorPos(1, 1)
        for key, value in pairs(_G.error_detail) do
            print(key, value)
        end
        read()
        os.shutdown()
    end
end

--[[
Fonction : Permet d'afficher un message d'erreur à l'utilisateur
Paramètre : text (string) - Le message d'erreur
Paramètre : y (number) - La position en y du message
Retour : Aucun
]]--
function Thread_manager:print_center(text, y)
    local w, h = term.getSize()
    term.setCursorPos(w / 2 - #text / 2, y)
    term.clearLine()
    term.write(text)
end

--[[
Fonction : Permet de gérer une erreur survenue dans une coroutine
Paramètre : task_id (number) - L'identifiant de la tâche
Paramètre : error_message (string) - Le message d'erreur
]]--
function Thread_manager:handleCoroutineError(task_id, error_message)
    term.setBackgroundColor(colors.red)
    term.setTextColor(colors.white)
    term.clear()
    
    self:print_center("Error in task " .. task_id, 5)
    term.setCursorPos(1, 7)
    print("Error message: " .. error_message, 7)

    self:Error_User_Input()
end

--[[
Fonction : Permet de gérer une erreur survenue dans un module
Paramètre : module_name (string) - Le nom du module
Paramètre : version (number) - La version du module
Paramètre : error_message (string) - Le message d'erreur
]]--
function Thread_manager:handleModuleError(module_name, version, error_message)
    term.setBackgroundColor(colors.red)
    term.setTextColor(colors.white)
    term.clear()
    
    self:print_center("Error in module " .. module_name .. " v" .. version, 5)
    term.setCursorPos(1, 7)
    print("Error message: " .. error_message, 7)

    self:Error_User_Input()
end

--[[
Fonction : Permet d'afficher un message d'erreur à l'utilisateur et de redémarrer l'ordinateur
Paramètre : Aucun
Retour : Aucun
]]--
function Thread_manager:Error_User_Input()
    local wait_timer = os.startTimer(1)

    local last_error_timer = settings.get("last_error_timer")
    local current_wait_time = 0
    local wait_time = 5

    if last_error_timer then
        wait_time = math.min(60*10, last_error_timer * 2)
    end

    while true do
        local event, arg1 = os.pullEvent()

        if current_wait_time >= wait_time then
            settings.set("last_error_timer", wait_time)
            settings.save(".settings")
            os.reboot()
        end

        if event == "timer" and arg1 == wait_timer then
            local minutes = math.floor((wait_time - current_wait_time) / 60)
            local seconds = (wait_time - current_wait_time) % 60
            self:print_center("Redemarrage dans " .. minutes .. " minutes et " .. seconds .. " secondes", 17)
            wait_timer = os.startTimer(1)
            current_wait_time = current_wait_time + 1
        elseif event == "key" and arg1 == keys.enter then
            os.shutdown()
        end
    end
end


--#endregion Internal Fonctions

--[[
Fonction : Permet de lancer le Thread_manager
Paramètre : Aucun
Retour : Aucun
]]--
function Thread_manager:run()
    if self.running then return end
    self.running = true
    local tFilters = {}
    local eventData = { n = 0 }
    print("Thread_manager:run")

    while self.running do
        self:checkForErrors()
        self:checkToAdd()

        local living = self.current_task_running

        -- Process coroutines
        for i = #self.coroutines, 1, -1 do
            local task = self.coroutines[i]
            if task then
                local r, task_id = task[1], task[2]
                if r and (tFilters[r] == nil or tFilters[r] == eventData[1] or eventData[1] == "terminate") then
                    local ok, param = coroutine.resume(r, table.unpack(eventData, 1, eventData.n))
                    if not ok then
                        print("Error in coroutine task " .. task_id .. ": " .. param)
                        -- Log or handle the error here instead of crashing
                        self:handleCoroutineError(task_id, param)
                    else
                        tFilters[r] = param
                    end
                    if coroutine.status(r) == "dead" then
                        table.remove(self.coroutines, i)
                        living = living - 1
                    end
                end
            end
        end

        -- Process modules
        for i = #self.modules, 1, -1 do
            local module = self.modules[i]
            local r, module_name, version = module[1], module[2], module[3]
            if r and (tFilters[r] == nil or tFilters[r] == eventData[1] or eventData[1] == "terminate") then
                local ok, param = coroutine.resume(r, table.unpack(eventData, 1, eventData.n))
                if not ok then
                    local file = fs.open("error.log", "a")
                    file.writeLine("Error in module " .. module_name .. " v" .. version .. ": " .. param)
                    file.close()

                    print("Error in module " .. module_name .. " v" .. version .. ": " .. param)
                    self:handleModuleError(module_name, version, param)
                else
                    tFilters[r] = param
                end
                if coroutine.status(r) == "dead" then
                    local file = fs.open("error.log", "a")
                    file.writeLine("Module " .. module_name .. " v" .. version .. " has been stopped")
                    file.close()

                    table.remove(self.modules, i)
                    living = living - 1
                end
            end
        end

        self.current_task_running = living

        eventData = table.pack(os.pullEventRaw())
    end
end


return Thread_manager
