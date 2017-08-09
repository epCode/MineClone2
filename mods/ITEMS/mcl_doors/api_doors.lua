-- Registers a door
--  name: The name of the door
--  def: a table with the folowing fields:
--    description
--    inventory_image
--    groups
--    tiles_bottom: the tiles of the bottom part of the door {front, side}
--    tiles_top: the tiles of the bottom part of the door {front, side}
--    If the following fields are not defined the default values are used
--    node_box_bottom
--    node_box_top
--    selection_box_bottom
--    selection_box_top
--    only_placer_can_open: if true only the player who placed the door can
--                          open it
--    only_redstone_can_open: if true, the door can only be opened by redstone,
--                            not by rightclicking it

function mcl_doors:register_door(name, def)
	def.groups.not_in_creative_inventory = 1
	def.groups.dig_by_piston = 1
	def.groups.door = 1

	if not def.sound_open then
		def.sound_open = "doors_door_open"
	end
	if not def.sound_close then
		def.sound_close = "doors_door_close"
	end

	local box = {{-8/16, -8/16, -8/16, 8/16, 8/16, -5/16}}

	if not def.node_box_bottom then
		def.node_box_bottom = box
	end
	if not def.node_box_top then
		def.node_box_top = box
	end
	if not def.selection_box_bottom then
		def.selection_box_bottom= box
	end
	if not def.selection_box_top then
		def.selection_box_top = box
	end

	local longdesc, usagehelp
	longdesc = def._doc_items_longdesc
	if not longdesc then
		if def.only_redstone_can_open then
			longdesc = "This door is a 2-block high barrier which can be opened or closed by hand or by redstone power."
		else
			longdesc = "This door is a 2-block high barrier which can only be opened by redstone power, not by hand."
		end
	end
	usagehelp = def._doc_items_usagehelp
	if not usagehelp then
		if def.only_redstone_can_open then
			usagehelp = "To open or close this door, send a redstone signal to its bottom half."
		else
			usagehelp = "To open or close this door, rightclick it or send a redstone signal to its bottom half."
		end
	end

	minetest.register_craftitem(name, {
		description = def.description,
		_doc_items_longdesc = longdesc,
		_doc_items_usagehelp = usagehelp,
		inventory_image = def.inventory_image,
		stack_max = 64,
		groups = { mesecon_conductor_craftable = 1 },
		on_place = function(itemstack, placer, pointed_thing)
			if not pointed_thing.type == "node" or not placer or not placer:is_player() then
				return itemstack
			end
			local pn = placer:get_player_name()
				if minetest.is_protected(pointed_thing.above, pn) and minetest.is_protected(pointed_thing.under, pn) then
					return itemstack
				end
					local ptu = pointed_thing.under
					local nu = minetest.get_node(ptu)
					-- Pointed thing's rightclick action takes precedence, unless player holds down the sneak key
					if minetest.registered_nodes[nu.name] and minetest.registered_nodes[nu.name].on_rightclick and not placer:get_player_control().sneak then
						return minetest.registered_nodes[nu.name].on_rightclick(ptu, nu, placer, itemstack)
					end

					local pt
					if minetest.registered_nodes[nu.name] and minetest.registered_nodes[nu.name].buildable_to then
						pt = pointed_thing.under
					else
						pt = pointed_thing.above
					end
					local pt2 = {x=pt.x, y=pt.y, z=pt.z}
					pt2.y = pt2.y+1
					local ptname = minetest.get_node(pt).name
					local pt2name = minetest.get_node(pt2).name
					if
						(minetest.registered_nodes[ptname] and not minetest.registered_nodes[ptname].buildable_to) or
						(minetest.registered_nodes[pt2name] and not minetest.registered_nodes[pt2name].buildable_to)
					then
						return itemstack
					end

					local p2 = minetest.dir_to_facedir(placer:get_look_dir())
					local pt3 = {x=pt.x, y=pt.y, z=pt.z}
					if p2 == 0 then
						pt3.x = pt3.x-1
					elseif p2 == 1 then
						pt3.z = pt3.z+1
					elseif p2 == 2 then
						pt3.x = pt3.x+1
					elseif p2 == 3 then
						pt3.z = pt3.z-1
					end
					if not string.find(minetest.get_node(pt3).name, name.."_b_") then
						minetest.set_node(pt, {name=name.."_b_1", param2=p2})
						minetest.set_node(pt2, {name=name.."_t_1", param2=p2})
					else
						minetest.set_node(pt, {name=name.."_b_2", param2=p2})
						minetest.set_node(pt2, {name=name.."_t_2", param2=p2})
					end
					if def.sounds and def.sounds.place then
						minetest.sound_play(def.sounds.place, {pos=pt})
					end

					if def.only_placer_can_open then
						local meta = minetest.get_meta(pt)
						meta:set_string("doors_owner", "")
						meta = minetest.get_meta(pt2)
						meta:set_string("doors_owner", "")
					end

					-- Save open state. 1 = open. 0 = closed
					local meta = minetest.get_meta(pt)
					meta:set_int("is_open", 0)
					meta = minetest.get_meta(pt2)
					meta:set_int("is_open", 0)

					if not minetest.settings:get_bool("creative_mode") then
						itemstack:take_item()
					end
				return itemstack
		end,
	})

	local tt = def.tiles_top
	local tb = def.tiles_bottom

	local function on_open_close(pos, dir, check_name, replace, replace_dir, params)
		local meta1 = minetest.get_meta(pos)
		pos.y = pos.y+dir
		local meta2 = minetest.get_meta(pos)
		if not minetest.get_node(pos).name == check_name then
			return
		end
		local p2 = minetest.get_node(pos).param2
		local np2 = params[p2+1]

		local metatable = minetest.get_meta(pos):to_table()
		minetest.set_node(pos, {name=replace_dir, param2=np2})
		minetest.get_meta(pos):from_table(metatable)

		pos.y = pos.y-dir
		metatable = minetest.get_meta(pos):to_table()
		minetest.set_node(pos, {name=replace, param2=np2})
		minetest.get_meta(pos):from_table(metatable)

		local door_switching_sound
		if meta1:get_int("is_open") == 1 then
			door_switching_sound = def.sound_close
			meta1:set_int("is_open", 0)
			meta2:set_int("is_open", 0)
		else
			door_switching_sound = def.sound_open
			meta1:set_int("is_open", 1)
			meta2:set_int("is_open", 1)
		end
		minetest.sound_play(door_switching_sound, {pos = pos, gain = 0.5, max_hear_distance = 16})
	end

	local function on_mesecons_signal_open (pos, node)
		on_open_close(pos, 1, name.."_t_1", name.."_b_2", name.."_t_2", {1,2,3,0})
	end

	local function on_mesecons_signal_close (pos, node)
		on_open_close(pos, 1, name.."_t_2", name.."_b_1", name.."_t_1", {3,0,1,2})
	end

	local function check_player_priv(pos, player)
		if not def.only_placer_can_open then
			return true
		end
		local meta = minetest.get_meta(pos)
		local pn = player:get_player_name()
		return meta:get_string("doors_owner") == pn
	end

	local on_rightclick
	-- Disable on_rightclick if this is a redstone-only door
	if not def.only_redstone_can_open then
		on_rightclick = function(pos, node, clicker)
			if check_player_priv(pos, clicker) then
				on_open_close(pos, 1, name.."_t_1", name.."_b_2", name.."_t_2", {1,2,3,0})
			end
		end
	end

	minetest.register_node(name.."_b_1", {
		tiles = {tt[2].."^[transformFY", tt[2], tb[2].."^[transformFX", tb[2], tb[1], tb[1].."^[transformFX"},
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		is_ground_content = false,
		drop = name,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = def.node_box_bottom
		},
		selection_box = {
			type = "fixed",
			fixed = def.selection_box_bottom
		},
		groups = def.groups,
		_mcl_hardness = def._mcl_hardness,
		_mcl_blast_resistance = def._mcl_blast_resistance,
		sounds = def.sounds,

		after_destruct = function(bottom, oldnode)
			local top = { x = bottom.x, y = bottom.y + 1, z = bottom.z }
			if minetest.get_node(bottom).name == "air" and minetest.get_node(top).name == name.."_t_1" then
				minetest.remove_node(top)
			end
		end,

		on_rightclick = on_rightclick,

		mesecons = { effector = {
			action_on = on_mesecons_signal_open
		}},

		can_dig = check_player_priv,
	})

	if def.only_redstone_can_open then
		on_rightclick = nil
	else
		on_rightclick = function(pos, node, clicker)
			if check_player_priv(pos, clicker) then
				on_open_close(pos, -1, name.."_b_1", name.."_t_2", name.."_b_2", {1,2,3,0})
			end
		end
	end

	minetest.register_node(name.."_t_1", {
		tiles = {tt[2].."^[transformFY", tt[2], tt[2].."^[transformFX", tt[2], tt[1], tt[1].."^[transformFX"},
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		is_ground_content = false,
		drop = "",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = def.node_box_top
		},
		selection_box = {
			type = "fixed",
			fixed = def.selection_box_top
		},
		groups = def.groups,
		_mcl_hardness = def._mcl_hardness,
		_mcl_blast_resistance = def._mcl_blast_resistance,
		sounds = def.sounds,

		after_destruct = function(top, oldnode)
			local bottom = { x = top.x, y = top.y - 1, z = top.z }
			if minetest.get_node(top).name == "air" and minetest.get_node(bottom).name == name.."_b_1" and oldnode.name == name.."_t_1" then
				minetest.dig_node(bottom)
			end
		end,

		on_rightclick = on_rightclick,

		can_dig = check_player_priv,
	})

	if def.only_redstone_can_open then
		on_rightclick = nil
	else
		on_rightclick = function(pos, node, clicker)
			if check_player_priv(pos, clicker) then
				on_open_close(pos, 1, name.."_t_2", name.."_b_1", name.."_t_1", {3,0,1,2})
			end
		end
	end

	minetest.register_node(name.."_b_2", {
		tiles = {tt[2].."^[transformFY", tt[2], tb[2].."^[transformFX", tb[2], tb[1].."^[transformFX", tb[1]},
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		is_ground_content = false,
		drop = name,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = def.node_box_bottom
		},
		selection_box = {
			type = "fixed",
			fixed = def.selection_box_bottom
		},
		groups = def.groups,
		_mcl_hardness = def._mcl_hardness,
		_mcl_blast_resistance = def._mcl_blast_resistance,
		sounds = def.sounds,

		after_destruct = function(bottom, oldnode)
			local top = { x = bottom.x, y = bottom.y + 1, z = bottom.z }
			if minetest.get_node(bottom).name == "air" and minetest.get_node(top).name == name.."_t_2" then
				minetest.remove_node(top)
			end
		end,

		on_rightclick = on_rightclick,

		mesecons = { effector = {
			action_on = on_mesecons_signal_close
		}},

		can_dig = check_player_priv,
	})

	if def.only_redstone_can_open then
		on_rightclick = nil
	else
		on_rightclick = function(pos, node, clicker)
			if check_player_priv(pos, clicker) then
				on_open_close(pos, -1, name.."_b_2", name.."_t_1", name.."_b_1", {3,0,1,2})
			end
		end
	end

	minetest.register_node(name.."_t_2", {
		tiles = {tt[2].."^[transformFY", tt[2], tt[2].."^[transformFX", tt[2], tt[1].."^[transformFX", tt[1]},
		paramtype = "light",
		paramtype2 = "facedir",
		sunlight_propagates = true,
		is_ground_content = false,
		drop = "",
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = def.node_box_top
		},
		selection_box = {
			type = "fixed",
			fixed = def.selection_box_top
		},
		groups = def.groups,
		_mcl_hardness = def._mcl_hardness,
		_mcl_blast_resistance = def._mcl_blast_resistance,
		sounds = def.sounds,

		after_destruct = function(top, oldnode)
			local bottom = { x = top.x, y = top.y - 1, z = top.z }
			if minetest.get_node(top).name == "air" and minetest.get_node(bottom).name == name.."_b_2" and oldnode.name == name.."_t_2" then
				minetest.dig_node(bottom)
			end
		end,

		on_rightclick = on_rightclick,

		can_dig = check_player_priv,
	})

	-- Add entry aliases for the Help
	if minetest.get_modpath("doc") then
		doc.add_entry_alias("craftitems", name, "nodes", name.."_b_1")
		doc.add_entry_alias("craftitems", name, "nodes", name.."_b_2")
		doc.add_entry_alias("craftitems", name, "nodes", name.."_t_1")
		doc.add_entry_alias("craftitems", name, "nodes", name.."_t_2")
	end

end
