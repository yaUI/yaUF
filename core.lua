local addon, ns = ...
local E, M = unpack(vCore);
local cfg = ns.cfg
local lib = ns.lib
local oUF = ns.oUF or oUF
assert(oUF, "vUF was unable to locate oUF.")
--------------

local function ChangedTarget(self, event, unit)
	if UnitIsUnit('target', self.unit) then
		self.Targeted:SetBackdropBorderColor(.8, .8, .8, 1)
		self.Targeted:Show()
	else
		self.Targeted:Hide()
	end
end

local function Shared(self, unit)
	unit = unit:match('^(.-)%d+') or unit

	self:RegisterForClicks('AnyUp')
	self:SetScript("OnEnter", function(self)
		self.Highlight:Show()
		UnitFrame_OnEnter(self)
	end)
	self:SetScript("OnLeave", function(self)
		self.Highlight:Hide()
		UnitFrame_OnLeave(self)
	end)

	-------------------
	-- Health
	-------------------
	local Health = CreateFrame("StatusBar", nil, self)
	Health:SetStatusBarTexture(cfg.barTexture)
	Health:SetPoint("TOPLEFT")
	Health:SetHeight(cfg.everythingElse.health.height)
	Health:SetWidth(cfg.everythingElse.health.width)

	if unit == "player" or unit == "target" or unit == 'party' then
		Health:SetHeight(cfg.player.health.height)
		Health:SetWidth(cfg.player.health.width)
	end

	--Options
	Health.frequentUpdates = true
	Health.colorTapping = true
	Health.colorDisconnected = true
	Health.colorClass = true
	Health.colorHealth = true
	Health.Smooth = true

	--Background
	local HealthBG = Health:CreateTexture(nil, "BACKGROUND")
	HealthBG:SetTexture(cfg.barTexture)
	HealthBG:SetAllPoints(Health)
	HealthBG.multiplier = 0.3

	--Registration
	Health.bg = HealthBG
	self.Health = Health

	-------------------
	-- Strings
	-------------------
	local name, hpval

	if unit == "targettarget" or unit == "focus" or unit == "pet" then
		name = lib.SetFont(Health, 10, "THINOUTLINE")
		hpval = lib.SetFont(Health, 10, "THINOUTLINE")
	else
		name = lib.SetFont(Health, 12, "THINOUTLINE")
		hpval = lib.SetFont(Health, 12, "THINOUTLINE")
	end

	name:SetPoint("LEFT", Health, "LEFT", 2, 0)
	name:SetJustifyH("LEFT")
	name:SetWordWrap(false)

	hpval:SetPoint("RIGHT", Health, "RIGHT", -2, 0)

	name:SetPoint("RIGHT", hpval, "LEFT", -5, 0)
	self:Tag(name, "[name]")

	if unit == "player" or unit == "target" then
		self:Tag(hpval, "[vui:hpdefault]")
	else
		self:Tag(hpval, "[vui:hpperc]")
	end

	-------------------
	-- Power
	-------------------
	local Power = CreateFrame("StatusBar", nil, self)
	Power:SetStatusBarTexture(cfg.barTexture)
	Power:SetPoint("TOPLEFT", Health, "BOTTOMLEFT", 0, -1)

	if unit == "targettarget" or unit == "focus" or unit == "pet" then
		Power:SetHeight(4)
		Power:SetWidth(cfg.everythingElse.health.width)
	else
		Power:SetHeight(5)
		Power:SetWidth(cfg.player.health.width)
	end

	--Options
	Power.frequentUpdates = true
	Power.colorPower = true
	Power.Smooth = true

	--Background
	local PowerBG = Power:CreateTexture(nil, "BACKGROUND")
	PowerBG:SetTexture(cfg.barTexture)
	PowerBG:SetAllPoints(Power)
	PowerBG.multiplier = 0.3

	--Registration
	Power.bg = PowerBG
	self.Power = Power

	--Backdrop for both health and power
	local HealthPowerBD = CreateFrame("Frame", nil, Health)
	HealthPowerBD:SetFrameLevel(0)
	HealthPowerBD:SetPoint("TOPLEFT",-5,5)
	HealthPowerBD:SetPoint("BOTTOMRIGHT", 5, -5 - Power:GetHeight() - 1)

	E:SkinBackdrop(HealthPowerBD)

	--Highlighter on mouseover
	local Highlight = Health:CreateTexture(nil, "OVERLAY")
	Highlight:SetAllPoints(self)
	Highlight:SetTexture(cfg.whiteSquare)
	Highlight:SetVertexColor(1, 1, 1, .1)
	Highlight:SetBlendMode("ADD")
	Highlight:Hide()

	self.Highlight = Highlight

	if unit == 'player' or unit == 'target' or unit == 'party' then

		-------------------
		-- Portrait
		-------------------
		local Portrait = CreateFrame("PlayerModel", nil, self)
		Portrait:SetHeight(unit == 'party' and cfg.player.portrait.partyHeight or cfg.player.portrait.height)
		Portrait:SetWidth(cfg.player.portrait.width)
		Portrait:SetFrameLevel(Health:GetFrameLevel() - 1)
		if unit == "player" or unit == 'party' then
			Portrait:SetPoint("TOPRIGHT", Health, "TOPLEFT", -5, 0)
		elseif unit == "target" then
			Portrait:SetPoint("TOPLEFT", Health, "TOPRIGHT", 5, 0)
		end

		--Backdrop
		E:CreateBackdrop(Portrait)

		--Registration
		self.Portrait = Portrait

		if unit == 'player' or unit == 'party' then

			-------------------
			-- Highlight the unit if its our target, makes it easier for healers and general ui feedback
			-------------------
			local Targeted = CreateFrame("Frame", nil, self)
			Targeted:SetPoint("TOPLEFT", Health, "TOPLEFT", 0, 0)
			Targeted:SetPoint("BOTTOMRIGHT", Health, "BOTTOMRIGHT", 0, 0)
			Targeted:SetBackdrop({edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 1})
			Targeted:SetFrameLevel(Health:GetFrameLevel() + 1)
			Targeted:Hide()
			self:RegisterEvent('PLAYER_TARGET_CHANGED', ChangedTarget)
			self:RegisterEvent('RAID_ROSTER_UPDATE', ChangedTarget)

			self.Targeted = Targeted
		end


-- Icons

		-------------------
		-- Raid Target icon
		-------------------
		local RaidTarget = self:CreateTexture(nil, "OVERLAY")
		RaidTarget:SetHeight(24)
		RaidTarget:SetWidth(24)
		RaidTarget:SetPoint("TOP", Portrait, "TOP", 0, 4)

		self.RaidTargetIndicator = RaidTarget

		-------------------
		-- Group Role icon
		-------------------
		local GroupRole = self:CreateTexture(nil, 'OVERLAY')
		GroupRole:SetHeight(16)
		GroupRole:SetWidth(16)
		if unit == "player" or unit == 'party' then
			GroupRole:SetPoint("TOPRIGHT", Portrait, "TOPRIGHT", 0, -1)
		elseif unit == "target" then
			GroupRole:SetPoint("TOPLEFT", Portrait, "TOPLEFT", 1, -1)
		end

		self.GroupRoleIndicator = GroupRole

		-------------------
		-- Ready Check icon
		-------------------
		local ReadyCheck = self:CreateTexture(nil, 'OVERLAY')
		ReadyCheck:SetHeight(16)
		ReadyCheck:SetWidth(16)
		ReadyCheck:SetPoint("CENTER", Portrait)

		self.ReadyCheckIndicator = ReadyCheck

		-------------------
		-- Leader icon
		-------------------
		local Leader = self:CreateTexture(nil, 'OVERLAY')
		Leader:SetHeight(16)
		Leader:SetWidth(16)
		if unit == "player" or unit == 'party' then
			Leader:SetPoint("BOTTOMLEFT", Portrait, "BOTTOMLEFT", 0, -3)
		elseif unit == "target" then
			Leader:SetPoint("BOTTOMRIGHT", Portrait, "BOTTOMRIGHT", 2, -3)
		end

		self.LeaderIndicator = Leader

		-------------------
		-- Raid Role icon
		-------------------
		local RaidRole = self:CreateTexture(nil, 'OVERLAY')
		RaidRole:SetHeight(16)
		RaidRole:SetWidth(16)
		RaidRole:SetPoint("BOTTOM", Portrait, "BOTTOM", 0, -1)

		self.RaidRoleIndicator = RaidRole

		-------------------
		-- Level text
		-------------------
		local Level = lib.SetFont(Portrait, 12, "THINOUTLINE")
		if unit == "player" or unit == 'party' then
			Level:SetPoint("BOTTOMRIGHT", Portrait, "BOTTOMRIGHT", 3, -0.5)
		elseif unit == "target" then
			Level:SetPoint("BOTTOMLEFT", Portrait, "BOTTOMLEFT", 0, -0.5)
		end
		self:Tag(Level, "[level]")

----------------------------------------

		-------------------
		-- Debuffs
		-------------------
		local Debuffs = CreateFrame("Frame", nil, self)

		--Options
		Debuffs.size = 21
		if unit == "player" or unit == 'party' then
			Debuffs.num = 9
		elseif unit == "target" then
			Debuffs.num = 18
		end
		Debuffs.spacing = 5
		Debuffs.onlyShowPlayer = false
		Debuffs:SetHeight((Debuffs.size+Debuffs.spacing)*2)
		Debuffs:SetWidth(cfg.player.health.width)
		Debuffs.PostCreateIcon = lib.PostCreateIcon
		if unit == 'player' or unit == 'party' then
			Debuffs.PostUpdateIcon = lib.PostUpdateBuff --Lets not desaturize the debuffs since we wont debuff party members or ourselves
		else
			Debuffs.PostUpdateIcon = lib.PostUpdateDebuff
		end

		if unit == "player" or unit == 'target' then
			Debuffs:SetPoint("BOTTOMLEFT", Health, "TOPLEFT", 0, 31)
			Debuffs.initialAnchor = "BOTTOMLEFT"
			Debuffs["growth-x"] = "RIGHT"
			Debuffs["growth-y"] = "UP"
		elseif unit == "party" then
			Debuffs:SetPoint("TOPLEFT", Power, "BOTTOMLEFT", 0, -5)
			Debuffs.initialAnchor = "TOPLEFT"
			Debuffs["growth-x"] = "RIGHT"
			Debuffs["growth-y"] = "DOWN"
		end

		--Registration
		self.Debuffs = Debuffs

		-------------------
		-- Buffs
		-------------------
		local Buffs = CreateFrame("Frame", nil, self)

		--Options
		Buffs.size = 21
		Buffs.num = 9
		Buffs.spacing = 5
		Buffs:SetHeight(Buffs.size+Buffs.spacing)
		Buffs:SetWidth(cfg.player.health.width)

		if unit == "player" or unit == 'target' then
			Buffs.onlyShowPlayer = false
			Buffs.showStealableBuffs = true
			Buffs:SetPoint("BOTTOMLEFT", Health, "TOPLEFT", 0, 5)
			Buffs.initialAnchor = "BOTTOMLEFT"
			Buffs["growth-x"] = "RIGHT"
			Buffs["growth-y"] = "UP"
		elseif unit == "party" then
			Buffs.onlyShowPlayer = true
			Buffs.showStealableBuffs = false
			Buffs:SetWidth(cfg.player.health.width)
			Buffs:SetPoint("TOPLEFT", Health, "TOPRIGHT", 5, 0)
			Buffs.initialAnchor = "TOPLEFT"
			Buffs["growth-x"] = "RIGHT"
			Buffs["growth-y"] = "DOWN"
		end

		--Registration
		Buffs.PostCreateIcon = lib.PostCreateIcon
		Buffs.PostUpdateIcon = lib.PostUpdateDebuff
		self.Buffs = Buffs

--player & target exclusive

		if unit == 'player' or unit == 'target' then

			-------------------
			-- Castbar
			-------------------
			local Castbar = CreateFrame("StatusBar", nil, self)
			Castbar:SetFrameStrata('HIGH')
			Castbar:SetHeight(cfg.player.castbar.height)
			Castbar:SetWidth(cfg.player.castbar.width)
			Castbar:SetPoint("TOPLEFT", Power, "BOTTOMLEFT", 0, -7)
			Castbar:SetStatusBarTexture(cfg.barTexture)
			Castbar:SetStatusBarColor(1, 0.8, 0,1)

			if not IsAddOnLoaded("vBars") and unit == 'player' then
				Castbar:ClearAllPoints()
				Castbar:SetPoint('BOTTOM', CENTER,'BOTTOM', 0, 330)
			end

			--Options
			Castbar.timeToHold = 0.2 --indicates for how many seconds the castbar should be visible after a _FAILED or _INTERRUPTED event

			--Backdrop
			E:CreateBackdrop(Castbar)

			--Background
			local CastbarBG = Castbar:CreateTexture(nil, "BACKGROUND")
			CastbarBG:SetTexture(cfg.barTexture)
			CastbarBG:SetAllPoints(Castbar)
			CastbarBG:SetVertexColor(1*0.3, 0.8*0.3, 0,0.7)

			--Spell Time
			local Time = lib.SetFont(Castbar, 11, "THINOUTLINE")
			Time:SetPoint("RIGHT", Castbar)

			--Spell Text
			local Text = lib.SetFont(Castbar, 11, "THINOUTLINE")
			Text:SetPoint("LEFT", Castbar, 2, 0)

			--Spark
			local Spark = Castbar:CreateTexture(nil, 'OVERLAY')
			Spark:SetSize(2, cfg.player.castbar.height - 2)
			Spark:SetColorTexture(1, 1, 1)

			--SafeZone represents red latency bar on the end of the castbar
			local SafeZone = Castbar:CreateTexture(nil, 'OVERLAY')

			--Shield represents interrupt shield
			local Shield = Castbar:CreateTexture(nil, 'OVERLAY')
			Shield:SetTexture(M:Fetch('vui', 'shield'))
			Shield:SetSize(32, 32)
			Shield:SetPoint('CENTER', Castbar)

			--Registration
			Castbar.bg = CastbarBG
			Castbar.Spark = Spark
			Castbar.SafeZone = SafeZone
			Castbar.Shield = Shield
			Castbar.Text = Text
			Castbar.Time = Time
			self.Castbar = Castbar

			-------------------
			-- Heal Prediction
			-------------------
			local myBar = CreateFrame('StatusBar', nil, Health)
			myBar:SetPoint('TOP')
			myBar:SetPoint('BOTTOM')
			myBar:SetPoint('LEFT', Health:GetStatusBarTexture(), 'RIGHT')
			myBar:SetWidth(cfg.player.health.width)
			myBar:SetStatusBarTexture(cfg.barTexture)
			myBar:SetStatusBarColor(125/255, 255/255, 50/255, .3)

			local otherBar = CreateFrame('StatusBar', nil, Health)
			otherBar:SetPoint('TOP')
			otherBar:SetPoint('BOTTOM')
			otherBar:SetPoint('LEFT', Health:GetStatusBarTexture(), 'RIGHT')
			otherBar:SetWidth(cfg.player.health.width)
			otherBar:SetStatusBarTexture(cfg.barTexture)
			otherBar:SetStatusBarColor(100/255, 235/255, 200/255, .3)

			local absorbBar = CreateFrame('StatusBar', nil, Health)
			absorbBar:SetPoint('TOP')
			absorbBar:SetPoint('BOTTOM')
			absorbBar:SetPoint('LEFT', Health:GetStatusBarTexture(), 'RIGHT')
			absorbBar:SetWidth(cfg.player.health.width)
			absorbBar:SetStatusBarTexture(cfg.barTexture)
			absorbBar:SetStatusBarColor(180/255, 255/255, 205/255, .35)

			local healAbsorbBar = CreateFrame('StatusBar', nil, Health)
			healAbsorbBar:SetPoint('TOP')
			healAbsorbBar:SetPoint('BOTTOM')
			healAbsorbBar:SetPoint('LEFT', Health:GetStatusBarTexture(), 'RIGHT')
			healAbsorbBar:SetWidth(cfg.player.health.width)
			healAbsorbBar:SetStatusBarTexture(cfg.barTexture)
			healAbsorbBar:SetStatusBarColor(183/255, 244/255, 255/255, .35)

			-- Register with oUF
			self.HealthPrediction = {
				myBar = myBar,
				otherBar = otherBar,
				absorbBar = absorbBar,
				healAbsorbBar = healAbsorbBar,
				maxOverflow = 1.00,
				frequentUpdates = true,
			}
		end
----------------------------------------
	end


	if unit == 'player' or unit == 'target' or unit == 'party' then
		self:SetSize(cfg.player.health.width, cfg.player.health.height)
	elseif unit == 'targettarget' or unit == 'focus' or unit == 'pet' then
		self:SetSize(cfg.everythingElse.frame.width, cfg.everythingElse.frame.height)
	else
		self:SetSize(300,51) --Nothing should hit this if everything is working right
	end

	if(ns.style[unit]) then
		return ns.style[unit](self)
	end
end

oUF:RegisterStyle("vUF", Shared)
oUF:Factory(function(self)
	self:SetActiveStyle('vUF')
	if IsAddOnLoaded("vBars") then
		self:Spawn('player', 'vUF_Player'):SetPoint('TOPRIGHT', UIParent, 'CENTER', -15, -200)
		self:Spawn('target', 'vUF_Target'):SetPoint('TOPLEFT', UIParent, 'CENTER', 15, -200)
	else
		self:Spawn('player', 'vUF_Player'):SetPoint('TOPLEFT', UIParent, 'TOPLEFT', cfg.player.portrait.width + 100, -100)
		self:Spawn('target', 'vUF_Target'):SetPoint('TOP', UIParent, 'TOP', 0, -100)
	end

	self:Spawn('focus', 'vUF_Focus'):SetPoint('BOTTOMLEFT', vUF_Player.Portrait, 'TOPLEFT', 0, 5)
	self:Spawn('pet', 'vUF_Pet'):SetPoint('TOPLEFT', vUF_Player.Portrait, 'BOTTOMLEFT', 0, -5)
	self:Spawn('targettarget', 'vUF_TargetTarget'):SetPoint('BOTTOMLEFT', vUF_Target.Portrait, 'TOPLEFT', 0, 6)

	local offset = -40
	if not IsAddOnLoaded("vBars") then
		offset = offset * -1
	end

	local header = self:SpawnHeader('vUF_Party', nil, 'party',
		'oUF-initialConfigFunction', [[
			self:SetWidth(230)
			self:SetHeight(60)
		]],
		'showParty', true,
		'yOffset', offset,
		'groupBy', 'ASSIGNEDROLE',
		'groupingOrder', 'TANK,HEALER,DAMAGER'
	);

	header:SetPoint('BOTTOMRIGHT', vUF_Player.Health,'BOTTOMLEFT', -200, 0)
	if not IsAddOnLoaded("vBars") then
		header:ClearAllPoints()
		header:SetPoint('TOPLEFT', vUF_Player,'BOTTOMLEFT', 0, -40)
	end
end)
