local Gladius = Gladius;
if not Gladius then
	DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires Gladius", "VoiceAlerts"))
end

local L = Gladius.L
local highestRankWyvernSting = 49012;
local bit_bor = _G.bit.bor;
local bit_band = _G.bit.band;
local config;
local version = 1;

local Alerts = Gladius:NewModule("Alerts", false, false, {
	alerts = {
	}
});
Alerts = LibStub("AceTimer-3.0"):Embed(Alerts);

local alertLookup = {};
local spellList= {
	["Sap"] = GetSpellInfo(6770),
	["Polymorph"] = GetSpellInfo(118),
	["Cyclone"] = GetSpellInfo(33786),
	["Freezing Trap Effect"] = GetSpellInfo(3355),
	["Psychic Scream"] = GetSpellInfo(8122),
	["Fear"] = GetSpellInfo(5782),
	["Howl of Terror"] = GetSpellInfo(5484),
	["Seduction"] = GetSpellInfo(6358),
	["Blind"] = GetSpellInfo(2094),
	["Scatter Shot"] = GetSpellInfo(19503),
	["Death Coil"] = GetSpellInfo(6789),
	["Intimidating Shout"] = GetSpellInfo(5246),
	["Entangling Roots"] = GetSpellInfo(339),
	["Gouge"] = GetSpellInfo(1776),
	["Frost Nova"] = GetSpellInfo(122),
	["Hungering Cold"] = GetSpellInfo(49203),
	["Hex"] = GetSpellInfo(51514),
	["PvP Trinket"] = GetSpellInfo(42292),
	["Hibernate"] = GetSpellInfo(2637),
	["Wyvern Sting"] = GetSpellInfo(19386),
	["Repentance"] = GetSpellInfo(20066),
	["Kidney Shot"] = GetSpellInfo(408),
	["Bash"] = GetSpellInfo(5211),
	["Maim"] = GetSpellInfo(22570),
	["Hammer of Justice"] = GetSpellInfo(853),
	["Shadowfury"] = GetSpellInfo(30283),
	["Concussion Blow"] = GetSpellInfo(12809),
	["Charge Stun"] = GetSpellInfo(7922),
	["Intercept"] = GetSpellInfo(30151),
	["War Stomp"] = GetSpellInfo(20549),
	["Cheap Shot"] = GetSpellInfo(1833),
	["Pounce"] = GetSpellInfo(9005),
	["Grounding Totem"] = GetSpellInfo(8177),
	["Tremor Totem"] = GetSpellInfo(8143),
	["Drink"] = GetSpellInfo(43183),
	["Ice Block"] = GetSpellInfo(45438),
	["Divine Protection"] = GetSpellInfo(498),
	["Divine Shield"] = GetSpellInfo(642),
	["Hand of Protection"] = GetSpellInfo(1022),
	["Pain Suppression"] = GetSpellInfo(33206),
	["Silenced - Improved Counterspell"] = GetSpellInfo(55021),
	["Silence"] = GetSpellInfo(15487),
	["Spell Lock"] = GetSpellInfo(19647),
	["Silenced - Improved Kick"] = GetSpellInfo(18425),
	["Garrote - Silence"] = GetSpellInfo(1330),
	["Strangulate"] = GetSpellInfo(47476),
	["Kick"] = GetSpellInfo(1766),
	["Counterspell"] = GetSpellInfo(2139),
	["Wind Shear"] = GetSpellInfo(57994),
	--["Shield Bash"] = GetSpellInfo(72),
	["Pummel"] = GetSpellInfo(6552),
	--["Feral Charge - Bear"] = GetSpellInfo(16979),
	["Throwing Specialization"] = GetSpellInfo(51680),
	["Mind Freeze"] = GetSpellInfo(47528),
	["Earth Shield"] = GetSpellInfo(974),
	["Leader of the Pack"] = GetSpellInfo(17007),
	["Moonkin Aura"] = GetSpellInfo(24907),
	["Soul Link"] = GetSpellInfo(19028),
	["Shadowform"] = GetSpellInfo(15473),
	["Trueshot Aura"] = GetSpellInfo(19506),
	["Ice Barrier"] = GetSpellInfo(11426),
	["Combustion"] = GetSpellInfo(11129),
	["Tree of Life"] = GetSpellInfo(65139),
	["Divine Spirit"] = GetSpellInfo(14752),
	["Blessing of Sanctuary"] = GetSpellInfo(20911),
	["Bone Shield"] = GetSpellInfo(49222),
	["Gnaw"] = GetSpellInfo(47481),
	["Resurrection"] = GetSpellInfo(2006),
	["Revive"] = GetSpellInfo(50769),
	["Revive Pet"] = GetSpellInfo(982),
	["Redemption"] = GetSpellInfo(7328),
	["Ancestral Spirit"] = GetSpellInfo(2008),
	["Innervate"] = GetSpellInfo(29166),
	["Disarm"] = GetSpellInfo(676),
	["Dismantle"] = GetSpellInfo(51722),
	["Chimera Shot - Scorpid"] = GetSpellInfo(53359),
	["Silenced - Shield of the Templar"] = GetSpellInfo(63529),
	["Silenced - Gag Order"] = GetSpellInfo(18498),
	["Arcane Torrent"] = GetSpellInfo(28730),
	["Shield Wall"] = GetSpellInfo(871),
	["Mark of the Wild"] = GetSpellInfo(1126),
	["Sleep"] = GetSpellInfo(700),
	["Shockwave"] = GetSpellInfo(46968),
	["Deep Freeze"] = GetSpellInfo(44572),
	["Freezing Arrow Effect"] = GetSpellInfo(60210),
	["Silencing Shot"] = GetSpellInfo(34490),
	["Nether Shock"] = GetSpellInfo(35334),
	["Snatch"] = GetSpellInfo(91644),
	["Psychic Horror"] = GetSpellInfo(64044),
	["Scare Beast"] = GetSpellInfo(1513),
	["Ravage"] = GetSpellInfo(6785),
	["Sonic Blast"] = GetSpellInfo(50519),
	["Demon Charge"] = GetSpellInfo(54785),
	["Glyph of Death Grip"] = GetSpellInfo(58628),
	["Impact"] = GetSpellInfo(12358),
	["Freeze"] = GetSpellInfo(33395),
	["Banish"] = GetSpellInfo(710),
	["Will of the Forsaken"] = GetSpellInfo(7744),
	["Every Man for Himself"] = GetSpellInfo(59752),
	["Clench"] = GetSpellInfo(50541),
	["Throwdown"] = GetSpellInfo(85388),
	["Solar Beam"] = GetSpellInfo(78675),
	["Ring of Frost"] = GetSpellInfo(82676),
	["Skull Bash"] = GetSpellInfo(80964),
	["Survival Instincts"] = GetSpellInfo(61336),
	["Dispersion"] = GetSpellInfo(47585),
};

-- CC effects
local effect = {
	[spellList["Sap"]] = true,
	[spellList["Polymorph"]] = true,
	[spellList["Cyclone"]] = true,
	[spellList["Freezing Trap Effect"]] = true,
	[spellList["Psychic Scream"]] = true,
	[spellList["Fear"]] = true,
	[spellList["Howl of Terror"]] = true,
	[spellList["Seduction"]] = true,
	[spellList["Blind"]] = true,
	[spellList["Scatter Shot"]] = true,
	[spellList["Death Coil"]] = true,
	[spellList["Intimidating Shout"]] = true,
	[spellList["Entangling Roots"]] = true,
	[spellList["Frost Nova"]] = true,
	[spellList["Hungering Cold"]] = true,
	[spellList["Hex"]] = true,
	[spellList["Hibernate"]] = true,
	[spellList["Wyvern Sting"]] = true,
	[spellList["Repentance"]] = true,
	[spellList["Scare Beast"]] = true,
	[spellList["Ring of Frost"]] = true,
};

local invulns = {
	[spellList["Ice Block"]] = true,
	[spellList["Divine Protection"]] = true,
	[spellList["Divine Shield"]] = true,
	[spellList["Hand of Protection"]] = true,
	[spellList["Pain Suppression"]] = true,
	[spellList["Shield Wall"]] = true,
	[spellList["Survival Instincts"]] = true,
	[spellList["Dispersion"]] = true,
};

-- silences and their durations
local silences = {
	[spellList["Silenced - Improved Counterspell"]] = 4,
	[spellList["Silence"]] = 5,
	[spellList["Spell Lock"]] = 3,
	[spellList["Silenced - Improved Kick"]] = 2,
	[spellList["Garrote - Silence"]] = 3,
	[spellList["Strangulate"]] = 5,
	[spellList["Silenced - Shield of the Templar"]] = 3,
	[spellList["Silenced - Gag Order"]] = 3,
	[spellList["Arcane Torrent"]] = 2,
	[spellList["Silencing Shot"]] = 3,
	[spellList["Nether Shock"]] = 2,
	[spellList["Solar Beam"]] = 10,
};

-- school lock interrupts and their durations
local interrupts = {
	[spellList["Kick"]] = 5,
	[spellList["Counterspell"]] = 8,
	[spellList["Spell Lock"]] = 6,
	[spellList["Wind Shear"]] = 2,
	[spellList["Pummel"]] = 4,
	[spellList["Throwing Specialization"]] = 3,
	[spellList["Mind Freeze"]] = 4,
	[spellList["Skull Bash"]] = 5,
};

local resurrections = {
	[spellList["Resurrection"]] = true,
	[spellList["Revive"]] = true,
	[spellList["Revive Pet"]] = true,
	[spellList["Redemption"]] = true,
	[spellList["Ancestral Spirit"]] = true,
};

local effectAudio = {
	[spellList["Sap"]] = "Sap",
	[spellList["Polymorph"]] = "Polymorph",
	[spellList["Cyclone"]] = "Cyclone",
	[spellList["Freezing Trap Effect"]] = "Freezing_Trap",
	[spellList["Psychic Scream"]] = "Fear",
	[spellList["Fear"]] = "Fear",
	[spellList["Howl of Terror"]] = "Fear",
	[spellList["Seduction"]] = "Seduction",
	[spellList["Blind"]] = "Blind",
	[spellList["Intimidating Shout"]] = "Fear",
	[spellList["Entangling Roots"]] = "Root",
	[spellList["Frost Nova"]] = "Root",
	[spellList["Freeze"]] = "Root",
	[spellList["Hungering Cold"]] = "Hungering_Cold",
	[spellList["Hex"]] = "Hex",
	[spellList["Hibernate"]] = "Sleep",
	[spellList["Wyvern Sting"]] = "Sleep",
	[spellList["Repentance"]] = "Repentance",
	[spellList["Scare Beast"]] = "Fear",
};

local voiceDurations = {
	["Partner"] = .5,
	["School_Locked"] = 1,
	["Silenced"] = .7,
	["On"] = .3,
	["Cyclone"] = .7,
	["Blind"] = .6,
	["PRIEST"] = .6,
	["DRUID"] = .6,
	["SHAMAN"] = .6,
	["PALADIN"] = .6,
	["WARRIOR"] = .6,
	["ROGUE"] = .6,
	["DEATHKNIGHT"] = .6,
	["WARLOCK"] = .6,
	["MAGE"] = .6,
	["HUNTER"] = .6,
	["Hex"] = .5,
	["Fear"] = .5,
	["Died"] = .5,
	["Down"] = .5,
	["Low"] = .5,
	["Polymorph"] = .8,
	["Trinket_Used"] = 1,
	["Trinket_Ready"] = 1,
	["Repentance"] = 1,
	["Seduction"] = 1,
	["Sleep"] = .5,
	["Root"] = .5,
	["Sap"] = .5,
	["Partner_CCed"] = 1,
	["Is_Drinking"] = 1,
	["Resurrecting"] = 1,
	["Hungering_Cold"] = 1,
	["Freezing_Trap"] = 1,
	["Casting"] = .5,
	["Wotf_Used"] = 1,
	["Wotf_Ready"] = 1,
	["Wotf"] = 1,
	["Trinket"] = .4,
	["Used"] = .3,
	["Ready"] = .3,
};

local DRData = LibStub("DRData-1.0");

local schoolLock = {
	["WARRIOR"] = 4,
	["MAGE"] = 8,
	["ROGUE"] = 5,
	["DRUID"] = 4,
	["HUNTER"] = 0,
	["SHAMAN"] = 2,
	["PRIEST"] = 0,
	["WARLOCK"] = 6,
	["PALADIN"] = 0,
	["DEATHKNIGHT"] = 4,
	["pet"] = 6;
};

local alerts = {
	{
		name = "drinking",
		func = function(dstGUID)
			return 1;
		end,
		soundEffect = "potion.ogg",
		speech = "$class Is_Drinking",
	},
	{
		name = "trinketUsed",
		func = function(guid)
			return 0;
		end,
		soundEffect = "portalenter.ogg",
		speech = "$class Trinket Used",
	},
	{
		name = "trinketAvailable",
		func = function(dstGUID)
			return 1;
		end,
		soundEffect = "amplifydamage.ogg",
		speech = "$class Trinket Ready",
	},
	{
		name = "resurrecting",
		combatEvent = "SPELL_CAST_START",
		objectReaction = "Hostile",
		func = function(srcGUID, dstGUID, spell)
			if ( resurrections[spell] and Alerts.opponents[srcGUID] ) then
				return 1
			end
		end,
		soundEffect = "nukesilo.ogg",
		speech = "$class Resurrecting",
	},
	{
		name = "lowHealth",
		func = function(guid, hp, maxhp)
			if ( not Alerts.opponents[guid] ) then
				return
			end
			if ( hp > 0) then
				local hppct = 100 / maxhp * hp;
				local threshold = Gladius.db["announcements"]["healthThreshold"] or 40;
				-- if health below threshold
				if ( hppct <= threshold ) then
					return 0;
				end
			end
		end,
		soundEffect = "gogogo.ogg",
		speech = "$class Low",
	},
	{
		name = "opponentDeaths",
		func = function(guid)
			if ( Alerts.opponents[guid] ) then
				return 0;
			end
		end,
		soundEffect = "outstanding.ogg",
		speech = "$class Died",
	},
	{
		name = "partnerCCs",
		combatEvent = "SPELL_AURA_APPLIED",
		objectReaction = "Hostile",
		buffType = "Debuff",
		func = function(srcGUID, dstGUID, spell)
			if ( Alerts.opponents[dstGUID] and Alerts.party[srcGUID] and effectAudio[spell] ) then
				return 0
			end
		end,
		soundEffect = "Miopia1.ogg",
		speech = "$spell On $class",
	},
	{
		name = "partnerCastingCC",
		combatEvent = "SPELL_CAST_START",
		objectReaction = "Friendly",
		func = function(srcGUID, dstGUID, spell)
			if ( Alerts.party[srcGUID] and effectAudio[spell] ) then
				return 0;
			end
		end,
		soundEffect = "halfmeteorlaunch.ogg",
		speech = "Casting $spell",
	},
	{
		name = "ccsOnPartner",
		combatEvent = "SPELL_AURA_APPLIED",
		objectReaction = "Friendly",
		buffType = "Debuff",
		func = function(srcGUID, dstGUID, spell)
			if ( Alerts.party[dstGUID] and effectAudio[spell] and not ( config["ccsOnPartner"]["excludes"] and config["ccsOnPartner"]["excludes"][spell] )) then
				return 1
			end
		end,
		soundEffect = "lockdown.ogg",
		speech = "$spell On Partner",
		excludes = {
			[spellList["Sap"]] = spellList["Sap"],
			[spellList["Polymorph"]] = spellList["Polymorph"],
			[spellList["Cyclone"]] = spellList["Cyclone"],
			[spellList["Freezing Trap Effect"]] = spellList["Freezing Trap Effect"],
			[spellList["Psychic Scream"]] = spellList["Psychic Scream"],
			[spellList["Fear"]] = spellList["Fear"],
			[spellList["Howl of Terror"]] = spellList["Howl of Terror"],
			[spellList["Seduction"]] = spellList["Seduction"],
			[spellList["Blind"]] = spellList["Blind"],
			[spellList["Intimidating Shout"]] = spellList["Intimidating Shout"],
			[spellList["Entangling Roots"]] = spellList["Entangling Roots"],
			[spellList["Frost Nova"]] = spellList["Frost Nova"],
			[spellList["Hungering Cold"]] = spellList["Hungering Cold"],
			[spellList["Hex"]] = spellList["Hex"],
			[spellList["Hibernate"]] = spellList["Hibernate"],
			[spellList["Wyvern Sting"]] = spellList["Wyvern Sting"],
			[spellList["Repentance"]] = spellList["Repentance"],
			[spellList["Freeze"]] = spellList["Freeze"],
			[spellList["Scare Beast"]] = spellList["Scare Beast"],
			[spellList["Ring of Frost"]] = spellList["Ring of Frost"],
		},
	},
	{
		name = "drExpiration",
		func = function(type, guid)
			if ( not (DRData:GetCategoryName(type)) ) then
				return 0;
			end
		end,
		soundEffect = "BEEPMETA.ogg",
	},
	{
		name = "drExpiration2",
		func = function(type, guid)
			if ( not (DRData:GetCategoryName(type))) then
				return 0
			end
		end,
		soundEffect = "pop.ogg",
	},
	{
		name = "invulns",
		combatEvent = "SPELL_AURA_APPLIED",
		objectReaction = "Hostile",
		buffType = "Buff",
		func = function(srcGUID, dstGUID, spell)
			if (Alerts.opponents[dstGUID] and invulns[spell] and not (config["invulns"]["excludes"] and config["invulns"]["excludes"][spell] )) then
				return 1;
			end
		end,
		soundEffect = "shield.ogg",
		excludes = {
			[spellList["Ice Block"]] = spellList["Ice Block"],
			[spellList["Divine Protection"]] = spellList["Divine Protection"],
			[spellList["Divine Shield"]] = spellList["Divine Shield"],
			[spellList["Hand of Protection"]] = spellList["Hand of Protection"],
			[spellList["Pain Suppression"]] = spellList["Pain Suppression"],
			[spellList["Shield Wall"]] = spellList["Shield Wall"],
			[spellList["Survival Instincts"]] = spellList["Survival Instincts"],
			[spellList["Dispersion"]] = spellList["Dispersion"],
		},
	},
	{
		name = "hostileSchoolLocks",
		combatEvent = "SPELL_INTERRUPT",
		objectReaction = "Hostile",
		func = function(srcGUID, dstGUID, spell, duration)
			if ( Alerts.opponents[dstGUID] ) then

				local caster = Alerts.party[srcGUID] or Alerts.partyPets[srcGUID];
				if ( not caster or (config["hostileSchoolLocks"]["excludes"] and config["hostileSchoolLocks"]["excludes"][spell]) ) then
					return
				end

				if ( not duration ) then
					duration = schoolLock[caster.class];
				end

				if ( Alerts.opponents[dstGUID].class == "PALADIN" ) then
					duration = duration *.7;
				end
				
				return 0;
			end
		end,
		soundEffect = "terranerror1.ogg",
		speech = "$class School_Locked",
		excludes = {
			[spellList["Kick"]] = spellList["Kick"],
			[spellList["Counterspell"]] = spellList["Counterspell"],
			[spellList["Spell Lock"]] = spellList["Spell Lock"],
			[spellList["Wind Shear"]] = spellList["Wind Shear"],
			--[spellList["Shield Bash"]] = spellList["Shield Bash"],
			[spellList["Pummel"]] = spellList["Pummel"],
			--[spellList["Feral Charge - Bear"]] = spellList["Feral Charge - Bear"],
			[spellList["Throwing Specialization"]] = spellList["Throwing Specialization"],
			[spellList["Mind Freeze"]] = spellList["Mind Freeze"],
			[spellList["Skull Bash"]] = spellList["Skull Bash"],
		},
	},
	{
		name = "hostileSilences",
		combatEvent = "SPELL_AURA_APPLIED",
		objectReaction = "Hostile",
		buffType = "Debuff",
		func = function(srcGUID, dstGUID, spell)
			if ( Alerts.opponents[dstGUID] and silences[spell] ) then

				if ( config["hostileSilences"]["excludes"] and config["hostileSilences"]["excludes"][spell] ) then
					return
				end

				return  0, silences[spell];
			end
		end,
		soundEffect = "terranerror1.ogg",
		speech = "$class Silenced",
		excludes = {
			[spellList["Silenced - Improved Counterspell"]] = spellList["Silenced - Improved Counterspell"],
			[spellList["Silence"]] = spellList["Silence"],
			[spellList["Spell Lock"]] = spellList["Spell Lock"],
			[spellList["Silenced - Improved Kick"]] = spellList["Silenced - Improved Kick"],
			[spellList["Garrote - Silence"]] = spellList["Garrote - Silence"],
			[spellList["Strangulate"]] = spellList["Strangulate"],
			[spellList["Silenced - Shield of the Templar"]] = spellList["Silenced - Shield of the Templar"],
			[spellList["Silenced - Gag Order"]] = spellList["Silenced - Gag Order"],
			[spellList["Arcane Torrent"]] = spellList["Arcane Torrent"],
			[spellList["Silencing Shot"]] = spellList["Silencing Shot"],
			[spellList["Nether Shock"]] = spellList["Nether Shock"],
			[spellList["Solar Beam"]] = spellList["Solar Beam"],
		},
	},
	{
		name = "friendlySilences",
		combatEvent = "SPELL_AURA_APPLIED",
		objectReaction = "Friendly",
		buffType = "Debuff",
		func = function(srcGUID, dstGUID, spell)
			if ( Alerts.party[dstGUID] and silences[spell] ) then

				if ( config["friendlySilences"]["excludes"] and config["friendlySilences"]["excludes"][spell] ) then
					return
				end

				return  1, silences[spell];
			end
		end,
		soundEffect = "weaken.ogg",
		speech = "Partner Silenced",
		excludes = {
			[spellList["Silenced - Improved Counterspell"]] = spellList["Silenced - Improved Counterspell"],
			[spellList["Silence"]] = spellList["Silence"],
			[spellList["Spell Lock"]] = spellList["Spell Lock"],
			[spellList["Silenced - Improved Kick"]] = spellList["Silenced - Improved Kick"],
			[spellList["Garrote - Silence"]] = spellList["Garrote - Silence"],
			[spellList["Strangulate"]] = spellList["Strangulate"],
			[spellList["Silenced - Shield of the Templar"]] = spellList["Silenced - Shield of the Templar"],
			[spellList["Silenced - Gag Order"]] = spellList["Silenced - Gag Order"],
			[spellList["Arcane Torrent"]] = spellList["Arcane Torrent"],
			[spellList["Silencing Shot"]] = spellList["Silencing Shot"],
			[spellList["Nether Shock"]] = spellList["Nether Shock"],
			[spellList["Solar Beam"]] = spellList["Solar Beam"],
		},
	},
	{
		name = "friendlySchoolLocks",
		combatEvent = "SPELL_INTERRUPT",
		objectReaction = "Friendly",
		func = function(srcGUID, dstGUID, spell, duration)
			if ( Alerts.party[dstGUID] ) then

				local caster = Alerts.opponents[srcGUID] or Alerts.pets[srcGUID];

				if ( not caster or (config["friendlySchoolLocks"]["excludes"] and config["friendlySchoolLocks"]["excludes"][spell]) ) then
					return
				end
				if ( not duration ) then
					duration = schoolLock[caster.class];
				end

				if ( Alerts.party[dstGUID].class == "PALADIN" ) then
					duration = duration * .7;
				end
				duration = math.ceil(duration);

				return 1, duration;
			end
		end,
		soundEffect = "weaken.ogg",
		speech = "Partner School_Locked",
		excludes = {
			[spellList["Kick"]] = spellList["Kick"],
			[spellList["Counterspell"]] = spellList["Counterspell"],
			[spellList["Spell Lock"]] = spellList["Spell Lock"],
			[spellList["Wind Shear"]] = spellList["Wind Shear"],
			--[spellList["Shield Bash"]] = spellList["Shield Bash"],
			[spellList["Pummel"]] = spellList["Pummel"],
			--[spellList["Feral Charge - Bear"]] = spellList["Feral Charge - Bear"],
			[spellList["Throwing Specialization"]] = spellList["Throwing Specialization"],
			[spellList["Mind Freeze"]] = spellList["Mind Freeze"],
			[spellList["Skull Bash"]] = spellList["Skull Bash"],
		},
	},
	{
		name = "innervateUsed",
		combatEvent = "SPELL_AURA_APPLIED",
		objectReaction = "Hostile",
		buffType = "Buff",
		func = function(srcGUID, dstGUID, spell)
			if ( spell == spellList["Innervate"] and Alerts.opponents[dstGUID] ) then
				return 1;
			end
		end,
		soundEffect = "stimpack.ogg",
	},
	{
		name = "manaTideDropped",
		combatEvent = "SPELL_CAST_START",
		objectReaction = "Hostile",
		func = function(srcGUID, dstGUID, spell)
			if ( spell == spellList["Mana Tide"] ) then
				return 1;
			end
		end,
		soundEffect = "stimpack.ogg",
	},
	{
		name = "gainedBuff",
		combatEvent = "SPELL_AURA_APPLIED",
		objectReaction = "Hostile",
		buffType = "Buff",
		func = function(srcGUID, dstGUID, spell)

			if ( not Alerts.opponents[dstGUID] or (config["gainedBuff"]["excludes"] and config["gainedBuff"]["excludes"][Alerts.opponents[dstGUID].class]) ) then
				return
			end

			if ( config["gainedBuff"]["options"] ) then
				if (	spell == config["gainedBuff"]["options"]["buff1"] or
					spell == config["gainedBuff"]["options"]["buff2"] or
					spell == config["gainedBuff"]["options"]["buff3"]
				) then
					return 1, spell;
				end			
			end
		end,
		soundEffect = "terranunderattack.ogg",
		options = {
			{
				name = "buff1",
				type = "edit box",
				label = "Buff1",
				value = "",
			},
			{
				name = "buff2",
				type = "edit box",
				label = "Buff2",
				value = "",
			},
			{
				name = "buff3",
				type = "edit box",
				label = "Buff3",
				value = "",
			},
		},
		excludes = {
			[LOCALIZED_CLASS_NAMES_MALE["WARRIOR"]] = "WARRIOR",
			[LOCALIZED_CLASS_NAMES_MALE["MAGE"]] = "MAGE",
			[LOCALIZED_CLASS_NAMES_MALE["ROGUE"]] = "ROGUE",
			[LOCALIZED_CLASS_NAMES_MALE["DRUID"]] = "DRUID",
			[LOCALIZED_CLASS_NAMES_MALE["HUNTER"]] = "HUNTER",
			[LOCALIZED_CLASS_NAMES_MALE["SHAMAN"]] = "SHAMAN",
			[LOCALIZED_CLASS_NAMES_MALE["PRIEST"]] = "PRIEST",
			[LOCALIZED_CLASS_NAMES_MALE["WARLOCK"]] = "WARLOCK",
			[LOCALIZED_CLASS_NAMES_MALE["PALADIN"]] = "PALADIN",
			[LOCALIZED_CLASS_NAMES_MALE["DEATHKNIGHT"]] = "DEATHKNIGHT",
		},
	},
	{
		name = "lostBuff",
		func = function(srcGUID, dstGUID, spell)
			if ( not Alerts.opponents[dstGUID] or (config["lostBuff"]["excludes"] and config["lostBuff"]["excludes"][Alerts.opponents[dstGUID].class]) ) then
				return
			end

			if ( config["lostBuff"]["options"] ) then
				if (	spell == config["lostBuff"]["options"]["buff1"] or
					spell == config["lostBuff"]["options"]["buff2"] or
					spell == config["lostBuff"]["options"]["buff3"]
				) then
					return 0, spellList;
				end			
			end
		end,
		soundEffect = "valkyrieappear1.ogg",
			options = {
			{
				name = "buff1",
				type = "edit box",
				label = "Buff1",
				value = "",
			},
			{
				name = "buff2",
				type = "edit box",
				label = "Buff2",
				value = "",
			},
			{
				name = "buff3",
				type = "edit box",
				label = "Buff3",
				value = "",
			},
		},
		excludes = {
			[LOCALIZED_CLASS_NAMES_MALE["WARRIOR"]] = "WARRIOR",
			[LOCALIZED_CLASS_NAMES_MALE["MAGE"]] = "MAGE",
			[LOCALIZED_CLASS_NAMES_MALE["ROGUE"]] = "ROGUE",
			[LOCALIZED_CLASS_NAMES_MALE["DRUID"]] = "DRUID",
			[LOCALIZED_CLASS_NAMES_MALE["HUNTER"]] = "HUNTER",
			[LOCALIZED_CLASS_NAMES_MALE["SHAMAN"]] = "SHAMAN",
			[LOCALIZED_CLASS_NAMES_MALE["PRIEST"]] = "PRIEST",
			[LOCALIZED_CLASS_NAMES_MALE["WARLOCK"]] = "WARLOCK",
			[LOCALIZED_CLASS_NAMES_MALE["PALADIN"]] = "PALADIN",
			[LOCALIZED_CLASS_NAMES_MALE["DEATHKNIGHT"]] = "DEATHKNIGHT",
		},
	},
	{
		name = "gainedDebuff",
		combatEvent = "SPELL_AURA_APPLIED",
		objectReaction = "Hostile",
		buffType = "Debuff",
		func = function(srcGUID, dstGUID, spell)
			if ( not Alerts.opponents[dstGUID] or (config["gainedDebuff"]["excludes"] and config["gainedDebuff"]["excludes"][Alerts.opponents[dstGUID].class]) ) then
				return
			end

			if ( config["gainedDebuff"]["options"] ) then
				if (	spell == config["gainedDebuff"]["options"]["debuff1"] or
					spell == config["gainedDebuff"]["options"]["debuff2"] or
					spell == config["gainedDebuff"]["options"]["debuff3"]
				) then
					return 0, spell
				end			
			end
		end,
		soundEffect = "mind.ogg",
		options = {
			{
				name = "debuff1",
				type = "edit box",
				label = "Debuff1",
				value = "",
			},
			{
				name = "debuff2",
				type = "edit box",
				label = "Debuff2",
				value = "",
			},
			{
				name = "debuff3",
				type = "edit box",
				label = "Debuff3",
				value = "",
			},
		},
		excludes = {
			[LOCALIZED_CLASS_NAMES_MALE["WARRIOR"]] = "WARRIOR",
			[LOCALIZED_CLASS_NAMES_MALE["MAGE"]] = "MAGE",
			[LOCALIZED_CLASS_NAMES_MALE["ROGUE"]] = "ROGUE",
			[LOCALIZED_CLASS_NAMES_MALE["DRUID"]] = "DRUID",
			[LOCALIZED_CLASS_NAMES_MALE["HUNTER"]] = "HUNTER",
			[LOCALIZED_CLASS_NAMES_MALE["SHAMAN"]] = "SHAMAN",
			[LOCALIZED_CLASS_NAMES_MALE["PRIEST"]] = "PRIEST",
			[LOCALIZED_CLASS_NAMES_MALE["WARLOCK"]] = "WARLOCK",
			[LOCALIZED_CLASS_NAMES_MALE["PALADIN"]] = "PALADIN",
			[LOCALIZED_CLASS_NAMES_MALE["DEATHKNIGHT"]] = "DEATHKNIGHT",
		},
	},
	{
		name = "lostDebuff",
		func = function(srcGUID, dstGUID, spell)
			if ( not Alerts.opponents[dstGUID] or (config["lostDebuff"]["excludes"] and config["lostDebuff"]["excludes"][Alerts.opponents[dstGUID].class]) ) then
				return
			end

			if ( config["lostDebuff"]["options"] ) then
				if (	spell == config["lostDebuff"]["options"]["debuff1"] or
					spell == config["lostDebuff"]["options"]["debuff2"] or
					spell == config["lostDebuff"]["options"]["debuff3"]
				) then
					return 1;
				end			
			end
		end,
		soundEffect = "feedback.ogg",
		options = {
			{
				name = "debuff1",
				type = "edit box",
				label = "Debuff1",
				value = "",
			},
			{
				name = "debuff2",
				type = "edit box",
				label = "Debuff2",
				value = "",
			},
			{
				name = "debuff3",
				type = "edit box",
				label = "Debuff3",
				value = "",
			},
		},
		excludes = {
			[LOCALIZED_CLASS_NAMES_MALE["WARRIOR"]] = "WARRIOR",
			[LOCALIZED_CLASS_NAMES_MALE["MAGE"]] = "MAGE",
			[LOCALIZED_CLASS_NAMES_MALE["ROGUE"]] = "ROGUE",
			[LOCALIZED_CLASS_NAMES_MALE["DRUID"]] = "DRUID",
			[LOCALIZED_CLASS_NAMES_MALE["HUNTER"]] = "HUNTER",
			[LOCALIZED_CLASS_NAMES_MALE["SHAMAN"]] = "SHAMAN",
			[LOCALIZED_CLASS_NAMES_MALE["PRIEST"]] = "PRIEST",
			[LOCALIZED_CLASS_NAMES_MALE["WARLOCK"]] = "WARLOCK",
			[LOCALIZED_CLASS_NAMES_MALE["PALADIN"]] = "PALADIN",
			[LOCALIZED_CLASS_NAMES_MALE["DEATHKNIGHT"]] = "DEATHKNIGHT",
		},
	},
	{
		name = "groundingDropped",
		combatEvent = "SPELL_SUMMON",
		objectReaction = "Hostile",
		func = function(id, spell)
			if ( spell == spellList["Grounding Totem"] ) then
				return 1;
			end
		end,
		soundEffect = "spidermineplanted.ogg",
	},
	{
		name = "tremorDropped",
		combatEvent = "SPELL_SUMMON",
		objectReaction = "Hostile",
		func = function(id, spell)
			if ( spell == spellList["Tremor Totem"] ) then
				return 1;
			end
		end,
		soundEffect = "zergplacebuilding.ogg",
	},
	{
		name = "groundingDied",
		func = function(dstName)
			if ( dstName == spellList["Grounding Totem"] ) then
				return 1;
			end
		end,
		soundEffect = "ppwrdown.ogg",
	},
	{
		name = "tremorDied",
		func = function(dstName)
			if ( dstName == spellList["Tremor Totem"] ) then
				return 1;
			end
		end,
		soundEffect = "ppwrdown.ogg",
	},
	{
		name = "wotfUsed",
		func = function(guid)
			return 0	
		end,
		soundEffect = "portalenter.ogg",
		speech = "$class Wotf Used",
	},
	{
		name = "wotfAvailable",
		func = function(dstGUID)
			if ( Alerts.opponents[dstGUID].race == "Scourge" ) then
				return 1;
			end
		end,
		soundEffect = "amplifydamage.ogg",
		speech = "$class Wotf Ready",
	},
};

for index, alert in ipairs(alerts) do
	if ( alert.combatEvent ) then
		if ( not alertLookup[alert.combatEvent] ) then
			alertLookup[alert.combatEvent] = {};
		end
		if ( alert.objectReaction ) then
			if ( not alertLookup[alert.combatEvent][alert.objectReaction] ) then
				alertLookup[alert.combatEvent][alert.objectReaction] = {};
			end
			if ( alert.buffType ) then
				if ( not alertLookup[alert.combatEvent][alert.objectReaction][alert.buffType] ) then
					alertLookup[alert.combatEvent][alert.objectReaction][alert.buffType] = {};
				end
				alertLookup[alert.combatEvent][alert.objectReaction][alert.buffType][alert.name] = alert;
			else
				alertLookup[alert.combatEvent][alert.objectReaction][alert.name] = alert;
			end
		else
			alertLookup[alert.combatEvent][alert.name] = alert;
		end
	end
	alertLookup[alert.name] = alert;
end

function Alerts:OnEnable()
	self.opponents = {};
	self.party = {};
	self.partyPets = {};
	self:RegisterEvent("ARENA_OPPONENT_UPDATE");
	self:RegisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL");
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	self:RegisterEvent("UNIT_HEALTH");

	config = Gladius.db.alerts
	if (not config.version or (config.version and config.version < version)) then
		for _, alert in pairs(alerts) do
			config[alert["name"]] = {
				soundEffect = true,
				speech = true
			}
			if (alert.excludes) then
				config[alert.name]["excludes"] = alert.excludes
			end

			if alert.options then
				local options = {}
				for i, opt in pairs(alert.options) do
					options[opt.name] = opt.value	
				end
				config[alert.name]["options"] = options;
			end
		end
		
		--config.version = version;
	end
end

function Alerts:OnDisable()
	self:UnregisterEvent("ARENA_OPPONENT_UPDATE");
	self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	self:UnregisterEvent("CHAT_MSG_BG_SYSTEM_NEUTRAL");
	self:UnregisterEvent("UNIT_HEALTH");
	self.opponents = {};
	self.party = {};
	self.partyPets = {};
end

function Alerts:Reset()
	self.opponents = {};
	self.party = {};
	self.partyPets = {};
	self.pets = {};
	if self.restTimer then
		self:CancelTimer(self.restTimer, true)
	end
end

function Alerts:CHAT_MSG_BG_SYSTEM_NEUTRAL()
	self:Reset();
	local guid, unit, class;
	for i = 1, 4 do
		unit = "party"..i;
		guid = UnitGUID(unit);
		if ( guid ) then
			_, class = UnitClass(unit);
			self.party[guid] = { class = class, name = UnitName(unit) };
		end

		unit = "partypet"..i;
		guid = UnitGUID(unit);
		if ( guid ) then
			self.partyPets[guid] = { class = "pet", name = UnitName(unit) };
		end
	end
end

function Alerts:UNIT_HEALTH(event, unit)
	local maxhp, hp = UnitHealthMax(unit), UnitHealth(unit);
	local guid = UnitGUID(unit);
	self:Alert("lowHealth", guid, hp, maxhp)
end

function Alerts:ARENA_OPPONENT_UPDATE(event, unit, type)
	if (type == "seen" or type == "destoryed") then
		if (UnitGUID(unit)) then
			self:AddOpponent(unit);
		end

	elseif (type == "unseen") then
		if (UnitGUID(unit)) then
			self:AddOpponent(unit);
		end
	end
end

function Alerts:AddOpponent(unit)
	local guid = UnitGUID(unit);

	if (not guid) then
		return;
	end

	local name = UnitName(unit);

	if (not name or name == "" or name == UNKNOWN) then
		return
	end
	
	if (not self.opponents[guid] and (UnitIsPlayer(unit) or Gladius.test)) then
		local _, class = UnitClass(unit);
		local _, race = UnitRace(unit);

		self.opponents[guid] = {
			unit = unit,
			name = name,
			class = class,
			race = race
		}
	end
end

function Alerts:COMBAT_LOG_EVENT_UNFILTERED(_,_,event, _, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, dstRaidFlags, ...)
	if (event == "SPELL_AURA_APPLIED") then
		local spell = select(2, ...);
		local type = select(4, ...);
		local spellId = ...
		-- hostile unit get a buff or debuff?
		if ( bit_band(dstFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 ) then
			if ( type == AURA_TYPE_DEBUFF ) then
				-- so wyvern sting dot does not trigger alerts
				if ( spell == spellList["Wyvern Sting"] ) then
					local spellId = ...;
					if ( spellId ~= highestRankWyvernSting ) then
						return
					end
				end
				self:CombatAlert(event, "Hostile", "Debuff", srcGUID, dstGUID, spell);
			elseif ( type == AURA_TYPE_BUFF ) then
				self:CombatAlert(event, "Hostile", "Buff", srcGUID, dstGUID, spell);
			end
			-- friendly unit get a buff or debuff?
		elseif ( bit_band(dstFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 and bit_band(dstFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) == 0 ) then
			if ( type == AURA_TYPE_DEBUFF ) then
				-- so wyvern sting dot does not trigger alerts
				if ( spell == spellList["Wyvern Sting"] ) then
					local spellId = ...;
					if ( spellId ~= highestRankWyvernSting ) then
						return
					end
				end
				self:CombatAlert(event, "Friendly", "Debuff", srcGUID, dstGUID, spell);
			elseif ( type == AURA_TYPE_BUFF ) then
				self:CombatAlert(event, "Friendly", "Buff", srcGUID, dstGUID, spell);
			end
		end
	elseif (event == "SPELL_CAST_START") then
		local spell = select(2, ...);
		-- hostile unit casting?
		if ( bit_band(srcFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 ) then
			self:CombatAlert(event, "Hostile", nil, srcGUID, dstGUID, spell);
			-- party member (excluding me) casting?
		elseif ( bit_band(srcFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 and (bit_band(srcFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) == 0 or Gladius.test) ) then
			self:CombatAlert(event, "Friendly", nil, srcGUID, dstGUID, spell);
		end

	elseif (event == "SPELL_CAST_SUCCESS") then
		local spell = select(2, ...);
		if ( self.opponents[srcGUID] ) then
			if ( spell == spellList["PvP Trinket"] 
			  or spell == spellList["Every Man for Himself"]
			) then
				self.opponents[srcGUID].trinket = GetTime() + 120;
				self:Alert("trinketUsed", srcGUID);
				-- trinket cools down wotf for 45 seconds
				if ( self.opponents[srcGUID].race == "Scourge" ) then
					if ( not self.opponents[srcGUID].wotf or self.opponents[srcGUID].wotf < (GetTime() + 45) ) then
						self.opponents[srcGUID].wotf = GetTime() + 45;
					end
				end
			elseif ( spell == spellList["Will of the Forsaken"] ) then
				self.opponents[srcGUID].wotf = GetTime() + 120;
				self:Alert("wotfUsed", srcGUID);
				-- wotf cools down trinket for 45 seconds
				if ( not self.opponents[srcGUID].trinket or self.opponents[srcGUID].trinket < (GetTime() + 45) ) then
					self.opponents[srcGUID].trinket = GetTime() + 45;
				end
			end
		end

	elseif ( event == "SPELL_AURA_REMOVED" or event == "SPELL_AURA_DISPELLED" ) then
		if ( bit_band(dstFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 ) then
			local spell = select(2, ...);
			local type = select(4, ...);
			if ( type == AURA_TYPE_DEBUFF ) then
				self:Alert("lostDebuff", srcGUID, dstGUID, spell);
				self:CombatAlert(event, "Hostile", "Debuff", srcGUID, dstGUID, spell);
			elseif (type == AURA_TYPE_BUFF) then
				self:Alert("lostBuff", srcGUID, dstGUID, spell);
			end
		end

	elseif ( event == "SPELL_INTERRUPT" ) then
		local spell = select(2, ...);
		local duration;

		if ( interrupts[spell] ) then
			duration = interrupts[spell];
		end

		-- hostile unit interrupted
		if ( bit_band(dstFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 ) then
			self:CombatAlert(event, "Hostile", nil, srcGUID, dstGUID, spell, duration);
		-- friendly interrupted
		elseif ( bit_band(dstFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY) > 0 and bit_band(dstFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) == 0 ) then
			self:CombatAlert(event, "Friendly", nil, srcGUID, dstGUID, spell, duration);
		end
	elseif (event == "SPELL_SUMMON") then
		if ( bit_band(srcFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 ) then
			local id, spell = ...;
			self:CombatAlert(event, "Hostile", nil, id, spell);
		end
	elseif ( event == "UNIT_DIED" ) then
		-- hostile unit died?
		if ( bit_band(dstFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 ) then
			self:CombatAlert(event, "Hostile", nil, dstGUID);

			self:Alert("groundingDied", dstName);
			self:Alert("tremorDied", dstName);
		end
	elseif event == "PARTY_KILL" then
		if ( Alerts.opponents[dstGUID] ) then
			self:Alert("opponentDeaths", dstGUID);
		end

		-- totems killed?
		if ( bit_band(dstFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0 ) then
			self:Alert("groundingDied", dstName);
			self:Alert("tremorDied", dstName);
		end
	end
end

function Alerts:CombatAlert(event, reaction, buffType, ...)
	if ( event ) then
		if ( not alertLookup[event] ) then
			return
		end
		if ( reaction ) then
			if ( not alertLookup[event][reaction] ) then
				return
			end
			if ( buffType ) then
				if ( alertLookup[event][reaction][buffType] ) then
					t = alertLookup[event][reaction][buffType];
				else
					return;
				end
			else
				t = alertLookup[event][reaction];
			end
		else
			t = alertLookup[event];
		end
		for name in pairs(t) do
			self:Alert(name, ...);
		end
	end
end

function Alerts:Alert(name, ...)
	local alert;
	if ( type(name) == "number" ) then
		alert = alerts[name];
	else
		alert = alertLookup[name];
	end

	if ( not alert ) then
		return
	end
	
	local msgType = alert.func(...);
	if msgType then
		-- speech
		local srcGUID, dstGUID, spell = ...;
		local class;

		-- try to get unit class from 2nd param (the dstGUID for combat log alerts)
		if ( dstGUID and self.opponents[dstGUID] ) then
			class = self.opponents[dstGUID].class;

			-- else try to get class from first param
		elseif ( srcGUID and self.opponents[srcGUID] ) then
			class = self.opponents[srcGUID].class;
		end
		
		-- pass third param as spell name
		self:Speak(alert.speech, class, spell);

		--sound effect
		if ( config[alert.name].soundEffect ) then
			if ( config[alert.name].customSound ) then
				--PlaySoundFile("Interface\\AddOns\\Gladius\\sounds\\Custom\\"..config[alert.name].customSound);
			else
				PlaySoundFile("Interface\\AddOns\\Gladius\\sound\\"..alert.soundEffect);
			end
		end
	end
end

function Alerts:Speak(str, class, spell)
	if not str then return end
	if type(str) == "table" then
		local t = str;
		str = t[1];
		class = t[2];
		spell = t[3]
	end

	if (not class) then class = "WARRIOR" end
	if not spell then spell = "Polymorph" end

	local firstFile, rest = strmatch(str, "^(%S+)%s*(.*)");
	if (firstFile == "$class") then
		firstFile = class
	end
	if (firstFile == "$spell") then
		firstFile = effectAudio[spell];
	end

	PlaySoundFile("Interface\\AddOns\\Gladius\\sound\\voice\\"..firstFile..".ogg");
	if ( rest and rest ~= "" ) then
		self.restTimer = self:ScheduleTimer("Speak", voiceDurations[firstFile], {rest, class, spell});
	end
end

------------------- gui ---------------------
function Alerts:GetOptions()
	local options = {};
	
	for index, alert in ipairs(alerts) do
		local option = {
			name = alert.name,
			desc = alert.name,
			type = "group",
			args = {
			}
		}

		if alert.speech then
			option.args["speech"] = {
				name = "Voice Alerts",
				desc = "Toggle VoiceAlert",
				type = "toggle",
				get = function()
					return config[alert.name].speech
				end,
				set = function(_, v)
					config[alert.name].speech = v
				end
			}
		end

		if alert.soundEffect then
			option.args["soundEffect"] = {
				name = "Sound Effect",
				desc = "Toggle SoundEffect",
				type = "toggle",
				get = function()
					return config[alert.name].soundEffect
				end,
				set = function(_, v)
					config[alert.name].soundEffect = v
				end
			}
		end

		--if (alert.excludes) then
		--	option.args["excludes"] = {
		--		type = "multiselect",
		--		name = "excludes",
		--		values = alert.excludes,
		--		set = function(_, v) 
		--			print(v)
		--		end,
		--		get = function() 
		--		
		--		end,
		--	}
		--end

		if (alert.options) then
			option.args["options"] = {
				name = "Extra Options",
				type = "group",
				inline = true,
				args = {}
			}
			for i, opt in pairs(alert.options) do
				option.args["options"].args[opt.name] = {
					name = opt.label,
					type = "input",
					width = "double",
					set = function(_, v)
						config[alert.name]["options"][opt.name] = v;
					end,
					get = function()
						return config[alert.name]["options"][opt.name]
					end
				}
			end
		end

		options[alert.name] = option;
	end

	return options;
end

-- Needed to not throw Lua errors <,<
function Alerts:GetAttachTo()
   return ""
end