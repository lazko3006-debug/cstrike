/*
	Проект: CS-MAKER.RU
	Группа проекта: https://vk.com/cs_maker_ru
*/

#include amxmodx
#include fakemeta_util
#include zombieplague


// ZOMBIE CLASS
new const szName[] = { "[Smoker]" };
new const szInfo[] = { "Hook [G]" };
new const szModel[] = { "zombie_class_smoker" };
new const szClawModel[] = { "zombie_knife/v_smoker.mdl" };
new const DragSoundMiss[] = "sound/Smoker_TongueHit_miss.wav";
new const DragSoundHit[] = "sound/Smoker_TongueHit_drag.wav";

const iHealth = 1800;
const iSpeed = 190;
const Float:flGravity = 1.0;
const Float:flKnockback = 1.0;

// DRAG ABILITY
const Float:DragTime = 5.0;		// Время притяжения
const Float:DragSpeed = 200.0;	// Скорость притяжения
const Float:DragTryTime = 10.0;	// Время перезарядки способности
const DragMaxDistance = 1500;	// Максимальная дистанция для притягивания
const DragMinDistance = 100;	// Минимальная дистанция для притягивания

// Variable
new Float:g_DragTime[33];
new g_iTarget[33];
new g_SpriteBeam;
new g_iRoundEnd;
new g_iSmoker;

public plugin_init() 
{
	register_plugin("[ZP] SMOKER ZOMBIE", "1.0", "Mr.Best");
	
	register_clcmd("drop", "push_button_g");
	register_forward(FM_PlayerPreThink,"fw_player_pre_think");
}

public plugin_precache()
{
	g_iSmoker = zp_register_zombie_class(szName, szInfo, szModel, szClawModel, iHealth, iSpeed, flGravity, flKnockback);
	g_SpriteBeam = precache_model("sprites/laserbeam.spr"); 
	precache_sound(DragSoundMiss);
	precache_sound(DragSoundHit);
}

public zp_round_ended() 	g_iRoundEnd = true;
public zp_round_started() 	g_iRoundEnd = false;

public zp_user_humanized_post(iPlayer, iSurvivor) 
{
	DragReset(iPlayer);
}

public zp_user_infected_post(iPlayer, iInfector, iNemesis)
{
	DragReset(iPlayer);
}

public push_button_g(iOwner) 
{
	if ( !zp_get_user_zombie(iOwner) || zp_get_user_nemesis(iOwner) || !is_user_alive(iOwner) )
		return PLUGIN_CONTINUE;
	
	if ( zp_get_user_zombie_class(iOwner) != g_iSmoker || g_iTarget[iOwner])
		return PLUGIN_CONTINUE;
	
	if ( task_exists(iOwner) )
		return PLUGIN_CONTINUE;
	
	static Float:flTimer[33];
	get_user_aiming(iOwner, g_iTarget[iOwner], .dist=DragMaxDistance);
	g_DragTime[iOwner] = get_gametime();
	
	if ( !g_iTarget[iOwner] && flTimer[iOwner] < g_DragTime[iOwner] )
	{
		flTimer[iOwner] = g_DragTime[iOwner] + DragTryTime;
			
		static Float:flAimPos[3];
		static intAimPos[3];
		
		fm_get_aim_origin(iOwner, flAimPos);
		intAimPos[0] = floatround(flAimPos[0]);
		intAimPos[1] = floatround(flAimPos[1]);
		intAimPos[2] = floatround(flAimPos[2]);
		LineEffect(iOwner, intAimPos);
	}
	
	if ( is_user_connected( g_iTarget[ iOwner ] ) && is_user_alive( g_iTarget[ iOwner ] ) )
		emit_sound(iOwner, CHAN_AUTO, DragSoundHit, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	else emit_sound(iOwner, CHAN_AUTO, DragSoundMiss, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	
	@Ability__Task(iOwner);
	return PLUGIN_HANDLED;
}

public fw_player_pre_think(iOwner)
{
	static iVictim; iVictim = g_iTarget[iOwner];

	if ( g_iRoundEnd || !iVictim )
		return FMRES_HANDLED;
	
	if ( !is_user_connected(iOwner) || !is_user_alive(iOwner) || !zp_get_user_zombie(iOwner) || zp_get_user_nemesis(iOwner) )
		return FMRES_HANDLED;

	if ( !is_user_connected(iVictim) || !is_user_alive(iVictim) || zp_get_user_zombie(iVictim) ) 
		return FMRES_HANDLED;
	
	if (get_gametime() - g_DragTime[iOwner] >= DragTime)
		return FMRES_IGNORED;
	
	static Float:flVictimPos[3];
	static Float:flOwnerPos[3];
	static Float:VELOCITY[3];
	static Float:VECTOR[3];
	static intVictimPos[3];
	static intOwnerPos[3];
	static iDistance;
	
	pev(iVictim, pev_origin, flVictimPos);
	pev(iOwner, pev_origin, flOwnerPos);
	iDistance = get_distance(intOwnerPos, intVictimPos);
	
	for ( new i = 0; i <= charsmax(flVictimPos); i++ ) 
	{
		intOwnerPos[i] = floatround(flOwnerPos[i]);
		intVictimPos[i] = floatround(flVictimPos[i]);
	}
	
	if ( iDistance <= DragMinDistance ) 
		return FMRES_IGNORED;
	
	xs_vec_sub(flOwnerPos, flVictimPos, VECTOR);
	xs_vec_normalize(VECTOR, VECTOR);
	xs_vec_mul_scalar(VECTOR, DragSpeed, VELOCITY);
	set_pev(iVictim, pev_velocity, VELOCITY);

	LineEffect2( iOwner, iVictim ) 
	return FMRES_IGNORED;
}


LineEffect(iOwner, const iEndPos[]) 
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTPOINT);
	write_short(iOwner);             			//Индекс entity
	write_coord(iEndPos[0]);    				//Конечная точка x
	write_coord(iEndPos[1]);    				//Конечная точка y
	write_coord(iEndPos[2]);    				//Конечная точка z
	write_short(g_SpriteBeam);     				//Индекс спрайта 
	write_byte(0);               				//Стартовый кадр
	write_byte(0);                 				//Скорость анимации
	write_byte(1);                 				//Врмея существования
	write_byte(3);               				//Толщина луча
	write_byte(0);               				//Искажение
	write_byte(255);       						//Цвет красный
	write_byte(50);								//Цвеи зеленый
	write_byte(0);								//Цвет синий
	write_byte(200);           					//Яркость
	write_byte(0);                 				//...
	message_end();
}

LineEffect2( pStartIndex, pEndIndex ) 
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMENTS);
	write_short(pStartIndex);             			//Индекс entity
	write_short(pEndIndex);             			//Индекс entity
	write_short(g_SpriteBeam);     				//Индекс спрайта 
	write_byte(0);               				//Стартовый кадр
	write_byte(0);                 				//Скорость анимации
	write_byte(1);                 				//Врмея существования
	write_byte(3);               				//Толщина луча
	write_byte(0);               				//Искажение
	write_byte(255);       						//Цвет красный
	write_byte(50);								//Цвеи зеленый
	write_byte(0);								//Цвет синий
	write_byte(200);           					//Яркость
	write_byte(0);                 				//...
	message_end();
}

DragReset(iOwner) 
{
	g_iTarget[iOwner] = 0;
	g_DragTime[iOwner] = 0.0;
	remove_task(iOwner);
}

@Ability__Task(iOwner)
{
	static Float:flTimer[33];
	
	if(!zp_get_user_zombie(iOwner) || zp_get_user_nemesis(iOwner))
	{
		flTimer[iOwner] = 0.0;
		DragReset(iOwner);
		return;
	}
	
	if ( flTimer[iOwner] > DragTryTime )
	{
		set_hudmessage(255, 50, 0, 0.75, 0.92, 1, 0.0, 0.8, 0.0, 0.2, -1);
		show_hudmessage(iOwner, "Притяжение готово [G]");
		
		flTimer[iOwner] = 0.0;
		DragReset(iOwner);
		return;
	}
	else
	{
		set_hudmessage(240, 100, 0, 0.75, 0.92, 0, 1.0, 1.1, 0.0, 0.0, -1);
		show_hudmessage(iOwner, "Перезарядка притяжения: [%.1f]", DragTryTime - flTimer[iOwner]);
		set_task(1.0, "@Ability__Task", iOwner)
		flTimer[iOwner]++;
	}
}