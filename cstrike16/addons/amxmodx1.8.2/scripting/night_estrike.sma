#include <amxmodx>

new a[6],bool:allow_night

public plugin_init()
{
	set_task(60.0, "task_check_time", _, _, _, "b")
	set_task(30.0, "players_check", _, _, _, "b")
}

public players_check()
{
	new b[6]
	get_time("%H", b, 5)
	if(get_playersnum(1)<13&&str_to_num(b)==23)	allow_night=true
}

public task_check_time()
{
	new cm[65]
	get_mapname(cm,charsmax(cm))
	get_time("%H:%M", a, 5)

	if(allow_night)
	{
		chat_color(0, "!g[AMXX] !nServerul trece pe setarile de noapte.")
		if(!equal(cm,"de_dust2x2"))	server_cmd("amx_map de_dust2x2")
		server_cmd("mp_timelimit 0")
		//server_cmd("amx_pausecfg stop adminvote")
		server_cmd("amx_pausecfg stop mapchooser")
		//server_cmd("amx_pausecfg stop mapsmenu")
		allow_night=false
	}

	if (equal(a, "07:59"))
	{
		server_cmd("amx_pausecfg enable mapchooser")
		server_cmd("mp_timelimit 30")
	}
	if (equal(a, "08:00"))	chat_color(0, "!g[AMXX] !nEste ora !g08:00 !nserverul trece pe setarile de zi.")
}

stock chat_color(const id, const input[], any:...)
{
	new count = 1, players[32]
	static msg[191]
	vformat(msg, 190, input, 3)

	replace_all(msg, 190, "!g", "^4")
	replace_all(msg, 190, "!n", "^1")
	replace_all(msg, 190, "!t", "^3")
	replace_all(msg, 190, "!t2", "^0")

	if (id) players[0] = id; else get_players(players, count, "ch")
	{
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
}