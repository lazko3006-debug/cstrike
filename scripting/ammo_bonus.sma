/*
	Проект:
	Группа проекта:
*/

#include amxmodx
#include nvault

native zp_set_user_ammo_packs(id, amount);
native zp_get_user_ammo_packs(id);

// Размер бонуса в аммо
#define BONUS_AMMO 500

// Команда для получения бонуса
#define BONUS_COMMAND "say /bonus"

// Откат бонуса, через сколько секунд он будет доступен
// 86400 сек == 24 часам;
#define BONUS_COUNTDOWN 86400

new g_Vault;
new g_iUserTime[33];
	
public plugin_init()
{
	register_plugin("(LITE-AMX) Daily Bonus", "1.0", "gajerek")
	register_clcmd(BONUS_COMMAND, "CMDGetBonus");	
	g_Vault = nvault_open("liteamxx_dailybonus");
}

public plugin_end() 
{
	nvault_close(g_Vault);
}

public client_putinserver(iPlayer)
{
	g_iUserTime[iPlayer] = 0;
	LoadData(iPlayer);
}

#if AMXX_VERSION_NUM < 183
public client_disconnect(iPlayer)
{
	SaveData(iPlayer);
	g_iUserTime[iPlayer] = 0;
}
#else
public client_disconnected(iPlayer)
{
	SaveData(iPlayer);
	g_iUserTime[iPlayer] = 0;
}	
#endif


public CMDGetBonus(iPlayer)
{
	if(get_systime() < g_iUserTime[iPlayer]) 
	{
		SendMessage(iPlayer, .access_bonus = false)
	}
	else
	{
		g_iUserTime[iPlayer] = get_systime() + BONUS_COUNTDOWN;
		zp_set_user_ammo_packs(iPlayer, zp_get_user_ammo_packs(iPlayer) + BONUS_AMMO);
		SendMessage(iPlayer, .access_bonus = true)
	}
}

SaveData(iPlayer)
{
	new AuthID[35];
	get_user_authid(iPlayer, AuthID, charsmax(AuthID));
	
	if(AuthID[0]) // Проверка, что AuthID получен
	{
		new VaultData[16];
		num_to_str(g_iUserTime[iPlayer], VaultData, charsmax(VaultData));
		nvault_set(g_Vault, AuthID, VaultData);
	}
}

LoadData(iPlayer)
{
	new AuthID[35];
	get_user_authid(iPlayer, AuthID, charsmax(AuthID));
	
	if(AuthID[0])
	{
		g_iUserTime[iPlayer] = nvault_get(g_Vault, AuthID);
	}
}


#if AMXX_VERSION_NUM < 183
stock SendMessage(iPlayer, access_bonus=true) 
{
	new time[3];
	time = SecondToTime(g_iUserTime[iPlayer]);
	
	switch ( access_bonus )
	{
		case true:  client_print(iPlayer, print_chat, "[LITE-AMX] Ежеднвеный бонус: +%d", BONUS_AMMO);
		case false:	client_print(iPlayer, print_chat, "[LITE-AMX] Вы уже брали, бонус, ждите: [%02d:%02d:%02d]", time[0], time[1], time[2]);
	}
}
#else
stock SendMessage(iPlayer, access_bonus=true) 
{
	new time[3];
	time = SecondToTime(g_iUserTime[iPlayer]);
	
	switch ( access_bonus )
	{
		case true:  client_print_color(iPlayer, print_team_grey, "^4[LITE-AMX] ^3Ежедневный бонус: ^1+%d", BONUS_AMMO);
		case false:	client_print_color(iPlayer, print_team_red, "^4[LITE-AMX] ^3Вы уже брали бонус, ждите: ^1[%02d:%02d:%02d]", time[0], time[1], time[2]);
	}
}
#endif

stock SecondToTime(time)
{
	new output[3];
	new current_second;

	current_second = time - get_systime();
	output[2] = ((current_second % 3600) % 60);
	output[1] = ((current_second % 3600) / 60);
	output[0] = current_second / 3600;
	return output;
}
