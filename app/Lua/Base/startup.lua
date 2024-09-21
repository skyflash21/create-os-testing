shell.run("set shell.allow_disk_startup false")
shell.run("set motd.enable false")
os.pullEvent = os.pullEventRaw

_G.url = "http://127.0.0.1:8000"
_G.host = "localhost"

local args = {...}
_ENV.start_args = {}

if #args == 1 then
    -- Vérification que les arguments sont bons
    if type(args[1]) ~= "string" then
        print("Error: Invalid arguments")
        read()
        os.shutdown()
    end
    _ENV.start_args = { token = args[1] }
elseif #args == 3 then
    -- Vérification que les arguments sont bons
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

    term.setBackgroundColor(colors.red)
    term.setTextColor(colors.white)
    term.clear()

    center_print("503 Service Unavailable", 5)
    center_print("Impossible de contacter l'API", 7)
    center_print("Veuillez contacter Skyflash21", 15)
    center_print("Discord : skyflash21", 16)

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
            center_print("Redemarrage dans " .. minutes .. " minutes et " .. seconds .. " secondes", 18)
            wait_timer = os.startTimer(1)
            current_wait_time = current_wait_time + 1
        elseif event == "key" and arg1 == keys.enter then
            os.shutdown()
        end
    end
end

local response, http_failing_response = http.get(_G.url .. "/api/bootstrap");

if response then
    local code = response.readAll()
    response.close()

    local func, err = load(code, "bootstrap", "t", _ENV)
    if not func then
        term.setTextColor(colors.red)
        print("Error: " .. err)
        read()
        os.shutdown()
    end

    -- Fonction personnalisée pour gérer les erreurs et afficher la ligne en question
    local function error_handler(err)
        term.setTextColor(colors.red)
        print("Error: " .. err)
        read()
        os.shutdown()
    end

    -- Utiliser xpcall avec la fonction error_handler
    local ok = xpcall(func, error_handler)
    os.shutdown()
else
    print("Error: Impossible de récupérer le bootstrap")
    read()
    os.shutdown()
end
