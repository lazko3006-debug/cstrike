#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <zombieplague>

#define PLUGIN "[ZP] Full Weapon Menu + Sound/Time"
#define VERSION "2.5"
#define AUTHOR "Community"

// Настройки
#define MENU_TIME_LIMIT 90.0 // Время в секундах, в течение которого можно брать оружие
#define OPEN_SOUND "buttons/lightswitch2.wav" // Путь к звуку (стандартный)

new g_primary[33], g_secondary[33]
new bool:g_save[33], bool:g_has_chosen[33]
new Float:g_round_start_time

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR)
    
    RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
    register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
    
    register_clcmd("buy", "clcmd_guns")
    register_clcmd("client_buy_open", "clcmd_guns")
    register_clcmd("say /guns", "clcmd_guns")
}

public plugin_precache() {
    precache_sound(OPEN_SOUND)
}

public event_round_start() {
    g_round_start_time = get_gametime()
}

public client_putinserver(id) {
    g_save[id] = false
    g_primary[id] = 0
    g_has_chosen[id] = false
}

public clcmd_guns(id) {
    if (!is_user_alive(id) || zp_get_user_zombie(id)) return PLUGIN_HANDLED;

    // Проверка времени
    if (get_gametime() - g_round_start_time > MENU_TIME_LIMIT) {
        client_print(id, print_center, "Время закупки (%.0f сек.) истекло!", MENU_TIME_LIMIT)
        return PLUGIN_HANDLED;
    }

    g_save[id] = false
    g_has_chosen[id] = false
    show_primary_menu(id)
    return PLUGIN_HANDLED;
}

public fw_PlayerSpawn_Post(id) {
    if (!is_user_alive(id) || zp_get_user_zombie(id) || zp_get_user_nemesis(id) || zp_get_user_survivor(id)) return;

    g_has_chosen[id] = false;

    if (g_save[id] && g_primary[id] != 0) {
        set_task(0.3, "give_weapons", id)
    } else {
        set_task(0.5, "show_primary_menu", id)
    }
}

public show_primary_menu(id) {
    if (!is_user_alive(id) || zp_get_user_zombie(id) || g_has_chosen[id]) return;
    
    // Воспроизводим звук открытия
    client_cmd(id, "spk %s", OPEN_SOUND)

    new menu = menu_create("\r[\yВыбор оружия\r]", "primary_handler")

    menu_additem(menu, "\wШтурмовая винтовка \yM4A1", "1")
    menu_additem(menu, "\wАвтомат \yAK-47", "2")
    menu_additem(menu, "\wПулемет \yM249", "3")
    menu_additem(menu, "\wАвто-дробовик \yXM1014", "4")
    menu_additem(menu, "\wСкорострелка \yG3SG1", "5")
    menu_additem(menu, "\wДробовик \yM3", "6")
    
    new save_status[64]
    formatex(save_status, charsmax(save_status), "\wЗапомнить выбор: %s^n", g_save[id] ? "\y[ДА]" : "\r[НЕТ]")
    menu_additem(menu, save_status, "8")

    menu_setprop(menu, MPROP_EXITNAME, "\rВыход")
    menu_display(id, menu, 0)
}

public primary_handler(id, menu, item) {
    if (item == MENU_EXIT || !is_user_alive(id)) {
        menu_destroy(menu); return PLUGIN_HANDLED;
    }

    new data[6], iName[64], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), iName, charsmax(iName), callback)
    new key = str_to_num(data)

    if (key == 8) {
        g_save[id] = !g_save[id]
        show_primary_menu(id)
    } else {
        g_primary[id] = key
        show_secondary_menu(id)
    }

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public show_secondary_menu(id) {
    if (!is_user_alive(id) || zp_get_user_zombie(id)) return;

    new menu = menu_create("\r[\yВыбор пистолета\r]", "secondary_handler")

    menu_additem(menu, "\wПистолет \yDesert Eagle", "1")
    menu_additem(menu, "\wПистолет \yGlock-18", "2")
    menu_additem(menu, "\wПистолет \yUSP", "3")
    menu_additem(menu, "\wДвойные пистолеты \yDual Elite", "4")

    menu_setprop(menu, MPROP_EXITNAME, "\rВыход")
    menu_display(id, menu, 0)
}

public secondary_handler(id, menu, item) {
    if (item == MENU_EXIT || !is_user_alive(id)) {
        menu_destroy(menu); return PLUGIN_HANDLED;
    }

    new data[6], iName[64], access, callback
    menu_item_getinfo(menu, item, access, data, charsmax(data), iName, charsmax(iName), callback)
    
    g_secondary[id] = str_to_num(data)
    g_has_chosen[id] = true
    give_weapons(id)

    menu_destroy(menu)
    return PLUGIN_HANDLED
}

public give_weapons(id) {
    if (!is_user_alive(id) || zp_get_user_zombie(id)) return;

    strip_user_weapons(id)
    give_item(id, "weapon_knife")

    switch(g_primary[id]) {
        case 1: { give_item(id, "weapon_m4a1"); cs_set_user_bpammo(id, CSW_M4A1, 250); }
        case 2: { give_item(id, "weapon_ak47"); cs_set_user_bpammo(id, CSW_AK47, 250); }
        case 3: { give_item(id, "weapon_m249"); cs_set_user_bpammo(id, CSW_M249, 250); }
        case 4: { give_item(id, "weapon_xm1014"); cs_set_user_bpammo(id, CSW_XM1014, 250); }
        case 5: { give_item(id, "weapon_g3sg1"); cs_set_user_bpammo(id, CSW_G3SG1, 250); }
        case 6: { give_item(id, "weapon_m3"); cs_set_user_bpammo(id, CSW_M3, 250); }
    }

    switch(g_secondary[id]) {
        case 1: { give_item(id, "weapon_deagle"); cs_set_user_bpammo(id, CSW_DEAGLE, 100); }
        case 2: { give_item(id, "weapon_glock18"); cs_set_user_bpammo(id, CSW_GLOCK18, 100); }
        case 3: { give_item(id, "weapon_usp"); cs_set_user_bpammo(id, CSW_USP, 100); }
        case 4: { give_item(id, "weapon_elite"); cs_set_user_bpammo(id, CSW_ELITE, 100); }
    }

    give_item(id, "weapon_hegrenade")
    give_item(id, "weapon_flashbang")
    give_item(id, "weapon_smokegrenade")
    cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM)
    
    g_has_chosen[id] = true
}