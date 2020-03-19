#include <amxmodx>
#include <amxmisc>
#include <hamsandwich> 

#define PLUGIN "Free VIP" 
#define VERSION "1.0" 
#define AUTHOR "Chakalaka In You. Boom Boom" 

#define FLAG_VF "a" //ADMIN_IMMUNITY			flagul atribuit pentru a avea VIP

#define ORA_START 20
#define ORA_SFARSIT 24

new g_FreeVip[33]; 
new const Protected_Flags[][]=
{
	"lkcvnmmcoqp",
	"kwqljdklsvnjk",
	"ddasdvrqasdas"
}
new last_flags[33][35]

public plugin_init() 
{ 
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1) 
}

public client_putinserver(id)
{
	if(is_user_bot(id)||is_user_hltv(id)||!is_user_connected(id)||!is_user_admin(id))	return
	g_FreeVip[id]=false
	last_flags[id]=stocare_flage_len(id)
}
public client_disconnect(id)	if(g_FreeVip[id])	g_FreeVip[id]=false

public fwHamPlayerSpawnPost(id) 
{ 
	new Ora[3]
	get_time("%H",Ora,2)
	
	new iTime = str_to_num(Ora) 
	if( ORA_START <= iTime <= ORA_SFARSIT ) 
	{
		client_printcolor(id, "^1[^4Event^1] ^1Free VIP On!^1^4 Have Fun!")//msg already bool?
		
		if(g_FreeVip[id])	return
		if( !Protejat(id) )
		{ 
			remove_user_flags(id); 
			set_user_flags(id, read_flags(FLAG_VF));
		}
		else	set_user_flags(id,read_flags(last_flags[id])&&read_flags(FLAG_VF))
		g_FreeVip[id] = true;
	} 
	else
	{
		client_printcolor(id, "^1[^4Event^1] ^1Free VIP Off!")
		
		if( !g_FreeVip[id] )	return
		if(!Protejat(id))
		{
			remove_user_flags(id); 
			set_user_flags(id, read_flags("z"));
		}
		else
		{
			remove_user_flags(id)
			set_user_flags(id,read_flags(last_flags[id]))
		}
		g_FreeVip[id] = false;
	} 
}

bool: Protejat(id)
{
	for(new i;i<charsmax(Protected_Flags);i++)	if( has_flag(id,FLAG_VF)||get_user_flags(id)==read_flags(Protected_Flags[i]) )	return true
	return false
}

stock stocare_flage_len(id)
{
	new flage[35]
	get_flags(get_user_flags(id),flage,charsmax(flage))
	return flage
}
stock client_printcolor(const id, const input[], any:...)
{
	new iCount = 1, iPlayers[32]
	static szMsg[191]

	vformat(szMsg, charsmax(szMsg), input, 3)
	replace_all(szMsg, 190, "!g", "^4")
	replace_all(szMsg, 190, "!n", "^1")
	replace_all(szMsg, 190, "!t", "^3")
	replace_all(szMsg, 190, "!n2", "^0")

	if(id) iPlayers[0] = id
	else get_players(iPlayers, iCount, "ch")
	
	for (new i = 0; i < iCount; i++)
	{
		if(is_user_connected(iPlayers[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, iPlayers[i])
			write_byte(iPlayers[i])
			write_string(szMsg)
			message_end()
		}
	}
}
