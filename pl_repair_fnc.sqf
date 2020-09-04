sleep 1;
if !(pl_enable_vehicle_recovery) exitWith {};

pl_show_dead_vehicles = false;
pl_additional_engVic = parseSimpleArray pl_additional_engVic;
pl_eng_vic_cls_names = ["B_APC_Tracked_01_CRV_F", "B_Truck_01_Repair_F", "O_Truck_01_Repair_F", "I_Truck_01_Repair_F"];
pl_eng_vic_cls_names = pl_eng_vic_cls_names + pl_additional_engVic;

pl_destroyed_vics_data = [];



addMissionEventHandler ["EntityKilled",{
    params ["_killed", "_killer", "_instigator", "_useEffects"];
    if (_killed isKindOf "Man" or _killed isKindOf "Air") exitWith {};
    if ((side (group (driver _killed))) isEqualTo playerSide) then {
        if (_killed getVariable ["pl_repair_lifes", 0] > 0) then {

            _groupId = groupId group driver _killed;
            playSound "beep";
            driver _killed sideChat format ["%1 has been disabled!", _groupId];

            _crew = crew _killed;

            _crewClassName = getText (configFile >> "CfgVehicles" >> typeOf _killed >> "crew");
            {
                if (typeOf _x isEqualTo _crewClassName and !(((_killed call BIS_fnc_objectType) select 1) isEqualTo "Car")) then {
                    deleteVehicle _x;
                }
                else
                {
                    [_x, _killed] call pl_crew_eject;
                };
            } forEach _crew;

            _pos = getPosATLVisual _killed;
            _dir = getDir _killed;
            _type = typeOf _killed;
            _appereance = _killed getVariable "pl_appereance";
            _loadout = _killed getVariable "pl_vic_inv";
            _lives = _killed getVariable "pl_repair_lifes";

            deleteVehicle _killed;

            [_type, _pos, _dir, _appereance, _loadout, _groupId, _lives] spawn pl_create_new_vic;
            
        }
        else
        {
            _groupId = groupId group driver _killed;
            playSound "beep";
            player sideChat format ["%1 has been destroyed", _groupId];
        };
    };
}];

pl_create_new_vic = {
    params ["_type", "_pos", "_dir", "_appereance", "_loadout", "_groupId", "_lives"];
    private ["_newVic"];

    sleep 0.3;

    _newVic = _type createVehicle _pos;
    _newVic setPos _pos;
    _newVic setDir _dir;

    _newVic setCaptive true;
    _newVic setDamage 0.9;
    _newVic allowDamage false;
    _newVic setVehicleLock "LOCKED";

    {
        _newVic animateSource [_x#0, _x#1];
    } forEach _appereance;

    [_loadout, _newVic] call pl_set_vic_laodout;

    _smokeGroup = createGroup east;
    _smoke = _smokeGroup createUnit ["ModuleEffectsSmoke_F", _pos, [],0 , ""];
    // _smoke setVariable ["timeout", 80];
    _fire = _smokeGroup createUnit ["ModuleEffectsFire_F", _pos, [],0 , ""];
    // _fire setVariable ["timeout", 80];
    _fire setPos _pos;
    _smoke setPos _pos;

    _markerName = format ["disabled%1", _newVic];
    createMarker [_markerName, _pos];
    _markerName setMarkerType "mil_destroy";
    _vicName = getText (configFile >> "CfgVehicles" >> _type >> "displayName");
    _markerName setMarkerText format ["Disabled %1", _vicName];

    _lives = _lives - 1;
    _newVic setVariable ["pl_repair_lifes", _lives];
    [_newVic] call pl_vehicle_setup;

    pl_destroyed_vics_data pushBack [_pos, _newVic, _markerName, _groupId, _smokeGroup];
};

pl_crew_eject = {
    params ["_unit", "_vic"];
    _pos = [[[getPos _vic, 8]],[]] call BIS_fnc_randomPos;
    _unit setPos _pos;
    _dir = [1, 359] call BIS_fnc_randomInt;
    _unit setDir _dir;
    unassignVehicle (_unit);
    doGetOut (_unit);
    group _unit setVariable ["pl_show_info", true];
    group _unit setVariable ["onTask", false];
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

pl_repair = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_group", "_engVic", "_vicPos", "_validEng", "_cords", "_repairTarget", "_toRepairVic", "_markerName", "_vicGroup", "_smokeGroup", "_icon"];

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

        if !(_validEng) exitWith {hint "Invalid Repair Vehicle!"};

        _engVic setUnloadInCombat [false, false];
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
            while {!pl_mapClicked} do {sleep 0.2;};
            pl_mapClicked = false;
            _cords = pl_repair_cords;
            private _distance = 100;
            {
                if ((_cords distance2D (_x #0)) < _distance) then {
                    _repairTarget = _x,
                    _distance = (_cords distance2D (_x #0));
                };
            } forEach pl_destroyed_vics_data;
            if (isNil "_repairTarget") exitWith {leader _group sideChat "No damaged Vehicles found, over"; playSound "beep";};

            _toRepairVic = _repairTarget #1;
            _markerName = _repairTarget #2;
            _vicGroupId = _repairTarget #3;
            _smokeGroup = _repairTarget #4;

            _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\repair_ca.paa";

            if (count _taskPlanWp != 0) then {

                // add Arrow indicator
                pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

                waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11) or !(_group getVariable ["pl_task_planed", false])};

                // remove Arrow indicator
                pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

                if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
                _group setVariable ["pl_task_planed", false];
            };

            if (pl_cancel_strike) exitWith {pl_cancel_strike = false;};

            [_group] call pl_reset;
            sleep 0.2;

            _group setVariable ["onTask", true];
            _group setVariable ["setSpecial", true];
            _group setVariable ["specialIcon", _icon];

            for "_i" from count waypoints _group - 1 to 0 step -1 do{
                deleteWaypoint [_group, _i];
            };
            _wp = _group addWaypoint [_repairTarget #0, 0];
            _group setVariable ["MARTA_customIcon", ["b_maint"]];
            // add Task Icon to wp
            pl_draw_planed_task_array pushBack [_wp, _icon];
            playSound "beep";
            // leader _group sideChat format ["%1 is moving to damaged vehicle, over", (groupId _group)];
            sleep 4;
            waitUntil {sleep 0.1; !alive _engVic or (unitReady _engVic) or !(_group getVariable ["onTask", true])};
            sleep 2;

            // remove Task Icon from wp and delete wp
            pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];

            _repairTime = time + 90;
            {
                _x disableAI "PATH";
            } forEach crew _engVic;
            waitUntil {sleep 1; time >= _repairTime or !(_group getVariable ["onTask", true])};
            {
                _x enableAI "PATH";
            } forEach crew _engVic;
            sleep 1;
            if ((alive _engVic) and (_group getVariable "onTask") and ({ alive _x } count units _group > 0) and (time >= _repairTime)) then {
                _idx = pl_destroyed_vics_data find _repairTarget;
                0 = pl_destroyed_vics_data deleteAt _idx;
                deleteMarker _markerName;
                _toRepairVic setDamage 0;
                _toRepairVic setFuel 1;
                _toRepairVic setVehicleAmmo 1;
                _toRepairVic setCaptive false;
                _toRepairVic allowDamage true;
                _toRepairVic setVehicleLock "DEFAULT";
                {
                    deleteVehicle ((_x getVariable "effectEmitter") select 0);  
                    // deleteVehicle ((_x getVariable "effectLight") select 0);
                } forEach (units _smokeGroup);
                sleep 0.1;
                if !(((_toRepairVic call BIS_fnc_objectType) select 1) isEqualTo "Car") then {
                    _vicGroup = createVehicleCrew _toRepairVic;
                };
                sleep 0.1;
                _vicGroup setGroupId [_vicGroupId];
                sleep  0.1;
                [_vicGroup] spawn pl_set_up_ai;
                sleep 4;
                player hcSetGroup [_vicGroup];
                [_vicGroup] spawn pl_reset;
                sleep 1;
                playsound "beep";
                (leader _vicGroup) sideChat format ["%1 is back up and fully operational, over", (groupId _vicGroup)];

                _group setVariable ["onTask", false];
                _group setVariable ["setSpecial", false];
                _group setVariable ["MARTA_customIcon", nil];
            };
        };
    }; 
};

pl_maintenance_area = 45;

pl_maintenance_point = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_group", "_markerName", "_areaMarkerName", "_cords", "_engineer", "_vics", "_groupId", "_icon"];

    // _group = hcSelected player select 0;
    _cords = getPos (leader _group);
    _engineer = {
        if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "engineer" ) isEqualTo 1) exitWith {_x};
        objNull
    } forEach (units _group);

    if (isNull _engineer) exitWith {hint format ["%1 has no Engineer!", groupId _group]};

    // _markerName = createMarker ["maintenance_point_center", (getPos (leader _group))];
    // _markerName setMarkerType "b_maint";
    // _markerName setMarkerText "Maintenance Point";

    // _group addGroupIcon ["b_maint"];
    // _group removeGroupIcon 1;

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\repair_ca.paa";

    if (count _taskPlanWp != 0) then {

        waitUntil {(((leader _group) distance2D (waypointPosition _taskPlanWp)) < 11) or !(_group getVariable ["pl_task_planed", false])};

        if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
        _group setVariable ["pl_task_planed", false];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

    if (vehicle (leader _group) != leader _group) then {
        _vic = vehicle (leader _group);
        [_group] call pl_leave_vehicle;
        waitUntil {(count (crew _vic) == 0)};
    };
    
    [_group] call pl_reset;
    
    sleep 0.2;

    _groupId = groupId _group;
    _group setGroupId [format ["%1 (Maintenance Point)", _groupId]];
    _group setVariable ["MARTA_customIcon", ["b_maint"]];
    _areaMarkerName = createMarker ["maintenance_point_area", getPos (leader _group)];
    _areaMarkerName setMarkerShape "ELLIPSE";
    _areaMarkerName setMarkerBrush "DiagGrid";
    _areaMarkerName setMarkerColor "colorBLUFOR";
    _areaMarkerName setMarkerAlpha 0.4;
    _areaMarkerName setMarkerSize [pl_maintenance_area, pl_maintenance_area];
    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];
    _engineer setVariable ["pl_is_ccp_medic", true];

    private _fn_repair_action = {
        params ["_vic", "_engineer", "_group"];
        private ["_pos", "_offsetX", "_offsetZ"];
        (driver _vic) disableAI "PATH";

        (group (driver _vic)) setVariable ["setSpecial", true];
        (group (driver _vic)) setVariable ["specialIcon", _icon];

        _offsetZ = ((getPosASL _vic)#2) - ((getPosWorldVisual _vic)#2);
        _offsetX = (((boundingBoxReal _vic) select 0) select 0) / 2 - 1;
        _pos = getPosASL _vic;
        _pos = [(_pos#0) + _offsetX, _pos#1, (_pos#2) + _offsetZ];

        _engineer doMove _pos;
        _engineer moveTo _pos;
        private _eLoadout = getUnitLoadout _engineer ;

        waitUntil {unitReady _engineer or !(_group getVariable ["onTask", true]) or (!alive _engineer)};
        if ((_group getVariable ["onTask", true]) and (alive _engineer)) then {
            doStop _engineer;
            _engineer disableAI "PATH";
            _engineer attachTo [_vic, [_offsetX ,0, _offsetZ]];
            [_engineer, "REPAIR_VEH_STAND", "ASIS", objNull, true, true] call BIS_fnc_ambientAnim;
            _engineer setDir 90;

            _time = time + 30;
            waitUntil {!(_group getVariable ["onTask", true]) or (!alive _engineer) or time > _time};
            _engineer call BIS_fnc_ambientAnim__terminate;
            _engineer enableAI "PATH";
            _engineer setUnitLoadout _eLoadout ;
            if ((_group getVariable ["onTask", true]) and (alive _engineer)) then {
                (group (driver _vic)) setVariable ["setSpecial", false];
                _vic setDamage 0;
                private _vicGroup = group (driver _vic);
                {
                    _vicGroup = group _x;
                    _x setDamage 0;
                } forEach (crew _vic);
                _g = createVehicleCrew _vic;
                [units _g] joinSilent _vicGroup; 
                sleep 5;
                // (driver _vic) enableAI "PATH";
                _engineer doMove (getPos (leader _group));
                _engineer moveTo (getPos (leader _group));
            };
        };
        (driver _vic) enableAI "PATH";
    };

    sleep 1;

    _engineer disableAI "AUTOCOMBAT";
    {
        _x disableAI "AUTOCOMBAT";
        [_x, (getPos _engineer), 0, 10, false] spawn pl_find_cover;
    } forEach (units _group) - [_engineer];

    while {(_group getVariable ["onTask", true] and (alive _engineer))} do {
        _vics = nearestObjects [_cords, ["Car", "Tank", "Truck"], pl_maintenance_area];
        {
            if ((getDammage _x) > 0) then {
                _s1 = [_x, _engineer, _group] spawn _fn_repair_action;
                waitUntil {scriptDone _s1};
            };
        } forEach (_vics select {side _x isEqualTo playerSide});
        sleep 2;
    };

    _engineer setVariable ["pl_is_ccp_medic", false];
    deleteMarker _areaMarkerName;
    _group setVariable ["MARTA_customIcon", nil];
    _group setGroupId [_groupId];
    // deleteMarker _markerName;
};
