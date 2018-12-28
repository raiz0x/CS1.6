#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>

#define TIME 35.0

new Float:player_origin[3][33];

public plugin_init()	RegisterHam(Ham_Spawn, "player", "e_Spawn", 1);
 
public e_Spawn(id)
{
     if(is_user_alive(id)&&!task_exists(id+69))
     {
           pev(id, pev_origin, player_origin[id]);
           set_task(TIME, "check_afk", id+69);
     }
}
public check_afk(id)
{
	if(is_user_alive(id)&&!is_user_bot(id)&&same_origin(id)&&task_exists(id+69))
	{
		user_kill(id,1);
		remove_task(id+69)
	}
}
public same_origin(id)
{
       new Float:origin[3];
       pev(id, pev_origin, origin);

       for(new i = 0; i < 3; i++)	if(origin[i] != player_origin[i][id])	return 0;
       return 1;
}

public client_disconnect(id)	if(!is_user_bot(id)&&task_exists(id+69))	remove_task(id+69)
