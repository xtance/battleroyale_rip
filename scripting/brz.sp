#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required
#define iUnits 63

Handle hrTimer;
int iRandom[4], iFloor = 0;
int iEnts[4] = {-1,-1,-1,-1};
int iZoneCounter;
char sHUD[256];
float fZone[4][3],fPos[3];
bool bHighrise = false;
ConVar hCvar;

enum {
	left,
	right,
	top,
	bottom
}

public Plugin myinfo = {
	name = "BR Zones",
	author = "XTANCE",
	description = "Управляет зонами на картах dm_royale, dm_royale_remix, dm_highrise",
	version = "1",
	url = "https://steamcommunity.com/id/xtance"
};

public void OnMapStart(){
	char sMap[512];
	GetCurrentMap(sMap, sizeof(sMap));
	GetMapDisplayName(sMap, sMap, sizeof(sMap));
	if (StrEqual(sMap, "dm_highrise", false)){
		PrintToConsoleAll("[BRZ] Playing on Highrise");
		bHighrise = true;
	} else {
		bHighrise = false;
	}
}

public void OnPluginStart(){
	LoadTranslations("brz.phrases");
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	if(!(hCvar = FindConVar("sv_disable_radar"))) LogMessage("No found cvar: sv_disable_radar");
}

public void OnClientPostAdminCheck(int iClient) {
	if (IsClientInGame(iClient) && !IsFakeClient(iClient)){
		if (bHighrise) hCvar.ReplicateToClient(iClient, "1");
		else hCvar.ReplicateToClient(iClient, "0");
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool Broadcast){
	if (hrTimer != null){
		KillTimer(hrTimer);
		hrTimer = null;
    }
}

public Action Event_RoundStart(Event event, const char[] name, bool Broadcast){
	iZoneCounter = 0;
	if (hrTimer != null) {
		KillTimer(hrTimer);
		hrTimer = null;
	}
	if (bHighrise){
		hrTimer = CreateTimer(2.0, rTimerHR, _, TIMER_REPEAT);
		iFloor = GetRandomInt(0, 26);
		iFloor+=1;
		PrintToChatAll(" \x04>>\x01 Безопасный этаж: \x04%i", iFloor);
		PrintToChatAll(" \x04>>\x01 Если не пишет инфу об этаже, \x04нажмите Esc");
	} else {
		int iEnt = -1;
		char sName[128];
		while((iEnt = FindEntityByClassname(iEnt, "func_tracktrain")) != -1){
			GetEntPropString(iEnt, Prop_Data, "m_iName", sName, sizeof(sName));
			if (StrEqual(sName, "w_left", false)) iEnts[0] = iEnt;
			else if (StrEqual(sName, "w_right", false)) iEnts[1] = iEnt;
			else if (StrEqual(sName, "w_top", false)) iEnts[2] = iEnt;
			else if (StrEqual(sName, "w_bottom", false)) iEnts[3] = iEnt;
		}
		// Этот говнокод был написан давным-давно.
		switch (GetRandomInt(1, 14)){
			case 1:{
				iRandom = {0,iUnits*6,0,iUnits*2};
				PrintToConsoleAll(" -> 1");
			}
			case 2:{
				iRandom = {iUnits,iUnits*5,0,iUnits*2};
				PrintToConsoleAll(" -> 2");
			}
			case 3:{
				iRandom = {iUnits*2,iUnits*4,0,iUnits*2};
				PrintToConsoleAll(" -> 3");
			}
			case 4:{
				iRandom = {iUnits*3,iUnits*3,0,iUnits*2};
				PrintToConsoleAll(" -> 4");
			}
			case 5:{
				iRandom = {iUnits*4,iUnits*2,0,iUnits*2};
				PrintToConsoleAll(" -> 5");
			}
			case 6:{
				iRandom = {iUnits*5,iUnits,0,iUnits*2};
				PrintToConsoleAll(" -> 6");
			}
			case 7:{
				iRandom = {iUnits*6,0,0,iUnits*2};
				PrintToConsoleAll(" -> 7");
			}
			case 8:{
				iRandom = {0,iUnits*6,iUnits*2,0};
				PrintToConsoleAll(" -> 8");
			}
			case 9:{
				iRandom = {iUnits,iUnits*5,iUnits*2,0};
				PrintToConsoleAll(" -> 9");
			}
			case 10:{
				iRandom = {iUnits*2,iUnits*4,iUnits*2,0};
				PrintToConsoleAll(" -> 10");
			}
			case 11:{
				iRandom = {iUnits*3,iUnits*3,iUnits*2,0};
				PrintToConsoleAll(" -> 11");
			}
			case 12:{
				iRandom = {iUnits*4,iUnits*2,iUnits*2,0};
				PrintToConsoleAll(" -> 12");
			}
			case 13:{
				iRandom = {iUnits*5,iUnits,iUnits*2,0};
				PrintToConsoleAll(" -> 13");
			}
			case 14:{
				iRandom = {iUnits*6,0,iUnits*2,0};
				PrintToConsoleAll(" -> 14");
			}
		}
		for (int i = 0; i < 4; i++){
			if (IsValidEntity(iEnts[i])){
				PrintToServer("Entity is valid: %i (ent: %i, random: %i)",i,iEnts[i],iRandom[i]);
				SDKHook(iEnts[i], SDKHook_Touch, OnTouch);
			} else {
				PrintToServer("Entity is invalid: %i (ent: %i, random: %i)",i,iEnts[i],iRandom[i]);
			}
		}
		hrTimer = CreateTimer(10.0, rTimer, _, TIMER_REPEAT);
	}
	return Plugin_Handled;
}

public void OnTouch(int iEntity, int iClient){
    if (IsValidEntity(iEntity) && (MAXPLAYERS >= iClient > 0)){
		int iHealth = GetClientHealth(iClient) - 25;
		if (iHealth <= 0) ForcePlayerSuicide(iClient);
		else SetEntityHealth(iClient, iHealth);
		SetGlobalTransTarget(iClient);
		FormatEx(sHUD, sizeof(sHUD), "%t", "sZoneHurt");
		ShowHudText(iClient, 2, sHUD);
	}
}

int GetFloor(float fNow){
	return RoundFloat((16243+fNow)/144)+1; // ;_;
}

public Action rTimerHR(Handle timer){
	iZoneCounter += 2;
	int iCurFloor;
	SetHudTextParams(-1.0, 0.8, 10.0, GetRandomInt(0,255),GetRandomInt(0,255),GetRandomInt(0,255),255, 0, 6.0, 0.1, 0.2);
	if (iZoneCounter < 60){
		
		for (int i = 1; i <= MaxClients; i++){
			if (IsClientInGame(i) && IsPlayerAlive(i)){
				if (GetClientTeam(i) == 3){
					SetGlobalTransTarget(i);
					FormatEx(sHUD, sizeof(sHUD), "%t", "sInvulnerable", 60-iZoneCounter);
					ShowHudText(i, 2, sHUD);
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", fPos);
					iCurFloor = GetFloor(fPos[2]);
					if (iCurFloor != iFloor){
						FormatEx(sHUD, sizeof(sHUD), "%t", "sSafeFloor", iFloor, iCurFloor);
						PrintToConsole(i, sHUD);
						PrintCenterText(i, sHUD);
					}
				} else{
					SetGlobalTransTarget(i);
					FormatEx(sHUD, sizeof(sHUD), "%t", "sKnife");
					ShowHudText(i, 2, sHUD);
				}
			}
		}
		
	} else if (iZoneCounter < 180){
		
		for (int i = 1; i <= MaxClients; i++){
			if (IsClientInGame(i) && IsPlayerAlive(i)){
				if (GetClientTeam(i) == 3){
					SetGlobalTransTarget(i);
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", fPos);
					iCurFloor = GetFloor(fPos[2]);
					if (iCurFloor != iFloor){
						FormatEx(sHUD, sizeof(sHUD), "%t", "sSafeFloor", iFloor, iCurFloor);
					} else {
						FormatEx(sHUD, sizeof(sHUD), "%t", "sFloorOk", iFloor);
					}
					PrintToConsole(i, sHUD);
					ShowHudText(i, 2, sHUD);
				} else{
					SetGlobalTransTarget(i);
					FormatEx(sHUD, sizeof(sHUD), "%t", "sKnife");
					ShowHudText(i, 2, sHUD);
				}
			}
		}
		
	} else {
		
		int iHealth;
		for (int i = 1; i <= MaxClients; i++){
			if (IsClientInGame(i) && IsPlayerAlive(i)){
				if (GetClientTeam(i) == 3){
					SetGlobalTransTarget(i);
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", fPos);
					iCurFloor = GetFloor(fPos[2]);
					if (iCurFloor != iFloor){
						FormatEx(sHUD, sizeof(sHUD), "%t", "sSafeFloor", iFloor, iCurFloor);
						PrintToConsole(i, sHUD);
						ShowHudText(i, 2, sHUD);
						if (GetRandomInt(0, 3) == 3){
							iHealth = GetClientHealth(i) - 5;
							if (iHealth <= 0) ForcePlayerSuicide(i);
							else SetEntityHealth(i, iHealth);
							FormatEx(sHUD, sizeof(sHUD), "%t", "sDamage");
							PrintToConsole(i, sHUD);
							SetHudTextParams(-1.0, 0.9, 3.0, GetRandomInt(0,255),GetRandomInt(0,255),GetRandomInt(0,255),255, 0, 6.0, 0.1, 0.2);
							ShowHudText(i, 3, sHUD);
						}
					} else {
						FormatEx(sHUD, sizeof(sHUD), "%t", "sFloorOk", iFloor);
						PrintToConsole(i, sHUD);
						ShowHudText(i, 2, sHUD);
					}
				} else{
					SetGlobalTransTarget(i);
					FormatEx(sHUD, sizeof(sHUD), "%t", "sKnife");
					ShowHudText(i, 2, sHUD);
				}
			}
		}
		
	}
	return Plugin_Continue;
}

public Action rTimer(Handle timer){
	iZoneCounter += 10;
	SetHudTextParams(-1.0, 0.8, 10.0, GetRandomInt(0,255),GetRandomInt(0,255),GetRandomInt(0,255),255, 0, 6.0, 0.1, 0.2);
	switch (iZoneCounter){
		case 10,20,30,40,50: {
			for (int i = 1; i <= MaxClients; i++){
				if (IsClientInGame(i) && IsPlayerAlive(i)){
					if (GetClientTeam(i) == 3){
						SetGlobalTransTarget(i);
						FormatEx(sHUD, sizeof(sHUD), "%t", "sInvulnerable", 60-iZoneCounter);
						ShowHudText(i, 2, sHUD);
					} else{
						SetGlobalTransTarget(i);
						FormatEx(sHUD, sizeof(sHUD), "%t", "sKnife");
						ShowHudText(i, 2, sHUD);
					}
				}
			}
		}
		case 60,70,80:{
			for (int i = 1; i <= MaxClients; i++){
				if (IsClientInGame(i) && IsPlayerAlive(i)){
					if (GetClientTeam(i) == 3){
						SetGlobalTransTarget(i);
						FormatEx(sHUD, sizeof(sHUD), "%t", "sAttention",90-iZoneCounter);
						ShowHudText(i, 2, sHUD);
					}
					else if (GetClientTeam(i) == 2){
						SetGlobalTransTarget(i);
						FormatEx(sHUD, sizeof(sHUD), "%t", "sKnife");
						ShowHudText(i, 2, sHUD);
					}
				}
			}
		}
		case 90:{
			bool b = false;
			for (int i = 0; i < 4; i++){
				if (iRandom[i] > 0){
					if (IsValidEntity(iEnts[i])){
						SetVariantFloat(50.0);
						b = AcceptEntityInput(iEnts[i], "SetSpeedReal");
						PrintToServer("Start: %i (ent: %i) = %b",i,iEnts[i],b);
					} else {
						PrintToServer("Invalid: %i (ent: %i)",i,iEnts[i]);
					}
				}
			}
		}
		default: {
			bool b = false;
			bool x = true;
			for (int i = 0; i < 4; i++){
				if (IsValidEntity(iEnts[i])){
					if (iRandom[i]+120 == iZoneCounter){
						SetVariantFloat(0.0);
						b = AcceptEntityInput(iEnts[i], "SetSpeedReal");
						PrintToServer("Stop: %i (ent: %i) = %b",i,iEnts[i],b);
					}
					GetEntPropVector(iEnts[i], Prop_Send, "m_vecOrigin", fZone[i]);
				} else {
					PrintToServer("Invalid %i (ent: %i)",i,iEnts[i]);
					fZone[i] = view_as<float>({0.0, 0.0, 0.0}); //fixed: https://github.com/alliedmodders/sourcepawn/pull/441
					x = false;
				}
			}
			PrintToServer("-------");
			if (x) for (int i = 1; i <= MaxClients; i++){
				if (IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(i) == 3)){
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", fPos);
					if ((fPos[1] > fZone[top][1]) || (fPos[1] < fZone[bottom][1]) || (fPos[0] < fZone[left][0]) || (fPos[0] > fZone[right][0])){
						ForcePlayerSuicide(i);
						PrintToServer("%N killed for being outside of Zone",i);
						SetGlobalTransTarget(i);
						FormatEx(sHUD, sizeof(sHUD), "%t", "sKilled");
						ShowHudText(i, 2, sHUD);
					}
				}
			}
		}
	}
	return Plugin_Continue;
}