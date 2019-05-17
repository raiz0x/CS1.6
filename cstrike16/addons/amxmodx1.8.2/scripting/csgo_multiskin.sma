/*
			set_pev(player_ent[id],pev_skin,0)//0 nr la model
			set_pev(player_ent[id],pev_body,0) // pe corp asta..la noob??
			set_pev(entity, pev_sequence,1)
pev(entindex, pev_body)

entity_set_int(entindex, EV_INT_body, num)
entity_get_int(entindex, EV_INT_body)
			set_animation(id,random_num(1,2))
			dllfunc( DLLFunc_ClientUserInfoChanged, id, engfunc( EngFunc_GetInfoKeyBuffer, id ) );

    iWep = give_item(id, "your_weapon")
    engfunc(EngFunc_SetModel, iWep, "P MODEL")
    set_pev(iWep, pev_body, your submodel number)
    fm_set_entity_visibility(iWep, 1)
    set_pev(id, pev_viewmodel2, "")  

SendWeaponAnim(id, iAnim)
{
    set_pev(id, pev_weaponanim, iAnim)

    message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
    write_byte(iAnim)
    write_byte(pev(id,pev_body))
    message_end()
}
*/

#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <engine>

#pragma tabsize 0

new ak47[33]=""

enum _:Data
{
	Nume_Model[35],
	v_Model[65],
	p_Model[65],
	w_Model[65],//csf..nu e necesar, da dacă ai la model poți pune
	NrBMP//numerotarea e de la 1 până la X-(setat mai jos)
}

new const INFOS[][Data]=
{											   //aici e w_, da poți lăsa așa - "" dacă nu vrei să pui, sau nu are
	{ "AK-47 MODAT", "v_ak47_mod", "p_ak47_mod", "", 10 }//10 .bmp(texturi) incluse în skin..
}

public plugin_init()
{
	register_clcmd("say /ak47","AK")
	register_clcmd("say_team /ak47","AK")

	register_event("CurWeapon","Event_CurWeapon","be","1=1")
	register_forward(FM_SetModel, "fw_SetModel")
}

public plugin_precache()
{
	for(new i;i<sizeof(INFOS);i++)//charsmax
	{
		if(!equal(INFOS[i][v_Model],""))	precache_player_model(INFOS[i][v_Model])
		if(!equal(INFOS[i][p_Model],""))	precache_player_model(INFOS[i][p_Model])
		if(!equal(INFOS[i][w_Model],""))	precache_player_model(INFOS[i][w_Model])
	}
}
precache_player_model(szModel[])
{
	static szFile[128]
	formatex(szFile,charsmax(szFile),"models/ak47/%s.mdl",szModel)
	precache_model(szFile)

//defined
	//if(contain(charsmax(szFile)-5,"T")!=-1)
	replace(szFile, charsmax(szFile), ".mdl", "T.mdl")
    if(file_exists(szFile))	precache_model(szFile)
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id)||equal(ak47[id],""))	return
	if(!equal(INFOS[ak47[id]][v_Model],""))	set_pev(id,pev_viewmodel2,INFOS[ak47[id]][v_Model])
	if(!equal(INFOS[ak47[id]][p_Model],""))	set_pev(id,pev_weaponmodel2,INFOS[ak47[id]][p_Model])
	engclient_cmd(id,"weapon_ak47")
}

public fw_SetModel(entity, model[])
{
    if(!is_valid_ent(entity))
        return FMRES_IGNORED

    static iOwner
    iOwner = entity_get_edict(entity, EV_ENT_owner)
	
    if(!equal(model,INFOS[ak47[iOwner]][w_Model])&&!equal(INFOS[ak47[iOwner]][w_Model],""))//xd
        return FMRES_IGNORED

    new className[33]
    entity_get_string(entity, EV_SZ_classname, className, 32)

    if(equal(className, "weaponbox") || equal(className, "armoury_entity") || equal(className, "grenade"))
    {
        entity_set_model(entity,INFOS[ak47[iOwner]][w_Model])
        return FMRES_SUPERCEDE
    }
    return FMRES_IGNORED
}

public client_putinserver(id)	ak47[id]=EOS
public client_disconnect(id)	ak47[id]=EOS

public AK(id)
{
	new menu=menu_create("Alege un Skin pentru AK47","choosed_options")
	new callback=menu_makecallback("hook_shop")//idk
	static text[125],i,tasta[2]

	for(i=0;i<sizeof INFOS;i++)
	{
		if(ak47[id]==i)	formatex(text,charsmax(text),"\d%s\w [\rSELECTAT\w]",INFOS[i][Nume_Model])
		else	formatex(text,charsmax(text),"\r%s",INFOS[i][Nume_Model])

		tasta[0]=i
		tasta[1]=0
		menu_additem(menu, text, tasta, _, callback)
	}

	menu_display(id,menu,0)
}
public hook_shop(id,menu,item)
{
	if(item==MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
 
	if(!is_user_alive(id)||ak47[id]==item)	return ITEM_DISABLED
   
	return ITEM_ENABLED
}

public choosed_options(id,menu,item)
{
	if(item==MENU_EXIT||!is_user_alive(id))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	new rand	//numărătoarea e de la 1 cică
	rand=random_num(1,INFOS[item][NrBMP])

	if(ak47[id]==rand)
	{
		client_print(id,print_chat,"* Ai deja %s",INFOS[rand][Nume_Model])
		return PLUGIN_HANDLED
	}

	client_print(id,print_chat,"* Ai ales cu succes modelul %s cu skinul %d din %d",INFOS[rand][Nume_Model],rand,INFOS[rand][NrBMP])//clamp/max/charsmax...
	ak47[id]=rand
	new iWep
	iWep = give_item(id, "weapon_ak47")
	engfunc(EngFunc_SetModel, iWep, INFOS[ak47[id]][p_Model])
	set_pev(iWep, pev_body, ak47[id])
	set_pev(INFOS[ak47[id]][p_Model],pev_skin,ak47[id])
	Event_CurWeapon(id)//xx
	//eng

	menu_destroy(menu)
	return PLUGIN_HANDLED
}
