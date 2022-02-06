pl_mortar_names = ["B_Mortar_01_F", "B_T_Mortar_01_F", "O_Mortar_01_F", "O_T_Mortar_01_F", "I_Mortar_01_F"];

pl_reworked_bis_unpack = {
    
        // Author: 
        //     Dean "Rocket" Hall, reworked by Killzone_Kid

        // Description:
        //     This function will move given support team to the given position
        //     The weapon crew will unpack carried weapon and start watching given position
        //     Requires three personnel in the team: Team Leader, Gunner and Asst. Gunner
        //     This function is MP compatible
        //     When weapon is unpacked, scripted EH "StaticWeaponUnpacked" is called with the following params: [group, leader, gunner, assistant, weapon]

        // Parameters:
        //     0: GROUP or OBJECT - the support team group or a unit from this group 
        //     1: ARRAY, STRING or OBJECT - weapon placement position, object position or marker
        //     2: ARRAY, STRING or OBJECT - target position, object position to watch or marker
        //     3: (Optional) ARRAY, STRING or OBJECT - position, object or marker group leader should move to
            
        // Returns:
        //     NOTHING
        
        // NOTE:
        //     If a unit flees, all bets are off and the function will exit leaving units on their own
        //     To guarantee weapon assembly, make sure the group has maximum courage (_group allowFleeing 0)
        
        // Example1:
        //     [leader1, "weapon_mrk", "target_mrk"] call BIS_fnc_unpackStaticWeapon;
            
        // Example2:
        //     group1 allowFleeing 0;
        //     [group1, "weapon_mrk", tank1, "leader_mrk"] call BIS_fnc_unpackStaticWeapon;
    

    params [
        ["_group", grpNull, [grpNull, objNull]], 
        ["_weaponPos", [0,0,0], [[], "", objNull], 3],
        ["_targetPos", [0,0,0], [[], "", objNull], 3],
        ["_leaderPos", [0,0,0], [[], "", objNull], 3]
    ];

    private _leader = leader _group;
    if (!local _leader) exitWith {_this remoteExecCall ["BIS_fnc_unpackStaticWeapon", _leader]};

    private _err_badGroup = 
    {
        ["Bad group! The group should exist and consist of minimum a Leader, Gunner and Asst. Gunner"] call BIS_fnc_error;
        nil
    };

    private _err_badPosition = 
    {
        ["Bad position! Position should exist and could be array, marker or object"] call BIS_fnc_error;
        nil
    };

    if (_group isEqualType objNull) then {_group = group _group};
    if (isNull _group) exitWith _err_badGroup;

    if (_weaponPos isEqualType "") then {_weaponPos = getMarkerPos _weaponPos};
    if (_weaponPos isEqualType objNull) then {_weaponPos = getPosATL _weaponPos};
    if (_weaponPos isEqualTo [0,0,0]) exitWith _err_badPosition;

    if (_targetPos isEqualType "") then {_targetPos = getMarkerPos _targetPos};
    if (_targetPos isEqualType objNull) then {_targetPos = getPosATL _targetPos};
    if (_targetPos isEqualTo [0,0,0]) exitWith _err_badPosition;

    if (_leaderPos isEqualType "") then {_leaderPos = getMarkerPos _leaderPos};
    if (_leaderPos isEqualType objNull) then {_leaderPos = getPosATL _leaderPos};

    private _cfg = configFile >> "CfgVehicles";
    private _supportUnits = ((units _group) - [_leader]); // changed by jellyfish from (units _group - [_leader]) select {getText (_cfg >> typeOf _x >> "vehicleClass") == "MenSupport"};
    if ((count _supportUnits) < 2) exitWith {[false, []]};
    private _gunner = 
    {
        if (unitBackpack _x isKindOf "Weapon_Bag_Base") exitWith {_x};
        
        objNull
    } forEach _supportUnits;

    if (isNull _gunner) exitWith {[false, []]}; // changed by Jellyfish

    private _cfgBase = configFile >> "CfgVehicles" >> backpack _gunner >> "assembleInfo" >> "base";
    private _compatibleBases = if (isText _cfgBase) then {[getText _cfgBase]} else {getArray _cfgBase};
    if (_compatibleBases isEqualTo [""]) then {_compatibleBases = []};
    private _assistant = 
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

    if (isNull _assistant) exitWith {[false, []]}; // changed by Jellyfish

    player hcRemoveGroup _group;
    
    // -- calculate optimal positions for weapon crew
    private _targetDir = _weaponPos getDir _targetPos;
    private _assistantPos = _weaponPos getPos [1.5, _targetDir + 90]; _assistantPos set [2, _weaponPos select 2]; // -- keep z
    private _gunnerPos = _weaponPos getPos [1.5, _targetDir - 90]; _gunnerPos set [2, _weaponPos select 2]; // -- keep z

    if (_gunner distance2D _gunnerPos > _gunner distance2D _assistantPos) then
    {
        // -- swap
        private _tmp = _gunnerPos; _gunnerPos = _assistantPos; _assistantPos = _tmp;
    }; 

    _gunner addEventHandler ["WeaponAssembled", format [
        '
            params ["_gunner", "_weapon"];
            
            _gunner removeEventHandler ["WeaponAssembled", _thisEventHandler];
            
            _weapon setDir (_weapon getDir %3);
            _weapon setPosATL getPosATL _gunner;

        
            [_gunner] allowGetIn true;
            _gunner assignAsGunner _weapon;
            _gunner moveInGunner _weapon;
            _gunner doWatch %3;
            
            _leader = "%1" call BIS_fnc_objectFromNetId;
            _assistant = "%2" call BIS_fnc_objectFromNetId;
            
            _group = group _gunner;
            _group addVehicle _weapon;

            
            [_group, "StaticWeaponUnpacked", [_group, _leader, _gunner, _assistant, _weapon]] call BIS_fnc_callScriptedEventHandler;
        ', 
                    
        _leader call BIS_fnc_netId,
        _assistant call BIS_fnc_netId,
        _targetPos
    ]]; 

    ((units _group) - [_gunner]) allowGetIn false;

    // -- leader logic
    [_leader, _leaderPos, _targetPos] spawn
    {
        params ["_leader", "_leaderPos", "_targetPos"];
        
        waitUntil {isNull (_leader getVariable ["BIS_staticWeaponLeaderScript", scriptNull])};
        _leader setVariable ["BIS_staticWeaponLeaderScript", _thisScript];
        
        if !(_leaderPos isEqualTo [0,0,0]) then
        {
            _leader doWatch _targetPos;
            _leader doMove _leaderPos;
            
            waitUntil {unitReady _leader};  
        };
        
        if (fleeing _leader) exitWith {};
        
        doStop _leader;
        
        _leader setUnitPos "MIDDLE";
        _leader doWatch _targetPos;

        waitUntil {stance _leader isEqualTo "CROUCH" || !alive _leader};
        
        _leader selectWeapon binocular _leader;
        // _markerName = format ["defence%1", (group _leader)];
        // _leader disableAI "PATH";
        // pl_denfence_draw_array = pl_denfence_draw_array - [[_markerName, _leader]];
    };

    // -- assistant logic
    private _assistantReady = [_assistant, _assistantPos, _targetPos] spawn
    {
        params ["_assistant", "_assistantPos", "_targetPos"];
        
        _assistant doWatch _targetPos;
        _assistant doMove _assistantPos;

        sleep 1;
        
        waitUntil {unitReady _assistant};
        
        if (fleeing _assistant) exitWith {};
        
        doStop _assistant;
        
        _assistant setUnitPos "MIDDLE";
        _assistant doWatch _targetPos;
        
        waitUntil {stance _assistant isEqualTo "CROUCH" || !alive _assistant};
    };

    // -- gunner logic
    
    [_gunner, _gunnerPos, _targetPos, _assistant, _assistantReady, _group] spawn
    {
        params ["_gunner", "_gunnerPos", "_targetPos", "_assistant", "_assistantReady", "_group"];
            
        _gunner doWatch _targetPos;
        _gunner doMove _gunnerPos;

        sleep 1;

        waitUntil {unitReady _gunner};
        
        if (!alive _gunner || fleeing _gunner) exitWith {_gunner removeAllEventHandlers "WeaponAssembled"; player hcSetGroup [_group];};
        
        doStop _gunner;
        
        _gunner setUnitPos "MIDDLE";
        _gunner doWatch _targetPos;
        
        waitUntil {stance _gunner isEqualTo "CROUCH" || !alive _gunner};
        waitUntil {scriptDone _assistantReady};
        
        if (!alive _assistant || fleeing _assistant) exitWith {_gunner removeAllEventHandlers "WeaponAssembled"; player hcSetGroup [_group];};
        
        // -- unpack weapon
        _weaponBase = unitBackpack _assistant;
        _gunner action ["PutBag", _assistant];
        _gunner action ["Assemble", _weaponBase];
        sleep 2;
        _weapon = vehicle _gunner;
        [] call pl_show_fire_support_menu;        
        _pos = getPosASL _weapon;
        _pos = [_pos#0, _pos#1, _pos#2 + 1.5];
        _weapon setPosASL _pos;
        _weapon setVectorUp surfaceNormal position _weapon;

        _icon = getText (configfile >> 'CfgVehicles' >> typeof _weapon >> 'icon');

        _group setVariable ["specialIcon", _icon];

        sleep 1;
        player hcSetGroup [_group];



    };
    [true, [_leader, _gunner, _assistant]]
};



    // Author: 
    //     Dean "Rocket" Hall, reworked by Killzone_Kid

    // Description:
    //     This function will make weapon team pack a static weapon
    //     The weapon crew will pack carried weapon (or given weapon if different) and follow leader
    //     Requires three personnel in the team: Team Leader, Gunner and Asst. Gunner
    //     This function is MP compatible
    //     When weapon is packed, scripted EH "StaticWeaponPacked" is called with the following params: [group, leader, gunner, assistant, weaponBag, tripodBag]

    // Parameters:
    //     0: GROUP or OBJECT - the support team group or a unit from this group
    //     1: (Optional) OBJECT - weapon to pack. If nil, current group weapon is packed
    //     2: (Optional) ARRAY, STRING or OBJECT - position, object or marker the group leader should move to after weapon is packed. By default the group will
    //        resume on to the next assigned waypoint. If this param is provided, group will not go to the next waypoint and will move to given position instead
        
    // Returns:
    //     NOTHING
    
    // NOTE:
    //     If a unit flees, all bets are off and the function will exit leaving units on their own
    //     To guarantee weapon disassembly, make sure the group has maximum courage (_group allowFleeing 0)
    
    // Example1:
    //     [leader1] call BIS_fnc_packStaticWeapon;
        
    // Example2:
    //     group1 allowFleeing 0;
    //     [group1, nil, "leaderpos_marker"] call BIS_fnc_packStaticWeapon;


pl_reworked_bis_pack = {
    params [
        ["_group", grpNull, [grpNull, objNull]], 
        ["_weapon", objNull, [objNull]],
        ["_leaderPos", [0,0,0], [[], "", objNull], 3]
    ];

    private _leader = leader _group;
    if (!local _leader) exitWith {_this remoteExecCall ["BIS_fnc_packStaticWeapon", _leader]};

    private _err_badGroup = 
    {
        ["Bad group! The group should exist and consist of minimum a Leader, Gunner and Asst. Gunner"] call BIS_fnc_error;
        nil
    };

    private _err_badPosition = 
    {
        ["Bad position! Position should exist and could be array, marker or object"] call BIS_fnc_error;
        nil
    };

    private _err_badWeapon = 
    {
        ["Bad static weapon! Static weapon should exist and not be packed or broken"] call BIS_fnc_error;
        nil
    };

    if (_group isEqualType objNull) then {_group = group _group};
    if (isNull _group) exitWith _err_badGroup;

    if (_leaderPos isEqualType "") then {_leaderPos = getMarkerPos _leaderPos};
    if (_leaderPos isEqualType objNull) then {_leaderPos = getPosATL _leaderPos};

    private _cfg = configFile >> "CfgVehicles";
    private _supportUnits = (units _group - [_leader]); // changed by Jellyfish from select {getText (_cfg >> typeOf _x >> "vehicleClass") == "MenSupport"};

    private _gunnerBackpackClass = "";
    private _gunner = gunner _weapon;

    if (isNull _gunner) exitWith {_err_badGroup};

    private _cfgBase = configFile >> "CfgVehicles" >> _gunnerBackpackClass >> "assembleInfo" >> "base";
    private _compatibleBases = if (isText _cfgBase) then {[getText _cfgBase]} else {getArray _cfgBase};
    private _assistant = 
    {   
        if (isNull (unitBackpack _x)) exitWith {_x};
        objNull;
    }
    forEach (_supportUnits - [_gunner, _leader]);

    if (isNull _assistant) exitWith {_err_badGroup};

    private _isWeaponGunner = false;

    if (isNull _weapon) then 
    {
        _weapon = assignedVehicle _gunner;
        _isWeaponGunner = objectParent _gunner isEqualTo _weapon;
    };

    if (!alive _weapon || !(_weapon isKindOf "StaticWeapon") || !isNull objectParent _weapon) exitWith _err_badWeapon;

    player hcRemoveGroup _group;

    _gunner addEventHandler ["WeaponDisassembled", format [
        '
            params ["_gunner", "_weaponBag", "_baseBag"];
            
            _gunner removeEventHandler ["WeaponDisassembled", _thisEventHandler];
            
            _leader = "%1" call BIS_fnc_objectFromNetId;
            _assistant = "%2" call BIS_fnc_objectFromNetId;
            
            _gunner action ["TakeBag", _weaponBag];
            _assistant action ["TakeBag", _baseBag];
                
            _gunner setUnitPos "AUTO";
            _gunner doWatch objNull;
            _gunner doFollow _leader;
            
            _assistant setUnitPos "AUTO";
            _assistant doWatch objNull;
            _assistant doFollow _leader;

            [] call pl_show_fire_support_menu;
            
            _group = group _gunner;
            [_group, "StaticWeaponPacked", [_group, _leader, _gunner, _assistant, _weaponBag, _baseBag]] call BIS_fnc_callScriptedEventHandler;
        ',
        _leader call BIS_fnc_netId,
        _assistant call BIS_fnc_netId
    ]];

    if (_isWeaponGunner) then {moveOut _gunner};
    _group leaveVehicle assignedVehicle _gunner;
    unassignVehicle _gunner;

    private _weaponPos = getPosATL _weapon;
    private _assistantPos = _weapon getRelPos [1, 135]; _assistantPos set [2, _weaponPos select 2]; // -- keep z
    private _gunnerPos = _weapon getRelPos [1, -135]; _gunnerPos set [2, _weaponPos select 2]; // -- keep z

    if (_gunner distance2D _gunnerPos > _gunner distance2D _assistantPos) then
    {
        // -- swap
        private _tmp = _gunnerPos; _gunnerPos = _assistantPos; _assistantPos = _tmp;
    }; 

    // -- leader logic
    [_leader, _leaderPos] spawn 
    {
        params ["_leader", "_leaderPos"];

        waitUntil {isNull (_leader getVariable ["BIS_staticWeaponLeaderScript", scriptNull])};
        _leader setVariable ["BIS_staticWeaponLeaderScript", _thisScript];
        
        _weapons = [primaryWeapon _leader, handgunWeapon _leader, secondaryWeapon _leader];

        if (!(currentWeapon _leader in _weapons) || currentWeapon _leader isEqualTo "") then
        {
            {
                if !(_x isEqualTo "") exitWith {_leader selectWeapon _x};
            }
            forEach _weapons;
        };
        
        _leader setUnitPos "AUTO";
        _leader doWatch objNull;
        
        if (_leaderPos isEqualTo [0,0,0]) exitWith {_leader doFollow _leader};
        
        _leader doMove _leaderPos;
            
        waitUntil {unitReady _leader};
            
        doStop _leader;
    };

    // -- assistant logic
    private _assistantReady = [_assistant, _assistantPos, _weapon, _isWeaponGunner] spawn
    {
        params ["_assistant", "_assistantPos", "_weapon", "_isWeaponGunner"];
        
        if (!_isWeaponGunner) then
        {
            _assistant setUnitPos "AUTO";
            _assistant doWatch _weapon;
            _assistant doMove _assistantPos;
            
            waitUntil {unitReady _assistant};
        };
        
        doStop _assistant;
        _assistant doWatch _weapon;
        
        if (fleeing _assistant) exitWith {};
    };

    // -- gunner logic
    [_gunner, _gunnerPos, _weapon, _assistant, _assistantReady, _isWeaponGunner, _group] spawn
    {
        params ["_gunner", "_gunnerPos", "_weapon", "_assistant", "_assistantReady", "_isWeaponGunner", "_group"];
            
        if (!_isWeaponGunner) then
        {
            _gunner setUnitPos "AUTO";
            _gunner doWatch _weapon;
            _gunner doMove _gunnerPos;
            
            waitUntil {unitReady _gunner};
        };
        
        if (!alive _gunner || fleeing _gunner) exitWith {_gunner removeAllEventHandlers "WeaponDisassembled"; player hcSetGroup [_group]};
        
        doStop _gunner;
        _gunner doWatch _weapon;
        
        waitUntil {scriptDone _assistantReady};


        if (!alive _assistant || fleeing _assistant) exitWith {_gunner removeAllEventHandlers "WeaponDisassembled"; player hcSetGroup [_group]};
        
        // -- pack weapon
        _gunner action ["Disassemble", _weapon];

        sleep 2;

        player hcSetGroup [_group];
    };
};