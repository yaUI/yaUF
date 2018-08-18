local _, ns = ...
local oUF = nUF or ns.oUF or oUF
assert(oUF, "vUF was unable to locate oUF.")
--------------

local tags = oUF.Tags
local tagMethods = tags.Methods
local tagEvents = tags.Events
local tagSharedEvents = tags.SharedEvents

local gsub = string.gsub
local format = string.format
local floor = math.floor

local function Short(value)
	if(value >= 1e6) then
		return gsub(format('%.2fm', value / 1e6), '%.?0+([km])$', '%1')
	elseif(value >= 1e4) then
		return gsub(format('%.1fk', value / 1e3), '%.?0+([km])$', '%1')
	else
		return value
	end
end

-- Default syntax
oUF.Tags.Methods["vui:hpdefault"] = function(unit)
	if not UnitIsConnected(unit) then
		return "|cff999999Off|r"
	end
	
	if(UnitIsDead(unit) or UnitIsGhost(unit)) then 
		return "|cff999999Dead|r"
	end
	
	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	local per = 0
	if max > 0 then
		per = floor(min/max*100)
	end
	
	local val = Short(min)
	return val.."|cffcccccc / |r"..per.."%"
end
oUF.Tags.Events["vui:hpdefault"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION"

-- Simple percentage
oUF.Tags.Methods["vui:hpperc"] = function(unit)
	if not UnitIsConnected(unit) then
		return "|cff999999Off|r"
	end
	
	if(UnitIsDead(unit) or UnitIsGhost(unit)) then 
		return "|cff999999Dead|r"
	end
	
	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	local per = 0
	if max > 0 then
		per = floor(min/max*100)
	end
	
	return per.."%"
end
oUF.Tags.Events["vui:hpperc"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION"

oUF.Tags.Methods["vui:hpraid"] = function(unit)
	if not UnitIsConnected(unit) then
		return "|cff999999Off|r"
	end
	if(UnitIsDead(unit) or UnitIsGhost(unit)) then
		return "|cff999999Dead|r"
	end
	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	if min == max and max > 0 then
		return UnitName(unit)
	end
	return "-"..Short(max-min)
end

oUF.Tags.Events["vui:hpraid"] = "UNIT_NAME_UPDATE UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION"