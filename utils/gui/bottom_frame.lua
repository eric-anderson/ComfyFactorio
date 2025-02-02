local Misc = require 'utils.commands.misc'
local Event = require 'utils.event'
local Global = require 'utils.global'
local Gui = require 'utils.gui'
local SpamProtection = require 'utils.spam_protection'

local this = {
    players = {},
    activate_custom_buttons = false,
    bottom_quickbar_button = {}
}

Global.register(
    this,
    function(t)
        this = t
    end
)

local Public = {}

local main_frame_name = Gui.uid_name()
local clear_corpse_button_name = Gui.uid_name()
local bottom_quickbar_button_name = Gui.uid_name()

function Public.get_player_data(player, remove_user_data)
    if remove_user_data then
        if this.players[player.index] then
            this.players[player.index] = nil
        end
        return
    end
    if not this.players[player.index] then
        this.players[player.index] = {}
    end
    return this.players[player.index]
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

function Public.remove_player(index)
    this.players[index] = nil
    this.bottom_quickbar_button[index] = nil
end

function Public.reset()
    local players = game.players
    for i = 1, #players do
        local player = players[i]
        if player and player.valid then
            if not player.connected then
                this.players[player.index] = nil
                this.bottom_quickbar_button[player.index] = nil
            end
        end
    end
end

----! Gui Functions ! ----

local function destroy_frame(player)
    local gui = player.gui
    local frame = gui.screen[main_frame_name]
    if frame and frame.valid then
        frame.destroy()
    end
end

local function create_frame(player, alignment, location, portable)
    local gui = player.gui
    local frame = gui.screen[main_frame_name]
    if frame and frame.valid then
        destroy_frame(player)
    end

    alignment = alignment or 'vertical'

    frame =
        player.gui.screen.add {
        type = 'frame',
        name = main_frame_name,
        direction = alignment
    }

    local data = Public.get_player_data(player)

    if data.visible ~= nil then
        if data.visible then
            frame.visible = true
        else
            frame.visible = false
        end
    end

    frame.style.padding = 3
    frame.style.top_padding = 4

    if alignment == 'vertical' then
        frame.style.minimal_height = 96
    end

    frame.location = location
    if portable then
        frame.caption = '•'
    end

    local inner_frame =
        frame.add {
        type = 'frame',
        direction = alignment
    }
    inner_frame.style = 'quick_bar_inner_panel'

    inner_frame.add {
        type = 'sprite-button',
        sprite = 'entity/behemoth-biter',
        name = clear_corpse_button_name,
        tooltip = {'commands.clear_corpse'},
        style = 'quick_bar_page_button'
    }

    local bottom_quickbar_button =
        inner_frame.add {
        type = 'sprite-button',
        name = bottom_quickbar_button_name,
        style = 'quick_bar_page_button'
    }

    this.bottom_quickbar_button[player.index] = {name = bottom_quickbar_button_name, frame = bottom_quickbar_button}

    if this.bottom_quickbar_button.sprite and this.bottom_quickbar_button.tooltip then
        bottom_quickbar_button.sprite = this.bottom_quickbar_button.sprite
        bottom_quickbar_button.tooltip = this.bottom_quickbar_button.tooltip
    end

    return frame
end

local function set_location(player, state)
    local data = Public.get_player_data(player)
    local alignment = 'vertical'

    local location
    local resolution = player.display_resolution
    local scale = player.display_scale

    state = state or data.state

    if state == 'bottom_left' then
        if data.above then
            location = {
                x = (resolution.width / 2) - ((259) * scale),
                y = (resolution.height - (150 * scale))
            }
            alignment = 'horizontal'
        else
            location = {
                x = (resolution.width / 2) - ((54 + 444) * scale),
                y = (resolution.height - (96 * scale))
            }
        end
        data.bottom_state = 'bottom_left'
    elseif state == 'bottom_right' then
        if data.above then
            location = {
                x = (resolution.width / 2) - ((-376) * scale),
                y = (resolution.height - (150 * scale))
            }
            alignment = 'horizontal'
        else
            location = {
                x = (resolution.width / 2) - ((54 + -528) * scale),
                y = (resolution.height - (96 * scale))
            }
        end
        data.bottom_state = 'bottom_right'
    else
        location = {
            x = (resolution.width / 2) - ((54 + -528) * scale),
            y = (resolution.height - (96 * scale))
        }
    end

    data.state = state

    create_frame(player, alignment, location, data.portable)
end

--- Activates the custom buttons
---@param value boolean
function Public.activate_custom_buttons(value)
    this.activate_custom_buttons = value or false
end

--- Fetches if the custom buttons are activated
function Public.is_custom_buttons_enabled()
    return this.activate_custom_buttons
end

Gui.on_click(
    clear_corpse_button_name,
    function(event)
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Clear Corpse')
        if is_spamming then
            return
        end
        Misc.clear_corpses(event)
    end
)

Event.add(
    defines.events.on_player_joined_game,
    function(event)
        if this.activate_custom_buttons then
            local player = game.get_player(event.player_index)
            local data = Public.get_player_data(player)
            set_location(player, data.state)
        end
    end
)

Event.add(
    defines.events.on_player_display_resolution_changed,
    function(event)
        if this.activate_custom_buttons then
            local player = game.get_player(event.player_index)
            local data = Public.get_player_data(player)
            set_location(player, data.state)
        end
    end
)

Event.add(
    defines.events.on_player_display_scale_changed,
    function(event)
        local player = game.get_player(event.player_index)
        if this.activate_custom_buttons then
            local data = Public.get_player_data(player)
            set_location(player, data.state)
        end
    end
)

Event.add(
    defines.events.on_pre_player_left_game,
    function(event)
        local player = game.get_player(event.player_index)
        destroy_frame(player)
    end
)

Event.add(
    defines.events.on_pre_player_died,
    function(event)
        if this.activate_custom_buttons then
            local player = game.get_player(event.player_index)
            destroy_frame(player)
        end
    end
)

Event.add(
    defines.events.on_player_respawned,
    function(event)
        if this.activate_custom_buttons then
            local player = game.get_player(event.player_index)
            local data = Public.get_player_data(player)
            set_location(player, data.state)
        end
    end
)

Event.add(
    defines.events.on_player_removed,
    function(event)
        Public.remove_player(event.player_index)
    end
)

function Public.toggle_player_frame(player, state)
    local gui = player.gui
    local frame = gui.screen[main_frame_name]
    if frame and frame.valid then
        local data = Public.get_player_data(player)
        if state then
            data.visible = true
            frame.visible = true
        else
            data.visible = false
            frame.visible = false
        end
    end
end
Public.main_frame_name = main_frame_name
Public.set_location = set_location
Gui.screen_to_bypass(main_frame_name)

return Public
