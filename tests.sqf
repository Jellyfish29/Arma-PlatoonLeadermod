pl_at_defence_change_firing_pos= {
    params ["_unit", "_defPos", "_validLosPos", "_ccpPos"];

    _unit setVariable ["pl_at_reverse_pos", _ccpPos];
    _unit setVariable ["pl_defPos", _defPos];

    private _changeEw = _unit addEventHandler ["Fired", {
        params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];

        if (([_weapon] call BIS_fnc_itemtype) select 1 in ["MissileLauncher", "RocketLauncher"] and ((getPosATL _unit)#2) < 2) then {

            [_unit, _weapon, _projectile, _magazine, _muzzle] spawn {
                params ["_unit", "_weapon", "_projectile", "_magazine", "_muzzle"];

                private _disposable = true;
                _missileCount = {toUpper _x in (getArray (configFile >> "CfgWeapons" >> secondaryWeapon _unit >> "magazines") apply {toUpper _x})} count magazines _unit;
                // _missileCount = _missileCount + 1;

                systemchat str (_missileCount);

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
                _unit setUnitPos "DOWN";
                _unit disableAI "AUTOCOMBAT";
                _unit setBehaviourStrong "AWARE";
                _unit disableAI "FSM";
                _unit forceSpeed 100;
                // _unit setVariable ['pl_is_at', true];
                private _chgPos = _unit getVariable ["pl_at_reverse_pos", getPos _unit];
                _unit doMove _chgPos;
                _unit setDestination [_chgPos, "LEADER DIRECT", true];
                _unit setUnitTrait ["camouflageCoef", 0.1, false];
                sleep 0.5;

                _loadedAmmo = _unit ammo _muzzle;
                // systemChat (str _loadedAmmo);

                if ((secondaryWeapon _unit) isNotEqualTo "") then {
                    _unit removeWeapon _weapon;
                    _unit switchMove "";
                    _disposable = false;
                    // sleep 0.1;
                    // _unit addWeapon _weapon;
                };

                // private _newMissileCount = ({toUpper _x in (getArray (configFile >> "CfgWeapons" >> secondaryWeapon _unit >> "magazines") apply {toUpper _x})} count magazines _unit);
                private _time = time + 15;

                waitUntil {sleep 0.5; time >= _time or unitReady _unit or (!alive _unit) or !((group _unit) getVariable ["onTask", true]) or (_unit distance2D _chgPos) <= 1 or lifeState _unit isEqualTo "INCAPACITATED" or _unit checkAIFeature "FIREWEAPON"};

                _newMissileCount = {toUpper _x in (getArray (configFile >> "CfgWeapons" >> secondaryWeapon _unit >> "magazines") apply {toUpper _x})} count magazines _unit;

                systemchat str (_newMissileCount);
                
                _unit addWeapon _weapon;
                if (!_disposable and _newMissileCount < _missileCount) then {
                    _unit addMagazines [_magazine, 1];
                };
                _unit setUnitPos "AUTO";
                _unit setUnitCombatMode "YELLOW";
                _unit enableAI "TARGET";
                _unit enableAI "AUTOTARGET";
                _unit enableAI "WEAPONAIM";
                _unit enableAI "FIREWEAPON";
                _unit setUnitTrait ["camouflageCoef", 0.5, false];
                _unit enableAI "FSM";
                _unit forceSpeed -1;

                sleep 0.1;
                private _defPos = _unit getVariable ["pl_sec_defPos", getPos _unit];
                _unit doMove _defPos;

                _unit setVariable ["pl_sec_defPos", _unit getVariable ["pl_defPos", _defPos]];
                _unit setVariable ["pl_defPos", _defPos];

                waitUntil {sleep 0.5; unitReady _unit or (!alive _unit) or !((group _unit) getVariable ["onTask", true]) or (_unit distance2D _defPos) <= 1 or lifeState _unit isEqualTo "INCAPACITATED"};

                // _unit setVariable ['pl_is_at', false];
                [_unit, 2, getDir _unit, true] spawn pl_find_cover;
            };

        };

    }];

    waitUntil {sleep 1; !((group _unit) getVariable ["onTask", true])};

    _unit removeEventHandler ["Fired", _changeEw];

};

pl_at_defence = {
    params ["_atSoldier", "_group", "_defencePos", "_defenceAreaSize", "_defenceDir", "_startPos", "_atEscord"];
    private ["_checkPosArray", "_watchPos", "_targets", "_debugMarkers", "_rifle"];

    _atEscord = objNull;

    sleep 0.5;

    _time = time + 10;
    waitUntil {sleep 0.5;  time >= _time or !(_group getVariable ["onTask", false])};
    if !(_group getVariable ["onTask", false]) exitWith {};

    _watchPos = (getPos _atSoldier) getPos [100, _defenceDir];

    private _weaponInfo = _atSoldier weaponsInfo [secondaryWeapon _atSoldier];
    private _weaponIndex = (_weaponInfo#0)#0;
    private _muzzleName = (_weaponInfo#0)#3;
    private _firemode = (_weaponInfo#0)#4;
    _rifle = primaryweapon _atSoldier;

    _defenceAreaSize = _defenceAreaSize + 50;


    while {sleep 0.5; alive _atSoldier and _group getVariable ["onTask", false]} do {

        // _group enableAttack true;

        if ((_atSoldier getVariable ["pl_wia", false]) or (((secondaryWeaponMagazine _atSoldier) isEqualTo []) and ({toUpper _x in (getArray (configFile >> "CfgWeapons" >> secondaryWeapon _atSoldier >> "magazines") apply {toUpper _x})} count magazines _atSoldier) <= 0)) then {
            _group setVariable ["pl_grp_active_at_soldier", nil];
            waitUntil {sleep 0.5; !(_atSoldier getVariable ["pl_wia", false]) and !((secondaryWeaponMagazine _atSoldier) isEqualTo [])};
        };

        if !((_group getVariable ["pl_grp_active_at_soldier", objNull]) == _atSoldier) then {
            waitUntil {sleep 0.5; !(_atSoldier getVariable ["pl_wia", false]) and !((secondaryWeaponMagazine _atSoldier) isEqualTo []) and (isNull (_group getVariable ["pl_grp_active_at_soldier", objNull]))};
        };

        // _vics = nearestObjects [_watchPos, ["Car", "Tank"], 300, true];
        _vics = _watchPos nearEntities [["Car", "Tank", "Truck"], 600];

        _targets = [];
        {
            // if (speed _x <= 3 and alive _x and (count (crew _x) > 0) and (_atSoldier knowsAbout _x) >= 0.5 and !((getPos _x) call pl_is_city) or _x getVariable ["pl_at_enaged", false] ) then {
            if (speed _x <= 15 and alive _x and (count (crew _x) > 0) and (_atSoldier knowsAbout _x) >= 0.1) then {
                _targets pushBack _x;
            };
        } forEach (_vics select {[(side _x), playerside] call BIS_fnc_sideIsEnemy});

        if (count _targets > 0 and !((secondaryWeaponMagazine _atSoldier) isEqualTo []) and _atSoldier checkAIFeature "FIREWEAPON") then {
            _targets = [_targets, [], {_x distance2D (getPos _atSoldier)}, "ASCEND"] call BIS_fnc_sortBy;
            _target = _targets#0;

            _debugMarkers = [];
            _checkPosArray = [];
            // _atkDir = _atSoldier getDir _target;

            _atkDir = _defencePos getDir _target;
            _lineStartPos = _startPos getPos [_defenceAreaSize, _atkDir - 90];
            _lineStartPos = _lineStartPos getPos [15, _atkDir];
            _lineOffset = 0;
            for "_i" from 0 to (_defenceAreaSize / 2) do {
                for "_j" from 0 to (_defenceAreaSize * 2) do { 
                    _checkPos = _lineStartPos getPos [_lineOffset, _atkDir + 90];
                    _lineOffset = _lineOffset + 1;

                    _checkPos = [_checkPos, 0.5] call pl_convert_to_heigth_ASL;

                    // _m = createMarker [str (random 1), _checkPos];
                    // _m setMarkerType "mil_dot";
                    // _m setMarkerSize [0.2, 0.2];
                    // _debugMarkers pushBack _m;

                    _vis = lineIntersectsSurfaces [_checkPos, AGLToASL (unitAimPosition _target), _target, vehicle _target, true, 1, "VIEW"];
                    // _vis2 = [_target, "VIEW", _target] checkVisibility [_checkPos, AGLToASL (unitAimPosition _target)];
                    if (_vis isEqualTo []) then {
                        _checkPosArray pushBack _checkPos;
                        // _m setMarkerColor "colorRED";
                    };
                };
                _lineStartPos = _lineStartPos getPos [1, _atkDir];
                _lineOffset = 0;
            };

            if (count _checkPosArray > 0 and !((secondaryWeaponMagazine _atSoldier) isEqualTo []) and _atSoldier checkAIFeature "FIREWEAPON") then {

                _target setVariable ["pl_at_enaged", true];

                [(group (driver _target)), true] call Pl_marta;

                // _group enableAttack true;

                _movePos = ([_checkPosArray, [], {_atSoldier distance2D _x}, "ASCEND"] call BIS_fnc_sortBy) select 0;

                if (_movePos distance2D _atSoldier <= 80) then {

                    doStop _atSoldier;
                    _atSoldier enableAI "PATH";
                    _atSoldier setUnitPosWeak "Middle";
                    _atSoldier setUnitCombatMode "RED";
                    _atSoldier enableAI "FIREWEAPON";
                    _atSoldier enableAI "TARGET";
                    _atSoldier enableAI "AUTOTARGET";
                    _atSoldier enableAI "WEAPONAIM";
                    _atSoldier enableAI "FIREWEAPON";
                    // _atSoldier disableAI "TARGET";
                    // _atSoldier disableAI "AUTOTARGET";
                    _atSoldier disableAI "AUTOCOMBAT";
                    // _atSoldier disableAI "FSM";
                    _atSoldier setBehaviourStrong "AWARE";
                    _atSoldier setUnitTrait ["camouflageCoef", 0.1, true];
                    _atSoldier setVariable ["pl_damage_reduction", true];
                    _atSoldier setVariable ['pl_is_at', true];
                    _atSoldier setVariable ["pl_engaging", true];

                    _atSoldier enableAI "PATH";
                    _atSoldier disableAI "AIMINGERROR";
                    _atSoldier disableAI "SUPPRESSION";
                    _atSoldier doTarget objNull;
                    _atSoldier doWatch objNull;

                    _group setVariable ["pl_grp_active_at_soldier", _atSoldier];
                    pl_at_attack_array pushBack [_atSoldier, _target, _atEscord];


                    _movePos = _movePos getpos [5, _movePos getdir _target];
                    _atSoldier setHit ["legs", 0];
                    _atSoldier doMove _movePos;

                    // _m = createMarker [str (random 1), _movePos];
                    // _m setMarkerType "mil_dot";
                    // _m setMarkerColor "colorGreen";
                    // _m setMarkerSize [0.7, 0.7];
                    // _debugMarkers pushBack _m;


                    _time = time + (((_atSoldier distance _movePos) / 1.6) + 10);
                    _atSoldier reveal [_target, 4];
                    // _atSoldier commandTarget _target;
                    // _atSoldier commandFire _target;

                    waitUntil {sleep 0.5; time >= _time or !(_group getVariable ["onTask", false]) or !alive _target or ((secondaryWeaponMagazine _atSoldier) isEqualTo []) or ((secondaryWeapon _atSoldier) isEqualTo "")};

                    if (time >= _time) then {
                        _atSoldier doMove _defencePos;
                    };
                    // _atSoldier enableAI "FSM";
                    // pl_at_attack_array = pl_at_attack_array - [[_atSoldier, _movePos]];
                };
            };

            pl_at_attack_array = pl_at_attack_array - [[_atSoldier, _target, _atEscord]];
            _atSoldier setVariable ['pl_is_at', false];
            _atEscord setVariable ['pl_is_at', false];
        };
        _timeOut = time + 5;
        waitUntil {sleep 0.5; time >= _timeOut or !((group _atSoldier) getVariable ["onTask", false])};
    };

    _group enableAttack false;
    _group setVariable ["pl_grp_active_at_soldier", nil];
    if !(isNil "_target") then {pl_at_attack_array = pl_at_attack_array - [[_atSoldier, _target, _atEscord]]}; 
};



// {toUpper _x in (getArray (configFile >> "CfgWeapons" >> secondaryWeapon cursorTarget >> "magazines") apply {toUpper _x})} count magazines cursorTarget


// pl_opfor_aggressivness = 0.6;
// pl_debug = true;
// pl_active_opfor_vic_grps = [];
// {
//     (group (driver _x)) execFSM "pl_opfor_cmd_vic_2.fsm";
//     pl_active_opfor_vic_grps pushback (group (driver _x));
// } forEach (vehicles select {side _x == east});

// {
//     if !(_x in pl_active_opfor_vic_grps) then {
//         _x execFSM "pl_opfor_cmd_inf_2.fsm";
//     };
// } forEach (allGroups select {side _x == east});

// execFSM "pl_opfor_cmd_commander.fsm"
