pl_destroyed_vics_data = [];
pl_show_dead_vehicles = false;
sleep 1;
if !(pl_enable_vehicle_recovery) exitWith {};

pl_additional_engVic = parseSimpleArray pl_additional_engVic;
pl_eng_vic_cls_names = ["B_APC_Tracked_01_CRV_F", "B_Truck_01_Repair_F", "O_Truck_01_Repair_F", "I_Truck_01_Repair_F"];
pl_eng_vic_cls_names = pl_eng_vic_cls_names + pl_additional_engVic;
pl_show_dead_vehicles_pos = getPos player;

pl_mapClicked = false;
addMissionEventHandler ["EntityKilled",{
    params ["_killed", "_killer", "_instigator", "_useEffects"];
    private ["_group"];
    if (_killed isKindOf "Man" or _killed isKindOf "Air") exitWith {};
    if ((side (group (driver _killed))) isEqualTo playerSide) then {
        _crew = crew _killed;
        {
            _x setDamage 1;
            _group = group _x;
            [_x, _killed, _group] spawn pl_eject_crew;
        } forEach _crew;
        // Save Vehicle Data
        _vicData = [];
        // Position 0
        _pos = getPos _killed;
        _vicData pushBack _pos;
        // Object 1
        _vicData pushBack _killed;
        // Type 2
        _type = typeOf _killed;
        _vicData pushBack _type;
        // marker 3
        _markerName = format ["destroyed%1", _killed];
        createMarker [_markerName, _pos];
        _markerName setMarkerType "mil_destroy";
        _markerName setMarkerText "Damaged Vehicle";
        _vicData pushBack _markerName;
        // Callsign 4
        _vicData pushBack (groupId _group);
        // Appearance 5
        _animations = "true" configClasses (configFile >> "CfgVehicles" >> typeOf vic1 >> "AnimationSources");
        _animationPhases = [];
        {
            _s = (str _x) splitString "/";
            _a =  _s select ((count _s) - 1);
            _animationPhases pushBack [_a, (vic1 animationSourcePhase _a)];
        } forEach _animations;
        _vicData pushBack _animationPhases;
        // Loadout 6
        // _w = getWeaponCargo _killed;
        // _t = getItemCargo _killed;
        // _m = getMagazineCargo _killed;
        // _b = getBackpackCargo _killed;
        // _vicInv = [_w, _t, _m ,_b];
        // _vicData pushBack _vicInv;

        pl_destroyed_vics_data pushBack _vicData;
    };
}];

pl_eject_crew = {
    params ["_unit", "_vic", "_group"];
    sleep 1;
    _name = typeOf _unit;
    deleteVehicle _unit;
    _pos = [[[getPos _vic, 10]],[]] call BIS_fnc_randomPos;
    _newUnit = _group createUnit [_name, _pos, [],0 , ""];
    _newUnit setDir ([0, 360] call BIS_fnc_randomInt);
    [_group] spawn pl_set_up_ai;
    _newUnit setVariable ["pl_bleedout_time", 600];
    _newUnit setUnconscious true;
    [_newUnit] spawn pl_wia_callout;
    [_newUnit] spawn pl_bleedout;
    _newUnit setVariable ["pl_damage_reduction", true];
    sleep 0.1;
    player hcSetGroup [_group];
};

pl_repair = {
    private ["_engVic", "_vicPos", "_validEng", "_toDeleteVic", "_toCreateVic", "_medic", "_vicGroup", "_cords", "_marker", "_callsign", "_repairTarget", "_appearance", "_loadout"];
    _group = hcSelected player select 0;
    if (vehicle (leader _group) != leader _group) then {
        _engVic = vehicle (leader _group);
        _validEng = false;
        if !((typeOf _engVic) in pl_eng_vic_cls_names) then {
            {
                if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "engineer" ) isEqualTo 1) then {
                    _validEng = true;
                };
            } forEach (crew _engVic);
        }
        else {_validEng = true;};

        if !(_validEng) exitWith {leader _group sideChat "Negativ, We don't have the required Equipment for this Task, over"};

        _engVic setUnloadInCombat [false, false];
        {
            if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {
                _medic = _x;
            };
            _x disableAI "AUTOCOMBAT";
        } forEach crew _engVic;
        if (visibleMap) then {
            pl_show_dead_vehicles = true;
            pl_show_dead_vehicles_pos = getPos _engVic;
            hint "Select on MAP";
            onMapSingleClick {
                pl_repair_cords = _pos;
                pl_mapClicked = true;
                pl_show_dead_vehicles = false;
                hint "";
                onMapSingleClick "";
            };
            while {!pl_mapClicked} do {sleep 0.5;};
            pl_mapClicked = false;
            _cords = pl_repair_cords;
            private _distance = 100;
            {
                if ((_cords distance2D (_x select 0)) < _distance) then {
                    _repairTarget = _x,
                    _distance = (_cords distance2D (_x select 0));
                };
            } forEach pl_destroyed_vics_data;
            if (isNil "_repairTarget") exitWith {leader _group sideChat "No demaged Vehicles found, over"; playSound "beep";};
            _vicPos = _repairTarget select 0;
            _toDeleteVic = _repairTarget select 1;
            _toCreateVic = _repairTarget select 2;
            _marker = _repairTarget select 3;
            _callsign = _repairTarget select 4;
            _appearance = _repairTarget select 5;
            _loadout = _repairTarget select 6;

            _group setVariable ["onTask", false];
            sleep 0.25;

            _group setVariable ["onTask", true];
            _group setVariable ["setSpecial", true];
            _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\repair_ca.paa"];

            for "_i" from count waypoints _group - 1 to 0 step -1 do{
                deleteWaypoint [_group, _i];
            };
            _pos = getPos _toDeleteVic;
            _group addWaypoint [_vicPos, 0];
            leader _group sideChat format ["%1 is moving to damaged vehicle, over", (groupId _group)];
            playSound "beep";
            sleep 7;
            waitUntil {sleep 0.1; !alive _engVic or (unitReady _engVic)};
            _group leaveVehicle _engVic;
            // Revive Crew
            sleep 7;
            [(leader _group), _toDeleteVic] spawn pl_repair_anim;
            if !(isNil "_medic") then {
                doStop _medic;
                _reviveTargets = (getPos _toDeleteVic) nearObjects ["Man", 25];
                {
                    if (lifeState _x isEqualTo "INCAPACITATED" and !(_x getVariable "pl_beeing_treatet")) then {
                        _h1 = [_group, _medic, nil, _x, _cords, 20] spawn pl_ccp_revive_action;
                        waitUntil {sleep 0.1; scriptDone _h1 or !(_group getVariable ["onTask", true])};
                        _vicGroup = (group _x);
                    };
                } forEach _reviveTargets;
            };
            _repairTime = time + 90;
            waitUntil {sleep 1; time >= _repairTime or !(_group getVariable ["onTask", true])};
            deleteMarker _marker;
            if ((alive _engVic) and (_group getVariable "onTask") and ({ alive _x } count units _group > 0)) then {
                deleteVehicle _toDeleteVic;
                sleep 0.1;
                // spawn new Vic
                _newVic = _toCreateVic createVehicle _vicPos;
                // set apperance
                {
                    _newVic animateSource [_x#0, _x#1];
                } forEach _appearance;
                // set loadout
                // [_loadout, _newVic] call pl_set_vic_laodout;
                sleep 2;
                _group addVehicle _engVic;
                {
                    _x call BIS_fnc_ambientAnim__terminate;
                    [_x] allowGetIn true;
                    [_x] orderGetIn true;
                    _x enableAI "AUTOCOMBAT";
                } forEach (units _group);
                if !(isNil "_vicGroup") then {
                    _vicGroup addVehicle _newVic;
                    {
                        [_x] allowGetIn true;
                        [_x] orderGetIn true;
                        _x setVariable ["pl_damage_reduction", false];
                    } forEach (units _vicGroup);
                };
                leader _group sideChat format ["%1 finished Repair, over", (groupId _group)];
                playSound "beep";
                _group setVariable ["onTask", false];
                _group setVariable ["setSpecial", false];
                sleep 5;
                if !(isNil "_vicGroup") then {
                    waitUntil {sleep 0.1; ({vehicle _x == _x} count units _vicGroup == 0)};
                    _newGroup = createVehicleCrew _newVic;
                    (units _newGroup) joinSilent _vicGroup;
                    playsound "beep";
                    (leader _vicGroup) sideChat format ["%1 is back up and fully operational, over", (groupId _vicGroup)];
                }
                else
                {
                    _newGroup = createVehicleCrew _newVic;
                    sleep 0.1;
                    player hcSetGroup [_newGroup];
                    _newGroup setGroupId [_callsign];
                    playsound "beep";
                    (leader _newGroup) sideChat format ["%1 is back up and fully operational, over", (groupId _newGroup)];
                };
            };
        };
    };
};

pl_repair_anim = {
    params ["_unit", "_vic"];
    _pos = getPos _vic;
    _unit doMove _pos;
    sleep 1;
    waitUntil {sleep 0.1; !alive _unit or (unitReady _unit)};
    [_unit, "REPAIR_VEH_KNEEL", "ASIS", objNull, true, true] call BIS_fnc_ambientAnim;
};

pl_set_vic_laodout = {
    params ["_loadout", "_vic"];
    clearWeaponcargo _vic;
    clearItemCargo _vic;
    clearMagazineCargo _vic;
    clearBackpackCargo _vic;
    _w = _loadout select 0;
    _t = _loadout select 1;
    _m = _loadout select 2;
    _b = _loadout select 3;

    for "_i" from 0 to ((count (_w#0)) -1) do {
        _vic addWeaponCargo [(_w#0#_i), _w#1#_i];
    };

    for "_i" from 0 to ((count (_t#0)) -1) do {
        _vic addItemCargo [(_t#0#_i), _t#1#_i];
    };

    for "_i" from 0 to ((count (_m#0)) -1) do {
        _vic addMagazineCargo [(_m#0#_i), _m#1#_i];
    };

    for "_i" from 0 to ((count (_b#0)) -1) do {
        _vic addBackpackCargo [(_b#0#_i), _b#1#_i];
    };
};

