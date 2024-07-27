local function draw(gui)
    local imgui = gui.imgui
    if imgui.Begin("Bank") then
        imgui.Text("wheres my money?")

        imgui.End()
    end
end

return {active = false, draw = draw}
