#include < amxmodx >
#include < amxmisc >
#include < fvault >

#define PLUGIN "Admins activity"
#define VERSION "0.1"

#pragma tabsize 0
#define MAX_WARN	5 

new g_szFile[ 128 ];
new const g_szFileName[ ] = "admini.ini" 		/* Numele la fisierul de unde sunt incarcate datele fiecarui admin */

new g_iPlayerWarn[ 33 ];
new g_iPlayerMinutes[ 33 ];
new szName[ 33 ][32];

new szData[ 512 ], szParseName[ 32 ],szFile,szVaultData[ 256 ],szParseMIN[ 32 ];

new const g_VAULTNAME[] = "Activitate_Admini";
new bool:e_in_program[33];
new gConfigsDir[64];
new gAdminsFile[64];

#define MAX_PLAYERS 32

new pip[MAX_PLAYERS+1][22]
new markedIp[MAX_PLAYERS+1]
new bool:poate_lua_warn[33]

public plugin_init( )
{
	register_plugin( PLUGIN, VERSION, "falcao" );
	
	/* Verificare fisier */
	
	get_configsdir( g_szFile, charsmax( g_szFile ) );
	formatex( g_szFile, charsmax( g_szFile ), "%s/%s", g_szFile, g_szFileName );
	
	if( !file_exists( g_szFile ) )
	{
		write_file( g_szFile, "; Adaugare ^"nume admin^" ^"minute necesare^"^n; Pentru evitarea citirii cuiva pune ^";^" in fata sa.");
	}
	
	/* Clcmd */
	
	register_clcmd( "say /warn", "cmdWarn" );
	register_clcmd( "say /program", "cmdProgram" );
	
	
	set_task(5.0,"read_vault",_,_,_,"b")
	
	get_configsdir(gConfigsDir, sizeof gConfigsDir - 1);
	formatex(gAdminsFile, sizeof gAdminsFile - 1, "%s/users.ini", gConfigsDir);
	
	register_cvar("amx_retrytimetowarn","10")
	register_cvar("amx_retrycounttowarn","2")
	for(new i=0; i< MAX_PLAYERS; i++)	markedIp[i]=0;
}

public clean_markedip(index[])	markedIp[str_to_num(index)]=0;

public ChekList(id)
{
	szFile = fopen( g_szFile, "rt" );
	
	if( !szFile )
		return 1;
	
	while( !feof( szFile ) )
	{
		fgets( szFile, szData, charsmax( szData ) );
		
		if( szData[ 0 ] == ';' || szData[ 0 ] == '!' || szData[ 0 ] == '/' && szData[ 1 ] == '/'||!szData[0] )
			continue;
		
		parse( szData, szParseName, charsmax( szParseName ) );
		
		if( equal( szParseName, szName[id] ) ) 
		{
			e_in_program[id]=true
			
			LoadData( id );
			
			set_task( 3.0, "verifyPlayer", id );
			
			set_task( 60.0, "adaugareMinut", id, _, _, "b");
			
			break;
		}
		else
		{
			if(e_in_program[id])
			{
				e_in_program[id]=false
				remove_task(id)
			}
		}
	}
	
	fclose( szFile );
	
	return 1;
}

public read_vault() {
	new iPlayers[32],iNum,id,i;
	get_players(iPlayers,iNum,"c");
	for(i = 0; i < iNum; i++)
	{
		id = iPlayers[i];
		if(!is_user_admin(id))	continue;
		SaveData(id);
	}
}

public client_infochanged(id) {
	SaveData(id);
	new newname[32];
	get_user_info(id,"name",newname,charsmax(newname));
	if(!equal(newname,szName[id]))
	{
		set_task(0.3,"LoadData",id);
		copy( szName[ id ], charsmax(szName[]), newname );
		ChekList(id);
	}
}

public client_putinserver( id )
{
	if(is_user_bot(id)||!is_user_admin(id))	return;
	
	get_user_name( id, szName[id], charsmax(szName[]) );
	
	ChekList(id);
}

public client_disconnect( id )
{	
	SaveData( id );
	remove_task(id);
	g_iPlayerMinutes[ id ]=0;
	g_iPlayerWarn[ id ]=0;
	
	e_in_program[id]=false;
	
	if ((!is_user_bot(id))) {
		for(new i = 1; i <= MAX_PLAYERS; i++) {
			if(pip[i][0] == 0) {
				markedIp[i]++;
				if (markedIp[i] == 1)
				{		
					new para[3];
					format(para, 2, "%d", i);
					set_task(60.0 * get_cvar_num("amx_retrytimetowarn"), "clean_markedip", 0, para, 1);		
				}
				else if (markedIp[i] == get_cvar_num("amx_retrycounttowarn"))
				{
					new userip[21+1];
					get_user_ip(id, userip, 21, 0);
					copy(pip[i], 21, userip);		
				}
				return PLUGIN_CONTINUE;
			}
		}
	}
	
	poate_lua_warn[id]=false;
	
	return PLUGIN_CONTINUE;
}

public adaugareMinut( id )
{
	if( is_user_connected( id ) )
	{
		if(e_in_program[id])	g_iPlayerMinutes[ id ]++;
		else
		{
			g_iPlayerMinutes[ id ]=0;
			remove_task(id);
		}
	}
}

public verifyPlayer( id )
{
	if(!e_in_program[id])	return 1;
	new userip[21+1];
	new uname[33+1];
	get_user_ip(id, userip, 21, 0);
	get_user_name(id, uname, 33);
	for(new i = 1; i <= MAX_PLAYERS; i++) {
		if (equal(userip, pip[i], 21)) {
			new userid[1];
			userid[0] = get_user_userid(id);
			if (markedIp[i] < get_cvar_num("amx_retrycounttowarn"))
			{
				return PLUGIN_CONTINUE;
			}
			
			poate_lua_warn[id]=true;
			
			markedIp[i] = 0;
			pip[i][0] = 0;
			
			return PLUGIN_CONTINUE;
		}
	}
	
	szFile = fopen( g_szFile, "rt" );
	
	if( !szFile )
		return 1;
	
	while( !feof( szFile ) )
	{
		fgets( szFile, szData, charsmax( szData ) );
		
		if( szData[ 0 ] == ';' || szData[ 0 ] == '!' || szData[ 0 ] == '/' && szData[ 1 ] == '/'||!szData[0] )
			continue;
		
		parse( szData, szParseName, charsmax( szParseName ), szParseMIN, charsmax( szParseMIN ) );
		
		if( equal( szParseName, szName[id] ) ) 
		{
			if( g_iPlayerMinutes[ id ] >= str_to_num( szParseMIN ))
			{
				log_to_file( "activity_admins.log", "%s si-a respectat programul cu %d/%d minut%s.", szName[id], g_iPlayerMinutes[ id ], str_to_num( szParseMIN ),str_to_num( szParseMIN )==1?"":"e" );	
			}
			else
			{
				if(g_iPlayerMinutes[ id ]!=0)
				{
					if(g_iPlayerWarn[ id ]>=MAX_WARN)	check_access(id);
					else if(poate_lua_warn[id])
					{
						g_iPlayerWarn[ id ] ++;
						
						log_to_file( "activity_admins.log", "%s a stat doar %d minut%s pe server. A primit +1 warn.", szName[id], g_iPlayerMinutes[ id ],g_iPlayerMinutes[ id ]==1?"":"e" );
						
						C_PrintChat( id, "!cAtentie! Azi ai facut!v %d!cminut%s. Trebuie sa stai minim!v %d!cminut%s.", g_iPlayerMinutes[ id ],g_iPlayerMinutes[ id ]==1?"":"e",str_to_num( szParseMIN ), str_to_num( szParseMIN )==1?"":"e" );
						C_PrintChat( id, "!cAi primit!v +1!c warn, pentru ca nu ai stat!v %d!c minut%s. Minute acumulate:!v %d!c, Warn: (!v%d!c/!v%d!c)", str_to_num( szParseMIN ),str_to_num( szParseMIN )==1?"":"e", g_iPlayerMinutes[ id ],g_iPlayerWarn[id],MAX_WARN );
						C_PrintChat( id, "!cComenzi!e informative!c in!e chat:!v /program!c,!v /warn");
					}
				}
				else
				{
					new DATA[32];
					get_time("%m.%d.%Y - %H:%M:%S",DATA,charsmax(DATA));
					log_to_file( "activity_admins.log", "%s si-a inceput programul: %s", szName[id], DATA );
					
					C_PrintChat( id, "!cSalut!v %s!c ! Se pare ca activitatea ta este contorizata, si trebuie sa stai cel putin!v %d!cminut%s.",szName[id],str_to_num( szParseMIN ),str_to_num( szParseMIN)==1?"":"e" );
					C_PrintChat( id, "!cComenzi!e informative!c in!e chat:!v /program!c,!v /warn");
				}
			}
			
			break;
		}
	}
	
	fclose( szFile );
	
	return 1;
}

public check_access(id)
{
	if( g_iPlayerWarn[ id ] >= MAX_WARN )
	{
		static iFileP;
		iFileP = fopen( gAdminsFile, "rt" );
		
		if( !iFileP )	return 1;
		new iLine;
		
		while( !feof( iFileP ) )
		{
			fgets( iFileP, szData, charsmax( szData ) );
			trim(szData);
			
			iLine++;
			
			if( szData[ 0 ] == ';' || (strlen(szData) < 3)||!szData[0])	continue;
			
			parse( szData, szParseName, charsmax( szParseName ) );
			remove_quotes(szParseName);
			
			if( equal( szParseName, szName[id] ) )
			{				
				format( szData, charsmax( szData ), ";%s", szData );
				write_file("/addons/amxmodx/configs/users.ini", szData, iLine-1);
				
				log_to_file( "activity_admins.log", "%s a primit remove pentru nerespectarea programului impus.", szName[id] );
				
				set_task( 3.0, "mesajWarn", id );
				
				break;
			}
		}
		fclose( iFileP );
	}
	return 1;
}

public mesajWarn( id )
{
	C_PrintChat( id, "!cAi facut!v %d!c/!v%d!v warn!c-uri.!e Adminul tau a fost oprit!c.",MAX_WARN,MAX_WARN );
	g_iPlayerWarn[ id ] = 0;
	g_iPlayerMinutes[id]=0;
	e_in_program[id]=false;
	poate_lua_warn[id]=false;
	remove_task(id);
	server_cmd("amx_reloadadmins");
	SaveData( id );
	return PLUGIN_HANDLED;
}

public cmdWarn( id )
{
	if( e_in_program[id] )
	{
		szFile = fopen( g_szFile, "rt" );
		
		if( !szFile )
			return 1;
		
		while( !feof( szFile ) )
		{
			fgets( szFile, szData, charsmax( szData ) );
			
			if( szData[ 0 ] == ';' || szData[ 0 ] == '!' || szData[ 0 ] == '/' && szData[ 1 ] == '/'||!szData[0] )
				continue;
			
			parse( szData,\
			szParseName, charsmax( szParseName ) );
			
			if( equal( szParseName, szName[id] ) ) 
			{
				if(g_iPlayerWarn[ id ]<MAX_WARN)	C_PrintChat( id, "!cAi!v %d!c/!v%d!c warn-uri, respectati programul zilnic sau primesti!e remove!c.", g_iPlayerWarn[ id ], MAX_WARN );
				else if(g_iPlayerWarn[ id ]>=MAX_WARN)
				{
					C_PrintChat( id, "!cAi primit!v remove!c din cauza acumularii a!v %d!c/!v%d!e WARN!c-uri.", MAX_WARN,MAX_WARN );
					check_access(id);
				}
				
				break;
			}
		}
		
		fclose( szFile );
	}	else	C_PrintChat( id, "!cNe pare rau, dar nu faci parte din program." );
	
	return 1;
}

public cmdProgram( id )
{
	if( e_in_program[id] )
	{
		szFile = fopen( g_szFile, "rt" );
		
		if( !szFile )
			return 1;
		
		while( !feof( szFile ) )
		{
			fgets( szFile, szData, charsmax(szData) );
			
			if( szData[ 0 ] == ';' || szData[ 0 ] == '!' || szData[ 0 ] == '/' && szData[ 1 ] == '/'||!szData[0] )
				continue;
			
			parse( szData, szParseName, charsmax( szParseName ),szParseMIN,charsmax(szParseMIN) );
			
			if( equal( szParseName, szName[id] ) ) 
			{
				C_PrintChat( id, "!cMai ai!v %d!c minut%s pana iti termini programul de azi. Pana acum ai!v %d!cminut%s", str_to_num(szParseMIN)-g_iPlayerMinutes[ id ],str_to_num(szParseMIN)-g_iPlayerMinutes[ id ]==1?"a":"e",g_iPlayerMinutes[ id ],g_iPlayerMinutes[ id ]==1?"":"e");
				break;
			}
		}
		
		fclose( szFile );
	}
	else
	{
		C_PrintChat( id, "!cNe pare rau, dar nu faci parte din program." );
	}
	
	return 1;
}

public LoadData( id )
{		
	if( fvault_get_data(g_VAULTNAME, szName[id], szVaultData, charsmax(szVaultData) ) )
	{
		new iWarn[ 33 ], iMinutes[ 33 ];
		parse( szVaultData,\
		iMinutes, charsmax( iMinutes ),\
		iWarn, charsmax( iWarn ) );
		
		g_iPlayerMinutes[ id ] = str_to_num( iMinutes );
		g_iPlayerWarn[ id ] = str_to_num( iWarn );
	}
	else
	{
		g_iPlayerMinutes[ id ] = 0;
		g_iPlayerWarn[ id ] = 0;
	}
}

public SaveData( id )
{
	formatex( szVaultData, charsmax( szVaultData ), "%d %d",g_iPlayerMinutes[ id ], g_iPlayerWarn[ id ] );
	
	fvault_set_data( g_VAULTNAME, szName[id],szVaultData );
}

stock C_PrintChat( const id, const szInput[ ], any:... )
{
	static szMesage[192];
	vformat(szMesage, charsmax(szMesage), szInput, 3);
	
	replace_all(szMesage, charsmax(szMesage), "!c", "^1");
	replace_all(szMesage, charsmax(szMesage), "!e", "^3");
	replace_all(szMesage, charsmax(szMesage), "!v", "^4");
	replace_all(szMesage, charsmax(szMesage), "!e2", "^0");
	
	static g_msg_SayText = 0;
	if(!g_msg_SayText)	g_msg_SayText = get_user_msgid("SayText");
	
	new Players[32], iNum = 1, i;
	
	if(id) Players[0] = id;
	else get_players(Players, iNum, "ch");
	
	for(--iNum; iNum >= 0; iNum--) 
	{
		i = Players[iNum];
		
		message_begin(MSG_ONE_UNRELIABLE, g_msg_SayText, _, i);
		write_byte(i);
		write_string(szMesage);
		message_end();
	}
}
