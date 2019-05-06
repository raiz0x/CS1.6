#include <amxmodx>
#include <amxmisc>

#include <fvault>
// Pruning player agree/decline after 15 days of not being updated
//	15 days * 24 hours * 60 minutes * 60 seconds = 15 days in seconds
//		15 * 24 * 60 * 60
#define ZILE_CURATARE	15	//dupa 15 zile ii sterge pe cei care au folosit un cod din promo, ca sa poata folosii altul dinou

native csgor_is_user_logged(Player);
native csgor_get_user_points(Player);
native csgor_set_user_points(Player, Points);

new const FVN[] = "PCodes";

new Array: g_PromoCodes;
new Array: g_PromoCodesPoints;

new cod_folosit[33];
new name[33] [32];

public plugin_precache()
{
	new ConfigsDir[128];
	get_configsdir(ConfigsDir, charsmax(ConfigsDir));
	add(ConfigsDir, charsmax(ConfigsDir), "/promocode.ini");

	if(!file_exists(ConfigsDir))
	{
		log_amx("Couldn't find ^"%s^"", ConfigsDir);
		return;
	}

	g_PromoCodes = ArrayCreate(64, 1);
	g_PromoCodesPoints = ArrayCreate(64, 1);

	new File = fopen(ConfigsDir, "r");
	if(File)
	{
		new Buffer[128], CodeName[8], CodePoints[10];
		while(!feof(File))
		{
			fgets(File, Buffer, charsmax(Buffer))
			trim(Buffer);
			
			if(!Buffer[0] || Buffer[0] ==';' || Buffer[0] == '#' || (Buffer[0] == '/' && Buffer[1] == '/'))	continue;

			parse(Buffer, CodeName, charsmax(CodeName), CodePoints, charsmax(CodePoints));
			
			ArrayPushString(g_PromoCodes, CodeName);
			
			for(new i = 0; i < sizeof(CodePoints); i++)	ArrayPushCell(g_PromoCodes, CodePoints[i]);//generare random xd
		}
	}
	fclose(File);
}

public plugin_init()	register_clcmd("say", "handle_say"),register_clcmd("say_team", "handle_say");

public client_authorized(id)	get_user_name(id, name[id], charsmax(name [])),LoadData(id);

public handle_say(Player)
{
	new Args[128];
	read_args(Args, charsmax(Args));
	if(!Args[0])	return PLUGIN_CONTINUE;
	remove_quotes(Args[0]);

	new szCmd[32], szCode[32], szTemp[10];
	parse(Args, szCmd, charsmax(szCmd), szCode, charsmax(szCode));

	if(equal(szCmd, "/promocode") && csgor_is_user_logged(Player))
	{
		new i;
		for(i = 0; i < ArraySize(g_PromoCodes); i++)
		{
			ArrayGetString(g_PromoCodes, i, szTemp, charsmax(szTemp));

			if(equal(szCode, szTemp) && cod_folosit[Player] > 0)
			{
				for(i = 0; i < ArraySize(g_PromoCodesPoints); i++)
				{
					csgor_set_user_points(Player, csgor_get_user_points(Player) + ArrayGetCell(g_PromoCodesPoints, i));
					cod_folosit[Player] = 1;
					SaveData(Player);
				}
				return PLUGIN_HANDLED;
			}
		}
	}

	return PLUGIN_CONTINUE;
}

public SaveData(id)	fvault_set_data(FVN, name[id], cod_folosit[id]);
public LoadData(id)
{
	new data[125];
	if(fvault_get_data(FVN, name[id], data, charsmax(data)))	cod_folosit[id] = str_to_num(data);
	else	cod_folosit[id] = 0;
}

public plugin_end()	fvault_prune(FVN, _, get_systime() - (ZILE_CURATARE * 24 * 60 * 60));//0	to cfg
