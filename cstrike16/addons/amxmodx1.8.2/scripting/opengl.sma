#include < amxmodx >

new const TehOpenGL[ ] = "../opengl32.dll";

public plugin_init( )
    register_plugin( "Anti OpenGL", "1.0", "CSF" );

public plugin_precache( )
    force_unmodified( force_exactfile, "", "", TehOpenGL );

public inconsistent_file( id, const szFileName[ ], szReason[ 64 ] ) {
    if( equal( szFileName, TehOpenGL ) ) {
        log_amx( "Client: %i - File: %s - Reason: %s", id, szFileName, szReason );
    }
}
