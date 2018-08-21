local addon, ns = ...
local E, M = unpack(vCore);
local cfg = CreateFrame("Frame")
--------------

-- Show/hide Blizzard Stuff
cfg.hideBuffFrame = true -- hide Blizzard's default buff frame (best to keep it on until you can cancel buffs in oUF again)
cfg.hideRaidframe = false -- hide Blizzard's default raid frames
cfg.showNameplates = true

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

cfg.namePlates = {
	frame = {
		width = 100,
		height = 15
	},
	health = {
		width = 100,
		height = 12
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
		color = {1, 0.8, 0, 1},
		unkickableColor = {.7, .7, .7, 1},
		colorBg = {1*0.3, 0.8*0.3, 0, 0.7},
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

cfg.whiteSquare = M:Fetch("vui", "backdrop")
cfg.barTexture = M:Fetch("vui", "statusbar")
cfg.font = M:Fetch("font", "RobotoBold")

---------------
ns.cfg = cfg
