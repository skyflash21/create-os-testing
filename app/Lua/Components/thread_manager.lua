-----------------------------------[Thread_manager Object]-----------------------------------

local Thread_manager = {}
Thread_manager.__index = Thread_manager

function Thread_manager.new()
    local self = setmetatable({}, Thread_manager)

    self.modules = {}    -- Liste des modules chargés
    self.modules_toAdd = {} -- Liste unique pour les modules à ajouter

    self.coroutines = {} -- Liste des coroutines en cours
    self.toAdd = {}      -- Liste unique pour les tâches à ajouter
    
    self.current_task_running = 0
    self.parallel_coroutines_limit = 250
    self.current_task_id = 0
    self.session_id = 0
    self.running = false

    for i = 1, self.parallel_coroutines_limit do
        self.coroutines[i] = {}
    end

    return self
end

-----------------------------------------[External Fonctions]-----------------------------------------

--#region External Fonctions - Task

--[[
    Add a task to the thread manager
    @param task: function
]]
function Thread_manager:addTask(task)
    if self == nil then
        error("La fonction doit être appelée avec le format : parallel:addTask(task)", 2)
    end
    if type(task) ~= "function" then error("Task must be a function", 2) end

    self.current_task_id = self.current_task_id + 1
    local task_id = self.current_task_id
    table.insert(self.toAdd, { coroutine.create(task), task_id})

    return task_id
end

--[[
    Stop or cancel a task
    @param task_id: number
]]
function Thread_manager:stopTask(task_id)
    if self == nil then
        error("La fonction doit être appelée avec le format : parallel:stopTask(task_id)", 2)
    end
    if type(task_id) ~= "number" then error("Task id must be a number", 2) end

    -- Check if the task is in the toAdd list
    for i = 1, #self.toAdd do
        if self.toAdd[i][2] == task_id then
            table.remove(self.toAdd, i)
            return
        end
    end

    -- Check if the task is in the coroutines list
    for i = 1, self.parallel_coroutines_limit do
        if self.coroutines[i][2] == task_id then
            self.coroutines[i] = {}
            return
        end
    end
end

--[[
    Wait for a task to finish
    @param task: function
]]
function Thread_manager:waitforAll(tasks)
    if self == nil then
        error("La fonction doit être appelée avec le format : parallel:waitforAll(tasks)", 2)
    end
    if type(tasks) ~= "table" then error("Tasks must be a table", 2) end

    local remaining_tasks = 0
    for i = 1, #tasks do
        if type(tasks[i]) ~= "function" then error("Task must be a function", 2) end
        self.current_task_id = self.current_task_id + 1
        local task_id = self.current_task_id
        local temp_func = function()
            tasks[i]()
            remaining_tasks = remaining_tasks - 1
            os.queueEvent("t_done")
        end
        remaining_tasks = remaining_tasks + 1
        table.insert(self.toAdd, { coroutine.create(temp_func), task_id})
    end


    while remaining_tasks > 0 do
        coroutine.yield()
    end
end

--[[
    Wait for a task to finish
    @param task: function
]]
function Thread_manager:waitfor(task)
    if self == nil then
        error("La fonction doit être appelée avec le format : parallel:waitfor(task)", 2)
    end
    if type(task) ~= "function" then error("Task must be a function", 2) end

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
    Load a module
    @param module: string
    @param version: integer
    @param module : module (object)
]]
function Thread_manager:loadModule(module_name, version, module)
    if self == nil then
        error("La fonction doit être appelée avec le format : parallel:loadModule(module_name, version, module)", 2)
    end
    if type(module_name) ~= "string" then error("Module must be a string", 2) end
    if type(version) ~= "number" then error("Version must be a number", 2) end
    if type(module) ~= "table" then error("Module must be a table", 2) end

    local module_function = function()
        module:run(self.session_id)
    end
    
    local module_coroutine = coroutine.create(module_function)
    table.insert(self.modules_toAdd, {module_coroutine, module_name, version, 1})
end

--#endregion External Fonctions - Modules

-----------------------------------------[Internal Fonctions]-----------------------------------------

function Thread_manager:checkToAdd()
    while #self.modules_toAdd ~= 0 and self.current_task_running < self.parallel_coroutines_limit do
        local next_module = table.remove(self.modules_toAdd, 1)
        table.insert(self.modules, next_module)
        self.current_task_running = self.current_task_running + 1
    end

    while #self.toAdd > 0 and self.current_task_running < self.parallel_coroutines_limit do
        for i = 1, self.parallel_coroutines_limit do
            if self.coroutines[i] == nil then
                error("self.coroutines["..i.."] is nil")
            end
            if #self.coroutines[i] == 0 then
                local next_task = table.remove(self.toAdd, 1)
                self.coroutines[i] = next_task
                break
            end
        end
        self.current_task_running = self.current_task_running + 1
    end
end

--[[
    Vérifie si une erreur critique est survenue.
    Les erreurs critique utilise le status "critical_error".
    Si une erreur critique est survenue, le programme doit s'arrêter.

    La variable _ENV.error contient le message d'erreur.
    
    @return void
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

------------------------------------------------[Main]------------------------------------------------

function Thread_manager:run()
    if self == nil then
        error("La fonction doit être appelée avec le format : parallel:run()", 2)
    end
    self.running = true
    local tFilters = {}
    local eventData = { n = 0 }
    print("Thread_manager:run")

    while true do
        while self.running do
            self:checkForErrors()
            self:checkToAdd()

            local living = self.current_task_running

            -- Pour chaque coroutine en cours
            for i = #self.coroutines, 1, -1 do
                if #self.coroutines[i] ~= 0 then
                    local r = self.coroutines[i][1]

                    if r and (tFilters[r] == nil or tFilters[r] == eventData[1] or eventData[1] == "terminate") then
                        local ok, param = coroutine.resume(r, table.unpack(eventData, 1, eventData.n))
                        if not ok then
                            error(param, 0)
                        else
                            tFilters[r] = param
                        end
                        if coroutine.status(r) == "dead" then
                            self.coroutines[i] = {}
                            living = living - 1
                        end
                    end
                end
            end

            -- Pour chaque coroutine en cours
            for i = #self.modules, 1, -1 do
                local current_module = self.modules[i]
                local r = current_module[1]
                local status = current_module[4]

                if r and (tFilters[r] == nil or tFilters[r] == eventData[1] or eventData[1] == "terminate") and status == 1 then
                    local ok, param = coroutine.resume(r, table.unpack(eventData, 1, eventData.n))
                    if not ok then
                        error(param, 0)
                    else
                        tFilters[r] = param
                    end
                    if coroutine.status(r) == "dead" then
                        table.remove(self.modules, i)
                        living = living - 1
                    end
                end
            end

            self.current_task_running = living

            eventData = table.pack(os.pullEventRaw())
        end
        
        if self.running == false then
            os.sleep(1)
        end
    end
end

return Thread_manager
