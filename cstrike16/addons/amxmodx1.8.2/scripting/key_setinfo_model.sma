#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >

new const g_szModel[][] = {

    "model1.mdl",
    "model2.mdl"
}

#define VIP_FLAG ADMIN_LEVEL_H

public plugin_init( ) {

    register_plugin( "Admin Skin", "1.0", "DoNii" ) ;

    RegisterHam( Ham_Spawn, "player", "fw_HamSpawnPost", 1 ) ;

    register_forward( FM_SetClientKeyValue, "fw_SetClientKeyValue" )
}

public plugin_precache( ) {

    new szBuffer[ 64 ] ;
    for(new i;i<sizeof(g_szModel);i++)
    {
        formatex( szBuffer, charsmax( szBuffer ), "models/player/%s/%s.mdl", g_szModel, g_szModel ) ;
    
        precache_model( szBuffer ) ;
    }
}

public fw_HamSpawnPost( id ) {

    if( ! is_user_alive( id ) )
    return HAM_IGNORED ;

    if( ~ get_user_flags( id ) & VIP_FLAG ) 
    return HAM_IGNORED ;

    set_user_info( id, "model", g_szModel[random_num(0,charsmax(g_szModel)] ) ;
    
    return HAM_HANDLED ;
}

public fw_SetClientKeyValue( id, const infobuffer[ ], const key[ ] ) {

    if( ~ get_user_flags( id ) & VIP_FLAG )
    return FMRES_IGNORED ;

    if( equal( key, "model" ) ) {

        set_user_info( id, "model", g_szModel[random_num(0,charsmax(g_szModel)] ) ;
        return FMRES_SUPERCEDE ;
    }
    
    return FMRES_IGNORED ;
}
