#include <amxmodx>
#include <fun>
#include <nvault>
#include <zombieplague>
#include <hamsandwich>
#include <colorchat> 

#define MAX_LVL 15
#define CHANCE_TO_GET_POINT 20 

new g_vault, g_sync_hud
new g_health_lvl[33], g_speed_lvl[33], g_damage_lvl[33], g_skill_points[33]

public plugin_init() {
    register_plugin("ZM RPG: Ultra Fix", "5.0", "AI_Assistant")
    
    // Регистрация команд с ПРИОРИТЕТОМ
    register_clcmd("say /skills", "show_skill_menu")
    register_clcmd("say_team /skills", "show_skill_menu")
    register_clcmd("chooseteam", "show_skill_menu")
    register_clcmd("jointeam", "show_skill_menu")
    register_clcmd("zm_skills", "show_skill_menu")

    register_event("CurWeapon", "event_curweapon", "be", "1=1")
    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
    
    g_vault = nvault_open("zm_skills_final_v5")
    g_sync_hud = CreateHudSyncObj()
    
    // Обновляем ОЧЕНЬ часто, чтобы перебить ZP сообщения
    set_task(0.1, "update_hud", 0, _, _, "b")
}

public show_skill_menu(id) {
    // Убираем проверку на зомби для самого ОТКРЫТИЯ меню (чтобы работало всегда)
    if (!is_user_connected(id)) return PLUGIN_HANDLED

    new menu = menu_create("\yМагазин навыков \r[RPG]", "menu_handler")
    new info[128], cost_h, cost_s, cost_d

    cost_h = get_upgrade_cost(g_health_lvl[id])
    cost_s = get_upgrade_cost(g_speed_lvl[id])
    cost_d = get_upgrade_cost(g_damage_lvl[id])

    formatex(info, charsmax(info), "\wДоступно очков: \r%d^n", g_skill_points[id])
    menu_addtext(menu, info, 0)

    formatex(info, charsmax(info), "%sЖивучесть \r[%d/%d] \y(%d очк.)", g_health_lvl[id] < MAX_LVL ? "\w" : "\d", g_health_lvl[id], MAX_LVL, cost_h)
    menu_additem(menu, info, "1")
    
    formatex(info, charsmax(info), "%sЛовкость \r[%d/%d] \y(%d очк.)", g_speed_lvl[id] < MAX_LVL ? "\w" : "\d", g_speed_lvl[id], MAX_LVL, cost_s)
    menu_additem(menu, info, "2")

    formatex(info, charsmax(info), "%sСила \r[%d/%d] \y(%d очк.)", g_damage_lvl[id] < MAX_LVL ? "\w" : "\d", g_damage_lvl[id], MAX_LVL, cost_d)
    menu_additem(menu, info, "3")
    
    menu_display(id, menu, 0)
    return PLUGIN_HANDLED // Возвращаем HANDLED, чтобы заблокировать стандартное меню М
}

public update_hud() {
    new players[32], num, id
    get_players(players, num, "ch")
    
    for (new i = 0; i < num; i++) {
        id = players[i]
        if (!zp_get_user_zombie(id)) {
            new dmg_pct = g_damage_lvl[id] * 3
            new speed_pct = g_speed_lvl[id] * 2
            new hp_bonus = g_health_lvl[id] * 20

            // Канал -1 заменен на стабильный Sync. Координаты 0.13 (высоко)
            set_hudmessage(255, 215, 0, 0.02, 0.13, 0, 0.0, 0.2, 0.0, 0.0, 2)
            
            ShowSyncHudMsg(id, g_sync_hud, 
                "Навыки:^nУровень: %d^nУрон: +%d%%^nСкорость: +%d%%^nЗдоровье: +%d HP^n^nОчки: %d [M - Меню]", 
                (g_health_lvl[id] + g_speed_lvl[id] + g_damage_lvl[id]), dmg_pct, speed_pct, hp_bonus, g_skill_points[id])
        }
    }
}

// ОСТАЛЬНОЙ КОД (меню_хандлер, урон, сейв) БЕЗ ИЗМЕНЕНИЙ
public menu_handler(id, menu, item) {
    if (item == MENU_EXIT) { menu_destroy(menu); return PLUGIN_HANDLED; }
    new name[32], cost; get_user_name(id, name, charsmax(name))
    switch(item) {
        case 0: {
            cost = get_upgrade_cost(g_health_lvl[id])
            if (g_health_lvl[id] < MAX_LVL && g_skill_points[id] >= cost) {
                g_health_lvl[id]++; g_skill_points[id] -= cost;
                set_user_health(id, get_user_health(id) + 20)
                ColorChat(0, GREEN, "^4[RPG] ^3%s ^1улучшил ^4Живучесть ^1до ^3%d ур!", name, g_health_lvl[id])
            }
        }
        case 1: {
            cost = get_upgrade_cost(g_speed_lvl[id])
            if (g_speed_lvl[id] < MAX_LVL && g_skill_points[id] >= cost) {
                g_speed_lvl[id]++; g_skill_points[id] -= cost;
                ColorChat(0, GREEN, "^4[RPG] ^3%s ^1улучшил ^4Ловкость ^1до ^3%d ур!", name, g_speed_lvl[id])
            }
        }
        case 2: {
            cost = get_upgrade_cost(g_damage_lvl[id])
            if (g_damage_lvl[id] < MAX_LVL && g_skill_points[id] >= cost) {
                g_damage_lvl[id]++; g_skill_points[id] -= cost;
                ColorChat(0, GREEN, "^4[RPG] ^3%s ^1улучшил ^4Сила ^1до ^3%d ур!", name, g_damage_lvl[id])
            }
        }
    }
    save_skills(id); show_skill_menu(id); menu_destroy(menu); return PLUGIN_HANDLED
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
    if (!is_user_connected(attacker) || zp_get_user_zombie(attacker) || attacker == victim) return HAM_IGNORED;
    if (g_damage_lvl[attacker] > 0) {
        new Float:bonus = 1.0 + (float(g_damage_lvl[attacker]) * 0.03)
        SetHamParamFloat(4, damage * bonus)
    }
    return HAM_HANDLED;
}

public event_curweapon(id) {
    if (!is_user_alive(id) || zp_get_user_zombie(id)) return;
    set_user_maxspeed(id, 250.0 + (float(g_speed_lvl[id]) * 5.0))
}

public zp_user_spawn_post(id) {
    if (is_user_alive(id) && !zp_get_user_zombie(id)) set_user_health(id, get_user_health(id) + (g_health_lvl[id] * 20))
}

public zp_user_killed(victim, attacker) {
    if (is_user_connected(attacker) && !zp_get_user_zombie(attacker)) {
        if (random_num(1, 100) <= CHANCE_TO_GET_POINT) {
            g_skill_points[attacker]++; client_print(attacker, print_center, "Вам доступно очко навыков!"); show_skill_menu(attacker)
        }
    }
}

get_upgrade_cost(level) {
    if (level < 5) return 1;
    if (level < 10) return 2;
    return 3;
}

public client_putinserver(id) load_skills(id)
public client_disconnected(id) save_skills(id)

save_skills(id) {
    new auth[32], vaultkey[64], vaultdata[64]
    get_user_authid(id, auth, charsmax(auth))
    format(vaultkey, charsmax(vaultkey), "%s-rpgv5", auth)
    format(vaultdata, charsmax(vaultdata), "%d %d %d %d", g_health_lvl[id], g_speed_lvl[id], g_damage_lvl[id], g_skill_points[id])
    nvault_set(g_vault, vaultkey, vaultdata)
}

load_skills(id) {
    new auth[32], vaultkey[64], vaultdata[64]
    get_user_authid(id, auth, charsmax(auth))
    format(vaultkey, charsmax(vaultkey), "%s-rpgv5", auth)
    if (nvault_get(g_vault, vaultkey, vaultdata, charsmax(vaultdata))) {
        new h[8], s[8], d[8], p[8]
        parse(vaultdata, h, 7, s, 7, d, 7, p, 7)
        g_health_lvl[id] = str_to_num(h); g_speed_lvl[id] = str_to_num(s); g_damage_lvl[id] = str_to_num(d); g_skill_points[id] = str_to_num(p)
    } else {
        g_health_lvl[id] = 0; g_speed_lvl[id] = 0; g_damage_lvl[id] = 0; g_skill_points[id] = 0
    }
}

public plugin_end() nvault_close(g_vault)