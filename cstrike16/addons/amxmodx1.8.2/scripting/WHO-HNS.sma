#include <amxmodx>
#include <amxmisc>

#define PLUGIN "Admini - HNS.ECILA.RO"
#define VERSION "1.0"
#define AUTHOR "Triplu"

#define CharsMax(%1) sizeof %1 - 1

#define MAX_GROUPS 8

new g_groupNames[MAX_GROUPS][] = {

	"----- * Fondator+Ftp * -----",
	"----- * Manager * -----",
	"----- * Owner * -----",
	"----- * GooD * -----",
	"----- * Moderator * -----",
	"----- * Administrator * -----",
	"----- * Helper * -----",
	"----- * Tester * -----"
}

new g_groupFlags[MAX_GROUPS][] = {

	"abcdefghijklmnoprstu",
	"abcdefijkmnoprst",
	"abcdefijmnrst",
	"bcdefijmnrt",
	"bfjcedijmngsp",
	"bfjcedijmn",
	"bfjceijdm",
	"bceij"
}

new g_groupFlagsValue[MAX_GROUPS];
//srvcmd pt unbancfg s fie doar pt mng si fond
public plugin_init() {
	
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	for(new i = 0; i < MAX_GROUPS; i++)
		g_groupFlagsValue[i] = read_flags(g_groupFlags[i]);
	
	register_clcmd("say /who", "cmdWho", -1, "");
	register_clcmd("say /admin", "cmdWho", -1, "");


	register_concmd("amx_unlag","UNLAG_FC",ADMIN_LEVEL_A,"<valoare>")
	register_concmd("amx_restart","RESTART_FC",ADMIN_LEVEL_A,"<valoare>")
	register_concmd("amx_timelimit","TIMELIMIT_FC",ADMIN_LEVEL_A,"<valoare>")
}


public UNLAG_FC(id,level,cid)
{
	if(!cmd_access(id,level,cid,2))	return PLUGIN_HANDLED

	new arg1[32],nume[32]
	read_argv(1,arg1,charsmax(arg1))
	get_user_name(id,nume,charsmax(nume))

	client_print(0,print_chat,"[AMXX] Adminul %s , a setat sv_unlag pe %d",nume,str_to_num(arg1))
	server_cmd("sv_unlag %d",str_to_num(arg1))

	return PLUGIN_HANDLED
}
public RESTART_FC(id,level,cid)
{
	if(!cmd_access(id,level,cid,2))	return PLUGIN_HANDLED

	new arg1[32],nume[32]
	read_argv(1,arg1,charsmax(arg1))
	get_user_name(id,nume,charsmax(nume))

	client_print(0,print_chat,"[AMXX] Adminul %s , a setat sv_restart pe %d",nume,str_to_num(arg1))
	server_cmd("sv_restart %d",str_to_num(arg1))

	return PLUGIN_HANDLED
}
public TIMELIMIT_FC(id,level,cid)
{
	if(!cmd_access(id,level,cid,2))	return PLUGIN_HANDLED

	new arg1[32],nume[32]
	read_argv(1,arg1,charsmax(arg1))
	get_user_name(id,nume,charsmax(nume))

	client_print(0,print_chat,"[AMXX] Adminul %s , a setat mp_timelimit pe %d",nume,str_to_num(arg1))
	server_cmd("mp_timelimit %d",str_to_num(arg1))

	return PLUGIN_HANDLED
}



public cmdWho(id)
{
	static sPlayers[32], iNum, iPlayer;
	static sName[32], sBuffer[1024];
	
	static iLen;
	iLen = formatex(sBuffer, sizeof sBuffer - 1, "<body bgcolor=#000000><font color=red><pre>");
	//iLen += formatex(sBuffer[iLen], CharsMax(sBuffer) - iLen,"<center><h2><font color=^"00f5d0^"><B>Admini Online</B></font></h2></center>^n^n");
	
	get_players(sPlayers, iNum, "ch");
	
	for(new i = 0; i < MAX_GROUPS; i++)
	{
		iLen += formatex(sBuffer[iLen], CharsMax(sBuffer) - iLen, "<center><h5><font color=^"white^"> *[<B>%s</B>]* ^n</font></h5></center>", g_groupNames[i]);
		
		for(new x = 0; x < iNum; x++)
		{
			iPlayer = sPlayers[x];
			
			if(get_user_flags(iPlayer) == g_groupFlagsValue[i])
			{
				get_user_name(iPlayer, sName, sizeof sName - 1);
				iLen += formatex(sBuffer[iLen], CharsMax(sBuffer) - iLen, "<center>%s^n</center>", sName);
			}
		}
	}
	show_motd(id, sBuffer, "Adminii Online");
	return 0;
}
