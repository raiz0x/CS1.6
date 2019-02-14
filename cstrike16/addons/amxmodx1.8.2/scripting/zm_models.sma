#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>

new const ZOMBIE_MODEL[] = "zombie" // The model we're gonna use for zombies
new const PLAYERMODEL_CLASSNAME[] = "ent_playermodel"
new const WEAPONMODEL_CLASSNAME[] = "ent_weaponmodel"

new g_player_model[33][32] // player's model name (string)
new g_ent_playermodel[33] // playermodel entity following this player
new g_ent_weaponmodel[33] // weaponmodel entity following this player
new g_zombie[33] // whether the player is a zombie
new g_glow[33] // whether the player has glow

/*================================================================================
 [Plugin Start]
=================================================================================*/

public plugin_precache()
{
    new modelpath[100]
    formatex( modelpath, charsmax( modelpath ), "models/player/%s/%s.mdl", ZOMBIE_MODEL, ZOMBIE_MODEL )
    engfunc( EngFunc_PrecacheModel, modelpath )
}

public plugin_init()
{
    register_plugin( "Player Model Changer Example", "0.3", "MeRcyLeZZ" )
    
    RegisterHam( Ham_Spawn, "player", "fw_PlayerSpawn", 1 )
    register_forward( FM_AddToFullPack, "fw_AddToFullPack" )

    register_event( "CurWeapon", "event_curweapon", "be", "1=1" )
    register_message( get_user_msgid( "ClCorpse" ), "message_clcorpse" )
    
    register_clcmd( "say /glow", "clcmd_sayglow" )
}

/*================================================================================
 [Player Spawn Event]
=================================================================================*/

public fw_PlayerSpawn( id )
{   
    // Not alive or didn't join a team yet
    if ( !is_user_alive( id ) || !cs_get_user_team( id ) )
        return;
    
    // Set to zombie if on Terrorist team
    g_zombie[id] = cs_get_user_team( id ) == CS_TEAM_T ? true : false;
    
    // Check if the player is a zombie
    if ( g_zombie[id] )
    {
        // Store our custom model in g_player_model[id]
        copy( g_player_model[id], charsmax( g_player_model[] ), ZOMBIE_MODEL )
        
        // Set the model on our playermodel entity
        fm_set_playermodel_ent( id, g_player_model[id] )
    }
    // Not a zombie, but still has a custom model
    else if ( fm_has_custom_model( id ) )
    {
        // Reset it back to default
        fm_remove_model_ents( id )
    }
}

/*================================================================================
 [Add to Full Pack Forward]
=================================================================================*/

public fw_AddToFullPack( es, e, ent, host, hostflags, player )
{
    // Narrow down our matches a bit
    if ( player ) return FMRES_IGNORED;
    
    // Check if it's one of our custom model ents being sent to its owner
    if ( ent == g_ent_playermodel[host] || ent == g_ent_weaponmodel[host] )
        return FMRES_SUPERCEDE;
    
    return FMRES_IGNORED;
}

/*================================================================================
 [Weapon Change Event]
=================================================================================*/

public event_curweapon( id )
{
    // Check if the player is using a custom player model
    if ( fm_has_custom_model( id ) )
    {
        // Update weapon model on entity
        fm_set_weaponmodel_ent( id )
    }
}

/*================================================================================
 [ClCorpse Message]
=================================================================================*/

public message_clcorpse()
{
    // Get player's id
    static id
    id = get_msg_arg_int( 12 )
    
    // Check if the player is using a custom player model
    if ( fm_has_custom_model( id ) )
    {
        // Set correct model on player corpse
        set_msg_arg_string( 1, g_player_model[id] )
    }
}

/*================================================================================
 [Client Disconnect Event]
=================================================================================*/

public client_disconnect( id )
{
    // Check if the player was using a custom player model
    if ( fm_has_custom_model( id ) )
    {
        // Remove custom entities
        fm_remove_model_ents( id )
    }
}

/*================================================================================
 [Client Command: Say /Glow]
=================================================================================*/

public clcmd_sayglow( id )
{
    // Turn glow on/off
    g_glow[id] = !( g_glow[id] )
    
    // Check if the player is using a custom player model
    if ( fm_has_custom_model( id ) )
    {
        // Check if the player has glow
        if ( g_glow[id] )
        {
            // Set glow on playermodel entity
            fm_set_rendering( g_ent_playermodel[id], kRenderFxGlowShell, 200, 0, 0, kRenderNormal, 50 )
        }
        else
        {
            // Remove glow on playermodel entity
            fm_set_rendering( g_ent_playermodel[id] )
        }
    }
    else
    {
        // Set and remove glow the usual way
        if ( g_glow[id] )
        {
            fm_set_rendering( id, kRenderFxGlowShell, 200, 0, 0, kRenderNormal, 50 )
        }
        else
        {
            fm_set_rendering( id )
        }
    }
}

/*================================================================================
 [Stocks]
=================================================================================*/

stock fm_set_playermodel_ent( id, const modelname[] )
{
    // Make original player entity invisible
    set_pev( id, pev_rendermode, kRenderTransTexture )
    // This is not 0 because it would hide the shadow and some effects when firing weapons
    set_pev( id, pev_renderamt, 1.0 )
    
    // Since we're passing the short model name to the function
    // we need to make the full path out of it
    static modelpath[100]
    formatex( modelpath, charsmax( modelpath ), "models/player/%s/%s.mdl", modelname, modelname )
    
    // Check if the entity assigned to this player exists
    if ( !pev_valid( g_ent_playermodel[id] ) )
    {
        // If it doesn't, proceed to create a new one
        g_ent_playermodel[id] = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "info_target" ) )
        
        // If it failed to create for some reason, at least this will prevent further "Invalid entity" errors...
        if ( !pev_valid( g_ent_playermodel[id] ) ) return;
        
        // Set its classname
        set_pev( g_ent_playermodel[id], pev_classname, PLAYERMODEL_CLASSNAME )
        
        // Make it follow the player
        set_pev( g_ent_playermodel[id], pev_movetype, MOVETYPE_FOLLOW )
        set_pev( g_ent_playermodel[id], pev_aiment, id )
        set_pev( g_ent_playermodel[id], pev_owner, id )
    }
    
    // Entity exists now, set its model
    engfunc( EngFunc_SetModel, g_ent_playermodel[id], modelpath )
}

stock fm_has_custom_model( id )
{
    return pev_valid( g_ent_playermodel[id] ) ? true : false;
}

stock fm_set_weaponmodel_ent( id )
{
    // Get the player's p_ weapon model
    static model[100]
    pev( id, pev_weaponmodel2, model, charsmax( model ) )
    
    // Check if the entity assigned to this player exists
    if ( !pev_valid(g_ent_weaponmodel[id]) )
    {
        // If it doesn't, proceed to create a new one
        g_ent_weaponmodel[id] = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "info_target" ) )
        
        // If it failed to create for some reason, at least this will prevent further "Invalid entity" errors...
        if ( !pev_valid( g_ent_weaponmodel[id] ) ) return;
        
        // Set its classname
        set_pev( g_ent_weaponmodel[id], pev_classname, WEAPONMODEL_CLASSNAME )
        
        // Make it follow the player
        set_pev( g_ent_weaponmodel[id], pev_movetype, MOVETYPE_FOLLOW )
        set_pev( g_ent_weaponmodel[id], pev_aiment, id )
        set_pev( g_ent_weaponmodel[id], pev_owner, id )
    }
    
    // Entity exists now, set its model
    engfunc( EngFunc_SetModel, g_ent_weaponmodel[id], model )
}

stock fm_remove_model_ents( id )
{
    // Make the player visible again
    set_pev( id, pev_rendermode, kRenderNormal )
    
    // Remove "playermodel" ent if present
    if ( pev_valid( g_ent_playermodel[id] ) )
    {
        engfunc( EngFunc_RemoveEntity, g_ent_playermodel[id] )
        g_ent_playermodel[id] = 0
    }
    // Remove "weaponmodel" ent if present
    if ( pev_valid( g_ent_weaponmodel[id] ) )
    {
        engfunc( EngFunc_RemoveEntity, g_ent_weaponmodel[id] )
        g_ent_weaponmodel[id] = 0
    }
}

// Set entity's rendering type (from fakemeta_util)
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
    new Float:color[3]
    color[0] = float(r)
    color[1] = float(g)
    color[2] = float(b)
    
    set_pev(entity, pev_renderfx, fx)
    set_pev(entity, pev_rendercolor, color)
    set_pev(entity, pev_rendermode, render)
    set_pev(entity, pev_renderamt, float(amount))
}
