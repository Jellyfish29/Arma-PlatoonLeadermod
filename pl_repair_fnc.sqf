pl_eng_vic_cls_names = ["B_APC_Tracked_01_CRV_F", "B_Truck_01_Repair_F"];
pl_destroyed_vics_data = [];
pl_show_dead_vehicles = false;
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
        _vicData = [];
        _pos = getPos _killed;
        _vicData pushBack _pos;
        _vicData pushBack _killed;
        _type = typeOf _killed;
        _vicData pushBack _type;
        _markerName = format ["destroyed%1", _killed];
        createMarker [_markerName, _pos];
        _markerName setMarkerType "mil_destroy";
        _markerName setMarkerText "Damaged Vehicle";
        _vicData pushBack _markerName;
        _vicData pushBack (groupId _group);
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
    _newUnit setUnconscious true;
    [_newUnit] spawn pl_wia_callout;
    [_newUnit] spawn pl_bleedout;
    _newUnit setVariable ["pl_damage_reduction", true];
    sleep 0.1;
    player hcSetGroup [_group];
};

pl_repair = {
    private ["_engVic", "_toDeleteVic", "_toCreateVic", "_medic", "_vicGroup", "_cords", "_marker", "_callsign"];
    _group = hcSelected player select 0;
    if (vehicle (leader _group) != leader _group) then {
        _engVic = vehicle (leader _group);
        if !((typeOf _engVic) in pl_eng_vic_cls_names) exitWith {leader _group sideChat "no eng vic"};

        {
            if (getNumber ( configFile >> "CfgVehicles" >> typeOf _x >> "attendant" ) isEqualTo 1) then {
                _medic = _x;
            };
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
            {
                if ((_cords distance2D (_x select 0)) < 20) then {
                    _toDeleteVic = _x select 1;
                    _toCreateVic = _x select 2;
                    _marker = _x select 3;
                    _callsign = _x select 4;
                };
            } forEach pl_destroyed_vics_data;
            if (isNil "_toDeleteVic") exitWith {leader _group sideChat "No demaged Vehicles found, over"; playSound "beep";};

            _group setVariable ["onTask", false];
            sleep 0.25;

            _group setVariable ["onTask", true];
            _group setVariable ["setSpecial", true];
            _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\repair_ca.paa"];

            for "_i" from count waypoints _group - 1 to 0 step -1 do{
                deleteWaypoint [_group, _i];
            };
            _pos = getPos _toDeleteVic;
            _group addWaypoint [_cords, 0];
            leader _group sideChat format ["%1 is moving to damaged vehicle, over", (groupId _group)];
            playSound "beep";
            sleep 4;
            waitUntil {!alive _engVic or (unitReady _engVic)};
            _group leaveVehicle _engVic;
            // Revive Crew
            sleep 7;
            [(leader _group), _toDeleteVic] spawn pl_repair_anim;
            if !(isNil "_medic") then {
                // unassignVehicle _medic;
                // doGetOut _medic;
                _reviveTargets = _cords nearObjects ["Man", 60];
                {
                    if (lifeState _x isEqualTo "INCAPACITATED") then {
                        _h1 = [_group, _medic, nil, _x, _cords, 20] spawn pl_ccp_revive_action;
                        waitUntil {scriptDone _h1 or !(_group getVariable "onTask")};
                        _vicGroup = (group _x);
                    };
                } forEach _reviveTargets;
            };
            sleep 60;
            deleteMarker _marker;
            deleteVehicle _toDeleteVic;
            sleep 0.1;
            _newVic = _toCreateVic createVehicle _pos;
            sleep 2;
            _group addVehicle _engVic;
            {
                [_x] allowGetIn true;
                [_x] orderGetIn true;
                _x call BIS_fnc_ambientAnim__terminate;
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
            sleep 15;
            _newGroup = createVehicleCrew _newVic;
            if !(isNil "_vicGroup") then {
                (units _newGroup) joinSilent _vicGroup;
                playsound "beep";
                (leader _vicGroup) sideChat format ["%1 is back up and fully operational, over", (groupId _vicGroup)];
            }
            else
            {
                player hcSetGroup [_newGroup];
                _newGroup setGroupId [_callsign];
                playsound "beep";
                (leader _newGroup) sideChat format ["%1 is back up and fully operational, over", (groupId _newGroup)];
            };
        };
    };
};

pl_repair_anim = {
    params ["_unit", "_vic"];
    _pos = getPos _vic;
    _unit doMove _pos;
    sleep 1;
    waitUntil {!alive _unit or (unitReady _unit)};
    [_unit, "REPAIR_VEH_KNEEL", "FULL", objNull, true, true] call BIS_fnc_ambientAnim;
};

