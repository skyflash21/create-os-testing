-- Cette classe sert de base afin de crée des autres, c'est un template. --

local module = {}
module.__index = module

-- Constructeur de la classe
function module.new()
    local self = setmetatable({}, module)
    self.name = "sample"
    self.session_id = 0

    return self
end

function module:run(current_session_id)
    self.session_id = current_session_id
    while true do
        local event, arg1, arg2, arg3 = os.pullEvent()

        -- nettoyage des valeurs
        arg1 = arg1 or "nil"
        arg2 = arg2 or "nil"
        arg3 = arg3 or "nil"

        if event == "stop_module" and arg1 == self.session_id then

            return
        elseif event == "complete_websocket_message" then

        end
    end
end

function module:start()
end

function module:command_help()
end

function module:command_run(type, arguments)
end

function module:log(message, priority)
    priority = priority%3 or 0

    local post_color = term.getTextColor()
    term.setTextColor(self.priority_colors[priority])
    print("["..self.name.."] "..message)
    term.setTextColor(post_color)
end

return module