-- Cette classe permet de charger la configuration initale et de preparer l'ordinateur
shell.run("set shell.allow_disk_startup false")
shell.run("set motd.enable false")
os.pullEvent = os.pullEventRaw
_G.url = "http://127.0.0.1:8000"
_G.host = "localhost"

local function load_api()
    local header = { Authorization = "Bearer " .. settings.get("token"), ["Content-Type"] = "application/json",["Accept"] = "application/json", ["Host"] = _G.host }
    local body = { path = "\\Components\\api.lua", computer_id = os.getComputerID() }

    local response, fail_string, http_failing_response = http.post(_G.url .. "/api/retrieveFile",
        textutils.serializeJSON(body), header)

    if not response then
        print(fail_string)
        print(http_failing_response.getResponseCode())
        
        _G.status = "critical_error"
        _G.error_detail = http_failing_response
    end
    
    local data = textutils.unserializeJSON(response.readAll())
    response.close()
    _G.api = load(data.content, "api", "t", _ENV)()
end

local function check_for_update()
    print("Verification de la mise a jour ...")

    local server_version = api.get_code_version("\\Base\\startup.lua")

    local local_version = settings.get("version") or 0

    if server_version > local_version then
        print("Mise a jour disponible")
        print("Version actuelle: " .. local_version)
        print("Version disponible: " .. server_version)
        local new_code, version = api.get_code("\\Base\\startup.lua", true)

        local file = fs.open("startup", "w")
        file.write(new_code)
        file.close()
        settings.set("version", version)
        settings.save()
        print("Mise a jour effectuee")
        print("Redemarrage de l'ordinateur")
        sleep(1)
        os.reboot()

    else
        print("Pas de mise a jour disponible")
        print("Version actuelle: " .. local_version)
        print("Version disponible: " .. server_version)
    end
end

local function reset_computer()
    -- Operation de nettoyage des settings
    settings.clear()
    settings.save()

    local listeFichiers = fs.list("/")
    for i = 1, #listeFichiers do
        -- On verifie que on peux le supprimer
        if fs.isReadOnly(listeFichiers[i]) == false and listeFichiers[i] ~= "startup" then
            fs.delete(listeFichiers[i])
        end
    end
end

-- On va commencer par demander le token a l'utilisateur
local function set_token_by_user(c_token)
    if c_token then
        settings.set("token", c_token)
        settings.save()
        return
    end
    
    term.clear()
    term.setCursorPos(1, 1)
    print("Bienvenue sur l'ordinateur")
    print("Veuillez entrer le token de l'ordinateur")
    term.write("Token: ")
    local token = read()
    settings.set("token", token)
    settings.save()
    term.clear()
    term.setCursorPos(1, 1)
end

-- On verifie que l'api est accessible
local function is_api_available()
    local response, fail_string, http_failing_response = http.get(_G.url .. "/api/api_test")
    if not response then
        return false, fail_string
    else
        return true
    end
end

local function verify_computer_availability()
    local header = { ["Content-Type"] = "application/json", ["Accept"] = "application/json", ["Host"] =
    _G.host }
    local body = { id = os.getComputerID() }
    local response, fail_string, http_failing_response = http.post(_G.url .. "/api/verify_computer_availability",
        textutils.serializeJSON(body), header)

    -- if code is 200, then computer is available if its 409 then computer is not available otherwise error
    if response then
        local data = response.readAll()
        response.close()
        return textutils.unserializeJSON(data).available
    else
        print("Erreur: ")
        print(fail_string)
        print(http_failing_response.getResponseCode())
        read()
        os.shutdown()
    end
end

-- Enregistrement de l'ordinateur
local function register_computer(c_name, c_description)
    
    reset_computer()
    print("L'ordinateur n'est pas enregistre")
    sleep(1)
    if not settings.get("token") then
        set_token_by_user(_ENV.start_args.token)
    end
    if not is_api_available() then
        print("L'api n'est pas disponible.")
        read()
        os.shutdown()
    end

    term.clear()
    term.setCursorPos(1, 1)
    print("Enregistrement de l'ordinateur :")
    print("ID: " .. os.getComputerID())
    term.write("Nom: ")
    local name = c_name or read()
    os.setComputerLabel(name)
    term.setCursorPos(1, 4)
    term.write("Description: ")
    local description = c_description or read()

    local type = nil
    if turtle then
        type = "turtle"
    elseif pocket then
        type = "pocket"
    else
        type = "computer"
    end

    local wireless_modem_side = "none"
    local modems_found = peripheral.find("modem")

    if modems_found then
        for i = 1, #modems_found do
            if modems_found[i].isWireless() then
                wireless_modem_side = peripheral.getName(modems_found[i])
                break
            end
        end
    else
        wireless_modem_side = "none"
    end
    
    local used_disk_space = fs.getCapacity("/")-fs.getFreeSpace("/")

    local body = {
        id = os.getComputerID(),
        name = os.getComputerLabel(),
        description = description,
        type = type,
        wireless_modem_side = wireless_modem_side,
        is_advanced = term.isColor(),
        total_disk_space = fs.getCapacity("/"),
        used_disk_space = used_disk_space
    }

    local header = {
        Authorization = "Bearer " .. settings.get("token"),
        ["Content-Type"] = "application/json",
        ["Accept"] = "application/json",
        ["Host"] = _G.host
    }

    local response, fail_string, http_failing_response = http.post(_G.url .. "/api/register_computer",
        textutils.serializeJSON(body), header)

    if not response then
        print("Erreur: ")
        print(fail_string)
        print(http_failing_response.getResponseCode())
        local data = http_failing_response.readAll()
        local errorData = textutils.unserializeJSON(data)
        if errorData and errorData.error then
            print("Erreur: " .. errorData.error)
        else
            print("Erreur in data: " .. data)
        end
        
        settings.clear()
        settings.save()

        -- save to file
        local file = fs.open("error", "w")
        file.write(data)
        file.close()

        read()
        os.shutdown()
    end
end

-- Cette fonction permet de telecharger les fichiers de l'ordinateur
local function initialize_computer()
    local data, fail_string, http_failing_respons = api.post("retrieveFilesList",{ path = "\\Modules" })
    if not data then
        error("Impossible de recuperer la liste des modules, " .. fail_string)
    end
    local json = textutils.unserializeJSON(data)
    local modules = {}
    for i = 1, #json do
        local file = json[i].path
        
        local last_code = json[i].last_version
        local executed_code, version = api.get_code(file, false)

        if executed_code then
            local current_module = executed_code.new()
            current_module.version = version
            current_module.path = file
            table.insert(modules, current_module)
            term.setTextColor(colors.green)
            term.write("OK ")
            term.setTextColor(colors.white)
            print(file .. " version: " .. version)
        else
            term.setTextColor(colors.red)
            term.write("Fail ")
            term.setTextColor(colors.white)
            print(file .. " version: " .. version)
        end
    end

    print("Fin de la sequence de chargement des modules")
    print("Ajout des modules dans le gestionnaire de thread")
    for i = 1, #modules do
        _G.parallel:loadModule(modules[i].name, modules[i].version, modules[i], modules[i].path)
    end
    print("Fin de l'ajout des modules dans le gestionnaire de thread")
    print("Verification de la sequence d'initialisation")

    local parallel_status = parallel.running
    if parallel_status then term.setTextColor(colors.green)
    else term.setTextColor(colors.red) end
    print("Parallel status: " .. tostring(parallel_status))
    term.setTextColor(colors.white)

    print("Fin de la verification de la sequence d'initialisation")
    
    print("Envoie du signal au gestionnaires de la console.")

    os.queueEvent("computer_ready")

    settings.set("last_error_timer", 5)
end

local function main()
    if verify_computer_availability() then
        register_computer(_ENV.start_args.name, _ENV.start_args.description)
    else
        print("L'ordinateur est deja enregistre")
        if settings.get("token") == nil then
            set_token_by_user()
        end
    end

    load_api()

    check_for_update()

    local code_loaded,version = api.get_code("\\Components\\thread_manager.lua", false)
    local thread_manager = code_loaded.new()
    _G.parallel = thread_manager

    print("Version du bootstrap: " .. settings.get("version"))

    thread_manager.version = version
    thread_manager:addTask(initialize_computer, 1)
    thread_manager:run()

end

main()
