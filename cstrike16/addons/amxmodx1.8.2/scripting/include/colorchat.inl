/*

	AMXBans, managing bans for Half-Life modifications
	Copyright (C) 2003, 2004  Ronald Renes / Jeroen de Rover
	
	Copyright (C) 2009, 2010  Thomas Kurz

	Color Chat Inc
	refer to http://forums.alliedmods.net/showthread.php?t=45753
	credits: teame06

	^x01 is Yellow
	^x03 is Team Color. Ie. Red (Terrorist) or blue (Counter-Terrorist) or grey (SPECTATOR or UNASSIGNED).
	^x04 is Green
*/

#if defined _colorchat_included
    #endinput
#endif
#define _colorchat_included

enum Color
{
	YELLOW = 1, // Yellow
	GREEN, // Green Color
	TEAM_COLOR, // Red, grey, blue
	GREY, // grey
	RED, // Red
	BLUE // Blue
};

new TeamInfo;
new SayText;
new MaxSlots;

new TeamName[][] = 
{
	"",
	"TERRORIST",
	"CT",
	"SPECTATOR"
};


public color_chat_init()
{
	TeamInfo = get_user_msgid("TeamInfo");
	SayText = get_user_msgid("SayText");
	MaxSlots = get_maxplayers();
}
/*
public cmdTest(id)
{
	ColorChat(id, YELLOW, "%s, This color is %s. It is the default color in Counter-Strike", "Hello", "yellow");
	ColorChat(id, GREEN, "%s, This color is %s.", "Hello", "green");
	ColorChat(id, GREY, "%s, This color is %s.", "Hello", "grey");
	ColorChat(id, BLUE, "%s, This color is %s.", "Hello", "blue");
	return PLUGIN_HANDLED;
}

public cmdTest2(id)
{
	ColorChat(0, RED, "%s, This color is %s.", "Hello", "red");
	ColorChat(0, TEAM_COLOR, "%s, This color is %s. The colors can be red or blue, or grey depending on the team.", "Hello", "the team color");
	ColorChat(0, YELLOW, "%s, This color is %s. ^x04This Color is %s. ^x03This is the %s", "Hello", "yellow", "green", "team color");
	return PLUGIN_HANDLED;
}

public client_putinserver(player)
{
	IsConnected[player] = true;
}

public client_disconnect(player)
{
	IsConnected[player] = false;
}
*/
public ColorChat(id, Color:type, const msg[], {Float,Sql,Result,_}:...)
{
	if( get_playersnum( ) < 1 )
		return;
	
	static message[256];

	switch(type)
	{
		case YELLOW: // Yellow
		{
			message[0] = 0x01;
		}
		case GREEN: // Green
		{
			message[0] = 0x04;
		}
		default: // White, Red, Blue
		{
			message[0] = 0x03;
		}
	}

	vformat(message[1], 251, msg, 4);

	// Make sure message is not longer than 192 character. Will crash the server.
	message[192] = '^0';
	
	replace_all( message, charsmax( message ), "!g", "^x04" );
	replace_all( message, charsmax( message ), "!t", "^x03" );
	replace_all( message, charsmax( message ), "!y", "^x01" );
	
	new team, ColorChange, index, MSG_Type;
	
	if(!id)
	{
		index = FindPlayer();
		MSG_Type = MSG_ALL;
	
	} else {
		MSG_Type = MSG_ONE;
		index = id;
	}
	
	team = get_user_team(index);	
	ColorChange = ColorSelection(index, MSG_Type, type);

	ShowColorMessage(index, MSG_Type, message);
		
	if(ColorChange)
	{
		Team_Info(index, MSG_Type, TeamName[team]);
	}
}

ShowColorMessage(id, type, message[])
{
	message_begin(type, SayText, _, id);
	write_byte(id);
	write_string(message);
	message_end();
}

Team_Info(id, type, team[])
{
	message_begin(type, TeamInfo, _, id);
	write_byte(id);
	write_string(team);
	message_end();

	return 1;
}

ColorSelection(index, type, Color:Type)
{
	switch(Type)
	{
		case RED:
		{
			return Team_Info(index, type, TeamName[1]);
		}
		case BLUE:
		{
			return Team_Info(index, type, TeamName[2]);
		}
		case GREY:
		{
			return Team_Info(index, type, TeamName[0]);
		}
	}

	return 0;
}

FindPlayer()
{
	new i = -1;

	while(i <= MaxSlots)
	{
		if(is_user_connected(++i))
		{
			return i;
		}
	}

	return -1;
}
