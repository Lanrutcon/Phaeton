local Addon = CreateFrame("FRAME");

--localing
local UnitCastingInfo, UnitChannelInfo, GetTime = UnitCastingInfo, UnitChannelInfo, GetTime;

local isCasting;

local castBar;


------------------------------------
--	UTILS
------------------------------------

--CreateTimer
local timer = CreateFrame("FRAME");
local frameHider = CreateFrame("FRAME");

local function createTimer(afterTime, func, ...)
	if(not timer:GetScript("OnUpdate")) then
    	local params = {...}
    	timer.total = 0;
    	timer:SetScript("OnUpdate", function(self, elapsed)
    		self.total = self.total + elapsed;
    		if(self.total > afterTime) then
    			func(unpack(params));
    			self:SetScript("OnUpdate", nil);
    		end	
    	end);
	end
end

--Stops timer
local function stopTimer()
	timer:SetScript("OnUpdate", nil);
	frameHider:SetScript("OnUpdate", nil);
end

--Replacing BLIZZ FUNCTION
local function UIFrameFadeOut(frame, timeToFade, startAlpha, endAlpha)
	local fadeInfo = {};
	fadeInfo.mode = "OUT";
	fadeInfo.timeToFade = timeToFade;
	fadeInfo.startAlpha = startAlpha;
	fadeInfo.endAlpha = endAlpha;
	UIFrameFade(frame, fadeInfo);
	
	local total = 0;
	frameHider:SetScript("OnUpdate", function(self, elapsed)
		total = total + elapsed;
		if(total > timeToFade and frame:GetAlpha() == 0) then
    		frame:Hide();
    		frameHider:SetScript("OnUpdate", nil);
		end
	end);
end


------------------------------------

local function setPosition(currentTime, castTime)
	local x = currentTime*255/castTime;

	return (255-x)/2;
end



local function onUNIT_SPELLCAST_START(event)
	local name, _, text, _, startTime, endTime, isTradeSkill, _, notInterruptible, color, isChanneling;
	
	if(event == "UNIT_SPELLCAST_START") then
		name, _, text, _, startTime, endTime, isTradeSkill, _, notInterruptible = UnitCastingInfo("player");
		color = {1,1,0.2};
		castBar.value = (GetTime() - (startTime / 1000));
		isChanneling = false;
	else --it's a channel spell
		name, _, text, _, startTime, endTime, isTradeSkill, _, notInterruptible = UnitChannelInfo("player");
		color = {0.35,1,0.35};
		castBar.value = (endTime - startTime)/1000;
		isChanneling = true;
	end
	
	local castTime = (endTime - startTime)/1000;
	castBar.spellName = name;
	
	
	castBar.filler:SetMinMaxValues(0, (endTime - startTime)/1000);
	castBar.filler:SetStatusBarColor(unpack(color));
	castBar.leftSpark:SetVertexColor(unpack(color));
	castBar.rightSpark:SetVertexColor(unpack(color));
	castBar.filler:SetValue(castBar.value);
	castBar.text:SetText(name);
	castBar.flash:Hide();
	
	local totalElapsed = 0;
	castBar:SetScript("OnUpdate", function(self, elapsed)
		totalElapsed = totalElapsed + elapsed;
		if(totalElapsed > 0.016) then
			if(isChanneling) then
				castBar.value = castBar.value - totalElapsed;
    		else
    			castBar.value = castBar.value + totalElapsed;
    		end
    		self.filler:SetValue(castBar.value);
    		self.filler:SetPoint("CENTER", setPosition(castBar.value, castTime), 0);
    		self.leftSpark:SetPoint("LEFT", -15, 0);
    		self.rightSpark:SetPoint("RIGHT", -242+castBar.value*260/castTime, 0);
    		totalElapsed = 0;
		end
	end);
	
	
	if(castBar:GetAlpha() < 1) then
		UIFrameFadeIn(castBar, 0.2, castBar:GetAlpha(), 1);
	end
	
	isCasting = true;
	stopTimer();
	
	castBar:Show();
end

local function onUNIT_SPELLCAST_SUCCEEDED(event, spellCasted)
	if(isCasting and castBar.spellName == spellCasted) then
    	castBar.filler:SetStatusBarColor(0.35,1,0.35);
    	castBar.leftSpark:SetVertexColor(0.35,1,0.35);
		castBar.rightSpark:SetVertexColor(0.35,1,0.35);
    	createTimer(0.2, UIFrameFadeOut, castBar, 0.5, 1, 0);
    	UIFrameFadeIn(castBar.flash, 0.2, 0, 1);
    	castBar.flash:Show();
	end
end

local function onUNIT_SPELLCAST_STOP()
	if(isCasting) then
    	castBar:SetScript("OnUpdate", nil);
    	castBar.filler:SetValue(select(2,castBar.filler:GetMinMaxValues()));
    	
    	castBar.leftSpark:SetPoint("LEFT", -15, 0);
    	castBar.rightSpark:SetPoint("RIGHT", 17, 0);
    	
   		castBar.filler:SetPoint("CENTER", 0, 0);
    	isCasting = false;
    	castBar.spellName = nil;
		createTimer(1, UIFrameFadeOut, castBar, 0.5, 1, 0);    	
	end
end

local function onUNIT_SPELLCAST_INTERRUPTED()
	castBar.filler:SetStatusBarColor(1,0.1,0.1);
	castBar.leftSpark:SetVertexColor(1,0.1,0.1);
	castBar.rightSpark:SetVertexColor(1,0.1,0.1);
	castBar.text:SetText("Interrutped");
end

local function onUNIT_SPELLCAST_CHANNEL_STOP()
	onUNIT_SPELLCAST_SUCCEEDED()
	onUNIT_SPELLCAST_STOP()
end

local function onUNIT_SPELLCAST_DELAYED()
	local name, _, text, _, startTime, endTime = UnitCastingInfo("player");
	local castTime = (endTime - startTime)/1000;
	
	castBar.value = (GetTime() - (startTime / 1000)); 
	castBar.filler:SetMinMaxValues(0, castTime);
end

local function onUNIT_SPELLCAST_CHANNEL_UPDATE()
	local name, _, text, _, startTime, endTime = UnitChannelInfo("player");
	local castTime = (endTime - startTime)/1000;
	
	castBar.value = (endTime / 1000) - GetTime();
	castBar.filler:SetMinMaxValues(0, castTime);
end


local eventHandler = {
	["UNIT_SPELLCAST_START"] = onUNIT_SPELLCAST_START,
	["UNIT_SPELLCAST_SUCCEEDED"] = onUNIT_SPELLCAST_SUCCEEDED,
	["UNIT_SPELLCAST_STOP"] = onUNIT_SPELLCAST_STOP,
	--["UNIT_SPELLCAST_FAILED"] = onUNIT_SPELLCAST_FAILED,
	["UNIT_SPELLCAST_INTERRUPTED"] = onUNIT_SPELLCAST_INTERRUPTED,
	["UNIT_SPELLCAST_CHANNEL_START"] = onUNIT_SPELLCAST_START,
	["UNIT_SPELLCAST_CHANNEL_STOP"] = onUNIT_SPELLCAST_CHANNEL_STOP,
	["UNIT_SPELLCAST_DELAYED"] = onUNIT_SPELLCAST_DELAYED,
	["UNIT_SPELLCAST_CHANNEL_UPDATE"] = onUNIT_SPELLCAST_CHANNEL_UPDATE;
};


local function setUpCastBar()
	
	castBar = CreateFrame("FRAME", "PhaetonCastingBar", UIParent);
	castBar:SetSize(512*0.7, 64*0.7);
	castBar:SetPoint("CENTER");
	
	castBar.background = castBar:CreateTexture(nil, "BACKGROUND"); 
	castBar.background:SetTexture("Interface\\AddOns\\Phaeton\\Textures\\frame.blp");
	castBar.background:SetAllPoints();
	
	castBar.filler = CreateFrame("StatusBar", "PhaetonCastingBarStatusBar", castBar);
	castBar.filler:SetStatusBarTexture("Interface\\AddOns\\Phaeton\\Textures\\texture.blp");
	castBar.filler:SetSize(260,13);
	castBar.filler:SetPoint("CENTER");
	
	castBar.leftSpark = castBar.filler:CreateTexture(nil, "OVERLAY");
	castBar.leftSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");
	castBar.leftSpark:SetBlendMode("ADD");
	castBar.leftSpark:SetSize(32, 32);
	
	castBar.rightSpark = castBar.filler:CreateTexture(nil, "OVERLAY");
	castBar.rightSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark");
	castBar.rightSpark:SetBlendMode("ADD");
	castBar.rightSpark:SetSize(32, 32);
	
	castBar.text = castBar.filler:CreateFontString(nil, "OVERLAY");
	castBar.text:SetFont("Interface\\AddOns\\Rising\\Futura-Condensed-Normal.TTF", 18, "OUTLINE");
	castBar.text:SetTextColor(0.7, 0.7, 0.7, 1);
	castBar.text:SetPoint("CENTER", castBar, 0, 1);
	
	castBar.flash = castBar:CreateTexture();
	castBar.flash:SetTexture("Interface\\AddOns\\Phaeton\\Textures\\flash.blp");
	castBar.flash:SetAllPoints();
	castBar.flash:SetBlendMode("ADD");
	castBar.flash:Hide();
	
	castBar:SetScript("OnEvent", function(self, event, unit, ...)
		if(unit == "player") then
			eventHandler[event](event, ...);
		end
	end);
	
	castBar:RegisterEvent("UNIT_SPELLCAST_START");
	castBar:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
	castBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
	--castBar:RegisterEvent("UNIT_SPELLCAST_FAILED");
	castBar:RegisterEvent("UNIT_SPELLCAST_STOP");
	castBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START");
	castBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP");
	castBar:RegisterEvent("UNIT_SPELLCAST_DELAYED");
	castBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE");
	
	
	--move bar on shift+click
	castBar:EnableMouse(true);
	castBar:SetScript("OnMouseDown", function(self, button)
		if(IsShiftKeyDown() and IsAltKeyDown() and button == "LeftButton") then
			self:SetMovable(true);
			self:StartMoving();
		end
	end);
	castBar:SetScript("OnMouseUp", function(self, button)
		if(IsShiftKeyDown() and IsAltKeyDown() and button == "LeftButton") then
			self:SetMovable(false);
			self:StopMovingOrSizing();
			PhaetonSV[UnitName("player")] = { self:GetPoint() };
		end
	end);
	
	
	castBar:Hide();
end


local function loadSavedVariables()
	if(not PhaetonSV) then
		PhaetonSV = {};
		PhaetonSV[UnitName("player")] = { castBar:GetPoint() };
	elseif(PhaetonSV[UnitName("player")]) then
		castBar:SetPoint(unpack(PhaetonSV[UnitName("player")]));
	else
		PhaetonSV[UnitName("player")] = { castBar:GetPoint() };
	end
end



Addon:SetScript("OnEvent", function()
	setUpCastBar();
	
	loadSavedVariables();
	
	--Disable Blizz Castbar
	CastingBarFrame:UnregisterAllEvents();
	
	Addon:UnregisterAllEvents();
end);

Addon:RegisterEvent("PLAYER_ENTERING_WORLD");