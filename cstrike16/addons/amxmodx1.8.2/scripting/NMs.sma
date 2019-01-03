#include <amxmodx>

new a[6],mapname[120]

public plugin_init()	set_task(60.0, "task_check_time", _, _, _, "b")

public task_check_time()
{
	get_time("%H:%M", a, 5)
	get_mapname(mapname,charsmax(mapname))

	if (equal(a, "23:59"))	chat_color(0, "!g[AMXX] !nEste ora !g23:59 !nserverul trece pe setarile de noapte.")
	if (equal(a, "00:00")&&!equali(mapname,"de_dust2x2"))	server_cmd("amx_map de_dust2x2")
	if (equal(a, "00:05"))
	{
		server_cmd("amx_rcon mp_timelimit 0")
		//server_cmd("amx_pausecfg stop adminvote")
		server_cmd("amx_pausecfg stop mapchooser")
		//server_cmd("amx_pausecfg stop mapsmenu")
	}

	if (equal(a, "07:55"))
	{
		server_cmd("amx_rcon mp_timelimit 30")
		server_cmd("amx_pausecfg enable mapchooser")
	}
	if (equal(a, "07:59")&&!equali(mapname,"de_dust2x2"))	server_cmd("amx_map de_dust2x2")
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
