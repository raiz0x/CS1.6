#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fvault>
#include <celltrie>

new const g_VAULTNAME[] = "CODES";

new activated[33],g_name[32][33],g_ip[32][33],g_authid[32][65],iIP[32],data[ 125 ],iName[32],Trie:Codes2;

public plugin_init()
{
	register_clcmd("say","SayFUNC")
	register_clcmd("say_team","SayFUNC")
	
	register_forward( FM_ClientUserInfoChanged, "Fwd_ClientUserInfoChanged" );
}

public plugin_precache()
{
	Codes2 = TrieCreate();
	new iFile[ 256 ];
	copy(iFile[ get_localinfo( "amxx_configsdir" , iFile, charsmax( iFile ) ) ] , charsmax( iFile ) , "/coduri.ini" );
	if( !file_exists( iFile ) )	write_file( iFile, "; Trece codurile mai jos, una sub alta", -1 );
	
	new iFilePointer = fopen(iFile, "r+")
	if(iFilePointer)
	{
		new szBuffer[160]
		while( !feof( iFilePointer ) )
		{
			fgets( iFilePointer, szBuffer, charsmax( szBuffer ) );
			trim(szBuffer)
			
			if( szBuffer[ 0 ] == '#' || szBuffer[ 0 ] == ';' ||
			(szBuffer[ 0 ] == '/' && szBuffer[ 1 ] == '/') || !szBuffer[ 0 ]
			/*|| !strlen(szBuffer)||szLineData[0] == EOS||szBuffer[ 0 ] == ' '*/)	continue;
			
			TrieSetCell( Codes2 , szBuffer , 1 );
		}
		fclose(iFilePointer);
	}
}

public client_putinserver(id)
{
	if(is_user_bot(id)||is_user_hltv(id)||!is_user_connected(id))	return
	
	get_user_name(id, g_name[id], charsmax(g_name[]));
	get_user_ip(id, g_ip[id], charsmax(g_ip[]),1);
	get_user_authid(id, g_authid[id], charsmax(g_authid[]));//not used!
	
	LoadData(id)
}

public Fwd_ClientUserInfoChanged( id, szBuffer )
{
	if ( !is_user_connected( id ) )	return FMRES_IGNORED;
	
	static szNewName[ 32 ];
	engfunc( EngFunc_InfoKeyValue, szBuffer, "name", szNewName, sizeof ( szNewName ) -1 );
	
	if ( equali( szNewName, g_name[ id ] ) )	return FMRES_IGNORED;
	
	if(activated[id])
	{
		SaveData( id );
		copy( g_name[ id ], sizeof ( g_name[ ] ) -1, szNewName );
		LoadData( id );
	}
	return FMRES_IGNORED;
}

public SayFUNC(id)
{
	new arg[195],arg1[32],arg2[65]
	read_args(arg,charsmax(arg))
	remove_quotes(arg)
	strbreak(arg, arg1, charsmax(arg1), arg2, charsmax(arg2))
	
	if ( equal(arg1,"/code",5))
	{
		write_code(id, arg2)
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}
public write_code(id,arg[])
{
	if(equali(arg,""))
	{
		client_print(id,print_chat,"[AMXX]: Folosire /code COD")
		return PLUGIN_HANDLED
	}
	
	if(TrieKeyExists(Codes2,arg))
	{
		if(activated[id]==1||equal(iIP[id],g_ip[id])||equal(g_name[id],iName[id]))//steamid, if is validated
		{
			client_print(id,print_chat,"[AMXX]: DEJA AI ACTIVAT")
			return PLUGIN_HANDLED
		}
		client_print(id,print_chat,"[AMXX]: AI ACTIVAT CU SUCCES")
		if(activated[id]!=1)	activated[id]=1
		SaveData(id)
		return PLUGIN_HANDLED
	}
	else
	{
		client_print(id,print_chat,"[AMXX]: COD INVALID")
		return PLUGIN_HANDLED
	}
	return PLUGIN_HANDLED
}

public SaveData(id)
{
	if(activated[id]>1)	activated[id]=1
	formatex( data, sizeof( data ) - 1, "%s %s %d", g_ip[id],g_name[id], activated[id] );
	fvault_set_data(g_VAULTNAME, g_name[id], data );
}
public LoadData(id)
{
	new szIp[ 32 ],szName[32], szActivated[ 3 ];
	if( fvault_get_data(g_VAULTNAME, g_name[id], data, sizeof( data ) - 1 ) )
	{
		parse( data, szIp, sizeof( szIp ) - 1,szName,sizeof(szName)-1, szActivated, sizeof( szActivated ) - 1 );
		copy(iIP[id],charsmax(iIP),szIp)
		copy(iName[id],charsmax(iName),szName)
		activated[id] = str_to_num( szActivated );
	}
}
