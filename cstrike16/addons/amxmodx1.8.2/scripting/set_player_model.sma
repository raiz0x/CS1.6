#include <amxmodx>
#include <fakemeta>

new g_has_custom_model[33]
new g_player_model[33][32]
/*
#define MODELCHANGE_DELAY 0.5 // delay between model changes
new Float:g_models_targettime // target time for the last model change
*/
public plugin_init() {
	register_forward( FM_SetClientKeyValue, "fw_SetClientKeyValue" )
}

public fw_SetClientKeyValue( id, const infobuffer[], const key[] )
{
    // Block CS model changes
    if ( g_has_custom_model[id] && equal( key, "model" ) )
    {
        // Get current model
        static currentmodel[32]
        fm_cs_get_user_model( id, currentmodel, charsmax( currentmodel ) )
        
        // Check whether it matches the custom model - if not, set it again
        if ( !equal( currentmodel, g_player_model[id] ) )
            fm_cs_set_user_model( id, g_player_model[id] )
        
        return FMRES_SUPERCEDE;
    }
    
    return FMRES_IGNORED;
}

/*public fm_cs_user_model_update( id )
{
    static Float:current_time
    current_time = get_gametime()
    
    // Delay needed?
    if ( current_time - g_models_targettime >= MODELCHANGE_DELAY )
    {
        fm_cs_set_user_model( id )
        g_models_targettime = current_time
    }
    else
    {
        set_task( (g_models_targettime + MODELCHANGE_DELAY) - current_time, "fm_cs_set_user_model", id )
        g_models_targettime = g_models_targettime + MODELCHANGE_DELAY
    }
}*/

stock fm_cs_set_user_model( player, const modelname[] )
{
	// Set new model
	engfunc( EngFunc_SetClientKeyValue, player, engfunc( EngFunc_GetInfoKeyBuffer, player ), "model", modelname )
	
	// Remember this player has a custom model
	g_has_custom_model[player] = true
}
stock fm_cs_get_user_model( player, model[], len )
{
	// Retrieve current model
	engfunc( EngFunc_InfoKeyValue, engfunc( EngFunc_GetInfoKeyBuffer, player ), "model", model, len )
}
stock fm_cs_reset_user_model( player )
{
	// Player doesn't have a custom model any longer
	g_has_custom_model[player] = false
	
	dllfunc( DLLFunc_ClientUserInfoChanged, player, engfunc( EngFunc_GetInfoKeyBuffer, player ) )
}
