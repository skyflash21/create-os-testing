shell.run("set shell.allow_disk_startup false")
shell.run("set motd.enable false")
os.pullEvent = os.pullEventRaw

_G.url = "http://create-os-testing.test"

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
