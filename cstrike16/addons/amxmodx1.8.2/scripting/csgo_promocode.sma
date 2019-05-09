#include <amxmodx>
#include <amxmisc>

#include <fvault>
// Pruning player agree/decline after 15 days of not being updated
//	15 days * 24 hours * 60 minutes * 60 seconds = 15 days in seconds
//		15 * 24 * 60 * 60
#define ZILE_CURATARE	15	//dupa 15 zile ii sterge pe cei care au folosit un cod din promo, ca sa poata folosii altul dinou

#include <csgo_remake>

new const FVN[] = "PCodes";
//enum data [35]
new Array: g_PromoCodes;
new Array: g_PromoCodesPoints;

new cod_folosit[33] = 0;
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

	g_PromoCodes = ArrayCreate(10);
	g_PromoCodesPoints = ArrayCreate(10);//1,32

	new File = fopen(ConfigsDir, "rt");//csf
	if(!File)	return;//...
	if(File)
	{
		new Buffer[120], CodeName[10], CodePoints[10];
		while(!feof(File))
		{
			fgets(File, Buffer, charsmax(Buffer))
			if(!Buffer[0] || Buffer[0] == ';' || Buffer[0] == '#' || (Buffer[0] == '/' && Buffer[1] == '/'))	continue;
			trim(Buffer);//xd
			parse(Buffer, CodeName, charsmax(CodeName), CodePoints, charsmax(CodePoints));

			ArrayPushString(g_PromoCodes, CodeName);//str enforce

			for(new a; a < sizeof(CodePoints); a++)	ArrayPushCell(g_PromoCodesPoints, CodePoints[a]);//generare random xd
		}
		fclose(File);
	}
}

public plugin_init()	register_clcmd("say", "handle_say"),register_clcmd("say_team", "handle_say");

public client_authorized(id)	get_user_name(id, name[id], charsmax(name [])),LoadData(id);

public handle_say(Player)
{
	new Args[125];
	read_args(Args, charsmax(Args));
	if(!Args[0])	return PLUGIN_CONTINUE;//xD
	remove_quotes(Args[0]);

	new szCmd[32], szCode[32], szTemp[10];
	parse(Args, szCmd, charsmax(szCmd), szCode, charsmax(szCode));

	if(equal(szCmd, "/promocode"))
	{
		if(!csgor_is_user_logged(Player))
		{
			client_print(Player, print_chat, "Se pare ca nu esti logat.");
			return PLUGIN_HANDLED;
		}
		for(new b; b < ArraySize(g_PromoCodes); b++)
		{
			ArrayGetString(g_PromoCodes, b, szTemp, charsmax(szTemp));

			if(equal(szCode, szTemp))
			{
				if(cod_folosit[Player] == 1)
				{
					client_print(Player, print_chat, "Se pare ca ai activat recent un cod. Asteapta sa expire.");
					return PLUGIN_HANDLED;
				}
				for(new c; c < ArraySize(g_PromoCodesPoints); c++)
				{
					client_print(Player, print_chat, "Felicitari! Ai activat cu succes codul ^"%s^" fiind unul valid, si ai primit +%d punct%s", szTemp, ArrayGetCell(g_PromoCodesPoints, c), ArrayGetCell(g_PromoCodesPoints, c) == 1 ? "" : "e");
					csgor_set_user_points(Player, csgor_get_user_points(Player) + ArrayGetCell(g_PromoCodesPoints, c));
					cod_folosit[Player] = 1;
					SaveData(Player);
					//ArrayClear(g_PromoCodes);
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
	new data[120];
	if(fvault_get_data(FVN, name[id], data, charsmax(data)))	cod_folosit[id] = str_to_num(data);
	else	cod_folosit[id] = 0;
}

public plugin_end()
{
	fvault_prune(FVN, _, get_systime() - (ZILE_CURATARE * 24 * 60 * 60));//0	road2cfg

	ArrayDestroy(g_PromoCodes);
	ArrayDestroy(g_PromoCodesPoints);
}
