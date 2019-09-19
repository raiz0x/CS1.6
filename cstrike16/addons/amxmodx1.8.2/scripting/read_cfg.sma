#include <amxmodx>
#include <amxmisc>

new g_szConfigsDir[ 128 ];

public TEST(id)	client_print(id,print_chat,"DADADADADADDAADDA")

public plugin_cfg()
{
	get_configsdir( g_szConfigsDir, charsmax( g_szConfigsDir ) );
	
	LoadConfig( )
}

public LoadConfig( )
{
	new szFile[ 128 ], szData[ 64 ];
	formatex( szFile, charsmax( szFile ), "%s/%s", g_szConfigsDir, "ReportSystem_Config.cfg" ); // line - COMMANDS_CREATE_MSG = /contact, /report, /ticket
	
	new iFile = fopen( szFile, "rt" );
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
					new szKey[ 32 ], szValue[ 64 ];
					strtok( szData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=' );
					trim( szKey ); 
					trim( szValue );
					
					remove_quotes( szKey );
					remove_quotes( szValue );
					
					if( !szValue[ 0 ] )
					{
						continue;
					}
					
					if( equal( szKey, "COMMANDS_CREATE_MSG" ) )
					{
						while( szValue[ 0 ] != 0 && strtok( szValue, szKey, charsmax( szKey ), szValue, charsmax( szValue ), ',' ) )
						{
							trim( szKey ); 
							trim( szValue );
							
							//remove_quotes(szKey)
							//ArrayPushString(gx_InfoCommands, szKey)
							//gx_InfoCommands = ArrayCreate(32, 1)
							
							new szCmd[ 32 ];
							formatex( szCmd, charsmax( szCmd ), "say %s", szKey );
							register_clcmd( szCmd, "TEST" );
							formatex( szCmd, charsmax( szCmd ), "say_team %s", szKey );
							register_clcmd( szCmd, "TEST" );
						}
					}
				}
			}
		}
		fclose( iFile );
	}
}
