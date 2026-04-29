#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <zombieplague>
#include <fun>

#define PLUGIN "[ZP] Zombie Class: Heal"
#define VERSION "1.1"
#define AUTHOR "Dias"

#define RADIUS 300
#define TASK_COOLDOWN 11111

new g_zclass_doctor
new bool:can_heal[33]
new Spr

new cvar_heal_cooldown
new cvar_heal_mode
new cvar_heal_amount

new const zclass_name[] = {"[Зомби-Хилл]"} // Ten
new const zclass_info[] = {"[G -> Лечение вокруг]"} // Thong Tin
new const zclass_model[] = {"zombie_heal"} // Player Model
new const zclass_clawmodel[] = {"v_knife_heal.mdl"} // Hand Model
const zclass_health = 4500 // Mau
const zclass_speed = 245 // Toc Do
const Float:zclass_gravity = 0.8 // Trong Luc
const Float:zclass_knockback = 1.0 // Do Day Lui

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("drop", "use_skill")
	
	cvar_heal_cooldown = register_cvar("zp_healing_cooldown", "10")
	cvar_heal_mode = register_cvar("zp_healing_mode", "1") // 0 = zp_healing_amount | 1 = Max Zombie Health
	cvar_heal_amount = register_cvar("zp_healing_amount", "2000")
}

public plugin_precache()
{
	Spr = precache_model("sprites/zb3/zp_restore_health.spr")
	g_zclass_doctor = zp_register_zombie_class(zclass_name, zclass_info, zclass_model, zclass_clawmodel, zclass_health, zclass_speed, zclass_gravity, zclass_knockback)
	precache_sound("Heal.wav")
}

public zp_user_infected_post(id, infector)
{
	if (zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_doctor)
	{
		can_heal[id] = true	
		client_printc(id, "\g[ZP] \y You are Heal Zombie, Press (G) to Heal for You and for Your Team")
	}
}

public use_skill(id)
{
	if (is_user_alive(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_doctor && !zp_get_user_nemesis(id))
	{
		if(can_heal[id])
		{
			new Distance
			for (new i = 1; i <= get_maxplayers(); i++)
			{
				if (is_user_alive(i) && zp_get_user_zombie(i))
				{
					Distance = get_entity_distance(i, id)
					if (Distance <= RADIUS) 
					{
						new Float:Origin[3]
						pev(i, pev_origin, Origin)
						
						Origin[2] = Origin[2] + 20.0
						
						message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
						write_byte(TE_SPRITE)
						engfunc(EngFunc_WriteCoord, Origin[0])
						engfunc(EngFunc_WriteCoord, Origin[1])
						engfunc(EngFunc_WriteCoord, Origin[2])
						write_short(Spr) 
						write_byte(0) 
						write_byte(200)
						message_end()
						
						if(get_pcvar_num(cvar_heal_mode) == 0)
						{
							if(get_user_health(i) < zp_get_zombie_maxhealth(i))
							{
								set_user_health(i, get_user_health(i) + get_pcvar_num(cvar_heal_amount))
							}
						} else if(get_pcvar_num(cvar_heal_mode) == 1) {
							set_user_health(id, zp_get_zombie_maxhealth(id))
						}
						
						client_printc(i, "\g[ZP] \y You have been Healed !!!")
						client_cmd(i, "spk heal.wav")
					}
				}
			}
			
			can_heal[id] = false
			set_task(get_pcvar_float(cvar_heal_cooldown), "reset_cooldown", id+TASK_COOLDOWN)
		} else {
			client_printc(id, "\g[ZP] \y You can't Heal at this time...")
		}
	}
}

public reset_cooldown(taskid)
{
	new id = taskid - TASK_COOLDOWN
	if (is_user_alive(id) && zp_get_user_zombie(id) && zp_get_user_zombie_class(id) == g_zclass_doctor && !zp_get_user_nemesis(id))
	{
		can_heal[id] = true
		client_printc(id, "\g[ZP] \y Now. You can't use your skill. Press (G) to Heal for You and for Your Team")
	}
}

stock client_printc(const id, const string[], {Float, Sql, Resul,_}:...)
{
	new msg[191], players[32], count = 1;
	vformat(msg, sizeof msg - 1, string, 3);
	
	replace_all(msg,190,"\g","^4"); //绿色 Green
	replace_all(msg,190,"\y","^1"); //黄色 Yellow
	replace_all(msg,190,"\t","^3"); //队伍色 Team
	
	if(id)
		players[0] = id;
	else
		get_players(players,count,"ch");
	
	new index;
	for (new i = 0 ; i < count ; i++)
	{
		index = players[i];
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"),_, index);
		write_byte(index);
		write_string(msg);
		message_end();  
	}  
}