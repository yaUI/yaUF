local addon, ns = ...
local E, M = unpack(vCore);
local cfg = CreateFrame("Frame")
--------------

-- Show/hide Blizzard Stuff
cfg.hideBuffFrame = true -- hide Blizzard's default buff frame (best to keep it on until you can cancel buffs in oUF again)
cfg.hideRaidframe = false -- hide Blizzard's default raid frames

cfg.everythingElse = {
	frame = {
		width = 100,
		height = 20
	},
	health = {
		width = 100,
		height = 17
	}
}

cfg.player = {
	health = {
		width = 229,
		height = 30
	},
	portrait = {
		width = cfg.everythingElse.frame.width - 1, --the portrait width is always a pixel larger
		height = 60,
		partyHeight = 63
	},
	castbar = {
		width = 229,
		height = 18
	},
	experience = {
		width = 229,
		height = 6
	},
	classpower = {
		spacing = 1
	}
}

cfg.barTexture = M:Fetch("vui", "statusbar")
cfg.font = M:Fetch("font", "RobotoBold")

---------------
ns.cfg = cfg
