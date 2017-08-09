mcl_compass = {}

local default_spawn_settings = minetest.settings:get("static_spawnpoint")

minetest.register_globalstep(function(dtime)
	local players  = minetest.get_connected_players()
	for i,player in ipairs(players) do
		local function has_compass(player)
			for _,stack in ipairs(player:get_inventory():get_list("main")) do
				if minetest.get_item_group(stack:get_name(), "compass") ~= 0 then
					return true
				end
			end
			return false
		end
		if has_compass(player) then
			local spawn = {x=0,y=0,z=0}
			local s = minetest.settings:get("static_spawnpoint")
			if s then
				local numbers = string.split(s, ",")
				spawn.x = tonumber(numbers[1])
				spawn.y = tonumber(numbers[2])
				spawn.z = tonumber(numbers[3])
				if type(spawn.x) ~= "number" and type(spawn.y) ~= "number" and type(spawn.z) ~= "number" then
					spawn = {x=0,y=0,z=0}
				end
			end
			local pos = player:getpos()
			local dir = player:get_look_horizontal()
			local angle_north = math.deg(math.atan2(spawn.x - pos.x, spawn.z - pos.z))
			if angle_north < 0 then angle_north = angle_north + 360 end
			local angle_dir = -math.deg(dir)
			local angle_relative = (angle_north - angle_dir + 180) % 360
			local compass_image = math.floor((angle_relative/11.25) + 0.5)%32

			for j,stack in ipairs(player:get_inventory():get_list("main")) do
				if minetest.get_item_group(stack:get_name(), "compass") ~= 0 and
						minetest.get_item_group(stack:get_name(), "compass")-1 ~= compass_image then
					local count = stack:get_count()
					player:get_inventory():set_stack("main", j, ItemStack("mcl_compass:"..compass_image.." "..count))
				end
			end
		end
	end
end)

local images = {}
for frame=0,31 do
	local s = string.format("%02d", frame)
	table.insert(images, "mcl_compass_compass_"..s..".png")
end

local doc_mod = minetest.get_modpath("doc") ~= nil

local stereotype_frame = 18
for i,img in ipairs(images) do
	local inv = 1
	if i == stereotype_frame then
		inv = 0
	end
	local use_doc, longdesc, usagehelp
	use_doc = i == stereotype_frame
	if use_doc then
		longdesc = "Compasses are tools which point to the world origin (X=0, Z=0) or the spawn point in the Overworld."
	end
	local itemstring = "mcl_compass:"..(i-1)
	minetest.register_craftitem(itemstring, {
		description = "Compass",
		_doc_items_create_entry = use_doc,
		_doc_items_longdesc = longdesc,
		_doc_items_usagehelp = usagehelp,
		inventory_image = img,
		wield_image = img,
		stack_max = 64,
		groups = {not_in_creative_inventory=inv, compass=i, tool=1}
	})

	-- Help aliases. Makes sure the lookup tool works correctly
	if not use_doc and doc_mod then
		doc.add_entry_alias("craftitems", "mcl_compass:"..(stereotype_frame-1), "craftitems", itemstring)
	end
end

minetest.register_craft({
	output = 'mcl_compass:'..stereotype_frame,
	recipe = {
		{'', 'mcl_core:iron_ingot', ''},
		{'mcl_core:iron_ingot', 'mesecons:redstone', 'mcl_core:iron_ingot'},
		{'', 'mcl_core:iron_ingot', ''}
	}
})

minetest.register_alias("mcl_compass:compass", "mcl_compass:"..stereotype_frame)

-- Export stereotype item for other mods to use
mcl_compass.stereotype = "mcl_compass:"..tostring(stereotype_frame)


