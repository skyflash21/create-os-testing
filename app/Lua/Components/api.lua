------------------------------------------------[Explication des fonctions]------------------------------------------------

--------------[Fonctions Internes]--------------
--[check_api_status] Permet de vérifier le status de l'api
--[show_code_loading_error] Permet d'afficher une erreur

--------------[Request Standard]--------------
--[post] Permet de faire une requête POST

--------------[Requête compliqué]--------------
--[get_raw_code] Permet de récupérer le code d'un fichier
--[get_code] Permet de récupérer le code d'un fichier et de le charger
--[get_code_version] Permet de récupérer la version d'un fichier

------------------------------------------------[Fonctions Internes]------------------------------------------------

--[[
    Permet de vérifier le status de l'api
    @return void
]]
local function check_api_status(crash_if_not_available)
    local response, fail_string, http_failing_response = http.get(_G.url .. "/api/api_test")
    if not response then
        if not crash_if_not_available then return false end
        _G.status = "critical_error"
        _G.error_detail = { tpye = "api not available",message = fail_string, code = http_failing_response.getResponseCode(), path = path, error_message = "Erreur lors de la requête GET" }
        sleep(0)
        return false
    else
        return true
    end
end

------------------------------------------------[Request Standard]------------------------------------------------

--[[
    Permet de faire une requête POST
    @param path: string
    @param body: table
    @param header: table
    @return string
]]
local function post(path,additional_body,additional_header)
    additional_header = additional_header or {}
    local header = { Authorization = "Bearer " .. settings.get("token"), ["Content-Type"] = "application/json", ["Accept"] = "application/json", ["Host"] = _G.host }

    -- On ajoute les headers passés en paramètre
    for key, value in pairs(additional_header) do
        header[key] = value
    end

    local body = { computer_id = os.getComputerID() }

    -- On ajoute le body passé en paramètre
    for key, value in pairs(additional_body) do
        body[key] = value
    end

    local response, fail_string, http_failing_response = http.post(_G.url.. "/api/"..path, textutils.serializeJSON(body), header)

    if not response then
        error("Erreur lors de la requête POST: " .. fail_string)
    end

    local data = response.readAll()
    response.close()

    return data
end


------------------------------------------------[Fonctions Local]------------------------------------------------

--[[
    Permet de récupérer le code d'un fichier
    @param path: string
    @return string
]]
local function retrieve_file_from_server(path)
    -- Vérification de la variable path
    if path == nil and type(path) ~= "string" then
        error("path must be a string, current type is " .. type(path))
    end

    -- Récupération des données
    local data, fail_string, http_failing_response = api.post("retrieveFile",{ path = path })

    if data == nil then
        error("Erreur lors de la récupération du code: " .. fail_string)
        return nil
    end

    -- On convertit le json en table
    data = textutils.unserializeJSON(data)

    -- Vérification de la réponse
    if data == nil or data == "" then
        error("La réponse recu est nil ou vide.")
        return nil
    end

    return data.content, data.version
end

------------------------------------------------[Requête compliqué]------------------------------------------------


--[[
    Permet de récupérer le code d'un fichier
    @param path: string
    @param get_raw: boolean
    @param crash_if_error: boolean
    @return string
]]
local function get_code(path, get_raw, crash_if_error)

    if not get_raw then
        get_raw = false
    end

    -- Récupération du code
    local code, version = retrieve_file_from_server(path)

    -- Vérification du code
    if code == nil or version == nil then
        error("Erreur lors de la récupération du code")
    end

    -- Retourne le code si get_raw est true
    if get_raw then
        return code, version
    end

    -- Chargement du code
    local filename = string.match(path, "[^/]+$")
    local code_loaded, err = load(code, filename, "t", _ENV)

    -- Vérification du code chargé
    if code_loaded == nil then
        error(err)
    end

    return code_loaded(), version
end

--[[
    Permet de récupérer la version d'un fichier
    @param path: string
    @param crash_if_error: boolean
    @return int
]]
local function get_code_version(path)
    local data = api.post("retrieveLastVersion", {path = path})

    data = textutils.unserializeJSON(data)

    if data == nil then
        error("Erreur lors de la récupération de la version du code: La réponse recu est nil ou vide.")
    end

    return data.version
end

--[[
    Permet de demander au serveur une commande
    @param commandName: string
    @return function
]]
local function get_command(commandName)
end

------------------------------------------------[Exportation]------------------------------------------------

return {
    get = get,
    post = post,
    get_code = get_code,
    get_code_version = get_code_version
}