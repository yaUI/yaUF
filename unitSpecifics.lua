local addon, ns = ...
local E, M = unpack(yaCore);
local cfg = ns.cfg
local lib = ns.lib
local oUF = ns.oUF or oUF
assert(oUF, "yaUF was unable to locate oUF.")
--------------

local UnitSpecific = {
		player = function(self)
--[[
			local PowerPrediction = CreateFrame('StatusBar', nil, self.Power)
			PowerPrediction:SetPoint('RIGHT', self.Power:GetStatusBarTexture())
			PowerPrediction:SetPoint('BOTTOM')
			PowerPrediction:SetPoint('TOP')
			PowerPrediction:SetWidth(cfg.player.health.width)
			PowerPrediction:SetStatusBarTexture(cfg.barTexture)
			PowerPrediction:SetStatusBarColor(1, 0, 0)
			PowerPrediction:SetReverseFill(true)
			self.PowerPrediction = {
				mainBar = PowerPrediction
			}]]

			------------------
			-- Class Power
			------------------
			local ClassPower = {}
			ClassPower.UpdateColor = lib.UpdateClassPowerColor
			ClassPower.PostUpdate = lib.PostUpdateClassPower

			for index = 1, 11 do -- have to create an extra to force __max to be different from UnitPowerMax
				local Bar = CreateFrame('StatusBar', nil, self.Power, "BackdropTemplate")
				Bar:SetHeight(5)
				Bar:SetStatusBarTexture(cfg.barTexture)

				if(index > 1) then
					Bar:SetPoint('LEFT', ClassPower[index - 1], 'RIGHT', cfg.player.classpower.spacing, 0)
				else
					Bar:SetPoint('TOPLEFT', self.Power, 'BOTTOMLEFT', 0, -1)
				end

				if(index > 5) then
					Bar:SetFrameLevel(Bar:GetFrameLevel() + 1)
				end

				--Background
				local Background = Bar:CreateTexture(nil, 'BORDER')
				Background:SetAllPoints()
				Bar.bg = Background

				--Backdrop
				E:CreateBackdrop(Bar)

				ClassPower[index] = Bar
			end
			-- Registration
			self.ClassPower = ClassPower

			------------------
			-- Totems
			------------------
			local Totems = {}
			Totems.PostUpdate = PostUpdateTotem

			for index = 1, MAX_TOTEMS do
				local Totem = CreateFrame('Button', nil, self.Power, "BackdropTemplate")
				Totem:SetSize(24, 24)
				Totem:SetPoint('TOPLEFT', self.Power, 'BOTTOMLEFT', (index - 1) * Totem:GetWidth(), -1)

				local Icon = Totem:CreateTexture(nil, 'OVERLAY')
				Icon:SetAllPoints()
				Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
				Totem.Icon = Icon

				local Cooldown = CreateFrame('Cooldown', nil, Totem, 'CooldownFrameTemplate')
				Cooldown:SetAllPoints()
				Cooldown:SetReverse(true)
				Totem.Cooldown = Cooldown

				--Backdrop
				E:CreateBackdrop(Totem)

				Totems[index] = Totem
			end
			-- Registration
			self.Totems = Totems

			if(E.Class == 'DEATHKNIGHT') then
				local spacerCount = 5
				local spacerTotalSize = spacerCount * cfg.player.classpower.spacing
				local barWidth = (cfg.player.health.width - spacerTotalSize) / 6

				local Runes = {}
				for index = 1, 6 do
					local Rune = CreateFrame('StatusBar', nil, self.Power, "BackdropTemplate")
					Rune:SetSize(barWidth, 2)
					Rune:SetStatusBarTexture(cfg.barTexture)

					if(index == 1) then
						Rune:SetPoint('TOPLEFT', self.Power, 'BOTTOMLEFT', 0, -1)
					else
						Rune:SetPoint('LEFT', Runes[index - 1], 'RIGHT', cfg.player.classpower.spacing, 0)
					end

					--Backdrop
					E:CreateBackdrop(Rune)

					Runes[index] = Rune
				end
				-- Registration
				self.Runes = Runes
			end

			------------------
			-- Experience
			------------------
			local Experience = CreateFrame('StatusBar', nil, UIParent, 'AnimatedStatusBarTemplate')
			Experience:SetStatusBarTexture(cfg.barTexture)
			Experience:SetStatusBarColor(0.15, 0.7, 0.1)
			Experience:SetScript('OnEnter', lib.UpdateExperienceTooltip)
			Experience:SetScript('OnLeave', GameTooltip_Hide)
			Experience:SetHeight(cfg.player.experience.height)

			if IsAddOnLoaded("vChat") and IsAddOnLoaded("vBars") then
				Experience:SetPoint('TOPLEFT', ChatFrame1, 'BOTTOMLEFT', 0, -6)
				Experience:SetWidth(ChatFrame1:GetWidth())
			else
				Experience:SetPoint('BOTTOMLEFT', 10, 10)
				Experience:SetWidth(cfg.player.experience.width)
			end

			local Rested = CreateFrame('StatusBar', nil, Experience)
			Rested:SetStatusBarTexture(cfg.barTexture)
			Rested:SetStatusBarColor(0, 0.4, 1, 0.6)
			Rested:SetAllPoints(Experience)
			Experience.Rested = Rested

			--Backdrop
			Mixin(Experience, BackdropTemplateMixin)
			E:CreateBackdrop(Experience)

			-- Registration
			self.Experience = Experience

			------------------
			-- Reputation
			------------------
			local Reputation = CreateFrame('StatusBar', nil, UIParent, 'AnimatedStatusBarTemplate')
			Reputation:SetStatusBarTexture(cfg.barTexture)
			Reputation:SetStatusBarColor(0.15, 0.7, 0.1)
			Reputation:SetScript('OnEnter', lib.UpdateReputationTooltip)
			Reputation:SetScript('OnLeave', GameTooltip_Hide)
			Reputation:SetHeight(cfg.player.experience.height)

			-- Reward
			local Reward = Reputation:CreateTexture(nil, 'ARTWORK')
			Reward:SetPoint('TOP', Reputation, 'BOTTOM', 0, -2)
			Reward:SetSize(16, 18)
			Reputation.Reward = Reward

			if IsAddOnLoaded("vChat") and IsAddOnLoaded("vBars") then
				Reputation:SetPoint('TOPLEFT', ChatFrame1, 'BOTTOMRIGHT', 15, -6)
				Reputation:SetPoint('TOPRIGHT', ChatFrame3, 'BOTTOMLEFT', -15, -6)
			else
				Reputation:SetPoint('BOTTOMLEFT', 10, 22)
				Reputation:SetWidth(cfg.player.experience.width)
			end

			--Options
			Reputation.colorStanding = true -- Color the bar by current standing

			--Backdrop
			Mixin(Reputation, BackdropTemplateMixin)
			E:CreateBackdrop(Reputation)

			-- Registration
			self.Reputation = Reputation

			------------------
			-- Artifact Power
			------------------
			local ArtifactPower = CreateFrame('StatusBar', nil, UIParent, 'AnimatedStatusBarTemplate')
			ArtifactPower:SetStatusBarTexture(cfg.barTexture)
			ArtifactPower:SetStatusBarColor(0.901, 0.8, 0.601)
			ArtifactPower:SetScript('OnEnter', lib.UpdateArtifactPowerTooltip)
			ArtifactPower:SetScript('OnLeave', GameTooltip_Hide)
			ArtifactPower:SetHeight(cfg.player.experience.height)

			if IsAddOnLoaded("vChat") and IsAddOnLoaded("vBars") then
				ArtifactPower:SetPoint('TOPLEFT', ChatFrame3, 'BOTTOMLEFT', 0, -6)
				ArtifactPower:SetWidth(ChatFrame1:GetWidth())
			else
				ArtifactPower:SetPoint('BOTTOMLEFT', 10, 34)
				ArtifactPower:SetWidth(cfg.player.experience.width)
			end

			--Backdrop
			Mixin(ArtifactPower, BackdropTemplateMixin)
			E:CreateBackdrop(ArtifactPower)

			-- Registration
			self.ArtifactPower = ArtifactPower


		end,

		party = function(self)
		end,

}

---------------
ns.style = UnitSpecific
