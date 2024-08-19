-- Cette classe permet de charger la configuration initale et de preparer l'ordinateur

os.pullEvent = os.pullEventRaw
shell.run("set shell.allow_disk_startup false")

local function check_for_update()
    print("Verification de la mise a jour ")

    local version = settings.get("version") or 0

    local header = { Authorization = "Bearer " .. settings.get("token"), ["Content-Type"] = "application/json", ["Accept"] = "application/json", ["Host"] = "create-os-testing.test" }
    local body = { path = "startup.lua"}
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
        local body = { path = "startup.lua", version = json.version, get_raw = true }
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
        print("Pas de mise a jour disponible.")
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
    local header = { Authorization = "Bearer " .. settings.get("token"), ["Content-Type"] = "application/json", ["Accept"] = "application/json", ["Host"] = "create-os-testing.test" }
    local body = { id = os.getComputerID() }
    local response, fail_string, http_failing_response = http.post("http://create-os-testing.test/api/verify_computer_availability", textutils.serializeJSON(body), header)
    
    -- if code is 200, then computer is available
    if response then
        return true
    else
        return false
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
    term.clear()
    term.setCursorPos(1, 1)
    print("Initialisation de l'ordinateur")

    local header = { Authorization = "Bearer " .. settings.get("token"), ["Content-Type"] = "application/json", ["Accept"] = "application/json", ["Host"] = "create-os-testing.test" }
    local body = { path = "/Main" }
    -- On va recuperer la liste des fichiers a telecharger
    local response, fail_string, http_failing_response = http.post("http://create-os-testing.test/api/retrieve_files_list/", textutils.serializeJSON(body), header)
end

local function main()
    if not settings.get("token") then
        reset_computer()
        set_token_by_user()
        
        if verify_computer_availability() then
            register_computer()
        end
    end
    
    check_for_update()
end

-- start with try catch
local status, err = pcall(main)
if not status then
    read()
    os.shutdown()
end
