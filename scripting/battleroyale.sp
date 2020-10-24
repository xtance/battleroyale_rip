#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

int iRoundWinner, iType[MAXPLAYERS+1], iLastProp[MAXPLAYERS+1];
bool bRoundEnd, bTime = true;

public Plugin myinfo =
{
	name = "Battle Royale Addon",
	author = "XTANCE",
	description = "Отвечает за автоперекидывание игроков за Т и стройку",
	version = "1",
	url = "http://steamcommunity.com/id/xtance/"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", HookPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", HookPlayerDeath, EventHookMode_Post);
	HookEvent("round_start", RoundStart, EventHookMode_Pre);
	HookEvent("round_end", RoundEnd, EventHookMode_Post);
	RegConsoleCmd("sm_p", XBuild, "Build");
	RegAdminCmd("sm_mo", XM, ADMFLAG_ROOT, "Money");
	AddCommandListener(XBuild2, "autobuy");
	iRoundWinner = 0;
	for (int i = 1; i <= MaxClients; i++){
		iType[i] = 300;
	}
}

public Action XBuild(int iClient, int iArgs){
	XBuildMenu(iClient);
	return Plugin_Handled;
}

public Action XM(int iClient, int iArgs){
	SetEntProp(iClient, Prop_Send, "m_iAccount", 10000);
	return Plugin_Handled;
}


public Action XBuild2(int iClient, const char[] cmd, int argc){
    XBuildMenu(iClient);
    return Plugin_Continue;
} 

void XBuildMenu(int iClient){
	if (bTime){
		if (IsPlayerAlive(iClient)){
			//if(GetClientTeam(iClient) == 3 && !bRoundEnd){
				int iMoney = GetEntProp(iClient, Prop_Send, "m_iAccount");
				Menu menu = new Menu(hmenu, MenuAction_Cancel);
				menu.SetTitle(">> Меню строительства. У вас %i долларов!",iMoney);
				switch (iType[iClient]){
					case 300: {
						menu.AddItem("i_switch","Сменить материал\nСетка: $300/постройка, 300 хп");
					}
					case 400: {
						menu.AddItem("i_switch","Сменить материал\nДерево: $400/постройка, 400 хп");
					}
					case 500: {
						menu.AddItem("i_switch","Сменить материал\nМеталл: $500/постройка, 500 хп");
					}
					default: {
						iType[iClient] = 300;
						XBuildMenu(iClient);
						LogMessage("%N's iType is default.. wtf?", iClient);
						return;
					}
				}
				menu.AddItem("i_ramp","Рампа");
				menu.AddItem("i_fence","Забор");
				menu.AddItem("i_floor","Пол");
				menu.Display(iClient, MENU_TIME_FOREVER);
			//} else PrintToChat(iClient, " \x07>>\x01 Строить можно лишь \x07в режиме Выживания!");
		} else PrintToChat(iClient, " \x07>>\x01 Чтобы строить, вы должны быть \x07живее трупа!");
	} else PrintToChat(iClient, " \x07>>\x01 Первые 30 секунд строить нельзя!");
}

public int hmenu(Menu menu, MenuAction action, int param1, int param2)
{
	if (bTime){
		switch (action)
		{
			case MenuAction_Select:
			{
				char item[64];
				menu.GetItem(param2, item, sizeof(item));
				if (StrEqual("i_switch", item, false)){
					if (iType[param1] == 300) {
						iType[param1] = 400;
					}
					else if (iType[param1] == 400) {
						iType[param1] = 500;
					}
					else {
						iType[param1] = 300;
					}
					XBuildMenu(param1);
				}
				else if (StrEqual("i_ramp", item, false)){
					XPlace(param1, 45.0);
				}
				else if (StrEqual("i_fence", item, false)){
					XPlace(param1, 0.0);
				}
				else if (StrEqual("i_floor", item, false)){
					XPlace(param1, 90.0);
				}
				else {
					//
				}
			}
		}
	} else PrintToChat(param1, " \x07>>\x01 Первые 30 секунд строить нельзя!");
	return 0;
}

void XPlace(int iClient, float fAngle){
	//if(GetClientTeam(iClient) == 3 && !bRoundEnd){
		int iMoney = GetEntProp(iClient, Prop_Send, "m_iAccount");
		if (iMoney >= iType[iClient]){
			
			float fPos[3];
			fPos = XLook(iClient);
			if (XFar(fPos, iClient)){
				float fAng[3];
				GetClientEyeAngles(iClient, fAng);
				fAng[0] = fAngle;
				iLastProp[iClient] = CreateEntityByName("prop_dynamic");
				switch (iType[iClient]){
					case 400: {
						DispatchKeyValue(iLastProp[iClient], "model",  "models/props_urban/wood_fence001_128.mdl");
						SetEntityModel(iLastProp[iClient], "models/props_urban/wood_fence001_128.mdl");
					}
					case 500: {
						DispatchKeyValue(iLastProp[iClient], "model",  "models/props/de_dust/hr_dust/dust_fences/dust_chainlink_fence_cover_001_128.mdl");
						SetEntityModel(iLastProp[iClient], "models/props/de_dust/hr_dust/dust_fences/dust_chainlink_fence_cover_001_128.mdl");
					}
					default: {
						DispatchKeyValue(iLastProp[iClient], "model",  "models/props/de_nuke/hr_nuke/chainlink_fence_001/chainlink_fence_gate_003a_128.mdl");
						SetEntityModel(iLastProp[iClient], "models/props/de_nuke/hr_nuke/chainlink_fence_001/chainlink_fence_gate_003a_128.mdl");
					}
				}
				DispatchKeyValue(iLastProp[iClient], "solid",   "6");
				DispatchSpawn(iLastProp[iClient]);
				SetEntityRenderMode(iLastProp[iClient], RENDER_NORMAL);
				TeleportEntity(iLastProp[iClient], fPos, fAng, NULL_VECTOR);
				SetEntProp(iLastProp[iClient], Prop_Data, "m_takedamage", 2, 1);
				SetEntProp(iLastProp[iClient], Prop_Data, "m_iHealth", iType[iClient]+1);
				SDKHook(iLastProp[iClient], SDKHook_OnTakeDamage, OnTakeDamageEnt);
				SetEntProp(iClient, Prop_Send, "m_iAccount", iMoney-iType[iClient]);
			}
			else PrintToChat(iClient, " \x07>>\x01 Нельзя строить рядом с другими игроками.");
		}
		else PrintToChat(iClient, " \x07>>\x01 Тебе не хватает денежек на эту постройку..");
	//} else PrintToChat(iClient, " \x07>>\x01 Строить можно лишь \x07в режиме Выживания!");
}

public Action OnTakeDamageEnt(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
	if (IsValidEdict(victim)){
		if (0 < attacker <= MaxClients && IsClientInGame(attacker)){
			int iHealth = GetEntProp(victim, Prop_Data, "m_iHealth");
			if (iHealth > 0){
				int iColor = GetRandomInt(1,9);
				switch (iColor){
					case 1: PrintToChat(attacker, " \x0E>>\x01 У постройки осталось \x0E%i ХП!", iHealth);
					case 2: PrintToChat(attacker, " \x02>>\x01 У постройки осталось \x02%i ХП!", iHealth);
					case 3: PrintToChat(attacker, " \x03>>\x01 У постройки осталось \x03%i ХП!", iHealth);
					case 4: PrintToChat(attacker, " \x04>>\x01 У постройки осталось \x04%i ХП!", iHealth);
					case 5: PrintToChat(attacker, " \x0C>>\x01 У постройки осталось \x0C%i ХП!", iHealth);
					case 6: PrintToChat(attacker, " \x10>>\x01 У постройки осталось \x10%i ХП!", iHealth);
					case 7: PrintToChat(attacker, " \x07>>\x01 У постройки осталось \x07%i ХП!", iHealth);
					case 8: PrintToChat(attacker, " \x0F>>\x01 У постройки осталось \x0F%i ХП!", iHealth);
					default: PrintToChat(attacker, " \x04>>\x01 У постройки осталось \x09%i ХП!", iHealth);
				}
			}
			
		}
	}
	return Plugin_Continue;
}

public Action RoundEnd(Event event, const char[] name, bool dontBroadcast) {
	bRoundEnd = true;
}

public Action CheckTime(Handle timer){
	bTime = true;
	PrintToChatAll(" ");
	PrintToChatAll(" \x04>>\x01 Теперь можно \x04строить! \x01Нажмите \x04F1");
	PrintToChatAll(" \x04>>\x01 Бинд меню на любую кнопку: \x04bind кнопка autobuy");
	PrintToChatAll(" ");
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	bRoundEnd = false;
	bTime = false;
	CreateTimer(30.0, CheckTime);
	for (int i = 1; i <= MaxClients; i++)
	{
		iLastProp[i] = -1;
		if (IsClientInGame(i)){
			if((GetClientTeam(i) == 3) && (i == iRoundWinner)){
				SetEntityHealth(i, GetClientHealth(i) + 15);
				PrintToConsoleAll("%i -> %N won previous round.", i, i);
			}
		}
	}
	iRoundWinner = 0;
}

bool XFar(float fEnt[3], int iClient){
	bool x = true;
	float fClientPos[3],fDistance;
	for (int i = 1; i <= MaxClients; i++){
		if (IsClientInGame(i) && IsPlayerAlive(i) && i != iClient){
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", fClientPos);
			fDistance = GetVectorDistance(fEnt, fClientPos);
			if (fDistance < 120.0){
				x = false;
				break;
			}
		}
	}
	return x;
}

public void HookPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsPlayerAlive(iClient) && IsClientInGame(iClient))
	{
		if ((GetClientTeam(iClient) == 2) && (GetRandomInt(1, 20) == 10)) GivePlayerItem(iClient, "weapon_revolver");
		GivePlayerItem(iClient, "weapon_knife");
	}
}

public void HookPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetAliveCTClients() <= 1)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i)){
				if (GetClientTeam(i) == 2)
				{
					CS_SwitchTeam(i, 3);
				}
			} 
		}
		CS_TerminateRound(3.0, CSRoundEnd_CTWin, false);
	}
	else
	{
		if (GetClientTeam(iClient) == 3 && !bRoundEnd)
		{
			CS_SwitchTeam(iClient, 2);
		}
	}
}

int GetAliveCTClients()
{
    int count;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i) || !IsPlayerAlive(i) || GetClientTeam(i) != 3)
        {
            continue;
        }
        count++;
    }
    return count;
}

bool XFilter(int ent, int mask, any iClient){
	return iClient != ent;
}

float XLook(int iClient){
	float fEyePos[3], fEyeAngles[3];
	Handle hTrace; 
	GetClientEyePosition(iClient, fEyePos); 
	GetClientEyeAngles(iClient, fEyeAngles);
	hTrace = TR_TraceRayFilterEx(fEyePos, fEyeAngles, MASK_SOLID, RayType_Infinite, XFilter, iClient); 
	TR_GetEndPosition(fEyePos, hTrace); 
	CloseHandle(hTrace);
	return fEyePos;
}

public void OnMapStart(){
	PrecacheModel("models/props/de_dust/hr_dust/dust_fences/dust_chainlink_fence_cover_001_128.mdl", true); //metal
	PrecacheModel("models/props/de_nuke/hr_nuke/chainlink_fence_001/chainlink_fence_gate_003a_128.mdl", true); //chainlink
	PrecacheModel("models/props_urban/wood_fence001_128.mdl", true); //wood
}