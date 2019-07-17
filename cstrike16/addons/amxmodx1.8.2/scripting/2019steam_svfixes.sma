#include <amxmodx>
new g_bwSend, bool:g_Enable=false;
public plugin_init() {
    if(get_cvar_pointer("mp_scoreboard_showhealth")){register_event_ex("Account", "Event", RegisterEvent_Single);g_Enable=true;}
    if(get_cvar_pointer("mp_scoreboard_showmoney")){register_event_ex("HealthInfo", "Event", RegisterEvent_Single);g_Enable=true;}
}
public Event(id) {
    if(!is_user_connected(id))return 0;
    if(!(g_bwSend & (1 << (id & 31))))return 1;
    return 0;
}
public client_authorized(id){
    if(!g_Enable)return;
    g_bwSend &= ~(1 << (id & 31));
    if(is_user_bot(id)||is_user_hltv(id))return;
    query_client_cvar(id, "sv_version", "check_sv_version");
}
public check_sv_version(id,const cvar[],const value[]){
    new a = strlen(value);
    if(a<21)return;
    if(str_to_num(value[a-4])>=8244)g_bwSend |= (1 << (id & 31));
}
