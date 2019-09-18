#include <amxmodx>
#include <amxmisc>

new g_szConfigsDir[ 128 ];
new Array:g_aStaffInfo;

public plugin_init()	register_clcmd("say /evo","TEST")

public TEST(id)	if(e_in_lista(id))	client_print(id,print_chat,"DADADADADADDAADDA")

public plugin_cfg()
{
	g_aStaffInfo = ArrayCreate( 32 );
	get_configsdir( g_szConfigsDir, charsmax( g_szConfigsDir ) );
	ReadNames( );
}

ReadNames( )
{
	new szFilename[ 256 ], szData[ 128 ];
	get_configsdir( g_szConfigsDir, charsmax( g_szConfigsDir ) );
	formatex( szFilename, charsmax( szFilename ), "%s/%s", g_szConfigsDir, "StaffNames.ini" );
	
	new iFile = fopen( szFilename, "rt" );
	if( iFile )
	{		
		while( fgets( iFile, szData, charsmax( szData ) ) )
		{
			trim( szData );
			remove_quotes( szData );
			
			switch( szData[ 0 ] )
			{
				case EOS, '#', ';', '/':
				{
					continue;
				}
				default:
				{										
					ArrayPushString( g_aStaffInfo, szData );
				}
			}
		}
		fclose( iFile );
	}
	return PLUGIN_CONTINUE;
}

stock bool:e_in_lista(id)
{
	new szName[ 32 ],tname[32]
	get_user_name(id,tname,charsmax(tname))
	for( new i; i < ArraySize( g_aStaffInfo ); i++ )
	{
		ArrayGetString( g_aStaffInfo, i, szName, charsmax( szName ) )
		if(equal(tname,szName))	return true
	}
	return false
}

public plugin_end( )	ArrayDestroy( g_aStaffInfo );
