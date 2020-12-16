#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#pragma tabsize 0

native zp_get_user_ammo_packs(id)
native zp_set_user_ammo_packs(id,amount)
native zp_get_user_zombie(id)
native zp_has_round_started(id)

enum _:ES{
	NUME_SKIN[35],
	NUME_MODEL[35],
	AMMO_COST,
	ACCESS_SKIN,
	TEAM
}
//modelele trebuie să le pui în /cstrike/models/NUME_MODEL/NUME_MODEL.mdl (dacă sunt și T nu e problemă!)
//ce e cu -1 va anula criteriul
//dacă vrei să fie accesibil la mai multe flage, delimitezi prin "|" dacă vrei să fie aces doar unor anumite flage delimitezi cu "&"	(pt a forța, introduci între "()")
static const	g_ES[][ES]={
					//	  NUME SKIN			NUME MODEL		PREȚ		FLAG ACCESS									ECHIPA	(2=CT/OM)
					{	"NUME SKIN 1",		"model1",		100,		-1,											2		},
					{	"NUME SKIN 2",		"model2",		-1,			ADMIN_LEVEL_H,								2		},
					{	"NUME SKIN 3",		"model3",		1223,		ADMIN_LEVEL_H|ADMIN_SLAY,					2		},
					{	"NUME SKIN 4",		"model4",		13,			ADMIN_LEVEL_H&ADMIN_SLAY,					2		},
					{	"NUME SKIN 5",		"model5",		1,			(ADMIN_LEVEL_H&ADMIN_SLAY)|ADMIN_IMMUNITY,	2		},
					{	"NUME SKIN 6",		"model6",		1,			(ADMIN_LEVEL_H&ADMIN_BAN),					2		},
					{	"NUME SKIN 7",		"model7",		122,		(ADMIN_LEVEL_H|ADMIN_KICK),					2		}
				},
				comanda_chat_shop[]="/skins",
				titlu_meniu_shop[]="Diferite skin-uri^n^tAi\r %d\w ammo packs\y",//sau\R \b
				chat_tag[]="[SKIN]",
				Float:VERIFY_SMT=5.0,	//la cât timp după spawn, să verifice dacă este om & are model, ca să-l seteze(spawn! nu rundă nouă!)

				PLAYERMODEL_CLASSNAME[] = "ent_playermodel"

static fmcc[120],g_MenuCallback
new pmff[33][125],g_player_model[33][32],g_ent_playermodel[33]

public plugin_init(){
    RegisterHam( Ham_Spawn, "player", "fw_PlayerSpawn", 1 )
    register_forward( FM_AddToFullPack, "fw_AddToFullPack" )
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0")
    register_message( get_user_msgid( "ClCorpse" ), "message_clcorpse" )

	formatex(fmcc,charsmax(fmcc),"say %s",comanda_chat_shop)
	register_clcmd(fmcc,"SHOP")
	formatex(fmcc,charsmax(fmcc),"say_team %s",comanda_chat_shop)
	register_clcmd(fmcc,"SHOP")

	g_MenuCallback = menu_makecallback( "menuitem_callback" )
}
public plugin_precache()	for(new i=0; i < sizeof g_ES; i++)	precache_player_model(g_ES[i][NUME_MODEL])
precache_player_model(szModel[]){
	static szFile[128]
	formatex(szFile, charsmax(szFile), "models/player/%s/%s.mdl", szModel, szModel)
	precache_model(szFile)

	replace(szFile, charsmax(szFile), ".mdl", "T.mdl")
	if(file_exists(szFile))	precache_model(szFile)
}

public client_putinserver(id)	if(is_user_connected(id)&&!is_user_bot(id)||!is_user_hltv(id))	pmff[id]=""
public client_disconnect( id )	if ( fm_has_custom_model( id ) )	fm_remove_model_ents( id )

public event_new_round()	arrayset(pmff[EOS],0,charsmax(pmff[]))

public SHOP(id){
	if(!is_user_alive(id)||!equali(pmff[id],"")||zp_get_user_zombie(id))	return
	static menu,formtm[120],formim[255];	formatex(formtm,charsmax(formtm),"%s",titlu_meniu_shop,zp_get_user_ammo_packs(id))	//%s - argument, am pus x2 %s pt că mai este unul sus în titlu meniu
	menu=menu_create(formtm,"MH")
	for(new i=0;i<sizeof g_ES;i++){
		if((zp_get_user_ammo_packs(id)<g_ES[i][AMMO_COST])&&g_ES[i][AMMO_COST]!=-1){
			if(!(get_user_flags(id)&g_ES[i][ACCESS_SKIN])&&g_ES[i][ACCESS_SKIN]!=-1)	formatex(formim,charsmax(formim),"\d%s\y (\rNU AI AMMO SUFICIENTI\y)\r [\wNU AI ACCES\r]",g_ES[i][NUME_SKIN])
			else	formatex(formim,charsmax(formim),"\d%s\y (\rNU AI AMMO SUFICIENTI\y)",g_ES[i][NUME_SKIN])
			format(formim,charsmax(formim),"%s%s",formim,get_user_team(id)!=g_ES[id][TEAM]?" \w{\yECHIPA NECORESPUNZATOARE\w}":"")
		}
		else{
			if(!(get_user_flags(id)&g_ES[i][ACCESS_SKIN])&&g_ES[i][ACCESS_SKIN]!=-1)	formatex(formim,charsmax(formim),"\d%s\y [\rNU AI ACCES\y]",g_ES[i][NUME_SKIN])
			if(formim[0])	format(formim,charsmax(formim),"%s%s%s",formim,get_user_team(id)!=g_ES[id][TEAM]?" \w{\yECHIPA NECORESPUNZATOARE\w}":"",g_ES[i][AMMO_COST]==-1?" \r*\wMOKA\r*":"")
			else	formatex(formim,charsmax(formim),"%s%s%s",g_ES[i][NUME_SKIN],get_user_team(id)!=g_ES[id][TEAM]?" \w{\yECHIPA NECORESPUNZATOARE\w}":"",g_ES[i][AMMO_COST]==-1?" \r*\wMOKA\r*":"")
		}
		if(formim[0])	menu_additem(menu,formim,.callback=g_MenuCallback)
		else	menu_additem(menu,g_ES[i][NUME_SKIN],.callback=g_MenuCallback)
	}
	menu_display(id,menu,0)
}
public menuitem_callback( id, menu, item ){
	if ( !is_user_alive( id )||zp_get_user_ammo_packs(id)<g_ES[item][AMMO_COST]&&g_ES[item][AMMO_COST]!=-1||!(get_user_flags(id)&g_ES[item][ACCESS_SKIN])&&g_ES[item][ACCESS_SKIN]!=-1||get_user_team(id)!=g_ES[item][TEAM] )	return ITEM_DISABLED;
	return ITEM_IGNORE;
}
public MH(id,menu,item){
	if(!is_user_alive(id)||!equali(pmff[id],"")||zp_get_user_zombie(id))	return
	pmff[id]=""
	zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id)-item)
	client_print(0,print_chat,"%s %s tocmai si-a achizitionat skin-ul %s pentru %d ammo%s",chat_tag,_get_user_name(id),g_ES[item][NUME_SKIN],g_ES[item][AMMO_COST]==-1?0:g_ES[item][AMMO_COST],g_ES[item][ACCESS_SKIN]!=-1?" (SPECIAL SKIN)":"")
	formatex(pmff[id],charsmax(pmff[]),"models/player/%s/%s.mdl",g_ES[item][NUME_MODEL],g_ES[item][NUME_MODEL])
	set_player_model(id)
}

public fw_PlayerSpawn( id )	if(is_user_alive(id))	set_task(VERIFY_SMT,"MSC",id)
public MSC(id){
	if ( !equali(pmff[id],"") )	set_player_model( id )
	else if ( fm_has_custom_model( id ) )	fm_remove_model_ents( id )
}

public fw_AddToFullPack( es, e, ent, host, hostflags, player ){
    if ( player ) return FMRES_IGNORED;
    if ( ent == g_ent_playermodel[host] )	return FMRES_SUPERCEDE;
    return FMRES_IGNORED;
}

public message_clcorpse(){
    static id;id = get_msg_arg_int( 12 )
    if ( fm_has_custom_model( id ) )	set_msg_arg_string( 1, g_player_model[id] )
}

stock set_player_model(id){
	set_pev( id, pev_rendermode, kRenderTransTexture )
	set_pev( id, pev_renderamt, 1.0 )
	if ( !pev_valid( g_ent_playermodel[id] ) ){
		g_ent_playermodel[id] = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "info_target" ) )
		if ( !pev_valid( g_ent_playermodel[id] ) ) return;
		set_pev( g_ent_playermodel[id], pev_classname, PLAYERMODEL_CLASSNAME )
		set_pev( g_ent_playermodel[id], pev_movetype, MOVETYPE_FOLLOW )
		set_pev( g_ent_playermodel[id], pev_aiment, id )
		set_pev( g_ent_playermodel[id], pev_owner, id )
	}
	engfunc( EngFunc_SetModel, g_ent_playermodel[id], pmff[id] )
}
stock fm_has_custom_model( id )	return pev_valid( g_ent_playermodel[id] ) ? true : false;
stock fm_remove_model_ents( id ){
    set_pev( id, pev_rendermode, kRenderNormal )
    if ( pev_valid( g_ent_playermodel[id] ) ){
        engfunc( EngFunc_RemoveEntity, g_ent_playermodel[id] )
        g_ent_playermodel[id] = 0
    }
	pmff[id]=""
}
stock _get_user_name(id){
	static name[33];
	return is_user_connected(id)?get_user_info(id,"name",name,charsmax(name)):copy(name,charsmax(name),"NO NAME")
}
