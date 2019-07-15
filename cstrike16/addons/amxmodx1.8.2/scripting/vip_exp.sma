#include <amxmodx>
#include <amxmisc>

enum _:database_items
{
	auth[50],
	password[50],
	type[2],
	prefix[32],
	model[32],
	model_ct[32],
	day[3],
	month[3],
	year[5]
}
new privileges_database[database_items]
new Array:database_holder
new g_privilege[33], g_day[33], g_month[33], g_year[33], g_prefix[33][32], g_model[33][32], g_model_ct[33][32]
new todaysyearnum, todaysmonthnum ,todaysdaynum

public plugin_init() {
	date(todaysyearnum, todaysmonthnum ,todaysdaynum)
}
public plugin_precache() reload_privileges()

public plugin_natives()
{
	register_native("privilege_get", "natvie_privilege_get",1)
	register_native("privilege_get_prefix", "natvie_privilege_prefix")
	register_native("privilege_get_model_t", "natvie_privilege_model_t")
	register_native("privilege_get_model_ct", "natvie_privilege_model_ct")
	register_native("privilege_get_day", "natvie_privilege_day",1)
	register_native("privilege_get_month", "natvie_privilege_month",1)
	register_native("privilege_get_year", "natvie_privilege_year",1)
}

public reload_privileges() {
	
	if(database_holder) ArrayDestroy(database_holder)
	database_holder = ArrayCreate(database_items)
	new configsDir[64]
	get_configsdir(configsDir, 63)
	format(configsDir, 63, "%s/privileges.ini", configsDir)
	
	new File=fopen(configsDir,"rt")
	new iLineCount=0
	
	if (File)
	{
		new Text[512], AuthData[50], Password[50], Type[2], Prefix[32],Model[32],Model_CT[32], Day[3], Month[3], Year[5],
		DayNum, MonthNum, YearNum
		while (!feof(File)&&file_exists(configsDir))
		{
			iLineCount++
			fgets(File,Text,sizeof(Text)-1);
			
			trim(Text);
			
			if (Text[0]==';') continue
			
			AuthData[0]=0
			Password[0]=0
			Day[0]=0
			Month[0]=0
			Year[0]=0
			Type[0]=0
			Prefix[0]=0
			Model[0]=0
			Model_CT[0]=0
			
			if (parse(Text, AuthData, charsmax(AuthData), Password,charsmax(Password), Type,charsmax(Type), Prefix, charsmax(Prefix), Model, charsmax(Model),Model_CT, charsmax(Model_CT), Day,charsmax(Day), Month,charsmax(Month), Year,charsmax(Year)) < 3)
				continue
				
			DayNum=str_to_num(Day)
			MonthNum=str_to_num(Month)
			YearNum=str_to_num(Year)
	
			if(Day[0]>0&&Month[0]>0&&Year[0]>0){
				if((DayNum<=todaysdaynum&&MonthNum==todaysmonthnum&&YearNum==todaysyearnum)
				|| (MonthNum<todaysmonthnum&&YearNum==todaysyearnum)
				|| (YearNum < todaysyearnum)) {
					fclose(File)
					DeleteLine(configsDir, iLineCount)
					return
				}
			}

			privileges_database[auth] = AuthData
			privileges_database[password] = Password
			privileges_database[type] = Type
			privileges_database[prefix] = Prefix
			privileges_database[model]=Model
			privileges_database[model_ct]=Model_CT
			privileges_database[day] = Day
			privileges_database[month] = Month
			privileges_database[year] = Year
			
			ArrayPushArray(database_holder, privileges_database)
			
			if(Model[0]){
				new tmp[64]
				formatex(tmp,charsmax(tmp),"models/player/%s/%s.mdl", Model, Model)
				precache_model(tmp)
			}
			if(Model_CT[0]){
				new tmp[64]
				formatex(tmp,charsmax(tmp),"models/player/%s/%s.mdl", Model_CT, Model_CT)
				precache_model(tmp)
			}
		}
		
		fclose(File)
	}
}

public DeleteLine(const szFilename[], const iLine)
{
	new iFile = fopen(szFilename, "rt")
	if(!iFile) return
	
	static const szTempFilename[ ] = "delete_line.txt"
	new iTempFile = fopen( szTempFilename, "wt" )
    
	new szData[256], iLineCount=0, bool:bReplaced = false
	while(!feof(iFile))
	{
		iLineCount++
		fgets(iFile, szData, 255)

		if(iLineCount == iLine) bReplaced = true
		else fputs(iTempFile, szData)
	}
    
	fclose(iFile )
	fclose(iTempFile)
    
	if(bReplaced)
	{
		delete_file(szFilename)
        
		while(!rename_file(szTempFilename, szFilename, 1)) { }
		
		reload_privileges()
	}
	else delete_file(szTempFilename)
}

stock set_flags(id, username[]="") {
	static authid[31], ip[31], name[51], index, client_password[31], size
	get_user_authid(id, authid, 30)
	get_user_ip(id, ip, 30, 1)
	
	if (username[0])
	{
		copy(name, 50, username)
	}
	else
	{
		get_user_name(id, name, 50)
	}
	
	get_user_info(id, "_pw", client_password, 30)
	
	g_privilege[id] = 0
	size = ArraySize(database_holder)
	for(index=0; index < size ; index++) {
		ArrayGetArray(database_holder, index, privileges_database)
		if(equali(name, privileges_database[auth]) || equali(authid, privileges_database[auth]) || equali(ip, privileges_database[auth]))
		{
			if(strlen(privileges_database[password])>0 && !equal(client_password, privileges_database[password])) 
			{
				server_cmd("kick #%d ^"Неверный пароль^"", get_user_userid(id))
				break
			}
			
			g_privilege[id] = str_to_num(privileges_database[type])
			g_day[id]=str_to_num(privileges_database[day])
			g_month[id]=str_to_num(privileges_database[month])
			g_year[id]=str_to_num(privileges_database[year])
			formatex(g_prefix[id], 31, "%s", privileges_database[prefix])
			formatex(g_model[id], 31, "%s", privileges_database[model])
			formatex(g_model_ct[id], 31, "%s", privileges_database[model_ct])
			if(g_privilege[id]==1) log_amx("[Vip] %s (%s %s) connecting", name, authid, ip)
			else if(g_privilege[id]==2) log_amx("[Boss] %s (%s %s) connecting", name, authid, ip)
			break
		}
	}
}

public client_connect(id)set_flags(id)

public client_infochanged(id)
{
	if (!is_user_connected(id))
	{
		return PLUGIN_CONTINUE
	}

	new newname[32], oldname[32]
	
	get_user_name(id, oldname, 31)
	get_user_info(id, "name", newname, 31)

	if (!equali(newname, oldname))
	{
		set_flags(id, newname)
	}
	return PLUGIN_CONTINUE
}

public natvie_privilege_prefix(plugin_id, num_params)
{	
	new id
	id=get_param(1)
	
	set_string(2, g_prefix[id], get_param(3))
	return true
}

public natvie_privilege_model_t(plugin_id, num_params)
{	
	new id
	id=get_param(1)
	
	set_string(2, g_model[id], get_param(3))
	return true
}

public natvie_privilege_model_ct(plugin_id, num_params)
{	
	new id
	id=get_param(1)
	
	set_string(2, g_model_ct[id], get_param(3))
	return true
}

public natvie_privilege_get(id) return g_privilege[id]
public natvie_privilege_day(id) return g_day[id]
public natvie_privilege_month(id) return g_month[id]
public natvie_privilege_year(id) return g_year[id]
