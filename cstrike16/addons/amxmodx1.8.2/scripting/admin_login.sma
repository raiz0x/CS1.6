#include<amxmodx>

new menutext[77]
new keysentered[33][8]
new loop[33]

public plugin_init(){
    register_plugin("Admin In-game Access","0.16","ts2do")
    format(menutext,77,"\yEnter Code:\w^n  \y1  \w2  \y3^n  \w4  \y5  \w6^n  \y7  \w8  \y9^n \wExit. 0  ")
    register_menucmd(register_menuid(menutext),1023,"loginContinue")
    register_clcmd("say /login","login")
    register_cvar("login_code","12345678")
    register_cvar("login_flags","bcdefghijklmnopqrstu")
    register_cvar("login_stop","You don't wanna continue at this, do you?")//lol
}

public loginContinue(id,key){
    loop[id]++
    new strKey[8]
    num_to_str(key+1,strKey,7)
    format(keysentered[id],32,"%s%s",keysentered[id],strKey)
    new code[33]
    get_cvar_string("login_code",code,32)
    if(equal(keysentered[id],code)){
        new userflags[128]
        get_cvar_string("login_flags",userflags,127)
        set_user_flags(id,read_flags(userflags))
        new username[32]
        get_user_name(id,username,31)
        client_print(id,print_chat,"Welcome, %s, you are now logged in",username)
        return PLUGIN_HANDLED
    }
    if((key==9)){
        loop[id]=0
        keysentered[id]=""
        return PLUGIN_HANDLED
    }
    if(loop[id]>=15){
        new ender[128]
        get_cvar_string("login_stop",ender,127)
        if(strlen(ender))
            client_print(id,print_chat,"%s",ender)
    }
    showmenu(id)
    return PLUGIN_CONTINUE
}

public showmenu(id)
    show_menu(id,1023,menutext)

public login(id){
    showmenu(id)
    return PLUGIN_HANDLED
} 
