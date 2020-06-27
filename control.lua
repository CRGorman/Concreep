PavementName = "refined-concrete"
DebugMode = false

function init()
	global.creepers = {} --Roboports added to list
	global.index = 1
	if DebugMode then
		game.print("Total surfaces" .. #game.surfaces)
	end
	for surfaceIndex, surface in pairs(game.surfaces) do
		for index, port in pairs(surface.find_entities_filtered{type="roboport"}) do
			addPort(port)
		end
	end
end

function checkRoboports()	
	if not(game.item_prototypes[settings.global["alternate pavement"].value] == nil) then
		PavementName = settings.global["alternate pavement"].value
	end
	if DebugMode then
		game.print("Alternative Pavement Type: " .. settings.global["alternate pavement"].value)
		game.print("Pavement Type: " .. PavementName)
		game.print("Total Roboports seen: " .. #global.creepers)
	end
	if global.creepers and #global.creepers > 0 then
		for index, creeper in pairs(global.creepers) do
			local creeper = global.creepers[global.index]
			if creeper then -- Redundant?
				local roboport = creeper.roboport
				local radius = creeper.radius
				local amount = 0			
				if roboport and roboport.valid then --Check if still alive
					if roboport.logistic_network and roboport.logistic_network.valid and roboport.prototype.electric_energy_source_prototype.buffer_capacity == roboport.energy then --Check if powered!
						if roboport.logistic_cell.construction_radius == 0 then --Not a valid creeper.
							table.remove(global.creepers, global.index)
							return false
						end
						if roboport.logistic_network.available_construction_robots > 0 then
							local constructionFactor = settings.global["concreep construction factor"].value
							amount = math.max(math.floor(roboport.logistic_network.available_construction_robots / constructionFactor), 1)
							if DebugMode then
								game.print("Total Construction Robots / ".. constructionFactor .. ": " .. amount)
							end
							if creep(global.index, amount) then
								return true
							end
						end
					else
						return false
					end
				else -- Roboport died
					table.remove(global.creepers, global.index)
				end
			else
				table.remove(global.creepers, global.index)
			end
			global.index = global.index + 1
			if global.index > #global.creepers then
				global.index = 1
			end
		end
	else
		if DebugMode then
			game.print("Reinit called")
		end
		init()
	end
end

function creep(index, amount)
	local creeper = global.creepers[index]
	--game.print(serpent.line(index))
	local roboport = creeper.roboport
	local radius = creeper.radius
	local count = 0
	--if roboport.logistic_network.get_item_count("concrete") > 0 then
		-- Need to offset up and left as +radius is outside of the actual radius.
		for xx = -radius, radius-1, 1 do
			for yy = -radius, radius-1, 1 do
				if xx <= -radius+1 or xx >= radius-2 or yy <= -radius+1 or yy >= radius-2 then --Check only the outer ring, width 2.
					local tile = roboport.surface.get_tile(roboport.position.x + xx, roboport.position.y + yy)
					--Skip already built tiles.
					if not tile.hidden_tile or (not string.find(tile.name, "concrete") and not settings.global["ignore placed tiles"].value and not string.find(tile.name, PavementName)) then
						local ghost = creeper.pattern[(xx-2) % 4][(yy-2) % 4]
						local it = creeper.item[(xx-2) % 4][(yy-2) % 4]
						local area = {{roboport.position.x + xx-0.2,  roboport.position.y + yy-0.2},{roboport.position.x + xx+0.8,  roboport.position.y + yy + 0.8}}
						if ghost and it then
							if roboport.logistic_network.get_item_count(it) >= amount then
								if roboport.surface.can_place_entity{name="tile-ghost", position={roboport.position.x + xx, roboport.position.y + yy}, inner_name=ghost, force=roboport.force} then
									roboport.surface.create_entity{name="tile-ghost", position={roboport.position.x + xx, roboport.position.y + yy}, inner_name=ghost, force=roboport.force, expires=false}
									for i, tree in pairs(roboport.surface.find_entities_filtered{type = "tree", area=area}) do
										tree.order_deconstruction(roboport.force)
									end
									--for i, rock in pairs(roboport.surface.find_entities_filtered{name = "stone-rock", area=area}) do
									for i, rock in pairs(roboport.surface.find_entities_filtered{type = "simple-entity", area=area}) do
										rock.order_deconstruction(roboport.force)
									end
									for i, cliff in pairs(roboport.surface.find_entities_filtered{type = "cliff", limit=1, area=area}) do
										if roboport.logistic_network.get_item_count("cliff-explosives") > 0 then
											cliff.order_deconstruction(roboport.force)
										end
									end
									count = count + 1
									--game.print(count .. " " .. amount)
								end
							else -- No concrete!
								if roboport.logistic_network.get_item_count(it) > 0 then
									amount = roboport.logistic_network.get_item_count(it)
									yy = yy - 1 -- Step loop backwards so we try again.
								else
									return false
								end
							end
						else
							log("Concreep: Error!  Concreep Pattern invalid.")
							--game.print("Tile: " .. serpent.line(ghost) .. " and item: " .. serpent.line(it))
						end
						if count >= amount then
							return true
						end
					end
				end
			end
		end
		-- Loop is over and we're still here?  Increase the raidus.
		if count == 0 then
			creeper.radius = creeper.radius + 1
			local cell = roboport.logistic_cell
			if cell and cell.valid and creeper.radius > (cell.construction_radius * settings.global["concreep range"].value / 100) then
				--Turn recheck mode on.  If recheck mode is already on, turn creeper off.
				if creeper.recheck then
					table.remove(global.creepers, index)
				else
					creeper.recheck = true
					creeper.radius = 1
				end
			end
		end
		return false
	--end
end

function roboports(event)
	if global.creepers then
		if global.creepers.count == nil then
			if event.created_entity and event.created_entity.valid and event.created_entity.type == "roboport" then
				addPort(event.created_entity)
			end
		else
			init()
		end	
	else
		init()
	end
end

function addPort(robo)
	local surface = robo.surface
	-- Now capture the pattern the roboport sits on.
	local patt = {}
	local it = {}
	for xx = -2, 1, 1 do
	patt[xx+2] = {}
	it[xx+2] = {}
		for yy = -2, 1, 1 do		
			local tile = surface.get_tile(robo.position.x + xx, robo.position.y + yy)
			if string.find(tile.name, PavementName) or string.find(tile.name, "dect-") then
				local items = tile.prototype.items_to_place_this
				it[xx+2][yy+2] = next(items, nil)
				patt[xx+2][yy+2] = tile.name
				--game.print(serpent.line(items))
			else
				patt[xx+2][yy+2] = PavementName
				it[xx+2][yy+2] = PavementName
			end
		end
	end
	table.insert(global.creepers, {roboport = robo, radius = 1, pattern = patt, item = it})
end	

function AdvanceIndex()
	if #global.creepers > 0 then
		global.index = global.index + 1
		if global.index > #global.creepers then
			global.index = 1
		end
	end
end

script.on_event(defines.events.on_built_entity, function(event)
	roboports(event)
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
	roboports(event)
end)

script.on_nth_tick(settings.global["tick count"].value, function(event)
	local retries = 0
	while (not checkRoboports()) and retries < 10 do
		AdvanceIndex()
		retries = retries + 1
	end	
end)

script.on_init(function()
	init()
end)

script.on_load(function()
	DebugMode = settings.global["debug mode"].value
end)

function tablelength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end