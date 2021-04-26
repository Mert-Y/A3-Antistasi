#define SHOP_SIZE_SMALL     1
#define SHOP_SIZE_MEDIUM    2
#define SHOP_SIZE_LARGE     3

#define PISTOLS             0
#define RIFLES              1
#define LAUNCHERS           2
#define EXPLOSIVES          3
#define AMMUNITION          4
#define ATTACHMENT          5
#define VESTS               6
#define BACKPACKS           7
#define NVG                 8
#define ITEM                9
#define GRENADES            10
#define HELMET              11


params
[
    ["_garage", objNull, [objNull]],
    ["_citySupportRatio", 0, [0]],
    ["_marker", "", [""]]
];

private _shopSize = (floor (_citySupportRatio / 0.34) + 1) min 3;
private _assets = [];

switch (_shopSize) do
{
    case (SHOP_SIZE_SMALL):
    {
        _assets =
        [
            ["Land_CampingTable_small_F", [-3, 2.3, 0], 180],
            ["C_Soldier_VR_F", [-2, 2, -0.4], 180],
            ["Land_CampingTable_F", [-1, -2.2, 0], 0],
            ["Land_CampingTable_small_F", [2, 2.3, 0], 180],
            ["Box_NATO_Equip_F", [-3, -2.2, 0.2], 90]
        ];
    };
    case (SHOP_SIZE_MEDIUM):
    {
        _assets =
        [
            ["Land_CampingTable_small_F", [-3, 2.3, 0], 180],
            ["C_Soldier_VR_F", [-2, 2, -0.4], 180],
            ["Land_CampingTable_F", [-1, -2.2, 0], 0],
            ["Land_CampingTable_small_F", [4.5, -2.2, 0], 0],
            ["C_Soldier_VR_F", [3.5, -1.9, -0.4], 0],
            ["Land_CampingTable_small_F", [2, 2.3, 0], 180],
            ["Box_NATO_Equip_F", [-3, -2.2, 0.2], 90]
        ];
    };
    case (SHOP_SIZE_LARGE):
    {
        _assets =
        [
            ["Land_CampingTable_small_F", [-3, 2.3, 0], 180],
            ["C_Soldier_VR_F", [-2, 2, -0.4], 180],
            ["Land_CampingTable_F", [-1, -2.2, 0], 0],
            ["Land_CampingTable_small_F", [4.5, -2.2, 0], 0],
            ["C_Soldier_VR_F", [3.5, -1.9, -0.4], 0],
            ["Land_CampingTable_small_F", [2, 2.3, 0], 180],
            ["Land_MapBoard_01_Wall_F", [0, 2.7, 1.25], 180],
            ["Land_MapBoard_01_Wall_F", [1.5, -2.6, 1.25], 0],
            ["Box_NATO_Equip_F", [-3, -2.2, 0.2], 90]
        ];
    };
};

private _fnc_getSlotPositions =
{
    params ["_asset"];
    private _result = [];
    switch (typeOf _asset) do
    {
        case ("Land_CampingTable_small_F"):
        {
            private _pos = (getPosWorld _asset) vectorAdd [0, 0, 0.45];
            private _rot = [150 + (getDir _asset), 0, 0];
            _result pushBack [_asset, _pos, _rot, [EXPLOSIVES, GRENADES, HELMET, VESTS, BACKPACKS, NVG]];
        };
        case ("Land_CampingTable_F"):
        {
            private _tableForward = vectorDir _asset;
            private _tableSide = _tableForward vectorCrossProduct [0, 0, 1];
            private _pos = (getPosWorld _asset) vectorAdd (_tableSide vectorMultiply -0.5) vectorAdd [0, 0, 0.45];
            private _rot = [150 + (getDir _asset), 0, 0];
            _result pushBack [_asset, _pos, _rot, [RIFLES, LAUNCHERS, PISTOLS, ITEM, GRENADES, VESTS, BACKPACKS, NVG, ATTACHMENT]];
            _pos = (getPosWorld _asset) vectorAdd (_tableSide vectorMultiply 0.5) vectorAdd [0, 0, 0.45];
            _result pushBack [_asset, _pos, _rot, [LAUNCHERS, PISTOLS, ITEM, VESTS, BACKPACKS, NVG]];
        };
        case ("Land_MapBoard_01_Wall_F"):
        {
            private _pos = (getPosWorld _asset) vectorAdd ((vectorDir _asset) vectorMultiply 0.05);
            private _rot = [getDir _asset + 180, 270, 0];
            _result pushBack [_asset, _pos, _rot, [PISTOLS, LAUNCHERS, AMMUNITION, ATTACHMENT, GRENADES, HELMET, ITEM, EXPLOSIVES, VESTS, BACKPACKS, NVG]];
        };
        case ("C_Soldier_VR_F"):
        {
            _result pushBack [_asset, [], 0, [PISTOLS, RIFLES, LAUNCHERS, AMMUNITION, ATTACHMENT, GRENADES, HELMET, ITEM, EXPLOSIVES]];
        };
    };
    _result;
};

private _fnc_chooseSpawnItem =
{
    private _fnc_getRandomNumber =
    {
        //Returns a number between 0 and 1
        params ["_meanValue", "_derivation"];

        private _result = _meanValue + sin (random 360) * _derivation;
        _result = (_result max 0) min 1;

        _result;
    };

    params ["_chooseArray", "_blockArray", "_supportPoint", "_alreadySelected"];
    private _arrayCopy = +_chooseArray;

    {
        _arrayCopy set [_x, 0];
    } forEach _blockArray;

    private _selection = shopArrayComplete selectRandomWeighted _arrayCopy;
    private _spawnItem = "";
    private _abort = 5;
    if(_selection#2) then
    {
        while {(_spawnItem == "") || (_spawnItem in _alreadySelected)} do
        {
            _spawnItem = selectRandom (_selection#0);
            _abort = _abort - 1;
            if(_abort < 0) exitWith
            {
                diag_log "Selection aborted, run into endless loop!";
            };
        };
    }
    else
    {
        while {(_spawnItem == "") || (_spawnItem in _alreadySelected)} do
        {
            private _itemCount = (count (_selection#0)) - 1;
            private _spawnItemIndex = ([_supportPoint, 0.2] call _fnc_getRandomNumber) * _itemCount;
            _spawnItem = (_selection#0)#_spawnItemIndex;
            _abort = _abort - 1;
            if(_abort < 0) exitWith
            {
                diag_log "Selection aborted, run into endless loop!";
            };
        };
    };

    _chooseArray set [_selection#1, (_chooseArray#(_selection#1)) - 1];
    [_selection#1, _spawnItem, _chooseArray];
};

private _fnc_spawnItem =
{
    params ["_type", "_item", "_slotPos", "_orientation", "_asset"];
    private _object = objNull;
    switch (_type) do
    {
        case (PISTOLS);
        case (RIFLES);
        case (LAUNCHERS):
        {
            _object = (format ["Weapon_%1", _item]) createVehicle _slotPos;
            _object setPosWorld _slotPos;
            [_object, _orientation] call BIS_fnc_setObjectRotation;
            _object setDamage 1;
            [_object, "CfgWeapons", _item, _type] call A3A_fnc_addShopActions;
        };
        case (AMMUNITION):
        {
            _object = "Box_NATO_Ammo_F" createVehicle _slotPos;
            _object enableSimulation false;
            _object setDamage 1;
            _object setPosWorld (_slotPos vectorAdd [0, 0, 0.26]);
            _object setDir ((_orientation#0) - 60);
            [_object, "CfgMagazines", _item, _type] call A3A_fnc_addShopActions;
        };
        case (GRENADES):
        {
            _object = "Box_NATO_Grenades_F" createVehicle _slotPos;
            _object enableSimulation false;
            _object setDamage 1;
            _object setPosWorld (_slotPos vectorAdd [0, 0, 0.26]);
            _object setDir ((_orientation#0) - 60);
            [_object, "CfgMagazines", _item, _type] call A3A_fnc_addShopActions;
        };
        case (EXPLOSIVES):
        {
            //These are bitches, maybe find a better way
            _object = "Box_NATO_AmmoOrd_F" createVehicle _slotPos;
            _object enableSimulation false;
            _object setDamage 1;
            _object setPosWorld (_slotPos vectorAdd [0, 0, 0.26]);
            _object setDir ((_orientation#0) - 60);
            [_object, "CfgMagazines", _item, _type] call A3A_fnc_addShopActions;
        };
        case (ITEM);
        case (ATTACHMENT):
        {
            _object = (format ["Item_%1", _item]) createVehicle _slotPos;
            _object setPosWorld (_slotPos vectorAdd [0, 0, 0.63]);
            [_object, _orientation] call BIS_fnc_setObjectRotation;
            _object setDamage 1;
            [_object, "CfgWeapons", _item, _type] call A3A_fnc_addShopActions;
        };
        case (NVG):
        {
            _asset enableSimulation true;
            _asset linkItem _item;
            _asset enableSimulation false;
            [_asset, "CfgWeapons", _item, _type] call A3A_fnc_addShopActions;
        };
        case (VESTS):
        {
            _asset enableSimulation true;
            _asset addVest _item;
            _asset enableSimulation false;
            [_asset, "CfgWeapons", _item, _type] call A3A_fnc_addShopActions;
        };
        case (BACKPACKS):
        {
            _asset enableSimulation true;
            _asset addBackpackGlobal _item;
            _asset enableSimulation false;
            [_asset, "CfgVehicles", _item, _type] call A3A_fnc_addShopActions;
        };
        case (HELMET):
        {
            _object = (format ["Headgear_%1", _item]) createVehicle _slotPos;
            _object setPosWorld _slotPos;//(_slotPos vectorAdd [0, 0, 0.05]);
            [_object, _orientation] call BIS_fnc_setObjectRotation;
            _object setDamage 1;
            [_object, "CfgWeapons", _item, _type] call A3A_fnc_addShopActions;
        };
    };
    if(!(isNull _object)) then
    {
        _object setVariable ["DoNotGarbageClean", true, true];
    };
    _object;
};

private _allObjects = [];

private _garageRight = vectorDir _garage;
private _garageUp = vectorUp _garage;
private _garageForward = _garageRight vectorCrossProduct _garageUp;
private _garagePos = getPosWorld _garage;
private _garageDir = getDir _garage;
private _slots = [];

{
    private _assetPos = _garagePos vectorAdd (_garageForward vectorMultiply _x#1#0) vectorAdd (_garageRight vectorMultiply _x#1#1) vectorAdd (_garageUp vectorMultiply _x#1#2);
    private _asset = (_x#0) createVehicle _garagePos;
    _asset allowDamage false;
    _asset enableSimulation false;
    _asset setDir (_x#2 + _garageDir);
    _asset setPosWorld (_assetPos vectorAdd [0,0,0.3]);
    clearItemCargoGlobal _asset;
    _slots append ([_asset] call _fnc_getSlotPositions);
    _allObjects pushBack _asset;
    if((_x#0) == "Box_NATO_Equip_F") then
    {
        //The sell box
        _asset spawn
        {
            sleep 1;
            _this enableSimulation true;
        };
        [_asset, ["Sell content of box", {[_this select 0] call A3A_fnc_sellBoxContent;}]] remoteExec ["addAction", [civilian, teamplayer], true];
    };
} forEach _assets;

private _chooseArray = [3, 8, 1, 3, 6, 6, 5, 7, 1, 6, 4, 3];
private _alreadySelected = [];
private _selectedItems = [];
{
    private _itemData = [_chooseArray, _x#3, _citySupportRatio, _alreadySelected] call _fnc_chooseSpawnItem;
    private _itemType = _itemData#0;
    private _item = _itemData#1;
    if(_item == "") then
    {
        diag_log format ["No selection done, staying empty"];
        diag_log format ["Slot was %1", _x];
    }
    else
    {
        _alreadySelected pushBack _item;
        _chooseArray = _itemData#2;
        diag_log format ["Selected %1 of type %2", _item, _itemType];
        diag_log format ["Slot was %1", _x];
        _allObjects pushBack ([_itemType, _item, _x#1, _x#2, _x#0] call _fnc_spawnItem);
    };
    _selectedItems pushBack [_itemType, _item];
} forEach _slots;



[_allObjects, _marker] spawn
{
    params ["_allObjects", "_marker"];
    waitUntil {sleep 10; (spawner getVariable _marker == 2)};
    {
        deleteVehicle _x;
    } forEach _allObjects;
};
