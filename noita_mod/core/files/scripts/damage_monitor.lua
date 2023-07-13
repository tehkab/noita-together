dofile_once("data/scripts/lib/utilities.lua")

function damage_received( damage, desc, entity_who_caused, is_fatal )
    local entity_id = GetUpdatedEntityID()

    if(damage > 0 and is_fatal) then
        --store in preparation for death message tx
        NT.last_killed_by=desc
        
        if(entity_who_caused == nil) or ( entity_who_caused == NULL_ENTITY ) then
            NT.last_killed_by_entity=nil
            --GamePrint("killed by nil: \"" .. desc .. "\"")
        else
            NT.last_killed_by_entity=EntityGetName(entity_who_caused)
            --GamePrint("killed by \"" .. GameTextGet(EntityGetName(entity_who_caused)) .. "\" : \"" .. GameTextGet(desc) .. "\"")
        end

        --disable myself for now, reenable after respawned
        EntitySetComponentsWithTagEnabled(entity_id, "NT_damage_monitor", false)
    end
end