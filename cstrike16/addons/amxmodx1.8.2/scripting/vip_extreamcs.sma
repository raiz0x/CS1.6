	#include <amxmodx>
	#include <fun>
	#include <engine>
	#include <hamsandwich>

	#define VIP_FLAG ADMIN_LEVEL_H
	#define TAG "!v[!nRESPAWN!v]!n"

	enum {
		SCOREATTRIB_ARG_PLAYERID = 1,
		SCOREATTRIB_ARG_FLAGS
	}
	enum ( <<= 1 ) {
		SCOREATTRIB_FLAG_NONE = 0,
		SCOREATTRIB_FLAG_DEAD = 1,
		SCOREATTRIB_FLAG_BOMB,
		SCOREATTRIB_FLAG_VIP
	}

	new jumpznum[33] = 0,bool:dozjump[33] = false,name[32]

	#pragma tabsize 0

	public plugin_init()
	{
		   register_message(get_user_msgid( "ScoreAttrib" ), "MessageScoreAttrib")

		   RegisterHam(Ham_Spawn, "player", "PlayerSpawn", 1 )

		   register_event( "DeathMsg","ev_DeathMsg", "a")

		   register_cvar("vip_jumps","2")
	}

	public client_putinserver(id)
	{
		if(!(is_user_bot(id)||is_user_hltv(id))&&is_user_connected(id)&&is_client_vip(id))
		{
			get_user_name(id,name,charsmax(name))

			jumpznum[id] = 0
			dozjump[id] = false

			xCoLoR(0,"%s VIP-UL!v %s!n , S-A CONECTAT PE SERVER!",TAG,name)
		}
	}
	public client_disconnect(id)
	{
		if(is_client_vip(id)&&!is_user_bot(id))
		{
		jumpznum[id] = 0
		dozjump[id] = false
		}
	}

	public PlayerSpawn(id)
	{
		if(is_user_alive(id)&&is_client_vip(id))
		{
			set_user_armor(id,100)

			give_item(id,"weapon_hegrenade")
			give_item(id,"weapon_hegrenade")
		}
	}

	public MessageScoreAttrib(iMsgId, iDest, iReceiver)
	{
		new iPlayer = get_msg_arg_int(SCOREATTRIB_ARG_PLAYERID)
		
		if(is_user_alive(iPlayer)&&is_client_vip(iPlayer))	set_msg_arg_int(SCOREATTRIB_ARG_FLAGS, ARG_BYTE, SCOREATTRIB_FLAG_VIP)
	}

	public ev_DeathMsg()
	{		
		new attacker = read_data( 1 ),victim=read_data(2),headshot=read_data(3);

		if( !(is_user_connected(attacker)||is_user_connected(victim))||attacker==victim )	return;
		
		if(headshot)	set_user_health(attacker,min(120,get_user_health(attacker)+15))
		else	set_user_health(attacker,min(120,get_user_health(attacker)+10))
	}

	public client_PreThink(id)
	{
		if(!is_user_alive(id) || !is_client_vip(id))	return PLUGIN_CONTINUE
		 
		new nzbut = get_user_button(id),ozbut = get_user_oldbutton(id)

		if((nzbut & IN_JUMP) && !(get_entity_flags(id) & FL_ONGROUND) && !(ozbut & IN_JUMP))
		{
			if (jumpznum[id] < get_cvar_num("vip_jumps"))
			{
				dozjump[id] = true
				jumpznum[id]++

				return PLUGIN_CONTINUE
			}
		}
		if((nzbut & IN_JUMP) && (get_entity_flags(id) & FL_ONGROUND))
		{
			jumpznum[id] = 0

			return PLUGIN_CONTINUE
		}    

		return PLUGIN_CONTINUE
	}
	public client_PostThink(id)
	{
		if(!is_user_alive(id)||!is_client_vip(id))	return PLUGIN_CONTINUE

		if(dozjump[id] == true)
		{
			new Float:vezlocityz[3]    
			entity_get_vector(id,EV_VEC_velocity,vezlocityz)
			vezlocityz[2] = random_float(265.0,285.0)
			entity_set_vector(id,EV_VEC_velocity,vezlocityz)
			dozjump[id] = false
			return PLUGIN_CONTINUE
		}    
		return PLUGIN_CONTINUE
	}  

	is_client_vip(id)
	{
		if((get_user_flags(id) & VIP_FLAG))	return true

		return false
	}

	stock xCoLoR(id, String[], any:...) 
	{
		static szMesage[192];
		vformat(szMesage, charsmax(szMesage), String, 3);
		
		replace_all(szMesage, charsmax(szMesage), "!n", "^1");
		replace_all(szMesage, charsmax(szMesage), "!e", "^3");
		replace_all(szMesage, charsmax(szMesage), "!v", "^4");
		replace_all(szMesage, charsmax(szMesage), "!e2", "^0");
		
		static g_msg_SayText = 0;
		if(!g_msg_SayText)	g_msg_SayText = get_user_msgid("SayText");
		
		new Players[32], iNum = 1, i;

		if(id) Players[0] = id;
		else get_players(Players, iNum, "ch");
		
		for(--iNum; iNum >= 0; iNum--) 
		{
			i = Players[iNum];
			
			message_begin(MSG_ONE_UNRELIABLE, g_msg_SayText, _, i);
			write_byte(i);
			write_string(szMesage);
			message_end();
		}
	}
