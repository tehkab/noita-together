dofile_once("data/scripts/lib/utilities.lua")
local entity_id = GetUpdatedEntityID()
local x, y = EntityGetTransform(entity_id)
EntityLoad("data/entities/projectiles/deck/crumbling_earth.xml", x, y)
EntityKill(entity_id)