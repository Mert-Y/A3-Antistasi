//Repairs a destroyed building.
//Parameter can either be the ruin of a building, or the building itself buried underneath the ruins.
#include "..\..\Includes\common.inc"
FIX_LINE_NUMBERS()
if (!isServer) exitWith { Error("Server-only function miscalled") };

params [["_target", objNull]];

if (isNull _target) exitWith { false };

if !(_target isKindOf "Ruins") exitWith { false };

private _buildingToRepair = _target getVariable ["building", objNull];

if (isNull _buildingToRepair) exitWith { false };

deleteVehicle _target;
_buildingToRepair hideObjectGlobal false;
_buildingToRepair enableSimulationGlobal true;

{
	if (_x #0 == _buildingToRepair) then
	{
		destroyedBuildings deleteAt _forEachIndex;
		break;
	};
} forEach destroyedBuildings;

true;
