#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <nvault>
#if defined USING_SQL
#include <sqlx>
#endif

#define MESSAGE_PREFIX "CSGO.EVILS.RO"

#define VIP_FLAGS_TYPE "ce" // Dont Change This
#define VIP_PASSWORD "" // Dont Change This
#define VIP_FLAGS_ACESS "t" // VIP Flags (You Can Use More Then 1 BUT You Should Use Only One)

new SavePoints, Point_Kill, Point_Hs, Point_Suicide, Point_TeamKill, VIP_Cost
new g_vault
new PlayerPoints[33]

public plugin_init() {
#if defined USING_SQL
	register_plugin("Buy VIP With Points (SQL)", "0.0.4", "Autor")
#else
	register_plugin("Buy VIP With Points", "0.0.4", "Autor")
#endif

	register_event("DeathMsg", "eDeath", "a")
	
	SavePoints = register_cvar("SavePoints","1") // Turn 0 To Desativate Save Points Option
	Point_Kill = register_cvar("Points_kill", "1") // Points That You Get Per Normal Kill
	Point_Hs = register_cvar("Points_kill_hs","2") // Points That You Get Per HS Kill
	Point_Suicide = register_cvar("Points_suicide","1") // Points That You Lose Per Suicide
	Point_TeamKill = register_cvar("Points_teamkill","1") // Points That You Lose Per TeamKill
	VIP_Cost = register_cvar("Points_VIP_Cost","500") // How Many Points VIP Cost?
	
	register_concmd("amx_givepoints", "admin_give_points", ADMIN_LEVEL_A, "<user> <amount> : Give Points To Someone")
	register_concmd("amx_removepoints", "admin_remove_points", ADMIN_LEVEL_A, "<user> <amount> : Remove Points From Someone")
	
	register_clcmd("say /addvip", "cmdVIPAdd", ADMIN_RCON)
	register_clcmd("say_team /addvip", "cmdVIPAdd", ADMIN_RCON)
	
	register_clcmd("say /puncte", "show_points")
	register_clcmd("say_team /puncte", "show_points")
	register_clcmd("say /puncte_castigate", "show_points")
	register_clcmd("say_team /puncte_castigate", "show_points")
	
	register_clcmd("say /vreauvip", "buy_vip")
	register_clcmd("say_team /vreauvip", "buy_vip")
	
	g_vault = nvault_open("vip_points_system")
}

// Save Points When Pausing The Plugin
public plugin_pause()
{
	new iPlayers[32], iNum
	get_players(iPlayers, iNum)
	for(new i; i<iNum; i++)
		SaveData(iPlayers)
}

// Load Points After Unpause The Plugin
public plugin_unpause()
{
	new iPlayers[32], iNum
	get_players(iPlayers, iNum)
	for(new i; i<iNum; i++)
		LoadData(iPlayers)
}

// Load Points
public client_putinserver(id)
{
	PlayerPoints[id] = 0
	if(get_pcvar_num(SavePoints))
		LoadData(id)
}

// Give Points When Kill Someone
public eDeath() 
{
	new attacker = read_data(1)
	new victim = read_data(2)
	new headshot = read_data(3)
 
	if(cs_get_user_team(attacker) != cs_get_user_team(victim)) // Kill Enemie
	{
		if(!headshot)
			PlayerPoints[attacker] += get_pcvar_num(Point_Kill)
	
		else
			PlayerPoints[attacker] += get_pcvar_num(Point_Hs)
	}
	
	else
	{
		if(attacker == victim) // Suicide
		{
			if(PlayerPoints[attacker] > get_pcvar_num(Point_Suicide))
				PlayerPoints[attacker] -= get_pcvar_num(Point_Suicide)
				
			else
				PlayerPoints[attacker] = 0
		}
		
		else // Team Kill (Not necessary check if friendlyfire is enabled)
		{
			if(PlayerPoints[attacker] > get_pcvar_num(Point_TeamKill))
				PlayerPoints[attacker] -= get_pcvar_num(Point_TeamKill)
					
			else
				PlayerPoints[attacker] = 0
		}
	}
		
	show_points(attacker)
	
	if(get_pcvar_num(SavePoints))
		SaveData(attacker)
}

// Show How Many Points Player Has
public show_points(id)
{
	client_print(id, print_chat, "[%s] Detii acum %d Puncte!", MESSAGE_PREFIX, PlayerPoints[id])
}

// Check If Can Buy
public buy_vip(id)
{
	if(is_user_admin(id))
		client_print(id, print_chat, "[%s] Ai deja VIP!", MESSAGE_PREFIX)
		
	else
	{
		if(PlayerPoints[id] < get_pcvar_num(VIP_Cost))
			client_print(id, print_chat, "[%s] Ai nevoie de mai multe %d Puncte pentru a cumpara VIP!", MESSAGE_PREFIX, get_pcvar_num(VIP_Cost) - PlayerPoints[id])
		
		else
			buying_vip(id)
	}
}

// Setting User VIP If Could Bought VIP
public buying_vip(id)
{
	new VIP_AuthID[35], VIP_Name[32]
	
	get_user_authid(id,VIP_AuthID,34)
	get_user_name(id,VIP_Name,31)
	
	PlayerPoints[id] -= get_pcvar_num(VIP_Cost)
	AddVIP(id, VIP_AuthID, VIP_FLAGS_ACESS, VIP_PASSWORD, VIP_FLAGS_TYPE, VIP_Name)
	client_print(id, print_chat, "[%s] Ai cumparat VIP. Mapa viitoare ti se va activa VIP-ul!", MESSAGE_PREFIX)
	
	if(get_pcvar_num(SavePoints))
		SaveData(id)
}

// Add VIP Via Chat Command
public cmdVIPAdd(id, lvl, cid)
{
	if( !(cmd_access(id, lvl, cid, 0)) )
		return PLUGIN_HANDLED
		
	else
	{
		new iMenu = menu_create("\yAdauga VIP:", "cmdVIPAddHandler")
		
		new iPlayers[32], iNum, iPlayer, szPlayerName[32], szUserId[32]

		get_players(iPlayers, iNum)
		for(--iNum; iNum>=0; iNum--)
		{
			iPlayer = iPlayers[iNum]
			get_user_name(iPlayer, szPlayerName, charsmax(szPlayerName))
			formatex(szUserId, charsmax(szUserId), "%d", get_user_userid(iPlayer))
			menu_additem(iMenu, szPlayerName, szUserId, 0)
		}
    
		menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\y")
		menu_display(id, iMenu)
	}
	
	return PLUGIN_HANDLED
}

public cmdVIPAddHandler(id, iMenu, iItem)
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy(iMenu)
		return PLUGIN_HANDLED
	}
	
	new szUserId[32], szPlayerName[32], iPlayer, iCRAP
	menu_item_getinfo(iMenu, iItem, iCRAP, szUserId, charsmax(szUserId), szPlayerName, charsmax(szPlayerName), iPlayer)
	
	if( (iPlayer = find_player("k", str_to_num(szUserId)))  )
	{
		if(is_user_admin(iPlayer))
			client_print(id, print_chat, "[%s] %s este deja in users.ini! Intra pentru a ii schimba flag-urile", MESSAGE_PREFIX, szPlayerName)
		
		else
		{
			new szAuthid[32], szAdminName[32]
			get_user_authid(iPlayer, szAuthid, charsmax(szAuthid))
			get_user_name(id, szAdminName, charsmax(szAdminName))
			
			AddVIP(id, szAuthid, VIP_FLAGS_ACESS, VIP_PASSWORD, VIP_FLAGS_TYPE, szPlayerName)
			client_print(iPlayer, print_chat, "[%s] %s ti-a adaugat VIP. Mapa viitoare il vei avea.", MESSAGE_PREFIX, szAdminName)
			client_print(id, print_chat, "[%s] Ai adaugat %s <%s> la VIPI. Mapa viitoare il va avea", MESSAGE_PREFIX, szPlayerName, szAuthid)
		}
	}
	
	else
		client_print(id, print_chat, "[%s] %s pare sa fie deconectat.", MESSAGE_PREFIX, szPlayerName)
	
	menu_destroy(iMenu)
	return PLUGIN_HANDLED
}

// Give Points To Someone
public admin_give_points(id,level,cid)
{
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED
	
	else
	{
		new target[32], tid
		read_argv(1,target,31)
		tid = cmd_target(id,target,2)
		
		new amountstr[10], amount
		read_argv(2,amountstr,9)
		amount = str_to_num(amountstr)
		
		new name[32], tname[32]
		get_user_name(id,name,31)
		get_user_name(tid,tname,31)
		
		PlayerPoints[tid] += amount
		client_print(id, print_chat, "[%s] Ai dat %d Puncte Lui %s", MESSAGE_PREFIX, amount, tname)
		client_print(tid, print_chat, "[%s] %s Ai dat %d Puncte. Ai acum %d Puncte", MESSAGE_PREFIX, name, amount)
	}
	return PLUGIN_HANDLED
}

// Remove Points From Someone
public admin_remove_points(id,level,cid)
{
	if(!cmd_access(id,level,cid,3))
		return PLUGIN_HANDLED
	
	else
	{
		new target[32], tid
		read_argv(1,target,31)
		tid = cmd_target(id,target,2)
		
		new amountstr[10], amount
		read_argv(2,amountstr,9)
		amount = str_to_num(amountstr)
		
		new name[32], tname[32]
		get_user_name(id,name,31)
		get_user_name(tid,tname,31)
		
		if((PlayerPoints[tid] -= amount) < 0)
			amount = PlayerPoints[tid]
			
		PlayerPoints[tid] -= amount
		client_print(id, print_chat, "[%s] I-ai scos %d Punctele Lui %s", MESSAGE_PREFIX, amount, tname)
		client_print(tid, print_chat, "[%s] %s I-ai scos  %d Punctele. Ai acum %d Puncte", MESSAGE_PREFIX, name, amount)
	}
	return PLUGIN_HANDLED
}

// Save Points
public SaveData(id)
{
	new AuthID[35]
	get_user_authid(id,AuthID,34)

	new vaultkey[64],vaultdata[256]
	format(vaultkey,63,"%s",AuthID)
	format(vaultdata,255,"%i#",PlayerPoints[id])
	nvault_set(g_vault,vaultkey,vaultdata)
}

// Load Points
public LoadData(id)
{
	new AuthID[35]
	get_user_authid(id,AuthID,34)
	
	new vaultkey[64],vaultdata[256]
	format(vaultkey,63,"%s",AuthID)
	format(vaultdata,255,"%i#",PlayerPoints[id])
	nvault_get(g_vault,vaultkey,vaultdata,255)
	
	replace_all(vaultdata, 255, "#", " ")
	
	new playerpoints[32]
	
	parse(vaultdata, playerpoints, 31)
	
	PlayerPoints[id] = str_to_num(playerpoints)
}

// CREDITS TO AMX MOD X DEVELOPMENT TEAM
AddVIP(id, auth[], accessflags[], password[], flags[], comment[]="")
{
#if defined USING_SQL
	new error[128], errno

	new Handle:info = SQL_MakeStdTuple()
	new Handle:sql = SQL_Connect(info, errno, error, 127)
	
	if (sql == Empty_Handle)
	{
		server_print("[CSGO.EVILS.RO] %L", LANG_SERVER, "SQL_CANT_CON", error)
		//backup to users.ini
#endif
		// Make sure that the users.ini file exists.
		new configsDir[64]
		get_configsdir(configsDir, 63)
		format(configsDir, 63, "%s/users.ini", configsDir)

		if (!file_exists(configsDir))
		{
			console_print(id, "[%s] Fisierul ^"%s^" nu exista.", MESSAGE_PREFIX, configsDir)
			return
		}

		// Make sure steamid isn't already in file.
		new line = 0, textline[256], len
		const SIZE = 63
		new line_steamid[SIZE + 1], line_password[SIZE + 1], line_accessflags[SIZE + 1], line_flags[SIZE + 1], parsedParams
		
		// <name|ip|steamid> <password> <access flags> <account flags>
		while ((line = read_file(configsDir, line, textline, 255, len)))
		{
			if (len == 0 || equal(textline, ";", 1))
				continue // comment line

			parsedParams = parse(textline, line_steamid, SIZE, line_password, SIZE, line_accessflags, SIZE, line_flags, SIZE)
			
			if (parsedParams != 4)
				continue	// Send warning/error?
			
			if (containi(line_flags, flags) != -1 && equal(line_steamid, auth))
			{
				console_print(id, "[%s] %s already exists!", MESSAGE_PREFIX, auth)
				return
			}
		}

		// If we came here, steamid doesn't exist in users.ini. Add it.
		new linetoadd[512]
		
		if (comment[0]==0)
		{
			formatex(linetoadd, 511, "^r^n^"%s^" ^"%s^" ^"%s^" ^"%s^"", auth, password, accessflags, flags)
		}
		else
		{
			formatex(linetoadd, 511, "^r^n^"%s^" ^"%s^" ^"%s^" ^"%s^" ; %s", auth, password, accessflags, flags, comment)
		}
		console_print(id, "Adding:^n%s", linetoadd)

		if (!write_file(configsDir, linetoadd))
			console_print(id, "[%s] Failed writing to %s!", MESSAGE_PREFIX, configsDir)
#if defined USING_SQL
	}
	
	new table[32]
	
	get_cvar_string("amx_sql_table", table, 31)
	
	new Handle:query = SQL_PrepareQuery(sql, "SELECT * FROM `%s` WHERE (`auth` = '%s')", table, auth)

	if (!SQL_Execute(query))
	{
		SQL_QueryError(query, error, 127)
		server_print("[CSGO.EVILS.RO] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", error)
		console_print(id, "[CSGO.EVILS.RO] %L", LANG_SERVER, "SQL_CANT_LOAD_ADMINS", error)
	} else if (SQL_NumResults(query)) {
		console_print(id, "[%s] %s exista deja!", MESSAGE_PREFIX, auth)
	} else {
		console_print(id, "Adding to database:^n^"%s^" ^"%s^" ^"%s^" ^"%s^"", auth, password, accessflags, flags)
	
		SQL_QueryAndIgnore(sql, "REPLACE INTO `%s` (`auth`, `password`, `access`, `flags`) VALUES ('%s', '%s', '%s', '%s')", table, auth, password, accessflags, flags)
	}
	
	SQL_FreeHandle(query)
	SQL_FreeHandle(sql)
	SQL_FreeHandle(info)
#endif
}
