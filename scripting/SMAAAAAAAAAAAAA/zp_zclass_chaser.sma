/*================================================================================

	--------------------------
	-*- [ZP] Zombie Class: Chaser | by Richicorejz -*-
	-*- My Group: https://vk.com/plague43 -*-
	-*- Feedback > Telegram: @corejz  | VK > https://vk.com/fzhyk -*-
	--------------------------

	Like in CSO:
	+ Простая система энергии.

    Code Features:
	+ ReAPI.
================================================================================*/

// ---- Includes
#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <fakemeta>
#include <reapi>
#include <zombieplague>
#include <screenfade_util>

// ---- Macroses
#define PrecacheArray(%0,%1)			for(new i; i < sizeof %1; i++) engfunc(EngFunc_Precache%0, %1[i])

#define _is_user_zombie(%0) 			zp_get_user_zombie(%0)
#define _is_chaser_zombie_class(%0) 	(zp_get_user_zombie_class(%0) == gl_iZClassID)
#define _is_user_nemesis(%0)			zp_get_user_nemesis(%0)

#define BIT_ADD(%0,%1)					(%0 |= BIT(%1))
#define BIT_SUB(%0,%1)					(%0 &= ~BIT(%1))
#define BIT_VALID(%0,%1)				bool: ((%0 & BIT(%1)) ? true : false)

#define ZOMBIE_HURT						true 	// Звуки боли, смерти (false - отключить)
#define TWO_SKILLS						true 	// Блокировать использования броска, если включена способность Гравитация (false - отключить)

// -- [Tasks]
#define TASKID_WAIT_HUD 58495
#define TASKID_GRAVITY 34260
#define TASKID_ENERGY 8877

// --- [Zombie Class Settings]
new const ZM_CLASS_NAME[] = "Chaser";
new const ZM_CLASS_INFO[] = "G > Dash | R > Gravity";
new const ZM_CLASS_MODEL[] = "booster_zombi_origin";
new const ZM_CLASS_CLAW[] = "v_knife_zombibooster.mdl";
new const ZM_CLASS_GRENADE[] = "models/LR_ZP/v_zombibomb_booster.mdl";
const ZM_CLASS_HEALTH = 4500;			// Health Point
const ZM_CLASS_SPEED = 240;				// Speed
const Float:ZM_CLASS_GRAVITY = 0.76; 	// Чем ниже значение, тем больше грава
const Float:ZM_CLASS_KNOCKBACK = 1.2; 	// Чем больше значение, тем меньше откидывание

// [Jerk Ability]
const ENERGY_MIN = 10;					// Минимальная энергия для броска
const ENERGY_MAX = 99;					// Максимальная энергия игрока ( -1 )

const ENERGY_WEAK_TAKE = 10;			// Сколько мы забираем энергии при использовании слабого броска
const ENERGY_WEAK_JERK = 700;			// Сила слабого броска

const ENERGY_STRONG_JERK = 1000;		// Сила сильного броска
const ENERGY_STRONG_NEED = 50;			// Минимум энергии для сильного броска
const ENERGY_STRONG_TAKE = 50;			// Сколько мы забираем энергии при использовании сильного рывка

// [Gravity Ability]
const Float:GRAVITY_BANTIME = 15.0;		// КД гравитации
const Float:GRAVITY_ACTIVETIME = 5.0;	// Время полетать , пиф паф, пуф паф
const Float:GRAVITY_VALUE = 0.53;		// Гравитация-значение

// Variables
new gl_iZClassID;
new gl_bitGravitySkillActive,

	Float:g_flGravityWait[MAX_CLIENTS + 1],
	Float:g_flGravityPrev[MAX_CLIENTS + 1];

new g_iCountEnergy[MAX_PLAYERS + 1];

new g_iNumDash;
new g_iPlayers[33];
new HookChain:g_hPrethink;

// --- [Sounds]
new const CHASER_SOUNDS[][] =
{
	"zombi/boosterzombie_booster.wav",
	"zombi/boosterzombie_stab.wav", // Не трогайте этот путь (он в mdl)
	"zombi/speedup.wav"
}

#if ZOMBIE_HURT == true
	new const CHASER_PAIN[][] =
	{
		"zombi/boosterzombie_hurt1.wav",
		"zombi/boosterzombie_hurt2.wav",
		"zombi/boosterzombie_death1.wav",
		"zombi/boosterzombie_death2.wav"
	}
#endif

// ---- [AmxModX]
public plugin_init()
{
	new i;

	register_plugin("[ZP] ZClass: Chaser", "1.0", "R1CHICOREJZ");
	
	new const GRENADES_ENTITY[][] = { "weapon_hegrenade", "weapon_flashbang", "weapon_smokegrenade" };
	for(i = 0; i < sizeof GRENADES_ENTITY; i++)
		RegisterHam(Ham_Item_Deploy, GRENADES_ENTITY[i], "CGrenade__Deploy_Post", true);

	// ReAPI
	RegisterHookChain(RG_CSGameRules_RestartRound, "CSGameRules_RestartRound", false)
	RegisterHookChain(RG_CBasePlayer_ImpulseCommands, "CBasePlayer_ImpulseCommands", false);
	#if ZOMBIE_HURT == true
		RegisterHookChain(RH_SV_StartSound, "SV_StartSound");
	#endif
	DisableHookChain((g_hPrethink = RegisterHookChain(RG_CBasePlayer_PreThink, "CBasePlayer_PreThink", false)));

	// Client Commands
	register_clcmd("drop", "DashAbility");
}

public plugin_precache()
{
	// Register Zombie Class
	gl_iZClassID = zp_register_zombie_class(ZM_CLASS_NAME, ZM_CLASS_INFO, ZM_CLASS_MODEL, ZM_CLASS_CLAW, ZM_CLASS_HEALTH, ZM_CLASS_SPEED, ZM_CLASS_GRAVITY, ZM_CLASS_KNOCKBACK)

	// Precache models
	engfunc(EngFunc_PrecacheModel, ZM_CLASS_GRENADE)

	// Precache Sounds
	PrecacheArray(Sound, CHASER_SOUNDS);

	#if ZOMBIE_HURT == true
		PrecacheArray(Sound, CHASER_PAIN);
	#endif

	UTIL_PrecacheSoundsFromModel(ZM_CLASS_GRENADE)
}

Reset_Value(id)
{
	BIT_SUB(gl_bitGravitySkillActive, id);

	g_flGravityWait[id] = 0.0;
	g_flGravityPrev[id] = 0.0;
	g_iCountEnergy[id] = 0;

	UTIL_ScreenFade(id);

	remove_task(id + TASKID_WAIT_HUD);
	remove_task(id + TASKID_GRAVITY);
	remove_task(id + TASKID_ENERGY);
}

public client_putinserver(id) Reset_Value(id); // AMX
public client_disconnected(id) Reset_Value(id); // Fakemeta

// Zombie Plague
public zp_user_humanized_post(id) Reset_Value(id);
public zp_user_infected_post(id)
{
	Reset_Value(id);

	if(!_is_user_zombie(id) || _is_user_nemesis(id)) return;
	if(_is_chaser_zombie_class(id))
	{
		set_task_ex(1.0, "CTask__Energy", id + TASKID_ENERGY, .flags = SetTask_Repeat);
	}
}

// [HamSandwich]
public CGrenade__Deploy_Post(iItem) {
	new id = get_member(iItem, m_pPlayer);
	if(!_is_user_zombie(id) || _is_user_nemesis(id)) return;
	if(_is_chaser_zombie_class(id))
	{
		set_entvar(id, var_viewmodel, ZM_CLASS_GRENADE);
	}
}

// [ReAPI]
public CSGameRules_RestartRound()
{
	new szPlayers[MAX_PLAYERS], iPlayersNum, id = NULLENT;
	get_players_ex(szPlayers, iPlayersNum, GetPlayers_ExcludeHLTV);

	for (new i; i < iPlayersNum; i++)
	{
		id = szPlayers[i];
		if (!is_user_connected(id))
			continue;
		
		Reset_Value(id);
	}
}

// R button
public CBasePlayer_ImpulseCommands(id)
{
	if(!is_user_alive(id))
		return;

	if(get_member(id, m_afButtonPressed) & IN_RELOAD) GravitySkillStart(id);
}

#if ZOMBIE_HURT == true
	public SV_StartSound(recipients, id, channel, sample[], volume, Float:attn, flags, pitch)
	{
		// Replace these next sounds for zombies only
		if(!is_user_connected(id))
			return HC_CONTINUE; 

		if(!_is_user_zombie(id) || !_is_chaser_zombie_class(id) || _is_user_nemesis(id))
			return HC_CONTINUE; 

		// Zombie being hit
		if(sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't') // hits
		{
			rh_emit_sound2(id, 0, CHAN_STATIC, CHASER_PAIN[random_num(0,1)]);
			// SetHookChainArg(4, ATYPE_STRING, CHASER_PAIN[random_num(0,1)]);
			return HC_SUPERCEDE; // also block default hits sounds
		}
		else if (sample[7] == 'd') // Death Sound
		{
			if (sample[8] == 'i' && sample[9] == 'e')
			{
				rh_emit_sound2(id, 0, CHAN_STATIC, CHASER_PAIN[random_num(2,3)])
			}
			else if (sample[8] == 'e' && sample[9] == 'a')
			{
				rh_emit_sound2(id, 0, CHAN_STATIC, CHASER_PAIN[random_num(2,3)])
			}
			return HC_SUPERCEDE; // also block default death sounds
		}
		else if (sample[0] == 'p' && sample[1] == 'l') // fix headshot sound
		{
			if (sample[7] == 'h' && sample[10] == 'd')
			{
				// client_print(recipients, print_chat, "	  sound headshot")
				rh_emit_sound2(id, 0, CHAN_STATIC, CHASER_PAIN[random_num(0,1)])
				return HC_SUPERCEDE; // also block default hs sounds
			}
		}
		return HC_CONTINUE;
	}
#endif

// [PreThink]
public CBasePlayer_PreThink(id)
{
	static Float:flVelocity[3];

	if (g_iNumDash == 1) {
		if (g_iCountEnergy[id] > ENERGY_STRONG_NEED)
		{
			velocity_by_aim(id, ENERGY_STRONG_JERK, flVelocity)
		}
		else
		{
			velocity_by_aim(id, ENERGY_WEAK_JERK, flVelocity)
		}
		set_entvar(id, var_velocity, flVelocity)
	}

	// client_print(id, print_chat, "	call PreThink")

	DashChecks(id);
}

// [Dash Ability]
public DashAbility(id)
{
	if(!is_user_alive(id) || !_is_user_zombie(id) || !_is_chaser_zombie_class(id) || _is_user_nemesis(id)) return PLUGIN_CONTINUE;

	new pActiveItem = get_member(id, m_pActiveItem);
	if(is_nullent(pActiveItem) || (get_member(pActiveItem, m_iId) != WEAPON_KNIFE)) return PLUGIN_CONTINUE;

	#if TWO_SKILLS == true
		if(BIT_VALID(gl_bitGravitySkillActive, id))
		{
			client_print(id, print_center, "Невозможно использовать два навыка одновременно.");
			return PLUGIN_HANDLED;
		}
	#endif

	if(g_iCountEnergy[id] < ENERGY_MIN) // Minimum for jerk
	{
		client_print(id, print_center, "Недостаточно энергии: (%d/%d)", g_iCountEnergy[id], ENERGY_MIN);
		return PLUGIN_HANDLED;
	}

	SetThink(id, "CDash__Think");
	DashChecks(id);

	static Float:flNextThink; flNextThink = get_gametime();
	set_entvar(id, var_nextthink, flNextThink + 0.1);
	
	UTIL_ScreenFade(id, { 255, 0, 0 }, 0.3, 0.3, 45, FFADE_IN, false, false) // Set ScreenFade
	rh_emit_sound2(id, 0, CHAN_STATIC, CHASER_SOUNDS[0]) // Ability Sound

	return PLUGIN_HANDLED;
}

// [Gravity Ability]
public GravitySkillStart(id)
{
	if(!is_user_alive(id) || !_is_user_zombie(id) || !_is_chaser_zombie_class(id) || _is_user_nemesis(id)) return PLUGIN_CONTINUE;

	if(BIT_VALID(gl_bitGravitySkillActive, id)) return PLUGIN_HANDLED;

	static Float:flGameTime; flGameTime = get_gametime();
	if(g_flGravityWait[id] >= flGameTime)
	{
		client_print(id, print_center, "Навык на перезарядке. [%.0f секунд до следующего использования]", g_flGravityWait[id] - flGameTime);
		return PLUGIN_HANDLED;
	}

	rg_set_ent_render(id, kRenderFxGlowShell, 150, 0, 0, kRenderNormal, 10); // Glowing
	UTIL_ScreenFade(id, { 238, 130, 238 }, 1.0, GRAVITY_ACTIVETIME, 25, FFADE_IN, false, false) // Set ScreenFade
	rh_emit_sound2(id, 0, CHAN_STATIC, CHASER_SOUNDS[2]) // Gravity Sound

	BIT_ADD(gl_bitGravitySkillActive, id);
	g_flGravityWait[id] = flGameTime + GRAVITY_BANTIME;
	g_flGravityPrev[id] = Float:get_entvar(id, var_gravity);
	set_entvar(id, var_gravity, GRAVITY_VALUE);

	if(!task_exists(id + TASKID_WAIT_HUD))
		set_task(1.0, "CTask__CreateMessages", id + TASKID_WAIT_HUD, _, _, .flags = "b");

	if(!task_exists(id + TASKID_GRAVITY))
		set_task(GRAVITY_ACTIVETIME, "CTask__ResetGravity", id + TASKID_GRAVITY);

	return PLUGIN_HANDLED;
}

public CTask__ResetGravity(iTask)
{
	new id = iTask - TASKID_GRAVITY;

	if(!is_user_alive(id))
	{
		remove_task(iTask);
		return;
	}

	rg_set_ent_render(id);

	// If gravity has changed during the ability, then there is no point in setting the previous gravity 
	if(Float:get_entvar(id, var_gravity) != GRAVITY_VALUE)
	{
		g_flGravityPrev[id] = 0.0;
		return;
	}

	client_print(id, print_center, "Гравитация деактивирована.");
	BIT_SUB(gl_bitGravitySkillActive, id);
	set_entvar(id, var_gravity, g_flGravityPrev[id]);
}

// [HUD Message]
public CTask__Energy(iTask)
{
	new id = iTask - TASKID_ENERGY;

	if(!is_user_alive(id)) return;
	
	if (g_iCountEnergy[id] <= ENERGY_MAX)
		g_iCountEnergy[id]++;

	if (g_iCountEnergy[id] == ENERGY_STRONG_NEED)
	{
		UTIL_ScreenFade(id, { 0, 255, 0 }, 0.3, 0.3, 75, FFADE_IN, false, false) // Set ScreenFade
	}

	set_hudmessage(10, 255, 0, -1.0, 0.01, 0, 1.0, 1.1, 0.0, 0.0);
	show_hudmessage(id, "Energy: %d", g_iCountEnergy[id]);
}

public CTask__CreateMessages(iTask)
{
	new id = iTask - TASKID_WAIT_HUD;

	if(is_user_alive(id))
	{
		new szGravityAbility[256];
		static Float: flGameTime; flGameTime = get_gametime();

		if(g_flGravityWait[id] <= flGameTime) remove_task(id + TASKID_WAIT_HUD);

		if(g_flGravityWait[id] >= flGameTime) formatex(szGravityAbility, charsmax(szGravityAbility), "(R) Gravity - %.0f^n", g_flGravityWait[id] - flGameTime);
		else szGravityAbility = ""

		set_hudmessage(255, 140, 0, 0.75, 0.92, 0, 1.0, 1.1, 0.0, 0.0, -1);
		show_hudmessage(id, "%s", szGravityAbility);
	}
	else
	{
		remove_task(id + TASKID_WAIT_HUD);
		g_flGravityWait[id] = 0.0;
	}
}

// [Dash Think]
public CDash__Think(id)
{
	static Float:flNextThink; flNextThink = get_gametime();

	if (g_iCountEnergy[id] > ENERGY_STRONG_NEED)
		g_iCountEnergy[id] -= ENERGY_STRONG_TAKE;
	else 
		g_iCountEnergy[id] -= ENERGY_WEAK_TAKE;
		
	// client_print(id, print_chat, "	call Think")

	if (g_iNumDash == 0)
		return;

	set_entvar(id, var_nextthink, flNextThink + 0.1);
}

// [Stocks]
stock DashChecks(id)
{
	g_iPlayers[id] = !g_iPlayers[id];
		
	if (g_iPlayers[id])
	{
		// client_print(id, print_chat, "		num: %d", g_iPlayers[id]);
		g_iNumDash++;
	}
	else
    {
		// client_print(id, print_chat, "		num: %d", g_iPlayers[id]);
		g_iNumDash--;
	}

	if (g_iNumDash == 1)
	{
		EnableHookChain(g_hPrethink);
	}
	else if (g_iNumDash == 0) 
	{
		DisableHookChain(g_hPrethink);
	}
}

stock rg_set_ent_render(id, iFx = 0, iRed = 255, iGreen = 255, iBlue = 255, iRender = 0, flAmount = 16)
{
	new Float:flColor[3];

	flColor[0] = float(iRed);
	flColor[1] = float(iGreen);
	flColor[2] = float(iBlue);

	set_entvar(id, var_renderfx, iFx);
	set_entvar(id, var_rendercolor, flColor);
	set_entvar(id, var_rendermode, iRender);
	set_entvar(id, var_renderamt, float(flAmount));
}

stock UTIL_PrecacheSoundsFromModel(const szModelPath[])
{
	new iFile;
	
	if((iFile = fopen(szModelPath, "rt")))
	{
		new szSoundPath[64];
		
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek(iFile, 164, SEEK_SET);
		fread(iFile, iNumSeq, BLOCK_INT);
		fread(iFile, iSeqIndex, BLOCK_INT);
		
		for(new k, i = 0; i < iNumSeq; i++)
		{
			fseek(iFile, iSeqIndex + 48 + 176 * i, SEEK_SET);
			fread(iFile, iNumEvents, BLOCK_INT);
			fread(iFile, iEventIndex, BLOCK_INT);
			fseek(iFile, iEventIndex + 176 * i, SEEK_SET);
			
			for(k = 0; k < iNumEvents; k++)
			{
				fseek(iFile, iEventIndex + 4 + 76 * k, SEEK_SET);
				fread(iFile, iEvent, BLOCK_INT);
				fseek(iFile, 4, SEEK_CUR);
				
				if(iEvent != 5004)
					continue;
				
				fread_blocks(iFile, szSoundPath, 64, BLOCK_CHAR);
				
				if(strlen(szSoundPath))
				{
					strtolower(szSoundPath);
					engfunc(EngFunc_PrecacheSound, szSoundPath);
				}
			}
		}
	}
	
	fclose(iFile);
}