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

local frameHider = CreateFrame("FRAME");

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
	frameHider:SetScript("OnUpdate", function(self, elapsed)		
		if(frame:GetAlpha() == 0) then
			frame:Hide();
			frameHider:SetScript("OnUpdate", nil);
		end
	end);
end


------------------------------------

local function setPosition(currentTime, castTime)
	local x = currentTime*260/castTime;

	return (260-x)/2;
end





local function onUNIT_SPELLCAST_START(...)
	local name, _, text, _, startTime, endTime, isTradeSkill, _, notInterruptible, color;
	
	local isChanneling = false;
	if(... == "UNIT_SPELLCAST_START") then
		name, _, text, _, startTime, endTime, isTradeSkill, _, notInterruptible = UnitCastingInfo("player");
		color = {1,1,0.2};
		castBar.value = (GetTime() - (startTime / 1000));
	else
		name, _, text, _, startTime, endTime, isTradeSkill, _, notInterruptible = UnitChannelInfo("player");
		color = {0.35,1,0.35};
		castBar.value = (endTime - startTime)/1000;
		isChanneling = true;
	end
	
	local castTime = (endTime - startTime)/1000;
	
	castBar.filler:SetMinMaxValues(0, (endTime - startTime)/1000);
	castBar.filler:SetStatusBarColor(unpack(color));
	castBar.filler:SetValue(castBar.value);
	castBar.text:SetText(name);
	
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

local function onUNIT_SPELLCAST_SUCCEEDED(...)
	if(isCasting) then
    	castBar.filler:SetStatusBarColor(0.35,1,0.35);
    	createTimer(0.2, UIFrameFadeOut, castBar, 0.5, 1, 0);
	end
end

local function onUNIT_SPELLCAST_STOP(...)
	if(isCasting) then
    	castBar:SetScript("OnUpdate", nil);
    	castBar.filler:SetValue(select(2,castBar.filler:GetMinMaxValues()));
   		castBar.filler:SetPoint("CENTER", 0, 0);
    	isCasting = false;
		createTimer(1, UIFrameFadeOut, castBar, 0.5, 1, 0);    	
	end
end

local function onUNIT_SPELLCAST_FAILED(...)

end

local function onUNIT_SPELLCAST_INTERRUPTED(...)
	castBar.filler:SetStatusBarColor(1,0.1,0.1);
	castBar.text:SetText("Interrutped");
end

local function onUNIT_SPELLCAST_CHANNEL_START(...)

end

local function onUNIT_SPELLCAST_CHANNEL_STOP(...)
	onUNIT_SPELLCAST_SUCCEEDED(...)
	onUNIT_SPELLCAST_STOP(...)
end

local function onUNIT_SPELLCAST_DELAYED(...)
	local name, _, text, _, startTime, endTime = UnitCastingInfo("player");
	local castTime = (endTime - startTime)/1000;
	
	castBar.value = (GetTime() - (startTime / 1000)); 
	castBar.filler:SetMinMaxValues(0, castTime);
end

local function onUNIT_SPELLCAST_CHANNEL_UPDATE(...)
	local name, _, text, _, startTime, endTime = UnitChannelInfo("player");
	local castTime = (endTime - startTime)/1000;
	
	castBar.value = (endTime / 1000) - GetTime();
	castBar.filler:SetMinMaxValues(0, castTime);
end

local eventHandler = {
	["UNIT_SPELLCAST_START"] = onUNIT_SPELLCAST_START,
	["UNIT_SPELLCAST_SUCCEEDED"] = onUNIT_SPELLCAST_SUCCEEDED,
	["UNIT_SPELLCAST_STOP"] = onUNIT_SPELLCAST_STOP,
	["UNIT_SPELLCAST_FAILED"] = onUNIT_SPELLCAST_FAILED,
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
	
	castBar.filler = CreateFrame("StatusBar", "test", castBar);
	castBar.filler:SetStatusBarTexture("Interface\\AddOns\\Phaeton\\Textures\\texture.blp");
	castBar.filler:SetSize(260,13);
	castBar.filler:SetPoint("CENTER");
	
	castBar.text = castBar.filler:CreateFontString(nil, "OVERLAY");
	castBar.text:SetFont("Interface\\AddOns\\Rising\\Futura-Condensed-Normal.TTF", 18, "OUTLINE");
	castBar.text:SetTextColor(0.7, 0.7, 0.7, 1);
	castBar.text:SetPoint("CENTER", castBar, 0, 1);
	
	
	
	castBar:SetScript("OnEvent", function(self, event, ...)
		if(... == "player") then
			eventHandler[event](event, ...);
		end
	end);
	
	castBar:RegisterEvent("UNIT_SPELLCAST_START");
	castBar:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED");
	castBar:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED");
	castBar:RegisterEvent("UNIT_SPELLCAST_FAILED");
	castBar:RegisterEvent("UNIT_SPELLCAST_STOP");
	castBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START");
	castBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP");
	castBar:RegisterEvent("UNIT_SPELLCAST_DELAYED");
	castBar:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE");
	
	castBar:Hide();
end








Addon:SetScript("OnEvent", function()
	setUpCastBar();
	
	--Disable Blizz Castbar
	--CastingBarFrame:UnregisterAllEvents();
	Addon:UnregisterAllEvents();	
end);

Addon:RegisterEvent("PLAYER_ENTERING_WORLD");

