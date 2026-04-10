if not lib then
    print('^1[Error] ox_lib is not loaded! Make sure ox_lib is started before this resource.^7')
    return
end

-- Initialize locale
lib.locale()

local userBinds = {}
local KVP_KEY = 'maru_keybinds:data'

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
        -- Re-verify the bind exists in the list (in case it was deleted)
        local found = false
        for _, b in ipairs(userBinds) do
            if b.id == bind.id then
                found = true
                break
            end
        end

        if found then
            if bind.type == 'command' then
                local action = bind.action
                if action:sub(1, 1) == '/' then
                    action = action:sub(2)
                end
                ExecuteCommand(action)
            elseif bind.type == 'client_event' then
                TriggerEvent(bind.action)
            elseif bind.type == 'server_event' then
                TriggerServerEvent(bind.action)
            end
        end
    end, false)

    -- Register the key mapping (FiveM handles persistence of the key itself)
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
                })

                if not input then return end

                local newBind = {
                    id = ('%s%s'):format(GetGameTimer(), math.random(100, 999)),
                    title = input[1],
                    key = input[2]:upper(),
                    type = input[3],
                    action = input[4]
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
            table.insert(options, {
                title = bind.title,
                description = locale('menu_desc'):format(bind.key, bind.type, bind.action),
                icon = 'keyboard',
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = locale('delete_confirm_header'),
                        content = locale('delete_confirm_content'),
                        centered = true,
                        cancel = true,
                        labels = {
                            confirm = locale('confirm'),
                            cancel = locale('cancel')
                        }
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
