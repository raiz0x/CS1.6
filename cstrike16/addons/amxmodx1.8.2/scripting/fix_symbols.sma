#include <amxmodx>

new args[195]

public plugin_init()
{
	register_clcmd("say","chat_handle")
	register_clcmd("say_team","chat_handle2")
}
public chat_handle(id)
{
	read_args(args,charsmax(args))
	remove_quotes(args)

	if(containi(args,"%")!=-1)
	{
		replace_all(args,charsmax(args),"%","％")
		engclient_cmd(id,"say",args)
	}
	if( containi(args,"#")!=-1)
	{
		replace_all(args,charsmax(args),"#","﹟")
		engclient_cmd(id,"say",args)
	}
}
public chat_handle2(id)
{
	read_args(args,charsmax(args))
	remove_quotes(args)

	if(containi(args,"%")!=-1)
	{
		replace_all(args,charsmax(args),"%","％")
		engclient_cmd(id,"say_team",args)
	}
	if(containi(args,"#")!=-1)
	{
		replace_all(args,charsmax(args),"#","﹟")
		engclient_cmd(id,"say_team",args)
	}
}
