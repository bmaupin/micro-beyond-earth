------------------------------------------------------------------------------
--	FILE:	 Tilted_Axis.lua
--	AUTHOR:  Bob Thomas
--	PURPOSE: Global map script - A very large world, tilted on its side with 
--           its south pole always locked in to facing the sun.
------------------------------------------------------------------------------
--	Copyright (c) 2014 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------

include("MapGenerator");
include("FractalWorld");
include("TerrainGenerator");
include("RiverGenerator");
include("FeatureGenerator");
include("MapmakerUtilities");

------------------------------------------------------------------------------
function GetMapScriptInfo()
	local world_age, temperature, rainfall, sea_level, resources = GetCoreMapOptions()
	local sea_level = {
		Name = "TXT_KEY_MAP_OPTION_SEA_LEVEL",
		Values = {
			{"TXT_KEY_MAP_OPTION_LOW"},
			{"TXT_KEY_MAP_OPTION_MEDIUM"},
			"TXT_KEY_MAP_OPTION_RANDOM",
		},
		DefaultValue = 1,
		SortPriority = -96,
	};
	return {
		Name = "TXT_KEY_MAP_TILTED_AXIS_NAME",
		Type = "TXT_KEY_MAP_TILTED_AXIS_TYPE",
		Description = "TXT_KEY_MAP_TILTED_AXIS_HELP",
		IsAdvancedMap = false,
		IconIndex = 10,
		CustomOptions = {world_age, rainfall, sea_level, resources,
			{
				Name = "TXT_KEY_MAP_OPTION_LANDMASS_TYPE",
				Values = {
					"TXT_KEY_MAP_OPTION_PANGAEA",
					"TXT_KEY_MAP_OPTION_LARGE_CONTINENTS",
					"TXT_KEY_MAP_OPTION_SMALL_CONTINENTS",
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 4,
				SortPriority = 1,
			},
		},
	}
end
------------------------------------------------------------------------------
function GetMapInitData(worldSize)
	-- This function can reset map grid sizes or world wrap settings.
	local worldsizes = {
		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {52, 32},
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {68, 44},
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {88, 56},
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {108, 68},
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {118, 74},
		--[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {128, 80}
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
------------------------------------------------------------------------------

------------------------------------------------------------------------------
PangaeaFractalWorld = {};
------------------------------------------------------------------------------
function PangaeaFractalWorld.Create(fracXExp, fracYExp)
	local gridWidth, gridHeight = Map.GetGridSize();
	
	local data = {
		InitFractal = FractalWorld.InitFractal,
		ShiftPlotTypes = FractalWorld.ShiftPlotTypes,
		ShiftPlotTypesBy = FractalWorld.ShiftPlotTypesBy,
		DetermineXShift = FractalWorld.DetermineXShift,
		DetermineYShift = FractalWorld.DetermineYShift,
		GenerateCenterRift = FractalWorld.GenerateCenterRift,
		GeneratePlotTypes = PangaeaFractalWorld.GeneratePlotTypes,	-- Custom method
		
		-- Four methods have been crafted to add canyons to the maps. Method D occurs with plot generation. Methods A, B and C come with rivers.
		-- Method A: Fault lines where plates are pulling apart. Opposite of mountain range creation. These large canyons may be segmented.
		-- Method B: Weak spots in the planet's crust. Crust collapses in a pocket area due to high magma activity in the mantle. Creates isolated canyons.
		-- Method C: Plate collision creates mountains, then (geologically) rapid plate separation also creates a parallel canyon.
		-- Method D: Plate separation creates a canyon at fault line, then later plate collision closes most of the canyon and also creates new mountains.
		PlotCanBeCanyon = FractalWorld.PlotCanBeCanyon,
		HexAdjustment = FractalWorld.HexAdjustment,
		GenerateCanyonPlotCandidateList = FractalWorld.GenerateCanyonPlotCandidateList,
		MethodD = FractalWorld.MethodD,
		
		iFlags = Map.GetFractalFlags(),
		
		fracXExp = fracXExp,
		fracYExp = fracYExp,
		
		iNumPlotsX = gridWidth,
		iNumPlotsY = gridHeight,
		plotTypes = table.fill(PlotTypes.PLOT_OCEAN, gridWidth * gridHeight),

		-- Canyon variables
		canyon_plot_candidate_list = {},
		mountain_count = 0,
		extra_mountains = 0,
		adjustment = 0,
		
	};
		
	return data;
end	
------------------------------------------------------------------------------
function PangaeaFractalWorld:GeneratePlotTypes(args)
	if(args == nil) then args = {}; end
	
	local sea_level_low = 59;
	local sea_level_normal = 63;
	local sea_level_high = 68;
	local world_age_old = 2;
	local world_age_normal = 3;
	local world_age_new = 5;
	--
	local extra_mountains = 0;
	local grain_amount = 3;
	local adjust_plates = 1.3;
	local shift_plot_types = true;
	local tectonic_islands = true;
	local hills_ridge_flags = self.iFlags;
	local peaks_ridge_flags = self.iFlags;
	local has_center_rift = false;
	
	local sea_level = Map.GetCustomOption(3)
	if sea_level == 3 then
		sea_level = 1 + Map.Rand(2, "Random Sea Level - Lua");
	end
	local world_age = Map.GetCustomOption(1)
	if world_age == 4 then
		world_age = 1 + Map.Rand(3, "Random World Age - Lua");
	end

	-- Set Sea Level according to user selection.
	local water_percent = sea_level_normal;
	if sea_level == 1 then -- Low Sea Level
		water_percent = sea_level_low;
	else -- Normal Sea Level
	end

	-- Set values for hills and mountains according to World Age chosen by user.
	local adjustment = world_age_normal;
	if world_age == 3 then -- 5 Billion Years
		adjustment = world_age_old;
		adjust_plates = adjust_plates * 0.75;
	elseif world_age == 1 then -- 3 Billion Years
		adjustment = world_age_new;
		adjust_plates = adjust_plates * 1.5;
	else -- 4 Billion Years
	end
	-- Apply adjustment to hills and peaks settings.
	local hillsBottom1 = 28 - adjustment;
	local hillsTop1 = 28 + adjustment;
	local hillsBottom2 = 72 - adjustment;
	local hillsTop2 = 72 + adjustment;
	local hillsClumps = 1 + adjustment;
	local hillsNearMountains = 91 - (adjustment * 2) - extra_mountains;
	local mountains = 97 - adjustment - extra_mountains;

	-- Hills and Mountains handled differently according to map size - Bob
	local WorldSizeTypes = {};
	for row in GameInfo.Worlds() do
		WorldSizeTypes[row.Type] = row.ID;
	end
	local sizekey = Map.GetWorldSize();
	-- Fractal Grains
	local sizevalues = {
		[WorldSizeTypes.WORLDSIZE_DUEL]     = 3,
		[WorldSizeTypes.WORLDSIZE_TINY]     = 3,
		[WorldSizeTypes.WORLDSIZE_SMALL]    = 4,
		[WorldSizeTypes.WORLDSIZE_STANDARD] = 4,
		[WorldSizeTypes.WORLDSIZE_LARGE]    = 5,
		--[WorldSizeTypes.WORLDSIZE_HUGE]		= 5
	};
	local grain = sizevalues[sizekey] or 3;
	-- Tectonics Plate Counts
	local platevalues = {
		[WorldSizeTypes.WORLDSIZE_DUEL]		= 6,
		[WorldSizeTypes.WORLDSIZE_TINY]     = 9,
		[WorldSizeTypes.WORLDSIZE_SMALL]    = 12,
		[WorldSizeTypes.WORLDSIZE_STANDARD] = 18,
		[WorldSizeTypes.WORLDSIZE_LARGE]    = 24,
		--[WorldSizeTypes.WORLDSIZE_HUGE]     = 30
	};
	local numPlates = platevalues[sizekey] or 5;
	-- Add in any plate count modifications passed in from the map script. - Bob
	numPlates = numPlates * adjust_plates;

	-- Generate continental fractal layer and examine the largest landmass. Reject
	-- the result until the largest landmass occupies 84% or more of the total land.
	local done = false;
	local iAttempts = 0;
	local iWaterThreshold, biggest_area, iNumTotalLandTiles, iNumBiggestAreaTiles, iBiggestID;
	while done == false do
		local grain_dice = Map.Rand(7, "Continental Grain roll - LUA Pangaea");
		if grain_dice < 4 then
			grain_dice = 1;
		else
			grain_dice = 2;
		end
		local rift_dice = Map.Rand(3, "Rift Grain roll - LUA Pangaea");
		if rift_dice < 1 then
			rift_dice = -1;
		end
		
		self.continentsFrac = nil;
		self:InitFractal{continent_grain = grain_dice, rift_grain = rift_dice};
		iWaterThreshold = self.continentsFrac:GetHeight(water_percent);
		
		iNumTotalLandTiles = 0;
		for x = 0, self.iNumPlotsX - 1 do
			for y = 0, self.iNumPlotsY - 1 do
				local i = y * self.iNumPlotsX + x;
				local val = self.continentsFrac:GetHeight(x, y);
				if(val <= iWaterThreshold) then
					self.plotTypes[i] = PlotTypes.PLOT_OCEAN;
				else
					self.plotTypes[i] = PlotTypes.PLOT_LAND;
					iNumTotalLandTiles = iNumTotalLandTiles + 1;
				end
			end
		end

		SetPlotTypes(self.plotTypes);
		Map.RecalculateAreas();
		
		biggest_area = Map.FindBiggestArea(false);
		iNumBiggestAreaTiles = biggest_area:GetNumTiles();
		-- Now test the biggest landmass to see if it is large enough.
		if iNumBiggestAreaTiles >= iNumTotalLandTiles * 0.84 then
			done = true;
			iBiggestID = biggest_area:GetID();
		end
		iAttempts = iAttempts + 1;
		
		--[[ Printout for debug use only
		print("-"); print("--- Pangaea landmass generation, Attempt#", iAttempts, "---");
		print("- This attempt successful: ", done);
		print("- Total Land Plots in world:", iNumTotalLandTiles);
		print("- Land Plots belonging to biggest landmass:", iNumBiggestAreaTiles);
		print("- Percentage of land belonging to Pangaea: ", 100 * iNumBiggestAreaTiles / iNumTotalLandTiles);
		print("- Continent Grain for this attempt: ", grain_dice);
		print("- Rift Grain for this attempt: ", rift_dice);
		print("- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -");
		print(".");
		]]--
	end
	
	-- Generate fractals to govern hills and mountains
	self.hillsFrac = Fractal.Create(self.iNumPlotsX, self.iNumPlotsY, grain, self.iFlags, self.fracXExp, self.fracYExp);
	self.mountainsFrac = Fractal.Create(self.iNumPlotsX, self.iNumPlotsY, grain, self.iFlags, self.fracXExp, self.fracYExp);
	self.hillsFrac:BuildRidges(numPlates, hills_ridge_flags, 1, 2);
	self.mountainsFrac:BuildRidges((numPlates * 2) / 3, peaks_ridge_flags, 6, 1);
	-- Get height values
	local iHillsBottom1 = self.hillsFrac:GetHeight(hillsBottom1);
	local iHillsTop1 = self.hillsFrac:GetHeight(hillsTop1);
	local iHillsBottom2 = self.hillsFrac:GetHeight(hillsBottom2);
	local iHillsTop2 = self.hillsFrac:GetHeight(hillsTop2);
	local iHillsClumps = self.mountainsFrac:GetHeight(hillsClumps);
	local iHillsNearMountains = self.mountainsFrac:GetHeight(hillsNearMountains);
	local iMountainThreshold = self.mountainsFrac:GetHeight(mountains);
	local iPassThreshold = self.hillsFrac:GetHeight(hillsNearMountains);
	-- Get height values for tectonic islands
	local iMountain100 = self.mountainsFrac:GetHeight(100);
	local iMountain99 = self.mountainsFrac:GetHeight(99);
	local iMountain97 = self.mountainsFrac:GetHeight(97);
	local iMountain95 = self.mountainsFrac:GetHeight(95);

	-- Because we haven't yet shifted the plot types, we will not be able to take advantage 
	-- of having water and flatland plots already set. We still have to generate all data
	-- for hills and mountains, too, then shift everything, then set plots one more time.
	for x = 0, self.iNumPlotsX - 1 do
		for y = 0, self.iNumPlotsY - 1 do
		
			local i = y * self.iNumPlotsX + x;
			local val = self.continentsFrac:GetHeight(x, y);
			local mountainVal = self.mountainsFrac:GetHeight(x, y);
			local hillVal = self.hillsFrac:GetHeight(x, y);
	
			if(val <= iWaterThreshold) then
				self.plotTypes[i] = PlotTypes.PLOT_OCEAN;
				
				if tectonic_islands then -- Build islands in oceans along tectonic ridge lines - Brian
					if (mountainVal == iMountain100) then -- Isolated peak in the ocean
						self.plotTypes[i] = PlotTypes.PLOT_MOUNTAIN;
					elseif (mountainVal == iMountain99) then
						self.plotTypes[i] = PlotTypes.PLOT_HILLS;
					elseif (mountainVal == iMountain97) or (mountainVal == iMountain95) then
						self.plotTypes[i] = PlotTypes.PLOT_LAND;
					end
				end
					
			else
				if (mountainVal >= iMountainThreshold) then
					if (hillVal >= iPassThreshold) then -- Mountain Pass though the ridgeline - Brian
						self.plotTypes[i] = PlotTypes.PLOT_HILLS;
					else -- Mountain
						self.plotTypes[i] = PlotTypes.PLOT_MOUNTAIN;
					end
				elseif (mountainVal >= iHillsNearMountains) then
					self.plotTypes[i] = PlotTypes.PLOT_HILLS; -- Foot hills - Bob
				else
					if ((hillVal >= iHillsBottom1 and hillVal <= iHillsTop1) or (hillVal >= iHillsBottom2 and hillVal <= iHillsTop2)) then
						self.plotTypes[i] = PlotTypes.PLOT_HILLS;
					else
						self.plotTypes[i] = PlotTypes.PLOT_LAND;
					end
				end
			end
		end
	end

	self:ShiftPlotTypes();
	
	-- Now shift everything toward the south pole, to tilt the continent toward the warm climate.
	local iStartRow, iNumRowsToShift;
	local bFoundPangaea, bDoShift = false, false;
	-- Shift South
	for y = 1, self.iNumPlotsY - 2 do
		for x = 0, self.iNumPlotsX - 1 do
			local i = y * self.iNumPlotsX + x;
			if self.plotTypes[i] == PlotTypes.PLOT_HILLS or self.plotTypes[i] == PlotTypes.PLOT_LAND then
				local plot = Map.GetPlot(x, y);
				local iAreaID = plot:GetArea();
				if iAreaID == iBiggestID then
					bFoundPangaea = true;
					iStartRow = y - 1;
					if iStartRow > 3 then -- Enough rows of water space to do a shift.
						bDoShift = true;
					end
					break
				end
			end
		end
		-- Check to see if we've found the Pangaea.
		if bFoundPangaea == true then
			break
		end
	end
	if bDoShift == true then
		local iRowsDifference = iStartRow - 1;
		local iRowsInPlay = math.floor(iRowsDifference * 0.7);
		local iRowsBase = math.ceil(iRowsDifference * 0.3);
		local rows_dice = Map.Rand(iRowsInPlay, "Number of Rows to Shift - LUA Pangaea");
		local iNumRows = math.min(iRowsDifference - 1, iRowsBase + rows_dice);
		local iNumEvenRows = 2 * math.floor(iNumRows / 2); -- MUST be an even number or we risk breaking a 1-tile isthmus and splitting the Pangaea.
		local iNumRowsToShift = math.max(2, iNumEvenRows);
		--print("-"); print("Shifting lands southward by this many plots: ", iNumRowsToShift); print("-");
		-- Process from bottom up.
		for y = 0, (self.iNumPlotsY - 1) - iNumRowsToShift do
			for x = 0, self.iNumPlotsX - 1 do
				local sourcePlotIndex = (y + iNumRowsToShift) * self.iNumPlotsX + x + 1;
				local destPlotIndex = y * self.iNumPlotsX + x + 1;
				self.plotTypes[destPlotIndex] = self.plotTypes[sourcePlotIndex]
			end
		end
		for y = self.iNumPlotsY - iNumRowsToShift, self.iNumPlotsY - 1 do
			for x = 0, self.iNumPlotsX - 1 do
				local i = y * self.iNumPlotsX + x + 1;
				self.plotTypes[i] = PlotTypes.PLOT_OCEAN;
			end
		end
	end

	-- Canyon generation handled independent from other plot generation, for easier customization.
	-- Individual components of canyon generation can be overridden without having to override the entire plot generator.
	-- Method D is called here. Methods A, B and C are called in the RiverGenerator.
	self:GenerateCanyonPlotCandidateList()
	self:MethodD()

	return self.plotTypes;
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
ContinentsFractalWorld = {};
------------------------------------------------------------------------------
function ContinentsFractalWorld.Create(fracXExp, fracYExp)
	local gridWidth, gridHeight = Map.GetGridSize();
	
	local data = {
		InitFractal = FractalWorld.InitFractal,
		ShiftPlotTypes = FractalWorld.ShiftPlotTypes,
		ShiftPlotTypesBy = FractalWorld.ShiftPlotTypesBy,
		DetermineXShift = FractalWorld.DetermineXShift,
		DetermineYShift = FractalWorld.DetermineYShift,
		GenerateCenterRift = FractalWorld.GenerateCenterRift,
		GeneratePlotTypes = ContinentsFractalWorld.GeneratePlotTypes,	-- Custom method
		
		-- Four methods have been crafted to add canyons to the maps. Method D occurs with plot generation. Methods A, B and C come with rivers.
		-- Method A: Fault lines where plates are pulling apart. Opposite of mountain range creation. These large canyons may be segmented.
		-- Method B: Weak spots in the planet's crust. Crust collapses in a pocket area due to high magma activity in the mantle. Creates isolated canyons.
		-- Method C: Plate collision creates mountains, then (geologically) rapid plate separation also creates a parallel canyon.
		-- Method D: Plate separation creates a canyon at fault line, then later plate collision closes most of the canyon and also creates new mountains.
		PlotCanBeCanyon = ContinentsFractalWorld.PlotCanBeCanyon,
		HexAdjustment = FractalWorld.HexAdjustment,
		GenerateCanyonPlotCandidateList = ContinentsFractalWorld.GenerateCanyonPlotCandidateList,
		MethodD = ContinentsFractalWorld.MethodD,
		ContsPlotCanBeCanyon = ContinentsFractalWorld.ContsPlotCanBeCanyon,
		ContsGenerateCanyonPlotCandidateList = ContinentsFractalWorld.ContsGenerateCanyonPlotCandidateList,
		ContsMethodD = ContinentsFractalWorld.ContsMethodD,
		
		iFlags = Map.GetFractalFlags(),
		
		fracXExp = fracXExp,
		fracYExp = fracYExp,
		
		iNumPlotsX = gridWidth,
		iNumPlotsY = gridHeight,
		plotTypes = table.fill(PlotTypes.PLOT_OCEAN, gridWidth * gridHeight),

		-- Canyon variables
		canyon_plot_candidate_list = {},
		mountain_count = 0,
		extra_mountains = 0,
		adjustment = 0,

	};
		
	return data;
end	
------------------------------------------------------------------------------
function ContinentsFractalWorld:ContsPlotCanBeCanyon(plot)
	if plot:IsWater() or plot:IsMountain() or plot:IsCanyon() then
		return false
	else
		return true
	end
end
------------------------------------------------------------------------------
function ContinentsFractalWorld:ContsGenerateCanyonPlotCandidateList()
	for x = 0, self.iNumPlotsX - 1 do
		for y = 1, self.iNumPlotsY - 2 do -- Never putting a canyon in top or bottom row of map.
			local plot = Map.GetPlot(x, y);
			local i = y * self.iNumPlotsX + x + 1;
			if plot:IsWater() then
				self.canyon_plot_candidate_list[i] = false;
			elseif plot:IsMountain() then
				self.mountain_count = self.mountain_count + 1;
				self.canyon_plot_candidate_list[i] = false;
			else
				self.canyon_plot_candidate_list[i] = true;
			end
		end
	end
end
------------------------------------------------------------------------------
function ContinentsFractalWorld:ContsMethodD()
	-- This method seeks to simulate areas where plates pulled apart first, then slammed back 
	-- together, first creating fault line canyons, then smashing most of them and making mountains.
	--
	-- The actual method is to identify hills plots of a specific fractal elevation, in
	-- relationship to mountain generation, and turn some of these and one or two adjacent 
	-- plots into canyons, always two or three plots in size. The net effect should be some
	-- cases of two or three plot canyons in the shadow of mountain ranges.
	print("Mountain count = ", self.mountain_count);
	local max_type_d_canyon_plots = math.ceil(self.mountain_count / 3);
	print("Max 'Type D' canyon plots = ", max_type_d_canyon_plots)
	local canyon_seed = 92 - self.extra_mountains - self.adjustment;
	local HeightTypeD = self.mountainsFrac:GetHeight(canyon_seed);
	local type_d_seed_list = {};
	local num_seed_plots = 0;
	local canyons_placed = 0;
	local firstRingYIsEven = {{0, 1}, {1, 0}, {0, -1}, {-1, -1}, {-1, 0}, {-1, 1}};
	local firstRingYIsOdd = {{1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, 0}, {0, 1}};
	
	-- Generate seed list.
	for x = 0, self.iNumPlotsX - 1 do
		for y = 0, self.iNumPlotsY - 1 do
			local plot = Map.GetPlot(x, y);
			if self:ContsPlotCanBeCanyon(plot) then
				local canyonVal = self.mountainsFrac:GetHeight(x, y);
				if canyonVal == HeightTypeD then
					table.insert(type_d_seed_list, {x, y});
					num_seed_plots = num_seed_plots + 1;
				end
			end
		end
	end
	local shuffled_seed_list;
	
	-- Apply Method D.
	if num_seed_plots > 0 then
		shuffled_seed_list = GetShuffledCopyOfTable(type_d_seed_list);
		for loop = 1, num_seed_plots do
			local x, y = shuffled_seed_list[loop][1], shuffled_seed_list[loop][2];
			local plot = Map.GetPlot(x, y)
			plot:SetPlotType(PlotTypes.PLOT_CANYON, false, false);
			canyons_placed = canyons_placed + 1;
			local i = y * self.iNumPlotsX + x + 1;
			self.canyon_plot_candidate_list[i] = false;
			print("Placing Canyon center via Method D at plot: ", x, y);
			
			-- Try to add adjacent canyon plots.
			local rand = Map.Rand(5, "Extra canyon plots - Lua FractalWorld");
			local num_extra = 1;
			if rand > 1 then
				num_extra = 2;
			end
			print("Attempting to add ", num_extra, " wing plots to this canyon.")
			local wing_plot_candidate_list = {};
			local randomized_first_ring_adjustments = nil;
			local isEvenY = true;
			if y / 2 > math.floor(y / 2) then
				isEvenY = false;
			end
			if isEvenY then
				randomized_first_ring_adjustments = GetShuffledCopyOfTable(firstRingYIsEven);
			else
				randomized_first_ring_adjustments = GetShuffledCopyOfTable(firstRingYIsOdd);
			end
			for attempt = 1, 6 do
				local plot_adjustments = randomized_first_ring_adjustments[attempt];
				local searchX, searchY = self:HexAdjustment(x, y, plot_adjustments)
				local search_i = searchY * self.iNumPlotsX + searchX + 1;
				-- Make sure the search plot is not off the grid.
				if search_i > 0 and search_i < self.iNumPlotsX * self.iNumPlotsY then -- OK, it's in play.
					if self.canyon_plot_candidate_list[search_i] == true then
						table.insert(wing_plot_candidate_list, {searchX, searchY});
					end
				end
			end
			local iNumWingCandidates = table.maxn(wing_plot_candidate_list);
			if iNumWingCandidates >= 1 then
				local iNumWings = math.min(num_extra, iNumWingCandidates)
				-- Create Canyon "wing" plots.
				for wing_loop = 1, iNumWings do
					local wing_x, wing_y = wing_plot_candidate_list[wing_loop][1], wing_plot_candidate_list[wing_loop][2];
					local wing_plot = Map.GetPlot(wing_x, wing_y)
					wing_plot:SetPlotType(PlotTypes.PLOT_CANYON, false, false);
					canyons_placed = canyons_placed + 1;
					local wing_i = wing_y - 1 * self.iNumPlotsX + wing_x + 1;
					self.canyon_plot_candidate_list[wing_i] = false;
					print("Placing Canyon wing via Method D at plot: ", wing_x, wing_y);
				end
			else
				print("No wings available for canyon at ", x, y);
			end

			if canyons_placed >= max_type_d_canyon_plots then
				print(canyons_placed, "canyon plots placed using Method D.");
				break
			elseif loop == num_seed_plots then
				print(canyons_placed, "canyon plots placed using Method D. Less than target: ran out of candidates.");
			end
		end
	else
		print("No eligible plots for Method D of Canyon generation.")
	end
end
------------------------------------------------------------------------------
function ContinentsFractalWorld:GeneratePlotTypes(args)
	if(args == nil) then args = {}; end
	
	local sea_level_low = 63;
	local sea_level_normal = 67;
	local sea_level_high = 71;
	local world_age_old = 2;
	local world_age_normal = 3;
	local world_age_new = 5;
	--
	local extra_mountains = 0;
	local grain_amount = 3;
	local adjust_plates = 1.0;
	local shift_plot_types = true;
	local tectonic_islands = false;
	local hills_ridge_flags = self.iFlags;
	local peaks_ridge_flags = self.iFlags;
	local has_center_rift = true;
	
	local sea_level = Map.GetCustomOption(3)
	if sea_level == 3 then
		sea_level = 1 + Map.Rand(2, "Random Sea Level - Lua");
	end
	local world_age = Map.GetCustomOption(1)
	if world_age == 4 then
		world_age = 1 + Map.Rand(3, "Random World Age - Lua");
	end

	-- Set Sea Level according to user selection.
	local water_percent = sea_level_normal;
	if sea_level == 1 then -- Low Sea Level
		water_percent = sea_level_low
	else -- Normal Sea Level
	end

	-- Set values for hills and mountains according to World Age chosen by user.
	local adjustment = world_age_normal;
	if world_age == 3 then -- 5 Billion Years
		adjustment = world_age_old;
		adjust_plates = adjust_plates * 0.75;
	elseif world_age == 1 then -- 3 Billion Years
		adjustment = world_age_new;
		adjust_plates = adjust_plates * 1.5;
	else -- 4 Billion Years
	end
	-- Apply adjustment to hills and peaks settings.
	local hillsBottom1 = 28 - adjustment;
	local hillsTop1 = 28 + adjustment;
	local hillsBottom2 = 72 - adjustment;
	local hillsTop2 = 72 + adjustment;
	local hillsClumps = 1 + adjustment;
	local hillsNearMountains = 91 - (adjustment * 2) - extra_mountains;
	local mountains = 97 - adjustment - extra_mountains;

	-- Hills and Mountains handled differently according to map size
	local WorldSizeTypes = {};
	for row in GameInfo.Worlds() do
		WorldSizeTypes[row.Type] = row.ID;
	end
	local sizekey = Map.GetWorldSize();
	-- Fractal Grains
	local sizevalues = {
		[WorldSizeTypes.WORLDSIZE_DUEL]     = 3,
		[WorldSizeTypes.WORLDSIZE_TINY]     = 3,
		[WorldSizeTypes.WORLDSIZE_SMALL]    = 4,
		[WorldSizeTypes.WORLDSIZE_STANDARD] = 4,
		[WorldSizeTypes.WORLDSIZE_LARGE]    = 5,
		--[WorldSizeTypes.WORLDSIZE_HUGE]		= 5
	};
	local grain = sizevalues[sizekey] or 3;
	-- Tectonics Plate Counts
	local platevalues = {
		[WorldSizeTypes.WORLDSIZE_DUEL]		= 6,
		[WorldSizeTypes.WORLDSIZE_TINY]     = 9,
		[WorldSizeTypes.WORLDSIZE_SMALL]    = 12,
		[WorldSizeTypes.WORLDSIZE_STANDARD] = 18,
		[WorldSizeTypes.WORLDSIZE_LARGE]    = 24,
		--[WorldSizeTypes.WORLDSIZE_HUGE]     = 30
	};
	local numPlates = platevalues[sizekey] or 5;
	-- Add in any plate count modifications passed in from the map script.
	numPlates = numPlates * adjust_plates;

	-- Generate continental fractal layer and examine the largest landmass. Reject
	-- the result until the largest landmass occupies 58% or less of the total land.
	local done = false;
	local iAttempts = 0;
	local iWaterThreshold, biggest_area, iNumTotalLandTiles, iNumBiggestAreaTiles, iBiggestID;
	while done == false do
		local grain_dice = Map.Rand(7, "Continental Grain roll - LUA Continents");
		if grain_dice < 4 then
			grain_dice = 2;
		else
			grain_dice = 1;
		end
		local rift_dice = Map.Rand(3, "Rift Grain roll - LUA Continents");
		if rift_dice < 1 then
			rift_dice = -1;
		end
		
		self.continentsFrac = nil;
		self:InitFractal{continent_grain = grain_dice, rift_grain = rift_dice};
		iWaterThreshold = self.continentsFrac:GetHeight(water_percent);
		
		iNumTotalLandTiles = 0;
		for x = 0, self.iNumPlotsX - 1 do
			for y = 0, self.iNumPlotsY - 1 do
				local i = y * self.iNumPlotsX + x;
				local val = self.continentsFrac:GetHeight(x, y);
				if(val <= iWaterThreshold) then
					self.plotTypes[i] = PlotTypes.PLOT_OCEAN;
				else
					self.plotTypes[i] = PlotTypes.PLOT_LAND;
					iNumTotalLandTiles = iNumTotalLandTiles + 1;
				end
			end
		end

		self:ShiftPlotTypes();
		self:GenerateCenterRift()

		SetPlotTypes(self.plotTypes);
		Map.RecalculateAreas();
		
		biggest_area = Map.FindBiggestArea(false);
		iNumBiggestAreaTiles = biggest_area:GetNumTiles();
		-- Now test the biggest landmass to see if it is large enough.
		if iNumBiggestAreaTiles <= iNumTotalLandTiles * 0.58 then
			done = true;
			iBiggestID = biggest_area:GetID();
		end
		iAttempts = iAttempts + 1;
		
		--[[ Printout for debug use only
		print("-"); print("--- Continents landmass generation, Attempt#", iAttempts, "---");
		print("- This attempt successful: ", done);
		print("- Total Land Plots in world:", iNumTotalLandTiles);
		print("- Land Plots belonging to biggest landmass:", iNumBiggestAreaTiles);
		print("- Percentage of land belonging to biggest: ", 100 * iNumBiggestAreaTiles / iNumTotalLandTiles);
		print("- Continent Grain for this attempt: ", grain_dice);
		print("- Rift Grain for this attempt: ", rift_dice);
		print("- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -");
		print(".");
		]]--
	end
	
	-- Generate fractals to govern hills and mountains
	self.hillsFrac = Fractal.Create(self.iNumPlotsX, self.iNumPlotsY, grain, self.iFlags, self.fracXExp, self.fracYExp);
	self.mountainsFrac = Fractal.Create(self.iNumPlotsX, self.iNumPlotsY, grain, self.iFlags, self.fracXExp, self.fracYExp);
	self.hillsFrac:BuildRidges(numPlates, hills_ridge_flags, 1, 2);
	self.mountainsFrac:BuildRidges((numPlates * 2) / 3, peaks_ridge_flags, 6, 1);
	-- Get height values
	local iHillsBottom1 = self.hillsFrac:GetHeight(hillsBottom1);
	local iHillsTop1 = self.hillsFrac:GetHeight(hillsTop1);
	local iHillsBottom2 = self.hillsFrac:GetHeight(hillsBottom2);
	local iHillsTop2 = self.hillsFrac:GetHeight(hillsTop2);
	local iHillsClumps = self.mountainsFrac:GetHeight(hillsClumps);
	local iHillsNearMountains = self.mountainsFrac:GetHeight(hillsNearMountains);
	local iMountainThreshold = self.mountainsFrac:GetHeight(mountains);
	local iPassThreshold = self.hillsFrac:GetHeight(hillsNearMountains);
	
	-- Set Hills and Mountains
	for x = 0, self.iNumPlotsX - 1 do
		for y = 0, self.iNumPlotsY - 1 do
			local plot = Map.GetPlot(x, y);
			local mountainVal = self.mountainsFrac:GetHeight(x, y);
			local hillVal = self.hillsFrac:GetHeight(x, y);
	
			if plot:GetPlotType() ~= PlotTypes.PLOT_OCEAN then
				if (mountainVal >= iMountainThreshold) then
					if (hillVal >= iPassThreshold) then -- Mountain Pass though the ridgeline
						plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
					else -- Mountain
						plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN, false, false);
					end
				elseif (mountainVal >= iHillsNearMountains) then
					plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
				elseif ((hillVal >= iHillsBottom1 and hillVal <= iHillsTop1) or (hillVal >= iHillsBottom2 and hillVal <= iHillsTop2)) then
					plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
				end
			end
		end
	end

	-- Canyon generation handled independent from other plot generation, for easier customization.
	-- Individual components of canyon generation can be overridden without having to override the entire plot generator.
	-- Method D is called here. Methods A, B and C are called in the RiverGenerator.
	self:ContsGenerateCanyonPlotCandidateList()
	self:ContsMethodD()

end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Generating Plot Types (Lua Tilted Axis) ...");
	
	-- Obtain landmass type selected by user.
	userInputLandmass = Map.GetCustomOption(5) -- GLOBAL variable
	if userInputLandmass == 4 then -- Random
		userInputLandmass = 1 + Map.Rand(3, "Tilted Axis Random Landmass Type - Lua");
	end

	-- Implement landmass type.
	if userInputLandmass == 2 then -- Continents
		local fractal_world = ContinentsFractalWorld.Create();
		fractal_world:GeneratePlotTypes();
	
		GenerateCoasts();
		
	elseif userInputLandmass == 3 then -- Small Continents
		local sea_level = Map.GetCustomOption(3)
		if sea_level == 3 then
			sea_level = 1 + Map.Rand(2, "Random Sea Level - Lua");
		end
		local world_age = Map.GetCustomOption(1)
		if world_age == 4 then
			world_age = 1 + Map.Rand(3, "Random World Age - Lua");
		end

		local fractal_world = FractalWorld.Create();
		fractal_world:InitFractal{
			continent_grain = 3};

		local args = {
			sea_level = sea_level,
			world_age = world_age,
			sea_level_low = 64,
			sea_level_normal = 70,
			sea_level_high = 75,
			extra_mountains = 2,
			adjust_plates = 1.5,
			tectonic_islands = true,
			}
		local plotTypes = fractal_world:GeneratePlotTypes(args);

		-- Now shift everything toward the south pole, to tilt the land toward the warm climate.
		local iW, iH = Map.GetGridSize()
		local iStartRow, iNumRowsToShift = 4, 4;
		-- Process from bottom up.
		for y = 0, (iH - 1) - iNumRowsToShift do
			for x = 0, iW - 1 do
				local sourcePlotIndex = (y + iNumRowsToShift) * iW + x + 1;
				local destPlotIndex = y * iW + x + 1;
				plotTypes[destPlotIndex] = plotTypes[sourcePlotIndex]
			end
		end
		for y = iH - iNumRowsToShift, iH - 1 do
			for x = 0, iW - 1 do
				local i = y * iW + x + 1;
				plotTypes[i] = PlotTypes.PLOT_OCEAN;
			end
		end
	
		SetPlotTypes(plotTypes);
		GenerateCoasts();

	else -- Pangaea
		local fractal_world = PangaeaFractalWorld.Create();
		local plotTypes = fractal_world:GeneratePlotTypes();
	
		SetPlotTypes(plotTypes);
		GenerateCoasts();

	end
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function TerrainGenerator:GetLatitudeAtPlot(iX, iY)
	-- Custom lat for Tilted Axis.
	local lat = 2 * iY/self.iHeight;
	lat = lat + (128 - self.variation:GetHeight(iX, iY))/(255.0 * 5.0);
	lat = math.clamp(lat, 0, 2);
	return lat
end
----------------------------------------------------------------------------------
function TerrainGenerator:GenerateTerrainAtPlot(iX,iY)
	local lat = self:GetLatitudeAtPlot(iX,iY);

	local plot = Map.GetPlot(iX, iY);
	if (plot:IsWater()) then
		local val = plot:GetTerrainType();
		if val == TerrainTypes.NO_TERRAIN then -- Error handling.
			val = self.terrainGrass;
			plot:SetPlotType(PlotTypes.PLOT_LAND, false, false);
		end
		return val;	 
	end
	
	local terrainVal = self.terrainGrass;

	if lat >= 1 then
		terrainVal = self.terrainSnow;
	elseif lat >= 0.8 then
		terrainVal = self.terrainTundra;
	elseif lat < 0.35 then
		terrainVal = self.terrainDesert;
	elseif lat <= 0.5 then
		terrainVal = self.terrainGrass;
	else
		local desertVal = self.deserts:GetHeight(iX, iY);
		local plainsVal = self.plains:GetHeight(iX, iY);
		if ((desertVal >= self.iDesertBottom) and (desertVal <= self.iDesertTop)) then
			terrainVal = self.terrainDesert;
		elseif ((plainsVal >= self.iPlainsBottom) and (plainsVal <= self.iPlainsTop)) then
			terrainVal = self.terrainPlains;
		end
	end
	
	-- Error handling.
	if (terrainVal == TerrainTypes.NO_TERRAIN) then
		return plot:GetTerrainType();
	end

	return terrainVal;
end
------------------------------------------------------------------------------
function GenerateTerrain()
	print("Generating Terrain (Lua Tilted Axis) ...");
	local args = {iDesertPercent = 11, iPlainsPercent = 35,	};
	local terraingen = TerrainGenerator.Create(args);

	local terrainTypes = terraingen:GenerateTerrain()
		
	SetTerrainTypes(terrainTypes);
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function RiverGenerator:GetCapsForMethodC()
	-- Set up caps for number of formations and plots based on world size.
	if userInputLandmass == 3 then -- Small Continents, reduce Method C parameters.
		local worldsizes = {
			[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {2, 4, 2, 0},
			[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {3, 7, 2, 1},
			[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {5, 12, 2, 2},
			[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {6, 18, 2, 3},
			[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {7, 28, 3, 3},
			--[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {9, 42, 4, 4},
			};
		local caps_list = worldsizes[Map.GetWorldSize()];
		local max_lines, max_plots, base_length, extension_range = caps_list[1], caps_list[2], caps_list[3], caps_list[4];
		return max_lines, max_plots, base_length, extension_range;
	else -- Regular parameters.
		local worldsizes = {
			[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {2, 6, 4, 2},
			[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {3, 10, 5, 2},
			[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {4, 14, 6, 2},
			[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {5, 21, 7, 3},
			[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {6, 32, 8, 3},
			--[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {8, 50, 10, 4},
			};
		local caps_list = worldsizes[Map.GetWorldSize()];
		local max_lines, max_plots, base_length, extension_range = caps_list[1], caps_list[2], caps_list[3], caps_list[4];
		return max_lines, max_plots, base_length, extension_range;
	end
end
------------------------------------------------------------------------------
function AddRivers()
	print("Generating Rivers, Canyons, and Lakes. (Lua Tilted Axis) ...");

	local args = {};
	local rivergen = RiverGenerator.Create(args);
	
	rivergen:Generate();
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function FeatureGenerator:GetLatitudeAtPlot(iX, iY)
	local lat = 2 * iY / self.iGridH;
	return lat
end
------------------------------------------------------------------------------
function FeatureGenerator:AddFeaturesAtPlot(iX, iY)
	-- adds any appropriate features at the plot (iX, iY) where (0,0) is in the SW
	local lat = self:GetLatitudeAtPlot(iX, iY);
	local plot = Map.GetPlot(iX, iY);

	-- Determine Wildness of this plot.
	local terrain_type = plot:GetTerrainType()
	if terrain_type == self.terrainDesert then
		local plot_type = plot:GetPlotType()
		if plot_type == PlotTypes.PLOT_LAND or plot_type == PlotTypes.PLOT_HILLS then
			local iWildVal = self.miasma:GetHeight(iX, iY)
			if iWildVal >= self.iWildAreaHeight then
				plot:SetWildness(20) -- Designate as a "core" wild plot in a desert Wild Area.
			else
				plot:SetWildness(21) -- Designate as a "periphery" wild plot in a desert Wild Area.
			end
		end
	elseif lat < 1 then
		local plot_type = plot:GetPlotType()
		if plot_type == PlotTypes.PLOT_LAND or plot_type == PlotTypes.PLOT_HILLS then
			if self.forestclumps:GetHeight(iX, iY) >= self.iClumpLevel then -- Wild plot.
				local iWildVal = self.miasma:GetHeight(iX, iY)
				if iWildVal >= self.iWildAreaHeight then
					if terrain_type == self.terrainTundra then
						plot:SetWildness(30) -- Designate as a "core" wild plot in a tundra Wild Area.
					elseif terrain_type == self.terrainGrass or terrain_type == self.terrainPlains then
						plot:SetWildness(10) -- Designate as a "core" wild plot in a forest Wild Area.
					end
				else
					if terrain_type == self.terrainTundra then
						plot:SetWildness(31) -- Designate as a "periphery" wild plot in a tundra Wild Area.
					elseif terrain_type == self.terrainGrass or terrain_type == self.terrainPlains then
						plot:SetWildness(11) -- Designate as a "periphery" wild plot in a forest Wild Area.
					end
				end
			end
		end
	end

	if plot:CanHaveFeature(self.featureFloodPlains) then
		-- All desert plots along river are set to flood plains.
		plot:SetFeatureType(self.featureFloodPlains, -1)
	end
	
	if (plot:GetFeatureType() == FeatureTypes.NO_FEATURE) then
		self:AddIceAtPlot(plot, iX, iY, lat);
	end

	if (plot:GetFeatureType() == FeatureTypes.NO_FEATURE) then
		self:AddMarshAtPlot(plot, iX, iY, lat);
	end
		
	if (plot:GetFeatureType() == FeatureTypes.NO_FEATURE) then
		self:AddForestsAtPlot(plot, iX, iY, lat);
	end
		
	if (plot:GetFeatureType() == FeatureTypes.NO_FEATURE) then
		self:AddJunglesAtPlot(plot, iX, iY, lat);
	end
	
	self:DetermineWildness(plot, iX, iY, lat);
	
end
------------------------------------------------------------------------------
function FeatureGenerator:AddIceAtPlot(plot, iX, iY, lat)
	if(plot:CanHaveFeature(self.featureIce)) then
		local iW, iH = Map.GetGridSize()
		if iY >= iH / 2 then
			plot:SetFeatureType(self.featureIce, -1);
		else
			local rand = Map.Rand(100, "Add Ice Lua") / 100;

			if(rand < 8 * (lat - 0.975)) then
				plot:SetFeatureType(self.featureIce, -1);
			elseif(rand < 4 * (lat - 0.85)) then
				plot:SetFeatureType(self.featureIce, -1);
			end
		end
	end
end
------------------------------------------------------------------------------
function FeatureGenerator:AddJunglesAtPlot(plot, iX, iY, lat)
	local lat = (lat - 0.425) * 1.3;
	-- Jungles are not placed in BE. This function has been repurposed to place a
	-- combination of marsh, clear and forest features in place of where jungles went.
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
------------------------------------------------------------------------------
function FeatureGenerator:AdjustTerrainTypes()
	local width = self.iGridW - 1;
	local height = self.iGridH - 1;
	
	for y = 0, math.floor(height * 0.48) do -- For Tilted Axis, only adjust on light side of the planet.
		for x = 0, width do
			local plot = Map.GetPlot(x, y);
			
			if (plot:GetFeatureType() == self.featureJungle) then
				plot:SetTerrainType(self.terrainPlains, false, true)  -- These flags are for recalc of areas and rebuild of graphics. No need to recalc from any of these changes.		
			elseif (plot:IsRiver()) then
				local terrainType = plot:GetTerrainType();
				if (terrainType == self.terrainTundra) then
					plot:SetTerrainType(self.terrainPlains, false, true)
				elseif (terrainType == self.terrainIce) then
					plot:SetTerrainType(self.terrainTundra, false, true)					
				end
			end
		end
	end
end
------------------------------------------------------------------------------
function FeatureGenerator:AddAtolls()
	-- Do nothing.
end
------------------------------------------------------------------------------
function AddFeatures()
	print("Adding Features (Lua Tilted Axis) ...");
	
	-- Get Rainfall setting input by user.
	local rain = Map.GetCustomOption(2)
	if rain == 4 then
		rain = 1 + Map.Rand(3, "Random Rainfall - Lua");
	end
	
	local args = {rainfall = rain}
	local featuregen = FeatureGenerator.Create(args);

	-- False parameter removes mountains from coastlines.
	featuregen:AddFeatures(false);
end
-------------------------------------------------------------------------
function StartPlotSystem()
	-- Get Resources setting input by user.
	local res = Map.GetCustomOption(4)
	if res == 6 then
		res = 1 + Map.Rand(3, "Random Resources Option - Lua");
	end

	print("Creating start plot database.");
	local start_plot_database = AssignStartingPlots.Create()
	
	print("Dividing the map in to Regions.");
	-- Regional Division Method 5: All Start (No starts in the ice.)
	local iW, iH = Map.GetGridSize()
	local args = {
		method = 5,
		resources = res,
		};
	start_plot_database:GenerateRegions(args)

	print("Choosing start locations for civilizations.");
	start_plot_database:ChooseLocations()
	
	print("Normalizing start locations and assigning them to Players.");
	start_plot_database:BalanceAndAssign()

	print("Placing Resources and City States.");
	start_plot_database:PlaceResourcesAndCityStates()

	if userInputLandmass == 3 then -- Small Continents, so
		-- tell the AI that we should treat this as a offshore expansion map
		Map.ChangeAIMapHint(4);
	elseif userInputLandmass == 4 then -- Small Continents or Islands map, so
		-- tell the AI that we should treat this as a offshore expansion map with a naval bias
		Map.ChangeAIMapHint(5);
	end

end
------------------------------------------------------------------------------
