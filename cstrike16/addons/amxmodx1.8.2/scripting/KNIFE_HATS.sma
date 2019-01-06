	#include <amxmodx>
	#include <amxmisc>
	#include <cstrike>
	#include <fakemeta>
	#include <fvault>
	#include <colorchat>

	new const VAULTNAME[]= "XPVAULT"

	#define KILLXP					100
	#define HSXP					200
	#define LEVELUPXP				400
	#define SKINHATSLEVELCHANGE		30
	#define SKINKNIVESLEVELCHANGE	50

	#define PLUG_TAG "SKINS:"//mare parte in chat

	stock fm_set_entity_visibility(index, visible = 1) set_pev(index, pev_effects, visible == 1 ? pev(index, pev_effects) & ~EF_NODRAW : pev(index, pev_effects) | EF_NODRAW)

	new g_HatEnt[33],xpplayer[ 33 ],settingH[ 33 ],settingK[ 33 ],menuCBH,menuCBK,authid[32],data[ 65 ], szXp[ 32 ]


	#define MAXLEVELHATS 38//0|1 -def/none
	new const skinNamesH[ MAXLEVELHATS ][128] =
	{
		"Default skin",//lv 0sau1 gen
		"[Afro] lvl 30",
		"[Angel] lvl 60",
		"[Arrow] lvl 90",
		"[Asswp] lvl 120",
		"[Barrel] lvl 150",
		"[BatMan] lvl 180",
		"[Bighead] lvl 210",
		"[Black Dragon] lvl 240",
		"[Poney Roz] lvl 270",
		"[Poney Albastru] lvl 300",
		"[Sonic Hat] lvl 330",
		"[Cheesehead] lvl 360",
		"[Cow] lvl 390",
		"[CowBoy] lvl 420",
		"[Dar] lvl 450",
		"[Devil] lvl 480",
		"[Cadou] lvl 510",
		"[Elf] lvl 540",
		"[Gladiator] lvl 570",
		"[GooDevil] lvl 600",
		"[Halloween] lvl 630",
		"[Jack Daniel's] lvl 660",
		"[Joker] lvl 690",
		"[KfcBucket] lvl 720",
		"[Miku Head] lvl 750",
		"[Urechi de Iepure] lvl 780",
		"[Shieeld] lvl 810",
		"[Siren Big] lvl 840",
		"[SuperMan] lvl 870",
		"[Urechi de pisica] lvl 900",
		"[Xmas] lvl 930",
		"[YeahBoye] lvl 960",
		"[Party Hat] lvl 990",
		"[Propeller Hat] lvl 1020",
		"[Rice Hat] lvl 1050",
		"[Arc] lvl 1080",
		"[Dildau] lvl 1110"
	};
	new const VnamesH[ MAXLEVELHATS ][ ] =
	{
		"",								//DEFAULT HAT/NONE/0  (model vizibil....)
		"models/hat_knife/afro.mdl",
		"models/hat_knife/angel2.mdl",
		"models/hat_knife/arrow.mdl",
		"models/hat_knife/asswp.mdl",
		"models/hat_knife/barrel.mdl",
		"models/hat_knife/bathat.mdl",
		"models/hat_knife/bighead.mdl",
		"models/hat_knife/black_dragon.mdl",
		"models/hat_knife/c_pony_hat.mdl",
		"models/hat_knife/ponygirlhat.mdl",
		"models/hat_knife/c_sonic_head_v2.mdl",
		"models/hat_knife/cheesehead.mdl",
		"models/hat_knife/cow.mdl",
		"models/hat_knife/cowboy.mdl",
		"models/hat_knife/dar.mdl",
		"models/hat_knife/devil2.mdl",
		"models/hat_knife/dickinabox.mdl",
		"models/hat_knife/elf.mdl",
		"models/hat_knife/gladiatorhat.mdl",
		"models/hat_knife/goodevil.mdl",
		"models/hat_knife/halloween2017.mdl",
		"models/hat_knife/jdshirt.mdl",
		"models/hat_knife/joker.mdl",
		"models/hat_knife/kfcbucket.mdl",
		"models/hat_knife/miku_head.mdl",
		"models/hat_knife/pbbears.mdl",
		"models/hat_knife/shieeldhat.mdl",
		"models/hat_knife/siren_big.mdl",
		"models/hat_knife/supermancape.mdl",
		"models/hat_knife/ua_hats25.mdl",
		"models/hat_knife/xmas_cap.mdl",
		"models/hat_knife/yeahboyehat.mdl",
		"models/hat_knife/Party_Hat.mdl",
		"models/hat_knife/Propeller_Hat.mdl",
		"models/hat_knife/Rice_Hat.mdl",
		"models/hat_knife/bow.mdl",
		"models/hat_knife/dildau.mdl"
	};


	#define MAXLEVELKNIVES 38
	new const skinNamesK[ MAXLEVELKNIVES ][128] =
	{
		"Default skin",
		"[Afro] lvl 30",
		"[Angel] lvl 60",
		"[Arrow] lvl 90",
		"[Asswp] lvl 120",
		"[Barrel] lvl 150",
		"[BatMan] lvl 180",
		"[Bighead] lvl 210",
		"[Black Dragon] lvl 240",
		"[Poney Roz] lvl 270",
		"[Poney Albastru] lvl 300",
		"[Sonic Hat] lvl 330",
		"[Cheesehead] lvl 360",
		"[Cow] lvl 390",
		"[CowBoy] lvl 420",
		"[Dar] lvl 450",
		"[Devil] lvl 480",
		"[Cadou] lvl 510",
		"[Elf] lvl 540",
		"[Gladiator] lvl 570",
		"[GooDevil] lvl 600",
		"[Halloween] lvl 630",
		"[Jack Daniel's] lvl 660",
		"[Joker] lvl 690",
		"[KfcBucket] lvl 720",
		"[Miku Head] lvl 750",
		"[Urechi de Iepure] lvl 780",
		"[Shieeld] lvl 810",
		"[Siren Big] lvl 840",
		"[SuperMan] lvl 870",
		"[Urechi de pisica] lvl 900",
		"[Xmas] lvl 930",
		"[YeahBoye] lvl 960",
		"[Party Hat] lvl 990",
		"[Propeller Hat] lvl 1020",
		"[Rice Hat] lvl 1050",
		"[Arc] lvl 1080",
		"[Dildau] lvl 1110"
	};
	new const VnamesK[ MAXLEVELKNIVES ][ ] =
	{
		"models/v_knife.mdl",
		"models/hat_knife/afro.mdl",
		"models/hat_knife/angel2.mdl",
		"models/hat_knife/arrow.mdl",
		"models/hat_knife/asswp.mdl",
		"models/hat_knife/barrel.mdl",
		"models/hat_knife/bathat.mdl",
		"models/hat_knife/bighead.mdl",
		"models/hat_knife/black_dragon.mdl",
		"models/hat_knife/c_pony_hat.mdl",
		"models/hat_knife/ponygirlhat.mdl",
		"models/hat_knife/c_sonic_head_v2.mdl",
		"models/hat_knife/cheesehead.mdl",
		"models/hat_knife/cow.mdl",
		"models/hat_knife/cowboy.mdl",
		"models/hat_knife/dar.mdl",
		"models/hat_knife/devil2.mdl",
		"models/hat_knife/dickinabox.mdl",
		"models/hat_knife/elf.mdl",
		"models/hat_knife/gladiatorhat.mdl",
		"models/hat_knife/goodevil.mdl",
		"models/hat_knife/halloween2017.mdl",
		"models/hat_knife/jdshirt.mdl",
		"models/hat_knife/joker.mdl",
		"models/hat_knife/kfcbucket.mdl",
		"models/hat_knife/miku_head.mdl",
		"models/hat_knife/pbbears.mdl",
		"models/hat_knife/shieeldhat.mdl",
		"models/hat_knife/siren_big.mdl",
		"models/hat_knife/supermancape.mdl",
		"models/hat_knife/ua_hats25.mdl",
		"models/hat_knife/xmas_cap.mdl",
		"models/hat_knife/yeahboyehat.mdl",
		"models/hat_knife/Party_Hat.mdl",
		"models/hat_knife/Propeller_Hat.mdl",
		"models/hat_knife/Rice_Hat.mdl",
		"models/hat_knife/bow.mdl",
		"models/hat_knife/dildau.mdl"
	};



/*
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
		540,
		570,
		600,
		630,
		660,
		690,
		720,
		750,
		780,
		810,
		840,
		870,
		900,
		930,
		960,
		990,		
		1020,
		1050,
		1080,
		1110
	};
*/

	static szChat[ 192 ],szName[ 32 ];

	new szFile[ 128 ];
	new PlayerTag[ 33 ][ 32 ];
	new bool: PlayerHasTag[ 33 ];


	public plugin_init()//fix by Adryyy
	{
		register_event("DeathMsg", "hook_death", "a"/*, "1>0"*/);

		register_event("CurWeapon","CurWeapon","be","1=1");

		menuCBH = menu_makecallback( "menucallback1" );
		menuCBK = menu_makecallback( "menucallback2" );
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

		for( new i; i < sizeof VnamesH; i++ )	if( !equal( VnamesH[ i ], "" ) )	precache_model( VnamesH[ i ] );

		for( new i; i < sizeof VnamesK; i++ )	precache_model( VnamesK[ i ] );
	}

	public client_putinserver( id )
	{
		if(is_user_connected(id)&&!is_user_bot(id))
		{
			LoadData(id)


			PlayerHasTag[ id ] = false;
			LoadPlayerTag( id );
		}
	}
	public client_disconnect( id )
	{
		if(!is_user_bot(id))
		{
			if(xpplayer[id]>0)
			{
				SaveData(id)
				xpplayer[ id ] = 0;
			}

			settingH[ id ] = 0;

			settingK[ id ] = 0;
		}
	}
	public SaveData(id){
		get_user_name(id, authid, 31)

		formatex( data, sizeof( data ) - 1, "%d",xpplayer[ id ]);
		fvault_set_data(VAULTNAME, authid, data );
	}
	public LoadData(id){
		get_user_name(id,authid,31)

		if( fvault_get_data(VAULTNAME, authid, data, sizeof( data ) - 1 ) )
		{
			parse( data, szXp, sizeof( szXp ) - 1 );

			xpplayer[id] = str_to_num( szXp );
		}
		else	xpplayer[id]=0
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
		
		format( message, 999, "[CurrentHat : %s]<br>[CurrentKnife : %s]<br>[Level : %i]<br>[Experience : %i / %i]<br>[Ordinary : %i]<br>[%i kills for new level]", skinNamesH[ settingH[ player ] ],skinNamesK[ settingK[ player ] ], level, xpplayer[ player ], LEVELUPXP * ( level + 1 ), level / SKINHATSLEVELCHANGE + 1, ( LEVELUPXP * ( level + 1 ) - xpplayer[ player ] ) / KILLXP );
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
		client_print(id,print_chat,"[Current Hat: %s][Current Knife: %s][Level: %i][Experience: %i/%i][Ordinary: %i][%i kills for new level]",skinNamesH[ settingH[ id ] ],skinNamesK[ settingK[ id ] ], level, xpplayer[ id ], LEVELUPXP * ( level + 1 ), level / SKINHATSLEVELCHANGE + 1, ( LEVELUPXP * ( level + 1 ) - xpplayer[ id ] ) / KILLXP)
	}
	   
	public SkinSelect( id )
	{
		if(!is_user_alive(id))	return

		new menu = menu_create( "What you want?", "menuhandler" );
	   
		menu_additem( menu, "HATS", "1" );
		menu_additem( menu, "KNIVES", "0" )

		menu_setprop( menu, MPROP_EXIT, MEXIT_ALL );
		menu_display( id, menu,0);
	}
	public menuhandler( id, Menu, Item )
	{
		if( Item < 0||!is_user_alive(id) )	return 0;

		new Key[ 3 ],Access, CallBack;
		menu_item_getinfo( Menu, Item, Access, Key, 2, _, _, CallBack );

		new isKey = str_to_num( Key );

		switch( isKey )
		{
			case 1:	if(is_user_alive(id))	HatsSelect( id )

			case 2:	if(is_user_alive(id))	KnivesSelect( id )
		}

		menu_destroy(Menu)
		return 1;
	}

	public HatsSelect( id )
	{
		if(!is_user_alive(id))	return

		new menu = menu_create( "Choose your hat skin", "menuhandler1" );
		//new level = xpplayer[ id ] / LEVELUPXP;
	   
		for( new i=0; i < sizeof skinNamesH; i++ )
		{
	/*
			for(new x;x<sizeof HatsLevels;x++)
			{
				menu_additem( menu, skinNames[ i ], _, level>=HatsLevels[x], menuCB );
			}
	*/
			menu_additem( menu, skinNamesH[ i ], _, _, menuCBH );
		}
	   
		menu_display( id, menu);
	}
	public menuhandler1( id, menu, item )
	{
		if(item == MENU_EXIT||!is_user_alive(id))
		{
			menu_destroy(menu)
			return PLUGIN_HANDLED
		}

		if(item == settingH[id])
		{
			client_print(id,print_chat, "%s You already have: %s",PLUG_TAG, skinNamesH[item]);
			menu_destroy(menu)
			return PLUGIN_HANDLED
		}

		Set_Hat( id, item );
		client_print(id,print_chat, "%s The hat you chose is: %s",PLUG_TAG, skinNamesH[item]);
		menu_destroy(menu);

		return PLUGIN_HANDLED
	}
	public menucallback1( id, menu, item )
	{
		static szInfo[8], iAccess, iCallback;
		menu_item_getinfo(menu, item, iAccess, szInfo, charsmax(szInfo), .callback = iCallback);
		/*static iType;
		iType = str_to_num(szInfo);*/

		new level = xpplayer[ id ] / LEVELUPXP;
		if( item > level / SKINHATSLEVELCHANGE/*||item == settingH[id]*/ )	return ITEM_DISABLED;
	   
		return ITEM_ENABLED;//IGNORED
	}
	public Set_Hat(player, imodelnum)
	{
		if(!is_user_alive(player))	return PLUGIN_HANDLED
		settingH[ player ] = imodelnum;

		if(g_HatEnt[player] < 1) {
			g_HatEnt[player] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
			if(g_HatEnt[player] > 0) {
				set_pev(g_HatEnt[player], pev_movetype, MOVETYPE_FOLLOW)
				set_pev(g_HatEnt[player], pev_aiment, player)
				if(settingH[player]==0)	fm_set_entity_visibility(g_HatEnt[player],0)
				else
				{
					set_pev(g_HatEnt[player], pev_rendermode, kRenderNormal)
					engfunc(EngFunc_SetModel, g_HatEnt[player], VnamesH[imodelnum])
				}
			}
		}
		else
		{
			if(settingH[player]==0)	fm_set_entity_visibility(g_HatEnt[player],0)
			else
			{
				fm_set_entity_visibility(g_HatEnt[player],1)
				engfunc(EngFunc_SetModel, g_HatEnt[player], VnamesH[imodelnum])
			}
		}

		return PLUGIN_HANDLED
	}


	public KnivesSelect( id )
	{
		if(!is_user_alive(id))	return

		new menu = menu_create( "Choose your knife skin", "menuhandler2" );
	   
		for( new i=0; i < sizeof skinNamesK; i++ )	menu_additem( menu, skinNamesK[ i ], _, _, menuCBK );
	   
		menu_display( id, menu);
	}
	public menuhandler2( id, menu, item )
	{
		if(item == MENU_EXIT||!is_user_alive(id))
		{
			menu_destroy(menu)
			return PLUGIN_HANDLED
		}

		if(item == settingK[id])
		{
			client_print(id,print_chat, "%s You already have: %s",PLUG_TAG, skinNamesK[item]);
			menu_destroy(menu)
			return PLUGIN_HANDLED
		}

		Set_Knife( id, item );
		client_print(id,print_chat, "%s The hat you chose is: %s",PLUG_TAG, skinNamesK[item]);
		menu_destroy(menu);

		return PLUGIN_HANDLED
	}
	public menucallback2( id, menu, item )
	{
		static szInfo[8], iAccess, iCallback;
		menu_item_getinfo(menu, item, iAccess, szInfo, charsmax(szInfo), .callback = iCallback);

		/*static iType;
		iType = str_to_num(szInfo);*/

		new level = xpplayer[ id ] / LEVELUPXP;
		if( item > level / SKINKNIVESLEVELCHANGE||item == settingK[id] )	return ITEM_DISABLED;
	   
		return ITEM_ENABLED
	}
	public Set_Knife(player, imodelnum)
	{
		if(!is_user_alive(player))	return PLUGIN_HANDLED

		settingK[ player ] = imodelnum;
	
		new Clip, Ammo, Weapon = get_user_weapon(player, Clip, Ammo)//da
		if ( Weapon != CSW_KNIFE ) 	return PLUGIN_HANDLED 
		
		new vModel[120],pModel[120] 
		
		/*if (imodelnum==0||!imodelnum)
		{
			format(vModel,charsmax(vModel),"models/v_knife.mdl")
			format(pModel,charsmax(pModel), "models/p_knife.mdl")//da
			return PLUGIN_HANDLED;
		}*/
		
		format(vModel,charsmax(vModel), VnamesK[imodelnum])
		format(pModel,charsmax(pModel), "models/p_knife.mdl")

		set_pev(player, pev_viewmodel2, vModel)
		set_pev(player, pev_weaponmodel2, pModel)

		return PLUGIN_HANDLED
	}
	public CurWeapon(id)	if(is_user_alive(id))	Set_Knife(id, settingK[id])




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
	public hook_teamsay(id)
	{
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
							case CS_TEAM_T:		ColorChat( iPlayer, RED, "^1%s(Terrorist) [Level:^4 %d^1]^3 *^4%s^3* %s^1: %s", is_user_alive( id ) ? "" : "*DEAD* ",level,PlayerTag[ id ], szName, szChat );
							case CS_TEAM_CT:	ColorChat( iPlayer, BLUE, "^1%s(Counter-Terrorist) [Level:^4 %d^1]^3 *^4%s^3* %s^1: %s", is_user_alive( id ) ? "" : "*DEAD* ",level,PlayerTag[ id ], szName, szChat );
							case CS_TEAM_SPECTATOR:	ColorChat( iPlayer, GREY, "^1(Spectator) [Level:^4 %d^1]^3 *^4%s^3* %s^1: %s",level,PlayerTag[ id ], szName, szChat );
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
