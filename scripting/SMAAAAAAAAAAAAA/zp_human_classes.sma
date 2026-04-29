#define PLUGIN_NAME			"[ZP] Human Classes (1.3)"
#define PLUGIN_VERSION		"1.3 - 01.09.2014"
#define PLUGIN_AUTHOR		"TERKECOREJZ"

#define ADMIN_FLAG			ADMIN_LEVEL_A

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <zombieplague>

new SayText, g_class[33]

#define MODEL_FEMALE		"hcfemale"
#define MODEL_MALE			"hcmale"
#define SUBMODEL_ONE		"0" // David Black | Choi Ji Yoon Limited
#define SUBMODEL_TWO		"1" // Asia Red Army | Alice Limited
#define SUBMODEL_THREE		"2" // Spade | Gunsmith
#define SUBMODEL_FOUR		"3" // Gerrard | Yuri Limited

#define HUMAN_GERRARD		"Gerrard"
#define HUMAN_DAVIDBLACK	"David Black"
#define HUMAN_ARA			"Asia Red Army"
#define HUMAN_SPADE			"Spade"
#define HUMAN_YURI2			"Yuri Limited"
#define HUMAN_ALICE2		"Alice Limited"
#define HUMAN_GUNSMITH		"Gunsmith"
#define HUMAN_CHOIJIYOON2	"Choi Ji Yoon Limited"

enum
{
	CLASS_GERRARD,
	CLASS_DAVIDBLACK,
	CLASS_ARA,
	CLASS_SPADE,
	CLASS_YURI2,
	CLASS_ALICE2,
	CLASS_GUNSMITH,
	CLASS_CHOIJIYOON2,
	CLASS_NULL
}

public plugin_init() {
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_clcmd("say /hc", "open_menu")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Spawn, "player", "Spawn_post", 1)
	register_menucmd(register_menuid("Menu Classes"), 1023, "menu_handler")
	register_menucmd(register_menuid("Menu Male"), 1023, "menu_male")
	register_menucmd(register_menuid("Menu Female"), 1023, "menu_female")
	SayText = get_user_msgid("SayText")
	register_dictionary("zp_human_classes.txt");}

public zp_user_humanized_post(id) open_menu(id)
	
public Spawn_post(id){
	if(!is_user_alive(id) && zp_get_user_zombie(id))
		return
		
	open_menu(id)
	new random = random_num(0, 2)
	switch(random){
		case 0: {
			zp_override_user_model(id, MODEL_MALE)
			set_pev(id, pev_body, SUBMODEL_FOUR);}
		case 1: {
			zp_override_user_model(id, MODEL_MALE)
			set_pev(id, pev_body, SUBMODEL_TWO);}
		case 2: {
			zp_override_user_model(id, MODEL_MALE)
			set_pev(id, pev_body, SUBMODEL_ONE);} } }
	
public plugin_precache(){
	new model[33]
	
	format(model, charsmax(model), "models/player/hcfemale/hcfemale.mdl", MODEL_FEMALE, MODEL_FEMALE)
	engfunc(EngFunc_PrecacheModel, model)
	format(model, charsmax(model), "models/player/hcmale/hcmale.mdl", MODEL_MALE, MODEL_MALE)
	engfunc(EngFunc_PrecacheModel, model);}
	
public client_connect(id) g_class[id] = CLASS_GERRARD
	
public open_menu(id) {
	if(is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_survivor(id)){
		new menu[512], len, keys = MENU_KEY_0
		len += formatex(menu[len], charsmax(menu) - len, "\w%L", id, "HC_MENU_CLASSES_TITLE")
		len += formatex(menu[len], charsmax(menu) - len, "^n\w%L \y[%s]^n^n", id, "HC_CURRENT_CLASS", g_class[id] == CLASS_GERRARD ? HUMAN_GERRARD : g_class[id] == CLASS_DAVIDBLACK ? HUMAN_DAVIDBLACK : g_class[id] == CLASS_ARA ? HUMAN_ARA : g_class[id] == CLASS_SPADE ? HUMAN_SPADE : g_class[id] == CLASS_YURI2 ? HUMAN_YURI2 : g_class[id] == CLASS_ALICE2 ? HUMAN_ALICE2 : g_class[id] == CLASS_GUNSMITH ? HUMAN_GUNSMITH : HUMAN_CHOIJIYOON2)
		len += formatex(menu[len], charsmax(menu) - len, "\r1. \w%L\w^n", id, "HC_MENU_CLASS_MALE_TITLE")
		keys += MENU_KEY_1
		len += formatex(menu[len], charsmax(menu) - len, "\r2. \w%L\w^n", id, "HC_MENU_CLASS_FEMALE_TITLE")
		keys += MENU_KEY_2
		len += formatex(menu[len], charsmax(menu) - len, "^n\r0. \w%L", id, "HC_EXIT_PAGE")
		if (pev_valid(id) == 2) set_pdata_int(id, 205, 0, 5)
		show_menu(id, keys, menu, -1, "Menu Classes")
		return PLUGIN_HANDLED;}
	return PLUGIN_HANDLED;}
	
public open_menu_male(id){
	if(is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_survivor(id)){
		new menu[512], len, keys = MENU_KEY_0
		len += formatex(menu[len], charsmax(menu) - len, "\w%L^n^n", id, "HC_MENU_CLASS_MALE_TITLE")
		len += formatex(menu[len], charsmax(menu) - len, "\r1. \w%s\w^n", HUMAN_GERRARD)
		keys += MENU_KEY_1
		len += formatex(menu[len], charsmax(menu) - len, "\r2. \w%s\w^n", HUMAN_DAVIDBLACK)
		keys += MENU_KEY_2
		len += formatex(menu[len], charsmax(menu) - len, "\r3. \w%s\w^n", HUMAN_ARA)
		keys += MENU_KEY_3
		if(get_user_flags(id) & ADMIN_FLAG){
			len += formatex(menu[len], charsmax(menu) - len, "\r4. \w%s \d- \y[%L] \d- \r[VIP]\w\^n^n", HUMAN_SPADE, id, "HC_BONUS_DAMAGE")
			keys += MENU_KEY_4
		} else {
			len += formatex(menu[len], charsmax(menu) - len, "\r4. \d%s - \y[%L] \d- \r[VIP]\w\^n^n", HUMAN_SPADE, id, "HC_BONUS_DAMAGE")
			keys += MENU_KEY_4;}
		len += formatex(menu[len], charsmax(menu) - len, "^n\r9. \w%L", id, "HC_BACK_PAGE")
		keys += MENU_KEY_9
		len += formatex(menu[len], charsmax(menu) - len, "^n\r0. \w%L", id, "HC_EXIT_PAGE")
		if (pev_valid(id) == 2) set_pdata_int(id, 205, 0, 5)
		show_menu(id, keys, menu, -1, "Menu Male")
		return PLUGIN_HANDLED;}
	return PLUGIN_HANDLED;}
	
public open_menu_female(id){
	if(is_user_alive(id) && !zp_get_user_zombie(id) && !zp_get_user_survivor(id)){
		new menu[512], len, keys = MENU_KEY_0
		len += formatex(menu[len], charsmax(menu) - len, "\w%L^n^n", id, "HC_MENU_CLASS_FEMALE_TITLE")
		len += formatex(menu[len], charsmax(menu) - len, "\r1. \w%s^n", HUMAN_YURI2)
		keys += MENU_KEY_1
		len += formatex(menu[len], charsmax(menu) - len, "\r2. \w%s^n", HUMAN_ALICE2)
		keys += MENU_KEY_2
		len += formatex(menu[len], charsmax(menu) - len, "\r3. \w%s^n", HUMAN_GUNSMITH)
		keys += MENU_KEY_3
		if(get_user_flags(id) & ADMIN_FLAG){
			len += formatex(menu[len], charsmax(menu) - len, "\r4. \w%s \d- \y[%L] \d- \r[VIP]\w^n", HUMAN_CHOIJIYOON2, id, "HC_BONUS_JUMP")
			keys += MENU_KEY_4
		} else {
			len += formatex(menu[len], charsmax(menu) - len, "\r4. \d%s - \y[%L] \d- \r[VIP]\w^n", HUMAN_CHOIJIYOON2, id, "HC_BONUS_JUMP")
			keys += MENU_KEY_4;}
		len += formatex(menu[len], charsmax(menu) - len, "^n\r9. \w%L", id, "HC_BACK_PAGE")
		keys += MENU_KEY_9
		len += formatex(menu[len], charsmax(menu) - len, "^n\r0. \w%L", id, "HC_EXIT_PAGE")
		if (pev_valid(id) == 2) set_pdata_int(id, 205, 0, 5)
		show_menu(id, keys, menu, -1, "Menu Female")
		return PLUGIN_HANDLED;}
	return PLUGIN_HANDLED;}

public menu_handler(id, key){
	if(!is_user_alive(id))
		return;
	switch (key) {
		case 0: open_menu_male(id)
		case 1: open_menu_female(id);}
	return;}
	
public menu_male(id, key){
	if(!is_user_alive(id))
		return;
	switch (key) {
		case 0: {
			g_class[id] = CLASS_GERRARD
			print_col_chat(id, "!g%L!y %L !t[%s]", id, "HC_PREFIX", id, "HC_CHOOSE_CLASS", HUMAN_GERRARD)
			zp_override_user_model(id, MODEL_MALE)
			set_pev(id, pev_body, SUBMODEL_FOUR);}
		case 1: {
			g_class[id] = CLASS_DAVIDBLACK
			print_col_chat(id, "!g%L!y %L !t[%s]", id, "HC_PREFIX", id, "HC_CHOOSE_CLASS", HUMAN_DAVIDBLACK)
			zp_override_user_model(id, MODEL_MALE)
			set_pev(id, pev_body, SUBMODEL_ONE);}
		case 2: {
			g_class[id] = CLASS_ARA
			print_col_chat(id, "!g%L!y %L !t[%s]", id, "HC_PREFIX", id, "HC_CHOOSE_CLASS", HUMAN_ARA)
			zp_override_user_model(id, MODEL_MALE)
			set_pev(id, pev_body, SUBMODEL_TWO);}
		case 3: {
			if(get_user_flags(id) & ADMIN_FLAG){
				g_class[id] = CLASS_SPADE
				zp_override_user_model(id, MODEL_MALE)
				set_pev(id, pev_body, SUBMODEL_THREE)
				print_col_chat(id, "!g%L!y %L !t[%s]", id, "HC_PREFIX", id, "HC_CHOOSE_CLASS", HUMAN_SPADE)
			} else {
				open_menu_male(id)
				print_col_chat(id, "!g%L!y %L", id, "HC_PREFIX", id, "HC_NOT_ACCESS");} }
				
		case 8: open_menu(id);}
	return;}
	
public menu_female(id, key){
	if(!is_user_alive(id))
		return;
	switch (key) {
		case 0: {
			g_class[id] = CLASS_YURI2
			print_col_chat(id, "!g%L!y %L !t[%s]", id, "HC_PREFIX", id, "HC_CHOOSE_CLASS", HUMAN_YURI2)
			zp_override_user_model(id, MODEL_FEMALE)
			set_pev(id, pev_body, SUBMODEL_FOUR);}
		case 1: {
			g_class[id] = CLASS_ALICE2
			print_col_chat(id, "!g%L!y %L !t[%s]", id, "HC_PREFIX", id, "HC_CHOOSE_CLASS", HUMAN_ALICE2)
			zp_override_user_model(id, MODEL_FEMALE)
			set_pev(id, pev_body, SUBMODEL_TWO);}
		case 2: {
			g_class[id] = CLASS_GUNSMITH
			print_col_chat(id, "!g%L!y %L !t[%s]", id, "HC_PREFIX", id, "HC_CHOOSE_CLASS", HUMAN_GUNSMITH)
			zp_override_user_model(id, MODEL_FEMALE)
			set_pev(id, pev_body, SUBMODEL_THREE);}
		case 3: {
			if(get_user_flags(id) & ADMIN_FLAG){
				g_class[id] = CLASS_CHOIJIYOON2
				zp_override_user_model(id, MODEL_FEMALE)
				set_pev(id, pev_body, SUBMODEL_ONE)
				print_col_chat(id, "!g%L!y %L !t[%s]", id, "HC_PREFIX", id, "HC_CHOOSE_CLASS", HUMAN_CHOIJIYOON2)
				if(g_class[id] == CLASS_CHOIJIYOON2)
					set_user_gravity(id, 0.9)
				else
					set_user_gravity(id, 1.0)
			} else {
				open_menu_female(id)
				print_col_chat(id, "!g%L!y %L", id, "HC_PREFIX", id, "HC_NOT_ACCESS");} }
		case 8: open_menu(id);}
	return;}
	
public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
	if (victim != attacker && is_user_connected(attacker))
		if(g_class[attacker] == CLASS_SPADE)
			SetHamParamFloat(4, damage * 1.1)

stock print_col_chat(const id, const input[], any:...){    
    new count = 1, players[32];    
    static msg[191];    
    vformat(msg, 190, input, 3);    
    replace_all(msg, 190, "!g", "^4")
    replace_all(msg, 190, "!y", "^1")
    replace_all(msg, 190, "!t", "^3")
    if (id) players[0] = id; else get_players(players, count, "ch");{    
        for ( new i = 0; i < count; i++ )    {    
            if ( is_user_connected(players[i]) )    {    
                message_begin(MSG_ONE_UNRELIABLE, SayText, _, players[i]);    
                write_byte(players[i]);    
                write_string(msg);    
                message_end();} } } }
