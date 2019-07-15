#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <biohazard>

#define		VIP_FLAGS	"bit"
#define		is_vip(%0)	(get_user_flags(%0)&read_flags(VIP_FLAGS))

#define		ORA_INCEPERE_FREE_VIP	20
#define		ORA_INCHEIERE_FREE_VIP	10

#define		VIP		( 1 << 2 )
#define		DEAD	( 1 << 0 )

new const MODEL_VIP[] = "vip"


new jumpznum[33]=0,bool:dozjump[33]=false,bool:a_ales[33],bool:vip_free


// weapons offsets
#define OFFSET_CLIPAMMO        51
#define OFFSET_LINUX_WEAPONS    4
#define fm_cs_set_weapon_ammo(%1,%2)    set_pdata_int(%1, OFFSET_CLIPAMMO, %2, OFFSET_LINUX_WEAPONS)

// players offsets
#define m_pActiveItem 373

const NOCLIP_WPN_BS    = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))

new const g_MaxClipAmmo[] = 
{
    0,
    13, //CSW_P228
    0,
    10, //CSW_SCOUT
    0,  //CSW_HEGRENADE
    7,  //CSW_XM1014
    0,  //CSW_C4
    30,//CSW_MAC10
    30, //CSW_AUG
    0,  //CSW_SMOKEGRENADE
    15,//CSW_ELITE
    20,//CSW_FIVESEVEN
    25,//CSW_UMP45
    30, //CSW_SG550
    35, //CSW_GALIL
    25, //CSW_FAMAS
    12,//CSW_USP
    20,//CSW_GLOCK18
    10, //CSW_AWP
    30,//CSW_MP5NAVY
    100,//CSW_M249
    8,  //CSW_M3
    30, //CSW_M4A1
    30,//CSW_TMP
    20, //CSW_G3SG1
    0,  //CSW_FLASHBANG
    7,  //CSW_DEAGLE
    30, //CSW_SG552
    30, //CSW_AK47
    0,  //CSW_KNIFE
    50//CSW_P90
}
new bool:ginf[33]


const WEAPONS_BITSUM = ( 1 << CSW_KNIFE | 1 << CSW_HEGRENADE | 1 << CSW_FLASHBANG | 1 << CSW_SMOKEGRENADE | 1 << CSW_C4 );
new Float:cl_pushangle[ 33 ][ 3 ],bool:nrecoil[33]

new bool:ddmg[33]

//--| Teleport |--//
new TeleportSprite, TeleportSprite2,Teleport_Cooldown[ 33 ],CvarTeleportCooldown, CvarTeleportRange,bool:g_bUserHasTEL[33]
new const SOUND_BLINK[ ] = { "weapons/flashbang-1.wav" };

public plugin_precache()
{
	precache_sound( SOUND_BLINK );

	TeleportSprite = precache_model( "sprites/shockwave.spr" );
	TeleportSprite2 = precache_model( "sprites/blueflare2.spr" );

	new szBuffer[ 100 ] ;
	for(new i;i<sizeof(MODEL_VIP);i++)
	{
        format( szBuffer, charsmax( szBuffer ), "models/player/%s/%s.mdl", MODEL_VIP, MODEL_VIP ) ;
        precache_model( szBuffer ) ;
	}
}

public plugin_init() {
	register_message( get_user_msgid( "ScoreAttrib" ), "MessageScoreAttrib" );
	
	register_cvar("vip_jumps","1")//1+aia default=2
	
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")
	register_event("CurWeapon" , "Event_CurWeapon" , "be" , "1=1" );
	
	check_time()
	set_task(60.0, "check_time", _, _, _, "b")

	RegisterHam( Ham_Spawn, "player", "fwPlayerSpawn", 1 )
	RegisterHam( Ham_TakeDamage, "player", "TakeDamage", 1 );
	new weapon_name[ 24 ];
	for( new i = 1; i <= 30; i++ )
	{
		if( !( WEAPONS_BITSUM & 1 << i ) && get_weaponname( i, weapon_name, 23 ) )
		{
			RegisterHam( Ham_Weapon_PrimaryAttack, weapon_name, "fw_Weapon_PrimaryAttack_Pre" );
			RegisterHam( Ham_Weapon_PrimaryAttack, weapon_name, "fw_Weapon_PrimaryAttack_Post", 1 );
		}
	}

	register_clcmd( "power", "Power" );
	CvarTeleportCooldown = register_cvar( "vip_teleport_cooldown", "15" );	// Teleport Cooldown
	CvarTeleportRange = register_cvar( "vip_teleport_range", "12345" );		// Teleport Range
}

public check_time()
{
	static preluare_ora[3], ora;
	get_time("%H", preluare_ora, 2)
	ora = str_to_num(preluare_ora)
	if(ORA_INCEPERE_FREE_VIP <= ora || ora < ORA_INCHEIERE_FREE_VIP)
	{
		if(!vip_free)
		{
			print_cc(0, "^1Eventul^3 Free VIP^1 a fost activat!")
			vip_free = true
			server_cmd("amx_default_access %s",VIP_FLAGS)
		}
	}
	else
	{
		if(vip_free)
		{
			print_cc(0, "^1Eventul^3 Free VIP^1 a fost dezactivat!")
			vip_free = false
			server_cmd("amx_default_access z")
			server_cmd("amx_reloadadmins")
		}
	}
}

public client_putinserver(id)	reset_vals(id)

reset_vals(id)
{
	if(!is_vip(id))	return

	Teleport_Cooldown[id]=0
	jumpznum[id] = 0
	dozjump[id] = false
	ddmg[id]=false
	ginf[id]=false
	nrecoil[id]=false
	g_bUserHasTEL[id]=false
}

public client_PreThink(id)
{
	if(!is_user_alive(id) || !is_vip(id))	return PLUGIN_CONTINUE
		 
	new nzbut = get_user_button(id),ozbut = get_user_oldbutton(id)
	if((nzbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(ozbut & IN_JUMP))
	{
		if (jumpznum[id] < get_cvar_num("vip_jumps"))
		{
			dozjump[id] = true
			jumpznum[id]++
			return PLUGIN_CONTINUE
		}
	}
	if((nzbut & IN_JUMP) && (get_entity_flags(id) & FL_ONGROUND))
	{
		jumpznum[id] = 0
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}
public client_PostThink(id)
{
	if(!is_user_alive(id)||!is_vip(id))	return PLUGIN_CONTINUE

	if(dozjump[id] == true)
	{
		new Float:vezlocityz[3]    
		entity_get_vector(id,EV_VEC_velocity,vezlocityz)
		vezlocityz[2] = random_float(265.0,285.0)
		entity_set_vector(id,EV_VEC_velocity,vezlocityz)
		dozjump[id] = false
		return PLUGIN_CONTINUE
	}    
	return PLUGIN_CONTINUE
}

public event_new_round()	for(new id = 1 ; id <= get_maxplayers() ; id++)	if(is_user_connected(id)&&is_vip(id))	a_ales[id]=false

public MessageScoreAttrib( iMsgID, iDest, iReceiver ) {
   new id = get_msg_arg_int( 1 );
   
   if(is_user_connected( id ) && is_vip(id) )	set_msg_arg_int( 2, ARG_BYTE, is_user_alive( id ) ? VIP : DEAD );
}

public fwPlayerSpawn(id)
{
	if(is_user_alive(id)&&is_vip(id)&&!is_user_zombie(id))
	{
		cs_set_user_armor( id, 100, CS_ARMOR_VESTHELM );//kevlar?xd
		set_task(3.5,"RESET_MODEL",id)
	}

	reset_vals(id)
}
public RESET_MODEL(id)	cs_set_user_model(id,MODEL_VIP)

public client_command(id)
{
	new cmd[32];
	read_argv(0,cmd,charsmax(cmd));
    
	if(equali(cmd,"say")||equali(cmd,"say_team")){
		read_argv(1,cmd,charsmax(cmd));
		trim(cmd);
		if(contain(cmd," ")>-1)	return PLUGIN_CONTINUE;
		if(equali(cmd,"/vips")/*!=-1*/)	print_adminlist(id)
		if(equali(cmd,"/vip"))	show_motd(id,"addons/amxmodx/configs/vip.html","PRETURI VIP")
		if(equali(cmd,"/vm")||equali(cmd,"/vmenu"))
		{
			if(is_vip(id))
			{
					if(!a_ales[id])	MENU_VIP(id)
					else	print_cc(id, "^4AI ALES DEJA^3 RUNDA^1 ASTA")
			}
			else	print_cc(id, "^4NU ESTI^3 VIP")
		}
	}
	return PLUGIN_CONTINUE
}
public print_adminlist(user) 
{
	new adminnames[33][32],message[256],id, count, x, len
	for(id = 1 ; id <= get_maxplayers() ; id++)	if(is_user_connected(id)&&is_vip(id))	get_user_name(id, adminnames[count++], 31)
	len = format(message, 255, "^4VIP ONLINE: ")
	if(count > 0) {
		for(x = 0 ; x < count ; x++) {
			len += format(message[len], 255-len, "%s%s", adminnames[x], x < (count-1) ? ", ":"")
			if(len > 96 ) {
				print_cc(user, message)
				len = format(message, 255, "")
			}
		}
		print_cc(user, message)
	}
	else {
		len += format(message[len], 255-len, "^1No VIP online.")
		print_cc(user, message)
	}
}

public MENU_VIP(id)
{
	if(is_user_zombie(id))	return

	new menu=menu_create("SPECIAL MENU","vmenu")

	menu_additem(menu,"X2 DMG","")
	menu_additem(menu,"15S TELEPORT","")
	menu_additem(menu,"INFINITE BULLETS","")
	menu_additem(menu,"NO RECOIL","")

	menu_setprop( menu, MPROP_EXIT, MEXIT_ALL );
	menu_display( id, menu );
}
public vmenu( id, menu, item )
{
    switch( item )
    {
        case 0:
        {
			if(ddmg[id])
			{
				print_cc(id,"^1AI DEJA ASTA")
				return
			}

			print_cc(id, "^1AI ALES CU SUCCES^3 DAMAGE DUBLU")
			ddmg[id]=true
			a_ales[id]=true
        }
        case 1:
        {
			if(g_bUserHasTEL[id])
			{
				print_cc(id,"^1AI DEJA ASTA")
				return
			}

			print_cc(id, "^1AI ALES CU SUCCES^3 TELEPORT")
			g_bUserHasTEL[id]=true
			a_ales[id]=true

			print_cc(id, "^1Power:^x03 Teleport.^x04 Cooldown:^x03 %dS", get_pcvar_num( CvarTeleportCooldown ) );
			print_cc(id, "^1Pentru a folosi^x03 Teleport^x04 seteaza in consola:^x03 bind t power" );

			if( Teleport_Cooldown[ id ] )	TeleportShowHUD( id );
        }
		case 2:
		{
			if(ginf[id])
			{
				print_cc(id,"^1AI DEJA ASTA")
				return
			}

			print_cc(id, "^1AI ALES CU SUCCES^3 GLOANTE INFINITE")
			ginf[id]=true
			a_ales[id]=true
		}
        case 3:
        {
			if(nrecoil[id])
			{
				print_cc(id,"^1AI DEJA ASTA")
				return
			}

			print_cc(id, "^1AI ALES CU SUCCES^3 NO-RECOIL")
			nrecoil[id]=true
			a_ales[id]=true
        }
    }

    menu_destroy(menu)
}
public Event_CurWeapon( id )
{
    new iWeapon = read_data(2)
    if( !( NOCLIP_WPN_BS & (1<<iWeapon) )&&ginf[id] )	fm_cs_set_weapon_ammo( get_pdata_cbase(id, m_pActiveItem) , g_MaxClipAmmo[ iWeapon ] )
}
public fw_Weapon_PrimaryAttack_Pre( entity )
{
	if( !pev_valid( entity ) )	return HAM_IGNORED;

	new id = pev( entity, pev_owner );
	if( is_user_alive( id ) && nrecoil[ id ] )
	{
		pev( id, pev_punchangle, cl_pushangle[ id ] );

		return HAM_IGNORED;
	}
	return HAM_IGNORED;
}
public fw_Weapon_PrimaryAttack_Post( entity )
{
	if( !pev_valid( entity ) )	return HAM_IGNORED;

	new id = pev( entity, pev_owner );
	if( is_user_alive( id ) && nrecoil[ id ] )
	{
		new Float: push[ 3 ];
		pev( id, pev_punchangle, push );

		xs_vec_sub( push, cl_pushangle[ id ], push );
		xs_vec_mul_scalar( push, 0.0, push );
		xs_vec_add( push, cl_pushangle[ id ], push );

		set_pev( id, pev_punchangle, push );

		return HAM_IGNORED;
	}
	return HAM_IGNORED;
}
public TakeDamage( victim, inflictor, attacker, Float:damage, damagebit )
{
	if( !is_user_alive( attacker ) || is_user_bot( attacker ) || !is_user_alive( victim ) || is_user_bot( victim ) )	return HAM_IGNORED;

	if( ddmg[attacker] )	SetHamParamFloat( 4, damage*2 );//xd

	return HAM_IGNORED;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Teleport |
//==========================================================================================================
public TeleportShowHUD( id )
{
	if( !is_user_alive( id ) || !g_bUserHasTEL[ id ] )
	{
		remove_task( id );
		Teleport_Cooldown[ id ] = 0;
		return PLUGIN_HANDLED;
	}
	set_hudmessage( 0, 100, 200, 0.05, 0.60, 0, 1.0, 1.1, 0.0, 0.0, -11/* 1*/ );
	if( Teleport_Cooldown[ id ] > 0 )
	{
		Teleport_Cooldown[ id ] --;
		show_hudmessage( id, "Puterea TELEPORT iti va reveni in: %d secund%s", Teleport_Cooldown[ id ], Teleport_Cooldown[ id ] == 1 ? "a" : "e" );
		return PLUGIN_HANDLED
	}
	else if( Teleport_Cooldown[ id ] <= 0 )
	{
		set_hudmessage( 0, 100, 200, 0.05, 0.58, 0, 1.0, 1.1, 0.0, 0.0, -11 /*1*/ );
		show_hudmessage( id, "Ti-a revenit puterea TELEPORT" );
		print_cc( id, "^1Iti poti folosi din nou puterea:^x03 TELEPORT" );
		remove_task( id );
		Teleport_Cooldown[ id ] = 0;
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED;
}
bool:teleport( id )
{
	new Float:vOrigin[ 3 ], Float:vNewOrigin[ 3 ],
	Float:vNormal[ 3 ], Float:vTraceDirection[ 3 ],
	Float:vTraceEnd[ 3 ];
	pev( id, pev_origin, vOrigin );
	velocity_by_aim( id, get_pcvar_num( CvarTeleportRange ), vTraceDirection );
	xs_vec_add( vTraceDirection, vOrigin, vTraceEnd );
	engfunc( EngFunc_TraceLine, vOrigin, vTraceEnd, DONT_IGNORE_MONSTERS, id, 0 );

	new Float:flFraction;
	get_tr2( 0, TR_flFraction, flFraction );
	if( flFraction < 1.0 )
	{
		get_tr2( 0, TR_vecEndPos, vTraceEnd );
		get_tr2( 0, TR_vecPlaneNormal, vNormal );
	}

	xs_vec_mul_scalar( vNormal, 40.0, vNormal ); // do not decrease the 40.0
	xs_vec_add( vTraceEnd, vNormal, vNewOrigin );

	if( is_player_stuck( id, vNewOrigin ) )	return false;

	emit_sound( id, CHAN_STATIC, SOUND_BLINK, 1.0, ATTN_NORM, 0, PITCH_NORM );
	tele_effect( vOrigin );

	engfunc( EngFunc_SetOrigin, id, vNewOrigin );
	tele_effect2( vNewOrigin );

	return true;
}
stock is_player_stuck( id, Float:originF[ 3 ] )
{
	engfunc( EngFunc_TraceHull, originF, originF, 0, ( pev( id, pev_flags ) & FL_DUCKING ) ? HULL_HEAD : HULL_HUMAN, id, 0 );
	if( get_tr2( 0, TR_StartSolid ) || get_tr2( 0, TR_AllSolid ) || !get_tr2( 0, TR_InOpen ) )	return true;

	return false;
}
stock tele_effect( const Float:torigin[ 3 ] )
{
	new origin[ 3 ];
	origin[ 0 ] = floatround( torigin[ 0 ] );
	origin[ 1 ] = floatround( torigin[ 1 ] );
	origin[ 2 ] = floatround( torigin[ 2 ] );

	message_begin( MSG_PAS, SVC_TEMPENTITY, origin );
	write_byte( TE_BEAMCYLINDER );
	write_coord( origin[ 0 ] );
	write_coord( origin[ 1 ] );
	write_coord( origin[ 2 ] + 10 );
	write_coord( origin[ 0 ] );
	write_coord( origin[ 1 ] );
	write_coord( origin[ 2 ] + 60 );
	write_short( TeleportSprite );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 3 );
	write_byte( 60 );
	write_byte( 0 );
	write_byte( 255 );
	write_byte( 255 );
	write_byte( 255 );
	write_byte( 255 );
	write_byte( 0 );
	message_end( );
}
stock tele_effect2( const Float:torigin[ 3 ] )
{
	new origin[ 3 ];
	origin[ 0 ] = floatround( torigin[ 0 ] );
	origin[ 1 ] = floatround( torigin[ 1 ] );
	origin[ 2 ] = floatround( torigin[ 2 ] );

	message_begin( MSG_PAS, SVC_TEMPENTITY, origin );
	write_byte( TE_BEAMCYLINDER );
	write_coord( origin[ 0 ] );
	write_coord( origin[ 1 ] );
	write_coord( origin[ 2 ] + 10 );
	write_coord( origin[ 0 ] );
	write_coord( origin[ 1 ] );
	write_coord( origin[ 2 ] + 60 );
	write_short( TeleportSprite );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 3 );
	write_byte( 60 );
	write_byte( 0 );
	write_byte( 255 );
	write_byte( 255 );
	write_byte( 255 );
	write_byte( 255 );
	write_byte( 0 );
	message_end( );

	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_SPRITETRAIL );
	write_coord( origin[ 0 ] );
	write_coord( origin[ 1 ] );
	write_coord( origin[ 2 ] + 40 );
	write_coord( origin[ 0 ] );
	write_coord( origin[ 1 ] );
	write_coord( origin[ 2 ] );
	write_short( TeleportSprite2 );
	write_byte( 30 );
	write_byte( 10 );
	write_byte( 1 );
	write_byte( 50 );
	write_byte( 10 );
	message_end( );
}

//------| Client Power |------//
public Power( id )
{
	if( !is_user_alive( id ) )
	{
		print_cc( id, "^1Trebuie sa fii in^03 VIATA^x01 pentru a folosi^x04 PUTEREA^x01 !" );
		return PLUGIN_HANDLED;
	}

	if( !g_bUserHasTEL[ id ] )
	{
		print_cc( id, "^1Nu ai ales puterea de^x03 TELEPORT^x01 !" );
		return PLUGIN_HANDLED;
	}

	if( Teleport_Cooldown[ id ] )
	{
		print_cc( id, "^1Puterea^x03 TELEPORT^x01 iti va reveni in^x04 %dS", Teleport_Cooldown[ id ] );
		return PLUGIN_CONTINUE;
	}

	if( teleport( id ) )
	{
		emit_sound( id, CHAN_STATIC, SOUND_BLINK, 1.0, ATTN_NORM, 0, PITCH_NORM );
		remove_task( id );
		Teleport_Cooldown[ id ] = get_pcvar_num( CvarTeleportCooldown );//crap
		set_task( 1.0, "TeleportShowHUD", id, _, _, "b" );
		if( get_pcvar_num( CvarTeleportCooldown ) > 0 )
		{
			set_hudmessage( 0, 100, 200, 0.05, 0.60, 0, 1.0, 1.1, 0.0, 0.0, -1 /*1*/ );
			show_hudmessage( id, "Puterea TELEPORT iti va reveni in: %d secund%s", get_pcvar_num( CvarTeleportCooldown ),get_pcvar_num( CvarTeleportCooldown )==1?"a":"e" );
		}
		return PLUGIN_HANDLED;
	}
	else
	{
		Teleport_Cooldown[ id ] = 0;//mda
		print_cc( id, "^1Pozitia de^x03 Teleportare^x01 este^x04 Invalida^x01 !" );
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}


print_cc(id, fmt[], any:...)
{
	static saytext = 0, fake_user;
	if (!saytext)
	{
		saytext = get_user_msgid("SayText");
		fake_user = get_maxplayers() + 1;
	}
	new msg[192];
	vformat(msg, charsmax(msg), fmt, 3)
	replace_all(msg, sizeof(msg) - 1, "!g", "^x04");
	replace_all(msg, sizeof(msg) - 1, "!n", "^x01");
	replace_all(msg, sizeof(msg) - 1, "!t", "^x03");
	message_begin(id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, saytext, _, id);
	write_byte(id ? id : fake_user);
	write_string(msg);
	message_end();
}
