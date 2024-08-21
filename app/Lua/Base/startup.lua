shell.run("set shell.allow_disk_startup false")
shell.run("set motd.enable false")
os.pullEvent = os.pullEventRaw

_G.url = "http://create-os-testing.test"

local args = {...}
_ENV.start_args = {}

if #args == 1 then
    -- Vérification que les arguments sont bon
    if type(args[1]) ~= "string" then
        print("Error: Invalid arguments")
        read()
        os.shutdown()
    end
    _ENV.start_args = { token = args[1] }
elseif #args == 3 then
    -- Vérification que les arguments sont bon
    if type(args[1]) ~= "string" or type(args[2]) ~= "string" or type(args[3]) ~= "string" then
        print("Error: Invalid arguments")
        read()
        os.shutdown()
    end
    _ENV.start_args = { token = args[1], name = args[2], description = args[3] }
end

local function is_api_available()
    local response, fail_string, http_failing_response = http.get(_G.url .. "/api/api_test")
    if not response then
        return false, fail_string
    else
        return true
    end
end

if not is_api_available() then
    local function center_print(text, y)
        local term_width, term_height = term.getSize()
        local x = term_width / 2 - #text / 2
        term.setCursorPos(x, y)
        term.write(text)
    end
    local key = ""
    while key ~= "q" do
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.white)
        term.clear()

        center_print("503 Service Unavailable", 5)
        center_print("Impossible de contacter l'API", 7)
        center_print("Veuillez contacter Skyflash21", 15)
        center_print("Discord : skyflash21", 16)

        _, key = os.pullEvent("key")
    end
    os.shutdown()
end

local response, http_failing_response = http.get(_G.url .. "/api/startup");

if response then
    if fs.exists("startup") then
        fs.delete("startup")
    end
    local file = fs.open("startup", "w")
    file.write(response.readAll())
    file.close()
    response.close()
else
    print("Error: " .. http_failing_response.getResponseCode())
    read()
    os.shutdown()
end

local response, http_failing_response = http.get(_G.url .. "/api/bootstrap");

if response then
    local code = response.readAll()
    response.close()

    local func, err = load(code, "bootstrap", "t", _ENV)
    if not func then
        print("Error: " .. err)
        read()
        os.shutdown()
    end

    local ok, err = pcall(func)
    if not ok then
        print("Error: " .. err)
        read()
        os.shutdown()
    end
else
    print("Error: " .. http_failing_response.getResponseCode())
    read()
    os.shutdown()
end
