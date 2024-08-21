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
        coroutine.yield()
        return false
    else
        return true
    end
end

--[[
    Permet d'afficher une erreur
    @param fail_string: string
    @param http_failing_response: table
    @param path: string
    @param error_message: string
    @return void
]]
local function show_code_loading_error(fail_string, http_failing_response, path, error_message)
    _G.status = "critical_error"
    _G.error_detail = { tpye = "code loading error", message = fail_string, code = http_failing_response.getResponseCode(), path = path, error_message = error_message }
    coroutine.yield()
end

------------------------------------------------[Request Standard]------------------------------------------------

--[[
    Permet de faire une requête GET
    @param path: string
    @param header: table
    @return string
]]
local function get(path,additional_header)
    additional_header = additional_header or {}
    local header = { Authorization = "Bearer " .. settings.get("token"), ["Content-Type"] = "application/json", ["Accept"] = "application/json", ["Host"] = "create-os-testing.test" }

    -- On ajoute les headers passés en paramètre
    for key, value in pairs(additional_header) do
        header[key] = value
    end

    local response, fail_string, http_failing_response = http.get(_G.url.. "/api/"..path, header)

    print("http://".._G.url.. "/api/"..path)

    if not response then
        check_api_status()
        return nil, fail_string, http_failing_response
    end

    local data = response.readAll()
    response.close()

    return data
end

--[[
    Permet de faire une requête POST
    @param path: string
    @param body: table
    @param header: table
    @return string
]]
local function post(path,body,additional_header)
    additional_header = additional_header or {}
    local header = { Authorization = "Bearer " .. settings.get("token"), ["Content-Type"] = "application/json", ["Accept"] = "application/json", ["Host"] = "create-os-testing.test" }

    -- On ajoute les headers passés en paramètre
    for key, value in pairs(additional_header) do
        header[key] = value
    end

    local response, fail_string, http_failing_response = http.post(_G.url.. "/api/"..path, textutils.serializeJSON(body), header)

    if not response then
        check_api_status()
        return nil, fail_string, http_failing_response
    end

    local data = response.readAll()
    response.close()

    return data
end

------------------------------------------------[Requête compliqué]------------------------------------------------
--[[
    Permet de récupérer le code d'un fichier et de le charger
    @param path: string
    @param crash_if_error: boolean
    @return function
]]
local function get_code(path, crash_if_error)
    -- Vérification de la variable path
    if path == nil and type(path) ~= "string" then
        error("path must be a string, current type is " .. type(path))
    end
    crash_if_error = crash_if_error or true

    -- Récupération des données
    local data = api.post("retrieve_file",{ path = path })
    data = textutils.unserializeJSON(data) -- On convertit le json en table

    -- Vérification de la réponse
    if data.file == nil or data.file == "" then
        if crash_if_error then
            show_code_loading_error("Erreur lors de la récupération du fichier", nil, path, "Le fichier recu est nil ou vide.")
        end
        return nil
    end

    local code = data.file.content
    local code_loaded, err = load(code, path, "t", _ENV)

    if code_loaded == nil then
        if crash_if_error then show_code_loading_error(err, nil, path, err) end
        return nil
    end

    return code_loaded(), data.file.version
end

return {
    get = get,
    post = post,
    get_code = get_code
}