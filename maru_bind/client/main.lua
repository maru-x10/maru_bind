if not lib then
    print('^1[Error] ox_lib is not loaded! Make sure ox_lib is started before this resource.^7')
    return
end

-- Initialize locale (Using 'ja')
lib.locale()

local userBinds = {}
local KVP_KEY = 'maru_keybinds:data'

-- Helper: Get the actual key currently bound to a command in GTA settings
local function getCurrentKey(id)
    local commandName = ('custom_bind_%s'):format(id)
    -- Using the hash of the command with 0x80000000 bit set to get the bound key string
    local button = GetControlInstructionalButton(2, GetHashKey(commandName) | 0x80000000, true)
    if button then
        -- The return value is usually "t_E", "t_F5", etc. Strip the "t_" prefix.
        if button:sub(1, 2) == "t_" then
            return button:sub(3):upper()
        end
        -- Fallback if it's a different format (e.g. controller)
        return button:upper()
    end
    return "???"
end

-- Helper: Convert string input to appropriate type (number, boolean, or nil)
local function formatArg(val)
    if not val or val == "" then return nil end
    local num = tonumber(val)
    if num then return num end
    
    local lower = val:lower()
    if lower == "true" then return true end
    if lower == "false" then return false end
    
    return val
end

-- Helper: Load binds from Client KVP
local function loadBinds()
    local data = GetResourceKvpString(KVP_KEY)
    if data then
        userBinds = json.decode(data)
    else
        userBinds = {}
    end
end

-- Helper: Save binds to Client KVP
local function saveBinds()
    SetResourceKvp(KVP_KEY, json.encode(userBinds))
end

-- Register a specific bind's command and key mapping
local function registerBindAction(bind)
    local commandName = ('custom_bind_%s'):format(bind.id)
    
    RegisterCommand(commandName, function()
        local currentBind = nil
        for _, b in ipairs(userBinds) do
            if b.id == bind.id then
                currentBind = b
                break
            end
        end

        if currentBind then
            local processedArg = formatArg(currentBind.arg)
            
            if currentBind.type == 'command' then
                local action = currentBind.action
                if action:sub(1, 1) == '/' then
                    action = action:sub(2)
                end
                ExecuteCommand(action)
            elseif currentBind.type == 'client_event' then
                TriggerEvent(currentBind.action, processedArg)
            elseif currentBind.type == 'server_event' then
                TriggerServerEvent(currentBind.action, processedArg)
            end
        end
    end, false)

    RegisterKeyMapping(commandName, bind.title, 'keyboard', bind.key)
end

-- Initialization
CreateThread(function()
    loadBinds()
    for _, bind in ipairs(userBinds) do
        registerBindAction(bind)
    end
end)

-- Main Menu
local function openKeybindMenu()
    local options = {
        {
            title = locale('create_new'),
            icon = 'plus',
            onSelect = function()
                local input = lib.inputDialog(locale('input_title'), {
                    { type = 'input', label = locale('label_title'), placeholder = locale('placeholder_title'), required = true },
                    { type = 'input', label = locale('label_key'), placeholder = locale('placeholder_key'), required = true },
                    { 
                        type = 'select', 
                        label = locale('label_type'), 
                        options = {
                            { value = 'command', label = locale('option_command') },
                            { value = 'client_event', label = locale('option_client_event') },
                            { value = 'server_event', label = locale('option_server_event') },
                        },
                        default = 'command',
                        required = true 
                    },
                    { type = 'input', label = locale('label_action'), placeholder = locale('placeholder_action'), required = true },
                    { type = 'input', label = locale('label_argument'), placeholder = locale('placeholder_argument'), required = false },
                })

                if not input then return end

                local newBind = {
                    id = ('%s%s'):format(GetGameTimer(), math.random(100, 999)),
                    title = input[1],
                    key = input[2]:upper(),
                    type = input[3],
                    action = input[4],
                    arg = input[5]
                }

                table.insert(userBinds, newBind)
                saveBinds()
                registerBindAction(newBind)
                
                lib.notify({
                    title = locale('notify_create_success'),
                    description = locale('desc_create_success'):format(newBind.title, newBind.key),
                    type = 'success'
                })
                
                openKeybindMenu()
            end
        }
    }

    if #userBinds > 0 then
        table.insert(options, { title = locale('registered_binds'), metadata = { count = #userBinds }, disabled = true })
        
        for i, bind in ipairs(userBinds) do
            -- Fetch the real key currently assigned in GTA settings
            local currentKey = getCurrentKey(bind.id)
            
            local desc = locale('menu_desc'):format(currentKey, bind.type, bind.action)
            if bind.arg and bind.arg ~= "" then
                desc = desc .. (" | Data: %s"):format(bind.arg)
            end

            table.insert(options, {
                title = bind.title,
                description = desc,
                icon = 'keyboard',
                onSelect = function()
                    lib.registerContext({
                        id = 'maru_bind_options',
                        title = bind.title,
                        menu = 'maru_keybind_menu',
                        options = {
                            {
                                title = locale('edit'),
                                icon = 'pen',
                                onSelect = function()
                                    local input = lib.inputDialog(locale('edit_title'), {
                                        { type = 'input', label = locale('label_title'), default = bind.title, required = true },
                                        { 
                                            type = 'select', 
                                            label = locale('label_type'), 
                                            options = {
                                                { value = 'command', label = locale('option_command') },
                                                { value = 'client_event', label = locale('option_client_event') },
                                                { value = 'server_event', label = locale('option_server_event') },
                                            },
                                            default = bind.type,
                                            required = true 
                                        },
                                        { type = 'input', label = locale('label_action'), default = bind.action, required = true },
                                        { type = 'input', label = locale('label_argument'), default = bind.arg, required = false },
                                    })

                                    if not input then return openKeybindMenu() end

                                    userBinds[i].title = input[1]
                                    userBinds[i].type = input[2]
                                    userBinds[i].action = input[3]
                                    userBinds[i].arg = input[4]

                                    saveBinds()
                                    registerBindAction(userBinds[i])

                                    lib.notify({
                                        title = locale('notify_edit_success'),
                                        description = locale('desc_edit_success'),
                                        type = 'success'
                                    })
                                    openKeybindMenu()
                                end
                            },
                            {
                                title = locale('delete'),
                                icon = 'trash',
                                onSelect = function()
                                    local alert = lib.alertDialog({
                                        header = locale('delete_confirm_header'),
                                        content = locale('delete_confirm_content'),
                                        centered = true,
                                        cancel = true,
                                        labels = { confirm = locale('confirm'), cancel = locale('cancel') }
                                    })

                                    if alert == 'confirm' then
                                        table.remove(userBinds, i)
                                        saveBinds()
                                        lib.notify({
                                            title = locale('notify_delete_success'),
                                            description = locale('desc_delete_success'),
                                            type = 'error'
                                        })
                                        openKeybindMenu()
                                    else
                                        openKeybindMenu()
                                    end
                                end
                            }
                        }
                    })
                    lib.showContext('maru_bind_options')
                end
            })
        end
    end

    lib.registerContext({
        id = 'maru_keybind_menu',
        title = locale('menu_title'),
        options = options
    })

    lib.showContext('maru_keybind_menu')
end

RegisterCommand('keybind', function()
    openKeybindMenu()
end, false)
