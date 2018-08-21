local addon, ns = ...
local E, M = unpack(vCore);
local cfg = ns.cfg
local lib = ns.lib
local oUF = ns.oUF or oUF
assert(oUF, "vUF was unable to locate oUF.")
--------------

local unpack = unpack

local function kickable(self)
	if (self.notInterruptible) then
		self:SetStatusBarColor(unpack(cfg.player.castbar.unkickableColor))
	else
		self:SetStatusBarColor(unpack(cfg.player.castbar.color))
	end
end

local function ChangedTarget(self, event, unit)
	if UnitIsUnit('target', self.unit) then
		self.Targeted:SetBackdropBorderColor(.8, .8, .8, 1)
		self.Targeted:Show()
	else
		self.Targeted:Hide()
	end
end

local cvars = {
  nameplateGlobalScale = 1,
  NamePlateHorizontalScale = 1,
  NamePlateVerticalScale = 1,
  nameplateLargerScale = 1,
  nameplateMaxScale = 1,
  nameplateMinScale = 0.8,
  nameplateSelectedScale = 1,
  nameplateSelfScale = 1,
  -- nameplateShowAll = 0,
  nameplateMinAlpha = 0.5,
  nameplateMinAlphaDistance = 10,
  nameplateMaxAlpha = 1,
  nameplateMaxAlphaDistance = 10,
  nameplateMaxDistance = 60,
}

local function getcolor(unit)
	local reaction = UnitReaction(unit, "player") or 5

	if UnitIsPlayer(unit) then
		local class = select(2, UnitClass(unit))
		local color = RAID_CLASS_COLORS[class]
		return color.r, color.g, color.b
	elseif UnitCanAttack("player", unit) then
		if UnitIsDead(unit) then
			return 136/255, 136/255, 136/255
		else
			if reaction<4 then
				return 1, 68/255, 68/255
			elseif reaction==4 then
				return 1, 1, 68/255
			end
		end
	else
		if reaction<4 then
			return 48/255, 113/255, 191/255
		else
			return 1, 1, 1
		end
	end
end

local function CreateCastBar(self, unit)

	-------------------
	-- Castbar
	-------------------
	local Castbar = CreateFrame("StatusBar", nil, self)
	Castbar:SetFrameStrata('HIGH')
	Castbar:SetHeight(cfg.player.castbar.height)
	Castbar:SetWidth(cfg.player.castbar.width)
	Castbar:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -7)
	Castbar:SetStatusBarTexture(cfg.barTexture)
	Castbar:SetStatusBarColor(unpack(cfg.player.castbar.color))

	if not IsAddOnLoaded("vBars") and unit == 'player' then
		Castbar:SetHeight(cfg.player.health.height)
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
	CastbarBG:SetVertexColor(unpack(cfg.player.castbar.colorBg))

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

	Castbar.PostChannelStart = kickable
	Castbar.PostChannelUpdate = kickable
	Castbar.PostCastStart = kickable
	Castbar.PostCastDelayed = kickable
	Castbar.PostCastNotInterruptible = kickable
	Castbar.PostCastInterruptible = kickable

	self.Castbar = Castbar


	-------------------
	-- Heal Prediction
	-------------------
	local myBar = CreateFrame('StatusBar', nil, self.Health)
	myBar:SetPoint('TOP')
	myBar:SetPoint('BOTTOM')
	myBar:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT')
	myBar:SetWidth(cfg.player.health.width)
	myBar:SetStatusBarTexture(cfg.barTexture)
	myBar:SetStatusBarColor(125/255, 255/255, 50/255, .3)

	local otherBar = CreateFrame('StatusBar', nil, self.Health)
	otherBar:SetPoint('TOP')
	otherBar:SetPoint('BOTTOM')
	otherBar:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT')
	otherBar:SetWidth(cfg.player.health.width)
	otherBar:SetStatusBarTexture(cfg.barTexture)
	otherBar:SetStatusBarColor(100/255, 235/255, 200/255, .3)

	local absorbBar = CreateFrame('StatusBar', nil, self.Health)
	absorbBar:SetPoint('TOP')
	absorbBar:SetPoint('BOTTOM')
	absorbBar:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT')
	absorbBar:SetWidth(cfg.player.health.width)
	absorbBar:SetStatusBarTexture(cfg.barTexture)
	absorbBar:SetStatusBarColor(180/255, 255/255, 205/255, .35)

	local healAbsorbBar = CreateFrame('StatusBar', nil, self.Health)
	healAbsorbBar:SetPoint('TOP')
	healAbsorbBar:SetPoint('BOTTOM')
	healAbsorbBar:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT')
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

local function CreateAuras(self, unit)
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
		Debuffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, 31)
		Debuffs.initialAnchor = "BOTTOMLEFT"
		Debuffs["growth-x"] = "RIGHT"
		Debuffs["growth-y"] = "UP"
	elseif unit == "party" then
		Debuffs:SetPoint("TOPLEFT", self.Power, "BOTTOMLEFT", 0, -5)
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
		Buffs:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, 5)
		Buffs.initialAnchor = "BOTTOMLEFT"
		Buffs["growth-x"] = "RIGHT"
		Buffs["growth-y"] = "UP"
	elseif unit == "party" then
		Buffs.onlyShowPlayer = true
		Buffs.showStealableBuffs = false
		Buffs:SetWidth(cfg.player.health.width)
		Buffs:SetPoint("TOPLEFT", self.Health, "TOPRIGHT", 5, 0)
		Buffs.initialAnchor = "TOPLEFT"
		Buffs["growth-x"] = "RIGHT"
		Buffs["growth-y"] = "DOWN"
	end

	--Registration
	Buffs.PostCreateIcon = lib.PostCreateIcon
	Buffs.PostUpdateIcon = lib.PostUpdateDebuff
	self.Buffs = Buffs
end

local function Shared(self, unit)
	unit = unit:match('^(.-)%d+') or unit

	self:RegisterForClicks('AnyUp')
	self:SetScript("OnEnter", function(self)
		if self.Highlight then
			self.Highlight:Show()
		end
		UnitFrame_OnEnter(self)
	end)
	self:SetScript("OnLeave", function(self)
		if self.Highlight then
			self.Highlight:Hide()
		end
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

	name = lib.SetFont(Health, 12, "THINOUTLINE")
	hpval = lib.SetFont(Health, 12, "THINOUTLINE")

	if unit ~= 'nameplate' then

		name:SetPoint("LEFT", Health, "LEFT", 2, 0)
		name:SetJustifyH("LEFT")
		name:SetWordWrap(false)

		hpval:SetPoint("RIGHT", Health, "RIGHT", -2, 0)

		name:SetPoint("RIGHT", hpval, "LEFT", -5, 0)
	else
		name:SetTextHeight(10)
		hpval:SetTextHeight(10)
		name:SetPoint("BOTTOM", Health, "TOP", 0, 2)

		hpval:SetPoint("CENTER", Health, "CENTER", 0, 0)
	end

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
	Power:SetPoint("TOPRIGHT", Health, "BOTTOMRIGHT", 0, -1)

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
	Highlight:SetAllPoints(Health)
	Highlight:SetTexture(cfg.whiteSquare)
	Highlight:SetVertexColor(1, 1, 1, .1)
	Highlight:SetBlendMode("ADD")
	Highlight:Hide()

	self.Highlight = Highlight

	if unit == 'player' or unit == 'party' or unit == 'nameplate' then

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


		CreateAuras(self, unit)
		if unit ~= 'party' then
			CreateCastBar(self, unit)
		end

	end

	-------------------
	-- Nameplates
	-------------------
	if unit == 'nameplate' then

		self:EnableMouse(false)
		self:SetPoint("CENTER", 0, -10)
		self.Health:SetHeight(cfg.namePlates.health.height)

		self.Power:SetHeight(cfg.namePlates.frame.height - cfg.namePlates.health.height)
		self.Power:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, 0)
		self.Power:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT", 0, 0)

		HealthPowerBD:SetPoint("TOPLEFT", -4, 4)
		HealthPowerBD:SetPoint("BOTTOMRIGHT", 4, -7)

		local QuestIndicator = self:CreateTexture(nil, 'OVERLAY')
		QuestIndicator:SetSize(20, 20)
		QuestIndicator:SetPoint('LEFT', self.Health, 'RIGHT', 2,  0)

		self.QuestIndicator = QuestIndicator

		local RaidTarget = self:CreateTexture(nil, "OVERLAY")
		RaidTarget:SetSize(24, 24)
		RaidTarget:SetPoint("RIGHT", self.Health, "LEFT", -2, 0)

		self.RaidTargetIndicator = RaidTarget

		self.Health.colorClass = false
		self.Health.colorReaction = true

		CreateCastBar(self, unit)
		CreateAuras(self, unit)

		self.Castbar:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 0, -5)
		self.Castbar:SetPoint("TOPRIGHT", self.Health, "BOTTOMRIGHT", 0, -5)

		self.Castbar.Time:SetTextHeight(7)
		self.Castbar.Text:SetTextHeight(7)

		self.Castbar:SetHeight(10)
		self.Castbar.Spark:SetSize(2, 8)
	end

	if unit == 'player' or unit == 'target' or unit == 'party' then
		self:SetSize(cfg.player.health.width, cfg.player.health.height)
	elseif unit == 'nameplate' then
		self:SetSize(cfg.namePlates.frame.width, cfg.namePlates.frame.height)
	elseif unit == 'targettarget' or unit == 'focus' or unit == 'pet' or unit == 'nameplate' then
		self:SetSize(cfg.everythingElse.frame.width, cfg.everythingElse.frame.height)
	else
		self:SetSize(300,51) --Nothing should hit this if everything is working right
	end

	if(ns.style[unit]) then
		return ns.style[unit](self)
	end
end

-- -----------------------------------
-- > SPAWN UNIT
-- -----------------------------------
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

	if cfg.showNameplates then
		self:SpawnNamePlates('vUF_NamePlate', ChangedTarget, cvars)
	end
end)
