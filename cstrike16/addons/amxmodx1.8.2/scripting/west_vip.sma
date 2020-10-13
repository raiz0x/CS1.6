#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#if AMXX_VERSION_NUM < 183
	#include <colorchat_lang>

static const	m_iMenu = 205,
				MENU_OFF= 0
#endif

#pragma tabsize 0

enum eData {
	Name[33],
	Pw[35],
	SpawnAP,
	MoneyKill,
	MoneyKillHS,
	HpKill, 
	HpKillHS,
	ApKill, 
	ApKillHS,
	MaxHP,
	MaxAP,
	Jumps
}
new Array:g_aBenefits
new g_iBenefitsNum = 0
new bool:g_bHaveBenefits[33]

new g_iJumpsNum[33], g_iMaxJumps[33]
new bool:g_bIsJumping[33]

enum _:EVO{
	vML[45]
}
new const WF[][EVO]=//x
{
	{"models/vip/v_akg.mdl"},
	{"models/vip/v_kng.mdl"}
}
new roundc,prefix_chat,g_szPrefix[32], g_hudmsg1, g_hudmsg2

public plugin_init() {
	
	// Add your code here...
	
	g_aBenefits = ArrayCreate(eData)
	
	RegisterHam(Ham_Spawn, "player", "HamPlayerSpawn", 1)
	RegisterHam(Ham_Player_Jump, "player", "hamPlayerJump", 0)
	
	register_event("DeathMsg", "evDeathMsg", "a")
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")
	register_event("Damage", "on_damage", "b", "2!0", "3=0", "4!0")	
	register_event("TextMsg", "eRestart", "a", "2&#Game_C", "2&#Game_w")
	register_event( "CurWeapon","Event_CurWeapon","be", "1=1" )
	
	register_clcmd("say", "cmdSay")
	register_clcmd("say_team", "cmdSay")
	
	prefix_chat=register_cvar("vip_cp","[^3WEST^1]")
	get_pcvar_string(prefix_chat,g_szPrefix,charsmax(g_szPrefix))
	
	g_hudmsg1 = CreateHudSyncObj()	
	g_hudmsg2 = CreateHudSyncObj()
}
public plugin_precache()	for (new i; i < sizeof(WF); i++)	precache_model(WF[i][vML])
public plugin_cfg(){
	new szConfigsDir[128];get_localinfo("amxx_configsdir",szConfigsDir, charsmax(szConfigsDir))
	add(szConfigsDir, charsmax(szConfigsDir), "/benefits.ini")
	
	if(!file_exists(szConfigsDir)){
		write_file(szConfigsDir,
";Numele VIP-ului	Parola		AP Spawn	Kill Money	Kill HS Money		HP Kill		HP Kill HS	Maxim HP	AP Kill		AP Kill HS	Maxim AP	Numar sarituri (1 = No multijump)")
		write_file(szConfigsDir, ";	Exemplu:")
		write_file(szConfigsDir,
";^"eVoLuTiOn^"		^"evoboss^"	^"100^"		^"150^"		^"2000^"		^"15^"		^"30^"		^"100^"		^"15^"		^"30^"		^"100^"		^"1^"")
	}
	
	static f; f = fopen(szConfigsDir, "r+")
	if(!f)	return
	new szLineData[128], szName[33], szPW[35], szSpawnAP[8], szMoneyPerKill[8],szMoneyPerKillHS[8], szHpPerKill[8], szHpPerKillHS[8],
	szApPerKill[8], szApPerKillHS[8],szMaxHP[8],szMaxAP[8], szJumpsNum[8]
	new aData[eData]
	while(!feof(f)){
		fgets(f, szLineData, charsmax(szLineData))
		if(szLineData[0] == ';' || !szLineData[0]) 	continue
		
		parse(szLineData, szName, charsmax(szName), szPW, charsmax(szPW), szSpawnAP, charsmax(szSpawnAP),
			szMoneyPerKill,charsmax(szMoneyPerKill), szMoneyPerKillHS, charsmax(szMoneyPerKillHS),
				szHpPerKill, charsmax(szHpPerKill),szHpPerKillHS,charsmax(szHpPerKillHS),szMaxHP,charsmax(szMaxHP),
					szApPerKill, charsmax(szApPerKill),szApPerKillHS,charsmax(szApPerKillHS),szMaxAP,charsmax(szMaxAP),szJumpsNum, charsmax(szJumpsNum));
		
		copy(aData[Name], charsmax(aData[Name]), szName)
		copy(aData[Pw], charsmax(aData[Pw]), szPW)
		aData[SpawnAP] = str_to_num(szSpawnAP)
		aData[MoneyKill] = str_to_num(szMoneyPerKill)
		aData[MoneyKillHS] = str_to_num(szMoneyPerKillHS)
		aData[HpKill] = str_to_num(szHpPerKill)
		aData[HpKillHS] = str_to_num(szHpPerKillHS)
		aData[MaxHP] = str_to_num(szMaxHP)
		aData[ApKill] = str_to_num(szApPerKill)
		aData[ApKillHS] = str_to_num(szApPerKillHS)
		aData[MaxAP] = str_to_num(szMaxAP)
		aData[Jumps] = str_to_num(szJumpsNum)
		
		ArrayPushArray(g_aBenefits, aData)
		g_iBenefitsNum++
	}
}
public plugin_end()	ArrayDestroy(g_aBenefits)

public client_putinserver(id){
	if(is_user_bot(id)||is_user_hltv(id))	return
	
	g_bHaveBenefits[id] = false
	g_bIsJumping[id] = false
	g_iJumpsNum[id] = 0
	g_iMaxJumps[id] = 1

	new aData[eData],name[33],cpw[35]
	get_user_name(id,name,charsmax(name))
	get_user_info(id,"_vip",cpw,charsmax(cpw))
	for (new i; i < g_iBenefitsNum; i++){
		ArrayGetArray(g_aBenefits, i, aData)
		if(equal(aData[Name],name)){
			if(equal(aData[Pw],cpw)){
				g_bHaveBenefits[id] = true
				g_iMaxJumps[id] = aData[Jumps]
			}
			else	server_cmd("kick #%d ^"Parola VIP gresita!^"",get_user_userid(id))
			//break;
		}
	}
}

public cmdSay(id){
	static arg[195];read_args(arg,charsmax(arg))
	remove_quotes(arg)
	if(!arg[0])	return
	
	if(equal(arg,"/vips"))	print_list(id)
	else	if(equal(arg,"/vip"))	show_motd(id,"/addons/amxmodx/configs/vip.html","VIP BENEFITS")
}
public print_list( user ){
	new adminnames[ 33 ][ 33 ],message[ 256 ]
	new id, count, x, len

	for( id = 1; id <= get_maxplayers( ); id++ )	if( is_user_connected( id )&&g_bHaveBenefits[id]&&!is_user_bot(id)||!is_user_hltv(id) )	get_user_name( id, adminnames[ count ++ ], charsmax(adminnames[]) );

	len = formatex( message, charsmax(message), "^4VIP ONLINE^1: " )
	if( count > 0 ){
		for( x = 0; x < count; x++ ){
			len += formatex( message[ len ], charsmax(message) - len, "[^3 %s^1 ]^4 %s ", adminnames[ x ], x < ( count - 1 ) ? " | " : "" )
			if( len > 96 ){
				len = formatex( message, charsmax(message), "" )
				client_print_color( user,print_team_default, message )
			}
		}
		client_print_color( user,print_team_default, message )
	}
	else{
		len += formatex( message[ len ], charsmax(message) - len, "Nu este nici un^3 VIP^1 Conectat." )
		client_print_color( user,print_team_default, message )
	}
}

public event_new_round()	roundc++

public client_PreThink(id){
    if(!is_user_alive(id))	return
	//if(!g_bHaveBenefits[id])	return			DACĂ VREI PARA DOAR PT VIP ACTIVEZI ASTA
    static button;button = get_user_button(id)
    if(button & IN_USE){
        static Float:velocity[3];entity_get_vector(id, EV_VEC_velocity, velocity)
        if (velocity[2] < 0.0){
			static Float:fallspeed;fallspeed = 100.0 * -1.0

            entity_set_int(id, EV_INT_sequence, 3)
            entity_set_int(id, EV_INT_gaitsequence, 1)
            entity_set_float(id, EV_FL_frame, 1.0)
            entity_set_float(id, EV_FL_framerate, 1.0)

            velocity[2] = (velocity[2] + 40.0 < fallspeed) ? velocity[2] + 40.0 : fallspeed
            entity_set_vector(id, EV_VEC_velocity, velocity)
        }
    }
}

public HamPlayerSpawn(id)
{
	if(!is_user_alive(id) || !g_bHaveBenefits[id])	return
	
	if(user_has_weapon(id,CSW_C4))	engclient_cmd(id,"drop","weapon_c4")	//use weapon_c4 + drop		//HC4[id]=true
	//else	HC4[id]=false
	strip_user_weapons(id)
	give_item(id,"weapon_knife")
	give_item(id,"weapon_deagle")
	cs_set_user_bpammo(id,CSW_DEAGLE,35)
	//if(HC4[id])	give_item(id,"weapon_c4")
	engclient_cmd(id,"weapon_knife")
	set_pev(id, pev_viewmodel2, WF[0][vML])
	
	new aData[eData]
	for (new i; i < g_iBenefitsNum; i++){
		ArrayGetArray(g_aBenefits, i, aData)
		if(aData[SpawnAP] > 0)	set_user_armor(id, aData[SpawnAP])
		//break;
	}
	
	if(roundc>=3)	MENIU_VIP(id)
}
public hamPlayerJump(id){
	if(!is_user_alive(id)||!g_bHaveBenefits[id]) return HAM_HANDLED;
	if( pev( id, pev_flags ) & FL_WATERJUMP || pev(id, pev_waterlevel) >= 2 || !(get_pdata_int(id, 246) & IN_JUMP) )	return HAM_IGNORED
	if(pev( id, pev_flags ) & FL_ONGROUND) {
		g_iJumpsNum[ id ] = 0
		return HAM_IGNORED
	}
	if( get_pdata_float(id, 251) < 500 && ++g_iJumpsNum[id] < g_iMaxJumps[id] ) {
		static Float:fVelocity[ 3 ];pev( id, pev_velocity, fVelocity )
		fVelocity[ 2 ] = 268.328157
		set_pev( id, pev_velocity, fVelocity )
		return HAM_HANDLED
	}
	return HAM_IGNORED	
}

public Event_CurWeapon(id){
	if(!is_user_alive(id)||!g_bHaveBenefits[id])	return
	switch(get_user_weapon(id)){
		case CSW_AK47:	set_pev(id, pev_viewmodel2, WF[0][vML])
		case CSW_KNIFE:	set_pev(id, pev_viewmodel2, WF[1][vML])
	}
}

public on_damage(id){	
	static damage; damage = read_data(2)		
	if(g_bHaveBenefits[id]||!is_user_connected(id)){			
		set_hudmessage(255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1)
		ShowSyncHudMsg(id, g_hudmsg2, "%i^n", damage)		
	}
	static attacker; attacker = get_user_attacker(id)
	if(is_user_connected(attacker)&&g_bHaveBenefits[attacker]){
		set_hudmessage(0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1)
		ShowSyncHudMsg(attacker, g_hudmsg1, "%i^n", damage)				
	}
}

public eRestart()	roundc=0

public MENIU_VIP(id){
	static menu; menu=menu_create("\yV.I.P\w MENU","VM")
	menu_additem(menu,"AK47")
	menu_additem(menu,"M4A1")
	menu_additem(menu,"AWP")
#if AMXX_VERSION_NUM < 183// Fix for AMXX basic menus
	set_pdata_int (id, m_iMenu, MENU_OFF);
#endif
	menu_display(id,menu)
}
public VM(id,Menu,Item){
	if(!is_user_alive(id)||Item<0)	return
	switch(Item){
		case 0:{
			give_item(id,"weapon_ak47")
			cs_set_user_bpammo(id,CSW_AK47,90)
			engclient_cmd(id,"weapon_ak47")
			set_pev(id, pev_viewmodel2, WF[0][vML])
		}
		case 1:{
			give_item(id,"weapon_m4a1")
			cs_set_user_bpammo(id,CSW_M4A1,90)
		}
		case 2:{
			give_item(id,"weapon_awp")
			cs_set_user_bpammo(id,CSW_AWP,30)
		}
	}
	if(Item==0||Item==1||Item==2){
		give_item(id,"weapon_hegrenade")
		give_item(id,"weapon_flashbang")
		give_item(id,"weapon_flashbang")
	}
}

public evDeathMsg( ){
	static iKiller; iKiller = read_data(1)
	static iVictim; iVictim = read_data(2)
	if(iKiller == iVictim || !is_user_alive(iKiller) || !g_bHaveBenefits[iKiller])	return
	static hs;hs=read_data(3)
	new aData[eData]
	for (new i; i < g_iBenefitsNum; i++){
		ArrayGetArray(g_aBenefits, i, aData)
		set_user_health(iKiller,!hs?min(aData[MaxHP],get_user_health(iKiller)+aData[HpKill]):min(aData[MaxHP],get_user_health(iKiller)+aData[HpKillHS]))
		set_user_armor(iKiller,!hs?min(aData[MaxAP],get_user_armor(iKiller)+aData[ApKill]):min(aData[MaxAP],get_user_armor(iKiller)+aData[ApKillHS]))
		cs_set_user_money(iKiller,!hs?cs_get_user_money(iKiller)+aData[MoneyKill]:cs_get_user_money(iKiller)+aData[MoneyKillHS],1)
		/*if(get_user_health(iKiller)>aData[MaxHP])	set_user_health(iKiller,aData[MaxHP])		ASTEA LE ACTIVEZI DACĂ VREI SĂ VERIFICE LIMITA HP/AP DRASTIC
		if(get_user_armor(iKiller)>aData[MaxAP])	set_user_armor(iKiller,aData[MaxAP])*/
		//break;
	}
}
