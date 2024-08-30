local Thread_manager = {}
Thread_manager.__index = Thread_manager

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

function Thread_manager:addTask(task)
    if type(task) ~= "function" then error("Task must be a function", 2) end

    self.current_task_id = self.current_task_id + 1
    local task_id = self.current_task_id
    table.insert(self.toAdd, { coroutine.create(task), task_id})

    return task_id
end

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

function Thread_manager:waitforAll(tasks)
    if type(tasks) ~= "table" then error("Tasks must be a table", 2) end

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
        coroutine.yield()
    end
end

function Thread_manager:waitfor(task)
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

function Thread_manager:loadModule(module_name, version, module)
    if type(module_name) ~= "string" then error("Module name must be a string", 2) end
    if type(version) ~= "number" then error("Version must be a number", 2) end
    if type(module) ~= "table" then error("Module must be a table", 2) end

    local module_function = function()
        module:run(self.session_id)
    end

    table.insert(self.modules_toAdd, { coroutine.create(module_function), module_name, version })
end

--#endregion External Fonctions - Modules

--#region Internal Fonctions

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

--#endregion Internal Fonctions

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
                        error(param, 0)
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
end

return Thread_manager
