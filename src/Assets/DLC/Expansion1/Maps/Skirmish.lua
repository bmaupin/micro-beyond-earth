------------------------------------------------------------------------------
--	FILE:	 Skirmish.lua
--	AUTHOR:  Bob Thomas
--	PURPOSE: Optimized for 1v1 or two-teams multiplayer.
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
	return {
		Name = "TXT_KEY_MAP_SKIRMISH",
		Type = "TXT_KEY_MAP_SKIRMISH",
		Description = "TXT_KEY_MAP_SKIRMISH_HELP",
		IconAtlas = "WORLDTYPE_ATLAS",
		IconIndex = 19,
		SupportsSinglePlayer = false,
		SupportsMultiplayer = false,
		CustomOptions = {
			{
				Name = "TXT_KEY_MAP_OPTION_DOMINANT_TERRAIN",
				Values = {
					{"TXT_KEY_MAP_SCRIPT_SKIRMISH_GRASSLANDS", "TXT_KEY_MAP_SCRIPT_SKIRMISH_GRASSLANDS_HELP"},
					{"TXT_KEY_MAP_SCRIPT_SKIRMISH_PLAINS", "TXT_KEY_MAP_SCRIPT_SKIRMISH_PLAINS_HELP"},
					{"TXT_KEY_MAP_SCRIPT_SKIRMISH_FOREST", "TXT_KEY_MAP_SCRIPT_SKIRMISH_FOREST_HELP"},
					{"TXT_KEY_MAP_SCRIPT_SKIRMISH_MARSH", "TXT_KEY_MAP_SCRIPT_SKIRMISH_MARSH_HELP"},
					{"TXT_KEY_MAP_SCRIPT_SKIRMISH_DESERT", "TXT_KEY_MAP_SCRIPT_SKIRMISH_DESERT_HELP"},
					{"TXT_KEY_MAP_SCRIPT_SKIRMISH_TUNDRA", "TXT_KEY_MAP_SCRIPT_SKIRMISH_TUNDRA_HELP"},
					{"TXT_KEY_MAP_SCRIPT_SKIRMISH_HILLS", "TXT_KEY_MAP_SCRIPT_SKIRMISH_HILLS_HELP"},
					{"TXT_KEY_MAP_OPTION_GLOBAL_CLIMATE", "TXT_KEY_MAP_OPTION_GLOBAL_CLIMATE_HELP"},
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 9,
				SortPriority = 1,
			},
			{
				Name = "TXT_KEY_MAP_OPTION_WATER_SETTING",
				Values = {
					{"TXT_KEY_MAP_OPTION_RIVERS", "TXT_KEY_MAP_OPTION_RIVERS_HELP"},
					{"TXT_KEY_MAP_OPTION_SMALL_LAKES", "TXT_KEY_MAP_OPTION_SMALL_LAKES_HELP"},
					{"TXT_KEY_MAP_OPTION_SEAS", "TXT_KEY_MAP_OPTION_SEAS_HELP"},
					{"TXT_KEY_MAP_OPTION_RIVERS_AND_SEAS", "TXT_KEY_MAP_OPTION_RIVERS_AND_SEAS_HELP"},
					{"TXT_KEY_MAP_OPTION_DRY", "TXT_KEY_MAP_OPTION_DRY_HELP"},
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 1,
				SortPriority = 2,
			},
			{
				Name = "TXT_KEY_MAP_OPTION_RESOURCES",
				Values = { -- Only one option here, but this will let all users know that resources are not set at default.
					"TXT_KEY_MAP_OPTION_BALANCED_RESOURCES",
				},
				DefaultValue = 1,
				SortPriority = 3,
			},
		},
	}
end
------------------------------------------------------------------------------

-------------------------------------------------------------------------------
function GetMapInitData(worldSize)
	-- This function can reset map grid sizes or world wrap settings.
	--
	-- Skirmish is a world without oceans, so use grid sizes two levels below normal.
	local worldsizes = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {12, 8},
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {16, 10},
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {20, 12},
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {24, 16},
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {32, 20},
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
	-- This implementation is specific to Skirmish.
	local iW, iH = Map.GetGridSize();
	local fracFlags = {FRAC_WRAP_X = true, FRAC_POLAR = true};
	self.wholeworldPlotTypes = table.fill(PlotTypes.PLOT_LAND, iW * iH);
	
	-- Get user inputs.
	dominant_terrain = Map.GetCustomOption(1) -- GLOBAL variable.
	if dominant_terrain == 9 then -- Random
		dominant_terrain = 1 + Map.Rand(8, "Random Type of Dominant Terrain - Skirmish LUA");
	end
	userInputWaterSetting = Map.GetCustomOption(2) -- GLOBAL variable.
	if userInputWaterSetting == 6 then -- Random
		userInputWaterSetting = 1 + Map.Rand(5, "Random Water Setting - Skirmish LUA");
	end

	-- Lake density: applies only to Small Lakes and Seas settings.
	if userInputWaterSetting >= 2 and userInputWaterSetting <= 4 then
		local lake_list = {0, 93, 85, 85};
		local lake_grains = {0, 5, 3, 3};
		local lakes = lake_list[userInputWaterSetting];
		local lake_grain = lake_grains[userInputWaterSetting];

		local lakesFrac = Fractal.Create(iW, iH, lake_grain, fracFlags, -1, -1);
		local iLakesThreshold = lakesFrac:GetHeight(lakes);

		for y = 1, iH - 2 do
			for x = 0, iW - 1 do
				local i = y * iW + x + 1; -- add one because Lua arrays start at 1
				local lakeVal = lakesFrac:GetHeight(x, y);
				if lakeVal >= iLakesThreshold then
					self.wholeworldPlotTypes[i] = PlotTypes.PLOT_OCEAN;
				end
			end
		end
	end

	-- Apply hills and mountains.
	if dominant_terrain == 7 then -- Hills dominate.
		local worldsizes = {
			[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = 4,
			[GameInfo.Worlds.WORLDSIZE_TINY.ID] = 4,
			[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = 5,
			[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = 5,
			[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = 5,
			--[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = 5,
			}
		local grain = worldsizes[Map.GetWorldSize()];

		local terrainFrac = Fractal.Create(iW, iH, grain, fracFlags, -1, -1);
		local iHillsThreshold = terrainFrac:GetHeight(70);
		local iPeaksThreshold = terrainFrac:GetHeight(95);
		local iHillsClumps = terrainFrac:GetHeight(10);

		local hillsFrac = Fractal.Create(iW, iH, grain, fracFlags, -1, -1);
		local iHillsBottom1 = hillsFrac:GetHeight(20);
		local iHillsTop1 = hillsFrac:GetHeight(30);
		local iHillsBottom2 = hillsFrac:GetHeight(70);
		local iHillsTop2 = hillsFrac:GetHeight(80);

		for x = 0, iW - 1 do
			for y = 0, iH - 1 do
				local i = y * iW + x + 1;
				local val = terrainFrac:GetHeight(x, y);
				if val >= iPeaksThreshold then
					self.wholeworldPlotTypes[i] = PlotTypes.PLOT_MOUNTAIN;
				elseif val >= iHillsThreshold or val <= iHillsClumps then
					self.wholeworldPlotTypes[i] = PlotTypes.PLOT_HILLS;
				else
					local hillsVal = hillsFrac:GetHeight(x, y);
					if hillsVal >= iHillsBottom1 and hillsVal <= iHillsTop1 then
						self.wholeworldPlotTypes[i] = PlotTypes.PLOT_HILLS;
					elseif hillsVal >= iHillsBottom2 and hillsVal <= iHillsTop2 then
						self.wholeworldPlotTypes[i] = PlotTypes.PLOT_HILLS;
					end
				end
			end
		end

	else -- Normal hills and mountains.
		local args = {
			adjust_plates = 1.2,
		};
		self:ApplyTectonics(args)
	end
	
	-- Create buffer zone in middle four columns. This will create some choke points.
	--
	-- Turn all plots in buffer zone to land.
	for x = iW / 2 - 2, iW / 2 + 1 do
		for y = 1, iH - 2 do
			local i = y * iW + x + 1;
			self.wholeworldPlotTypes[i] = PlotTypes.PLOT_LAND;
		end
	end
	-- Add mountains in top and bottom rows of buffer zone.
	for x = iW / 2 - 2, iW / 2 + 1 do
		local i = x + 1;
		self.wholeworldPlotTypes[i] = PlotTypes.PLOT_MOUNTAIN;
		local i = (iH - 1) * iW + x + 1;
		self.wholeworldPlotTypes[i] = PlotTypes.PLOT_MOUNTAIN;
	end
	-- Add random smattering of mountains to middle two columns of buffer zone.
	local west_half, east_half = {}, {};
	for loop = 1, iH - 2 do
		table.insert(west_half, loop);
		table.insert(east_half, loop);
	end
	local west_shuffled = GetShuffledCopyOfTable(west_half)
	local east_shuffled = GetShuffledCopyOfTable(east_half)
	local iNumMountainsPerColumn = math.max(math.floor(iH * 0.225), math.floor((iH / 4) - 1));
	local x_west, x_east = iW / 2 - 1, iW / 2;
	for loop = 1, iNumMountainsPerColumn do
		local y_west, y_east = west_shuffled[loop], east_shuffled[loop];
		local i_west_plot = y_west * iW + x_west + 1;
		local i_east_plot = y_east * iW + x_east + 1;
		self.wholeworldPlotTypes[i_west_plot] = PlotTypes.PLOT_MOUNTAIN;
		self.wholeworldPlotTypes[i_east_plot] = PlotTypes.PLOT_MOUNTAIN;
	end
	-- Hills need to be added near mountains, but this needs to wait until after plot types have been initially set.

	-- Plot Type generation completed. Return global plot array.
	return self.wholeworldPlotTypes
end
------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Setting Plot Types (Lua Skirmish) ...");

	local layered_world = MultilayeredFractal.Create();
	local plotsSkirmish = layered_world:GeneratePlotsByRegion();
	
	SetPlotTypes(plotsSkirmish);

	-- Examine all plots in buffer zone.
	local iW, iH = Map.GetGridSize();
	local firstRingYIsEven = {{0, 1}, {1, 0}, {0, -1}, {-1, -1}, {-1, 0}, {-1, 1}};
	local firstRingYIsOdd = {{1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, 0}, {0, 1}};
	for x = iW / 2 - 2, iW / 2 + 1 do
		for y = 1, iH - 2 do
			local plot = Map.GetPlot(x, y)
			if plot:IsFlatlands() then -- Check for adjacent Mountain plot; if found, change this plot to Hills.
				local isEvenY, search_table = true, {};
				if y / 2 > math.floor(y / 2) then
					isEvenY = false;
				end
				if isEvenY then
					search_table = firstRingYIsEven;
				else
					search_table = firstRingYIsOdd;
				end

				for loop, plot_adjustments in ipairs(search_table) do
					local searchX, searchY;
					searchX = x + plot_adjustments[1];
					searchY = y + plot_adjustments[2];
					local searchPlot = Map.GetPlot(searchX, searchY)
					local plotType = searchPlot:GetPlotType()
					if plotType == PlotTypes.PLOT_MOUNTAIN then
						local diceroll = Map.Rand(5, "Random Canyon in Middle - Lua"); -- 20% chance turn this hill into canyon.
						if diceroll < 1 then
							plot:SetPlotType(PlotTypes.PLOT_CANYON, false, false)
						else
							plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false)
						end
						break
					end
				end
			end
		end
	end

	GenerateCoasts();
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function TerrainGenerator:GenerateTerrainAtPlot(iX,iY)
	local lat = self:GetLatitudeAtPlot(iX,iY);
	local terrainVal = self.terrainGrass;

	local plot = Map.GetPlot(iX, iY);
	if (plot:IsWater()) then
		local val = plot:GetTerrainType();
		if val == TerrainTypes.NO_TERRAIN then -- Error handling.
			val = self.terrainGrass;
			plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
		end
		return val;	 
	end
	
	-- Begin implementation of User Input for dominant terrain type (Skirmish.lua)
	if dominant_terrain == 2 then -- Plains
		-- Mostly Plains, but a smattering of grass or desert.
		local desertVal = self.deserts:GetHeight(iX, iY);
		local plainsVal = self.plains:GetHeight(iX, iY);
		if desertVal >= self.deserts:GetHeight(85) then
			terrainVal = self.terrainDesert;
			-- Set Desert Wild Area value.
			if not (plot:IsMountain() or plot:IsCanyon()) then
				if desertVal >= self.deserts:GetHeight(91) then
					plot:SetWildness(20);
				elseif desertVal >= self.deserts:GetHeight(85) then
					plot:SetWildness(21);
				end
			end
		elseif plainsVal <= self.plains:GetHeight(85) then
			terrainVal = self.terrainPlains;
		end
	elseif dominant_terrain == 4 then -- Marsh
		-- Set Desert Wild Area value, even though there are no deserts.
		local desertVal = self.deserts:GetHeight(iX, iY);
		if not (plot:IsMountain() or plot:IsCanyon()) then
			if desertVal >= self.deserts:GetHeight(91) then
				plot:SetWildness(20);
			elseif desertVal >= self.deserts:GetHeight(85) then
				plot:SetWildness(21);
			end
		end
		-- All grass all the time!
	elseif dominant_terrain == 5 then -- Desert
		local desertVal = self.deserts:GetHeight(iX, iY);
		local plainsVal = self.plains:GetHeight(iX, iY);
		if desertVal >= self.deserts:GetHeight(25) then
			terrainVal = self.terrainDesert;
			-- Set Desert Wild Area value.
			if not (plot:IsMountain() or plot:IsCanyon()) then
				if desertVal >= self.deserts:GetHeight(88) then
					plot:SetWildness(20);
				elseif desertVal >= self.deserts:GetHeight(80) then
					plot:SetWildness(21);
				end
			end
		elseif plainsVal >= self.plains:GetHeight(40) then
			terrainVal = self.terrainPlains;
		end
	elseif dominant_terrain == 6 then -- Tundra
		local desertVal = self.deserts:GetHeight(iX, iY);
		local plainsVal = self.plains:GetHeight(iX, iY);
		if plainsVal >= self.plains:GetHeight(85) then
			terrainVal = self.terrainPlains;
		elseif desertVal >= self.deserts:GetHeight(88) then
			terrainVal = self.terrainSnow;
			-- Set Desert Wild Area value -- using snow for this.
			if not (plot:IsMountain() or plot:IsCanyon()) then
				if desertVal >= self.deserts:GetHeight(93) then
					plot:SetWildness(20);
				elseif desertVal >= self.deserts:GetHeight(88) then
					plot:SetWildness(21);
				end
			end
		else
			terrainVal = self.terrainTundra;
		end
	elseif dominant_terrain == 8 then -- Global (aka normal climate bands)
		if(lat >= self.fSnowLatitude) then
			terrainVal = self.terrainSnow;
		elseif(lat >= self.fTundraLatitude) then
			terrainVal = self.terrainTundra;
		elseif (lat < self.fGrassLatitude) then
			terrainVal = self.terrainGrass;
		else
			local desertVal = self.deserts:GetHeight(iX, iY);
			local plainsVal = self.plains:GetHeight(iX, iY);
			if ((desertVal >= self.iDesertBottom) and (desertVal <= self.iDesertTop) and (lat >= self.fDesertBottomLatitude) and (lat < self.fDesertTopLatitude)) then
				terrainVal = self.terrainDesert;
				-- Set Desert Wild Area value.
				if not (plot:IsMountain() or plot:IsCanyon()) then
					if desertVal >= self.deserts:GetHeight(91) then
						plot:SetWildness(20);
					elseif desertVal >= self.deserts:GetHeight(85) then
						plot:SetWildness(21);
					end
				end
			elseif ((plainsVal >= self.iPlainsBottom) and (plainsVal <= self.iPlainsTop)) then
				terrainVal = self.terrainPlains;
			end
		end
	else -- Grassland / Forest / Hills
		local plainsVal = self.plains:GetHeight(iX, iY);
		if plainsVal >= self.plains:GetHeight(85) then
			terrainVal = self.terrainPlains;
		end
		-- Set Desert Wild Area value, even though there are no deserts.
		local desertVal = self.deserts:GetHeight(iX, iY);
		if not (plot:IsMountain() or plot:IsCanyon()) then
			if desertVal >= self.deserts:GetHeight(91) then
				plot:SetWildness(20);
			elseif desertVal >= self.deserts:GetHeight(85) then
				plot:SetWildness(21);
			end
		end
	end
	
	return terrainVal;
end
------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua Skirmish) ...");
	
	local terraingen = TerrainGenerator.Create();

	local terrainTypes = terraingen:GenerateTerrain();
	
	SetTerrainTypes(terrainTypes);
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function RiverGenerator:GetRiverValueAtPlot(plot)
	-- Custom method to force rivers to flow away from the map center.
	local iW, iH = Map.GetGridSize()
	local x = plot:GetX()
	local y = plot:GetY()
	local random_factor = Map.Rand(3, "River direction random factor - Skirmish LUA");
	local direction_influence_value = (math.abs(iW - (x - (iW / 2))) + ((math.abs(y - (iH / 2))) / 3)) * random_factor;

	local numPlots = PlotTypes.NUM_PLOT_TYPES;
	local sum = ((numPlots - plot:GetPlotType()) * 20) + direction_influence_value;

	local numDirections = DirectionTypes.NUM_DIRECTION_TYPES;
	for direction = 0, numDirections - 1 do
		local adjacentPlot = Map.PlotDirection(plot:GetX(), plot:GetY(), direction);
		if (adjacentPlot ~= nil) then
			sum = sum + (numPlots - adjacentPlot:GetPlotType());
		else
			sum = sum + (numPlots * 10);
		end
	end
	sum = sum + Map.Rand(10, "River Rand");

	return sum;
end
------------------------------------------------------------------------------
function RiverGenerator:GenerateRivers(args)
	-- Only add rivers if Water Setting is value of 1 or 4. Otherwise no rivers.
	if userInputWaterSetting == 2 or userInputWaterSetting == 3 or userInputWaterSetting == 5 then -- No Rivers!
		return
	end

	-- Customization for Skirmish, to keep river starts away from buffer zone in middle columns of map, and set river "original flow direction".
	local iW, iH = Map.GetGridSize()
	print("Skirmish - Adding Rivers");
	local passConditions = {
		function(plot)
			return plot:IsHills() or plot:IsMountain();
		end,
		
		function(plot)
			return (not plot:IsCoastalLand()) and (Map.Rand(8, "MapGenerator AddRivers") == 0);
		end,
		
		function(plot)
			local area = plot:Area();
			local plotsPerRiverEdge = GameDefines["PLOTS_PER_RIVER_EDGE"];
			return (plot:IsHills() or plot:IsMountain()) and (area:GetNumRiverEdges() <	((area:GetNumTiles() / plotsPerRiverEdge) + 1));
		end,
		
		function(plot)
			local area = plot:Area();
			local plotsPerRiverEdge = GameDefines["PLOTS_PER_RIVER_EDGE"];
			return (area:GetNumRiverEdges() < (area:GetNumTiles() / plotsPerRiverEdge) + 1);
		end
	}
	for iPass, passCondition in ipairs(passConditions) do
		local riverSourceRange;
		local seaWaterRange;
		if (iPass <= 2) then
			riverSourceRange = GameDefines["RIVER_SOURCE_MIN_RIVER_RANGE"];
			seaWaterRange = GameDefines["RIVER_SOURCE_MIN_SEAWATER_RANGE"];
		else
			riverSourceRange = (GameDefines["RIVER_SOURCE_MIN_RIVER_RANGE"] / 2);
			seaWaterRange = (GameDefines["RIVER_SOURCE_MIN_SEAWATER_RANGE"] / 2);
		end
		for i, plot in Plots() do
			local current_x = plot:GetX()
			local current_y = plot:GetY()
			if current_x < 1 or current_x >= iW - 2 or current_y < 2 or current_y >= iH - 1 then
				-- Plot too close to edge, ignore it.
			elseif current_x >= (iW / 2) - 2 and current_x <= (iW / 2) + 1 then
				-- Plot in buffer zone, ignore it.
			elseif (not plot:IsWater()) then
				if(passCondition(plot)) then
					if (not Map.FindWater(plot, riverSourceRange, true)) then
						if (not Map.FindWater(plot, seaWaterRange, false)) then
							local inlandCorner = plot:GetInlandCorner();
							if(inlandCorner) then
								local start_x = inlandCorner:GetX()
								local start_y = inlandCorner:GetY()
								local orig_direction;
								if start_y < iH / 2 then -- South half of map
									if start_x < iW / 2 then -- West half of map
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_NORTHWEST;
									else -- East half
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_NORTHEAST;
									end
								else -- North half of map
									if start_x < iW / 2 then -- West half of map
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST;
									else -- NE corner
										orig_direction = FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST;
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
function RiverGenerator:GenerateLakes(args)
	-- No lakes added in this manner.
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
----------------------------------------------------------------------------------
function RiverGenerator:MethodA()
	--print("Map Generation - Adding canyons via Method A.");
	local iW, iH = Map.GetGridSize();
	local iFlags = Map.GetFractalFlags();
	local grain = 3;
	
	-- Generating canyons in large fractal rings, by taking a slice out of the lower middle heights.	
	local canyons = Fractal.Create(iW, iH, grain, iFlags, -1, -1);
	local canyon_bottom_1		= canyons:GetHeight(24);
	local canyon_top_1			= canyons:GetHeight(27);
	local canyon_bottom_2		= canyons:GetHeight(35);
	local canyon_top_2			= canyons:GetHeight(36);
	
	-- Generate canyons.
	for y = 1, iH - 2 do
		for x = 0, iW - 1 do
			local plot = Map.GetPlot(x, y);
			-- Canyon plot must not be water.
			if not plot:IsWater() then
				-- Canyon plot must not be coastal land.
				if not plot:IsCoastalLand() then
					-- Canyon plot must not be river.
					if not plot:IsRiver() then
						-- Preserve existing mountains or canyons.
						if not (plot:IsMountain() or plot:IsCanyon()) then
							-- Check to see if this plot is a member of one of the fractal canyon rings.
							local canyonVal = canyons:GetHeight(x, y);
							if (canyonVal >= canyon_bottom_1 and canyonVal <= canyon_top_1) or (canyonVal >= canyon_bottom_2 and canyonVal <= canyon_top_2) then
								-- Plot has met all conditions. Place canyon here.
								plot:SetPlotType(PlotTypes.PLOT_CANYON, false, false);
								self.num_type_a_canyons_placed = self.num_type_a_canyons_placed + 1;
							end
						end
					end
				end
			end
		end
	end
	
	print("- -"); print("- Number of Type A canyons placed: ", self.num_type_a_canyons_placed); print("- -");
	
	Map.RecalculateAreas()
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
function FeatureGenerator:__initFractals()
	local width = self.iGridW;
	local height = self.iGridH;
	self.terrainSnow	= GameInfoTypes["TERRAIN_SNOW"];
	self.terrainTundra	= GameInfoTypes["TERRAIN_TUNDRA"];
	
	-- Create fractals
	self.jungles		= Fractal.Create(width, height, self.jungle_grain, self.fractalFlags, self.fracXExp, self.fracYExp);
	self.forests		= Fractal.Create(width, height, self.forest_grain, self.fractalFlags, self.fracXExp, self.fracYExp);
	self.forestclumps	= Fractal.Create(width, height, self.clump_grain, self.fractalFlags, self.fracXExp, self.fracYExp);
	self.marsh			= Fractal.Create(width, height, 4, self.fractalFlags, self.fracXExp, self.fracYExp);
	self.repurpose		= Fractal.Create(width, height, 5, self.fractalFlags, self.fracXExp, self.fracYExp);
	self.miasma			= Fractal.Create(width, height, 7, self.fractalFlags, self.fracXExp, self.fracYExp);
	
	-- Get heights
	self.iJungleBottom	= self.jungles:GetHeight((100 - self.iJunglePercent)/2)
	self.iJungleTop		= self.jungles:GetHeight((100 + self.iJunglePercent)/2)
	self.iJungleRange	= (self.iJungleTop - self.iJungleBottom) * self.iJungleFactor;
	self.iForestLevel	= self.forests:GetHeight(80) -- 20% forest coverage
	self.iClumpLevel	= self.forestclumps:GetHeight(94) -- 6% forest clumps
	self.iMarshLevel	= self.marsh:GetHeight(100 - self.fMarshPercent)
	self.iBottom		= self.repurpose:GetHeight(25)
	self.iTop			= self.repurpose:GetHeight(50)
	
	self.iWildAreaLevel = self.forestclumps:GetHeight(self.iWildAreaHeight)
	self.iMiasmaBase	= self.miasma:GetHeight(100 - self.iMiasmaBasePercent)
	
	if dominant_terrain == 3 then -- Forest
		self.iClumpLevel	= self.forestclumps:GetHeight(65) -- 35% forest clumps
		self.iForestLevel	= self.forests:GetHeight(55) -- 45% forest coverage of what isn't covered by clumps.
	elseif dominant_terrain == 6 then -- Tundra
		self.iClumpLevel	= self.forestclumps:GetHeight(80) -- 20% forest clumps
		self.iForestLevel	= self.forests:GetHeight(60) -- 40% forest coverage of what isn't covered by clumps.
	elseif dominant_terrain == 8 then -- Global
		self.iClumpLevel	= self.forestclumps:GetHeight(90) -- 10% forest clumps
		self.iForestLevel	= self.forests:GetHeight(69) -- 31% forest coverage of what isn't covered by clumps.
	end
end
------------------------------------------------------------------------------
function FeatureGenerator:AddIceAtPlot(plot, iX, iY, lat)
	if dominant_terrain == 8 then -- Global
		if (plot:CanHaveFeature(self.featureIce)) then
			if Map.IsWrapX() and (iY == 0 or iY == self.iGridH - 1) then
				plot:SetFeatureType(self.featureIce, -1)
			else
				local rand = Map.Rand(100, "Add Ice Lua")/100.0;
				if(rand < 8 * (lat - 0.875)) then
					plot:SetFeatureType(self.featureIce, -1);
				elseif(rand < 4 * (lat - 0.75)) then
					plot:SetFeatureType(self.featureIce, -1);
				end
			end
		end
	end
end
------------------------------------------------------------------------------
function FeatureGenerator:AddJunglesAtPlot(plot, iX, iY, lat)
	if dominant_terrain == 4 then -- Marsh
		if plot:IsFlatlands() then
			local jungle_height = self.jungles:GetHeight(iX, iY);
			if jungle_height <= self.jungles:GetHeight(70) and jungle_height >= self.jungles:GetHeight(20) then
				plot:SetFeatureType(self.featureMarsh, -1);
			end
		end
	elseif dominant_terrain == 8 then -- Global, use default.
		local jungle_height = self.jungles:GetHeight(iX, iY);
		if jungle_height <= self.iJungleTop and jungle_height >= self.iJungleBottom + (self.iJungleRange * lat) then
			if(plot:CanHaveFeature(self.featureJungle)) then
				local repurpose_height = self.repurpose:GetHeight(iX, iY);
				if repurpose_height > self.iTop then
					local plotType = plot:GetPlotType()
					if plotType ~= PlotTypes.PLOT_HILLS then
						plot:SetFeatureType(self.featureMarsh, -1);
					end
				elseif repurpose_height < self.iBottom then
					plot:SetFeatureType(self.featureForest, -1);
				else -- Leave this plot clear.
				end
			end
		end
	end
end
------------------------------------------------------------------------------
function FeatureGenerator:DetermineWildness(plot, iX, iY, lat)
	-- Determine Wildness value for forest, tundra and ocean.
	-- Forest Clump fractal is used for these three types of Wild Areas. (Desert Wilds are determined using the Desert fractal in TerrainGenerator).
	local iWildVal = self.forestclumps:GetHeight(iX, iY)
	if not (plot:IsWater() or plot:IsMountain() or plot:IsCanyon()) then -- Land plot.
		local terrain_value = plot:GetTerrainType()

		if dominant_terrain == 6 then -- Tundra: Xenomass will be placed in Tundra wilds.
			if terrain_value == self.terrainTundra then -- Check for Tundra Wildness.
				if iWildVal >= self.forestclumps:GetHeight(85) then -- Tundra Wild Area, Core plot.
					plot:SetWildness(30)
					self.iNumCoreTundraWilds = self.iNumCoreTundraWilds + 1;
				elseif iWildVal >= self.forestclumps:GetHeight(75) then -- Tundra Wild Area, Periphery plot.
					plot:SetWildness(31)
					self.iNumPeripheryTundraWilds = self.iNumPeripheryTundraWilds + 1;
				end
			end
		elseif dominant_terrain == 8 then -- Global
			if terrain_value == self.terrainTundra then -- Check for Tundra Wildness.
				if iWildVal >= self.iTundraCoreLevel then -- Tundra Wild Area, Core plot.
					plot:SetWildness(30)
					self.iNumCoreTundraWilds = self.iNumCoreTundraWilds + 1;
				elseif iWildVal >= self.iTundraPeripheryLevel then -- Tundra Wild Area, Periphery plot.
					plot:SetWildness(31)
					self.iNumPeripheryTundraWilds = self.iNumPeripheryTundraWilds + 1;
				end
			else
				-- Handle Forest Wildness.
				if iWildVal >= self.forestclumps:GetHeight(90) then -- Forest Wild Area, Core plot.
					plot:SetWildness(10) -- Forest wild area, Core plot.
					self.iNumCoreForestWilds = self.iNumCoreForestWilds + 1;
				elseif iWildVal >= self.forestclumps:GetHeight(83) then -- Forest Wild Area, Periphery plot.
					plot:SetWildness(11) -- Forest wild area, Periphery plot.
					self.iNumPeripheryForestWilds = self.iNumPeripheryForestWilds + 1;
				end
			end
		else -- No tundra present on the map! Firaxite will be placed in Forest wilds.
			-- Handle Forest Wildness.
			if iWildVal >= self.forestclumps:GetHeight(85) then -- Forest Wild Area, Core plot.
				plot:SetWildness(10) -- Forest wild area, Core plot.
				self.iNumCoreForestWilds = self.iNumCoreForestWilds + 1;
			elseif iWildVal >= self.forestclumps:GetHeight(75) then -- Forest Wild Area, Periphery plot.
				plot:SetWildness(11) -- Forest wild area, Periphery plot.
				self.iNumPeripheryForestWilds = self.iNumPeripheryForestWilds + 1;
			end
		end
	end
end
------------------------------------------------------------------------------
function AddFeatures()
	print("Adding Features (Lua Skirmish) ...");

	local featuregen = FeatureGenerator.Create();

	featuregen:AddFeatures();
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function AssignStartingPlots:GenerateRegions(args)
	print("Map Generation - Dividing the map in to Regions");
	-- This version is tailored for handling two-teams play.
	local args = args or {};
	local iW, iH = Map.GetGridSize();
	self.method = 3; -- Flag the map as using a Rectangular division method.

	-- Automatically set strategic resources to place a source of iron, horse and oil at every start location.
	self.resource_setting = 5;
	
	-- Determine number of civilizations and city states present in this game.
	self.iNumCivs, self.iNumCityStates, self.player_ID_list, self.bTeamGame, self.teams_with_major_civs, self.number_civs_per_team = GetPlayerAndTeamInfo()
	self.iNumCityStatesUnassigned = self.iNumCityStates;
	print("-"); print("Civs:", self.iNumCivs); --print("City States:", self.iNumCityStates);

	-- Determine number of teams (of Major Civs only, not City States) present in this game.
	iNumTeams = table.maxn(self.teams_with_major_civs);				-- GLOBAL
	print("-"); print("Teams:", iNumTeams);

	-- If two teams are present, use team-oriented handling of start points, one team west, one east.
	if iNumTeams == 2 then
		print("-"); print("Number of Teams present is two! Using custom team start placement for Skirmish."); print("-");
		
		-- ToDo: Correctly identify team IDs and how many Civs are on each team.
		-- Also need to shuffle the teams so its random who starts on which half.
		local shuffled_team_list = GetShuffledCopyOfTable(self.teams_with_major_civs)
		teamWestID = shuffled_team_list[1];							-- GLOBAL
		teamEastID = shuffled_team_list[2]; 						-- GLOBAL
		iNumCivsInWest = self.number_civs_per_team[teamWestID];		-- GLOBAL
		iNumCivsInEast = self.number_civs_per_team[teamEastID];		-- GLOBAL

		-- Process the team in the west.
		self.inhabited_WestX = 0;
		self.inhabited_SouthY = 0;
		self.inhabited_Width = math.floor(iW / 2) - 1;
		self.inhabited_Height = iH;
		-- Obtain "Start Placement Fertility" inside the rectangle.
		-- Data returned is: fertility table, sum of all fertility, plot count.
		local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
		                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
		-- Assemble the Rectangle data table:
		local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
		                    self.inhabited_Height, -1, fertCount, plotCount}; -- AreaID -1 means ignore area IDs.
		-- Divide the rectangle.
		self:DivideIntoRegions(iNumCivsInWest, fert_table, rect_table)

		-- Process the team in the east.
		self.inhabited_WestX = math.floor(iW / 2) + 1;
		self.inhabited_SouthY = 0;
		self.inhabited_Width = math.floor(iW / 2) - 1;
		self.inhabited_Height = iH;
		-- Obtain "Start Placement Fertility" inside the rectangle.
		-- Data returned is: fertility table, sum of all fertility, plot count.
		local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityInRectangle(self.inhabited_WestX, 
		                                         self.inhabited_SouthY, self.inhabited_Width, self.inhabited_Height)
		-- Assemble the Rectangle data table:
		local rect_table = {self.inhabited_WestX, self.inhabited_SouthY, self.inhabited_Width, 
		                    self.inhabited_Height, -1, fertCount, plotCount}; -- AreaID -1 means ignore area IDs.
		-- Divide the rectangle.
		self:DivideIntoRegions(iNumCivsInEast, fert_table, rect_table)
		-- The regions have been defined.

	-- If number of teams is any number other than two, use standard division.
	else	
		print("-"); print("Number of team is not two, so dividing the map at random."); print("-");
		self.method = 2;	
		local best_areas = {};
		local globalFertilityOfLands = {};

		-- Obtain info on all landmasses for comparision purposes.
		local iGlobalFertilityOfLands = 0;
		local iNumLandPlots = 0;
		local iNumLandAreas = 0;
		local land_area_IDs = {};
		local land_area_plots = {};
		local land_area_fert = {};
		-- Cycle through all plots in the world, checking their Start Placement Fertility and AreaID.
		for x = 0, iW - 1 do
			for y = 0, iH - 1 do
				local i = y * iW + x + 1;
				local plot = Map.GetPlot(x, y);
				if not plot:IsWater() then -- Land plot, process it.
					iNumLandPlots = iNumLandPlots + 1;
					local iArea = plot:GetArea();
					local plotFertility = self:MeasureStartPlacementFertilityOfPlot(x, y, true); -- Check for coastal land is enabled.
					iGlobalFertilityOfLands = iGlobalFertilityOfLands + plotFertility;
					--
					if TestMembership(land_area_IDs, iArea) == false then -- This plot is the first detected in its AreaID.
						iNumLandAreas = iNumLandAreas + 1;
						table.insert(land_area_IDs, iArea);
						land_area_plots[iArea] = 1;
						land_area_fert[iArea] = plotFertility;
					else -- This AreaID already known.
						land_area_plots[iArea] = land_area_plots[iArea] + 1;
						land_area_fert[iArea] = land_area_fert[iArea] + plotFertility;
					end
				end
			end
		end
		
		-- Sort areas, achieving a list of AreaIDs with best areas first.
		--
		-- Fertility data in land_area_fert is stored with areaID index keys.
		-- Need to generate a version of this table with indices of 1 to n, where n is number of land areas.
		local interim_table = {};
		for loop_index, data_entry in pairs(land_area_fert) do
			table.insert(interim_table, data_entry);
		end
		-- Sort the fertility values stored in the interim table. Sort order in Lua is lowest to highest.
		table.sort(interim_table);
		-- If less players than landmasses, we will ignore the extra landmasses.
		local iNumRelevantLandAreas = math.min(iNumLandAreas, self.iNumCivs);
		-- Now re-match the AreaID numbers with their corresponding fertility values
		-- by comparing the original fertility table with the sorted interim table.
		-- During this comparison, best_areas will be constructed from sorted AreaIDs, richest stored first.
		local best_areas = {};
		-- Currently, the best yields are at the end of the interim table. We need to step backward from there.
		local end_of_interim_table = table.maxn(interim_table);
		-- We may not need all entries in the table. Process only iNumRelevantLandAreas worth of table entries.
		for areaTestLoop = end_of_interim_table, (end_of_interim_table - iNumRelevantLandAreas + 1), -1 do
			for loop_index, AreaID in ipairs(land_area_IDs) do
				if interim_table[areaTestLoop] == land_area_fert[land_area_IDs[loop_index] ] then
					table.insert(best_areas, AreaID);
					table.remove(land_area_IDs, landLoop);
					break
				end
			end
		end

		-- Assign continents to receive start plots. Record number of civs assigned to each landmass.
		local inhabitedAreaIDs = {};
		local numberOfCivsPerArea = table.fill(0, iNumRelevantLandAreas); -- Indexed in synch with best_areas. Use same index to match values from each table.
		for civToAssign = 1, self.iNumCivs do
			local bestRemainingArea;
			local bestRemainingFertility = 0;
			local bestAreaTableIndex;
			-- Loop through areas, find the one with the best remaining fertility (civs added 
			-- to a landmass reduces its fertility rating for subsequent civs).
			for area_loop, AreaID in ipairs(best_areas) do
				local thisLandmassCurrentFertility = land_area_fert[AreaID] / (1 + numberOfCivsPerArea[area_loop]);
				if thisLandmassCurrentFertility > bestRemainingFertility then
					bestRemainingArea = AreaID;
					bestRemainingFertility = thisLandmassCurrentFertility;
					bestAreaTableIndex = area_loop;
				end
			end
			-- Record results for this pass. (A landmass has been assigned to receive one more start point than it previously had).
			numberOfCivsPerArea[bestAreaTableIndex] = numberOfCivsPerArea[bestAreaTableIndex] + 1;
			if TestMembership(inhabitedAreaIDs, bestRemainingArea) == false then
				table.insert(inhabitedAreaIDs, bestRemainingArea);
			end
		end
				
		-- Loop through the list of inhabited landmasses, dividing each landmass in to regions.
		-- Note that it is OK to divide a continent with one civ on it: this will assign the whole
		-- of the landmass to a single region, and is the easiest method of recording such a region.
		local iNumInhabitedLandmasses = table.maxn(inhabitedAreaIDs);
		for loop, currentLandmassID in ipairs(inhabitedAreaIDs) do
			-- Obtain the boundaries of and data for this landmass.
			local landmass_data = ObtainLandmassBoundaries(currentLandmassID);
			local iWestX = landmass_data[1];
			local iSouthY = landmass_data[2];
			local iEastX = landmass_data[3];
			local iNorthY = landmass_data[4];
			local iWidth = landmass_data[5];
			local iHeight = landmass_data[6];
			local wrapsX = landmass_data[7];
			local wrapsY = landmass_data[8];
			-- Obtain "Start Placement Fertility" of the current landmass. (Necessary to do this
			-- again because the fert_table can't be built prior to finding boundaries, and we had
			-- to ID the proper landmasses via fertility to be able to figure out their boundaries.
			local fert_table, fertCount, plotCount = self:MeasureStartPlacementFertilityOfLandmass(currentLandmassID, 
		  	                                         iWestX, iEastX, iSouthY, iNorthY, wrapsX, wrapsY);
			-- Assemble the rectangle data for this landmass.
			local rect_table = {iWestX, iSouthY, iWidth, iHeight, currentLandmassID, fertCount, plotCount};
			-- Divide this landmass in to number of regions equal to civs assigned here.
			iNumCivsOnThisLandmass = numberOfCivsPerArea[loop];
			if iNumCivsOnThisLandmass > 0 and iNumCivsOnThisLandmass <= 22 then -- valid number of civs.
				self:DivideIntoRegions(iNumCivsOnThisLandmass, fert_table, rect_table)
			else
				print("Invalid number of civs assigned to a landmass: ", iNumCivsOnThisLandmass);
			end
		end
	end
end
------------------------------------------------------------------------------
function AssignStartingPlots:BalanceAndAssign()
	-- This function determines what level of Bonus Resource support a location
	-- may need, identifies compatibility with civ-specific biases, and places starts.

	-- Normalize each start plot location.
	local iNumStarts = table.maxn(self.startingPlots);
	for region_number = 1, iNumStarts do
		self:NormalizeStartLocation(region_number)
	end

	-- Assign Civs to start plots.
	if iNumTeams == 2 then
		-- Two teams, place one in the west half, other in east -- even if team membership totals are uneven.
		print("-"); print("This is a team game with two teams! Place one team in West, other in East."); print("-");
		local playerList, westList, eastList = {}, {}, {};
		for loop = 1, self.iNumCivs do
			local player_ID = self.player_ID_list[loop];
			table.insert(playerList, player_ID);
			local player = Players[player_ID];
			local team_ID = player:GetTeam()
			if team_ID == teamWestID then
				print("Player #", player_ID, "belongs to Team #", team_ID, "and will be placed in the West.");
				table.insert(westList, player_ID);
			elseif team_ID == teamEastID then
				print("Player #", player_ID, "belongs to Team #", team_ID, "and will be placed in the East.");
				table.insert(eastList, player_ID);
			else
				print("* ERROR * - Player #", player_ID, "belongs to Team #", team_ID, "which is neither West nor East!");
			end
		end
		
		-- Debug
		if table.maxn(westList) ~= iNumCivsInWest then
			print("-"); print("*** ERROR! *** . . . Mismatch between number of Civs on West team and number of civs assigned to west locations.");
		end
		if table.maxn(eastList) ~= iNumCivsInEast then
			print("-"); print("*** ERROR! *** . . . Mismatch between number of Civs on East team and number of civs assigned to east locations.");
		end
		
		local westListShuffled = GetShuffledCopyOfTable(westList)
		local eastListShuffled = GetShuffledCopyOfTable(eastList)
		for region_number, player_ID in ipairs(westListShuffled) do
			local x = self.startingPlots[region_number][1];
			local y = self.startingPlots[region_number][2];
			local start_plot = Map.GetPlot(x, y)
			local player = Players[player_ID]
			player:SetStartingPlot(start_plot)
		end
		for loop, player_ID in ipairs(eastListShuffled) do
			local x = self.startingPlots[loop + iNumCivsInWest][1];
			local y = self.startingPlots[loop + iNumCivsInWest][2];
			local start_plot = Map.GetPlot(x, y)
			local player = Players[player_ID]
			player:SetStartingPlot(start_plot)
		end
	else
		print("-"); print("This game does not have specific start zone assignments."); print("-");
		local playerList = {};
		for loop = 1, self.iNumCivs do
			local player_ID = self.player_ID_list[loop];
			table.insert(playerList, player_ID);
		end
		local playerListShuffled = GetShuffledCopyOfTable(playerList)
		for region_number, player_ID in ipairs(playerListShuffled) do
			local x = self.startingPlots[region_number][1];
			local y = self.startingPlots[region_number][2];
			local start_plot = Map.GetPlot(x, y)
			local player = Players[player_ID]
			player:SetStartingPlot(start_plot)
		end
		-- If this is a team game (any team has more than one Civ in it) then make 
		-- sure team members start near each other if possible. (This may scramble 
		-- Civ biases in some cases, but there is no cure).
		if self.bTeamGame == true and team_setting ~= 2 then
			--print("However, this IS a team game, so we will try to group team members together."); print("-");
			self:NormalizeTeamLocations()
		end
	end
end
------------------------------------------------------------------------------
function AssignStartingPlots:PlaceKeyStrategics()
	-- This is a BE function to regulate the amounts of the "key" strategics that get placed.
	-- This regulation pertains to Float Stone, Xenomass and Firaxite.
	self:GetKeyStrategicsTargetValues()
	
	-- For Skirmish only, handle terrain cases. Note: All cases have Desert wild already handled.
	if dominant_terrain == 6 then -- Tundra map, no Forest Wild present. Place Xenomass in tundra wild.
		self.large_xenomass_list = self.large_firaxite_list;
		self.small_xenomass_list = self.small_firaxite_list;
	elseif dominant_terrain < 8 then -- No tundra present. Place Firaxite in forest wild.
		self.large_firaxite_list = self.large_xenomass_list;
		self.small_firaxite_list = self.small_xenomass_list;
	end
	
	-- Process large deposits inside wild areas.
	local rand1, rand2, rand3 = self.xenomass_max - self.xenomass_min + 1, self.firaxite_max - self.firaxite_min + 1, self.floatstone_max - self.floatstone_min + 1;
	local large_xenomass_target = Map.Rand(rand1, "Number of Large Xenomass deposits to place - Lua") + self.xenomass_min;
	local large_firaxite_target = Map.Rand(rand2, "Number of Large Firaxite deposits to place - Lua") + self.firaxite_min;
	local large_floatstone_target = Map.Rand(rand3, "Number of Large Float Stone deposits to place - Lua") + self.floatstone_min;
	
	local resources_to_place = {
	{self.xenomass_ID, self.xenomass_base, self.xenomass_range, 100, 2, 2}, };
	self:BeyondEarthProcessStrategicResourceList(3, self.large_xenomass_list, resources_to_place, true, large_xenomass_target)
	
	local resources_to_place = {
	{self.firaxite_ID, self.firaxite_base, self.firaxite_range, 100, 2, 2}, };
	self:BeyondEarthProcessStrategicResourceList(3, self.large_firaxite_list, resources_to_place, true, large_firaxite_target)
	
	local resources_to_place = {
	{self.floatstone_ID, self.floatstone_base, self.floatstone_range, 100, 2, 2}, };
	self:BeyondEarthProcessStrategicResourceList(3, self.large_floatstone_list, resources_to_place, true, large_floatstone_target)

	-- Process small deposits inside wild areas.
	local rand1, rand2, rand3 = self.xenomass_max - self.xenomass_min + 1, self.firaxite_max - self.firaxite_min + 1, self.floatstone_max - self.floatstone_min + 1;
	local small_xenomass_target = Map.Rand(rand1, "Number of Large Xenomass deposits to place - Lua") + self.xenomass_min;
	local small_firaxite_target = Map.Rand(rand2, "Number of Large Firaxite deposits to place - Lua") + self.firaxite_min;
	local small_floatstone_target = Map.Rand(rand3, "Number of Large Float Stone deposits to place - Lua") + self.floatstone_min;
	
	local resources_to_place = {
	{self.xenomass_ID, self.minor_xenomass_base, self.minor_xenomass_range, 100, 1, 2}, };
	self:BeyondEarthProcessStrategicResourceList(3, self.small_xenomass_list, resources_to_place, true, small_xenomass_target)
	
	local resources_to_place = {
	{self.firaxite_ID, self.minor_firaxite_base, self.minor_firaxite_range, 100, 1, 2}, };
	self:BeyondEarthProcessStrategicResourceList(3, self.small_firaxite_list, resources_to_place, true, small_firaxite_target)
	
	local resources_to_place = {
	{self.floatstone_ID, self.minor_floatstone_base, self.minor_floatstone_range, 100, 1, 2}, };
	self:BeyondEarthProcessStrategicResourceList(3, self.small_floatstone_list, resources_to_place, true, small_floatstone_target)
	
	-- Process small deposits outside wild areas.
	local rand1, rand2, rand3 = 2 * (self.xenomass_max - self.xenomass_min + 1), 2 * (self.firaxite_max - self.firaxite_min + 1), 2 * (self.floatstone_max - self.floatstone_min + 1);
	local loose_xenomass_target = Map.Rand(rand1, "Number of Large Xenomass deposits to place - Lua") + 2 * self.xenomass_min;
	local loose_firaxite_target = Map.Rand(rand2, "Number of Large Firaxite deposits to place - Lua") + 2 * self.firaxite_min;
	local loose_floatstone_target = Map.Rand(rand3, "Number of Large Float Stone deposits to place - Lua") + 2 * self.floatstone_min;
	
	local resources_to_place = {
	{self.xenomass_ID, self.minor_xenomass_base, self.minor_xenomass_range, 100, 2, 2}, };
	self:BeyondEarthProcessStrategicResourceList(3, self.loose_xenomass_list, resources_to_place, true, loose_xenomass_target)
	
	local resources_to_place = {
	{self.firaxite_ID, self.minor_firaxite_base, self.minor_firaxite_range, 100, 2, 2}, };
	self:BeyondEarthProcessStrategicResourceList(3, self.loose_firaxite_list, resources_to_place, true, loose_firaxite_target)
	
	local resources_to_place = {
	{self.floatstone_ID, self.minor_floatstone_base, self.minor_floatstone_range, 100, 2, 2}, };
	self:BeyondEarthProcessStrategicResourceList(3, self.loose_floatstone_list, resources_to_place, true, loose_floatstone_target)
	
end
------------------------------------------------------------------------------
function StartPlotSystem()
	-- Custom for Skirmish.
	print("Creating start plot database.");
	local start_plot_database = AssignStartingPlots.Create()
	
	print("Dividing the map in to Regions.");
	local args = {};
	start_plot_database:GenerateRegions()

	print("Choosing start locations for civilizations.");
	start_plot_database:ChooseLocations()
	
	print("Normalizing start locations and assigning them to Players.");
	start_plot_database:BalanceAndAssign()

	print("Placing Resources and City States.");
	start_plot_database:PlaceResourcesAndCityStates()
end
------------------------------------------------------------------------------
