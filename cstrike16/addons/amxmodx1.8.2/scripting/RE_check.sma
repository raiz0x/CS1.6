#include <amxmodx>
#include <amxmisc>
//#define HARD_RESTART
#if defined HARD_RESTART
#include <fakemeta>
#endif
#define FILE_PATCH "../engine_i486.so"
#define UPDATE_FILEPATCH "addons/amxmodx/data/engine_i486.so"
public plugin_init(){register_plugin("Engine Updater","0.002","mado");register_srvcmd("update_engine", "pseudo_update");}
public pseudo_update(){
	if(!file_exists(UPDATE_FILEPATCH)){
		server_print("File ^"%s^" not found",UPDATE_FILEPATCH);
		return 0;
	}
	if(!file_exists(FILE_PATCH)){
		server_print("File ^"%s^" not found",FILE_PATCH);
		return 0;
	}
	unlink(FILE_PATCH);if(file_exists(FILE_PATCH)){server_print("Error #1");return 0;}
	rename_file(UPDATE_FILEPATCH,FILE_PATCH, 1);
	if(!file_exists(UPDATE_FILEPATCH) && file_exists(FILE_PATCH))server_print("Update successful");
#if defined HARD_RESTART
	set_tr2(1, TR_AllSolid, 0);
#endif	
	return 0;
}
