sleep 1;
if !(pl_enable_vehicle_recovery) exitWith {};

pl_show_dead_vehicles = false;
pl_destroyed_vics_data = [];



addMissionEventHandler ["EntityKilled",{
    params ["_killed", "_killer", "_instigator", "_useEffects"];
    if (_killed isKindOf "Man" or _killed isKindOf "Air") exitWith {};
    _abandonedVics = [];
    {
        _abandonedVics pushBack (_x#0);
    } forEach pl_abandoned_markers;

    if ((side (group (driver _killed))) isEqualTo playerSide or _killed in _abandonedVics) then {
        if (_killed getVariable ["pl_repair_lifes", 0] > 0) then {

            _groupId = groupId group driver _killed;
            if (pl_enable_beep_sound) then {playSound "beep"};
            if (pl_enable_chat_radio) then {driver _killed sideChat format ["%1 has been disabled!", _groupId]};
            if (pl_enable_map_radio) then {[group (driver _killed), "...We are hit!", 15] call pl_map_radio_callout};
            [group driver _killed, "damaged", 1] call pl_voice_radio_answer;

            _crew = crew _killed;
            _vicGroup = group (driver _killed);

            _crewClassName = getText (configFile >> "CfgVehicles" >> typeOf _killed >> "crew");
            _unitText = getText (configFile >> "CfgVehicles" >> typeOf _killed >> "textSingular");
            private _cargoGroups = [];
            {
                // if (typeOf _x isEqualTo _crewClassName and !(((_killed call BIS_fnc_objectType) select 1) isEqualTo "Car")) then {
                if ((_killed isKindOf "Tank" or _unitText isEqualTo "APC") and (group _x) == _vicGroup ) then {
                    deleteVehicle _x;
                }
                else
                {
                    [_x, _killed] call pl_crew_eject;
                };
                _cargoGroups pushBackUnique (group _x);
            } forEach _crew;

            {
                [_x] call pl_show_group_icon;
                [_x] spawn pl_reset;
            } forEach _cargoGroups;

            _pos = getPosATLVisual _killed;
            _dir = getDir _killed;
            _type = typeOf _killed;
            _appereance = _killed getVariable "pl_appereance";
            _loadout = _killed getVariable "pl_vic_inv";
            _lives = _killed getVariable "pl_repair_lifes";

            {
                if (_killed == (_x#0)) exitWith {
                    deleteMarker (_x#1);
                    pl_abandoned_markers = pl_abandoned_markers - [[_x#0, _x#1]];
                };
            } forEach pl_abandoned_markers;

            deleteVehicle _killed;

            [_type, _pos, _dir, _appereance, _loadout, _groupId, _lives] spawn pl_create_new_vic;
            
        }
        else
        {
            _groupId = groupId group driver _killed;
            if (pl_enable_beep_sound) then {playSound "beep"};
            if (pl_enable_chat_radio) then {player sideChat format ["%1 has been destroyed", _groupId]};
            if (pl_enable_map_radio) then {[group (driver _killed), "...Ahhh", 10] call pl_map_radio_callout};
            [group driver _killed, "damaged", 1] call pl_voice_radio_answer;
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
        _newVic animateSource [_x#0, _x#1, true];
    } forEach _appereance;

    [_loadout, _newVic] call pl_set_vic_laodout;

    _smokeGroup = createGroup civilian;
    _smoke = _smokeGroup createUnit ["ModuleEffectsSmoke_F", _pos, [],0 , ""];
    // _smoke setVariable ["timeout", 80];
    _fire = _smokeGroup createUnit ["ModuleEffectsFire_F", _pos, [],0 , ""];
    // _fire setVariable ["timeout", 80];
    _fire setPos _pos;
    _smoke setPos _pos;

    _markerName = format ["disabled%1", _newVic];
    createMarker [_markerName, _pos];
    _markerName setMarkerType "mil_destroy";
    _markerName setMarkerColor pl_side_color;
    _markerName setMarkerShadow false;
    _markerName setMarkerDir 45;
    _markerName setMarkerSize [0.8, 0.8];

    _vicName = getText (configFile >> "CfgVehicles" >> _type >> "displayName");
    _markerName setMarkerText format ["%1", _vicName];

    [_newVic] call pl_vehicle_setup;
    _lives = _lives - 1;
    _newVic setVariable ["pl_repair_lifes", _lives];

    pl_destroyed_vics_data pushBack [_pos, _newVic, _markerName, _groupId, _smokeGroup];
};

pl_crew_eject = {
    params ["_unit", "_vic"];
    _pos = [[[getPos _vic, 8]],[]] call BIS_fnc_randomPos;
    _unit setPos _pos;
    _dir = [1, 359] call BIS_fnc_randomInt;
    _unit setDir _dir;
    unassignVehicle _unit;
    doGetOut _unit;
    // group _unit setVariable ["pl_show_info", true];
    // if !(_group getVariable ["pl_show_info", false]) then {[group _unit] call pl_show_group_icon};
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
    private ["_group", "_engVic", "_vicPos", "_validEng", "_cords", "_repairTarget", "_toRepairVic", "_markerName", "_vicGroup", "_smokeGroup", "_vicGroupId", "_icon", "_wp", "_repairTime"];

    if (vehicle (leader _group) != leader _group) then {
        _engVic = vehicle (leader _group);
        _vicType = typeOf _engVic;

        if !(_engVic getVariable ["pl_is_repair_vehicle", false]) exitWith {hint "Requires Repair Vehicle!"};

        _repairCargo = _engVic getVariable ["pl_repair_supplies", 0];

        if (_repairCargo <= 0) exitWith {hint "No more Supplies left!"};

        if (visibleMap) then {
            pl_show_dead_vehicles = true;
            pl_show_dead_vehicles_pos = getPos _engVic;
            pl_show_damaged_vehicles = true;
            pl_show_vehicles_pos = getPos _engVic;
            hint "Select on MAP";
            onMapSingleClick {
                pl_repair_cords = _pos;
                pl_mapClicked = true;
                pl_show_dead_vehicles = false;
                pl_show_damaged_vehicles = false;
                hint "";
                onMapSingleClick "";
            };
            while {!pl_mapClicked} do {sleep 0.1;};

            pl_mapClicked = false;
            _cords = pl_repair_cords;
            private _distance = 30;
            {
                if ((_cords distance2D (_x #0)) < _distance) then {
                    _repairTarget = _x,
                    _distance = (_cords distance2D (_x #0));
                };
            } forEach pl_destroyed_vics_data;

            if !(isNil "_repairTarget") then {

                _toRepairVic = _repairTarget #1;
                _markerName = _repairTarget #2;
                _vicGroupId = _repairTarget #3;
                _smokeGroup = _repairTarget #4;
            }
            else
            {
                _vics = nearestObjects [_cords, ["Car", "Tank", "Truck"], 30];
                _distance = 30;
                {
                    if ((((_cords distance2D _x) < _distance) and ((getDammage _x) > 0 or !(canMove _x)) and alive _x and (side _x) == playerSide) or ((count (crew _x)) <= 0 and ((getDammage _x) > 0 or !(canMove _x)) and alive _x)) then {
                        _repairTarget = _x,
                        _distance = (_cords distance2D _x);
                    };
                } forEach _vics;
            };

            if (isNil "_repairTarget") exitWith {
                if (pl_enable_chat_radio) then {leader _group sideChat "No damaged Vehicles found"};
                if (pl_enable_map_radio) then {[_group, "...No damaged Vehicles found", 20] call pl_map_radio_callout};
                if (pl_enable_beep_sound) then {playSound "beep"};
            };

            _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\repair_ca.paa";

            if (count _taskPlanWp != 0) then {

                // add Arrow indicator
                pl_draw_planed_task_array_wp pushBack [_cords, _taskPlanWp, _icon];

                waitUntil {sleep 0.5; (((leader _group) distance2D (waypointPosition _taskPlanWp)) < 30) or !(_group getVariable ["pl_task_planed", false])};

                // remove Arrow indicator
                pl_draw_planed_task_array_wp = pl_draw_planed_task_array_wp - [[_cords, _taskPlanWp, _icon]];

                if !(_group getVariable ["pl_task_planed", false]) then {pl_cancel_strike = true}; // deleteMarker
                _group setVariable ["pl_task_planed", false];
            };

            if (pl_cancel_strike) exitWith {pl_cancel_strike = false;};


            // if (pl_enable_beep_sound) then {playSound "beep"};
            [_group, "confirm", 1] call pl_voice_radio_answer;
            [_group] call pl_reset;

            sleep 0.5;

            [_group] call pl_reset;

            sleep 0.5;

            _group setVariable ["onTask", true];
            _group setVariable ["setSpecial", true];
            _group setVariable ["specialIcon", _icon];
            _group setVariable ["pl_is_support", true];

            for "_i" from count waypoints _group - 1 to 0 step -1 do{
                deleteWaypoint [_group, _i];
            };
            if ((typeName _repairTarget) isEqualTo "ARRAY") then {
                _wp = _group addWaypoint [_repairTarget #0, 0];
                _repairTime = time + 90;
            }
            else
            {
                _wp = _group addWaypoint [getPos _repairTarget, 0];
                _repairTime = time + 45;
            };
            [_group, "maint"] call pl_change_group_icon;
            // add Task Icon to wp
            pl_draw_planed_task_array pushBack [_wp, _icon];
            if (pl_enable_beep_sound) then {playSound "beep"};
            // leader _group sideChat format ["%1 is moving to damaged vehicle, over", (groupId _group)];
            sleep 4;
            waitUntil {sleep 0.5; !alive _engVic or (unitReady _engVic) or !(_group getVariable ["onTask", true])};
            sleep 2;

            // remove Task Icon from wp and delete wp
            pl_draw_planed_task_array = pl_draw_planed_task_array - [[_wp,  _icon]];

            // _repairTime = time + 90;
            {
                _x disableAI "PATH";
            } forEach crew _engVic;
            waitUntil {sleep 0.5; time >= _repairTime or !(_group getVariable ["onTask", true])};
            {
                _x enableAI "PATH";
            } forEach crew _engVic;
            sleep 1;
            if ((alive _engVic) and (_group getVariable "onTask") and ({ alive _x } count units _group > 0) and (time >= _repairTime)) then {
                if ((typeName _repairTarget) isEqualTo "ARRAY") then {
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
                    _unitText = getText (configFile >> "CfgVehicles" >> typeOf _toRepairVic>> "textSingular");
                    if (_toRepairVic isKindOf "Tank" or _unitText isEqualTo "APC") then {
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
                    if (pl_enable_beep_sound) then {playSound "beep"};
                    if (pl_enable_chat_radio) then {(leader _vicGroup) sideChat format ["%1 is back up and fully operational", (groupId _vicGroup)]};
                    if (pl_enable_map_radio) then {[_vicGroup, "...We are back up!", 20] call pl_map_radio_callout};

                    _group setVariable ["onTask", false];
                    _group setVariable ["setSpecial", false];
                    // _group setVariable ["MARTA_customIcon", nil];
                    _repairCargo = _repairCargo - 2;
                }
                else
                {
                    _repairTarget setDamage 0;
                    _repairTarget setFuel 1;
                    _group setVariable ["onTask", false];
                    _group setVariable ["setSpecial", false];
                    // _group setVariable ["MARTA_customIcon", nil];
                    if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: Repairs Completeted", (groupId _group)]};
                    if (pl_enable_map_radio) then {[_group, "...Repairs Completeted", 20] call pl_map_radio_callout};
                    _repairCargo = _repairCargo - 1;
                };
                
                _engVic setVariable ["pl_repair_supplies", _repairCargo];
                _group setVariable ["pl_is_support", false];
            };
        };
    }; 
};

pl_repair_bridge = {
    params [["_group", (hcSelected player) select 0], ["_taskPlanWp", []]];
    private ["_cords", "_engineer", "_bridges", "_bridgeMarkers"];

    _engineer = {
    if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "engineer" ) isEqualTo 1) exitWith {_x};
        objNull
    } forEach (units _group);

    if (isNull _engineer) exitWith {hint format ["%1 has no Engineer!", groupId _group]};

    if (visibleMap) then {

        _markerName = createMarker ["pl_charge_range_marker2", [0,0,0]];
        _markerName setMarkerColor "colorOrange";
        _markerName setMarkerShape "ELLIPSE";
        _markerName setMarkerBrush "Border";
        _markerName setMarkerSize [30, 30];

        private _rangelimiter = 60;

        private _markerBorderName = str (random 2);
        private _borderMarkerPos = getPos (leader _group);
        if !(_taskPlanWp isEqualTo []) then {_borderMarkerPos = waypointPosition _taskPlanWp};
        createMarker [_markerBorderName, _borderMarkerPos];
        _markerBorderName setMarkerShape "ELLIPSE";
        _markerBorderName setMarkerBrush "Border";
        _markerBorderName setMarkerColor "colorOrange";
        _markerBorderName setMarkerAlpha 0.8;
        _markerBorderName setMarkerSize [_rangelimiter, _rangelimiter];

        hint "Select on MAP";
        onMapSingleClick {
            pl_repair_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hint "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            if ((_mPos distance2D _borderMarkerPos) <= _rangelimiter) then {
                _markerName setMarkerPos _mPos;
            };
        };

        pl_mapClicked = false;
        _cords = getMarkerPos _markerName;
        deleteMarker _markerName;
        deleteMarker _markerBorderName;
    }
    else
    {
        _cords = screenToWorld [0.5, 0.5];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false};

    _roads = _cords nearRoads 30;
    _bridges = [];
    _bridgeMarkers = [];

    {
        _info = getRoadInfo _x;
        if (_info#8) then {
            if ((getDammage _x) > 0) then {
                _bridges pushBackUnique _x;
                _bridgeMarker = format ["%bridge%2", _group, random 2];
                createMarker [_bridgeMarker, getPos _x];
                _bridgeMarker setMarkerType "mil_destroy";
                _bridgeMarker setMarkerColor "colorORANGE";
                _bridgeMarker setMarkerText "Damaged Bridge";
                _bridgeMarkers pushBack _bridgeMarker;
            };
        };
    } forEach _roads;

    if ((count _bridges) <= 0) exitWith {hint format ["No damaged Bridges in Area", groupId _group]};

    // if (pl_enable_beep_sound) then {playSound "beep"};
    [_group, "confirm", 1] call pl_voice_radio_answer;
    [_group] call pl_reset;

    sleep 0.5;

    [_group] call pl_reset;

    sleep 0.5;

    _icon = "\A3\ui_f\data\igui\cfg\simpleTasks\types\use_ca.paa";
    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", _icon];

    private _escort = {
        if (_x != (leader _group) and _x != _engineer) exitWith {_x};
        objNull
    } forEach (units _group);

    {
        [_x, getPos _x, _x getDir _cords, 15, false] spawn pl_find_cover;
    } forEach (units _group) - [_engineer] - [_escort];

    _engineer disableAI "AUTOCOMBAT";
    _engineer disableAI "TARGET";
    _engineer disableAI "AUTOTARGET";
    _escort disableAI "AUTOCOMBAT";
    _group setBehaviour "AWARE";
    {
        _x setVariable ['pl_is_ccp_medic', true];
        _x setVariable ["pl_engaging", true];
        _x setUnitTrait ["camouflageCoef", 0.5, true];
        _x setVariable ["pl_damage_reduction", true];
        _x setUnitPosWeak "MIDDLE";
    } forEach [_engineer, _escort];

    _roads = _roads - _bridges;
    _movePos = getPos (([_roads, [], {_engineer distance _x }, "ASCEND"] call BIS_fnc_sortBy)#0);
    _engineer doMove _movePos;
    _escort doFollow _engineer;

    sleep 1;
    waitUntil {sleep 0.5; (!alive _engineer) or (unitReady _engineer) or !(_group getVariable ["onTask", true])};

    if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: Starting Repairs", (groupId _group)]};
    if (pl_enable_map_radio) then {[_group, "...Starting Repairs", 20] call pl_map_radio_callout};

    _repairTime = time + 100;

    waitUntil {sleep 0.5; time >= _repairTime or !(_group getVariable ["onTask", true]) or !alive _engineer or _engineer getVariable ["pl_wia", false]};

    if ((_group getVariable ["onTask", false]) and alive _engineer and !(_engineer getVariable ["pl_wia", false])) then {
        {
            _x setDamage 0;
        } forEach _bridges;
        if (pl_enable_beep_sound) then {playSound "beep"};
        if (pl_enable_chat_radio) then {(leader _group) sideChat format ["%1: Bridge Repairs completeted", (groupId _group)]};
        if (pl_enable_map_radio) then {[_group, "...Bridge Repairs completeted", 20] call pl_map_radio_callout};
        [_group] call pl_reset;
    };
    _engineer setVariable ['pl_is_ccp_medic', false];
    _escort setVariable ['pl_is_ccp_medic', false];

    {
        deleteMarker _x;
    } forEach _bridgeMarkers;
};

