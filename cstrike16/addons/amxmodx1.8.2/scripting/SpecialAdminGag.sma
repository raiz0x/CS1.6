#include < amxmodx >
#include < amxmisc >

#include < fakemeta >
#include < engine >

#define PLUGIN "Special Admin Gag"
#define VERSION "1.0"

#define COMMAND_ACCESS  	ADMIN_KICK // accesu adminilor pentru comanda
#define MAX_PLAYERS 		32 + 1

#define			SAVEDATA_FILE			"GagSaveDataFile"
#define			CHAT_TAG			"^1[^4ESTRIKE.RO^1]"

enum {
	INFO_NAME
};

new const bars[ ] = "/";

new command[ ] [ ] =  {
	"/gag",
	"/ungag",
	"/mute",
	"/unmute"
};

new Caccess[ ] =  {
	COMMAND_ACCESS,
	COMMAND_ACCESS,
	COMMAND_ACCESS,
	COMMAND_ACCESS
};

new const gGagFileName[ ] = "gag_words.ini";

new const gGagThinkerClassname[ ] = "GagThinker_";

new PlayerGagged[ MAX_PLAYERS ];
new PlayerGagTime[ MAX_PLAYERS ];
new JoinTime[ MAX_PLAYERS ];

new g_Words[ 562 ] [ 32 ], g_Count;

new gCvarSwearGagTime;
new gCvarGagMinuteLimit;
new gCvarGagMinuteInSeconds;
new gCvarAdminGag;
new gCvarWords;

new gMaxPlayers;

new SaveDataFile [ 128 ], g_admin[ 32 ];

public plugin_init( ) 
{
	register_plugin( PLUGIN, PLUGIN, "Cristi .C" );//Adryyy fix
	
	register_concmd( "amx_gag", "CommandGag" ); 
	register_concmd( "amx_ungag", "CommandUngag" );
	register_concmd( "amx_mute", "CommandGag" ); 
	register_concmd( "amx_unmute", "CommandUngag" );
	
	register_clcmd( "say", "CheckGag" );
	register_clcmd( "say_team", "CheckGag" );
	register_clcmd( "say_team @", "CheckGag" );
	
	register_clcmd( "say", "command_chat" );
	register_clcmd( "say_team", "command_chat" );
	register_clcmd( "say_team @", "command_chat" );
	
	GagThinker( );
	register_think( gGagThinkerClassname, "Forward_GagThinker" );
	
	gCvarSwearGagTime = register_cvar( "amx_autogag_time", "10" ); // minutele pentru gag cand ia autogag
	gCvarGagMinuteLimit = register_cvar( "amx_gag_minute_limit", "300" ); // limita maxima pentru gag minute
	gCvarGagMinuteInSeconds = register_cvar( "amx_gag_minute_in_seconds", "60" ); // minute in secunde
	gCvarAdminGag = register_cvar( "amx_admingag", "1" ); // poti da si la admini gag daca e egal cu 1, daca e 0 nu poti
	gCvarWords = register_cvar( "amx_maxwords", "200" ); // lista maxima de cuvinte in gag_words.ini
	
	gMaxPlayers = get_maxplayers( );
	
	new DataDir [ 64 ];
	get_datadir ( DataDir, 63 );
	format ( SaveDataFile, 127, "%s/%s.dat", DataDir, SAVEDATA_FILE );
}

public plugin_cfg( ) 
{
	static szConfigDir[ 64 ], iFile[ 64 ];
	get_localinfo ( "amxx_configsdir", szConfigDir, 63 );
	formatex ( iFile , charsmax( iFile ) , "%s/%s" , szConfigDir, gGagFileName );
	
	if( !file_exists( iFile ) )	write_file( iFile, "# Pune aici cuvintele jignitoare sau reclamele", -1 );
	
	new szBuffer[ 128 ];
	new szFile = fopen( iFile, "rt" );
	
	while( !feof( szFile ) )
	{
		fgets( szFile, szBuffer, charsmax( szBuffer ) );
		
		if( szBuffer[ 0 ] == '#' )	continue;
		
		parse( szBuffer, g_Words[ g_Count ], sizeof g_Words[ ] - 1 );
		g_Count++;
		
		if( g_Count >= get_pcvar_num ( gCvarWords ) )	break;
	}
	fclose( szFile );
}

public client_putinserver( id ) 
{ 
	if ( is_user_connected( id ) && !is_user_bot(id) )
	{
		JoinTime[ id ] = get_systime( );
		LoadData( id );
	}
}

public client_disconnect ( id )	if ( PlayerGagged [ id ]&&!is_user_bot(id) )	SaveData( id );

public SaveData ( client ) {
	new Name [ 32 ];
	get_user_name ( client, Name, 31 );
	
	new _Gagged = PlayerGagged [ client ];
	new _GagTime = PlayerGagTime [ client ];
	
	new StrongData [ 1024 ];
	formatex ( StrongData, sizeof ( StrongData ) - 1, "^"%i^" ^"%i^" ^"%s^"", _Gagged, _GagTime,g_admin );
	
	new Save [ 1024 ];
	format ( Save, sizeof ( Save ) - 1, "^"%s^" %s", Name, StrongData );
	
	new Line [ 128 ], Linie, IsPlayer = false, Arg1 [ 32 ];
	new FileOpen = fopen ( SaveDataFile, "rt" );
	while ( !feof ( FileOpen ) ) {
		fgets ( FileOpen, Line, 127 );
		trim ( Line );
		parse ( Line, Arg1, 31 );
		if ( equali ( Arg1, Name ) ) {
			write_file ( SaveDataFile, Save, Linie );
			IsPlayer = true;
			break;
		}
		Linie++;
	}
	
	fclose ( FileOpen );
	if ( !IsPlayer )	write_file ( SaveDataFile, Save, -1 );
}

public LoadData ( client ) {
	new Name [ 32 ];
	get_user_name ( client, Name, 31 );
	new Line [ 128 ], IsPlayer = false, Arg1 [ 32 ], Arg2 [ 32 ], Arg3 [ 32 ], Arg4 [ 32 ];
	new FileOpen = fopen ( SaveDataFile, "rt" );
	while ( !feof ( FileOpen ) ) {
		fgets ( FileOpen, Line, 127 );
		trim ( Line );
		parse ( Line, Arg1, 31, Arg2, 31, Arg3, 31, Arg4, 31 );
		if ( equali ( Arg1, Name ) ) {
			PlayerGagged [ client ] = str_to_num ( Arg2 );
			PlayerGagTime [ client ] = str_to_num ( Arg3 );
			copy(g_admin,charsmax(Arg4),Arg4)
			IsPlayer = true;
			break;
		}
	}
	fclose ( FileOpen );
	
	if ( !IsPlayer ) {
		PlayerGagged [ client ] = 0;
		PlayerGagTime [ client ]  = 0;
	}
}

public command_chat( index )
{
	static szArg[ 192 ], command2[ 192 ];
	read_args( szArg, charsmax ( szArg ) );
	if( !szArg [ 0 ] )	return PLUGIN_CONTINUE;
	remove_quotes( szArg[0] );
	
	for( new x; x < sizeof command; x++ )
	{
		if ( equal ( szArg, command [ x ], strlen ( command [ x ] ) ) )
		{
			if ( get_user_flags ( index ) & Caccess [ x ] )
			{
				replace( szArg, charsmax ( szArg ), bars, "" );
				formatex( command2, charsmax(command2), "amx_%s", szArg );
				client_cmd( index, command2 );
			}
			break;
		}
	}
	return PLUGIN_CONTINUE;
}

public CheckGag( id ) 
{
	new szSaid[ 300 ];
	read_args( szSaid, charsmax( szSaid ) );
	remove_quotes( szSaid );
	if( !UTIL_IsValidMessage( szSaid ) )	return PLUGIN_HANDLED;
	
	if( PlayerGagged[ id ] == 1 )
	{
		PlayerGagged[ id ] = 1;
		chat_color( id, "%s Ai fost pedepsit de^4 %s^1 ! Vei putea folosi chatul peste^4 %d^1 minut%s !",CHAT_TAG,g_admin, PlayerGagTime[ id ], PlayerGagTime[ id ]==1?"":"e" );	
		return PLUGIN_HANDLED;
	}
	if( PlayerGagged[ id ] == 2 )
	{
		chat_color( id, "%s You've been^4 Auto-Gagged^1 for your behavior.^4 %d minute%s^1 remaining",CHAT_TAG, PlayerGagTime[ id ], PlayerGagTime[ id ]==1?"":"s" );
		return PLUGIN_HANDLED
	}

	new i;
	for( i = 0; i < get_pcvar_num ( gCvarWords ); i++ )
	{
		if( containi( szSaid, g_Words[ i ] ) != -1 )
		{
			if( get_pcvar_num( gCvarAdminGag ) == 0 && is_user_admin ( id ) )	return 1;
				
			PlayerGagged[ id ] = 2;
			PlayerGagTime[ id ] = get_pcvar_num ( gCvarSwearGagTime );
			set_speak( id, SPEAK_MUTED );
				
			chat_color( id, "%s You've been^4 Auto-Gagged^1 for your behavior.^4 %d minute%s^1 remaining",CHAT_TAG, PlayerGagTime[ id ], PlayerGagTime[ id ]==1?"":"s" );
				
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

public CommandGag( id )  
{  
	if( !(get_user_flags( id ) & COMMAND_ACCESS ) )
	{
		client_cmd( id, "echo |AMXX-GAG| Nu ai acces la aceasta comanda !" );
		return 1;
	}
	
	new szArg[ 32 ], szMinutes[ 32 ];
	read_argv( 1, szArg, charsmax ( szArg ) );
	
	if( equal( szArg, "" ) )
	{
		client_cmd( id, "echo |AMXX-GAG| amx_gag < nume > < minute >" );
		return 1;
	}
	
	new iPlayer = cmd_target( id, szArg, CMDTARGET_ALLOW_SELF );
	
	if( !iPlayer )
	{
		client_cmd( id, "echo |AMXX-GAG| Jucatorul specificat nu a fost gasit !" );
		return 1;
	}
	
	if ( get_pcvar_num( gCvarAdminGag ) == 0 && is_user_admin( iPlayer ) )
	{
		client_cmd( id, "echo |AMXX-GAG| Nu poti da gag la Admini !" );
		return 1;
	}
	
	read_argv( 2, szMinutes, charsmax ( szMinutes ) );
	
	if( !str_to_num(szMinutes) )
	{
		client_cmd( id, "echo |AMXX-GAG| Format incorect minute !" );
		return 1;
	}
	
	new iMinutes = str_to_num( szMinutes );
	
	if ( iMinutes > get_pcvar_num ( gCvarGagMinuteLimit ) )
	{
		console_print( id, "|AMXX-GAG| Ai setat %d minut%s, iar limita maxima este %d! Setare automata pe %d minut%s", iMinutes,iMinutes==1?"":"e", get_pcvar_num ( gCvarGagMinuteLimit ), get_pcvar_num ( gCvarGagMinuteLimit ),get_pcvar_num ( gCvarGagMinuteLimit)==1?".":"e." );
		iMinutes = get_pcvar_num( gCvarGagMinuteLimit ) ;
	}
	
	if( PlayerGagged[ iPlayer ] == 1 ||PlayerGagged[ iPlayer ] == 2) 
	{
		client_cmd( id, "echo |AMXX-GAG| Jucatorul %s are deja gag !", GetInfo( iPlayer, INFO_NAME ) );
		return 1;
	}
	
	PlayerGagged[ iPlayer ] = 1;
	PlayerGagTime[ iPlayer ] = iMinutes;
	set_speak( iPlayer, SPEAK_MUTED );
	
	chat_color(0, "%s ADMIN^4 %s^1 GAG^4 %s^1 for^4 %d^1 minute%s",CHAT_TAG, GetInfo( id, INFO_NAME ), GetInfo( iPlayer, INFO_NAME ), iMinutes, iMinutes==1?"":"s" );
	
	new szAdminName[32]
	get_user_name(id,szAdminName,charsmax(szAdminName))
	copy(g_admin,charsmax(szAdminName),szAdminName)
	return PLUGIN_HANDLED;
}

public CommandUngag( id )  
{  
	if( !(get_user_flags( id ) & COMMAND_ACCESS ) )
	{
		client_cmd( id, "echo |AMXX-GAG| Nu ai acces la aceasta comanda !" );
		return 1;
	}
	
	new szArg[ 32 ];
	read_argv( 1, szArg, charsmax( szArg ) );
	
	if( equal( szArg, "" ) )
	{
		client_cmd( id, "echo |AMXX-GAG| amx_ungag < nume > !" );
		return 1;
	}
	
	new iPlayer = cmd_target ( id, szArg, CMDTARGET_ALLOW_SELF );
	
	if( !iPlayer )
	{
		client_cmd(  id, "echo |AMXX-GAG| Jucatorul specificat nu a fost gasit !" );
		return 1;
	}
	
	if( PlayerGagged[ iPlayer ] == 0 ) 
	{
		console_print( id, "|AMXX-GAG| Jucatorul %s nu are Gag !", GetInfo( iPlayer, INFO_NAME ) );
		return 1;
	}
	
	PlayerGagged[ iPlayer ] = 0;
	PlayerGagTime[ iPlayer ] = 0;
	set_speak( iPlayer, SPEAK_NORMAL );
	SaveData(iPlayer);
	
	chat_color(0, "%s Admin^4 %s^1 UNGAG^4 %s", CHAT_TAG, GetInfo( id, INFO_NAME ), GetInfo( iPlayer, INFO_NAME ) );
	
	return PLUGIN_HANDLED;
}

public Forward_GagThinker( iEntity )
{
	if ( pev_valid( iEntity ) )
	{
		set_pev( iEntity, pev_nextthink, get_gametime( ) + 1.0 ) ;
		
		new id;
		for ( id = 1; id <= gMaxPlayers; id++ )
		{
			if ( is_user_connected ( id ) 	
			&& ! is_user_bot( id )
			&& PlayerGagged[ id ] !=0
			&& PlayerGagTime[ id ] > 0
			&& ( ( get_systime( ) - JoinTime[ id ] ) >= get_pcvar_num ( gCvarGagMinuteInSeconds ) ) ) {
				JoinTime[ id ] = get_systime( );
				PlayerGagTime[ id ] -= 1;
				if ( PlayerGagTime[ id ] <= 0 )
				{
					chat_color(id,"%s Ai primit^4 AutoUngag^1 !",CHAT_TAG)
					PlayerGagTime[ id ] = 0;
					PlayerGagged[ id ] = 0;
					set_speak( id, SPEAK_NORMAL );
					SaveData(id);
				}
			}
		}
	}
}

stock GagThinker( )
{
	new iEntity = create_entity ( "info_target" );
	
	if( !pev_valid ( iEntity ) )	return PLUGIN_HANDLED;
	
	set_pev ( iEntity, pev_classname, gGagThinkerClassname );
	set_pev ( iEntity, pev_nextthink, get_gametime( ) + 1.0 );
	
	return PLUGIN_HANDLED;
}

stock GetInfo( id, const iInfo )
{
	new szInfoToReturn[ 64 ];
	switch( iInfo )
	{
		case INFO_NAME:
		{
			new szName[ 32 ];
			get_user_name( id, szName, sizeof ( szName ) -1 );
			copy( szInfoToReturn, sizeof ( szInfoToReturn ) -1, szName );
		}
	}
	return szInfoToReturn;
}

stock bool:UTIL_IsValidMessage( const szSaid[ ] )
{
	new iLen = strlen( szSaid );
	
	if( !iLen )	return false;
	
	for( new i = 0; i < iLen; i++ )	if( szSaid[ i ] != ' ' )	return true;
	
	return false;
}

stock chat_color(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[320]
	vformat(msg, 190, input, 3)
	replace_all(msg, 190, "!g", "^4")
	replace_all(msg, 190, "!n", "^1")
	replace_all(msg, 190, "!t", "^3")
	replace_all(msg, 190, "!t2", "^0")
	
	if (id)	players[0] = id;
	else	get_players(players, count, "ch")
	
	for (new i = 0; i < count; i++)
	{
		if (is_user_connected(players[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
			write_byte(players[i])
			write_string(msg)
			message_end()
		}
	}
}
