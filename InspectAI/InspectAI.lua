--------------------------------------------------------------------------------
-- InspectAI (c) 2014 by Siarkowy
-- Released under the terms of BSD 2.0 license.
--------------------------------------------------------------------------------

local EAI = CreateFrame("Frame", "InspectAI")

local concat = table.concat
local format = format
local pairs = pairs
local tinsert = tinsert
local tonumber = tonumber
local type = type

local tmp = {}
local multi_option = {
    __call = function(t, par)
        for k in pairs(tmp) do tmp[k] = nil end
        for k, v in pairs(t) do
            if bit.band(k, par) > 0 then
                tinsert(tmp, v)
            end
        end
        local r = concat(tmp, "|")
        return r ~= "" and r or NONE
    end
}

local function tm(d)
    d = tonumber(d)

    if d >= 60000 then return format(d % 60000 == 0 and "%dm" or "%.1fm", d/60000)
    else return format(d % 1000 == 0 and "%ds" or "%.1fs", d/1000) end
end

local cast_flags = setmetatable({
    [0x01] = "IntrPrev",
    [0x02] = "Trig",
    [0x04] = "Force",
    [0x08] = "NoMeleeOOM",
    [0x10] = "ForceSelf",
    [0x20] = "AuraMissing"
}, multi_option)

local cast_targets = {
    "Target", -- 1
    "SecondPlayer", -- 2
    "LastPlayer", -- 3
    "RandomPlayer", -- 4
    "RandomPlayerNot1st", -- 5
    "Invoker", -- 6
    "TargetOrPet", -- 7
    "AnySecond", -- 8
    "AnyLast", -- 9
    "AnyRandom", -- 10
    "AnyNot1st", -- 11
    "InvokerNotPlayer", -- 12
    "Null", -- 13
    [0] = "Self"
}

local events = {
    function(a,b,c,d) return format("Every OOC %s-%s %s-%s", tm(a), tm(b), tm(c), tm(d)) end, -- 1
    "HP %d>%d%% rpt %d-%d%%", -- 2
    "Mana %d>%d%% rpt %d-%d%%", -- 3
    "Aggro", -- 4
    "Kill %d-%d", -- 5
    "Death", -- 6
    "Evade", -- 7
    function(a,b,c,d) return format("SpellHit spell %s <%d> school %d rpt %d-%d", GetSpellLink(a) or UNKNOWN, a, b, c, d) end, -- 8
    "Range %d-%dyd rpt %d-%d", -- 9
    "OocLos NoHostile %d MaxRange %d rpt %d-%d", -- 10
    "Spawned cond %d val %d", -- 11
    "TargetHP %d>%d%% rpt %d-%d%%", -- 12
    "TargetCasting rpt %d-%d", -- 13
    "FriendlyHP hpDeficit %d radius %d rpt %d-%d%%", -- 14
    "FriendlyIsCC dispelType %d radius %d rpt %d-%d", -- 15
    function(a,b,c,d) return format("FriendlyMissingBuff spell %s <%d> radius %d rpt %d-%d", GetSpellLink(a) or UNKNOWN, a, b, c, d) end, -- 16
    "SummonedUnit creature %d rpt %d-%d", -- 17
    "TargetMana %d>%d%% rpt %d-%d%%", -- 18
    "QuestAccept %d", -- 19
    "QuestComplete %d", -- 20
    "ReachedHome", -- 21
    "ReceiveEmote emoteId %d cond %d val1 %d val2 %d", -- 22
    function(a,b,c,d) return format("Buffed spell %s <%d> x%d rpt %d-%d", GetSpellLink(a) or UNKNOWN, a, b, c, d) end, -- 23
    function(a,b,c,d) return format("TargetBuffed spell %s <%d> x%d rpt %d-%d", GetSpellLink(a) or UNKNOWN, a, b, c, d) end, -- 24
    "TrinityReset", --35
    [0] = function(a,b,c,d) return format("Every %s %s %s %s", tm(a), tm(b), tm(c), tm(d)) end -- 0
}

local actions = {
    "Text %d %d %d", -- 1
    "SetFaction %d", -- 2
    "Morph entry %d model %d", -- 3
    "Sound %d", -- 4
    "Emote %d", -- 5
    "RandomSay %d %d %d", -- 6
    "RandomYell %d %d %d", -- 7
    "RandomTextEmote %d %d %d", -- 8
    "RandomSound %d %d %d", -- 9
    "RandomEmote %d %d %d", -- 10
    function(a,b,c) return format("Cast %s <%d> on %s flags %s", GetSpellLink(a) or UNKNOWN, a, cast_targets[tonumber(b)] or b, cast_flags(c)) end, -- 11
    "Summon creature %d at %d for %dms", -- 12
    "ThreatSingle %d%% on %d", -- 13
    "ThreatAll %d%%", -- 14
    function(a,b,c) return format("QuestEvent quest %d target %s", a, cast_targets[tonumber(b)]) end, -- 15
    function(a,b,c) return format("CastEvent quest %d spell %s <%d> target %s", a, GetSpellLink(b) or UNKNOWN, b, cast_targets[tonumber(c)]) end, -- 16
    function(a,b,c) return format("SetUnitFieldFlag %d to %d for %s", a, b, cast_targets[tonumber(c)]) end, -- 17
    function(a,b,c) return format("SetUnitFlag flags %d target %s", a, cast_targets[tonumber(b)]) end, -- 18
    function(a,b,c) return format("RemoveUnitFlag flags %d target %s", a, cast_targets[tonumber(b)]) end, -- 19
    "AutoAttack state %d", -- 20
    "CombatMovement %d", -- 21
    "SetPhase %d", -- 22
    "IncPhase %d", -- 23
    "Evade", -- 24
    "FleeForAssist", -- 25
    "QuestEventAll %d", -- 26
    function(a,b,c) return format("CastEventAll creature %d spell %s <%d>", a, GetSpellLink(b) or UNKNOWN, b) end, -- 27
    function(a,b,c) return format("RemoveAurasFromSpell target %s spell %s <%d>", cast_targets[tonumber(a)], GetSpellLink(b) or UNKNOWN, b) end, -- 28
    "RangedMovement %dyd angle %d", -- 29
    "RandPhase %d %d %d", -- 30
    "RandPhaseRange %d-%d", -- 31
    function(a,b,c) return format("SummonID creature %d target %s spawnId %d", a, cast_targets[tonumber(b)], c) end, -- 32
    function(a,b,c) return format("KilledMonster creature %d target %s", a, cast_targets[tonumber(b)]) end, -- 33
    "SetInstData field %d data %d", -- 34
    function(a,b,c) return format("SetInstData64 field %d target %s", a, cast_targets[tonumber(b)]) end, -- 35
    "UpdateTemplate entry %d team %d", -- 36
    "Die", -- 37
    "ZoneCombatPulse", -- 38
    "CallForHelp %dyd", -- 39
    "SetSheath %d", -- 40
    "ForceDespawn", -- 41
    "SetInvincibilityHpLevel minhp %d flatOrPerc %d", -- 42
    "RemoveCorpse", -- 43
    function(a,b,c) return format("CastGUID spell %s <%d> targetGuid %s flags %s", GetSpellLink(a) or UNKNOWN, a, b, cast_flags(c)) end, -- 44
    "CombatStop", -- 45
    "CheckThr", -- 46

    "SetPhaseMask %d %d %d", -- 97
    "SetStandState %d", -- 98
    "MoveRandomPoint", -- 99
    "SetVisibility %d", -- 100
    "SetActive %d", -- 101
    "SetReactState %d", -- 102
    "AttackStartPulse %dyd", -- 103
    "SummonGO gobj %d despTime %dms", -- 104

    [0] = "None"
}

function EAI:Printf(...)
    DEFAULT_CHAT_FRAME:AddMessage("[EAI] " .. format(...), 0, 1, 1)
end

function EAI:GetFormattedEvent(id, ...)
    id = tonumber(id)

    local fmt = events[id]
    return fmt and ((type(fmt) == "function") and fmt(...) or format(fmt, ...)) or format("E%d %d, %d, %d, %d", id, ...)
end

function EAI:GetFormattedAction(id, ...)
    id = tonumber(id)

    if id > 0 then
        local fmt = actions[id]
        return fmt and ((type(fmt) == "function") and fmt(...) or format(fmt, ...)) or format("A%d %d, %d, %d", id, ...)
    end
end

local info = {}
EAI:SetScript("OnEvent", function(self, event, prefix, msg, distr, unit)
    if prefix ~= "EAI" then return end

    if self.raw then
        return self:Print("%s || %s", unit, msg)
    end

    local e, a1, a2, a3 = strsplit(" ", msg)
    local id, phase, type, par1, par2, par3, par4 = select(2, strsplit(":", e))

    a1 = self:GetFormattedAction(select(2, strsplit(":", a1)))
    a2 = self:GetFormattedAction(select(2, strsplit(":", a2)))
    a3 = self:GetFormattedAction(select(2, strsplit(":", a3)))

    for k in pairs(info) do info[k] = nil end
    if a1 then tinsert(info, a1) end
    if a2 then tinsert(info, a2) end
    if a3 then tinsert(info, a3) end

    self:Printf("%s p:%d || %s || %s || #%s", unit, phase, self:GetFormattedEvent(type, par1, par2, par3, par4), concat(info, " || "), id)
end)

EAI:RegisterEvent("CHAT_MSG_ADDON")
