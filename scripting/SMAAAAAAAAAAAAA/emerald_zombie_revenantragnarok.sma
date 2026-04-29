#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <zombieplague>
#include <cstrike>

#define OFFSET_MODELINDEX 491
#define OFFSET_LINUX 5 

new const thunder_sound[] = "ambience/thunder_clap.wav";
new const zclass_name[] = { "[Ревенант Ragnarok]" } // name
new const zclass_info[] = { "\r[Шар на G|SPONSOR]" } // description
new const zclass_model[] = { "revenant_hell" } // model
new const zclass_clawmodel[] = { "v_revenant_hell.mdl" } // claw model
new const g_vgrenade[] = "models/zombie_plague/v_bomb_revenant_hell.mdl"
const zclass_health = 11000 // health
const zclass_speed = 350 // speed
const Float:zclass_gravity = 0.7 // gravity
const Float:zclass_knockback = 1.0 // knockback

new index, defaultindex, model_gibs2

new g_zclassthunder , g_msgScreenShake
new cvar_thunderrad , cvar_thunderdmg , cvar_thunderdelay
new g_lightning, g_smoke , g_can[33] , g_msgScoreInfo

public plugin_precache()
{
	register_plugin("[ZP] Zombie Class: Revenant Ragnarok", "0.1", "Emerald")

	g_msgScreenShake = get_user_msgid("ScreenShake")

	cvar_thunderrad = register_cvar("zp_classthunder_rad","80.0")
	cvar_thunderdmg = register_cvar("zp_classthunder_dmg","60.0")
	cvar_thunderdelay = register_cvar("zp_classthunder_delay","10")

	precache_sound( thunder_sound );
	g_lightning = precache_model( "sprites/lgtning.spr" );
	g_smoke = precache_model( "sprites/steam1.spr" );

	register_clcmd("drop","thunder_cmd")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");
	model_gibs2 = precache_model("sprites/zombie_plague/holybomb_exp.spr")

	g_msgScoreInfo = get_user_msgid("ScoreInfo")
		
	precache_model(g_vgrenade)

	g_zclassthunder = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)

	index = precache_model("models/player/revenant_hell/revenant_hell.mdl")
    defaultindex = precache_model("models/player.mdl")
}

public thunder_cmd( id )
{
	if( !is_user_alive(id) || !zp_get_user_zombie(id) || zp_get_user_zombie_class(id) != g_zclassthunder)
		return PLUGIN_CONTINUE;

	if(g_can[id]) 
	{
		client_print(id,print_center,"Востановление через %d сек.",g_can[id])
		return PLUGIN_HANDLED;
	}

	new vorigin[ 3 ], pos[ 3 ] , lightor[3] , Float:flvorigin[3];

	get_user_origin(id, vorigin, 3)

	flvorigin[0] = float(vorigin[0])
	flvorigin[1] = float(vorigin[1])
	flvorigin[2] = float(vorigin[2])

	pos[ 0 ] = vorigin[ 0 ] ;
	pos[ 1 ] = vorigin[ 1 ] ;
	pos[ 2 ] = vorigin[ 2 ] + 1600;

	lightor[ 0 ] = vorigin[ 0 ] ;
	lightor[ 1 ] = vorigin[ 1 ];
	lightor[ 2 ] = vorigin[ 2 ] + 80;

	vorigin[2] += 80
	
	Thunder( pos, vorigin , lightor);
	Smoke( vorigin, 10, 10 );
	
	for(new i = 1; i < 33; i++)
	{
		if (is_user_alive(i) && !zp_get_user_zombie(i))
		{
			new Float:VictimOrigin[3], Float:distance
			pev(i, pev_origin, VictimOrigin)
			
			distance = get_distance_f(VictimOrigin, flvorigin )
			
			if (distance <= get_pcvar_float(cvar_thunderrad))
			{
				message_begin(MSG_ONE, g_msgScreenShake, {0,0,0}, i)
				write_short(1<<14) // Amount
				write_short(1<<14) // Duration
				write_short(1<<14) // Frequency
				message_end()
				
				radius_damage_ab(flvorigin , VictimOrigin , i , id)
			}
		}
	}

	g_can[id] = get_pcvar_num(cvar_thunderdelay)
	set_task(1.0,"ability_zero",id)
	func_break2(id)
	
	return PLUGIN_HANDLED;
}

public func_break2(id)
{
	new origin[3]
   
	get_user_origin(id,origin,3)
   
	message_begin(MSG_ALL,SVC_TEMPENTITY,{0,0,0},id)
	write_byte(TE_SPRITETRAIL)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+20)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2]+80)
	write_short(model_gibs2)
	write_byte(20)
	write_byte(20)
	write_byte(4)
	write_byte(20)
	write_byte(10)
	message_end()
}

public radius_damage_ab(Float:originF[3] , Float:flOrigin[3] , iVictim , iAttacker)
{
	new Float:dist = get_distance_f(originF, flOrigin);
	new Float:dmg = get_pcvar_float(cvar_thunderdmg) - ( get_pcvar_float(cvar_thunderdmg) / get_pcvar_float(cvar_thunderrad) ) * dist;

	if(pev(iVictim,pev_health) - dmg <= 0) 
	{
		new headshot
		if(dist < 20.0) headshot = 1
		if(dist >= 20.0) headshot = 0
		message_begin( MSG_ALL, get_user_msgid("DeathMsg"),{0,0,0},0)
		write_byte(iAttacker)
		write_byte(iVictim)
		write_byte(headshot)
		write_string("thunder")
		message_end()

		user_silentkill(iVictim)

		set_pev(iAttacker, pev_frags, float(pev(iAttacker, pev_frags) + 1))
		fm_cs_set_user_deaths(iVictim, cs_get_user_deaths(iVictim) + 1)

		message_begin(MSG_BROADCAST, g_msgScoreInfo)
		write_byte(iAttacker) // id
		write_short(pev(iAttacker, pev_frags)) // frags
		write_short(cs_get_user_deaths(iAttacker)) // deaths
		write_short(0) // class?
		write_short(fm_cs_get_user_team(iAttacker)) // team
		message_end()
		
		message_begin(MSG_BROADCAST, g_msgScoreInfo)
		write_byte(iVictim) // id
		write_short(pev(iVictim, pev_frags)) // frags
		write_short(cs_get_user_deaths(iVictim)) // deaths
		write_short(0) // class?
		write_short(fm_cs_get_user_team(iVictim)) // team
		message_end()

	}else{
		set_pev(iVictim , pev_health , pev(iVictim,pev_health) - dmg)
	}
}

public zp_user_humanized_post(id)
{
	fm_set_user_model_index(id, defaultindex)
 	remove_values(id)
}
public fw_PlayerKilled(id, attacker, shouldgib) remove_values(id)
public client_connect(id)  remove_values(id)

public remove_values(id)
{
	remove_task(id)
	g_can[id] = 0
}

public ability_zero(id) 
{
	g_can[id] -= 1
	if(!g_can[id]) client_print(id,print_center,"Способность активна!")
	if(g_can[id]) set_task(1.0,"ability_zero",id)
}

public zp_user_infected_post(id) 
{
	if((zp_get_user_zombie_class(id) == g_zclassthunder) && (zp_get_user_zombie(id)))
	{
		fm_set_user_model_index(id, index)
	}
	remove_values(id)
}

public zp_user_infected_pre(id)
{
    if(!(get_user_flags(id) & ADMIN_CHAT))
    {
        if (zp_get_user_next_class(id) == g_zclassthunder)
        {
            zp_set_user_zombie_class(id, 0)
        }
    }
}

public Event_CurWeapon(id)    
{   
    new weaponID = read_data(2)    

    if(!zp_get_user_zombie(id) || !is_user_alive(id) || zp_get_user_zombie_class(id) != g_zclassthunder)   
    return PLUGIN_CONTINUE   

    if(weaponID == CSW_HEGRENADE ) 
    { 
        set_pev(id, pev_viewmodel, engfunc(EngFunc_AllocString, g_vgrenade))    
    }  
    if(weaponID == CSW_FLASHBANG ) 
    { 
        set_pev(id, pev_viewmodel, engfunc(EngFunc_AllocString, g_vgrenade))     
    }  
    if(weaponID == CSW_SMOKEGRENADE ) 
    { 
        set_pev(id, pev_viewmodel, engfunc(EngFunc_AllocString, g_vgrenade))    
    }  
    return PLUGIN_CONTINUE    
}

Thunder( start[ 3 ], end[ 3 ] , lightor[3])
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY ); 
	write_byte( TE_BEAMPOINTS ); 
	write_coord( start[ 0 ] ); 
	write_coord( start[ 1 ] ); 
	write_coord( start[ 2 ] ); 
	write_coord( end[ 0 ] ); 
	write_coord( end[ 1 ] ); 
	write_coord( end[ 2 ] - 75 ); 
	write_short( g_lightning ); 
	write_byte( 1 );
	write_byte( 5 );
	write_byte( 7 );
	write_byte( 20 );
	write_byte( 30 );
	write_byte( 200 ); 
	write_byte( 200 );
	write_byte( 200 );
	write_byte( 200 );
	write_byte( 200 );
	message_end();
	
	message_begin( MSG_PVS, SVC_TEMPENTITY, end );
	write_byte( TE_SPARKS );
	write_coord( end[ 0 ]  );
	write_coord( end[ 1 ]);
	write_coord( end[ 2 ] - 75);
	message_end();


	message_begin( MSG_PVS, SVC_TEMPENTITY, end );
	write_byte( TE_DLIGHT );
	write_coord( lightor[ 0 ]  );
	write_coord( lightor[ 1 ]);
	write_coord( lightor[ 2 ] );
	write_byte(20) 
	write_byte(0)
	write_byte(255) 
	write_byte(240) 
	write_byte(2) 
	write_byte(0) 
	message_end();

	emit_sound( 0 ,CHAN_ITEM, thunder_sound, 1.0, ATTN_NORM, 0, PITCH_NORM );
}

Smoke( iorigin[ 3 ], scale, framerate )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_SMOKE );
	write_coord( iorigin[ 0 ] );
	write_coord( iorigin[ 1 ] );
	write_coord( iorigin[ 2 ] );
	write_short( g_smoke );
	write_byte( scale );
	write_byte( framerate );
	message_end();
}


stock fm_cs_set_user_deaths(id, value)
{
	set_pdata_int(id, 444, value, 5)
}

stock fm_cs_get_user_team(id)
{
	return get_pdata_int(id, 114, 5);
}

stock fm_set_user_model_index(id, value)
{
    set_pdata_int(id, OFFSET_MODELINDEX, value, OFFSET_LINUX)
}  
