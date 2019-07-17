#include <amxmodx>
#include <amxmisc>
#include <nvault>
#include <colorchat>

#define Flaga ADMIN_LEVEL_H
#define prefix "^1[^3GOLDSRC^1]"

new use[33],czas_gracza[33],vaultkey[64],vaultdata[256],name[35]
new g_vault
new czas,zapis

public plugin_init() 
{
	g_vault = nvault_open("vtest")
	if(g_vault==INVALID_HANDLE)	set_fail_state("Eroare la deschiderea `vtest`")

	register_clcmd("say", "handleSay")
	register_clcmd("say_team", "handleSay")
	
	czas = register_cvar("goldsrc_viptest_ore","2")//cam aiurea
	zapis = register_cvar("goldsrc_viptest_save","1")//1-nume/2-steamid/3-ip
}

public handleSay( e_Index )
{
	static s_Args[ 192 ]
	read_args( s_Args, charsmax( s_Args ) )
	if( !s_Args[ 0 ] )	return 1
	remove_quotes( s_Args[ 0 ] )

	if( equal( s_Args,"/testvip" )||equal( s_Args,"/viptest" ) )	vip_test(e_Index)

	return PLUGIN_CONTINUE
}

public vip_test(id)
{
	if(get_user_flags(id) & Flaga || use[id] == 1)	ColorChat(id, NORMAL, "%s Beneficiezi deja de^4 acces",prefix)
	else
	{
		use[id] = 1
		czas_gracza[id] = get_pcvar_num(czas)*3600
		set_task(1.0,"sprawdz",id,_,_,"b")
		set_task(30.0,"timer",id,_,_,"b")
		set_user_flags(id, get_user_flags(id) | Flaga)
		save(id)
	}
}
public sprawdz(id)
{
	czas_gracza[id]--
	if(czas_gracza[id] <= 0)
	{
		if(task_exists(id))	remove_task(id)
		remove_user_flags(id, Flaga)//set DEF..
		czas_gracza[id]=0
		if(use[id])	use[id]=0
	}
}

public client_connect(id)
{
	use[id] = 0
	czas_gracza[id] = 0
	load(id)
}

public client_disconnect(id)
{
	if(task_exists(id))	remove_task(id)
	if(use[id] == 1)	save(id)
}

public save(id)
{
	switch(get_pcvar_num(zapis))
	{
		case 1:	get_user_name(id,name,charsmax(name))
		case 2:
		{
			if(is_user_steam(id))	get_user_authid(id, name, charsmax(name))
			else	get_user_name(id,name,charsmax(name))
		}
		case 3:	get_user_ip(id,name,charsmax(name),1)
	}
	
	new vaultkey[64],vaultdata[256]
	formatex(vaultkey,charsmax(vaultkey),"%s-vt",name)
	formatex(vaultdata,charsmax(vaultdata),"%d#%d",czas_gracza[id],use[id])
	nvault_set(g_vault,vaultkey,vaultdata)
}
public load(id)
{
	switch(get_pcvar_num(zapis))
	{
		case 1:	get_user_name(id,name,charsmax(name))
		case 2:
		{
			if(is_user_steam(id))	get_user_authid(id, name, charsmax(name))
			else	get_user_name(id,name,charsmax(name))
		}
		case 3:	get_user_ip(id,name,charsmax(name),1)
	}
	
	formatex(vaultkey,charsmax(vaultkey),"%s-vt",name)
	formatex(vaultdata,charsmax(vaultdata),"%d#%d",czas_gracza[id], use[id])
	nvault_get(g_vault,vaultkey,vaultdata,charsmax(vaultdata))
	replace_all(vaultdata,charsmax(vaultdata), "#", " ")
	
	new zmienna[33], zmienna1[33]
	parse(vaultdata, zmienna, charsmax(zmienna), zmienna1, charsmax(zmienna1))	
	
	czas_gracza[id] = str_to_num(zmienna)
	use[id] = str_to_num(zmienna1)
	
	if(czas_gracza[id] > 0)//use
	{
		set_task(30.0,"timer",id,.flags="b")
		set_task(1.0,"sprawdz",id,.flags="b")
		set_user_flags(id, get_user_flags(id) | Flaga)
	}
}

public timer(id)
{
	new szTime[32]
	getFormatedTime(czas_gracza[id], szTime, charsmax(szTime))
	ColorChat(id, NORMAL, "%s ^3VIPTEST^1 expira peste: ^4%s^1!",prefix,szTime)
}

stock getFormatedTime(iTime, szTime[], size)
{
	new hours = iTime/3600
	new minutes=iTime%3600/60//da..
	formatex(szTime, size, "%d or%s si %d minut%s", hours,hours==1?"a":"e",minutes,minutes==1?"":"e")//chrm
}
stock bool:is_user_steam(id) {
	get_user_authid(id, name,charsmax(name));
	return bool:(contain(name, "STEAM_0:0:") != -1 || contain(name, "STEAM_0:1:") != -1);
}

public plugin_end()	if(g_vault!=INVALID_HANDLE)	nvault_close(g_vault)
