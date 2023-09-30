dofile_once("mods/noita-together/files/scripts/utils.lua")
dofile_once("mods/noita-together/files/store.lua")

--return true if we should end the run due to low max hp
function HostCheckDeathPenalty()
    --must be host
    if not NT.is_host then return end
    --nt print_error("HostCheckDeathPenalty")

    local MAXHP_END_RUN_THRESHOLD = 1

--    local player_maxhp_list = {}
    local mean_maxhp = 0
    local maxhp_reduced = 0
--[[
    local players_under_threshold = 0
]]--

    --create list for median check, and sum maxhp
    for id,player in pairs(PlayerList) do
        --nt print_error("" .. id .. " \"" .. player.name .. "\"" " .. player.maxHp)
        maxhp_reduced = player.maxHp * 0.8 --TODO: need to track other players multipliers, use strict default for now
--        player_maxhp_list[id] = maxhp_reduced
        mean_maxhp = mean_maxhp + maxhp_reduced
--[[
        if maxhp_reduced < MAXHP_END_RUN_THRESHOLD then
            players_under_threshold = players_under_threshold + 1
        end
]]--
    end

    --dont forget to add ourself :^)
    local player = GetPlayer()
    local damage_model = EntityGetFirstComponent(player, "DamageModelComponent")
    maxhp_reduced = ComponentGetValue2(damage_model, "max_hp") * GetDeathPenaltyMaxHPMultiplier()
    mean_maxhp = mean_maxhp + maxhp_reduced
    --[[if maxhp_reduced < MAXHP_END_RUN_THRESHOLD then
        players_under_threshold = players_under_threshold + 1
    end]]--

    --average maxhps
    mean_maxhp = mean_maxhp / (#PlayerList + 1)

    --sort list
--    table.sort(player_maxhp_list)

    --nt print_error("mean maxhp is " .. mean_maxhp .. " (" .. (#PlayerList+1) .. " players)")

    --too many players under threshold? only use this check if enough players
--[[    --just an idea, might not use
    if #PlayerList > 8 and players_under_threshold > (#PlayerList+1) / 4
      return true
    end
]]--

    --(MEAN): fail if under threshold, simplest method i think
    if mean_maxhp < MAXHP_END_RUN_THRESHOLD then
        --nt print_error("(NT) MEAN MAXHP FAILED - KILL NOW!")
        return true
    end
end