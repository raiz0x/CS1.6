#include < amxmodx >
#include < amxmisc >
#include < fakemeta >
#include < fun >
#include < xs >
#include <hamsandwich>

#pragma tabsize 0

#define POWERS_TIMER	 20.0 

new Float:g_fLastUsed[ 33 ],Float:fTime

new bool:g_bTeleport[ 33 ],bool:g_bGM[ 33 ]

new const VIP_DIR[]=	"addons/amxmodx/configs/VIP"
new const VIP_FILE[]=	"vips.ini"

new File[125],bool:IsUserVip[33] = false,Trie:LoadVip

public plugin_init( ) 
{
	register_event( "HLTV", "event_new_round", "a", "1=0", "2=0" );
	
	register_clcmd( "say", "SayChatAnswer" );
	register_clcmd( "say_team", "SayChatAnswer" );
	
	register_concmd( "+teleport", "cmdVIPTeleport" );
	register_concmd( "-teleport", "cmdVIPTeleport" );
	
	LoadVip = TrieCreate()
}

public plugin_precache()	if(!dir_exists(VIP_DIR))	mkdir(VIP_DIR)

public plugin_cfg()
{
	formatex(File,charsmax(File),"%s/%s",VIP_DIR, VIP_FILE)
	if(!file_exists (File))
	{
		write_file (File,"; ===========================================================");
		write_file (File,"; --------------------- VIP LIST ----------------------------");
		write_file (File,"; ===========================================================");
		write_file (File,"; Nota: Incepe randul cu ; pentru a dezactiva un VIP");
		write_file (File,"; Nota: Pentru a adauga un nume cu spatiu, pune-l intre ^"^"");
	}
	
	new FilePointer,Key[32],FileData[256]
	FilePointer = fopen(File,"rt")
	/*if(!file_exists(File))
{
	FilePointer = fopen(File,"w")
	fclose(FilePointer)
}*/
	if(FilePointer)
	{
		while(!feof(FilePointer))//fgets
		{
			//trim(FileData)
			fgets(FilePointer,FileData,charsmax(FileData))
			if ( !strlen (FileData) || FileData[0] == ';' )	continue;
			parse(FileData,Key,charsmax(Key))
			TrieSetCell(LoadVip,Key,charsmax(Key))
		}
		fclose(FilePointer)
	}
}

public client_connect(id) {
	new szName[32]
	get_user_name(id,szName,charsmax(szName))

	if(TrieKeyExists(LoadVip,szName))	IsUserVip[id] = true
}
public client_infochanged(id) {
	new oldname[32],newname[32]
	get_user_name(id,oldname,charsmax(oldname))
	get_user_info(id,"name",newname,charsmax(newname))

	if(equal(newname,oldname))	return
	
	if(TrieKeyExists(LoadVip,newname))	IsUserVip[id] = true
	else	IsUserVip[id] = false
}
public plugin_end()	TrieDestroy(LoadVip)
public client_disconnect(id)	IsUserVip[id] = false

public event_new_round()
{
	for(new id;id<=get_maxplayers();id++)
	{
		g_bGM[id]=false
		g_bTeleport[id]=false
	}
}

public SayChatAnswer( id )
{
	new szSaid[ 132 ];
	read_args( szSaid, sizeof ( szSaid ) - 1 );
	remove_quotes( szSaid );
	
	if ( contain( szSaid, "/vip" )!=-1 || contain( szSaid, "/vips" )!=-1 )
	{
		if(IsUserVip[id])
		{
			ShowMenuVIP( id );
			client_print(id,print_chat,"Ai deschis meniul VIP Premium.")
		}
		else
		{
			client_print(id,print_chat,"Doar VIP-II Premium au acces la aceasta comanda.")
		}
	}
}
public ShowMenuVIP( id )
{
	new szMenu;
	szMenu = menu_create( "\rMeniu VIP Premium:\w", "iContent" );
	
	menu_additem( szMenu, "\wTeleport", 	"2" );
	menu_additem( szMenu, "\wGodMode", 	"1" );
	
	menu_setprop( szMenu, MPROP_NUMBER_COLOR, "\r" );
	menu_setprop( szMenu, MPROP_EXIT, MEXIT_ALL );
	menu_display( id, szMenu, 0 );
}
public iContent( id, szMenu, Item )
{
	if ( Item == MENU_EXIT||!is_user_alive(id) )
	{
		menu_destroy( szMenu )
		return PLUGIN_HANDLED;
	}
	
	new iData[ 9 ], szName[ 32 ];
	new iAccess, iCallback;
	menu_item_getinfo( szMenu, Item, iAccess, iData, sizeof ( iData ) - 1, szName, sizeof ( szName ) - 1, iCallback );
	
	new iKeys = str_to_num( iData );
	switch( iKeys )
	{
		case 1:
		{
			if(g_bGM[id]||g_bTeleport[id])	return PLUGIN_HANDLED
			
			g_bGM[id]=true
			set_user_godmode(id,1)
			
			client_print( id, print_chat, "Ai primit GodMode!" );
			client_print(id,print_chat,"Aceasta putere poate fi folosita odata la 20 secunde.")
			
			if( g_fLastUsed[ id ] > 0.0 && ( fTime - g_fLastUsed[ id ] ) < POWERS_TIMER )
			{
				client_print( id, print_chat, "Nu au trecut %i de la ultima folosire a puterii",floatround( POWERS_TIMER ) );
				return PLUGIN_HANDLED;
			}
			
			g_fLastUsed[id] = fTime;
			
			set_task( 3.0, "End_God", id);
		}
		
		case 2:
		{
			if(g_bTeleport[id]||g_bGM[id])	return PLUGIN_HANDLED
			g_bTeleport[ id ]  = true;
			
			client_cmd( id, ";bind v +teleport" );
			
			client_print( id, print_chat, "Ai primit Teleport!" );
			client_print( id, print_chat, "Aceasta putere poate fi folosita odata la 20 secunde." );
		}
	}
	return PLUGIN_HANDLED
}

public End_God(id)	if(is_user_connected(id)&&g_bGM[id])	set_user_godmode(id,0)

public cmdVIPTeleport( id )
{
	if( !is_user_alive( id ) || !g_bTeleport[ id ] )	return PLUGIN_HANDLED;
	
	fTime = get_gametime( );
	
	if( g_fLastUsed[ id ] > 0.0 && ( fTime - g_fLastUsed[ id ] ) < POWERS_TIMER )
	{
		client_print( id, print_chat, "Nu au trecut %i de la ultima folosire a puterii",floatround( POWERS_TIMER ) );
		return PLUGIN_HANDLED;
	}
	
	static Float:start[ 3 ], Float:dest[ 3 ];
	pev(id, pev_origin, start);
	pev(id, pev_view_ofs, dest);
	xs_vec_add(start, dest, start);
	pev(id, pev_v_angle, dest);
	
	engfunc(EngFunc_MakeVectors, dest);
	global_get(glb_v_forward, dest);
	xs_vec_mul_scalar(dest, 9999.0, dest);
	xs_vec_add(start, dest, dest);
	engfunc(EngFunc_TraceLine, start, dest, IGNORE_MONSTERS, id, 0);
	get_tr2(0, TR_vecEndPos, start);
	get_tr2(0, TR_vecPlaneNormal, dest);
	
	static const player_hull[] = {HULL_HUMAN, HULL_HEAD};
	engfunc(EngFunc_TraceHull, start, start, DONT_IGNORE_MONSTERS, player_hull[_:!!(pev(id, pev_flags) & FL_DUCKING)], id, 0);
	
	if ( !get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) &&  get_tr2(0, TR_InOpen))
	{
		engfunc(EngFunc_SetOrigin, id, start);
		return PLUGIN_HANDLED;
	}
	
	static Float:size[3];
	pev(id, pev_size, size);
	
	xs_vec_mul_scalar(dest, (size[0] + size[1]) / 2.0, dest);
	xs_vec_add(start, dest, dest);
	engfunc(EngFunc_SetOrigin, id, dest);
	
	g_fLastUsed[id] = fTime;
	
	return PLUGIN_HANDLED;
}
