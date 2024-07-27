local function draw(gui)
    local imgui = gui.imgui
    if imgui.Begin("Players") then
        imgui.Text("where are the players? :D")

        imgui.End()
    end
end

return {active = false, draw = draw}
