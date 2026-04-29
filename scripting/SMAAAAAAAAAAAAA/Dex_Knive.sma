/* 
	Связь с автором:
	Vk Page: 
	Vk Group: 
*/

//#define DEATHRUN								/* Раскомментируйте, если используете Дезран-модификацию */
#define ZOMBIEPLAGUE							/* Раскомментируйте, если используете Зомби-модификацию */

#include < amxmodx >
#include < hamsandwich >
#include < fakemeta_util >
#include < engine >
#if defined ZOMBIEPLAGUE
#include < zombieplague >
#endif

#define NAME 				"Knife Mode"
#define VERSION				"1.0"
#define AUTHOR				"Exodus"

#define COMMAND				"say /knife"				/* Команда, вызывающая меню ножей */

#define ACCESS_V			ADMIN_LEVEL_A		/* Флаг m для Вип-Ножа */
#define ACCESS_A			ADMIN_BAN			/* Флаг d Для Админ-Ножа */

#define SPEED_NORMAL		250.0				/* Нормальная скорость на сервере */
#define GRAVITY_NORMAL		0.9					/* Нормальная гравитация на сервере */
#define SPEED_POWER			290.0				/* Повышенная скорость от ножей */
#define GRAVITY_POWER		0.68				/* Пониженная гравитация от ножей */
#define DAMAGE_POWER		2.0					/* Повышенный множитель урона от ножей */

#define REGEN_TIME			5.0					/* Интервал времени, через которое будет прибавляться здоровье от ножей */
#define REGEN_AMOUNT		15					/* Колличество здоровья, которое будет прибавляться от ножей */
#define REGEN_MAXIMAL		200					/* Максимальное колличество здоровья на сервере */
#define POISON_TREATMENT	20.0				/* Время в секундах, за которое игрок будет вылечен от "Яда" */
#define POISON_TIME			5.0					/* Интервал времени, через которое будет работать навык "Яд" */
#define POISON_AMOUNT		25					/* Колличество здоровья, которое будет отниматься при отравлении */
#define POISON_MINIMAL		5					/* Минимальное колличество здоровья, ниже которого навык отравления не будет работать */
#define TIME_FREEZE			3.0					/* Время, через которое будет разморожен игрок при "Заморозке" */
#define TIME_PROTECT		5.0					/* Время, через которое будет окончена защита при "Заморозке" */

static 
	Knife_Menu, 
	Regen_Sprite,
	Poison_Sprite,
	Frost_Sprite,
	Frost_Gibs,
	Choosen_Knife[ 33 ], 
	Jumps_Amount[ 33 ], 
	Jumps_Done[ 33 ],
	bool: Has_Jumps[ 33 ],
	bool: Has_Damage[ 33 ],
	bool: Has_Poison[ 33 ],
	bool: Has_Freeze[ 33 ]

#if defined DEATHRUN
static 
	Duel_Mode[ 127 ]
#endif

static const Knife_Models[ 2 ][ 10 ][] = {
	{
		"" ,
		"models/Exodus_System/Knive/v_steels.mdl",
		"models/Exodus_System/Knive/v_combat.mdl",
		"models/Exodus_System/Knive/v_strong.mdl",
		"models/Exodus_System/Knive/v_dagger.mdl",
		"models/Exodus_System/Knive/v_kujang.mdl",
		"models/Exodus_System/Knive/v_splash.mdl",
		"models/Exodus_System/Knive/v_shiner.mdl",
		"models/Exodus_System/Knive/v_muerto.mdl",
		"models/Exodus_System/Knive/v_katana.mdl"
	},
	
	{
		"" ,
		"models/Exodus_System/Knive/p_steels.mdl",
		"models/Exodus_System/Knive/p_combat.mdl",
		"models/Exodus_System/Knive/p_strong.mdl",
		"models/Exodus_System/Knive/p_dagger.mdl",
		"models/Exodus_System/Knive/p_kujang.mdl",
		"models/Exodus_System/Knive/p_splash.mdl",
		"models/Exodus_System/Knive/p_shiner.mdl",
		"models/Exodus_System/Knive/p_muerto.mdl",
		"models/Exodus_System/Knive/p_katana.mdl"
	}
}

static const Sound_List[][] = {
	"Exodus_System/Knive/Regen.wav",
	"Exodus_System/Knive/Poison.wav",
	"Exodus_System/Knive/Freeze.wav",
	"Exodus_System/Knive/Unfreeze.wav"
}

public plugin_init() {
	register_plugin( NAME, VERSION, AUTHOR )
	
	Knife_Menu = menu_create( "Холодное оружие:", "Knife_Handle" )
	register_clcmd( COMMAND, "Knife_Function", ADMIN_ALL, "G_Knife_Menu" )
	Build_Menu()
	
	register_event( "CurWeapon", "Knife_Curweapon", "be", "1=1" )
	register_event( "HLTV", "Knife_Round", "a", "1=0", "2=0" )
	
	RegisterHam( Ham_TakeDamage, "player", "Knife_Damage", 0 )
	RegisterHam( Ham_Killed, "player", "Knife_Killed", 0 )
	RegisterHam( Ham_Item_Deploy, "weapon_knife", "Knife_Deploy", 1 )
	RegisterHam( Ham_Player_Jump, "player", "Knife_Jumps" )
	RegisterHam( Ham_Player_PostThink, "player", "Knife_Ability" )
}

public plugin_precache() {
	for( new a = 1; a < 10; a++ ) {
		precache_model( Knife_Models[ 0 ][ a ] )
		precache_model( Knife_Models[ 1 ][ a ] )
	}
	for( new b; b < sizeof Sound_List; b++ ) {
		precache_sound( Sound_List[ b ] )
	}
	Regen_Sprite = precache_model( "sprites/Exodus_System/Knive/Regen.spr" )
	Poison_Sprite = precache_model( "sprites/Exodus_System/Knive/Poison.spr" )
	Frost_Sprite = precache_model( "sprites/Exodus_System/Knive/Frost.spr" )
	Frost_Gibs = precache_model( "models/glassgibs.mdl" )
}

public client_authorized( iPlayer ) Choosen_Knife[ iPlayer ] = 1

public client_disconnect( iPlayer ) {
	Has_Poison[ iPlayer ] = false
	Has_Freeze[ iPlayer ] = false
}


public Build_Menu() {
	menu_additem( Knife_Menu, "Нож \ySteels | \rСкорость", "1" )
	menu_additem( Knife_Menu, "Нож \yCombat | \rГравитация", "2" )
	menu_additem( Knife_Menu, "Нож \yStrong | \rДвойной Урон", "3" )
	menu_additem( Knife_Menu, "Нож \yDagger | \rДвойной Прыжок", "4" )
	menu_additem( Knife_Menu, "Нож \yKujang | \rРегенерация", "5" )
	menu_additem( Knife_Menu, "Нож \ySplash | \rОтравление", "6" )
	menu_additem( Knife_Menu, "Нож \yShiner | \rЗаморозка", "7" )
	menu_additem( Knife_Menu, "Нож \yMuerto | Вип | \rСкорость|Урон|Прыжки|Яд", "8" )
	menu_additem( Knife_Menu, "Нож \yKatana | Админ | \rВсе Способности", "9" )
	menu_setprop( Knife_Menu, MPROP_BACKNAME, "Назад" ) 
	menu_setprop( Knife_Menu, MPROP_NEXTNAME, "Вперёд" )
	menu_setprop( Knife_Menu, MPROP_EXITNAME, "Выход" )
}

public Knife_Function( iPlayer ) {
	#if defined DEATHRUN
	get_cvar_string( "deathrun_mode", Duel_Mode, charsmax( Duel_Mode ) )
	#endif
	if( !is_user_alive( iPlayer ) ) {
		Color_Print( iPlayer, "!g[Ножи] Недоступны для мертвых!" )
		return
	}
	#if defined ZOMBIEPLAGUE
	else if( zp_get_user_zombie( iPlayer ) || zp_get_user_nemesis( iPlayer ) || zp_get_user_survivor( iPlayer ) ) {
		Color_Print( iPlayer, "!g[Ножи] Недоступны для зомби, немезиды или выжившего!" )
		return
	}
	#endif
	#if defined DEATHRUN
	else if( ( equal( Duel_Mode, "DUEL" ) ) ) {
		Color_Print( iPlayer, "!g[Ножи] Недоступны в дуэли!" )
		return
	}
	#endif
	else {
		menu_display( iPlayer, Knife_Menu, 0 )
	}
}

public Knife_Handle( iPlayer, menu, item ) {
	if( item < 0 ) {
		return PLUGIN_CONTINUE
	}
	new cmd[ 2 ]
	new access, callback
	menu_item_getinfo( menu, item, access, cmd,2, _, _, callback )
	new choice = str_to_num( cmd )
	switch ( choice ) {
		case 1: {
			Choosen_Knife[ iPlayer ] = 1
			Color_Print( iPlayer, "!g[Ножи] !teamВаша способность: !gСкорость" )
			Play_Anim( iPlayer )
		}
		case 2: {
			Choosen_Knife[ iPlayer ] = 2
			Color_Print( iPlayer, "!g[Ножи] !teamВаша способность: !gГравитация" )
			Play_Anim( iPlayer )
		}
		case 3: {
			Choosen_Knife[ iPlayer ] = 3
			Color_Print( iPlayer, "!g[Ножи] !teamВаша способность: !gУрон" )
			Play_Anim( iPlayer )
		}
		case 4: {
			Choosen_Knife[ iPlayer ] = 4
			Color_Print( iPlayer, "!g[Ножи] !teamВаша способность: !gДвойной Прыжок" )
			Play_Anim( iPlayer )
		}
		case 5: {
			Choosen_Knife[ iPlayer ] = 5
			Color_Print( iPlayer, "!g[Ножи] !teamВаша способность: !gРегенерация" )
			Play_Anim( iPlayer )
		}
		case 6: {
			Choosen_Knife[ iPlayer ] = 6
			Color_Print( iPlayer, "!g[Ножи] !teamВаша способность: !gОтравление" )
			Play_Anim( iPlayer )
		}
		case 7: {
			Choosen_Knife[ iPlayer ] = 7
			Color_Print( iPlayer, "!g[Ножи] !teamВаша способность: !gЗаморозка" )
			Play_Anim( iPlayer )
		}
		case 8: {
			if( get_user_flags( iPlayer ) & ACCESS_V ) {
				Choosen_Knife[ iPlayer ] = 8
				Color_Print( iPlayer, "!g[Ножи] !teamВаши способности: !gСкорость, Урон, Прыжки, Яд" )
				Play_Anim( iPlayer )
			}
			else {
				Knife_Function( iPlayer )
				Color_Print( iPlayer, "!g[Ножи] !teamСперва купи привелегию !gВип!" )
			}
		}
		case 9: {
			if( get_user_flags( iPlayer ) & ACCESS_A ) {
				Choosen_Knife[ iPlayer ] = 9
				Color_Print( iPlayer, "!g[Ножи] !teamВаши способности: !gВсе Возможные" )
				Play_Anim( iPlayer )
			}
			else {
				Knife_Function( iPlayer )
				Color_Print( iPlayer, "!g[Ножи] !teamСперва купи привелегию !gАдмин!" )
			}
		}
	}
	return PLUGIN_HANDLED
}

public Knife_Round() { 
	new iPlayers[ 32 ], iCount, iPlayer
	get_players( iPlayers, iCount, "ch" ) 
	for( new i = 0; i < iCount; i++ ) {
		iPlayer = iPlayers[ i ]
		if( Has_Poison[ iPlayer ] ) {
			Has_Poison[ iPlayer ] = false
		}
		if( Has_Freeze[ iPlayer ] ) {
			Has_Freeze[ iPlayer ] = false
		}
	}
}

public Knife_Curweapon( iPlayer ) {
	if( !is_user_alive( iPlayer ) )
		return
		
	#if defined ZOMBIEPLAGUE
	if( zp_get_user_zombie( iPlayer ) || zp_get_user_nemesis( iPlayer ) || zp_get_user_survivor( iPlayer ) ) {
		return
	}
	#endif
	#if defined DEATHRUN
	get_cvar_string( "deathrun_mode", Duel_Mode, charsmax( Duel_Mode ) )
	if( ( equal( Duel_Mode, "DUEL" ) ) ) {
		return
	}
	#endif
	if( get_user_weapon( iPlayer ) != CSW_KNIFE ) {
		Has_Damage[ iPlayer ] = false
		Has_Jumps[ iPlayer ] = false
		fm_set_user_gravity( iPlayer, GRAVITY_NORMAL )
		fm_set_user_maxspeed( iPlayer, SPEED_NORMAL )
		return
	}
	switch( Choosen_Knife[ iPlayer ] ) {
		case 1: {
			Has_Damage[ iPlayer ] = false
			Has_Jumps[ iPlayer ] = false
			fm_set_user_gravity( iPlayer, GRAVITY_NORMAL )
			fm_set_user_maxspeed( iPlayer, SPEED_POWER )
		}
		case 2: {
			Has_Damage[ iPlayer ] = true
			Has_Jumps[ iPlayer ] = false
			fm_set_user_gravity( iPlayer, GRAVITY_POWER )
			fm_set_user_maxspeed( iPlayer, SPEED_NORMAL )
		}
		case 3: {
			Has_Damage[ iPlayer ] = true
			Has_Jumps[ iPlayer ] = false
			fm_set_user_gravity( iPlayer, GRAVITY_NORMAL )
			fm_set_user_maxspeed( iPlayer, SPEED_NORMAL )
		}
		case 4: {
			Has_Damage[ iPlayer ] = false
			Has_Jumps[ iPlayer ] = true
			fm_set_user_gravity( iPlayer, GRAVITY_NORMAL )
			fm_set_user_maxspeed( iPlayer, SPEED_NORMAL )
		}
		case 5: {
			Has_Damage[ iPlayer ] = false
			Has_Jumps[ iPlayer ] = false
			fm_set_user_gravity( iPlayer, GRAVITY_NORMAL )
			fm_set_user_maxspeed( iPlayer, SPEED_NORMAL )
		}
		case 6: {
			Has_Damage[ iPlayer ] = true
			Has_Jumps[ iPlayer ] = false
			fm_set_user_gravity( iPlayer, GRAVITY_NORMAL )
			fm_set_user_maxspeed( iPlayer, SPEED_NORMAL )
		}
		case 7: {
			Has_Damage[ iPlayer ] = true
			Has_Jumps[ iPlayer ] = false
			fm_set_user_gravity( iPlayer, GRAVITY_NORMAL )
			fm_set_user_maxspeed( iPlayer, SPEED_NORMAL )
		}
		case 8: {
			Has_Damage[ iPlayer ] = true
			Has_Jumps[ iPlayer ] = true
			fm_set_user_gravity( iPlayer, GRAVITY_NORMAL )
			fm_set_user_maxspeed( iPlayer, SPEED_POWER )
		}
		case 9: {
			Has_Damage[ iPlayer ] = true
			Has_Jumps[ iPlayer ] = true
			fm_set_user_gravity( iPlayer, GRAVITY_POWER )
			fm_set_user_maxspeed( iPlayer, SPEED_POWER )
		}
	}
}

public Knife_Deploy( iEnt ) {
	if( pev_valid( iEnt ) != 2 )
		return HAM_HANDLED
		
	new iPlayer = get_pdata_cbase( iEnt, 41, 4 )
	  
	if( !is_user_alive( iPlayer ) )
		return HAM_IGNORED
	
	#if defined ZOMBIEPLAGUE
	if( zp_get_user_zombie( iPlayer ) || zp_get_user_nemesis( iPlayer ) || zp_get_user_survivor( iPlayer ) ) {
		return HAM_IGNORED
	}
	#endif
	#if defined DEATHRUN
	get_cvar_string( "deathrun_mode", Duel_Mode, charsmax( Duel_Mode ) )
	if( ( equal( Duel_Mode, "DUEL" ) ) ) {
		return HAM_IGNORED
	}
	#endif

	switch( Choosen_Knife[ iPlayer ] ) {
		case 1: {
			Has_Damage[ iPlayer ] = false
			Has_Jumps[ iPlayer ] = false
			fm_set_user_gravity( iPlayer, GRAVITY_NORMAL )
			fm_set_user_maxspeed( iPlayer, SPEED_POWER )
		}
		case 2: {
			Has_Damage[ iPlayer ] = true
			Has_Jumps[ iPlayer ] = false
			fm_set_user_gravity( iPlayer, GRAVITY_POWER )
			fm_set_user_maxspeed( iPlayer, SPEED_NORMAL )
		}
		case 3: {
			Has_Damage[ iPlayer ] = true
			Has_Jumps[ iPlayer ] = false
			fm_set_user_gravity( iPlayer, GRAVITY_NORMAL )
			fm_set_user_maxspeed( iPlayer, SPEED_NORMAL )
		}
		case 4: {
			Has_Damage[ iPlayer ] = false
			Has_Jumps[ iPlayer ] = true
			fm_set_user_gravity( iPlayer, GRAVITY_NORMAL )
			fm_set_user_maxspeed( iPlayer, SPEED_NORMAL )
		}
		case 5: {
			Has_Damage[ iPlayer ] = false
			Has_Jumps[ iPlayer ] = false
			fm_set_user_gravity( iPlayer, GRAVITY_NORMAL )
			fm_set_user_maxspeed( iPlayer, SPEED_NORMAL )
		}
		case 6: {
			Has_Damage[ iPlayer ] = true
			Has_Jumps[ iPlayer ] = false
			fm_set_user_gravity( iPlayer, GRAVITY_NORMAL )
			fm_set_user_maxspeed( iPlayer, SPEED_NORMAL )
		}
		case 7: {
			Has_Damage[ iPlayer ] = true
			Has_Jumps[ iPlayer ] = false
			fm_set_user_gravity( iPlayer, GRAVITY_NORMAL )
			fm_set_user_maxspeed( iPlayer, SPEED_NORMAL )
		}
		case 8: {
			Has_Damage[ iPlayer ] = true
			Has_Jumps[ iPlayer ] = true
			fm_set_user_gravity( iPlayer, GRAVITY_NORMAL )
			fm_set_user_maxspeed( iPlayer, SPEED_POWER )
		}
		case 9: {
			Has_Damage[ iPlayer ] = true
			Has_Jumps[ iPlayer ] = true
			fm_set_user_gravity( iPlayer, GRAVITY_POWER )
			fm_set_user_maxspeed( iPlayer, SPEED_POWER )
		}
	}
	set_pev( iPlayer, pev_viewmodel2, Knife_Models[ 0 ][ Choosen_Knife[ iPlayer ] ] )
	set_pev( iPlayer, pev_weaponmodel2, Knife_Models[ 1 ][ Choosen_Knife[ iPlayer ] ] )
	
	return HAM_IGNORED
}

public Knife_Damage( victim, inflictor, attacker, Float: damage, bits ) {
	if( !is_user_connected( attacker ) || get_user_weapon( attacker ) != CSW_KNIFE || get_user_team( victim ) == get_user_team( attacker ) || !is_user_alive( attacker ) )
		return HAM_IGNORED
	#if defined ZOMBIEPLAGUE
	if( zp_get_user_zombie( attacker ) || zp_get_user_nemesis( attacker ) || zp_get_user_survivor( attacker ) ) {
		return HAM_IGNORED
	}
	#endif
	#if defined DEATHRUN
	get_cvar_string( "deathrun_mode", Duel_Mode, charsmax( Duel_Mode ) )
	if( ( equal( Duel_Mode, "DUEL" ) ) ) {
		return HAM_IGNORED
	}
	#endif
	if( Choosen_Knife[ attacker ] == 3 ) {
		SetHamParamFloat( 4, damage * DAMAGE_POWER )
	}
	if( Choosen_Knife[ attacker ] == 6 ) {
		if( !Has_Poison[ victim ] ) {
			Func_Poison( victim )
		}
	}
	if( Choosen_Knife[ attacker ] == 7 ) {
		if( !Has_Freeze[ victim ] ) {
			Func_Freeze( victim )
		}
	}
	if( Choosen_Knife[ attacker ] == 8 ) {
		SetHamParamFloat( 4, damage * DAMAGE_POWER )
		if( !Has_Poison[ victim ] ) {
			Func_Poison( victim )
		}
	}
	if( Choosen_Knife[ attacker ] == 9 ) {
		SetHamParamFloat( 4, damage * DAMAGE_POWER )
		if( !Has_Poison[ victim ] ) {
			Func_Poison( victim )
		}
		if( !Has_Freeze[ victim ] ) {
			Func_Freeze( victim )
		}
	}
	return HAM_IGNORED
}

public Func_Poison( victim ) {
	Has_Poison[ victim ] = true
	Color_Print( victim, "!g[Здоровье] !teamВас отравили на 20 секунд!" )
	set_task( POISON_TREATMENT, "Treatment", 7513 + victim )
}

public Func_Freeze( victim ) {
	Screen_Fade( victim, 0, 0, 255, 90 )
	set_rendering( victim, kRenderFxGlowShell, 0, 100, 200, kRenderNormal, 30 )
	if( ~pev( victim, pev_flags ) & FL_FROZEN ) set_pev( victim, pev_flags, pev( victim, pev_flags ) | FL_FROZEN ) 
	new Float: Origin[ 3 ]
	pev( victim, pev_origin, Origin )
	Origin[ 2 ] -= 35.0
	Frost_Effect( Origin )
	emit_sound( victim, CHAN_BODY, Sound_List[ 2 ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
	Has_Freeze[ victim ] = true
	Color_Print( victim, "!g[Информация] !teamВы заморожены на 3 секунды!" )
	set_task( TIME_FREEZE, "Unfreeze", 7512 + victim )
	set_task( TIME_PROTECT, "Protect", 7511 + victim )
}

public Treatment( taskid ) {
	new id = taskid - 7513
	if( !is_user_alive( id ) ) {
		return
	}
	Has_Poison[ id ] = false
	Color_Print( id, "!g[Здоровье] !teamДействие яда успешно завершено!" )
}

public Unfreeze( taskid ) {
	new id = taskid - 7512
	if( !is_user_alive( id ) ) {
		return
	}
	set_rendering( id )
	if( pev( id, pev_flags ) & FL_FROZEN ) set_pev( id, pev_flags, pev( id, pev_flags ) & ~FL_FROZEN )
	emit_sound( id, CHAN_BODY, Sound_List[ 3 ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
	Color_Print( id, "!g[Информация] !teamВы разморожены и снова можете двигаться!" )
	
	static iOrigin[ 3 ]
	get_user_origin( id, iOrigin )

	message_begin( MSG_PVS, SVC_TEMPENTITY, iOrigin )
	write_byte( TE_BREAKMODEL )
	write_coord( iOrigin[ 0 ] )
	write_coord( iOrigin[ 1 ] )
	write_coord( iOrigin[ 2 ] + 24 )
	write_coord( 16 )
	write_coord( 16 )
	write_coord( 16 )
	write_coord( random_num( -50, 50 ) )
	write_coord( random_num( -50, 50 ) )
	write_coord( 25 )
	write_byte( 10 )
	write_short( Frost_Gibs )
	write_byte( 10 )
	write_byte( 25 )
	write_byte( 0x01 )
	message_end()
}

public Protect( taskid ) {
	new id = taskid - 7511
	if( !is_user_alive( id ) ) {
		return
	}
	Has_Freeze[ id ] = false
}

public Knife_Killed( victim, attacker, shouldgib ) {
	if( Has_Freeze[ victim ] ) {
		set_rendering( victim )
		if( pev( victim, pev_flags ) & FL_FROZEN ) set_pev( victim, pev_flags, pev( victim, pev_flags ) & ~FL_FROZEN )
		Has_Freeze[ victim ] = false
	}
	if( Has_Poison[ victim ] ) {
		Has_Poison[ victim ] = false
	}
}

public Knife_Jumps( iPlayer ) {
	if( Has_Jumps[ iPlayer ] ) {
		#if defined ZOMBIEPLAGUE
		if( zp_get_user_zombie( iPlayer ) || zp_get_user_nemesis( iPlayer ) || zp_get_user_survivor( iPlayer ) ) {
			return PLUGIN_CONTINUE
		}
		#endif
		#if defined DEATHRUN
		get_cvar_string( "deathrun_mode", Duel_Mode, charsmax( Duel_Mode ) )
		if( ( equal( Duel_Mode, "DUEL" ) ) ) {
			return PLUGIN_CONTINUE
		}
		#endif
		new szButton = pev( iPlayer, pev_button )
		new szOldButton = pev( iPlayer, pev_oldbuttons )
 
		if( ( szButton & IN_JUMP ) && !( pev( iPlayer, pev_flags ) & FL_ONGROUND ) && !( szOldButton & IN_JUMP ) ) {
			if( Choosen_Knife[ iPlayer ] == 4 || Choosen_Knife[ iPlayer ] == 8 || Choosen_Knife[ iPlayer ] == 9 ) {
				if( Jumps_Amount[ iPlayer ] < 1 ) {
					Jumps_Done[ iPlayer ] = true
					Jumps_Amount[ iPlayer ]++
					Jump_Think_Post( iPlayer )
					return PLUGIN_CONTINUE
				}
			}
		}
		if( ( szButton & IN_JUMP ) && ( pev( iPlayer, pev_flags) & FL_ONGROUND ) ) {
			Jumps_Amount[ iPlayer ] = 0
		}
	}
	return PLUGIN_CONTINUE
}

public Jump_Think_Post( iPlayer ) {
	if( Has_Jumps[ iPlayer ] ) {
		if( !is_user_alive( iPlayer ) ) {
			return PLUGIN_CONTINUE
		}
		#if defined ZOMBIEPLAGUE
		if( zp_get_user_zombie( iPlayer ) || zp_get_user_nemesis( iPlayer ) || zp_get_user_survivor( iPlayer ) ) {
			return PLUGIN_CONTINUE
		}
		#endif
		#if defined DEATHRUN
		get_cvar_string( "deathrun_mode", Duel_Mode, charsmax( Duel_Mode ) )
		if( ( equal( Duel_Mode, "DUEL" ) ) ) {
			return PLUGIN_CONTINUE
		}
		#endif
	
		if( Jumps_Done[ iPlayer ] ) {
			new Float:szVelocity[ 3 ]  
			pev( iPlayer, pev_velocity, szVelocity )
			szVelocity[ 2 ] = random_float( 295.0, 305.0 )
			set_pev( iPlayer, pev_velocity, szVelocity )
			Jumps_Done[ iPlayer ] = false
			return PLUGIN_CONTINUE
		}
	}
	return PLUGIN_CONTINUE
}

public Knife_Ability( iPlayer ) {
	if( get_user_weapon( iPlayer ) != CSW_KNIFE ) {
		return
	}
	#if defined ZOMBIEPLAGUE
	if( zp_get_user_zombie( iPlayer ) || zp_get_user_nemesis( iPlayer ) || zp_get_user_survivor( iPlayer ) ) {
		return
	}
	#endif
	#if defined DEATHRUN
	get_cvar_string( "deathrun_mode", Duel_Mode, charsmax( Duel_Mode ) )
	if( ( equal( Duel_Mode, "DUEL" ) ) ) {
		return
	}
	#endif
	new Float: gt = get_gametime()
	static Float: lim[ 33 ]
	if( lim[ iPlayer ] < gt ){
		lim[ iPlayer ]= gt + REGEN_TIME
		if( Choosen_Knife[ iPlayer ] == 5 || Choosen_Knife[ iPlayer ] == 9 ) {
			if( is_user_alive( iPlayer ) ) {
				if( get_user_health( iPlayer ) < REGEN_MAXIMAL ) {
				fm_set_user_health( iPlayer, get_user_health( iPlayer ) + min( ( REGEN_MAXIMAL - get_user_health( iPlayer ) ), REGEN_AMOUNT ) )
				client_cmd( iPlayer, "spk %s", Sound_List[ 0 ] )
				Color_Print( iPlayer, "!g[Здоровье] !teamВы восстановили %d здоровья", REGEN_AMOUNT )
				Screen_Fade( iPlayer, 0, 255, 20, 50 )
				new Float: Origin[ 3 ]
				pev( iPlayer, pev_origin, Origin )
				Origin[ 2 ] -= 35.0
				Regen_Effect( Origin )
				}
				else {
					return
				}
			}
		}
	}
	new Float: gt2 = get_gametime()
	static Float: lim2[ 33 ]
	if( lim2[ iPlayer ] < gt2 ){
		lim2[ iPlayer ]= gt2 + POISON_TIME
		if( Has_Poison[ iPlayer ] ) {
			if( is_user_alive( iPlayer ) ) {
				if( get_user_health( iPlayer ) > POISON_MINIMAL ) {
				fm_set_user_health( iPlayer, get_user_health( iPlayer ) - min( ( get_user_health( iPlayer ) - POISON_MINIMAL ), POISON_AMOUNT ) )
				client_cmd( iPlayer, "spk %s", Sound_List[ 1 ] )
				Color_Print( iPlayer, "!g[Здоровье] !teamВы отравлены и получаете %d урона от Яда.", POISON_AMOUNT )
				Screen_Fade( iPlayer, 255, 70, 20, 50 )
				new Float: Origin[ 3 ]
				pev( iPlayer, pev_origin, Origin )
				Origin[ 2 ] -= 35.0
				Poison_Effect( Origin )
				}
				else {
					return
				}
			}
		}
	}
}

stock Play_Anim( iPlayer ) {
	new iEnt = get_pdata_cbase( iPlayer, 373, 5 )
	if( pev_valid( iEnt ) && get_user_weapon( iPlayer ) == CSW_KNIFE ) {
		ExecuteHamB( Ham_Item_Deploy, iEnt )
	}
}

stock Regen_Effect( Float: origin[ 3 ] ) {
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_SPRITE )
	engfunc( EngFunc_WriteCoord, origin[ 0 ] )
	engfunc( EngFunc_WriteCoord, origin[ 1 ] )
	engfunc( EngFunc_WriteCoord, origin[ 2 ] + 45 )
	write_short( Regen_Sprite )
	write_byte( 15 )
	write_byte( 255 )
	message_end()
}

stock Poison_Effect( Float: origin[ 3 ] ) {
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_SPRITE )
	engfunc( EngFunc_WriteCoord, origin[ 0 ] )
	engfunc( EngFunc_WriteCoord, origin[ 1 ] )
	engfunc( EngFunc_WriteCoord, origin[ 2 ] + 45 )
	write_short( Poison_Sprite )
	write_byte( 15 )
	write_byte( 255 )
	message_end()
}

stock Frost_Effect( Float: origin[ 3 ] ) {
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( TE_SPRITETRAIL )
	engfunc( EngFunc_WriteCoord, origin[ 0 ] )
	engfunc( EngFunc_WriteCoord, origin[ 1 ] )
	engfunc( EngFunc_WriteCoord, origin[ 2 ] + 45 )
	engfunc( EngFunc_WriteCoord, origin[ 0 ] )
	engfunc( EngFunc_WriteCoord, origin[ 1 ] )
	engfunc( EngFunc_WriteCoord, origin[ 2 ] + 30 )
	write_short( Frost_Sprite )
	write_byte( 60 )
	write_byte( random_num( 25, 30 ) )
	write_byte( 2 )
	write_byte( 50 )
	write_byte( 10 )
	message_end()
}

stock Screen_Fade( iPlayer, Red, Green, Blue, Alpha ) {
	if( !is_user_connected( iPlayer ) ) {
		return
	}
	
	message_begin ( MSG_ONE_UNRELIABLE, get_user_msgid ( "ScreenFade" ), { 0, 0, 0 }, iPlayer )
	write_short ( 1 << 10 )
	write_short ( 1 << 11 )
	write_short ( 0x0000 )
	write_byte( Red )
	write_byte( Green )
	write_byte( Blue )
	write_byte( Alpha )
	message_end()
}

stock Color_Print( const iPlayer, const input[], any:... ) {
	new count = 1, players[ 32 ]
	static msg[ 191 ]
	vformat( msg, 190, input, 3 )
	replace_all( msg, 190, "!g", "^4" )
	replace_all( msg, 190, "!y", "^1" )
	replace_all( msg, 190, "!team", "^3" )
	if( iPlayer ) {
		players[ 0 ] = iPlayer
	}
	else {
		get_players( players, count, "ch" )
	}
	for ( new i = 0; i < count; i++ ) {
		if (is_user_connected( players[ i ] ) ) {
			message_begin( MSG_ONE_UNRELIABLE, get_user_msgid( "SayText" ), _, players[ i ] )
			write_byte( players[ i ] )
			write_string( msg )
			message_end()
		}
	}
}