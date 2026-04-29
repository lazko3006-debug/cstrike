#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>
#include <fun>

#define IsValidPrivateData(%0)          ( pev_valid( %0 ) == 2 )
 
new const zclass_name[] = "[Ведьма]"
new const zclass_info[] = "[Притягивает [G]]"
new const zclass_model[] = "BZ_banshee2"
new const zclass_clawmodel[] = "v_knife_witch_zombi.mdl"
const zclass_health = 5600
const zclass_speed = 240
const Float:zclass_gravity = 0.9
const Float:zclass_knockback = 1.0

new const SOUND_FIRE[] = "BZ_sound/zombi_banshee_pulling_fire.wav"
new const SOUND_BAT_HIT[] = "BZ_sound/skill.wav"
new const SOUND_BAT_MISS[] = "BZ_sound/zombi_banshee_pulling_fail.wav"
new const MODEL_BAT[] = "models/BZ_models/bat_witch.mdl"
new const BAT_CLASSNAME[] = "banchee_bat"
new spr_skull

const Float:banchee_skull_bat_speed = 800.0
const Float:banchee_skull_bat_flytime = 3.0
const Float:banchee_skull_bat_catch_time = 4.0
const Float:banchee_skull_bat_catch_speed = 300.0
const Float:bat_timewait = 40.0

new g_CurWeapon[33]

new g_stop[33]
new g_bat_time[33]
new g_bat_stat[33]
new g_bat_enemy[33]
new g_no_fly[33] //отключаем возможность летать на парашюте
new Float:g_temp_speed[33]
new g_cooldown[33]
new idclass_banchee
new g_maxplayers
new g_roundend
new g_msgSayText
new g_MsgSync

enum (+= 100)
{
	TASK_BOT_USE_SKILL = 2367,
	TASK_REMOVE_STAT,
	TASK_COOLDOWN,
	TASK_ABILITY
}


#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)
#define ID_TASK_REMOVE_STAT (taskid - TASK_REMOVE_STAT)

public plugin_precache()
{
	precache_sound(SOUND_FIRE)
	precache_sound(SOUND_BAT_HIT)
	precache_sound(SOUND_BAT_MISS)
	
	precache_model(MODEL_BAT)
	
	spr_skull = precache_model("sprites/ef_bat.spr")
	
	idclass_banchee = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
}

public plugin_init()
{		
	register_event("HLTV", "EventHLTV", "a", "1=0", "2=0")
	register_event("DeathMsg", "EventDeath", "a")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	register_clcmd("drop", "cmd_bat")
	
	register_forward(FM_PlayerPreThink,"fw_PlayerPreThink")
	
	register_event("CurWeapon", "Event_CurrentWeapon", "be", "1=1")

	RegisterHam(Ham_Touch,"info_target","EntityTouchPost",1)
	RegisterHam(Ham_Think,"info_target","EntityThink")
	
	g_MsgSync = CreateHudSyncObj()
	
	g_maxplayers = get_maxplayers()
	g_msgSayText = get_user_msgid("SayText")
}

public plugin_natives()
{
	register_native("bat_buff", "native_bat_buff", 1);
}

public native_bat_buff(id)
{
	return g_no_fly[id];
}

public client_putinserver(id)
{
	reset_value_player(id)
}

public client_disconnect(id)
{
	reset_value_player(id)
}

public EventHLTV()
{
	g_roundend = 0
	
	for(new id = 1; id <= g_maxplayers; id++)
	{
		if (!is_user_connected(id)) continue;
		
	    remove_task(id+TASK_ABILITY)
	    remove_task(id+TASK_COOLDOWN)		
		reset_value_player(id)
	}
}

public logevent_round_end()
{
	g_roundend = 1
	
	for(new id = 1; id <= g_maxplayers; id++)
	{
		if (!is_user_connected(id)) continue;
		
		reset_value_player(id)
	}
}


public EventDeath()
{
	new id = read_data(2)
	
	reset_value_player(id)
}
public Event_CurrentWeapon(id) g_CurWeapon[id] = read_data(2)

public fw_Weapon_Deploy_Post(weapon_ent)
{
	if( !IsValidPrivateData( weapon_ent ) )
	{
         return HAM_IGNORED;
    }
	static id; id = get_pdata_cbase(weapon_ent, 41, 4)

	static weaponid ; weaponid = cs_get_weapon_id(weapon_ent)

	g_CurWeapon[id] = weaponid
	
	return HAM_IGNORED;
}


public zp_user_infected_post(id)
{
	reset_value_player(id)

	if(zp_get_user_nemesis(id)) return;
	
	if(zp_get_user_zombie_class(id) == idclass_banchee && !zp_get_user_nemesis(id))
	{
	    g_cooldown[id] = 0
		set_task(1.0, "Ability", id+TASK_ABILITY, _, _, "b")	
	}
}

public zp_user_humanized_post(id)
{
	reset_value_player(id)
	remove_task(id+TASK_ABILITY)
	remove_task(id+TASK_COOLDOWN)
}

public cmd_bat(id)
{
	if(g_roundend) return PLUGIN_CONTINUE
	
	if(!is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_nemesis(id)) return PLUGIN_CONTINUE
	
	if(zp_get_user_zombie_class(id) == idclass_banchee && !g_bat_time[id] && !g_cooldown[id])
	{
		g_bat_time[id] = 1
		
		g_cooldown[id] = 30
		set_task(1.0, "RemoveCooldown", id+TASK_COOLDOWN, _, _, "a",g_cooldown[id])	
		
		set_task(bat_timewait,"clear_stat",id+TASK_REMOVE_STAT)
		
		new ent = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
		
		if(!pev_valid(ent)) return PLUGIN_HANDLED
		
		new Float:vecAngle[3],Float:vecOrigin[3],Float:vecVelocity[3],Float:vecForward[3]
		fm_get_user_startpos(id,5.0,2.0,-1.0,vecOrigin)
		pev(id,pev_angles,vecAngle)
		
		engfunc(EngFunc_MakeVectors,vecAngle)
		global_get(glb_v_forward,vecForward)
		
		velocity_by_aim(id,floatround(banchee_skull_bat_speed),vecVelocity)
		
		set_pev(ent,pev_origin,vecOrigin)
		set_pev(ent,pev_angles,vecAngle)
		set_pev(ent,pev_classname,BAT_CLASSNAME)
		set_pev(ent,pev_movetype,MOVETYPE_FLY)
		set_pev(ent,pev_solid,SOLID_BBOX)
		engfunc(EngFunc_SetSize,ent,{-20.0,-15.0,-8.0},{20.0,15.0,8.0})
		
		engfunc(EngFunc_SetModel,ent,MODEL_BAT)
		set_pev(ent,pev_animtime,get_gametime())
		set_pev(ent,pev_framerate,1.0)
		set_pev(ent,pev_owner,id)
		set_pev(ent,pev_velocity,vecVelocity)
		set_pev(ent,pev_nextthink,get_gametime()+banchee_skull_bat_flytime)
		emit_sound(ent, CHAN_WEAPON, SOUND_FIRE, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		g_stop[id] = ent
		
		PlayWeaponAnimation(id, 2)

		pev(id, pev_maxspeed, g_temp_speed[id])
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

stock Player_SetAnimation(const iPlayer, const szAnim[])
{
   #define ACT_RANGE_ATTACK1   28
   
   // Linux extra offsets
   #define extra_offset_player   5
   #define extra_offset_animating   4
   
   // CBaseAnimating
   #define m_flFrameRate      36
   #define m_flGroundSpeed      37
   #define m_flLastEventCheck   38
   #define m_fSequenceFinished   39
   #define m_fSequenceLoops   40
   
   // CBaseMonster
   #define m_Activity      73
   #define m_IdealActivity      74
   
   // CBasePlayer
   #define m_flLastAttackTime   220
   
   new iAnimDesired, Float: flFrameRate, Float: flGroundSpeed, bool: bLoops;
      
   if ((iAnimDesired = lookup_sequence(iPlayer, szAnim, flFrameRate, bLoops, flGroundSpeed)) == -1)
   {
      iAnimDesired = 0;
   }
   
   new Float: flGametime = get_gametime();

   set_pev(iPlayer, pev_frame, 0.0);
   set_pev(iPlayer, pev_framerate, 1.0);
   set_pev(iPlayer, pev_animtime, flGametime  );
   set_pev(iPlayer, pev_sequence, iAnimDesired);
   
   set_pdata_int(iPlayer, m_fSequenceLoops, bLoops, extra_offset_animating);
   set_pdata_int(iPlayer, m_fSequenceFinished, 0, extra_offset_animating);
   
   set_pdata_float(iPlayer, m_flFrameRate, flFrameRate, extra_offset_animating);
   set_pdata_float(iPlayer, m_flGroundSpeed, flGroundSpeed, extra_offset_animating);
   set_pdata_float(iPlayer, m_flLastEventCheck, flGametime , extra_offset_animating);
   
   set_pdata_int(iPlayer, m_Activity, ACT_RANGE_ATTACK1, extra_offset_player);
   set_pdata_int(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1, extra_offset_player);   
   set_pdata_float(iPlayer, m_flLastAttackTime, flGametime , extra_offset_player);
}

public Ability(taskid)
{
	new id = taskid - TASK_ABILITY
	
	if(is_user_alive(id))
	{
		if (g_cooldown[id] == 0)
		{
           set_hudmessage(200, 100, 0, -1.0, 0.12, 0, 1.0, 1.1, 0.0, 0.0, -1)
		   ShowSyncHudMsg(id, g_MsgSync, "Летучие мыши - [G]^nСпособность готова!")
		}
	}
	else remove_task(id+TASK_ABILITY)
}

public RemoveCooldown(taskid)
{
	new id = taskid - TASK_COOLDOWN
	
	if(is_user_alive(id))
	{
		g_cooldown[id]--
		if (g_cooldown[id] == 0)
		{
		    set_task(2.5, "Ability", id+TASK_ABILITY)
			remove_task(id+TASK_COOLDOWN)
		}
		set_hudmessage(200, 100, 0, -1.0, 0.12, 0, 1.0, 1.1, 0.0, 0.0, -1)
		ShowSyncHudMsg(id, g_MsgSync, "Летучие мыши - [G]^nПерезарядка: %d",g_cooldown[id])
	}
	else remove_task(id+TASK_COOLDOWN)
}

public fw_PlayerPreThink(id)
{
	if(!is_user_alive(id)) return FMRES_IGNORED
	
	if(g_bat_stat[id])
	{
		new owner = g_bat_enemy[id], Float:ownerorigin[3]
		pev(owner,pev_origin,ownerorigin)
		static Float:vec[3]
		aim_at_origin(id,ownerorigin,vec)
		engfunc(EngFunc_MakeVectors, vec)
		global_get(glb_v_forward, vec)
		vec[0] *= banchee_skull_bat_catch_speed
		vec[1] *= banchee_skull_bat_catch_speed
		vec[2] = 0.0
		set_pev(id,pev_velocity,vec)
	}
	
	return FMRES_IGNORED
}

public EntityThink(ent)
{
	if(!pev_valid(ent)) return HAM_IGNORED
	
	new classname[32]
	pev(ent,pev_classname,classname,31)
	
	if(equal(classname,BAT_CLASSNAME))
	{
		static Float:origin[3];
		pev(ent,pev_origin,origin);
		
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
		write_byte(TE_EXPLOSION); // TE_EXPLOSION
		write_coord(floatround(origin[0])); // origin x
		write_coord(floatround(origin[1])); // origin y
		write_coord(floatround(origin[2])); // origin z
		write_short(spr_skull); // sprites
		write_byte(40); // scale in 0.1's
		write_byte(30); // framerate
		write_byte(14); // flags 
		message_end(); // message end
		
		emit_sound(ent, CHAN_WEAPON, SOUND_BAT_MISS, 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		new owner = pev(ent, pev_owner)
		g_stop[owner] = 0
		set_pev(owner,pev_maxspeed,g_temp_speed[owner])
		
		engfunc(EngFunc_RemoveEntity,ent)
	}
	
	return HAM_IGNORED
}

public EntityTouchPost(ent,ptd)
{
	if(!pev_valid(ent)) return HAM_IGNORED
	
	new classname[32]
	pev(ent,pev_classname,classname,31)
	
	if(equal(classname,BAT_CLASSNAME))
	{
	
		if(!pev_valid(ptd))
		{
			static Float:origin[3];
			pev(ent,pev_origin,origin);
			
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
			write_byte(TE_EXPLOSION); // TE_EXPLOSION
			write_coord(floatround(origin[0])); // origin x
			write_coord(floatround(origin[1])); // origin y
			write_coord(floatround(origin[2])); // origin z
			write_short(spr_skull); // sprites
			write_byte(40); // scale in 0.1's
			write_byte(30); // framerate
			write_byte(14); // flags 
			message_end(); // message end
			
			emit_sound(ent, CHAN_WEAPON, SOUND_BAT_MISS, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			new owner = pev(ent, pev_owner)
			g_stop[owner] = 0
			set_pev(owner,pev_maxspeed,g_temp_speed[owner])
			
			engfunc(EngFunc_RemoveEntity,ent)
			
			return HAM_IGNORED
		}
		
		new owner = pev(ent,pev_owner)
		
		if(0 < ptd && ptd <= g_maxplayers && is_user_alive(ptd) && ptd != owner)
		{
			g_bat_enemy[ptd] = owner
			
			if(!zp_get_user_zombie(ptd)) set_user_rendering(ptd, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, 30)
			
			set_pev(ent,pev_nextthink,get_gametime()+banchee_skull_bat_catch_time)
			set_task(banchee_skull_bat_catch_time,"clear_stat2",ptd+TASK_REMOVE_STAT)
			set_pev(ent,pev_movetype,MOVETYPE_FOLLOW)
			set_pev(ent,pev_aiment,ptd)
			
			emit_sound(owner, CHAN_VOICE, SOUND_BAT_HIT, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			g_bat_stat[ptd] = 1
		}
	}
	
	return HAM_IGNORED
}

public clear_stat(taskid)
{
	new id = ID_TASK_REMOVE_STAT
	
	g_bat_stat[id] = 0
	g_bat_time[id] = 0
	
	zp_colored_print(id, "^x04[ZP]^x01 Ваша способность ^x04 'Летучие мыши'^x01 - готова!")
}

public clear_stat2(idx)
{
	new id = idx-TASK_REMOVE_STAT
	
	g_bat_enemy[id] = 0
	g_bat_stat[id] = 0
	g_no_fly[id] = true;
	set_task(3.0, "can_fly", id)
}
 
public can_fly(id)
{
	if(is_user_alive(id))
	{
		g_no_fly[id] = false;
		set_user_rendering(id)
	}
}


public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	
	if (!is_user_alive(id)) return;
	
	cmd_bat(id)
	
	set_task(random_float(5.0,15.0), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

fm_get_user_startpos(id,Float:forw,Float:right,Float:up,Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	engfunc(EngFunc_MakeVectors, vAngle)
	
	global_get(glb_v_forward, vForward)
	global_get(glb_v_right, vRight)
	global_get(glb_v_up, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

aim_at_origin(id, Float:target[3], Float:angles[3])
{
	static Float:vec[3]
	pev(id,pev_origin,vec)
	vec[0] = target[0] - vec[0]
	vec[1] = target[1] - vec[1]
	vec[2] = target[2] - vec[2]
	engfunc(EngFunc_VecToAngles,vec,angles)
	angles[0] *= -1.0
	angles[2] = 0.0
}

PlayWeaponAnimation(id, animation)
{
	set_pev(id, pev_weaponanim, animation)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(animation)
	write_byte(pev(id, pev_body))
	message_end()
}

reset_value_player(id)
{
	g_stop[id] = 0
	g_bat_time[id] = 0
	g_bat_stat[id] = 0
	g_bat_enemy[id] = 0
	g_cooldown[id] = 0
	g_no_fly[id] = false;

	remove_task(id+TASK_BOT_USE_SKILL)
	remove_task(id+TASK_REMOVE_STAT)
}

zp_colored_print(target, const message[], any:...)
{
	static buffer[512], i, argscount
	argscount = numargs()
	
	if (!target)
	{
		static player
		for (player = 1; player <= g_maxplayers; player++)
		{
			if (!is_user_connected(player))
				continue;
			
			static changed[5], changedcount
			changedcount = 0
			
			for (i = 2; i < argscount; i++)
			{
				if (getarg(i) == LANG_PLAYER)
				{
					setarg(i, 0, player)
					changed[changedcount] = i
					changedcount++
				}
			}
			
			vformat(buffer, charsmax(buffer), message, 3)
			
			message_begin(MSG_ONE_UNRELIABLE, g_msgSayText, _, player)
			write_byte(player)
			write_string(buffer)
			message_end()
			
			for (i = 0; i < changedcount; i++)
				setarg(changed[i], 0, LANG_PLAYER)
		}
	}
	else
	{
		vformat(buffer, charsmax(buffer), message, 3)
		
		message_begin(MSG_ONE, g_msgSayText, _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}

stock Anim(ent, sequence)
{
        set_pev(ent, pev_sequence, sequence)
        set_pev(ent, pev_animtime, halflife_time())
        set_pev(ent, pev_framerate, 1.0)       
}
