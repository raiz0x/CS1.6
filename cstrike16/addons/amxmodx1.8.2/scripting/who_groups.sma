/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>

new TAG[] = "[Red.Furious.Ro]";

new const rang[][] =
{
	"Director",
	"Legenda",
	"Owner",
	"Co-Owner",
	"Maresal",
	"General",
	"Colonel",
	"Sergent",
	"Helper",
	"VIP",
	"Slot"
}
new const rank[][] =
{
	"abcdefghijklmnopqrstu",
	"bcdefghijklmnopqrstu",
	"bcdefghijmnopqrst",
	"bcdefhijmnopqrst",
	"bcdefijmnpqr",
	"bcdefijmnp",
	"bcdefijmno",
	"bcdefijm",
	"bcefijm",
	"bit",
	"b"
}
new rangflag_val[7],rangflag2_val[7];

public plugin_init() {
	register_clcmd("say /who", "cmd_who")
	register_clcmd("say_team /who", "cmd_who")
	
	static i;
	for(i = 0; i < 7; i++)
	{
		rangflag_val[i] = read_flags(rang[i])
		rangflag2_val[i] = read_flags(rank[i])
	}
}

public cmd_who(id)
{
	static menu;
	menu = menu_create("\y Adminii de pe\r Bacau.CF\y:", "handler_who")
	static menu_item[80], tasta[2];
	for(new i = 0; i < 7; i++)
	{
		formatex(menu_item, charsmax(menu_item), "\y%s\w[\r%d\w]", rang[i], get_rang_players(i))
		tasta[0] = i
		tasta[1] = 0
		menu_additem(menu, menu_item, tasta)
	}
	menu_display(id, menu, 0)
	return PLUGIN_CONTINUE;
}
public handler_who(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED;
	}
	
	if(item > 7) return PLUGIN_HANDLED;
	
	show_players_rang(id, item)
	return PLUGIN_HANDLED;
}

public show_players_rang(id, item)
{		
	static menu_name[100], menu_item[80], tasta[2], menu;
	formatex(menu_name, charsmax(menu_name) - 1, "\wJucatorii cu grad\y %s\w.\nNumarul lor:\y %d.\w", rang[item], get_rang_players(item))
	menu = menu_create(menu_name, "handler_players_rang")
	static players[32], inum, player, a, numere;
	numere = 0
	get_players(players, inum)
	for(a = 0; a < inum; ++a)
	{
		player = players[a]
		if(get_user_flags(player) == rangflag2_val[item])
		{
			numere++
			formatex(menu_item, charsmax(menu_item), "\y%s", get_name(player))
			tasta[0] = numere
			tasta[1] = 0
			menu_additem(menu, menu_item, tasta)
		}
	}
	if(!get_rang_players(item))
	{
		color(id, ".v%s.g Nu sunt admini cu rankul de.e %s.g online pe server.", TAG, rang[item])
		return PLUGIN_HANDLED;
	}
	
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED;
}
public handler_players_rang(id)	return PLUGIN_HANDLED;
	
public get_rang_players(rank)
{
	if(rank > 8)	return -1;
	
	static players[32], inum, player, a, numarrank;
	numarrank = 0
	get_players(players, inum)
	
	for(a = 0; a < inum; ++a)
	{
		player = players[a]
		if(get_user_flags(player)== rangflag2_val[rank])	numarrank++
	}
	return numarrank;
}

stock get_name(id)
{
	static name[32];
	get_user_name(id, name, charsmax(name) - 1);
	return name;
}

stock color(const id, const input[], any:...)
{
	new count = 1, players[32];
	static msg[191]
	vformat(msg, 190, input, 3)
	
	replace_all(msg, 190, ".v", "^4")
	replace_all(msg, 190, ".g", "^1")
	replace_all(msg, 190, ".e", "^3")
	
	if(id) players[0] = id; else get_players(players, count, "ch")
	{
		for(new i = 0; i < count; i++)
		{
			if(is_user_connected(players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
				write_byte(players[i]);
				write_string(msg);
				message_end();
			}
		}
	}
}