pl_at_defence_change_firing_pos= {
    params ["_unit", "_defPos", "_validLosPos", "_ccpPos"];

    _unit setVariable ["pl_at_chg_pos", _ccpPos];
    _unit setVariable ["pl_defPos", _defPos];

    private _changeEw = _unit addEventHandler ["Fired", {
        params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];

        if (([_weapon] call BIS_fnc_itemtype) select 1 in ["MissileLauncher", "RocketLauncher"] and ((getPosATL _unit)#2) < 2) then{


            [_unit, _weapon, _projectile, _magazine, _muzzle] spawn {
                params ["_unit", "_weapon", "_projectile", "_magazine", "_muzzle"];


                if ((([secondaryWeapon _unit] call BIS_fnc_itemtype) select 1) == "MissileLauncher") then {
                    waitUntil {sleep 0.1; (speed _projectile) <= 0 or isNull _projectile};
                } else {
                    sleep 0.1;
                };

                [group _unit, getPos _unit] call pl_group_throw_smoke;
                _unit setUnitCombatMode "BLUE";
                _unit enableAI "PATH";
                _unit disableAI "TARGET";
                _unit disableAI "AUTOTARGET";
                _unit disableAI "WEAPONAIM";
                _unit disableAI "FIREWEAPON";
                _unit setUnitPos "AUTO";
                _unit disableAI "AUTOCOMBAT";
                _unit setBehaviourStrong "AWARE";
                _unit forceSpeed 100;
                _unit setVariable ['pl_is_at', true];
                private _chgPos = _unit getVariable ["pl_at_chg_pos", getPos _unit];
                _unit doMove _chgPos;
                _unit setDestination [_chgPos, "LEADER DIRECT", true];
                _unit setUnitTrait ["camouflageCoef", 0.1, false];
                sleep 0.5;

                _loadedAmmo = _unit ammo _muzzle;
                // systemChat (str _loadedAmmo);

                _unit removeWeapon _weapon;
                sleep 0.05;
                _unit addWeapon _weapon;
                sleep 1;

                if (_loadedAmmo > 0) then {
                    // systemChat "oof";
                    _unit addMagazines [_magazine, 1];
                };

                // private _newMissileCount = ({toUpper _x in (getArray (configFile >> "CfgWeapons" >> secondaryWeapon _unit >> "magazines") apply {toUpper _x})} count magazines _unit);

                waitUntil {sleep 0.5; unitReady _unit or (!alive _unit) or !((group _unit) getVariable ["onTask", true]) or (_unit distance2D _chgPos) <= 1};


                _unit setUnitCombatMode "YELLOW";
                _unit enableAI "TARGET";
                _unit enableAI "AUTOTARGET";
                _unit enableAI "WEAPONAIM";
                _unit enableAI "FIREWEAPON";
                _unit setUnitTrait ["camouflageCoef", 0.5, false];
                _unit forceSpeed -1;
                // deleteVehicle _weaponFake;
                sleep 0.1;
                private _defPos = _unit getVariable ["pl_defPos", getPos _unit];
                _unit doMove _defPos;

                waitUntil {sleep 0.5; unitReady _unit or (!alive _unit) or !((group _unit) getVariable ["onTask", true]) or (_unit distance2D _defPos) <= 1};

                _unit setVariable ['pl_is_at', false];
                [_unit, 2, getDir _unit, true] spawn pl_find_cover;
            };

        };

    }];

    waitUntil {sleep 1; !((group _unit) getVariable ["onTask", true])};

    _unit removeEventHandler ["Fired", _changeEw];

};