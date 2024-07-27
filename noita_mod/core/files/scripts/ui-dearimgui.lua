local gui = {imgui = nil, screen = {}}

gui.imgui = load_imgui and load_imgui({version="1.21.0", mod="noita-together"}) or nil

do
    local screens = {
        "debug_ui",
        "login",
        "lobbylist",
        "lobby",
        "playerlist",
        "bank",
    }

    for _,n in ipairs(screens) do
        local screen = dofile_once("mods/noita-together/files/scripts/ui/" .. n .. ".lua")
        if screen then
            gui.screen[n] = screen
        end
    end
end

draw_gui = function()
    if not gui.imgui then
        if 0 == (GameGetFrameNum() % 30) then
            GamePrint("Can't load imgui - Is NoitaDearImGui enabled and above Noita Together???")
        end
        return
    end

    for k,v in pairs(gui.screen) do
--        print_error("" .. k .. "? " .. (v.active and "true" or "false"))
        if v.active and v.draw then
            v.draw(gui)
        end
    end
end

