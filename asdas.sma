// 00:36

#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <fun>

#define PLUGIN "Furien Clasic"
#define VERSION "2.0"
#define AUTHOR "Aragon*/DaNNe."

#define DMG_HEGRENADE (1<<24)

#define FURIEN_GRAVITY 0.4
#define FURIEN_SPEED 800.0
#define TEAM_FURIEN 1
#define TEAM_ANTIFURIEN 2

#define TASKID_CANPLANT 10001
#define TASKID_C4COUNTDOWN 453

#if cellbits == 32
#define OFFSET_BZ 235
#else
#define OFFSET_BZ 268
#endif

//Shop
new SuperKnifeModel_V[] = "models/v_superknife.mdl"
new bool: HaveSuperKnife[33]

//Settings
new Float:Wallorigin[33][3]

//Parachute
#define PARACHUTE_CLASS "Parachute"
new ParaENT[33];

new Menu;
new cvar_gamedescription, furienspawnhp, antifurienspawnhp, removebuyzone, superknife_damage_multiplier, cvar_autojoin_class, cvar_autojoin_team, cvar_aim_info,
MSGID_SayText, MSGID_StatusIcon, MSGID_TextMsg, MSGID_SendAudio, MSGID_ShowMenu, MSGID_VGUIMenu, MSGID_Health,
bool:CanPlant, C4_CountDownDelay;

public plugin_cfg() {
	server_cmd("mp_playerid 2")
	server_cmd("sv_maxspeed 9000")
	server_cmd("sv_maxvelocity 9000")
	server_cmd("sv_restart 5")
}

//===========================================================================================//
//===============================[Weapons Settings]=========================================//
//=========================================================================================//
new bool:HavePrimaryWeapon[33], bool:HaveSecondaryWeapon[33], PrimaryWeapon[33], SecondaryWeapon[33];

//---|| Primary
#define M4A1_KEY 100
#define AK47_KEY 101
#define M3_KEY 102
#define AUG_KEY 103
#define FAMAS_KEY 104
#define MP5_KEY 105
#define XM1014_KEY 106

//---|| Secondary
#define USP_KEY 107
#define DEAGLE_KEY 108
#define ELITE_KEY 109
#define FIVESEVEN_KEY 110

new bool:g_speed[33], bool:g_last[33],g_money, g_lasthp;

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	cvar_gamedescription = register_cvar("furien_gamename", "Furien CS1")
	antifurienspawnhp = register_cvar("antifurien_spawnhp", "100")
	furienspawnhp = register_cvar("furien_spawnhp", "100")
	superknife_damage_multiplier = register_cvar("superknife_damage_multiplier", "5.0")
	cvar_autojoin_team = register_cvar("furien_team", "5")
	cvar_autojoin_class = register_cvar("furien_class", "5")
	cvar_aim_info = register_cvar("furien_enable_aiminfo", "1")
	g_money = register_cvar("last_money", "1500");
	g_lasthp = register_cvar("last_hp", "70");

	MSGID_SayText = get_user_msgid("SayText")
	MSGID_StatusIcon = get_user_msgid("StatusIcon")
	MSGID_TextMsg = get_user_msgid("TextMsg")
	MSGID_SendAudio = get_user_msgid("SendAudio")
	MSGID_ShowMenu = get_user_msgid("ShowMenu")
	MSGID_VGUIMenu = get_user_msgid("VGUIMenu")

	register_clcmd("say shop", "CmdShopMenu")
	register_clcmd("say /shop", "CmdShopMenu")
	register_clcmd("say_team shop", "CmdShopMenu")
	register_clcmd("say_team /shop", "CmdShopMenu")
	//register_clcmd("say weapons", "CmdWeaponsMenu")
	//register_clcmd("say /weapons", "CmdWeaponsMenu")
	register_clcmd("jointeam", "CMD_BlockJoinTeam")
	register_clcmd("jointeam 1", "CMD_BlockJoinTeam")
	register_clcmd("jointeam 2", "CMD_BlockJoinTeam")
	register_clcmd("jointeam 3", "CMD_BlockJoinTeam")
	register_clcmd("chooseteam", "CMD_BlockChooseTeam")
	register_clcmd("say /rs", "CmdResetScore")
	register_clcmd("say_team /rs", "CmdResetScore")
	register_clcmd("say /resetscore", "CmdResetScore")
	register_clcmd("say_team /resetscore", "CmdResetScore")
	
	RegisterHam(Ham_Spawn, "player", "Ham_Spawn_Post", 1)
	RegisterHam(Ham_Touch, "weaponbox", "HAM_Touch_Weapon")
	RegisterHam(Ham_Touch, "armoury_entity", "HAM_Touch_Weapon")
	RegisterHam(Ham_Touch, "weapon_shield", "HAM_Touch_Weapon")
	RegisterHam(Ham_TakeDamage, "player", "SuperKnife_TakeDamage")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_c4", "C4_PrimaryAttack");
	
	register_forward(FM_PlayerPreThink, "Player_PreThink");
	register_forward(FM_AddToFullPack, "FWD_AddToFullPack", 1);
	register_forward(FM_GetGameDescription, "FWD_GameDescription")
	
	register_event("CurWeapon", "EVENT_CurWeapon", "be", "1=1")
	register_event("DeathMsg", "EVENT_Death", "a");
	register_event("SendAudio", "EVENT_SwitchTeam", "a", "1=0", "2=%!MRAD_ctwin");
	register_event("HLTV", "EVENT_NewRound", "a", "1=0", "2=0");
	register_event("TextMsg", "EVENT_FireINTheHole", "b", "2&#Game_radio", "4&#Fire_in_the_hole")
	register_event("TextMsg", "EVENT_FireINTheHole", "b", "3&#Game_radio", "5&#Fire_in_the_hole")
	
	register_message(MSGID_StatusIcon, "MSG_StatusIcon");
	register_message(MSGID_TextMsg, "MSG_TextMessage");
	register_message(MSGID_ShowMenu, "MSG_ShowMenu");
	register_message(MSGID_VGUIMenu, "MSG_VGUIMenu");
	register_message(MSGID_SendAudio, "MSG_SendAudio");
	register_message(MSGID_Health, "MSG_Health")
}

public plugin_precache() {
	removebuyzone = register_cvar("furien_removebuyzone", "1")
	if(get_pcvar_num(removebuyzone)) {
		remove_entity_name("info_map_parameters");
		remove_entity_name("func_buyzone");
		
		new Entity = create_entity("info_map_parameters");
		
		DispatchKeyValue(Entity, "buying", "3");
		DispatchSpawn(Entity);
	}

	precache_model(SuperKnifeModel_V)
}

public client_putinserver(id) {
	client_cmd(id, "cl_forwardspeed 999.0")
	client_cmd(id, "cl_sidespeed 999.0")
	client_cmd(id, "cl_backspeed 999.0")
	client_cmd(id, "cl_upspeed 999.0")

	PrimaryWeapon[id] = 0
	SecondaryWeapon[id] = 0
}

public Ham_Spawn_Post(id) {
	if(is_user_alive(id)) {
		set_user_rendering(id)

		g_speed[id] = false;
		g_last[id] = false;

		strip_user_weapons(id)

		HavePrimaryWeapon[id] = false
		HaveSecondaryWeapon[id] = false

		switch(get_user_team(id)) {
			case TEAM_FURIEN: {
				fm_give_item(id, "weapon_hegrenade")
				fm_give_item(id, "weapon_knife")
				set_user_footsteps(id, 1)
				fm_set_user_health(id, get_pcvar_num(furienspawnhp))
			}
			case TEAM_ANTIFURIEN: {
				fm_give_item(id, "weapon_hegrenade")
				fm_give_item(id, "weapon_knife")
				set_user_footsteps(id, 0)
				fm_set_user_health(id, get_pcvar_num(antifurienspawnhp))
				HaveSuperKnife[id] = false;
				Equipment(id)
			}
		}
	}
}

public HAM_Touch_Weapon(ent, id) {
	if(is_user_alive(id) && get_user_team(id) == TEAM_FURIEN && !(get_pdata_cbase(ent, 39, 4) > 0))	return HAM_SUPERCEDE
	return HAM_IGNORED
}

public SuperKnife_TakeDamage(Victim, Inflictor, Attacker, Float:Damage, DamageType) {
	if(is_user_alive(Attacker) && is_user_connected(Victim))	if(get_user_weapon(Attacker) == CSW_KNIFE)	if(HaveSuperKnife[Attacker])	SetHamParamFloat(4, Damage * get_pcvar_float(superknife_damage_multiplier))
	return HAM_IGNORED
}

///////////////////////////////////////////////////////////////////////////////////////////////

public CmdResetScore(id) {
	if(get_user_frags(id) == 0 && get_user_deaths(id) == 0)	ColorChat(id, "!g[FURIEN] Scorul tau este deja!t 0-0!g !")
	else {
		cs_set_user_deaths(id, 0);
		set_user_frags(id, 0);
		
		ColorChat(id, "!g[FURIEN] Ti-ai resetat scorul cu succes !")
	}
}

public CmdShopMenu(id) {
	if(!is_user_alive(id))	return PLUGIN_HANDLED
	switch(get_user_team(id)) {
		case TEAM_FURIEN: CmdFurienShop(id)
		case TEAM_ANTIFURIEN: CmdAntiFurienShop(id)
	}
	return PLUGIN_HANDLED
}

public CmdFurienShop(id) {
	if(is_user_alive(id) && get_user_team(id) == TEAM_FURIEN) {
		Menu = menu_create("\r[\wMagazin\r] \wcu obiecte FURIEN:^n\w[\r*\w]\w FURIEN.FASTCS.RO", "CmdFurienHandler")
		
		new SuperKnife[256];
		formatex(SuperKnife, sizeof(SuperKnife)-1, "Super cutit: \w[\r10000$\w]")
		menu_additem(Menu, SuperKnife, "1", 0)
		
		new Health[256];
		formatex(Health, sizeof(Health)-1, "50 viata: \w[\r3000$\w]")
		menu_additem(Menu, Health, "2", 0)
		
		new Armor[256];
		formatex(Armor, sizeof(Armor)-1, "50 aparare: \w[\r500$\w]")
		menu_additem(Menu, Armor, "3", 0)
		
		new Grenade[256];
		formatex(Grenade, sizeof(Grenade)-1, "Grenada exploziva: \w[\r4000$\w]")
		menu_additem(Menu, Grenade, "4", 0)
		
		menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL);
		menu_display(id, Menu, 0);
	}
}

public CmdAntiFurienShop(id) {
	if(is_user_alive(id) && get_user_team(id) == TEAM_ANTIFURIEN) {
		Menu = menu_create("\r[\wMagazin\r] \wcu obiecte ANTI-FURIEN:^n\w[\r*\w]\w FURIEN.FASTCS.RO", "CmdAntiFurienHandler")
		
		new Defuse[256];
		formatex(Defuse, sizeof(Defuse)-1, "Pachet dezamorsare: \w[\r500$\w]")
		menu_additem(Menu, Defuse, "1", 0)
		
		new Health[256];
		formatex(Health, sizeof(Health)-1, "50 viata: \w[\r3000$\w]")
		menu_additem(Menu, Health, "2", 0)
		
		new Armor[256];
		formatex(Armor, sizeof(Armor)-1, "50 aparare: \w[\r500$\w]")
		menu_additem(Menu, Armor, "3", 0)
		
		new Grenade[256];
		formatex(Grenade, sizeof(Grenade)-1, "Grenada exploziva: \w[\r4000$\w]")
		menu_additem(Menu, Grenade, "4", 0)
		
		menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL);
		menu_display(id, Menu, 0);
	}
}

public CmdFurienHandler(id, menu, item) {
	if(item == MENU_EXIT || !is_user_alive(id) || get_user_team(id) != 1) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	new Data[6], Name[64];
	new Access, CallBack;
	menu_item_getinfo(menu, item, Access, Data,5, Name, 63, CallBack);
	new Key = str_to_num(Data);
	switch(Key) {
		case 1: {
			if(HaveSuperKnife[id])
				client_print(id, print_center, "You already have SuperKnife!")
			else {
				new Money = cs_get_user_money(id) - 10000
				if(Money < 0)
					client_print(id, print_center, "You have insufficient founds!")
				else {
					HaveSuperKnife[id] = true;
					EVENT_CurWeapon(id)
					cs_set_user_money(id, Money)
				}
			}
		}
		case 2: {
			if(get_user_health(id) >= 250)
				client_print(id, print_center, "You already have 250 HP!")
			else {
				new Money = cs_get_user_money(id) - 3000
				if(Money < 0)
					client_print(id, print_center, "You have insufficient founds!")
				else {
					if(get_user_health(id) + 50 > 250)
						fm_set_user_health(id, 250)
					else
						fm_set_user_health(id, get_user_health(id) + 50)
					cs_set_user_money(id, Money)
				}
			}
		}
		case 3: {
			if(get_user_armor(id) >= 250)
				client_print(id, print_center, "You already have 250 AP!")
			else {
				new Money = cs_get_user_money(id) - 500
				if(Money < 0)
					client_print(id, print_center, "You have insufficient founds!")
				else {
					if(get_user_armor(id) + 50 > 250)
						fm_set_user_armor(id, 250)
					else
						fm_set_user_armor(id, get_user_armor(id) + 50)
					cs_set_user_money(id, Money)
				}
			}
		}
		case 4: {
			if(user_has_weapon(id, CSW_HEGRENADE))
				client_print(id, print_center, "You already have HE GRENADE!")
			else {
				new Money = cs_get_user_money(id) - 4000
				if(Money < 0)
					client_print(id, print_center, "You have insufficient founds!")
				else {
					fm_give_item(id, "weapon_hegrenade")
					cs_set_user_money(id, Money)
				}
			}
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public CmdAntiFurienHandler(id, menu, item) {
	if(item == MENU_EXIT || !is_user_alive(id) || get_user_team(id) != 2) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	new Data[6], Name[64];
	new Access, CallBack;
	menu_item_getinfo(menu, item, Access, Data,5, Name, 63, CallBack);
	new Key = str_to_num(Data);
	switch(Key) {
		case 1: {
			if(cs_get_user_defuse(id))
				client_print(id, print_center, "You already have Defuse KIT!")
			else {
				new Money = cs_get_user_money(id) - 500
				if(Money < 0)
					client_print(id, print_center, "You have insufficient founds!")
				else {
					cs_set_user_defuse(id, 1)
					cs_set_user_money(id, Money)
				}
			}
		}
		case 2: {
			if(get_user_health(id) >= 250)
				client_print(id, print_center, "You already have 250 HP!")
			else {
				new Money = cs_get_user_money(id) - 3000
				if(Money < 0)
					client_print(id, print_center, "You have insufficient founds!")
				else {
					if(get_user_health(id) + 50 > 250)
						fm_set_user_health(id, 250)
					else
						fm_set_user_health(id, get_user_health(id) + 50)
					cs_set_user_money(id, Money)
				}
			}
		}
		case 3: {
			if(get_user_armor(id) >= 250)
				client_print(id, print_center, "You already have 250 AP!")
			else {
				new Money = cs_get_user_money(id) - 500
				if(Money < 0)
					client_print(id, print_center, "You have insufficient founds!")
				else {
					if(get_user_armor(id) + 50 > 250)
						fm_set_user_armor(id, 250)
					else
						fm_set_user_armor(id, get_user_armor(id) + 50)
					cs_set_user_money(id, Money)
				}
			}
		}
		case 4: {
			if(user_has_weapon(id, CSW_HEGRENADE))
				client_print(id, print_center, "You already have HE GRENADE!")
			else {
				new Money = cs_get_user_money(id) - 4000
				if(Money < 0)
					client_print(id, print_center, "You have insufficient founds!")
				else {
					fm_give_item(id, "weapon_hegrenade")
					cs_set_user_money(id, Money)
				}
			}
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

//=========================================================================//
//=======================[Weapons Settings]===============================//
//=======================================================================//

public Equipment(id) {
	if(is_user_alive(id) && get_user_team(id) == 2) {
		Menu = menu_create("\rMeniu arme", "EquipmentCmd");
		menu_additem(Menu, "\rArme primare", "1", 0);
		if(PrimaryWeapon[id] && SecondaryWeapon[id])
			menu_additem(Menu, "\wArme anterioare", "2", 0);
		else
			menu_additem(Menu, "\dArme anterioare", "2", 0);
		menu_setprop(Menu, MPROP_EXIT, MEXIT_NEVER)
		menu_display(id, Menu, 0);
	}
}

public EquipmentCmd(id, menu, item) {
	if(item == MENU_EXIT || !is_user_alive(id) || get_user_team(id) != 2) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	new Data[6], Name[64];
	new Access, CallBack;
	menu_item_getinfo(menu, item, Access, Data,5, Name, 63, CallBack);
	new Key = str_to_num(Data);
	switch(Key) {
		case 1: {
			if(!HavePrimaryWeapon[id])
				Primary(id)
			else if(!HaveSecondaryWeapon[id])
				Secondary(id)
		}
		case 2: {
			if(PrimaryWeapon[id] && SecondaryWeapon[id])
				GiveLastWeapons(id)
			else Equipment(id)
		}
		default: return PLUGIN_HANDLED;
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public Primary(id) {
	if(is_user_alive(id) && get_user_team(id) == TEAM_ANTIFURIEN) {
		Menu = menu_create("\rMeniu arme^n\rprimare:", "CmdWeaponsHandler")
		
		menu_additem(Menu, "M4A1;", "1", 0)
		menu_additem(Menu, "AK47;", "2", 0)
		menu_additem(Menu, "M3;", "3", 0)
		menu_additem(Menu, "Aug;", "4", 0)
		menu_additem(Menu, "Famas;", "5", 0)
		menu_additem(Menu, "MP5 Navy;", "6", 0)
		menu_additem(Menu, "XM1014;", "7", 0)
		
		menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL);
		menu_display(id, Menu, 0);
	}
}

public CmdWeaponsHandler(id, menu, item) {
	if(item == MENU_EXIT || !is_user_alive(id) || get_user_team(id) != 2) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	new Data[6], Name[64];
	new Access, CallBack;
	menu_item_getinfo(menu, item, Access, Data,5, Name, 63, CallBack);
	new Key = str_to_num(Data);
	switch(Key) {
		case 1: {
			fm_give_item(id, "weapon_m4a1")
			cs_set_user_bpammo(id, CSW_M4A1, 254)
			PrimaryWeapon[id] = M4A1_KEY
			HavePrimaryWeapon[id] = true;
			Secondary(id)
		}
		case 2: {
			fm_give_item(id, "weapon_ak47")
			cs_set_user_bpammo(id, CSW_AK47, 254)
			PrimaryWeapon[id] = AK47_KEY
			HavePrimaryWeapon[id] = true;
			Secondary(id)
		}
		case 3: {
			fm_give_item(id, "weapon_m3")
			cs_set_user_bpammo(id, CSW_M3, 254)
			PrimaryWeapon[id] = M3_KEY
			HavePrimaryWeapon[id] = true;
			Secondary(id)
		}
		case 4: {
			fm_give_item(id, "weapon_aug")
			cs_set_user_bpammo(id, CSW_AUG, 254)
			PrimaryWeapon[id] = AUG_KEY
			HavePrimaryWeapon[id] = true;
			Secondary(id)
		}
		case 5: {
			fm_give_item(id, "weapon_famas")
			cs_set_user_bpammo(id, CSW_FAMAS, 254)
			PrimaryWeapon[id] = FAMAS_KEY
			HavePrimaryWeapon[id] = true;
			Secondary(id)
		}
		case 6: {
			fm_give_item(id, "weapon_mp5navy")
			cs_set_user_bpammo(id, CSW_MP5NAVY, 254)
			PrimaryWeapon[id] = MP5_KEY
			HavePrimaryWeapon[id] = true;
			Secondary(id)
		}
		case 7: {
			fm_give_item(id, "weapon_xm1014")
			cs_set_user_bpammo(id, CSW_XM1014, 254)
			PrimaryWeapon[id] = XM1014_KEY
			HavePrimaryWeapon[id] = true;
			Secondary(id)
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public Secondary(id) {
	if(is_user_alive(id) && get_user_team(id) == TEAM_ANTIFURIEN) {
		Menu = menu_create("\yAnti-Furien Weapons^n\rSecondary:", "CmdSecondaryHandler")
		
		menu_additem(Menu, "USP", "1", 0)
		menu_additem(Menu, "Deagle", "2", 0)
		menu_additem(Menu, "Elite", "3", 0)
		menu_additem(Menu, "Five Seven", "4", 0)
		
		menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL);
		menu_display(id, Menu, 0);
	}
}

public CmdSecondaryHandler(id, menu, item) {
	if(item == MENU_EXIT || !is_user_alive(id) || get_user_team(id) != 2) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	new Data[6], Name[64];
	new Access, CallBack;
	menu_item_getinfo(menu, item, Access, Data,5, Name, 63, CallBack);
	new Key = str_to_num(Data);
	switch(Key) {
		case 1: {
			fm_give_item(id, "weapon_usp")
			cs_set_user_bpammo(id, CSW_USP, 256)
			SecondaryWeapon[id] = USP_KEY
			HaveSecondaryWeapon[id] = true;
		}
		case 2: {
			fm_give_item(id, "weapon_deagle")
			cs_set_user_bpammo(id, CSW_DEAGLE, 256)
			SecondaryWeapon[id] = DEAGLE_KEY
			HaveSecondaryWeapon[id] = true;
		}
		case 3: {
			fm_give_item(id, "weapon_elite")
			cs_set_user_bpammo(id, CSW_ELITE, 256)
			SecondaryWeapon[id] = ELITE_KEY
			HaveSecondaryWeapon[id] = true;
		}
		case 4: {
			fm_give_item(id, "weapon_fiveseven")
			cs_set_user_bpammo(id, CSW_FIVESEVEN, 256)
			SecondaryWeapon[id] = FIVESEVEN_KEY
			HaveSecondaryWeapon[id] = true;
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public GiveLastWeapons(id) {
	if(!HavePrimaryWeapon[id]) {
		switch(PrimaryWeapon[id]) {
			case M4A1_KEY: {
				fm_give_item(id, "weapon_m4a1")
				cs_set_user_bpammo(id, CSW_M4A1, 256)
				HavePrimaryWeapon[id] = true;
			}
			case AK47_KEY: {
				fm_give_item(id, "weapon_ak47")
				cs_set_user_bpammo(id, CSW_AK47, 256)
				HavePrimaryWeapon[id] = true;
			}
			case M3_KEY: {
				fm_give_item(id, "weapon_m3")
				cs_set_user_bpammo(id, CSW_M3, 256)
				HavePrimaryWeapon[id] = true;
			}
			case AUG_KEY: {
				fm_give_item(id, "weapon_aug")
				cs_set_user_bpammo(id, CSW_AUG, 256)
				HavePrimaryWeapon[id] = true;
			}
			case FAMAS_KEY: {
				fm_give_item(id, "weapon_famas")
				cs_set_user_bpammo(id, CSW_FAMAS, 256)
				HavePrimaryWeapon[id] = true;
			}
			case MP5_KEY: {
				fm_give_item(id, "weapon_mp5navy")
				cs_set_user_bpammo(id, CSW_MP5NAVY, 256)
				HavePrimaryWeapon[id] = true;
			}
			case XM1014_KEY: {
				fm_give_item(id, "weapon_xm1014")
				cs_set_user_bpammo(id, CSW_XM1014, 256)
				HavePrimaryWeapon[id] = true;
			}
		}
	}
	if(!HaveSecondaryWeapon[id]) {
		switch(SecondaryWeapon[id]) {
			case USP_KEY: {
				fm_give_item(id, "weapon_usp")
				cs_set_user_bpammo(id, CSW_USP, 256)
				HaveSecondaryWeapon[id] = true;
			}
			case DEAGLE_KEY: {
				fm_give_item(id, "weapon_deagle")
				cs_set_user_bpammo(id, CSW_DEAGLE, 256)
				HaveSecondaryWeapon[id] = true;
			}
			case ELITE_KEY: {
				fm_give_item(id, "weapon_elite")
				cs_set_user_bpammo(id, CSW_ELITE, 256)
				HaveSecondaryWeapon[id] = true;
			}
			case FIVESEVEN_KEY: {
				fm_give_item(id, "weapon_fiveseven")
				cs_set_user_bpammo(id, CSW_FIVESEVEN, 256)
				HaveSecondaryWeapon[id] = true;
			}
		}
	}
}
public CMD_BlockJoinTeam(id) {
	console_print(id, "*** Nu ai voie sa foloseti JoinTeam ! ***")
	return 1;
}

public CMD_BlockChooseTeam(id) {
	console_print(id, "*** Nu ai voie sa foloseti ChooseTeam ! ***")
	return 1;
}

/////////////////////////////////////////////////////////////////////////

public EVENT_CurWeapon(id) {
	if(!is_user_alive(id))	return

	if(get_user_weapon(id) == CSW_KNIFE)	if(HaveSuperKnife[id])	set_pev(id, pev_viewmodel2, SuperKnifeModel_V)

	new PlayerHealth;
	PlayerHealth = get_user_health(id)
	if(PlayerHealth == 256)	fm_set_user_health(id, 255)
}

public EVENT_Death() {
	static Attacker, Victim;
	Attacker = read_data(1)
	Victim = read_data(2)

	HaveSuperKnife[Victim] = false;


	new Counter[32], NumCT, LastCT;
	new Tero[32], NumT, LastT;
	new Name[32];
	new Money = get_pcvar_num(g_money);
	new HP = get_pcvar_num(g_lasthp);
	get_players(Counter, NumCT, "aceh", "CT");
	get_players(Tero, NumT, "aceh", "TERRORIST");

	if(NumCT == 1) {
		LastCT = Counter[0];

		get_user_name(LastCT, Name, charsmax(Name));
		ColorChat(0, "!g[ANTI-FURIEN]!t %s!y este ultimul!t ANTI-FURIEN!y ! Ramai in viata !", Name);
		ColorChat(0, "!g[ANTI-FURIEN]!y A primit!t %d $ si %d HP!y !", Money, HP);

		cs_set_user_money(LastCT, cs_get_user_money(LastCT) + Money);
		set_user_health(LastCT, get_user_health(LastCT) + HP);
		set_user_rendering(LastCT, kRenderFxGlowShell, 0, 127, 255, kRenderNormal, 0);

		g_last[LastCT] = g_speed[LastCT]=true;
	}

	if(NumT == 1) {
		LastT = Tero[0];

		get_user_name(LastT, Name, charsmax(Name));
		ColorChat(0, "!g[FURIEN]!t %s!y este ultimul!t FURIEN!y ! Ramai in viata !", Name);
		ColorChat(0, "!g[FURIEN]!y A primit!t %d $ si %d HP!y !", Money, HP);

		cs_set_user_money(LastT, cs_get_user_money(LastT) + Money);
		set_user_health(LastT, get_user_health(LastT) + HP);

		g_last[LastT] = true;
	}


	if(Victim == Attacker)	return 1;
	if(is_user_connected(Attacker)) {
		if(get_user_team(Victim) == 2)	cs_set_user_money(Attacker, cs_get_user_money(Attacker) + 1200)
		else if(get_user_team(Victim) == 1)	cs_set_user_money(Attacker, cs_get_user_money(Attacker) + 3000)
	}
	return 1;
}

public MSG_StatusIcon(msg_id, msg_dest, id) {
	static Attrib
	Attrib = get_msg_arg_int(2)
	
	if(Attrib == (1<<1))	set_msg_arg_int(2, ARG_BYTE, 0)
	
	new Icon[8];
	get_msg_arg_string(2, Icon, 7);
	if(get_pcvar_num(removebuyzone)) {
		static const BuyZone[] = "buyzone";
		
		if(equal(Icon, BuyZone)) {
			set_pdata_int(id, OFFSET_BZ, get_pdata_int(id, OFFSET_BZ, 5) & ~(1 << 0), 5);
			
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

public MSG_TextMessage() {
	static TextMsg[22];
	get_msg_arg_string(2, TextMsg, charsmax(TextMsg))
	if(equal(TextMsg, "#Terrorists_Win")) {
		client_print(0, print_center, "The Furiens have won this round!")
		return PLUGIN_HANDLED;
	}
	else if(equal(TextMsg, "#CTs_Win")) {
		client_print(0, print_center, "The Anti-Furiens have won this round!")
		return PLUGIN_HANDLED;
	}
	else if(equal(TextMsg, "#Bomb_Defused")) {
		client_print(0, print_center, "The Anti-Furiens have won this round!")
		return PLUGIN_HANDLED;
	}
	else if(equal(TextMsg, "#Target_Bombed")) {
		client_print(0, print_center, "The Furiens have won this round!")
		return PLUGIN_HANDLED;
	}
	else if(equal(TextMsg, "#Target_Saved")) {
		client_print(0, print_center, "The Anti-Furiens have won this round!")
		return PLUGIN_HANDLED;
	}
	else if(equal(TextMsg, "#Fire_in_the_hole"))	return PLUGIN_HANDLED
	else if(equal(TextMsg, "#C4_Plant_At_Bomb_Spot"))	if(!CanPlant)	return PLUGIN_HANDLED

	return PLUGIN_CONTINUE;
}
public EVENT_NewRound() {
	remove_task(TASKID_C4COUNTDOWN)
	remove_task(TASKID_CANPLANT)
	C4_CountDownDelay=0
	CanPlant = false;
	new Float:FloatTime = get_cvar_num("mp_freezetime") + (get_cvar_num("mp_roundtime") * 60) - 60.0
	set_task(FloatTime, "TASK_CanPlant", TASKID_CANPLANT)
}
public TASK_CanPlant() {
	CanPlant = true;
	set_hudmessage(random(255), random(255), random(255), -1.0, -1.0, 1, 3.1, 3.0)
	show_hudmessage(0, "Furienii pot planta bomba!")
}
public C4_PrimaryAttack() {
	if(!CanPlant)	return HAM_SUPERCEDE
	return HAM_IGNORED
}
public bomb_planted() {
	//if(!CanPlant)	return
	C4_CountDownDelay = get_cvar_num("mp_c4timer") - 1
	TASK_C4_CountDown();
	set_hudmessage(random(255), random(255), random(255), -1.0, -1.0, 1, 3.1, 3.0)
	show_hudmessage(0, "Furienii au plantat bomba!")
}
public TASK_C4_CountDown() {
	//if(!CanPlant)	return
	new Red, Green, Blue
	if(C4_CountDownDelay > 10)	Red = 0, Green = 255, Blue = 0;
	else if(C4_CountDownDelay > 5)	Red = 255, Green = 200, Blue = 0;
	else if(C4_CountDownDelay <= 5)	Red = 255, Green = 0, Blue = 0;
	
	if(C4_CountDownDelay) {
		new Message[256];
		formatex(Message,sizeof(Message)-1,"----------^n| C4: %d |^n----------", C4_CountDownDelay);
		
		set_hudmessage(Red, Green, Blue, -1.0, 0.78, 0, 6.0, 1.0)
		show_hudmessage(0, "%s", Message)
		set_task(1.0, "TASK_C4_CountDown", TASKID_C4COUNTDOWN);
		C4_CountDownDelay--;
	}
	else if(!C4_CountDownDelay)	C4_CountDownDelay = 0;
}
public MSG_SendAudio() {
	static Sound[17]
	get_msg_arg_string(2, Sound, sizeof Sound - 1)
	
	if(equal(Sound, "terwin") || equal(Sound, "ctwin") || equal(Sound, "rounddraw") || equal(Sound, "bombpl") || equal(Sound, "bombdef"))	return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public EVENT_FireINTheHole()	return PLUGIN_HANDLED

public MSG_Health(msgid, dest, id) {
	static Health;
	Health = get_msg_arg_int(1)
	if(Health > 255)	set_msg_arg_int(1, ARG_BYTE, 255);
	else if(Health == 256)	set_msg_arg_int(1, ARG_BYTE, get_user_health(id) + 10)
}

public MSG_ShowMenu(msgid, dest, id) {
	if(!Should_AutoJoin(id))	return PLUGIN_CONTINUE
	
	static team_select[] = "#Team_Select"
	static menu_text_code[sizeof team_select]
	get_msg_arg_string(4, menu_text_code, sizeof menu_text_code - 1)
	if(!equal(menu_text_code, team_select))	return PLUGIN_CONTINUE
	
	JoinTeam_Task(id, msgid)
	
	return PLUGIN_HANDLED
}
public MSG_VGUIMenu(msgid, dest, id) {
	if(get_msg_arg_int(1) != 2 || !Should_AutoJoin(id))	return PLUGIN_CONTINUE
	
	JoinTeam_Task(id, msgid)
	
	return PLUGIN_HANDLED
}
bool:Should_AutoJoin(id)	return(get_pcvar_num(cvar_autojoin_team) && !get_user_team(id) && !task_exists(id))
JoinTeam_Task(id, menu_msgid) {
	static param_menu_msgid[2]
	param_menu_msgid[0] = menu_msgid
	
	set_task(0.1, "Force_JoinTeam", id, param_menu_msgid, sizeof param_menu_msgid)
}
public Force_JoinTeam(menu_msgid[], id) {
	if(get_user_team(id))	return
	
	static team[2], class[2]
	get_pcvar_string(cvar_autojoin_team, team, sizeof team - 1)
	get_pcvar_string(cvar_autojoin_class, class, sizeof class - 1)

	Force_Team_Join(id, menu_msgid[0], team, class)
}
stock Force_Team_Join(id, menu_msgid, team[] = "5", class[] = "0") {
	static jointeam[] = "jointeam"
	if(class[0] == '0') {
		engclient_cmd(id, jointeam, team)
		return
	}
	
	static msg_block, joinclass[] = "joinclass"
	msg_block = get_msg_block(menu_msgid)
	set_msg_block(menu_msgid, BLOCK_SET)
	engclient_cmd(id, jointeam, team)
	engclient_cmd(id, joinclass, class)
	set_msg_block(menu_msgid, msg_block)
}

public EVENT_SwitchTeam() {
	new Players[32], PlayersNum, id;
	get_players(Players, PlayersNum)
	if(PlayersNum) {
		for(new i; i < PlayersNum; i++) {
			id = Players[i]
			BeginDelay(id)
		}
	}
}
public BeginDelay(id) {
	if(is_user_connected(id)) {
		switch(id) {
			case 1..7: set_task(0.1, "BeginTeamSwap", id)
				case 8..15: set_task(0.2, "BeginTeamSwap", id)
				case 16..23: set_task(0.3, "BeginTeamSwap", id)
				case 24..32: set_task(0.4, "BeginTeamSwap", id)
			}
	}
}
public BeginTeamSwap(id) {
	if(is_user_connected(id)) {
		switch(get_user_team(id)) {
			case TEAM_FURIEN: cs_set_user_team(id, CS_TEAM_CT)
			case TEAM_ANTIFURIEN: cs_set_user_team(id, CS_TEAM_T)
		}
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////

public Player_PreThink(id) {
	if(!is_user_alive(id))	return

	if(get_user_team(id) == TEAM_FURIEN) {
		if(pev(id, pev_gravity) > FURIEN_GRAVITY && pev(id, pev_gravity) > 0.1)	set_pev(id, pev_gravity, FURIEN_GRAVITY)
			
		if(pev(id, pev_maxspeed) < FURIEN_SPEED && pev(id, pev_maxspeed) > 1.0) {
			set_pev(id, pev_maxspeed, FURIEN_SPEED)
			set_user_footsteps(id, 1)
		}
	}

	if(get_pcvar_num(cvar_aim_info)) {
			new Target, Body;
			get_user_aiming(id, Target, Body);
			if(is_user_alive(Target)) {
				new TargetTeam, PlayerTeam, TargetName[32], Message[128], TargetHealth, TargetArmor, RED, GREEN, BLUE;
				TargetTeam = get_user_team(Target)
				PlayerTeam = get_user_team(id)
				get_user_name(Target, TargetName, 31)
				TargetHealth = get_user_health(Target)
				TargetArmor = get_user_armor(Target)

				if(PlayerTeam == TEAM_FURIEN && TargetTeam == TEAM_ANTIFURIEN) {
					formatex(Message, sizeof(Message)-1, "%s^nHP: %i | AP: %i", TargetName, TargetHealth, TargetArmor)
					RED = 20
					GREEN = 200
					BLUE = 50
				}
				else if(PlayerTeam == TEAM_FURIEN && TargetTeam == TEAM_FURIEN) {
					formatex(Message, sizeof(Message)-1, "%s^nHP: %i | AP: %i", TargetName, TargetHealth, TargetArmor)
					RED = 200
					GREEN = 20
					BLUE = 20
				}
				else if(PlayerTeam == TEAM_ANTIFURIEN && TargetTeam == TEAM_ANTIFURIEN) {
					formatex(Message, sizeof(Message)-1, "%s^nHP: %i | AP: %i", TargetName, TargetHealth, TargetArmor)
					RED = 200
					GREEN = 20
					BLUE = 20
				}
				else if(PlayerTeam == TEAM_ANTIFURIEN && TargetTeam == TEAM_FURIEN)	return

				set_hudmessage(RED, GREEN, BLUE, -1.0, -1.0, 0, 0.0, 0.1, 0.0, 0.0, -1);
				show_hudmessage(id, "%s", Message)
			}
	}

	if(get_user_team(id) == TEAM_ANTIFURIEN) {
		new Float:FallSpeed = -50.0;
		new Float:Frame;
		
		new Button = pev(id, pev_button);
		new OldButton = pev(id, pev_oldbuttons);
		new Flags = pev(id, pev_flags);
		
		if(ParaENT[id] > 0 &&(Flags & FL_ONGROUND)) {
			
			if(pev(ParaENT[id],pev_sequence) != 2) {
				set_pev(ParaENT[id], pev_sequence, 2);
				set_pev(ParaENT[id], pev_gaitsequence, 1);
				set_pev(ParaENT[id], pev_frame, 0.0);
				set_pev(ParaENT[id], pev_fuser1, 0.0);
				set_pev(ParaENT[id], pev_animtime, 0.0);
				return;
			}
			
			pev(ParaENT[id],pev_fuser1, Frame);
			Frame += 2.0;
			set_pev(ParaENT[id],pev_fuser1,Frame);
			set_pev(ParaENT[id],pev_frame,Frame);
			
			if(Frame > 254.0) {
				engfunc(EngFunc_RemoveEntity, ParaENT[id]);
				ParaENT[id] = 0;
			}
			else {
				engfunc(EngFunc_RemoveEntity, ParaENT[id]);
				ParaENT[id] = 0;
			}
			return;
		}
		
		if(Button & IN_USE) {
			new Float:Velocity[3];
			pev(id, pev_velocity, Velocity);
			
			if(Velocity[2] < 0.0) {
				if(ParaENT[id] <= 0) {
					ParaENT[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
					
					if(ParaENT[id] > 0) {
						set_pev(ParaENT[id],pev_classname, PARACHUTE_CLASS);
						set_pev(ParaENT[id], pev_aiment, id);
						set_pev(ParaENT[id], pev_owner, id);
						set_pev(ParaENT[id], pev_movetype, MOVETYPE_FLY);
						set_pev(ParaENT[id], pev_sequence, 0);
						set_pev(ParaENT[id], pev_gaitsequence, 1);
						set_pev(ParaENT[id], pev_frame, 0.0);
						set_pev(ParaENT[id], pev_fuser1, 0.0);
					}
				}
				if(ParaENT[id] > 0) {
					set_pev(id, pev_sequence, 3);
					set_pev(id, pev_gaitsequence, 1);
					set_pev(id, pev_frame, 1.0);
					set_pev(id, pev_framerate, 1.0);
					
					Velocity[2] = (Velocity[2] + 40.0 < FallSpeed) ? Velocity[2] + 40.0 : FallSpeed;
					set_pev(id, pev_velocity, Velocity);
					
					if(pev(ParaENT[id],pev_sequence) == 0) {
						pev(ParaENT[id],pev_fuser1, Frame);
						Frame += 1.0;
						set_pev(ParaENT[id],pev_fuser1,Frame);
						set_pev(ParaENT[id],pev_frame,Frame);
						
						if(Frame > 100.0) {
							set_pev(ParaENT[id], pev_animtime, 0.0);
							set_pev(ParaENT[id], pev_framerate, 0.4);
							set_pev(ParaENT[id], pev_sequence, 1);
							set_pev(ParaENT[id], pev_gaitsequence, 1);
							set_pev(ParaENT[id], pev_frame, 0.0);
							set_pev(ParaENT[id], pev_fuser1, 0.0);
						}
					}
				}
			}
			else if(ParaENT[id] > 0) {
				engfunc(EngFunc_RemoveEntity, ParaENT[id]);
				ParaENT[id] = 0;
			}
		}
		else if((OldButton & IN_USE) && ParaENT[id] > 0) {
			engfunc(EngFunc_RemoveEntity, ParaENT[id]);
			ParaENT[id] = 0;
		}
	}

	if(g_speed[id]&&g_last[id])	set_user_maxspeed(id, 300.0);
}

public FWD_AddToFullPack(es, e, ent, host, host_flags, player, p_set) {
	if(is_user_connected(ent) && is_user_connected(host) && is_user_alive(ent)) {
		if(is_user_alive(host) && get_user_team(ent) == 1 && get_user_team(host) == 1
		|| !is_user_alive(host) && get_user_team(ent) == 1 && pev(host, pev_iuser2) == ent
		|| get_user_team(ent) == 1 && pev(ent, pev_maxspeed) <= 1.0) {
			set_es(es, ES_RenderFx, kRenderFxNone);
			set_es(es, ES_RenderMode, kRenderTransTexture);
			set_es(es, ES_RenderAmt, 255);
		}
		else if(get_user_team(ent) == 1) {
			set_es(es, ES_RenderFx, kRenderFxNone);
			set_es(es, ES_RenderMode, kRenderTransTexture);
			static Float:Origin[3]
			pev(ent, pev_origin, Origin)
			
			if(get_user_weapon(ent) == CSW_KNIFE && fm_get_speed(ent) <= 5 || get_user_weapon(ent) == CSW_KNIFE && Origin[0] == Wallorigin[ent][0] && Origin[1] == Wallorigin[ent][1] && Origin[2] == Wallorigin[ent][2]||get_user_weapon(ent) == CSW_C4 && (get_user_button(ent) & IN_DUCK)&&g_last[ent])	set_es(es, ES_RenderAmt, 0);
			else	set_es(es, ES_RenderAmt, 255);
		}
	}
}

public FWD_GameDescription() {
	static GameName[32]
	get_pcvar_string(cvar_gamedescription, GameName, 31)
	
	forward_return(FMV_STRING, GameName)
	
	return FMRES_SUPERCEDE
}

stock ColorChat(const id, const input[], any:...) {
	new count = 1, players[32];
	static msg[191];
	vformat(msg, 190, input, 3);
	
	replace_all(msg, 190, "!g", "^4");
	replace_all(msg, 190, "!y", "^1");
	replace_all(msg, 190, "!t", "^3");
	
	if(id) players[0] = id;
	else get_players(players, count, "ch");

	for(new i = 0; i < count; i++) {
			if(is_user_connected(players[i])) {
				message_begin(MSG_ONE_UNRELIABLE, MSGID_SayText, _, players[i]);
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
}
