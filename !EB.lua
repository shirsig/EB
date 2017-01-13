local BUFFS = {
	["Adrenaline Rush"] = {
		ICON = 'Spell_Shadow_ShadowWordDominate',
		DURATION = 15,
	},
	["Sprint"] = {
		ICON = 'Ability_Rogue_Sprint',
		DURATION = 15,
	},
	["Evasion"] = {
		ICON = 'Spell_Shadow_ShadowWard',
		DURATION = 15,
	},
	["Blade Flurry"] = {
		ICON = 'Ability_GhoulFrenzy',
		DURATION = 15,
	},
	["Power Word: Shield"] = {
		ICON = 'Spell_Holy_PowerWordShield',
		DURATION = 30,
	},
	["Power Infusion"] = {
		ICON = 'Spell_Holy_PowerInfusion',
		DURATION = 15,
	},
	["Arcane Power"] = {
		ICON = 'Spell_Nature_Lightning',
		DURATION = 15,
	},
	["Ice Block"] = {
		ICON = 'Spell_Frost_Frost',
		DURATION = 10,
	},
	["Ice Barrier"] = {
		ICON = 'Spell_Ice_Lament',
		DURATION = 60,
	},
	["Nature's Grasp"] = {
		ICON = 'Spell_Nature_NaturesWrath',
		DURATION = 45,
	},
	["Dash"] = {
		ICON = 'Ability_Druid_Dash',
		DURATION = 15,
	},
	["Barkskin"] = {
		ICON = 'Spell_Nature_StoneClawTotem',
		DURATION = 15,
	},
	["Tiger's Fury"] = {
		ICON = 'Ability_Mount_JungleTiger',
		DURATION = 6,
	},
	["Deterrence"] = {
		ICON = 'Ability_Whirlwind',
		DURATION = 10,
	},
	["Rapid Fire"] = {
		ICON = 'Ability_Hunter_RunningShot',
		DURATION = 15,
	},
	["Divine Shield"] = {
		ICON = 'Spell_Holy_DivineIntervention',
		DURATION = 12,
	},
	["Blessing of Protection"] = {
		ICON = 'Spell_Holy_SealOfProtection',
		DURATION = 10,
	},
	["Blessing of Freedom"] = {
		ICON = 'Spell_Holy_SealOfValor',
		DURATION = 10,
	},
	["Sacrifice"] = {
		ICON = 'Spell_Shadow_SacrificialShield',
		DURATION = 30,
	},
	["Berserker Rage"] = {
		ICON = 'Spell_Nature_AncestralGuardian',
		DURATION = 10,
	},
	["Bloodrage"] = {
		ICON = 'Ability_Racial_BloodRage',
		DURATION = 10,
	},
	["Sweeping Strikes"] = {
		ICON = 'Ability_Rogue_SliceDice',
		DURATION = 20,
	},
	["Last Stand"] = {
		ICON = 'Spell_Holy_AshesToAshes',
		DURATION = 20,
	},
	["Retaliation"] = {
		ICON = 'Ability_Warrior_Challange',
		DURATION = 15,
	},
	["Shield Wall"] = {
		ICON = 'Ability_Warrior_ShieldWall',
		DURATION = 10,
	},
	["Recklessness"] = {
		ICON = 'Ability_CriticalStrike',
		DURATION = 15,
	},
	["Death Wish"] = {
		ICON = 'Spell_Shadow_DeathPact',
		DURATION = 30,
	},
	["Will of the Forsaken"] = {
		ICON = 'Spell_Shadow_RaiseDead',
		DURATION = 5,
	},
	["Perception"] = {
		ICON = 'Spell_Nature_Sleep',
		DURATION = 20,
	},
}

local EMPTY = {}

local buffs = {}

local handlers = {}
do
	local f = CreateFrame'Frame'
	f:SetScript('OnEvent', function()
		handlers[event](this)
	end)
	for _, event in {
		'PLAYER_LOGIN',
		'CHAT_MSG_COMBAT_HONOR_GAIN', 'CHAT_MSG_COMBAT_HOSTILE_DEATH',
		'CHAT_MSG_SPELL_AURA_GONE_OTHER', 'CHAT_MSG_SPELL_BREAK_AURA',
		'CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS',
	} do f:RegisterEvent(event) end
end

local SPOOFED_UNIT_AURA

do
	local UNIT_AURA = {}
	function SPOOFED_UNIT_AURA()
		for handler in UNIT_AURA do
			local saved_event, saved_arg1 = event, arg1
			event, arg1 = 'UNIT_AURA', 'target'
			handler()
			event, arg1 = saved_event, saved_arg1
		end
	end
	function handlers.PLAYER_LOGIN()
		local f
		while true do
			f = EnumerateFrames(f)
			if not f then
				break
			end
			local handler = f.GetScript and f:GetScript'OnEvent'
			if handler then
				f:SetScript('OnEvent', function()
					if event == 'UNIT_AURA' then
						UNIT_AURA[handler] = true
					end
					return handler()
				end)
				do
					local orig = f.RegisterEvent
					function f:RegisterEvent(event)
						if event == 'UNIT_AURA' then
							UNIT_AURA[handler] = true
						end
						return orig(self, event)
					end
				end
				do
					local orig = f.UnregisterEvent
					function f:UnregisterEvent(event)
						if event == 'UNIT_AURA' then
							UNIT_AURA[handler] = nil
						end
						return orig(self, event)
					end
				end
			end
		end
	end
end

do
	local orig = UnitBuff
	function UnitBuff(unitid, index)
		local offset = 0
		while orig('target', offset + 1) do
			offset = offset + 1
		end
		if unitid == 'target' and UnitIsEnemy('target', 'player') then
			local icon = ((buffs[UnitName'target'] or EMPTY)[index - offset] or EMPTY).icon
			if icon then
				return [[Interface\Icons\]] .. icon, 1
			end
		else
			return orig(unitid, index)
		end
	end
end

local function updateBuffs(unit)
	if UnitName'target' == unit then
		SPOOFED_UNIT_AURA()
	end
end

local function removeBuff(unit, name)
	for i = getn(buffs[unit] or EMPTY), 1, -1 do
		if BUFFS[name] and buffs[unit][i].icon == BUFFS[name].ICON then
			tremove(buffs[unit], i)
		end
	end
end

CreateFrame'Frame':SetScript('OnUpdate', function()
	local removed
	for unit, unitBuffs in buffs do
		for i = getn(unitBuffs), 1, -1 do
			if GetTime() > unitBuffs[i].expiration then
				tremove(unitBuffs, i)
				removed = true
			end
		end
		if removed then
			updateBuffs(unit)
		end		
	end
end)

function handlers.CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS()
	for unit, buff in string.gfind(arg1, '(.+) gains (.+)%.') do
		if BUFFS[buff] then
			removeBuff(unit, buff)
			buffs[unit] = buffs[unit] or {}
			tinsert(buffs[unit], {
				icon = BUFFS[buff].ICON,
				expiration = GetTime() + BUFFS[buff].DURATION
			})
			updateBuffs(unit)
		end
	end
end

function handlers.CHAT_MSG_SPELL_AURA_GONE_OTHER()
	for effect, unit in string.gfind(arg1, '(.+) fades from (.+)%.') do
		removeBuff(unit, effect)
		updateBuffs(unit)
	end
end

function handlers.CHAT_MSG_SPELL_BREAK_AURA()
	for unit, effect in string.gfind(arg1, "(.+)'s (.+) is removed%.") do
		removeBuff(unit, effect)
		updateBuffs(unit)
	end
end

function handlers.CHAT_MSG_COMBAT_HOSTILE_DEATH()
	for unit in string.gfind(arg1, '(.+) dies') do
		buffs[unit] = nil
		updateBuffs(unit)
	end
end

function handlers.CHAT_MSG_COMBAT_HONOR_GAIN()
	for unit in string.gfind(arg1, '(.+) dies') do
		buffs[unit] = nil
		updateBuffs(unit)
	end
end