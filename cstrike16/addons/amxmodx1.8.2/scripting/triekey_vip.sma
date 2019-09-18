#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <hamsandwich>
#include <fun>

new const g_szFileName [] = "vip_list.ini";
new g_szFile[128];
new Trie: g_tVipList;
new bool: g_bIsVip[33]; // = false
new g_type, g_enabled, g_recieved, bool:g_showrecieved, g_hudmsg1, g_hudmsg2;
new jumpnum[33] = 0;
new bool:dojump[33] = false;

new const fail_maps[][] =
{
	"35hp",
	"he_"
}

new stop_vip=0

public plugin_init()
{
	new map[128], message[128];
	get_mapname(map, charsmax(map));
	for(new i = 0; i < sizeof fail_maps; i++)
	{
		if(containi(map, fail_maps[i]))
		{
			formatex(message, charsmax(message), "Harta %s nu suporta acest plugin!", map);
			set_fail_state(message);
			//break;
			stop_vip=1
		}
	}

	if(stop_vip!=1)
	{
		RegisterHam(Ham_Spawn, "player", "HAM_Spawn_Post", 1);
	
		register_event("Damage", "on_damage", "b", "2!0", "3=0", "4!0");
	
		g_type = register_cvar("amx_bulletdamage","1");
		g_recieved = register_cvar("amx_bulletdamage_recieved","1");
		register_cvar("amx_maxjumps","2");
	
		g_hudmsg1 = CreateHudSyncObj();
		g_hudmsg2 = CreateHudSyncObj();
	
		register_clcmd("say /premium","cmdVips");
	}
}

public plugin_precache()
{
	g_tVipList = TrieCreate();
}

public plugin_cfg()
{
	new szDir[128];
	get_configsdir(szDir, charsmax(szDir));
	
	formatex(g_szFile, charsmax(g_szFile), "%s/%s", szDir, g_szFileName);
	
	if(!file_exists(g_szFile)) 
	{
		new fp = fopen(g_szFile, "a+");
		if(fp)
		{
			fputs(fp, "; ===========================================================^n");
			fputs(fp, "; --------------------- VIP LIST ----------------------------^n");
			fputs(fp, "; ===========================================================^n");
			fputs(fp, "; Nota: Incepe randul cu ^";^" pentru a dezactiva un VIP^n" );
			//fputs( fp, "^b" );
		}
		
		fclose(fp);
	}
	
	ReadIniFile();
}

public plugin_end()
{
	TrieDestroy(g_tVipList);
}

ReadIniFile()
{
	new fp = fopen(g_szFile , "rt");
	if(!fp)
	{
		return 0;
	}
	
	new szData[256], i;
	
	while(!feof(fp))
	{
		fgets(fp, szData, charsmax(szData));
		trim(szData);
		
		if(!szData[0] || szData[0] == ';' || szData[0] == '#' || (szData[0] == '/' && szData[1] == '/'))
		{
			continue;
		}
		
		TrieSetCell(g_tVipList, szData, i);
		i ++;
	}
	
	return 0;
}

public client_putinserver(id)
{
	new szName[32]; get_user_name(id, szName, charsmax(szName))
	new szSteamID[32]; get_user_authid(id, szSteamID, charsmax(szSteamID))
	if(TrieKeyExists(g_tVipList, szName) || TrieKeyExists(g_tVipList, szSteamID))
	{
		g_bIsVip[id] = true;
	}

	if(g_bIsVip[id])
	{
		jumpnum[id] = 0;
		dojump[id] = false;
	}
}

public client_disconnect(id)
{
	if(g_bIsVip[id])
	{
		g_bIsVip[id] = false;
		jumpnum[id] = 0;
		dojump[id] = false;
	}
}

public HAM_Spawn_Post(id)
{
	if(is_user_alive(id) && g_bIsVip[id])
	{
		give_item(id, "weapon_deagle");
		cs_set_user_bpammo(id, CSW_DEAGLE, 35);
		give_item(id, "weapon_hegrenade");
		cs_set_user_bpammo(id, CSW_HEGRENADE, 2);
		cs_set_user_armor(id, 100, CS_ARMOR_VESTHELM);
		g_enabled = get_pcvar_num(g_type);
		//new CM[32]
		//get_mapname(CM,charsmax(CM))
		//if((containi(CM,"de_")))
		//{
		if(cs_get_user_team(id)==CS_TEAM_CT)
		{
				/*if(cs_get_user_defuse(id)==1)
					cs_set_user_defuse(id, 1, 255, 255, 0, "defuser", 0)
				else cs_set_user_defuse(id, 1, 255, 255, 0, "defuser", 0)*/
				cs_set_user_defuse(id, 1, 255, 255, 0, _, 0)
		}
		//}
		if(get_pcvar_num(g_recieved))
			g_showrecieved = true;
		show_menuX(id);
	}
}

public on_damage(id)
{
	if(g_enabled && g_bIsVip[id])
	{
		static attacker; attacker = get_user_attacker(id);
		static damage; damage = read_data(2);
		if(g_showrecieved)
		{
			set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1);
			ShowSyncHudMsg(id, g_hudmsg2, "%i^n", damage);
		}
		if(is_user_connected(attacker))
		{
			if(g_bIsVip[attacker])
			{
				set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1);
				ShowSyncHudMsg(attacker, g_hudmsg1, "%i^n", damage);
			}
		}
	}
}

public cmdVips(id) {
	new iPlayers[32],iNum,len,name[32],buffer[256],player,i,count = 0;
	get_players(iPlayers,iNum);
	for(i = 0;i < iNum; i++)
	{
		player = iPlayers[i];
		if(g_bIsVip[player])
		{
			count++;
			get_user_name(player,name,charsmax(name));
			
			len = len+= formatex(buffer[len],charsmax(buffer),"%s ,",name);
		}
	}
	if(count > 0)
	xCoLoR(id,"!vPremium online: %s",buffer);
	else
	client_print(id,print_chat,"Nu sunt Premium online.");
}

public show_menuX(id)
{
	new menu = menu_create("\y.::Premium::.\r \w:", "v_handler");
	menu_additem(menu, "\wM4A1", "1");
	menu_additem(menu, "\wAK47", "2");
	menu_additem(menu, "\wAWP", "3");
	menu_additem(menu, "\wFAMAS", "4");
	//menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu);
}

public v_handler(id, menu, item) // de modificat...
{
	if(!g_bIsVip[id])
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	if(!is_user_alive(id))
	{
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}
	
	/*
	if(item < 0)
	{
		return 0
	}
	
	new Key[3]
	new Access, CallBack
	
	menu_item_getinfo(menu, item, Access, Key, 2, _, _, CallBack)
	
	new isKey = str_to_num(Key)
	*/
	
	switch(item) // switch(isKey)
	{
		case 0:
		{
			give_item(id, "weapon_m4a1");
			cs_set_user_bpammo(id, CSW_M4A1, 90);
		}
		case 1:
		{
			give_item(id, "weapon_ak47");
			cs_set_user_bpammo(id, CSW_AK47, 90);
		}
		case 2:
		{
			give_item(id, "weapon_awp");
			cs_set_user_bpammo(id, CSW_AWP, 90);
		}
		case 3:
		{
			give_item(id, "weapon_famas");
			cs_set_user_bpammo(id, CSW_FAMAS, 90);
		}
	}
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public client_death(killer, victim, wpnindex, hitplace, TK) // de modficat
{
	if(wpnindex == CSW_C4 || killer == victim || !is_user_connected(killer) || !is_user_connected(victim) || !g_bIsVip[killer])
	{
		return PLUGIN_HANDLED;
	}
	
	if(hitplace == HIT_HEAD)
	{
		set_user_health(killer, min(105, get_user_health(killer) + 30));
		//cs_set_user_money(killer, cs_get_user_money(killer) + 250);
	}
	
	if(hitplace != HIT_HEAD) // else
	{
		set_user_health(killer, min(104, get_user_health(killer) + 30));
		//cs_set_user_money(killer, cs_get_user_money(killer) + 150);
	}
	
	//set_user_health(killer, get_user_health(killer) + 30)
	
	return PLUGIN_HANDLED;
}

public client_PreThink(id)
{
	if(!is_user_alive(id) || !g_bIsVip[id]) return PLUGIN_CONTINUE;
	new nbut = get_user_button(id);
	new obut = get_user_oldbutton(id);
	if((nbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(obut & IN_JUMP))
	{
		if(jumpnum[id] < get_cvar_num("amx_maxjumps"))
		{
			dojump[id] = true;
			jumpnum[id]++;
			return PLUGIN_CONTINUE;
		}
	}
	if((nbut & IN_JUMP) && (get_entity_flags(id) & FL_ONGROUND))
	{
		jumpnum[id] = 0;
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_CONTINUE;
}

public client_PostThink(id)
{
	if(!is_user_alive(id) || !g_bIsVip[id]) return PLUGIN_CONTINUE;
	if(dojump[id] == true)
	{
		new Float:velocity[3];
		entity_get_vector(id,EV_VEC_velocity,velocity);
		velocity[2] = random_float(265.0,285.0);
		entity_set_vector(id,EV_VEC_velocity,velocity);
		dojump[id] = false;
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_CONTINUE;
}

stock xCoLoR( const id, const input[ ], any:... )
{
	new count = 1, players[ 32 ];
	static msg[ 191 ];

	vformat( msg, 190, input, 3 );

	replace_all( msg, 190, "!v", "^4" );
	replace_all( msg, 190, "!n", "^1" );
	replace_all( msg, 190, "!e", "^3" );
	replace_all( msg, 190, "!e2", "^0" );

	if( id )
	{
		players[ 0 ] = id;
	}

	else get_players( players, count, "ch" );
	{
		for( new i = 0; i < count; i++ )
		{
			if( is_user_connected( players[ i ] ) )
			{
				message_begin( MSG_ONE_UNRELIABLE, get_user_msgid( "SayText" ), _, players[ i ] );
				write_byte( players[ i ] );
				write_string( msg );
				message_end( );
			}
		}
	}
}
