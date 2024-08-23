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
			return (not (plot:IsCoastalLand() or plot:IsCanyon())) and (Map.Rand(8, "MapGenerator AddRivers") == 0);
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
								self:DoRiver(inlandCorner, FlowDirectionTypes.NO_FLOWDIRECTION, orig_direction, nil);
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

function StartPlotSystem()
	-- Get Resources setting input by user.
	local res = Map.GetCustomOption(4)
	if res == 6 then
		res = 1 + Map.Rand(3, "Random Resources Option - Lua");
	end

	print("Creating start plot database (MapGenerator.Lua)");
	local start_plot_database = AssignStartingPlots.Create()
	
	print("Dividing the map in to Regions (Lua Inland Sea)");
	-- Regional Division Method 5: All Start
	local args = {
		method = 5,
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
