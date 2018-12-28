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
	get_time("%H", a, 5)
	get_time("%M", b, 5)
	if((str_to_num(a)>=22&&str_to_num(b)>58))
	{
		if(get_playersnum(1)<13)	allow_night=true
	}
	else if((str_to_num(a)>=07&&str_to_num(b)>50))	allow_night=false
}

public task_check_time()
{
	new cm[65]
	get_mapname(cm,charsmax(cm))
	get_time("%H:%M", a, 5)

	if(allow_night)
	{
		if(equal(a, "22:59"))	chat_color(0, "!g[AMXX] !nServerul trece pe setarile de noapte.")
		if(!equal(cm,"de_dust2x2"))	server_cmd("amx_map de_dust2x2")
		server_cmd("mp_timelimit 0")
		//server_cmd("amx_pausecfg stop adminvote")
		//server_cmd("amx_pausecfg stop mapsmenu")
		pause("d","mapchooser.amxx")
		pause("d","rtv.amxx")
		allow_night=false
	}

	if (equal(a, "07:59"))
	{
		unpause("a","mapchooser.amxx")
		unpause("a","rtv.amxx")
		server_cmd("mp_timelimit 30")
	}
	if (equal(a, "08:00"))	chat_color(0, "!g[AMXX]!n Serverul trece pe setarile de zi.")
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
