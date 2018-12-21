//EDIT 3

	#include <amxmodx>
	#include <amxmisc>
	#include <fakemeta>
	#include <cstrike>
	#include <nvault>

	#define PLUGIN "XP Plugin"
	#define VERSION "1.0"
	#define AUTHOR "Kazalu"

	#define VAULTNAME "XPVAULT"
	#define KILLXP 100
	#define HSXP 200
	#define LEVELUPXP 400
	#define UPDATETIME 60.0
	#define SKINLEVELCHANGE 30
	#define PLUG_TAG "HATS"

	stock fm_set_entity_visibility(index, visible = 1) set_pev(index, pev_effects, visible == 1 ? pev(index, pev_effects) & ~EF_NODRAW : pev(index, pev_effects) | EF_NODRAW)

	new g_HatEnt[33],xpplayer[ 33 ],setting[ 33 ];

	new menuCB;


	#define MAXLEVEL 19
	new const skinNames[ MAXLEVEL ][128] =
	{
		"Default skin",
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
	new const HatsLevels[MAXLEVEL] =
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
		"models/hat/default.mdl",//DEFAULT HAT
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
	 
	public plugin_init()
	{
		register_plugin(PLUGIN, VERSION, AUTHOR);//fix by Adryyy
	   
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

		register_clcmd( "amx_setlevel", "SetLevel", ADMIN_RCON, "<tinta> <valoare>" );
	}

	public plugin_precache()	for( new i; i < sizeof Vnames; i++ )	precache_model( Vnames[ i ] );

	public client_putinserver( id )
	{
		if(is_user_connected(id)&&get_user_team(id)!=3&&!is_user_bot(id))
		{
		xpplayer[ id ] = 0;
		setting[ id ] = 0;
		set_task( 5.0, "SkinSelect", id );
	   
		new vault = nvault_open( VAULTNAME );
	   
		new name[ 50 ], useless;
		get_user_name( id, name, 49 );
	   
		new showSz[ 50 ];
		nvault_lookup( vault, name, showSz, 49, useless );
	   
		xpplayer[ id ] = str_to_num( showSz );
	   
		nvault_close( vault );
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
			if( headshot )
				xpplayer[ Killer ] += HSXP;
			else
				xpplayer[ Killer ] += KILLXP;
			   
			new level = xpplayer[ Killer ] / LEVELUPXP;
			   
			client_print( Killer, print_center, "XP %i / %i", xpplayer[ Killer ], LEVELUPXP * ( level + 1 ) );
		}
	}

	public CmdGetLevel( player )
	{
		new message[ 1000 ];
		new level = xpplayer[ player ] / LEVELUPXP;
		
		format( message, 999, "[Knife : %s]<br>[Level : %i]<br>[Experience : %i / %i]<br>[Ordinary : %i]<br>[%i kills for new level]", skinNames[ setting[ player ] ], level, xpplayer[ player ], LEVELUPXP * ( level + 1 ), level / SKINLEVELCHANGE + 1, ( LEVELUPXP * ( level + 1 ) - xpplayer[ player ] ) / KILLXP );
		show_motd( player, message );
	}

	public SetLevel( id, level, cid )
	{
		if (!cmd_access(id,level,cid,2))
			return PLUGIN_HANDLED
		   
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
		   
		//client_print( player, print_chat, "%s", skinNames[ setting[ player ] ] );
		/*
		set_hudmessage( 255, 0, 255, 0.02, 0.17, 0, 6.0, UPDATETIME );
		show_hudmessage( player, "[Knife : %s]^n[Level : %i]^n[Experience : %i / %i]^n[Ordinary : %i]^n[%i kills for new level]", skinNames[ setting[ player ] ], level, xpplayer[ player ], LEVELUPXP * ( level + 1 ), level / SKINLEVELCHANGE + 1, ( LEVELUPXP * ( level + 1 ) - xpplayer[ player ] ) / KILLXP );
		*/

		client_print(id,print_chat,"[Knife : %s][Level : %i][Experience : %i / %i][Ordinary : %i][%i kills for new level]", skinNames[ setting[ id ] ], level, xpplayer[ id ], LEVELUPXP * ( level + 1 ), level / SKINLEVELCHANGE + 1, ( LEVELUPXP * ( level + 1 ) - xpplayer[ id ] ) / KILLXP)
	}
	   
	public SkinSelect( id )
	{
		new menu = menu_create( "Choose your knife skin", "menuhandler1" );
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

		Set_Hat( id, item );

		client_print(id,print_chat, "%s The hat you chose is: %s",PLUG_TAG, skinNames[item]);

		return PLUGIN_HANDLED
	}
	 
	public menucallback1( id, menu, item )
	{
		static szInfo[8], iAccess, iCallback;
		menu_item_getinfo(menu, item, iAccess, szInfo, charsmax(szInfo), .callback = iCallback);
		static iType;
		iType = str_to_num(szInfo);
		new level = xpplayer[ id ] / LEVELUPXP;
		if( item > level / SKINLEVELCHANGE||item == setting[id] )	return ITEM_DISABLED;
	   
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
				set_pev(g_HatEnt[player], pev_rendermode, kRenderNormal)
				engfunc(EngFunc_SetModel, g_HatEnt[player], Vnames[imodelnum])
			}
		}
		else	engfunc(EngFunc_SetModel, g_HatEnt[player], Vnames[imodelnum])

		return PLUGIN_HANDLED
	}
