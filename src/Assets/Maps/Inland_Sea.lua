------------------------------------------------------------------------------
--	FILE:	 Inland_Sea.lua
--	AUTHOR:  Bob Thomas
--	PURPOSE: Regional map script - Loosely simulates a Mediterranean type
--	         temperate zone with civs ringing a central sea.
------------------------------------------------------------------------------
--	Copyright (c) 2014 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------

include("MapGenerator");
include("MultilayeredFractal");
include("TerrainGenerator");
include("RiverGenerator");
include("FeatureGenerator");
include("MapmakerUtilities");

------------------------------------------------------------------------------
function GetMapScriptInfo()
	local world_age, temperature, rainfall, sea_level, resources = GetCoreMapOptions()

	return {
		Name = "TXT_KEY_MAP_INLAND_SEA",
		Type = "TXT_KEY_MAP_INLAND_SEA",
		Description = "TXT_KEY_MAP_INLAND_SEA_HELP",
		IsAdvancedMap = false,
		IconIndex = 12,
		
		CustomOptions = {world_age, temperature, rainfall, resources},
	}
end
------------------------------------------------------------------------------

-------------------------------------------------------------------------------
function GetMapInitData(worldSize)
	-- This function can reset map grid sizes or world wrap settings.
	local worldsizes = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {28, 18},
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {36, 22},
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {46, 28},
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {60, 36},
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {72, 44},
		--[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {84, 52}
		}
	local grid_size = worldsizes[worldSize];
	--
	local world = GameInfo.Worlds[worldSize];
	if(world ~= nil) then
	return {
		Width = grid_size[1],
		Height = grid_size[2],
		WrapX = false,
	};      
     end
end
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
function MultilayeredFractal:GeneratePlotsByRegion()
	-- Sirian's MultilayeredFractal controlling function.
	-- You -MUST- customize this function for each script using MultilayeredFractal.
	--
	-- This implementation is specific to Inland Sea.
	local iW, iH = Map.GetGridSize();

	-- Fill all rows with land plots.
	self.wholeworldPlotTypes = table.fill(PlotTypes.PLOT_LAND, iW * iH);

	-- Generate the inland sea.
	local iWestX = math.floor(iW * 0.18) - 1;
	local iEastX = math.ceil(iW * 0.82) - 1;
	local iWidth = iEastX - iWestX;
	local iSouthY = math.floor(iH * 0.28) - 1;
	local iNorthY = math.ceil(iH * 0.72) - 1;
	local iHeight = iNorthY - iSouthY;
	local fracFlags = {FRAC_POLAR = true};
	local grain = 1 + Map.Rand(2, "Inland Sea ocean grain - LUA");
	local seaFrac = Fractal.Create(iWidth, iHeight, grain, fracFlags, -1, -1)
	local seaThreshold = seaFrac:GetHeight(47);
	
	for region_y = 0, iHeight - 1 do
		for region_x = 0, iWidth - 1 do
			local val = seaFrac:GetHeight(region_x, region_y);
			if val >= seaThreshold then
				local x = region_x + iWestX;
				local y = region_y + iSouthY;
				local i = y * iW + x + 1; -- add one because Lua arrays start at 1
				self.wholeworldPlotTypes[i] = PlotTypes.PLOT_OCEAN;
			end
		end
	end

	-- Second, oval layer to ensure one main body of water.
	local centerX = (iW / 2) - 1;
	local centerY = (iH / 2) - 1;
	local xAxis = centerX / 2;
	local yAxis = centerY * 0.35;
	local xAxisSquared = xAxis * xAxis;
	local yAxisSquared = yAxis * yAxis;
	for x = 0, iW - 1 do
		for y = 0, iH - 1 do
			local i = y * iW + x + 1;
			local deltaX = x - centerX;
			local deltaY = y - centerY;
			local deltaXSquared = deltaX * deltaX;
			local deltaYSquared = deltaY * deltaY;
			local oval_value = deltaXSquared / xAxisSquared + deltaYSquared / yAxisSquared;
			if oval_value <= 1 then
				self.wholeworldPlotTypes[i] = PlotTypes.PLOT_OCEAN;
			end
		end
	end

	-- Land and water are set. Now apply hills and mountains.
	local world_age = Map.GetCustomOption(1)
	if world_age == 4 then
		world_age = 1 + Map.Rand(3, "Random World Age - Lua");
	end
	local args = {world_age = world_age};
	self:ApplyTectonics(args)

	-- Plot Type generation completed. Return global plot array.
	return self.wholeworldPlotTypes
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Setting Plot Types (Lua Inland Sea) ...");

	local layered_world = MultilayeredFractal.Create();
	local plotsIS = layered_world:GeneratePlotsByRegion();
	
	SetPlotTypes(plotsIS);

	GenerateCoasts();
end
----------------------------------------------------------------------------------
function TerrainGenerator:GetLatitudeAtPlot(iX, iY)
	local lat = math.abs((self.iHeight / 2) - iY) / (self.iHeight / 2);
	lat = lat + (128 - self.variation:GetHeight(iX, iY))/(255.0 * 5.0);
	lat = math.clamp(lat, 0, 1);

	-- For Inland Sea only, adjust latitude to cut out Tundra and most Jungle.
	local adjusted_lat = 0.07 + 0.52 * lat;
	
	return adjusted_lat;
end
------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua Inland Sea) ...");
	
	-- Get Temperature setting input by user.
	local temp = Map.GetCustomOption(2)
	if temp == 4 then
		temp = 1 + Map.Rand(3, "Random Temperature - Lua");
	end

	local args = {temperature = temp};
	local terraingen = TerrainGenerator.Create(args);

	terrainTypes = terraingen:GenerateTerrain();
	
	SetTerrainTypes(terrainTypes);
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function GetRiverValueAtPlot(plot)
	-- Custom method to force rivers to flow toward the map center.
	local iW, iH = Map.GetGridSize()
	local x = plot:GetX()
	local y = plot:GetY()
	local random_factor = Map.Rand(3, "River direction random factor - Inland Sea LUA");
	local direction_influence_value = (math.abs(x - (iW / 2)) + math.abs(y - (iH / 2))) * random_factor;

	local numPlots = PlotTypes.NUM_PLOT_TYPES;
	local sum = ((numPlots - plot:GetPlotType()) * 20) + direction_influence_value;

	local numDirections = DirectionTypes.NUM_DIRECTION_TYPES;
	for direction = 0, numDirections - 1, 1 do
		local adjacentPlot = Map.PlotDirection(plot:GetX(), plot:GetY(), direction);
		if (adjacentPlot ~= nil) then
			if adjacentPlot:IsCanyon() then
				sum = sum + 99999; -- Want rivers to avoid canyons at all times.
			else
				sum = sum + (numPlots - adjacentPlot:GetPlotType());
			end
		else
			sum = 0;
		end
	end
	sum = sum + Map.Rand(10, "River Rand");

	return sum;
end
------------------------------------------------------------------------------
function RiverGenerator:GenerateRivers(args)
	-- Customization for Inland Sea, to keep river starts away from map edges and set river "original flow direction".
	local iW, iH = Map.GetGridSize()
	print("Inland Sea - Adding Rivers");
	local passConditions = {
		function(plot)
			return plot:IsHills() or plot:IsMountain();
		end,
		
		function(plot)
			return (not plot:IsCoastalLand()) and (Map.Rand(8, "MapGenerator AddRivers") == 0);
		end,
	
		function(plot)
			local area = plot:Area();
			return (plot:IsHills() or plot:IsMountain()) and (area:GetNumRiverEdges() <	((area:GetNumTiles() / self.plots_per_river_edge) + 1));
		end,
		
		function(plot)
			local area = plot:Area();
			return (area:GetNumRiverEdges() < (area:GetNumTiles() / self.plots_per_river_edge) + 1);
		end
	}
	for iPass, passCondition in ipairs(passConditions) do
		local riverSourceRange;
		local seaWaterRange;
		if (iPass <= 2) then
			riverSourceRange = self.source_range;
			seaWaterRange = self.sea_range;
		else
			riverSourceRange = (self.source_range / 2);
			seaWaterRange = (self.sea_range / 2);
		end
		for i, plot in Plots() do
			local current_x = plot:GetX()
			local current_y = plot:GetY()
			if current_x < 1 or current_x >= iW - 2 or current_y < 2 or current_y >= iH - 1 then
				-- Plot too close to edge, ignore it.
			elseif(not plot:IsWater()) then
				if(passCondition(plot)) then
					if (not Map.FindWater(plot, riverSourceRange, true)) then
						if (not Map.FindWater(plot, seaWaterRange, false)) then
							local inlandCorner = plot:GetInlandCorner();
							if(inlandCorner) then
								local start_x = inlandCorner:GetX()
								local start_y = inlandCorner:GetY()
								local orig_direction;
								if start_y < iH / 2 then -- South half of map
									if start_x < iW / 3 then -- SW Corner
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_NORTHEAST;
									elseif start_x > iW * 0.66 then -- SE Corner
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_NORTHWEST;
									else -- South, middle
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_NORTH;
									end
								else -- North half of map
									if start_x < iW / 3 then -- NW corner
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST;
									elseif start_x > iW * 0.66 then -- NE corner
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST;
									else -- North, middle
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_SOUTH;
									end
								end
								self:DoRiver(inlandCorner, nil, orig_direction, nil);
							end
						end
					end
				end			
			end
		end
	end		
end
------------------------------------------------------------------------------
function RiverGenerator:GetCapsForMethodC()
	-- Set up caps for number of formations and plots based on world size.
	local worldsizes = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {2, 4, 2, 0},
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {3, 7, 2, 1},
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {5, 12, 2, 2},
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {6, 18, 2, 3},
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {7, 28, 3, 3},
		--[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {9, 42, 3, 4},
		};
	local caps_list = worldsizes[Map.GetWorldSize()];
	local max_lines, max_plots, base_length, extension_range = caps_list[1], caps_list[2], caps_list[3], caps_list[4];
	return max_lines, max_plots, base_length, extension_range;
end
------------------------------------------------------------------------------
function AddRivers()
	print("Generating Rivers, Canyons, and Lakes. (Lua Inland Sea) ...");

	local args = {};
	local rivergen = RiverGenerator.Create(args);
	
	rivergen:Generate();
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function FeatureGenerator:GetLatitudeAtPlot(iX, iY)
	local lat = math.abs((self.iGridH/2) - iY)/(self.iGridH/2);

	-- For Inland Sea only, adjust latitude to cut out Tundra and most Jungle.
	local adjusted_lat = 0.07 + 0.52 * lat;
	
	return adjusted_lat
end
------------------------------------------------------------------------------
function FeatureGenerator:AddIceAtPlot(plot, iX, iY, lat)
	return
end
------------------------------------------------------------------------------
function AddFeatures()
	print("Adding Features (Lua Inland Sea) ...");

	-- Get Rainfall setting input by user.
	local rain = Map.GetCustomOption(3)
	if rain == 4 then
		rain = 1 + Map.Rand(3, "Random Rainfall - Lua");
	end
	
	local args = {
		rainfall = rain,
		iClumpHeight = 66,
		iWildAreaHeight = 82,
	};
	local featuregen = FeatureGenerator.Create(args);

	-- False parameter removes mountains from coastlines.
	featuregen:AddFeatures(false);
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function AssignStartingPlots:GenerateGlobalResourcePlotLists()
	-- This function generates all global plot lists needed for resource distribution.
	local iW, iH = Map.GetGridSize();
	local temp_coast_next_to_land_list, temp_marsh_list, temp_flood_plains_list = {}, {}, {};
	local temp_hills_open_list, temp_hills_covered_list, temp_hills_jungle_list = {}, {}, {};
	local temp_hills_forest_list, temp_jungle_flat_list, temp_forest_flat_list = {}, {}, {};
	local temp_desert_flat_no_feature, temp_plains_flat_no_feature, temp_dry_grass_flat_no_feature = {}, {}, {};
	local temp_fresh_water_grass_flat_no_feature, temp_tundra_flat_including_forests, temp_forest_flat_that_are_not_tundra = {}, {}, {};
	--
	-- Lists for BE.
	local temp_next_to_canyon_list, temp_coastal_land_list, temp_next_to_mountain_list = {}, {}, {};
	local temp_river_list, temp_wild_area_list, temp_wild_area_flatlands_list, temp_next_to_wild_area_list = {}, {}, {}, {};
	local temp_wild_desert_list, temp_wild_tundra_list, temp_wild_ocean_list = {}, {}, {};
	local temp_large_xenomass_list, temp_large_floatstone_list, temp_large_firaxite_list = {}, {}, {};
	local temp_small_xenomass_list, temp_small_floatstone_list, temp_small_firaxite_list = {}, {}, {};
	local temp_loose_xenomass_list, temp_loose_floatstone_list, temp_loose_firaxite_list = {}, {}, {};
	--
	local iW, iH = Map.GetGridSize();
	local temp_hills_list, temp_coast_list, temp_grass_flat_no_feature = {}, {}, {};
	local temp_tundra_flat_no_feature, temp_snow_flat_list, temp_land_list = {}, {}, {};
	local temp_deer_list, temp_desert_wheat_list, temp_banana_list = {}, {}, {};
	--
	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local i = y * iW + x + 1; -- Lua tables/lists/arrays start at 1, not 0 like C++ or Python
			local plot = Map.GetPlot(x, y)
			-- Check if plot has a civ start, CS start, or Natural Wonder
			if self.playerCollisionData[i] == true then
				-- Do not process this plot!
			elseif plot:GetResourceType(-1) ~= -1 then
				-- Plot has a resource already, do not include it.
			else
				-- Process this plot for inclusion in the plot lists.
				local plotType = plot:GetPlotType()
				local terrainType = plot:GetTerrainType()
				local featureType = plot:GetFeatureType()
				if plotType == PlotTypes.PLOT_MOUNTAIN or plotType == PlotTypes.PLOT_CANYON then
					self.barren_plots = self.barren_plots + 1;
				elseif plotType == PlotTypes.PLOT_OCEAN then
					if featureType ~= self.feature_atoll then
						if featureType == FeatureTypes.FEATURE_ICE then
							self.barren_plots = self.barren_plots + 1;
						elseif plot:IsLake() then
							self.barren_plots = self.barren_plots + 1;
						else
							if is_ocean_wild then
								table.insert(temp_wild_ocean_list, i);
							end
							if terrainType == TerrainTypes.TERRAIN_COAST then
								table.insert(temp_coast_list, i);
								if plot:IsAdjacentToLand() then
									table.insert(temp_coast_next_to_land_list, i);
								end
							else
								self.barren_plots = self.barren_plots + 1;
							end
						end
					end
				else -- Plot is hills or flat land.
					-- Check Wildness for the Key (Affinity-enabling) resources.
					local iWildValue = plot:GetWildness()
					local is_any_wild, is_forest_wild, is_desert_wild, is_tundra_wild = true, false, false, false;
					if iWildValue == 11 then -- Periphery forest wild plot.
						table.insert(temp_small_xenomass_list, i);
						is_forest_wild = true;
						if plotType == PlotTypes.PLOT_HILLS then -- Custom for Inland Sea, which lacks tundra: set forest hills to host Firaxite.
							table.insert(temp_small_firaxite_list, i);
						end
					elseif iWildValue == 21 then -- Periphery desert wild plot.
						table.insert(temp_small_floatstone_list, i);
						is_desert_wild = true;
					elseif iWildValue == 31 then -- Periphery tundra wild plot.
						table.insert(temp_small_firaxite_list, i);
						is_tundra_wild = true;
					elseif iWildValue == 10 then -- Core forest wild plot.
						table.insert(temp_large_xenomass_list, i);
						is_forest_wild = true;
						if plotType == PlotTypes.PLOT_HILLS then -- Custom for Inland Sea, which lacks tundra: set forest hills to host Firaxite.
							table.insert(temp_large_firaxite_list, i);
						end
					elseif iWildValue == 20 then -- Core desert wild plot.
						table.insert(temp_large_floatstone_list, i);
						is_desert_wild = true;
					elseif iWildValue == 30 then -- Core tundra wild plot.
						table.insert(temp_large_firaxite_list, i);
						is_tundra_wild = true;
					else
						is_any_wild = false;
					end
					-- On with the plot evaluation.
					if plot:IsCoastalLand() and terrainType ~= TerrainTypes.TERRAIN_SNOW then
						table.insert(temp_coastal_land_list, i);
					elseif plot:IsRiver() then
						if plotType == PlotTypes.PLOT_LAND then
							table.insert(temp_river_list, i);
							if is_any_wild == false then
								table.insert(temp_loose_xenomass_list, i);
							end
						end
					end
					-- Check all adjacent plots for canyons, mountains, and wild area.
					local plot_adjustments_table = self.firstRingYIsEven;
					local isEvenY = true;
					if y / 2 > math.floor(y / 2) then
						plot_adjustments_table = self.firstRingYIsOdd;
					end
					for attempt = 1, 6 do
						local plot_adjustments = plot_adjustments_table[attempt];
						local searchX, searchY = self:ApplyHexAdjustment(x, y, plot_adjustments)
						local search_plot = Map.GetPlot(searchX, searchY);
						if search_plot ~= nil then
							if search_plot:IsCanyon() then
								table.insert(temp_next_to_canyon_list, i);
								if is_any_wild == false then
									table.insert(temp_loose_floatstone_list, i);
								end
							elseif search_plot:IsMountain() then
								table.insert(temp_next_to_mountain_list, i);
								if is_any_wild == false then
									table.insert(temp_loose_floatstone_list, i);
								end
							elseif is_any_wild == false then
								local search_plot_wild_value = search_plot:GetWildness()
								if search_plot_wild_value >= 10 and search_plot_wild_value < 40 then
									table.insert(temp_next_to_wild_area_list, i);
								end
							end
						end
					end
				
					if plotType == PlotTypes.PLOT_HILLS then
						if terrainType == TerrainTypes.TERRAIN_SNOW then
							if is_tundra_wild then
								table.insert(temp_wild_tundra_list, i);
							end
						else
							table.insert(temp_hills_list, i);
							if featureType == FeatureTypes.NO_FEATURE then
								table.insert(temp_hills_open_list, i);
								if is_desert_wild then
									table.insert(temp_wild_desert_list, i);
								elseif is_tundra_wild then
									table.insert(temp_wild_tundra_list, i);
								elseif is_forest_wild == false then
									table.insert(temp_loose_firaxite_list, i);
								end
							elseif featureType == FeatureTypes.FEATURE_FOREST then
								if is_forest_wild then
									table.insert(temp_wild_area_list, i);
								elseif is_tundra_wild then
									table.insert(temp_wild_tundra_list, i);
								end
								table.insert(temp_hills_forest_list, i);
								table.insert(temp_hills_covered_list, i);
								if terrainType == TerrainTypes.TERRAIN_TUNDRA then
									table.insert(temp_deer_list, i);
								end
							end
						end
					elseif featureType == FeatureTypes.FEATURE_MARSH then
						table.insert(temp_marsh_list, i);
						if is_any_wild == false then
							table.insert(temp_loose_xenomass_list, i);
						end
					elseif featureType == FeatureTypes.FEATURE_FLOOD_PLAINS then
						table.insert(temp_flood_plains_list, i);
						table.insert(temp_desert_wheat_list, i);
						if is_desert_wild then
							table.insert(temp_wild_desert_list, i);
						end
					elseif plotType == PlotTypes.PLOT_LAND then
						table.insert(temp_land_list, i);
						if featureType == FeatureTypes.FEATURE_FOREST then
							if is_forest_wild then
								table.insert(temp_wild_area_list, i);
								table.insert(temp_wild_area_flatlands_list, i);
							end
							table.insert(temp_forest_flat_list, i);
							if terrainType == TerrainTypes.TERRAIN_TUNDRA then
								if is_tundra_wild then
									table.insert(temp_wild_tundra_list, i);
								end
								table.insert(temp_deer_list, i);
								table.insert(temp_tundra_flat_including_forests, i);
							else
								table.insert(temp_forest_flat_that_are_not_tundra, i);
								if is_any_wild == false then
									table.insert(temp_loose_xenomass_list, i);
								end
							end
						elseif featureType == FeatureTypes.NO_FEATURE then
							if terrainType == TerrainTypes.TERRAIN_SNOW then
								if is_tundra_wild then
									table.insert(temp_wild_tundra_list, i);
								else
									table.insert(temp_loose_floatstone_list, i);
								end
								table.insert(temp_snow_flat_list, i);
							elseif terrainType == TerrainTypes.TERRAIN_TUNDRA then
								if is_tundra_wild then
									table.insert(temp_wild_tundra_list, i);
								end
								table.insert(temp_tundra_flat_no_feature, i);
								table.insert(temp_tundra_flat_including_forests, i);
							elseif terrainType == TerrainTypes.TERRAIN_DESERT then
								if is_desert_wild then
									table.insert(temp_wild_desert_list, i);
								else
									table.insert(temp_loose_firaxite_list, i);
								end
								table.insert(temp_desert_flat_no_feature, i);
								if plot:IsFreshWater() then
									table.insert(temp_desert_wheat_list, i);
								end
							elseif terrainType == TerrainTypes.TERRAIN_PLAINS then
								table.insert(temp_plains_flat_no_feature, i);
								--if plot:IsFreshWater() == false then
								--end
							elseif terrainType == TerrainTypes.TERRAIN_GRASS then
								table.insert(temp_grass_flat_no_feature, i);
								if plot:IsFreshWater() then
									table.insert(temp_fresh_water_grass_flat_no_feature, i);
								else
									table.insert(temp_dry_grass_flat_no_feature, i);
								end
							else
								self.barren_plots = self.barren_plots + 1;
								table.remove(temp_land_list);
							end
						else
							self.barren_plots = self.barren_plots + 1;
							table.remove(temp_land_list);
						end
					else
						self.barren_plots = self.barren_plots + 1;
					end
				end
			end
		end
	end
	
	--print("Finished scanning plots for global plot lists."); print("-");
	
	-- Scramble and record the lists.
	self.coast_next_to_land_list = GetShuffledCopyOfTable(temp_coast_next_to_land_list)
	self.marsh_list = GetShuffledCopyOfTable(temp_marsh_list)
	self.flood_plains_list = GetShuffledCopyOfTable(temp_flood_plains_list)
	self.hills_open_list = GetShuffledCopyOfTable(temp_hills_open_list)
	self.hills_covered_list = GetShuffledCopyOfTable(temp_hills_covered_list)
	self.hills_jungle_list = GetShuffledCopyOfTable(temp_hills_jungle_list)
	self.hills_forest_list = GetShuffledCopyOfTable(temp_hills_forest_list)
	self.jungle_flat_list = GetShuffledCopyOfTable(temp_jungle_flat_list)
	self.forest_flat_list = GetShuffledCopyOfTable(temp_forest_flat_list)
	self.desert_flat_no_feature = GetShuffledCopyOfTable(temp_desert_flat_no_feature)
	self.plains_flat_no_feature = GetShuffledCopyOfTable(temp_plains_flat_no_feature)
	self.dry_grass_flat_no_feature = GetShuffledCopyOfTable(temp_dry_grass_flat_no_feature)
	self.fresh_water_grass_flat_no_feature = GetShuffledCopyOfTable(temp_fresh_water_grass_flat_no_feature)
	self.tundra_flat_including_forests = GetShuffledCopyOfTable(temp_tundra_flat_including_forests)
	self.forest_flat_that_are_not_tundra = GetShuffledCopyOfTable(temp_forest_flat_that_are_not_tundra)
	--
	self.grass_flat_no_feature = GetShuffledCopyOfTable(temp_grass_flat_no_feature)
	self.tundra_flat_no_feature = GetShuffledCopyOfTable(temp_tundra_flat_no_feature)
	self.snow_flat_list = GetShuffledCopyOfTable(temp_snow_flat_list)
	self.hills_list = GetShuffledCopyOfTable(temp_hills_list)
	self.land_list = GetShuffledCopyOfTable(temp_land_list)
	self.coast_list = GetShuffledCopyOfTable(temp_coast_list)
	self.extra_deer_list = GetShuffledCopyOfTable(temp_deer_list)
	self.desert_wheat_list = GetShuffledCopyOfTable(temp_desert_wheat_list)
	self.banana_list = GetShuffledCopyOfTable(temp_banana_list)
	--
	self.next_to_canyon_list = GetShuffledCopyOfTable(temp_next_to_canyon_list)
	self.coastal_land_list = GetShuffledCopyOfTable(temp_coastal_land_list)
	self.next_to_mountain_list = GetShuffledCopyOfTable(temp_next_to_mountain_list)
	self.river_list = GetShuffledCopyOfTable(temp_river_list)
	self.wild_area_list = GetShuffledCopyOfTable(temp_wild_area_list)
	self.wild_area_flatlands_list = GetShuffledCopyOfTable(temp_wild_area_flatlands_list)
	self.next_to_wild_area_list = GetShuffledCopyOfTable(temp_next_to_wild_area_list)
	self.wild_desert_list = GetShuffledCopyOfTable(temp_wild_desert_list)
	self.wild_tundra_list = GetShuffledCopyOfTable(temp_wild_tundra_list)
	self.wild_ocean_list = GetShuffledCopyOfTable(temp_wild_ocean_list)
	self.large_xenomass_list = GetShuffledCopyOfTable(temp_large_xenomass_list)
	self.large_firaxite_list = GetShuffledCopyOfTable(temp_large_firaxite_list)
	self.large_floatstone_list = GetShuffledCopyOfTable(temp_large_floatstone_list)
	self.small_xenomass_list = GetShuffledCopyOfTable(temp_small_xenomass_list)
	self.small_firaxite_list = GetShuffledCopyOfTable(temp_small_firaxite_list)
	self.small_floatstone_list = GetShuffledCopyOfTable(temp_small_floatstone_list)
	self.loose_xenomass_list = GetShuffledCopyOfTable(temp_loose_xenomass_list)
	self.loose_firaxite_list = GetShuffledCopyOfTable(temp_loose_firaxite_list)
	self.loose_floatstone_list = GetShuffledCopyOfTable(temp_loose_floatstone_list)
	--[[
	local iNumXeno = table.maxn(self.large_xenomass_list);
	local iNumFirax = table.maxn(self.large_firaxite_list);
	local iNumFloat = table.maxn(self.large_floatstone_list);
	local iNumSmallXeno = table.maxn(self.small_xenomass_list);
	local iNumSmallFirax = table.maxn(self.small_firaxite_list);
	local iNumSmallFloat = table.maxn(self.small_floatstone_list);
	local iNumLooseXeno = table.maxn(self.loose_xenomass_list);
	local iNumLooseFirax = table.maxn(self.loose_firaxite_list);
	local iNumLooseFloat = table.maxn(self.loose_floatstone_list);
	print("-"); print("************************"); print("*");
	print("* Number of candidate plots for large deposits of Xenomass: ", iNumXeno);
	print("* Number of candidate plots for large deposits of Firaxite: ", iNumFirax);
	print("* Number of candidate plots for large deposits of Float Stone: ", iNumFloat); print("*");
	print("* Number of candidate plots for small deposits of Xenomass: ", iNumSmallXeno);
	print("* Number of candidate plots for small deposits of Firaxite: ", iNumSmallFirax);
	print("* Number of candidate plots for small deposits of Float Stone: ", iNumSmallFloat); print("*");
	print("* Number of candidate plots for Xenomass outside wild areas: ", iNumLooseXeno);
	print("* Number of candidate plots for Firaxite outside wild areas: ", iNumLooseFirax);
	print("* Number of candidate plots for Float Stone outside wild areas: ", iNumLooseFloat);
	print("*"); print("************************"); print("-");
	]]--
	-- Set up the Global Luxury Plot Lists matrix, with indices synched to GetIndicesForLuxuryType()
	self.global_luxury_plot_lists = {
	self.coast_next_to_land_list,				-- 1
	self.marsh_list,							-- 2
	self.flood_plains_list,						-- 3
	self.hills_open_list,						-- 4
	self.hills_covered_list,					-- 5
	self.hills_jungle_list,						-- 6
	self.hills_forest_list,						-- 7
	self.jungle_flat_list,						-- 8
	self.forest_flat_list,						-- 9
	self.desert_flat_no_feature,				-- 10
	self.plains_flat_no_feature,				-- 11
	self.dry_grass_flat_no_feature,				-- 12
	self.fresh_water_grass_flat_no_feature,		-- 13
	self.tundra_flat_including_forests,			-- 14
	self.forest_flat_that_are_not_tundra,		-- 15
	};

end
------------------------------------------------------------------------------
function StartPlotSystem()
	-- Get Resources setting input by user.
	local res = Map.GetCustomOption(4)
	if res == 6 then
		res = 1 + Map.Rand(3, "Random Resources Option - Lua");
	end

	print("Creating start plot database (MapGenerator.Lua)");
	local start_plot_database = AssignStartingPlots.Create()
	
	print("Dividing the map in to Regions (Lua Inland Sea)");
	-- Regional Division Method 1: Biggest Landmass
	local args = {
		method = 1,
		resources = res,
		};
	start_plot_database:GenerateRegions(args)

	print("Choosing start locations for civilizations (MapGenerator.Lua)");
	start_plot_database:ChooseLocations()
	
	print("Normalizing start locations and assigning them to Players (MapGenerator.Lua)");
	start_plot_database:BalanceAndAssign()

	print("Placing Resources and City States (MapGenerator.Lua)");
	start_plot_database:PlaceResourcesAndCityStates()
end
------------------------------------------------------------------------------
