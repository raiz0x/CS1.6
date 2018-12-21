	#include <amxmodx>
	#include <amxmisc>
	#include <cstrike>
	#include <fakemeta>
	#include <nvault>
	#include <colorchat>

	#define VAULTNAME "XPVAULT"
	#define KILLXP 100
	#define HSXP 200
	#define LEVELUPXP 400
	#define SKINLEVELCHANGE 30
	#define PLUG_TAG "HATS"

	stock fm_set_entity_visibility(index, visible = 1) set_pev(index, pev_effects, visible == 1 ? pev(index, pev_effects) & ~EF_NODRAW : pev(index, pev_effects) | EF_NODRAW)

	new g_HatEnt[33],xpplayer[ 33 ],setting[ 33 ],menuCB;


	#define MAXLEVEL 19//0|1 -def/none
	new const skinNames[ MAXLEVEL ][128] =
	{
		"Default skin",//lv 0sau1 gen
		"[angel2] lvl 30",
		"[afro] lvl 60",
		"[arrow] lvl 90",
		"[asswp] lvl 120",
		"[awesome] lvl 150",
		"[barrel] lvl 180",
		"[beerhat] lvl 210",
		"[bighead] lvl 240",
		"[bobafett] lvl 270",
		"[bow] lvl 300",
		"[bucket] lvl 330",
		"[camper] lvl 360",
		"[cashield] lvl 390",
		"[cheesehead] lvl 420",
		"[clocknecklace] lvl 450",
		"[clonetrooper] lvl 480",
		"[clonetrooper_big] lvl 510",
		"[cross] lvl 540"
	};
	new const HatsLevels[MAXLEVEL] =//NEFOLOSIT MOMENTAN
	{
		0,
		30,
		60,
		90,
		120,
		150,
		180,
		210,
		240,
		270,
		300,
		330,
		360,
		390,
		420,
		450,
		480,
		510,
		540
	};
	new const Vnames[ MAXLEVEL ][ ] =
	{
		"",//DEFAULT HAT/NONE/0  (model vizibil....)
		"models/hat/afro.mdl",
		"models/hat/angel2.mdl",
		"models/hat/arrow.mdl",
		"models/hat/asswp.mdl",
		"models/hat/awesome.mdl",
		"models/hat/barrel.mdl",
		"models/hat/beerhat.mdl",
		"models/hat/bighead.mdl",
		"models/hat/bobafett.mdl",
		"models/hat/bow.mdl",
		"models/hat/bucket.mdl",
		"models/hat/camper.mdl",
		"models/hat/cashield.mdl",
		"models/hat/cheesehead.mdl",
		"models/hat/clocknecklace.mdl",
		"models/hat/clonetrooper.mdl",
		"models/hat/clonetrooper_big.mdl",
		"models/hat/cross.mdl"
	};


	static szChat[ 192 ],szName[ 32 ];

	new szFile[ 128 ];
	new PlayerTag[ 33 ][ 32 ];
	new bool: PlayerHasTag[ 33 ];


	public plugin_init()//fix by Adryyy
	{
		register_event("DeathMsg", "hook_death", "a"/*, "1>0"*/);

		menuCB = menu_makecallback( "menucallback1" );

		register_clcmd( "say /hat", "SkinSelect" );
		register_clcmd( "say /hats", "SkinSelect" );
		register_clcmd( "say_team /hat", "SkinSelect" );
		register_clcmd( "say_team /hats", "SkinSelect" );
		
		register_clcmd( "say /level", "CmdGetLevel" );
		register_clcmd( "say_team /level", "CmdGetLevel" );

		register_clcmd( "say /xp", "ShowDetails" );
		register_clcmd( "say_team /xp", "ShowDetails" );

		register_clcmd( "amx_sethatslevel", "SetLevel", ADMIN_RCON, "<tinta> <valoare>" );
		register_clcmd( "amx_sethatsxp", "SetXP", ADMIN_RCON, "<tinta> <valoare>" );


		register_clcmd ("say", "hook_say")
		register_clcmd ("say_team", "hook_teamsay")


		register_concmd( "amx_reloadhatstag", "ClCmdReloadTags", -1 );
	}

	public plugin_precache()
	{
		get_configsdir( szFile, sizeof ( szFile ) -1 );
		formatex( szFile, sizeof ( szFile ) -1, "%s/PlayerTags.ini", szFile );

		if( !file_exists( szFile ) ) 
		{
		write_file( szFile, ";Aici treceti tag-urile jucatorilor !", -1 );
		write_file( szFile, ";ex: ^"Nume Player^" ^"Ip Player^" ^"SteamId Player^" ^"Tag Player^" ^"Flage^"", -1 );
		write_file( szFile, ";Numele sa fie exact( ex: Askhanar va fi Askhanar nu askhanar ! ) ", -1 );
		}

		for( new i; i < sizeof Vnames; i++ )	if( !equal( Vnames[ i ], "" ) )	precache_model( Vnames[ i ] );
	}

	public client_putinserver( id )
	{
		if(is_user_connected(id)&&!is_user_bot(id))
		{
		xpplayer[ id ] = 0;
		setting[ id ] = 0;//def hat
	   
		new vault = nvault_open( VAULTNAME );
		new name[ 50 ], useless;
		get_user_name( id, name, 49 );
		new showSz[ 50 ];
		nvault_lookup( vault, name, showSz, 49, useless );
		xpplayer[ id ] = str_to_num( showSz );
		nvault_close( vault );


		PlayerHasTag[ id ] = false;
		LoadPlayerTag( id );
		}
	}

	public client_disconnect( id )
	{
		if(!is_user_bot(id))
		{
		new vault = nvault_open( VAULTNAME );
		new name[ 50 ];
		get_user_name( id, name, 49 );
		new showSz[ 50 ];
		num_to_str( xpplayer[ id ], showSz, 49 );
		nvault_set( vault, name, showSz );
		nvault_close( vault );
		xpplayer[ id ] = 0;
		setting[ id ] = 0;
		}
	}
	 
	public hook_death()
	{
		new Killer = read_data( 1 );
		new Victim = read_data( 2 );
		new headshot = read_data( 3 );
	   
		if( is_user_connected(Killer)&&Killer != Victim )
		{
			if( headshot )	xpplayer[ Killer ] += HSXP;
			else	xpplayer[ Killer ] += KILLXP;
			   
			new level = xpplayer[ Killer ] / LEVELUPXP;
			client_print( Killer, print_center, "%s XP %i / %i",PLUG_TAG, xpplayer[ Killer ], LEVELUPXP * ( level + 1 ) );
		}
	}

	public CmdGetLevel( player )
	{
		new message[ 1000 ];
		new level = xpplayer[ player ] / LEVELUPXP;
		
		format( message, 999, "[Hat : %s]<br>[Level : %i]<br>[Experience : %i / %i]<br>[Ordinary : %i]<br>[%i kills for new level]", skinNames[ setting[ player ] ], level, xpplayer[ player ], LEVELUPXP * ( level + 1 ), level / SKINLEVELCHANGE + 1, ( LEVELUPXP * ( level + 1 ) - xpplayer[ player ] ) / KILLXP );
		show_motd( player, message );
	}

	public SetLevel( id, level, cid )
	{
		if (!cmd_access(id,level,cid,2))	return PLUGIN_HANDLED
		   
		new name[ 50 ];
		read_argv( 1, name, 49 );
		new valSz[ 50 ], val;
		read_argv( 2, valSz, 49 );
		val = str_to_num( valSz );

		if(equali(name,"")||equali(valSz,""))	return PLUGIN_HANDLED
		if(val<=0)	return PLUGIN_HANDLED
	   
		new user = cmd_target( id, name, CMDTARGET_NO_BOTS );

		if(!user)	return PLUGIN_HANDLED

		xpplayer[ user ] = val * 400;
	   
		return PLUGIN_HANDLED;
	}
	public SetXP( id, level, cid )
	{
		if (!cmd_access(id,level,cid,2))	return PLUGIN_HANDLED
		   
		new name[ 50 ];
		read_argv( 1, name, 49 );
		new valSz[ 50 ], val;
		read_argv( 2, valSz, 49 );
		val = str_to_num( valSz );

		if(equali(name,"")||equali(valSz,""))	return PLUGIN_HANDLED
		if(val<=0)	return PLUGIN_HANDLED
	   
		new user = cmd_target( id, name, CMDTARGET_NO_BOTS );

		if(!user)	return PLUGIN_HANDLED

		xpplayer[ user ] += val
	   
		return PLUGIN_HANDLED;
	}
	 
	public ShowDetails(id)
	{
		new level = xpplayer[ id ] / LEVELUPXP;
		client_print(id,print_chat,"%s [Hat : %s][Level: %i][Experience: %i/%i][Ordinary: %i][%i kills for new level]",PLUG_TAG, skinNames[ setting[ id ] ], level, xpplayer[ id ], LEVELUPXP * ( level + 1 ), level / SKINLEVELCHANGE + 1, ( LEVELUPXP * ( level + 1 ) - xpplayer[ id ] ) / KILLXP)
	}
	   
	public SkinSelect( id )
	{
		new menu = menu_create( "Choose your hat skin", "menuhandler1" );
		//new level = xpplayer[ id ] / LEVELUPXP;
	   
		for( new i=0; i < sizeof skinNames; i++ )
		{
	/*
			for(new x;x<sizeof HatsLevels;x++)
			{
				menu_additem( menu, skinNames[ i ], _, level>=HatsLevels[x], menuCB );
			}
	*/
			menu_additem( menu, skinNames[ i ], _, _, menuCB );
		}
	   
		menu_display( id, menu);
	}
	public menuhandler1( id, menu, item )
	{
		if(item == MENU_EXIT)
		{
			menu_destroy(menu)
			return PLUGIN_HANDLED
		}

		if(item == setting[id])
		{
			client_print(id,print_chat, "%s You already have: %s",PLUG_TAG, skinNames[item]);
			menu_destroy(menu)
			return PLUGIN_HANDLED
		}

		Set_Hat( id, item );
		client_print(id,print_chat, "%s The hat you chose is: %s",PLUG_TAG, skinNames[item]);
		menu_destroy(menu);

		return PLUGIN_HANDLED
	}
	public menucallback1( id, menu, item )
	{
		static szInfo[8], iAccess, iCallback;
		menu_item_getinfo(menu, item, iAccess, szInfo, charsmax(szInfo), .callback = iCallback);
		static iType;
		iType = str_to_num(szInfo);
		new level = xpplayer[ id ] / LEVELUPXP;
		if( item > level / SKINLEVELCHANGE/*||item == setting[id]*/ )	return ITEM_DISABLED;
	   
		return ITEM_ENABLED;//IGNORED
	}
	public Set_Hat(player, imodelnum)
	{
		if(!is_user_alive(player)||get_user_team(player)==3)	return PLUGIN_HANDLED
		setting[ player ] = imodelnum;

		if(g_HatEnt[player] < 1) {
			g_HatEnt[player] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
			if(g_HatEnt[player] > 0) {
				set_pev(g_HatEnt[player], pev_movetype, MOVETYPE_FOLLOW)
				set_pev(g_HatEnt[player], pev_aiment, player)
				if(setting[player]==0)	fm_set_entity_visibility(g_HatEnt[player],0)
				else
				{
					set_pev(g_HatEnt[player], pev_rendermode, kRenderNormal)
					engfunc(EngFunc_SetModel, g_HatEnt[player], Vnames[imodelnum])
				}
			}
		}
		else
		{
			if(setting[player]==0)	fm_set_entity_visibility(g_HatEnt[player],0)
			else
			{
				fm_set_entity_visibility(g_HatEnt[player],1)
				engfunc(EngFunc_SetModel, g_HatEnt[player], Vnames[imodelnum])
			}
		}

		return PLUGIN_HANDLED
	}



	public ClCmdReloadTags( id )
	{
	if( !( get_user_flags( id ) & ADMIN_KICK ) )
	{
		client_cmd( id, "echo Nu ai acces la aceasta comanda !");
		return 1;
	}

	new iPlayers[ 32 ];
	new iPlayersNum;

	get_players( iPlayers, iPlayersNum, "c" );		
	for( new i = 0 ; i < iPlayersNum ; i++ )
	{
		PlayerHasTag[ iPlayers[ i ] ] = false;
		LoadPlayerTag( iPlayers[ i ] );
	}

	client_cmd( id, "echo Tag-urile jucatorilor au fost incarcate cu succes !");
	return 1;
	}
	public LoadPlayerTag( id )
	{
	PlayerHasTag[ id ] = false;

	if( !file_exists( szFile ) ) 
	{
		write_file( szFile, ";Aici treceti tag-urile jucatorilor !", -1 );
		write_file( szFile, ";ex: ^"Nume Player^" ^"Ip Player^" ^"SteamId Player^" ^"Tag Player^" ^"Flage^"", -1 );
		write_file( szFile, ";Numele sa fie exact( ex: Askhanar va fi Askhanar nu askhanar ! ) ", -1 );
	}

	new f = fopen( szFile, "rt" );
	if( !f ) return 0;
	new data[ 512 ], buffer[ 5 ][ 32 ] ;
	while( !feof( f ) ) 
	{
		fgets( f, data, sizeof ( data ) -1 );
		if( !data[ 0 ] || data[ 0 ] == ';' || ( data[ 0 ] == '/' && data[ 1 ] == '/' ) ) 	continue;
		parse(data,\
			buffer[ 0 ], sizeof ( buffer[ ] ) - 1,\
			buffer[ 1 ], sizeof ( buffer[ ] ) - 1,\
			buffer[ 2 ], sizeof ( buffer[ ] ) - 1,\
			buffer[ 3 ], sizeof ( buffer[ ] ) - 1,\
			buffer[ 4 ], sizeof ( buffer[ ] ) - 1
		);
		
		new name[ 32 ], ip[ 32 ], authid[65];
		get_user_name( id, name, sizeof ( name ) -1 );
		get_user_ip( id, ip, sizeof ( ip ) -1, 1 );
		get_user_authid( id, authid, sizeof ( authid ) -1 );
		if( equal( name, buffer[ 0 ] ) || equal( ip, buffer[ 1 ] )|| equal( authid, buffer[ 2 ] )||get_user_flags(id)==read_flags(buffer[ 4 ]) )
		{
			PlayerHasTag[ id ] = true;
			copy( PlayerTag[ id ], sizeof ( PlayerTag[ ] ) -1, buffer[ 3 ] );
			break;
		}
	}

	return 0;
	}
	public hook_say(id)
	{
	if( is_user_bot( id )||!is_user_connected(id) )	return PLUGIN_CONTINUE;
	read_args( szChat, sizeof( szChat ) - 1 );
	remove_quotes( szChat );
	if( equali( szChat,"" ) )	return PLUGIN_CONTINUE;
	get_user_name( id, szName, sizeof ( szName ) -1 );

	new level = xpplayer[ id ] / LEVELUPXP;

	if( PlayerHasTag[ id ] )
	{
			switch( cs_get_user_team( id ) )
			{
				case CS_TEAM_T:		ColorChat( 0, RED,"^1%s[Level:^4 %d^1]^3 *^4%s^3* %s^1: %s", is_user_alive( id ) ? "" : "*DEAD* ",level,PlayerTag[ id ], szName, szChat );
				case CS_TEAM_CT:	ColorChat( 0, BLUE,"^1%s[Level:^4 %d^1]^3 *^4%s^3* %s^1: %s", is_user_alive( id ) ? "" : "*DEAD* ",level,PlayerTag[ id ], szName, szChat );
				case CS_TEAM_SPECTATOR:	ColorChat( 0, GREY,"^1*SPEC* [Level:^4 %d^1]^3 *^4%s^3* %s^1: %s",level,PlayerTag[ id ], szName, szChat );
			}
	}
	else if( !PlayerHasTag[ id ] )
	{
			switch( cs_get_user_team( id ) )
			{
				case CS_TEAM_T:		ColorChat( 0, RED,"^1%s[Level:^4 %d^1]^3 %s^1: %s", is_user_alive( id ) ? "" : "*DEAD* ",level,szName, szChat );
				case CS_TEAM_CT:	ColorChat( 0, BLUE,"^1%s[Level:^4 %d^1]^3 %s^1: %s", is_user_alive( id ) ? "" : "*DEAD* ",level,szName, szChat );
				case CS_TEAM_SPECTATOR:	ColorChat( 0, GREY,"^1*SPEC* [Level:^4 %d^1]^3 %s^1: %s",level,szName, szChat );
			}
	}

	return PLUGIN_HANDLED_MAIN
	}
	public hook_teamsay(id) {
	if( is_user_bot( id )||!is_user_connected(id) )	return PLUGIN_CONTINUE;
	read_args( szChat, sizeof( szChat ) - 1 );
	remove_quotes( szChat );
	if( equali( szChat,"" ) )	return PLUGIN_CONTINUE;

	static iPlayers[ 32 ], iPlayersNum;
	get_user_name( id, szName, sizeof ( szName ) -1 );
	get_players( iPlayers, iPlayersNum, "ch" );
	if( !iPlayersNum )	return PLUGIN_CONTINUE;
	static iPlayer, i;
	iPlayer = -1; i = 0;
	new level = xpplayer[ id ] / LEVELUPXP;

	for( i = 0; i < iPlayersNum; i++ )
	{
			iPlayer = iPlayers[ i ];

			if( cs_get_user_team( id ) == cs_get_user_team( iPlayer ) && PlayerHasTag[ id ] )
			{
				switch( cs_get_user_team( id ) )
				{
						case CS_TEAM_T:		ColorChat( iPlayer, RED, "^1%s(Terrorist) [Level:^4 %d^1] ^3*^4%s^3* %s^1: %s", is_user_alive( id ) ? "" : "*DEAD* ",level,PlayerTag[ id ], szName, szChat );
						case CS_TEAM_CT:	ColorChat( iPlayer, BLUE, "^1%s(Counter-Terrorist) [Level:^4 %d^1] ^3*^4%s^3* %s^1: %s", is_user_alive( id ) ? "" : "*DEAD* ",level,PlayerTag[ id ], szName, szChat );
						case CS_TEAM_SPECTATOR:	ColorChat( iPlayer, GREY, "^1(Spectator) [Level:^4 %d^1] ^3*^4%s^3*^3 %s^1: %s",level,PlayerTag[ id ], szName, szChat );
				}
			}
			else if( cs_get_user_team( id ) == cs_get_user_team( iPlayer ) && !PlayerHasTag[ id ] )
			{
				switch( cs_get_user_team( id ) )
				{
						case CS_TEAM_T:		ColorChat( iPlayer, RED, "^1%s(Terrorist) [Level:^4 %d^1]^3 %s^1: %s", is_user_alive( id ) ? "" : "*DEAD* ",level, szName, szChat );
						case CS_TEAM_CT:	ColorChat( iPlayer, BLUE, "^1%s(Counter-Terrorist) [Level:^4 %d^1]^3 %s^1: %s", is_user_alive( id ) ? "" : "*DEAD* ",level, szName, szChat );
						case CS_TEAM_SPECTATOR:	ColorChat( iPlayer, GREY, "^1(Spectator) [Level:^4 %d^1]^3 %s^1: %s",level, szName, szChat );
				}
			}
	}

	return PLUGIN_HANDLED_MAIN
	}
