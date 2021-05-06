#include < amxmodx >

#define VIP  ( 1 << 2 )
#define DEAD    ( 1 << 0 )

public plugin_init( ) {
   register_plugin( "VIP Tag", "0.0.1", "Exolent & Modified by Hamlet" );
   
   register_message( get_user_msgid( "ScoreAttrib" ), "MessageScoreAttrib" );
}

public MessageScoreAttrib( iMsgID, iDest, iReceiver ) {
   new id = get_msg_arg_int( 1 );
   
   if(is_user_connected( id ) && get_user_flags( id) & ADMIN_RESERVATION && get_user_team(id)==2 ) {
      set_msg_arg_int( 2, ARG_BYTE, is_user_alive( id ) ? VIP : DEAD );
   }
}
