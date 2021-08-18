#include "..\..\Includes\common.inc"
FIX_LINE_NUMBERS()

params ["_item", "_name", "_actionID", "_object"];

private _fnc_improvementRamp =
{
    params ["_alreadyBought"];
    private _increase = 0;
    switch (_alreadyBought) do
    {
        case (0): {_increase = 1;};
        case (1): {_increase = 0.9;};
        case (2): {_increase = 0.75;};
        case (3): {_increase = 0.6;};
        case (4): {_increase = 0.5;};
        case (5): {_increase = 0.4;};
        default {_increase = 0.25;};
    };
    _increase;
};

private _itemData = missionNamespace getVariable [format ["%1_data", _item], []];
if(count _itemData == 0) exitWith
{
    Error_1("%1 does not have any data defined", _item);
};

private _increase = [_itemData#2] call _fnc_improvementRamp;

private _firstBuy = (_itemData#2 == 0);

_itemData set [2, _itemData#2 + 1];
//Check if magazine
if(_itemData#1 == 4) then
{
    private _bulletCount = getNumber (configFile >> "CfgMagazines" >> _item >> "count");
    _itemData set [3, _itemData#3 + round (_increase * _bulletCount)];
}
else
{
    _itemData set [3, _itemData#3 + _increase];
    if(_itemData#1 < 3) then
    {
        //Unlock at least one ammo type for it too
        private _magazine = (getArray (configFile >> "CfgWeapons" >> _item >> "magazines")) # 0;
        private _ammoData = missionNamespace getVariable [format ["%1_data", _magazine], []];
        if(_ammoData#3 <= 0) then
        {
            private _bulletCount = getNumber (configFile >> "CfgMagazines" >> _magazine >> "count");
            _ammoData set [3, _bulletCount];
            A3A_allSupplies pushBack [_magazine, _bulletCount];
            unlockedMagazines pushBack _magazine;
        }
    };
};
A3A_allSupplies set [_item, _itemData#3];
publicVariable "A3A_allSupplies";


private _basePrice = _object getVariable ["basePrice", 0];
private _supplyPrice = round (_basePrice * exp ((_itemData#2)/20)) * 5;

_object setVariable ["supplyPrice", _supplyPrice, true];

[_object, [_actionID, format ["Buy %1 supply for %2", _name, _supplyPrice]]] remoteExec ["setUserActionText", [civilian, teamPlayer], true];

if(_firstBuy) then
{
    private _categories = _item call A3A_fnc_equipmentClassToCategories;

    {
    	private _categoryName = _x;
    	//Consider making this pushBackUnique.
    	(missionNamespace getVariable ("unlocked" + _categoryName)) pushBack _item;
    	publicVariable ("unlocked" + _categoryName);
    } forEach _categories;
};

private _updated = format ["%1 increased to %2/h gain", _name, _itemData#3];
_updated = format ["<t size='0.5' color='#C1C0BB'>Arsenal Updated<br/><br/>%1</t>",_updated];
[petros,"income",_updated] remoteExec ["A3A_fnc_commsMP",[teamPlayer,civilian]];
