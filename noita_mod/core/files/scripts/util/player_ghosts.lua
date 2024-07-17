--move player ghost utility code into this file!
function SpawnPlayerGhosts(player_list)
    for userId, player in pairs(player_list) do
        local ghost = SpawnPlayerGhost(player, userId)
        
        --this only happens if SpawnPlayerGhost for some reason returns nil
        --most likely reason for this is because noita emotes overwrote the function
        --see the interoperability notice on SpawnPlayerGhost
        if ghost == nil then
            --this is in a weird spot on purpose, see interop notice on SpawnPlayerGhost
            --invalidate stored ghost entity (it will be recached)
            player.ghostEntityId = nil 
            --apply cosmetics, finding ghost in process
            SetPlayerGhostCosmetics(userId, nil)
            --refresh inventory
            SetPlayerGhostInventory(userId, nil)
        end
    end
end

--interoperability notice: noita emotes overwrites this function, so let infinitesunrise know if we change it
--might(?) still work when moved into this file and dofile() included from original utils.lua???
function SpawnPlayerGhost(player, userId)
    local ghost = EntityLoad("mods/noita-together/files/entities/ntplayer.xml", 0, 0)
    AppendName(ghost, player.name)
    local vars = EntityGetComponent(ghost, "VariableStorageComponent")
    for _, var in pairs(vars) do
        local name = ComponentGetValue2(var, "name")
        if (name == "userId") then
            ComponentSetValue2(var, "value_string", userId)
        end
        if (name == "inven") then
            ComponentSetValue2(var, "value_string", json.encode(PlayerList[userId].inven))
        end
    end
    if (player.x ~= nil and player.y ~= nil) then
        EntitySetTransform(ghost, player.x, player.y)
    end

    --cache the ghost's entity id for this player
    player.ghostEntityId = ghost
    --apply cosmetics (if known)
    SetPlayerGhostCosmetics(userId, ghost)
    --restore emotes skin
    SkinSwapPlayerGhost(userId, nil) --use cached
    --refresh inventory
    SetPlayerGhostInventory(userId, ghost)
    --toggle ghost based on settings
    if ModSettingGet("noita-together.NT_FOLLOW_DEFAULT") then
        EntityAddTag(ghost, "nt_follow")
    end
    --return reference to created ghost
    return ghost
end

function GetGhostUserId(ghost)
    local vars = EntityGetComponent(ghost, "VariableStorageComponent")
    for _, var in pairs(vars) do
        local name = ComponentGetValue2(var, "name")
        if (name == "userId") then
            return ComponentGetValue2(var, "value_string")
        end
    end
end

function DespawnPlayerGhosts()
    local ghosts = EntityGetWithTag("nt_ghost")
    for _, eid in pairs(ghosts) do
        EntityKill(eid)
    end

    --clear cached ghosts from all players
    for userId, entry in pairs(PlayerList) do
        --nt print_error("DespawnPlayerGhosts: invalidating cached ghost for userId " .. userId)
        entry.ghostEntityId = nil
    end
end

function DespawnPlayerGhost(userId)
    local ghosts = EntityGetWithTag("nt_ghost")

    for _, ghost in pairs(ghosts) do
        local id = GetGhostUserId(ghost)
        if id == userId then EntityKill(ghost) end
    end
end

--cull ghosts that shouldnt exist right now
function CullPlayerGhosts()
    local ghosts = EntityGetWithTag("nt_ghost")
    for _, eid in pairs(ghosts) do
        local userId = GetGhostUserId(eid)
        if not userId or not ShouldShowGhost(userId) then
            EntityKill(eid)

            --invalidate cached entry too
            if userId then
                PlayerList[userId].ghostEntityId = nil
                --nt print_error("DespawnPlayerGhosts: invalidating cached ghost for userId " .. userId)
            end
        end
    end
end

function TeleportPlayerGhost(data)
    --cull ghost if we get a teleport packet
    DespawnPlayerGhost(data.userId)
end

function ShouldShowGhost(userId)
    if HideGhosts.mode == HideGhosts.show_all then --all
        --NONE: show all ghosts (subject to culling?)
        return true
    elseif HideGhosts.mode == HideGhosts.show_some then --"some"
        --SOME: host and followed
        --Hey there's no way to tell who is the host!
        --TODO WHO IS HOST?
        if PlayerList[userId].follow_ghost or PlayerList[userId].isHost then
            return true
        end
    end
    --else: none

    return false
--    return hideMode == HIDEMODE_NONE or (Playe
end

function MovePlayerGhost(data)
    local ghost = GetPlayerGhost(data.userId)

    --move packets likely means the player is nearby; spawn their ghost if it doesnt already exist
    if not ghost and ShouldShowGhost(data.userId) then
        ghost = SpawnPlayerGhost(PlayerList[data.userId], data.userId)
    end

    if ghost then
        local dest = get_variable_storage_component(ghost, "dest")
        ComponentSetValue2(dest, "value_string", data.jank)
    end
end

--utility function to get the ghost entity for a particular player, tries cached value then checks all ghosts
function GetPlayerGhost(userId)
    --store/fetch player ghost's entity from its PlayerList object
    local eid = PlayerList[userId].ghostEntityId or 0
    if eid ~= 0 and EntityHasTag(eid, "nt_ghost") then
        local id_comp = get_variable_storage_component(eid, "userId")
        local entityUserId = ComponentGetValue2(id_comp, "value_string")

        if entityUserId == userId then
            --nt print_error("GetPlayerGhost: use cached ghost " .. eid .. " for userId " .. userId)
            return eid
        end
    end

    --ghostEntityId was not the ghost, need to check all ghosts
    local ghosts = EntityGetWithTag("nt_ghost")

    for _, ghost in pairs(ghosts) do
        local id_comp = get_variable_storage_component(ghost, "userId")
        local entityUserId = ComponentGetValue2(id_comp, "value_string")

        if entityUserId == userId then
            --cache this value for later calls
            PlayerList[userId].ghostEntityId = ghost
            --nt print_error("GetPlayerGhost: caching ghost " .. ghost .. " for userId " .. userId)
            return ghost
        end
    end

    --failed to find
    --nt print_error("GetPlayerGhost failed to find for userId " .. userId)
    return nil
end

--set inventory on a player's ghost
--userId is the player userid, non-nil
--ghost is the ghost entity, if nil try to find it
function SetPlayerGhostInventory(userId, ghost)
    --nt print_error("SetPlayerGhostInventory: ghost " .. (ghost or "(nil)") .. ", userId " .. userId)

    --get player ghost entity
    if not ghost then
        ghost = GetPlayerGhost(userId)

        if not ghost then
            --nt print_error("SetPlayerGhostInventory: failed to find player's ghost???")
            --should we print a real error?
            return
        end
    end

    local inven = ","
    for i, wand in ipairs(PlayerList[userId].inven) do
        inven = inven .. "," .. tostring(wand.stats.inven_slot) .. "," .. wand.stats.sprite .. ","
    end

    local inventoryVSComp = get_variable_storage_component(ghost, "inven")
    ComponentSetValue2(inventoryVSComp, "value_string", inven)
end

--PLAYER GHOST COSMETICS
function GetPlayerCosmeticFlags()
    local data = {}
    if HasFlagPersistent( "secret_amulet" ) then
        table.insert(data, "player_amulet")
    end
    if HasFlagPersistent( "secret_amulet_gem" ) then
        table.insert(data, "player_amulet_gem")
    end
    if HasFlagPersistent( "secret_hat" ) then
        table.insert(data, "player_hat2")
    end
    return data
end

function StorePlayerGhostCosmetic(data, refresh)
    if PlayerList[data.userId] ~= nil then
        local cosmeticFlags = {}

        --nt print_error("StorePlayerGhostCosmetic: store " .. ((data and #(data.flags)) or "(nil?)") .. " cosmetic flags for userId " .. data.userId)
        if data.flags and #(data.flags) > 0 then
            for _, flag in pairs(data.flags) do
                cosmeticFlags[#cosmeticFlags+1] = flag
                --nt print_error(" + " .. flag)
            end
        end

        PlayerList[data.userId].cosmeticFlags = cosmeticFlags

        if refresh then
            SetPlayerGhostCosmetics(data.userId)
        end
    else
        --nt print_error("StorePlayerGhostCosmetic: invalid userId " .. data.userId)
    end
end

--set cosmetics on a player's ghost
--userId is the player userid, non-nil
--ghost is the ghost entity, if nil try to find it
function SetPlayerGhostCosmetics(userId, ghost)
    --nt print_error("SetPlayerGhostCosmetics: ghost " .. (ghost or "(nil)") .. ", userId " .. userId)

    --get player ghost entity
    if not ghost then
        ghost = GetPlayerGhost(userId)

        if not ghost then
            --nt print_error("SetPlayerGhostCosmetics: failed to find player's ghost???")
            --should we print a real error?
            return
        end
    end

    --TODO do we need to be able to CLEAR these flags ever?
    for _, flag in pairs(PlayerList[userId].cosmeticFlags) do
        EntitySetComponentsWithTagEnabled(ghost, flag, true)
    end
end

function EmotePlayerGhost(data)
    if ModSettingGet("noita-together.NT_SHOW_EMOTES") then
        local ghost = GetPlayerGhost(data.userId)

        if ghost then
            local children = EntityGetAllChildren(ghost)
            if children then
                for _, child in ipairs(children) do
                    if EntityGetName(child) == "emotes_on_ghost" then
                        local vscs = EntityGetComponentIncludingDisabled(child, "VariableStorageComponent")
                        if vscs then
--                          local current_emote_var_comp = EntityGetComponentIncludingDisabled(child, "VariableStorageComponent")[1]
--                          local frames_emoting_var_comp = EntityGetComponentIncludingDisabled(child, "VariableStorageComponent")[4]
                            ComponentSetValue2(vscs[1], "value_string", data.emote) --current_emote_var_comp
                            ComponentSetValue2(vscs[4], "value_int", 0) --frames_emoting_var_comp
                        end
                    end
                end
            end
        end
    end
end

function SkinSwapPlayerGhost(userId, skin)
    if ModSettingGet("noita-together.NT_SHOW_EMOTES") then
        --use cached value if 'skin' not provided; default to "purple" if that isnt set
        if not skin then
            skin = PlayerList[userId].noitaEmotes.skin or "purple"
        end
        local ghost = GetPlayerGhost(userId)
        if ghost then
            local children = EntityGetAllChildren(ghost)
            if children then
                for _, child in ipairs(children) do
                    if EntityGetName(child) == "emotes_on_ghost" then
                        local skin_var_comp = EntityGetComponentIncludingDisabled(child, "VariableStorageComponent")[8]
                        --nt print_error("skin " .. tostring(data.skin))
                        --nt print_error("skin " .. tostring(skin_var_comp))
                        ComponentSetValue2(skin_var_comp, "value_string", skin)
                    end
                end
            end
        end
    end
end
