local addon, ns = ...
local E, M = unpack(yaCore);
local cfg = ns.cfg
local lib = CreateFrame("Frame")
--------------

lib.SetFont = function(f, size, outline, font)
	local fs = f:CreateFontString(nil, "OVERLAY")
	fs:SetFont(font or cfg.font, size, outline)
	fs:SetShadowColor(0, 0, 0, 0.2)
	fs:SetShadowOffset(0, -0)
	return fs
end

lib.UpdateAura = function(self, elapsed)
	if(self.expiration) then
		self.expiration = math.max(self.expiration - elapsed, 0)

		if(self.expiration > 0 and self.expiration < 60) then
			self.Duration:SetFormattedText('%d', self.expiration)
		else
			self.Duration:SetText()
		end
	end
end

lib.PostCreateIcon = function(element, button)
	button.cd:SetReverse(true)
	button.cd:SetHideCountdownNumbers(true)
	button.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	button.icon:SetDrawLayer('ARTWORK')

	--Backdrop
	Mixin(button, BackdropTemplateMixin)
	E:CreateBackdrop(button)

	-- We create a parent for aura strings so that they appear over the cooldown widget
	local StringParent = CreateFrame('Frame', nil, button)
	StringParent:SetFrameLevel(20)

	button.count:SetParent(StringParent)
	button.count:ClearAllPoints()
	button.count:SetPoint('BOTTOMRIGHT', button, 2, 1)
	button.count:SetFont(M:Fetch("font", "Roboto"), 10, "THINOUTLINE")

	local Duration = lib.SetFont(StringParent, 12, "THINOUTLINE")
	Duration:SetPoint('TOPLEFT', button, 0, -1)
	button.Duration = Duration

	button:HookScript('OnUpdate', lib.UpdateAura)
end

lib.PostUpdateBuff = function(element, unit, button, index)
	local _, _, _, _, duration, expiration, _, _ = UnitAura(unit, index, button.filter)

	if(duration and duration > 0) then
		button.expiration = expiration - GetTime()
	else
		button.expiration = math.huge
	end
end

lib.PostUpdateDebuff = function(element, unit, button, index, position)
	local _, _, _, _, _, _, owner = UnitAura(unit, index, button.filter)

	if (owner == 'player') or (owner == 'pet') then
		button.icon:SetDesaturated(false)
	else
		button.icon:SetDesaturated(true)
	end

	lib.PostUpdateBuff(element, unit, button, index)
end

lib.PostUpdateClassPower = function(element, cur, max, diff, powerType)
	if(diff) then

		-- Rogues can go from 5 to 6
		local barWidth
		local spacerCount = max - 1
		local spacerTotalSize = spacerCount * cfg.player.classpower.spacing
		barWidth = (cfg.player.health.width - spacerTotalSize) / max

		for index = 1, max do
			local Bar = element[index]
			Bar:SetWidth(barWidth)

			if(index > 1) then
				Bar:ClearAllPoints()
				Bar:SetPoint('LEFT', element[index - 1], 'RIGHT', cfg.player.classpower.spacing, 0)
			end
		end
	end
end

lib.UpdateClassPowerColor = function(element)
	local r, g, b = 1, 1, 2/5
	if(not UnitHasVehicleUI('player')) then
		if(E.Class == 'MONK') then
			r, g, b = 0, 4/5, 3/5
		elseif(E.Class == 'WARLOCK') then
			r, g, b = 2/3, 1/3, 2/3
		elseif(E.Class == 'PALADIN') then
			r, g, b = 1, 1, 2/5
		elseif(E.Class == 'MAGE') then
			r, g, b = 5/6, 1/2, 5/6
		end
	end

	for index = 1, #element do
		local Bar = element[index]
		if(E.Class == 'ROGUE' and element.__max == 10 and index > 5) then
			r, g, b = 1, 0, 0
		end

		Bar:SetStatusBarColor(r, g, b)
		Bar.bg:SetColorTexture(r * 1/3, g * 1/3, b * 1/3)
	end
end

lib.PostUpdateTotem = function(element)
	local shown = {}
	for index = 1, MAX_TOTEMS do
		local Totem = element[index]
		if(Totem:IsShown()) then
			local prevShown = shown[#shown]

			Totem:ClearAllPoints()
			Totem:SetPoint('TOPLEFT', shown[#shown] or element.__owner, 'TOPRIGHT', 1, 0)
			table.insert(shown, Totem)
		end
	end
end

lib.UpdateExperienceTooltip = function(self)
	local honor = UnitLevel('player') == MAX_PLAYER_LEVEL and IsWatchingHonorAsXP()

	local bars = honor and 5 or 20
	local cur = (honor and UnitHonor or UnitXP)('player')
	local max = (honor and UnitHonorMax or UnitXPMax)('player')
	local per = math.floor(cur / max * 100 + 0.5)

	local rested = (honor and GetHonorExhaustion or GetXPExhaustion)() or 0
	rested = math.floor(rested / max * 100 + 0.5)

	GameTooltip:SetOwner(self, 'ANCHOR_NONE')
	GameTooltip:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -5)
	GameTooltip:SetText(string.format('%s / %s (%s%%)', BreakUpLargeNumbers(cur), BreakUpLargeNumbers(max), per))
	GameTooltip:AddLine(string.format('%.1f bars, %s%% rested', cur / max * bars, rested))
	GameTooltip:Show()
end

lib.UpdateReputationTooltip = function(self)
	local pendingReward
	local name, standingID, min, max, cur, factionID = GetWatchedFactionInfo()

	local friendID, _, _, _, _, _, standingText, _, friendMax = GetFriendshipReputation(factionID)
	if(friendID) then
		if(friendMax) then
			max = friendMax
			cur = math.fmod(cur, max)
		else
			max = cur
		end

		standingID = 5 -- force friends' color
	else
		if(standingID ~= 8) then
			max = max - min
			cur = cur - min
		end

		standingText = GetText('FACTION_STANDING_LABEL' .. standingID, UnitSex('player'))
	end

	local per = math.floor(cur / max * 100 + 0.5)

	GameTooltip:SetOwner(self, 'ANCHOR_NONE')
	GameTooltip:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -5)
	GameTooltip:SetText(name)
	GameTooltip:AddLine(string.format('%s / %s (%s%%)', BreakUpLargeNumbers(cur), BreakUpLargeNumbers(max), per))
	GameTooltip:AddLine(string.format('%s: %.1f bars', standingText, cur / max * 20))
	GameTooltip:Show()
end

lib.UpdateArtifactPowerTooltip = function(self)
	local _, _, _, _, totalPower, traitsLearned, _, _, _, _, _, _, tier = C_ArtifactUI.GetEquippedArtifactInfo()

	local cur = self.current
	local max = self.max
	local per = math.floor(cur / max * 100 + 0.5)

	GameTooltip:SetOwner(self, 'ANCHOR_NONE')
	GameTooltip:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', 0, -5)
	GameTooltip:SetText(string.format('%s / %s (%s%%) %.1f bars.', BreakUpLargeNumbers(cur), BreakUpLargeNumbers(max), per, cur / max * 20))
	GameTooltip:Show()
end



local frame = CreateFrame("FRAME", nil); -- Frame to respond to events
frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:RegisterEvent("PLAYER_REGEN_ENABLED");
frame:RegisterEvent("GROUP_ROSTER_UPDATE");
frame:RegisterEvent("PARTY_LEADER_CHANGED");
frame:RegisterEvent("RAID_TARGET_UPDATE");
frame:RegisterEvent("PLAYER_FLAGS_CHANGED");
frame:RegisterEvent("UNIT_FLAGS");
frame:RegisterEvent("RAID_ROSTER_UPDATE");
frame:RegisterEvent("UI_SCALE_CHANGED");
frame:RegisterEvent("DISPLAY_SIZE_CHANGED");
frame:RegisterEvent("UNIT_PET");

local frames = {"Manager", "Container"}
local function eventHandler(self, event, ...)
	if InCombatLockdown() then return end
	if event then
		if cfg.hideRaidframe then
			if IsAddOnLoaded("Blizzard_CompactRaidFrames") then
				for _, v in ipairs(frames) do
					local f = _G["CompactRaidFrame"..v]
					f:UnregisterAllEvents()
					f.Show = function() end
				end
			end
		end
		if cfg.hideBuffFrame then
			local BlizzFrame = _G['BuffFrame']
			BlizzFrame:UnregisterEvent('UNIT_AURA')
			BlizzFrame:Hide()
			BlizzFrame = _G['TemporaryEnchantFrame']
			BlizzFrame:Hide()
		end
	end
end

frame:SetScript("OnEvent", eventHandler); -- frame script that begins running the on event handler
--------------
ns.lib = lib
