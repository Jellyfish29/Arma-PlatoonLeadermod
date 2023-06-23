
pl_get_has_static = {
    params ["_group"];

    private _supportUnits = units _group;
    if ((count _supportUnits) < 2) exitWith {false};
    private _gunner = 
    {
        if (unitBackpack _x isKindOf "Weapon_Bag_Base") exitWith {_x};
        
        objNull
    } forEach _supportUnits;

    if (isNull _gunner) exitWith {false}; // changed by Jellyfish
    if ((backpack _gunner) in ["B_UAV_01_backpack_F", "O_UAV_01_backpack_F", "I_UAV_01_backpack_F", "I_E_UAV_01_backpack_F"]) exitWith {false};

    _group setVariable ["pl_static_bag_gun", backpack _gunner];

    private _cfgBase = configFile >> "CfgVehicles" >> backpack _gunner >> "assembleInfo" >> "base";
    private _compatibleBases = if (isText _cfgBase) then {[getText _cfgBase]} else {getArray _cfgBase};
    // if (_compatibleBases isEqualTo [""]) then {_compatibleBases = []};
    private _assistant = objNull;
    if (_compatibleBases isEqualTo [""]) then {
        _assistant = _gunner;
    } else {
        _assistant = 
        {   
            // private _xx = _x;
            
            // if ({unitBackpack _xx isKindOf _x} count _compatibleBases > 0) exitWith {_xx};
            
            // objNull
            _cfgBaseAssistant = configFile >> "CfgVehicles" >> backpack _x >> "assembleInfo" >> "base";
            _compatibleBasesAssistant = if (isText _cfgBaseAssistant) then {[getText _cfgBaseAssistant]} else {getArray _cfgBaseAssistant};
            if ((backpack _x) in _compatibleBases || { (backpack _gunner) in _compatibleBasesAssistant}) exitWith {_x};
            objNull
        }
        forEach (_supportUnits - [_gunner]);
    };

    if (!(isNull _gunner) and (!(isNull _assistant) or (_gunner == _assistant))) exitWith {true};
    false
};

pl_toggle_static = {
    params [["_group", (hcSelected player) select 0]];

    if !([_group] call pl_get_has_static) exitWith {hint "NO Static Weapon in Group"};

    if (_group getVariable ["pl_allow_static", false]) exitWith {
        _group setVariable ["pl_allow_static", nil];
        hint "Set to NOT Deploy";
    };
    _group setVariable ["pl_allow_static", true];
    hint "Set to Deploy";
};


pl_static_unpack = {
    params ["_supportUnits", "_group", "_weaponPos", "_targetPos"];


    // private _supportUnits = units _group;
    if ((count _supportUnits) < 2) exitWith {[false, []]};
    private _gunner = 
    {
        if (unitBackpack _x isKindOf "Weapon_Bag_Base") exitWith {_x};
        
        objNull
    } forEach _supportUnits;

    if (isNull _gunner) exitWith {[false, []]}; // changed by Jellyfish
    if (((backpack _gunner) in ["B_UAV_01_backpack_F", "O_UAV_01_backpack_F", "I_UAV_01_backpack_F", "I_E_UAV_01_backpack_F"]) or (_gunner getVariable ["pl_is_uav_operator", false])) exitWith {[false, []]};

    _group setVariable ["pl_static_bag_gun", backpack _gunner];

    private _cfgBase = configFile >> "CfgVehicles" >> backpack _gunner >> "assembleInfo" >> "base";
    private _compatibleBases = if (isText _cfgBase) then {[getText _cfgBase]} else {getArray _cfgBase};
    // if (_compatibleBases isEqualTo [""]) then {_compatibleBases = []};
    private _assistant = objNull;
    if (_compatibleBases isEqualTo [""]) then {
        _assistant = _gunner;
    } else {
        _assistant = 
        {   
            // private _xx = _x;
            
            // if ({unitBackpack _xx isKindOf _x} count _compatibleBases > 0) exitWith {_xx};
            
            // objNull
            _cfgBaseAssistant = configFile >> "CfgVehicles" >> backpack _x >> "assembleInfo" >> "base";
            _compatibleBasesAssistant = if (isText _cfgBaseAssistant) then {[getText _cfgBaseAssistant]} else {getArray _cfgBaseAssistant};
            if ((backpack _x) in _compatibleBases || { (backpack _gunner) in _compatibleBasesAssistant}) exitWith {_x};
            objNull
        }
        forEach (_supportUnits - [_gunner]);
    };

    if (isNull _assistant) exitWith {[false, []]}; // changed by Jellyfish

    _group setVariable ["pl_static_bag_base", backpack _assistant];

    _gunner addEventHandler ["WeaponAssembled", 
    {
        _gunner = _this#0;
        _weapon = _this#1;
        _weapon setUnitTrait ["camouflageCoef", 0, true];
        [_gunner] allowGetIn true;
        _gunner assignAsGunner _weapon;
        _gunner moveInGunner _weapon;
        pl_actvie_mg_gunners pushBack _gunner;
        _gunner setVariable ['pl_in_static', true];
        _gunner removeEventHandler ["WeaponAssembled", _thisEventHandler];

        (group _gunner) setVariable ["pl_group_static", _weapon];
    }]; 

    [_gunner, _assistant, _targetPos, _weaponPos, _group] spawn {
        params ["_gunner", "_assistant", "_targetPos", "_weaponPos", "_group"];

        _gunner disableAI "AUTOCOMBAT";
        _gunner disableAI "AUTOTARGET";
        _gunner disableAI "TARGET";
        _gunner setUnitTrait ["camouflageCoef", 0, true];
        _gunner setVariable ["pl_damage_reduction", true];
        // _gunner disableAI "FSM";
        _gunner doMove _weaponPos;
        _gunner setDestination [_weaponPos, "FORMATION PLANNED", false];
        sleep 1;
        private _counter = 0;
        while {alive _gunner and ((group _gunner) getVariable ["onTask", true])} do {
            sleep 0.5;
            _dest = [_gunner, _weaponPos, _counter] call pl_position_reached_check;
            if (_dest#0) exitWith {};
            _counter = _dest#1;
        };
        // waitUntil {sleep 0.5; unitReady _unit or (!alive _unit) or !((group _unit) getVariable ["onTask", true])};
        _gunner enableAI "AUTOCOMBAT";
        _gunner enableAI "AUTOTARGET";
        _gunner enableAI "TARGET";

        if (_group getVariable ["onTask", true]) then {
            if (_assistant != _gunner) then {
                _weaponBase = unitBackpack _assistant;
                sleep 0.2;
                _gunner action ["PutBag", _assistant];
                _gunner action ["Assemble", _weaponBase];
            } else {
                _gunner action ["Assemble"];
            };
            _weapon = vehicle _gunner;

            waitUntil{sleep 0.5; vehicle _gunner != _gunner or !alive _gunner};

            [] call pl_show_fire_support_menu;
            _weapon = vehicle _gunner;       
            _pos = getPosASL _weapon;   
            _pos = [_pos#0, _pos#1, _pos#2 + 1.5];
            _weapon setPosASL _pos;
            _weapon setVectorUp surfaceNormal position _weapon;
            _weapon setDir (_weaponPos getDir _targetPos);

            _icon = getText (configfile >> 'CfgVehicles' >> typeof _weapon >> 'icon');
            _group setVariable ["specialIcon", _icon];
        };
    };
    [true, [_gunner, _assistant]]
};

pl_static_pack = {
    params ["_group", "_weapon", "_crew"];

    private _gunner = _crew#0;
    private _assistant = _crew#1;

    if !(alive _gunner) then {
        _gunner = {
            if (!(_x in _crew) and (isNull (unitBackpack _x)) and alive _x) exitWith {_x};
            objNull
        } forEach (units _group);
    };

    if (isNull _gunner) exitWith {false};

    if (!(alive _assistant) and !(_assistant == _gunner)) then {
        _assistant = {
            if (!(_x in _crew) and (isNull (unitBackpack _x)) and alive _x) exitWith {_x};
            objNull
        } forEach (units _group);
    };

    if (isNull _assistant) exitWith {false};


    [_weapon, _gunner, _assistant, _group] spawn {
        params ["_weapon", "_gunner", "_assistant", "_group"];

        _gun = _group getVariable ["pl_static_bag_gun", objNull];
        _base = _group getVariable ["pl_static_bag_base", objNull];

        _group leaveVehicle assignedVehicle _gunner;
        unassignVehicle _gunner;

        sleep 1;

        deleteVehicle _weapon;

        _gunner addBackpack _gun;
        _gunner setVariable ['pl_in_static', nil];

        if (_assistant != _gunner) then {
            _assistant addBackpack _base;
        };

        pl_actvie_mg_gunners deleteat (pl_actvie_mg_gunners find _gunner);

        [] call pl_show_fire_support_menu;
    };

};