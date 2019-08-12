#include < amxmodx >
#include < amxmisc > 
#include < engine >
#include < hamsandwich >

#define VIP_FLAG ADMIN_LEVEL_H

#define MAX_PLAYERS         32

#define HUD_POSITION_X        -1.0
#define HUD_POSITION_Y        0.0

#define HUD_COLOR_RED        0
#define HUD_COLOR_GREEN        200
#define HUD_COLOR_BLUE        0

new g_iCvars[ 3 ];

new bool:g_bFreeVipTime;
new bool:g_bAlreadyVip[ MAX_PLAYERS + 1 ];

new g_iCacheFlags[ MAX_PLAYERS + 1 ];

const g_iFlagsBitsum = ( VIP_FLAG | ADMIN_RESERVATION | ADMIN_CHAT | ADMIN_LEVEL_F )

public plugin_init( )
{
    register_plugin( "Free VIP", "1.2", "DoNii" );

    register_event( "HLTV", "OnNewRound", "a", "1=0", "2=0" );

    RegisterHam( Ham_Spawn, "player", "fw_HamSpawnPost", 1 );
    
    g_iCvars[ 0 ] = register_cvar( "free_vip_on", "1" );
    g_iCvars[ 1 ] = register_cvar( "free_vip_start_time", "15" );
    g_iCvars[ 2 ] = register_cvar( "free_vip_end_time", "22" );
    
    set_task( 1.0, "CheckVips", _, .flags = "b" );
}

public plugin_natives( )
{
    register_library( "free_vip" );
    register_native( "is_free_vip_time", "native_is_free_vip_time", 0 );
}

public native_is_free_vip_time( iPlugin, iParams )
{
    return bool:g_bFreeVipTime;
}

public client_putinserver( id )
{
    g_bAlreadyVip[ id ] = ( get_user_flags( id ) & VIP_FLAG ) ? true : false;
}

public client_disconnect( id )
{
    ResetFlagsToDefault( id );
    
    g_bAlreadyVip[ id ] = false;
    g_iCacheFlags[ id ] = 0;
}

public OnNewRound( )
{
    if( ! get_pcvar_num( g_iCvars[ 0 ] ) )
    {
        return PLUGIN_CONTINUE;
    }
    
    g_bFreeVipTime = IsVipHour( get_pcvar_num( g_iCvars[ 1 ] ), get_pcvar_num( g_iCvars[ 2 ] ) );
    
    return PLUGIN_CONTINUE;
}

public CheckVips( )
{
    if( ! g_bFreeVipTime || ! get_pcvar_num( g_iCvars[ 0 ] ) )
    {
        return PLUGIN_HANDLED;
    }
    
    set_hudmessage( HUD_COLOR_RED, HUD_COLOR_GREEN, HUD_COLOR_BLUE, HUD_POSITION_X, HUD_POSITION_Y, 0, 6.0, 1.1 );
    show_hudmessage( 0, "Happy Hour > Free VIP Start: %dh^n\Happy Hour > Free VIP End: %dh", get_pcvar_num( g_iCvars[ 1 ] ), get_pcvar_num( g_iCvars[ 2 ] ) );
    
    return PLUGIN_CONTINUE;
}

public fw_HamSpawnPost( id )
{
    if( ! is_user_alive( id ) || is_user_bot( id ) || ! get_pcvar_num( g_iCvars[ 0 ] ) )
    return HAM_IGNORED;
    
    if( g_bFreeVipTime )
    {
        if( ( get_user_flags( id ) & ADMIN_ADMIN || get_user_flags( id ) & ADMIN_USER ) && ! g_bAlreadyVip[ id ] )
        {
            g_iCacheFlags[ id ] = get_user_flags( id ); // cache his flags
            SetVipFlag( id );
        }
    }
    
    else
    {
        if( ! g_bAlreadyVip[ id ] && ( get_user_flags( id ) & VIP_FLAG ) )
        {
            ResetFlagsBack( id ); // time expired so should the flag
        }
    }    
    return HAM_IGNORED;
}

ResetFlagsToDefault( id )
{
    remove_user_flags( id )
    set_user_flags( id, ADMIN_USER );
}

ResetFlagsBack( id )
{
    remove_user_flags( id );    
    set_user_flags( id, g_iCacheFlags[ id ] );
}

SetVipFlag( id )
{
    if( get_user_flags( id ) & ADMIN_USER )
    {
        remove_user_flags( id, ADMIN_USER );
    }
    set_user_flags( id, g_iFlagsBitsum );
}

bool:IsVipHour( iStart, iEnd )
{
    new iHour; time( iHour );
    return bool:( iStart < iEnd ? ( iStart <= iHour < iEnd ) : ( iStart <= iHour || iHour < iEnd ) )
}  
