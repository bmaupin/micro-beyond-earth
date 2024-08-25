------------------------------------------------------------------------------
--	FILE:	 Vulcan.lua
--	AUTHOR:  Bob Thomas
--	PURPOSE: Global map script - An oceanless planet.
------------------------------------------------------------------------------
--	Copyright (c) 2014 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------

include("MapGenerator");
include("MultilayeredFractal");
include("FeatureGenerator");
include("TerrainGenerator");
include("RiverGenerator");

------------------------------------------------------------------------------
function GetMapScriptInfo()
	local world_age, temperature, rainfall, sea_level, resources = GetCoreMapOptions()
	return {
		Name = "TXT_KEY_MAP_VULCAN_NAME",
		Type = "TXT_KEY_MAP_VULCAN_TYPE",
		Description = "TXT_KEY_MAP_VULCAN_HELP",
		IsAdvancedMap = false,
		SupportsMultiplayer = true,
		IconIndex = 13,
		CustomOptions = {world_age, temperature, rainfall, resources,
			{
				Name = "TXT_KEY_MAP_OPTION_BODIES_OF_WATER",
				Values = {
					{"TXT_KEY_MAP_OPTION_SMALL_LAKES"},
					{"TXT_KEY_MAP_OPTION_LARGE_LAKES"},
					{"TXT_KEY_MAP_OPTION_SEAS"},
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 4,
				SortPriority = 1,
			},
		},
	}
end
------------------------------------------------------------------------------

-------------------------------------------------------------------------------
function GetMapInitData(worldSize)
	-- This function can reset map grid sizes or world wrap settings.
	--
	-- Vulcan is a world without oceans, so use grid sizes two levels below normal.
	-- Expanding the grid sizes slightly vs Civ5 Lakes map, to make room for Canyons and Wild Areas.
	local worldsizes = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {12, 8},
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {16, 10},
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {20, 12},
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {24, 16},
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {32, 20},
		--[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {90, 56}
		}
	local grid_size = worldsizes[worldSize];
	--
	local world = GameInfo.Worlds[worldSize];
	if(world ~= nil) then
	return {
		Width = grid_size[1],
		Height = grid_size[2],
		WrapX = true,
	};      
     end
end
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
function MultilayeredFractal:GeneratePlotsByRegion()
	-- Sirian's MultilayeredFractal controlling function.
	-- You -MUST- customize this function for each script using MultilayeredFractal.
	--
	-- This implementation is specific to Vulcan.
	local iW, iH = Map.GetGridSize();
	local fracFlags = {FRAC_WRAP_X = true, FRAC_POLAR = true};
	self.wholeworldPlotTypes = table.fill(PlotTypes.PLOT_LAND, iW * iH);

	-- Get user inputs.
	local world_age = Map.GetCustomOption(1)
	if world_age == 4 then
		world_age = 1 + Map.Rand(3, "Random World Age - Lua");
	end
	local userInputLakes = Map.GetCustomOption(5)
	if userInputLakes == 4 then -- Random
		userInputLakes = 1 + Map.Rand(3, "Vulcan Random Lake Size - Lua");
	end

	-- Lake density
	local lake_list = {92, 89, 85};
	local lake_grains = {5, 4, 3};
	local lakes = lake_list[userInputLakes];
	local lake_grain = lake_grains[userInputLakes];

	local lakesFrac = Fractal.Create(iW, iH, lake_grain, fracFlags, -1, -1);
	local iLakesThreshold = lakesFrac:GetHeight(lakes);

	for y = 0, iH - 1 do
		for x = 0, iW - 1 do
			local i = y * iW + x + 1; -- add one because Lua arrays start at 1
			local lakeVal = lakesFrac:GetHeight(x, y);
			if lakeVal >= iLakesThreshold then
				self.wholeworldPlotTypes[i] = PlotTypes.PLOT_OCEAN;
			end
		end
	end


	-- Land and water are set. Now apply hills and mountains.
	local args = {
		adjust_plates = 1.2,
		world_age = world_age,
	};
	self:ApplyTectonics(args)

	-- Plot Type generation completed. Return global plot array.
	return self.wholeworldPlotTypes
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Setting Plot Types (Lua Vulcan) ...");

	local layered_world = MultilayeredFractal.Create();
	local plotsLakes = layered_world:GeneratePlotsByRegion();
	
	SetPlotTypes(plotsLakes);

	GenerateCoasts();
end
-------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua Vulcan) ...");
	
	-- Get Temperature setting input by user.
	local temp = Map.GetCustomOption(2)
	if temp == 4 then
		temp = 1 + Map.Rand(3, "Random Temperature - Lua");
	end

	local args = {temperature = temp, fSnowLatitude = 0.85};
	local terraingen = TerrainGenerator.Create(args);

	terrainTypes = terraingen:GenerateTerrain();
	
	SetTerrainTypes(terrainTypes);
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function RiverGenerator:GetCapsForMethodC()
	-- Set up caps for number of formations and plots based on world size.
	local worldsizes = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {5, 16, 5, 2},
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {6, 24, 6, 2},
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {7, 32, 7, 3},
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {8, 45, 8, 3},
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {9, 64, 9, 4},
		--[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {11, 90, 10, 5},
		};
	local caps_list = worldsizes[Map.GetWorldSize()];
	local max_lines, max_plots, base_length, extension_range = caps_list[1], caps_list[2], caps_list[3], caps_list[4];
	return max_lines, max_plots, base_length, extension_range;
end
----------------------------------------------------------------------------------
function RiverGenerator:MethodA()
	print("Map Generation - Adding canyons via Method A.");
	local iW, iH = Map.GetGridSize();
	local iFlags = Map.GetFractalFlags();
	local grain = 2;
	
	-- Generating canyons in large fractal rings, by taking a slice out of the lower middle heights.	
	local canyons = Fractal.Create(iW, iH, grain, iFlags, -1, -1);
	local canyon_bottom		= canyons:GetHeight(40);
	local canyon_top		= canyons:GetHeight(50);
	
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
							if canyonVal >= canyon_bottom and canyonVal <= canyon_top then
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
----------------------------------------------------------------------------------
function AddRivers()
	print("Generating Rivers, Canyons, and Lakes. (Lua Vulcan) ...");

	local args = {};
	local rivergen = RiverGenerator.Create(args);
	
	rivergen:Generate();
end
------------------------------------------------------------------------------
function AddFeatures()
	print("Adding Features (Lua Vulcan) ...");

	-- Get Rainfall setting input by user.
	local rain = Map.GetCustomOption(3)
	if rain == 4 then
		rain = 1 + Map.Rand(3, "Random Rainfall - Lua");
	end
	
	local args = {rainfall = rain, iClumpHeight = 70, iClumpChange = 10}
	local featuregen = FeatureGenerator.Create(args);

	-- False parameter removes mountains from coastlines.
	featuregen:AddFeatures(false);
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function AssignStartingPlots:PlaceOilInTheSea()
	-- Oil only on land for this map script.
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function StartPlotSystem()
	-- Get Resources setting input by user.
	local res = Map.GetCustomOption(5)
	if res == 6 then
		res = 1 + Map.Rand(3, "Random Resources Option - Lua");
	end

	print("Creating start plot database.");
	local start_plot_database = AssignStartingPlots.Create()
	
	print("Dividing the map in to Regions.");
	-- Regional Division Method 1: Biggest Landmass
	local args = {
		method = 1,
		resources = res,
		};
	start_plot_database:GenerateRegions(args)

	print("Choosing start locations for civilizations.");
	start_plot_database:ChooseLocations()
	
	print("Normalizing start locations and assigning them to Players.");
	start_plot_database:BalanceAndAssign()

	print("Placing Resources and City States.");
	start_plot_database:PlaceResourcesAndCityStates()
end
------------------------------------------------------------------------------
