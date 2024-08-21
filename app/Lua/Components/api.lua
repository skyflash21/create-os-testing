local function get(path,header)
    local header = { Authorization = "Bearer " .. settings.get("token"), ["Content-Type"] = "application/json", ["Accept"] = "application/json", ["Host"] = "create-os-testing.test" }

    -- On ajoute les headers passés en paramètre
    for key, value in pairs(header) do
        header[key] = value
    end

    local response, fail_string, http_failing_response = http.get("http://".._G.url.. "/api/"..path, header)
end

return {
    api_call = api_call
}