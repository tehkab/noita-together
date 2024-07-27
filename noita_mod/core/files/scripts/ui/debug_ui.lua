local function draw(gui)
    local imgui = gui.imgui
    if imgui.Begin("NT UI tests") then
        imgui.Text("Show windows")

        for k,v in pairs(gui.screen) do
            if k ~= "debug_ui" then
                imgui.SameLine()
                clicked, state = imgui.Checkbox(k, v.active)
                if clicked then
                    if k == "debug_ui" then
                        GamePrint("sorry you cant turn this one off right now :D")
                    else
                        GamePrint("toggle " .. k .. " " .. (state and "ON" or "OFF"))
                        v.active = state
                    end
                end
            end
        end

        imgui.End()
    end
end

return {active = true, draw = draw}

