//	NO HARD
//		UN PLUGIN FACUT DIN SIMPLITATE&DRAGOSTE , 
//			DE LA EVO PT DARKYYY
//				PLUGIN CREAT DE	ADRYYY	LA CEREREA LUI	DRAKYYY	PENTRU	EVILS.RO
//					PLUGIN CREAT PE	27.04.2017	20:00
//						ULTIMA EDITARE PE	12.06.2017 - 21:22

#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta_util>
#include <engine>
#include <fun>

#define ADMIN_FLAG_X (1<<23)

#define VIP_GOLD ADMIN_FLAG_X
#define VIP_PLANTIUM ADMIN_ADMIN

enum {
	SCOREATTRIB_ARG_PLAYERID = 1,
	SCOREATTRIB_ARG_FLAGS
};

enum ( <<= 1 ) {
	SCOREATTRIB_FLAG_NONE = 0,
	SCOREATTRIB_FLAG_DEAD = 1,
	SCOREATTRIB_FLAG_BOMB,
	SCOREATTRIB_FLAG_VIP
};

new jumpnum[33] = 0,bool:dojump[33] = false,VGMenu,VPMenu

new bool:vip_free,vip_freeX = 0
new const vip_time[] = {22,10}

public plugin_init()
{

	register_message( get_user_msgid( "ScoreAttrib" ), "MessageScoreAttrib" );
	
	register_cvar("enable_vip","0")
	
	register_clcmd("say /vmenu","VIPM")
	register_clcmd("say_team /vmenu","VIPM")
	register_clcmd("say /vm","VIPM")
	register_clcmd("say_team /vm","VIPM")
	
	register_cvar("vip_gold_maxhp","125")
	register_cvar("vip_gold_killhp","5")
	register_cvar("vip_gold_hshp","10")
	register_cvar("vip_gold_multidmg","1.5")
	register_cvar("vip_gold_maxjumps","2")
	register_cvar("vip_gold_freevip","1")
	register_cvar("vip_gold_start","22")
	register_cvar("vip_gold_end","10")
	
	register_cvar("vip_plantium_maxhp","150")
	register_cvar("vip_plantium_killhp","5")
	register_cvar("vip_plantium_hshp","10")
	register_cvar("vip_plantium_multidmg","2.0")
	register_cvar("vip_plantium_maxjumps","3")
	
	if(get_cvar_num("vip_gold_freevip"))
	{
		check_time( )
		set_task( 10.0, "check_time", _, _, _, "b" )
		
		register_clcmd( "say /event", "time_remain" );
		register_clcmd( "say event", "time_remain" );
		register_clcmd( "say_team /event", "time_remain" );
		register_clcmd( "say_team event", "time_remain" );
	}
}

public client_putinserver(id)
{
	if(!get_cvar_num("enable_vip"))	return
	if(is_gold_vip(id)||is_plantium_vip(id))
	{
		jumpnum[id] = 0
		dojump[id] = false
	}
	if(get_cvar_num("vip_gold_freevip"))	check_time( )
}

public MessageScoreAttrib( iMsgId, iDest, iReceiver ) {
	new iPlayer = get_msg_arg_int( SCOREATTRIB_ARG_PLAYERID );
	
	if( is_plantium_vip(iPlayer)&&get_cvar_num("enable_vip") ) {
		set_msg_arg_int( SCOREATTRIB_ARG_FLAGS, ARG_BYTE, SCOREATTRIB_FLAG_VIP );
	}
}

public check_time( )
{
	if(get_cvar_num("vip_gold_freevip")==0)	return
	static preluare_ora[ 3 ], ora;
	get_time( "%H", preluare_ora, 2 );
	ora = str_to_num( preluare_ora );
	
	if( get_cvar_num("vip_gold_start") <= ora || ora < get_cvar_num("vip_gold_end") )
	{
		if( !vip_free )
		{
			xCoLoR(0, "!v[!n FREE GOLD-VIP!v ]!n Fiind trecut de ora!e %d:00!n, toti jucatorii conectati au primit acces!v *V.I.P GOLD*!n, pana la ora!e %d:00!n !",get_cvar_num("vip_gold_start"),get_cvar_num("vip_gold_end") );
		}
		vip_free = true;
		server_cmd( "amx_default_access ^"t^"" );
		server_cmd( "amx_reloadadmins" );
		vip_freeX = 1;
	}
	
	else
	{
		if( vip_free )
		{
			xCoLoR(0, "!v[!n FREE GOLD-VIP!v ]!n Fiind trecut de ora!e %d:00!n, eventul!v *V.I.P GOLD*!n, a luat!e Sfarsit!n, si va reincepe la ora!v %d:00!n !",get_cvar_num("vip_gold_end"),get_cvar_num("vip_gold_start") );
		}
		vip_free = false;
		server_cmd( "amx_default_access ^"z^"" );
		server_cmd( "amx_reloadadmins" );
		vip_freeX = 0;
	}
}

public client_disconnect(id)
{
	if(!get_cvar_num("enable_vip"))	return
	if(is_gold_vip(id)||is_plantium_vip(id))
	{
		jumpnum[id] = 0
		dojump[id] = false
	}
	if(get_cvar_num("vip_gold_freevip"))	check_time( )
}

public client_spawn(id)
{
	if(!is_user_alive(id)||get_cvar_num("enable_vip")!=1)	return
	if(is_gold_vip(id))	set_user_health(id,get_cvar_num("vip_gold_maxhp"))
	else if(is_plantium_vip(id))	set_user_health(id,get_cvar_num("vip_plantium_maxhp"))
}

public client_PreThink(id)
{
	if(!is_user_alive(id) ||!is_gold_vip(id)||!is_plantium_vip(id) ||get_cvar_num("enable_vip")!=1) return PLUGIN_HANDLED
	new nbut = get_user_button(id)
	new obut = get_user_oldbutton(id)
	if((nbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(obut & IN_JUMP))
	{
		if(is_gold_vip(id))
		{
			if(jumpnum[id] < get_cvar_num("vip_gold_maxjumps"))
			{
				dojump[id] = true
				jumpnum[id]++
				return PLUGIN_CONTINUE
			}
		}
		else if(is_plantium_vip(id))
		{
			if(jumpnum[id] < get_cvar_num("vip_plantium_maxjumps"))
			{
				dojump[id] = true
				jumpnum[id]++
				return PLUGIN_CONTINUE
			}	
		}
	}
	if((nbut & IN_JUMP) && (get_entity_flags(id) & FL_ONGROUND))
	{
		jumpnum[id] = 0
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}

public client_PostThink(id)
{
	if(!is_user_alive(id) ||!is_gold_vip(id)||!is_plantium_vip(id) ||get_cvar_num("enable_vip")!=1) return PLUGIN_HANDLED
	if(dojump[id] == true)
	{
		new Float:velocity[3]
		entity_get_vector(id,EV_VEC_velocity,velocity)
		velocity[2] = random_float(265.0,285.0)
		entity_set_vector(id,EV_VEC_velocity,velocity)
		dojump[id] = false
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
} 

public client_damage(attacker,victim,damage,wpnindex,hitplace,TA)
{
	if(!is_user_alive(attacker)||!is_user_alive(victim)||attacker==victim||get_cvar_num("enable_vip")!=1)	return
	if(is_gold_vip(attacker))	damage * get_cvar_float("vip_gold_multidmg")
	else if(is_plantium_vip(attacker))	damage * get_cvar_float("vip_plantium_multidmg")
}

public client_death(killer,victim,wpnindex,hitplace,TK)
{
	if(!is_user_alive(killer)||!is_user_alive(victim)||victim==killer||get_cvar_num("enable_vip")!=1)	return
	if(is_gold_vip(killer))
	{
		if(hitplace==HIT_HEAD)	set_user_health(killer,get_user_health(killer)+get_cvar_num("vip_gold_hshp"))
		else	set_user_health(killer,get_user_health(killer)+get_cvar_num("vip_gold_killhp"))
	}
	else if(is_plantium_vip(killer))
	{
		if(hitplace==HIT_HEAD)	set_user_health(killer,get_user_health(killer)+get_cvar_num("vip_plantium_hshp"))
		else	set_user_health(killer,get_user_health(killer)+get_cvar_num("vip_plantium_killhp"))
	}
}

public VIPM(id)
{
	if(!is_user_alive(id)||get_cvar_num("enable_vip")!=1)	return 1
	
	if(is_gold_vip(id))
	{
		VGMenu = menu_create( "wMENIU ARMEy Vw.yIw.yPr GOLD", "VGC" );
		
		menu_additem( VGMenu, "r>w AK47y V.I.P", "1" );
		menu_additem( VGMenu, "r>w M4A1y V.I.P", "2" );
		menu_additem( VGMenu, "r>w AWPy V.I.P", "3" );
		
		menu_display( id, VGMenu );
	}
	else if(is_plantium_vip(id))
	{
		VPMenu = menu_create( "wMENIU ARMEy Vw.yIw.yPd PLANTIUM", "VPC" );
		
		menu_additem( VPMenu, "d>w FULLy V.I.Pw AK47", "1" );
		menu_additem( VPMenu, "d>w FULLy V.I.Pw M4A1", "2" );
		menu_additem( VPMenu, "d>w FULLy V.I.Pw AWP", "3" );
		
		menu_display( id, VPMenu );
	}
	return 1
}

public VGC( id, Menu, Item )
{
	if( Item < 0 )
	{
		return 0;
	}
	
	new Key[ 3 ];
	new Access, CallBack;
	
	menu_item_getinfo( Menu, Item, Access, Key, 2, _, _, CallBack );
	
	new isKey = str_to_num( Key );
	
	switch( isKey )
	{
		case 1:
		{
			give_item(id,"weapon_ak47")
			cs_set_user_bpammo(id,fm_find_ent_by_owner(-1,"weapon_ak47",id),90)
		}
		case 2:
		{
			give_item(id,"weapon_m4a1")
			cs_set_user_bpammo(id,fm_find_ent_by_owner(-1,"weapon_m4a1",id),90)
		}
		case 3:
		{
			give_item(id,"weapon_awp")
			cs_set_user_bpammo(id,fm_find_ent_by_owner(-1,"weapon_awp",id),30)
		}
	}
	
	return 1;
}

public VPC( id, Menu, Item )
{
	if( Item < 0 )
	{
		return 0;
	}
	
	new Key[ 3 ];
	new Access, CallBack;
	
	menu_item_getinfo( Menu, Item, Access, Key, 2, _, _, CallBack );
	
	new isKey = str_to_num( Key );
	
	switch( isKey )
	{
		case 1:
		{
			give_item(id,"weapon_ak47")
			cs_set_user_bpammo(id,fm_find_ent_by_owner(-1,"weapon_ak47",id),90)
			
			give_item(id,"weapon_hegrenade")
			give_item(id,"weapon_flashbang")
			give_item(id,"weapon_flashbang")
			give_item(id,"weapon_smokegrenade")
			give_item(id,"weapon_deagle")
			cs_set_user_bpammo(id,fm_find_ent_by_owner(-1,"weapon_deagle",id),35)
		}
		case 2:
		{
			give_item(id,"weapon_m4a1")
			cs_set_user_bpammo(id,fm_find_ent_by_owner(-1,"weapon_m4a1",id),90)
			
			give_item(id,"weapon_hegrenade")
			give_item(id,"weapon_flashbang")
			give_item(id,"weapon_flashbang")
			give_item(id,"weapon_smokegrenade")
			give_item(id,"weapon_deagle")
			cs_set_user_bpammo(id,fm_find_ent_by_owner(-1,"weapon_deagle",id),35)
		}
		case 3:
		{
			give_item(id,"weapon_awp")
			cs_set_user_bpammo(id,fm_find_ent_by_owner(-1,"weapon_awp",id),30)
			
			give_item(id,"weapon_hegrenade")
			give_item(id,"weapon_flashbang")
			give_item(id,"weapon_flashbang")
			give_item(id,"weapon_smokegrenade")
			give_item(id,"weapon_deagle")
			cs_set_user_bpammo(id,fm_find_ent_by_owner(-1,"weapon_deagle",id),35)
		}
	}
	
	return 1;
}

stock bool: is_gold_vip( id )
{
	if( get_user_flags( id ) & VIP_GOLD )
	{
		return true;
	}
	
	return false;
}

stock bool: is_plantium_vip( id )
{
	if( get_user_flags( id ) & VIP_PLANTIUM )
	{
		return true;
	}
	
	return false;
}

public time_remain( id )
{
	switch( vip_freeX )
	{
		case 1: xCoLoR( id, "!v[!n CS!v ]!n Eventul!e - VIP GRATUIT -!n se sfarseste in:!v %s!n.", time_left_vip( ) );
		
		case 0: xCoLoR( id, "!v[!n CS!v ]!n Eventul!e - VIP GRATUIT -!n incepe in:!v %s!n.", time_left_vip( ) );
	}
	
	//return PLUGIN_CONTINUE;
}

stock time_left_vip( )
{
	new timp_ramas[ 32 ], len = 0;
	
	new h, m, lh, lm;
	
	time( h, m, _ );
	
	switch( vip_freeX )
	{
		case 1:
		{
			new l = vip_time[ 1 ];
			
			if( h > l )
			l += add_time( h ) + h;
			
			lh = l - h;
		}
		
		case 0: lh = vip_time[ 0 ] - h;
	}
	
	lm = 60 - m;
	
	if( lm < 60 )
	lh--;
	
	if( lh > 0 )
	len += formatex( timp_ramas[ len ], charsmax( timp_ramas ) - len, "%d or%s", lh, lh == 1 ? "a" : "e" );
	
	if( lm < 60 )
	len += formatex( timp_ramas[ len ], charsmax( timp_ramas ) - len, " si %d minut%s", lm, lm == 1 ? "" : "e" );
	
	return timp_ramas;
}

stock add_time( x )
{
	new j;
	
	switch( x )
	{
		case 0: j = 24;
		
		case 1: j = 23;
		
		case 2: j = 22;
		
		case 3: j = 21;
		
		case 4: j = 20;
		
		case 5: j = 19;
		
		case 6: j = 18;
		
		case 7: j = 17; 
		
		case 8: j = 16;
		
		case 9: j = 15;
		
		case 10: j = 14;
		
		case 11: j = 13;
		
		case 12: j = 12;
		
		case 13: j = 11;
		
		case 14: j = 10;
		
		case 15: j = 9;
		
		case 16: j = 8;
		
		case 17: j = 7;
		
		case 18: j = 6;
		
		case 19: j = 5;
		
		case 20: j = 4;
		
		case 21: j = 3;
		
		case 22: j = 2;
		
		case 23: j = 1;
	}
	
	if( x < vip_time[ 1 ] )
	j = 0;
	
	return j;
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
