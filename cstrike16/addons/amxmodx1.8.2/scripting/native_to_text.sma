#include <amxmodx>

#define FIRST_PLAYER_ID 1

new g_iMaxPlayers
#define IsPlayer(%1)	( FIRST_PLAYER_ID <= %1 <= g_iMaxPlayers )

#define CHECK_PLAYER(%1) \
	if( !IsPlayer(%1) ) \
	{ \
		log_error(AMX_ERR_NATIVE, "Player out of range (%d)", %1); \
		return 0; \
	} \
	else if( !is_user_connected(%1) ) \
	{ \
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", %1); \
		return 0; \
	}

public plugin_init()
{
	register_plugin("My Awesome Fake Native", "0.1", "ConnorMcLeod")

	g_iMaxPlayers = get_maxplayers()
}

public plugin_natives()
{
    register_native("get_persons_name", "get_persons_name", 0)
}

public get_persons_name(plugin, paramsnum) // get_persons_name(index, name[], len)
{
	if( paramsnum != 3 )
	{
		log_error(AMX_ERR_NATIVE, "Bad arguments num, expected 3, passed %d", paramsnum)
		return 0
	}

	new id = get_param(1)

	CHECK_PLAYER( id )    

	new name[32]
	get_user_name(id, name, charsmax(name))

	new len = get_param(3)
	name[len] = 0

	set_string(2, name, len)

	return 1
}
