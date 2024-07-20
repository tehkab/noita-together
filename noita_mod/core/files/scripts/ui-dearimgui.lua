local imgui = load_imgui and load_imgui({version="1.21.0", mod="noita-together"}) or nil

draw_gui = function()
    if not imgui then
        if 0 == (GameGetFrameNum() % 30) then
            GamePrint("Can't load imgui - Is NoitaDearImGui enabled and above Noita Together???")
        end
        return
    end
end


