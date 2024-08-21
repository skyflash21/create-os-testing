-- Cette classe permet de charger la configuration initale et de preparer l'ordinateur


local function check_for_update()
    print("Verification de la mise a jour ...")

    local version = settings.get("version") or 0

    local header = { Authorization = "Bearer " .. settings.get("token"), ["Content-Type"] = "application/json", ["Accept"] = "application/json", ["Host"] = "create-os-testing.test" }
    local body = { path = "Base/startup.lua"}
    local response, fail_string, http_failing_response = http.post("http://create-os-testing.test/api/retrieve_file_version", textutils.serializeJSON(body), header)

    if not response then
        print(fail_string)
        print(http_failing_response.getResponseCode())
        read()
        os.shutdown()
    end

    local data = response.readAll()
    response.close()
    local json = textutils.unserializeJSON(data)

    json.version = tonumber(json.version)

    if json.version > version then
        local body = { path = "Base/startup.lua", version = json.version, get_raw = true }
        local response, fail_string, http_failing_response = http.post("http://create-os-testing.test/api/retrieve_file", textutils.serializeJSON(body), header)

        if not response then
            print(fail_string)
            print(http_failing_response.getResponseCode())
            read()
            os.shutdown()
        end

        local data = response.readAll()
        response.close()
        local file = fs.open("startup", "w")
        file.write(data)
        file.close()
        settings.set("version", json.version)
        settings.save()
        print("Mise a jour effectuee avec succes.")
        sleep(1)
        os.reboot()
    else
        print("Pas de mise a jour disponible")
        print("Version actuelle: " .. version)
        print("Version disponible: " .. json.version)
        read()
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
local function set_token_by_user()
    term.clear()
    term.setCursorPos(1, 1)
    print("Bienvenue sur l'ordinateur")
    print("Veuillez entrer le token de l'ordinateur")
    term.write("Token: ")
    token = read()
    settings.set("token", token)
    settings.save()
    term.clear()
    term.setCursorPos(1, 1)
end

-- On verifie que l'api est accessible

local function is_api_available()
    local response, fail_string, http_failing_response = http.get("http://create-os-testing.test/api/api_test")
    if not response then
        return false,fail_string
    else
        return true
    end
end

local function verify_computer_availability()
    local header = { ["Content-Type"] = "application/json", ["Accept"] = "application/json", ["Host"] = "create-os-testing.test" }
    local body = { id = os.getComputerID() }
    local response, fail_string, http_failing_response = http.post("http://create-os-testing.test/api/verify_computer_availability", textutils.serializeJSON(body), header)
    
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

    local body = { 
        id = os.getComputerID(),
        name = os.getComputerLabel(),
        description = description
    }

    local header = { 
        Authorization = "Bearer " .. settings.get("token"),
        ["Content-Type"] = "application/json", 
        ["Accept"] = "application/json", 
        ["Host"] = "create-os-testing.test" }

    local response, fail_string, http_failing_response = http.post("http://create-os-testing.test/api/register_computer", textutils.serializeJSON(body), header)

    if response then
        local data = response.readAll()
        response.close()
        if data == "Unauthorized" then
            print("Token invalide")
            return
        end

        local json = textutils.unserializeJSON(data)
        
    else
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
        read()
        os.shutdown()
    end
end

-- Cette fonction permet de telecharger les fichiers de l'ordinateur
local function initialize_computer()
    local header = { Authorization = "Bearer " .. settings.get("token"), ["Content-Type"] = "application/json", ["Accept"] = "application/json", ["Host"] = "create-os-testing.test" }
    -- Chargement des différents modules
end

local function main()
    if verify_computer_availability() then
        print("L'ordinateur n'est pas enregistre")
        sleep(1)
        if not settings.get("token") then
            set_token_by_user()
        end
        if not is_api_available() then
            print("L'api n'est pas disponible.")
            read()
            os.shutdown()
        end
        register_computer()
    else
        print("L'ordinateur est deja enregistre")
    end
    
    check_for_update()

    local header = { Authorization = "Bearer " .. settings.get("token"), ["Content-Type"] = "application/json", ["Accept"] = "application/json", ["Host"] = "create-os-testing.test" }
    
    -- Ici on va charger les différents élements de l'ordinateur
    -- On va commencer par le gestionnaire de thread
    local body = { path = "Components\\thread_manager.lua"}
    local response, fail_string, http_failing_response = http.post("http://create-os-testing.test/api/retrieve_file", textutils.serializeJSON(body), header)

    if not response then
        print(fail_string)
        print(http_failing_response.getResponseCode())
        read()
        os.shutdown()
    end
    
    local data = textutils.unserializeJSON(response.readAll())
    response.close()
    local thread_manager = load(data.file.content)().new()
    thread_manager.version = data.file.version
    thread_manager:addTask(initialize_computer,1)
    thread_manager:run()

    _G.parallel = thread_manager
end

main()
