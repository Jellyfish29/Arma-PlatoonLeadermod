Pl_marta = {
    params ["_opfGrp", ["_reveal", false]];
    private ["_unitText"];

    if (_opfGrp getVariable ["pl_not_recon_able", false]) exitWith {};

    _leader = leader _opfGrp;
    if (vehicle _leader != _leader and ((assignedVehicleRole _leader)#0) == "cargo") exitWith {};

    _callsign = groupId _opfGrp;
    private _markerNameArrow = format ["intelMarkerArrow%1", _opfGrp];
    private _markerNameGroup = format ["intelMarkerGroup%1", _opfGrp];
    private _markerNameStrength = format ["intelMarkerStrength%1", _opfGrp];
    private _markerNameOpfTactic = format ["interMarkerOpfTactic%1", _opfGrp];

    private _setTacMarker = false;
    private _tacMarkerType = "";
    switch (_opfGrp getVariable ["pl_opf_tac_marker", ""]) do { 
        case "" : {_setTacMarker = false; _tacMarkerType = ""}; 
        case "position" : {_setTacMarker = true; _tacMarkerType = "marker_position_eny"};
        case "attack" : {_setTacMarker = true; _tacMarkerType = "marker_std_atk"};
        default {_setTacMarker = false; _tacMarkerType = ""}; 
    };

    private _sideColor = "colorOpfor";
    private _sideColorRGB = [0.5,0,0,0.5];
    private _side = side _leader;
    switch (_opfGrp getVariable ["pl_opf_side", _side]) do { 
        case west : {_sideColor = "colorBlufor"; _sideColorRGB = [0,0.3,0.6,0.5]}; 
        case east : {_sideColor = "colorOpfor"; _sideColorRGB = [0.5,0,0,0.5]};
        case resistance : {_sideColor = "colorIndependent"; _sideColorRGB = [0,0.5,0,0.5]};
        default {_sideColor = "exit"; _sideColorRGB = [0.5,0,0,0.5];}; 
    };

    if (_sideColor == "exit") exitWith {};


    // 50 % chance to create Marker
    if (((random 1) < 0.5 and (currentWaypoint _opfGrp) < count (waypoints _opfGrp)) or ((random 1) < 0.15 and (currentWaypoint _opfGrp) >= count (waypoints _opfGrp)) or _reveal) then {

        _unitText = getText (configFile >> "CfgVehicles" >> typeOf (vehicle (leader _opfGrp)) >> "textSingular");


        private _status = "f";
        if !(_reveal) then {
            _status = "s";
        };
        // private _markerTypeType = format ["unknown_%1_pl", _status];
        private _markerTypeType = "mil_dot";
        private _markerSize = 1;

        if !(isNull objectParent (leader _opfGrp)) then {
            private _vic = vehicle (leader _opfGrp);

            switch (_unitText) do {
                case "truck" : {
                    _markerTypeType = format ["%1_%2_truck_sup_pl", pl_opfor_prefix, _status];
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportSoldier")) > 8) then {_markerTypeType = format ["%1_%2_truck_sup_pl", pl_opfor_prefix, _status]} else {
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportAmmo")) > 0) then {_markerTypeType = format ["%1_%2_truck_sup_pl", pl_opfor_prefix, _status]} else {;
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportRepair")) > 0) then {_markerTypeType = format ["%1_%2_truck_sup_pl", pl_opfor_prefix, _status]}}};
                };
                case "car" : {
                    _markerTypeType = format ["%1_%2_truck_pl", pl_opfor_prefix, _status];
                    if ([_vic] call pl_is_apc) then {_markerTypeType = format ["%1_%2_apcwe_pl", pl_opfor_prefix, _status]} else {
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportSoldier")) > 8) then {_markerTypeType = format ["%1_%2_truck_sup_pl", pl_opfor_prefix, _status]} else {
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportAmmo")) > 0) then {_markerTypeType = format ["%1_%2_truck_sup_pl", pl_opfor_prefix, _status]} else {;
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportRepair")) > 0) then {_markerTypeType = format ["%1_%2_truck_sup_pl", pl_opfor_prefix, _status]}}}};
            }; 
                case "tank" : {
                    _markerTypeType = format ["%1_%2_tank_pl", pl_opfor_prefix, _status];
                    if ((getNumber (configFile >> "cfgVehicles" >> typeOf _vic >> "transportSoldier")) > 6) then {_markerTypeType = format ["%1_%2_apctr_pl", pl_opfor_prefix, _status]};
                };
                case "APC" : {
                    _markerTypeType = format ["%1_%2_apctr_pl", pl_opfor_prefix, _status];
                    if (_vic isKindOf "CAR") then {_markerTypeType = format ["%1_%2_apcwe_pl", pl_opfor_prefix, _status]};
                };
                default {_markerTypeType = format ["%1_%2_truck_pl", pl_opfor_prefix, _status]};
            };

            if (_unitText == "tank" and !(["apctr", _markerTypeType] call BIS_fnc_inString)) then {

                _isAPCtr = {
                    if ([_x, typeOf _vic] call BIS_fnc_inString) exitWith {true};
                    false
                } forEach ["m113", "bmp", "m2a2", "m2a3", "mtlb", "bmd"];
                if (_isAPCtr) then {_markerTypeType = format ["%1_%2_apctr_pl", pl_opfor_prefix, _status];}
            };

        } else {
            if (count (units _opfGrp) <= 6) then {
                // inf Team
                _markerTypeType = format ["%1_%2_t_inf_pl", pl_opfor_prefix, _status];
            } else {
                // Inf Squad
                _markerTypeType = format ["%1_%2_s_inf_pl", pl_opfor_prefix, _status];
            };
        };

        private _opfDir = -1;
        if ((currentWaypoint _opfGrp) < count (waypoints _opfGrp) and (waypointPosition ((waypoints _opfGrp) select (currentWaypoint _opfGrp)) distance2D _leader) > 50) then {
            _wp = waypointPosition ((waypoints _opfGrp) select (currentWaypoint _opfGrp));
            _opfDir = _leader getDir _wp;
            _pos = (getPos _leader) getPos [45, _opfDir];
            pl_opfor_wp_dic set [groupId _opfGrp, [getPos _leader, _pos, _sideColorRGB, _opfGrp]];
        } else {
            if (_callsign in pl_opfor_wp_dic) then {pl_opfor_wp_dic deleteat _callsign};
        };

        if !(_callsign in pl_marta_dic) then {
            createMarker [_markerNameGroup, getPos _leader];
            pl_marta_dic set [_callsign, [_opfGrp, [_markerNameGroup, _markerNameStrength]]];
            [_opfGrp, _unitText, _opfDir] spawn pl_marta_spotrep;

            _markerNameGroup setMarkerSize [_markerSize, _markerSize];
            // _markerNameGroup setMarkerColor _sideColor;
            // first time call out
        } else {
            _markerNameGroup setMarkerPos (getPos _leader);
        };

        _markerNameGroup setMarkerType _markerTypeType;
        
        if (_reveal) then {
            _markerNameGroup setMarkerAlpha 0.9;
        } else {
            _markerNameGroup setMarkerAlpha 0.8;
        };

        if (_setTacMarker) then {

            if !(_markerNameOpfTactic in ((pl_marta_dic get _callsign)#1)) then {


                private _targets = ((getPos _leader) nearEntities [["Man"], 1000]) select {side _x == playerSide};

                if !(_targets isEqualto []) then {

                    _target = ([_targets, [], {_leader distance2D _x}, "ASCEND"] call BIS_fnc_sortBy)#0;
                    private _targetPos = getPos _target;
                    private _targetDir = _leader getDir _targetPos;
                    private _tacMarkerPos = (getPos _leader) getPos [6, _targetDir];
                    if ((_opfGrp getVariable ["pl_opf_tac_marker", ""]) == "attack") then {
                        _tacMarkerPos = (getPos _leader) getPos [((getPos _leader) distance2D _targetPos) / 2, _targetDir];
                    };
                     createMarker [_markerNameOpfTactic, _tacMarkerPos];
                    _markerNameOpfTactic setMarkerType _tacMarkerType;
                    _markerNameOpfTactic setMarkerColor _sideColor;
                    _markerNameOpfTactic setMarkerDir _targetDir;
                    _markerNameOpfTactic setMarkerSize [_markerSize, _markerSize];

                    pl_marta_dic set [_callsign, [_opfGrp, [_markerNameGroup, _markerNameStrength, _markerNameOpfTactic]]];
                };
            } else {
                if ((_opfGrp getVariable ["pl_opf_tac_marker", ""]) == "position") then {_markerNameOpfTactic setMarkerPos (getPos _leader)};
            };     
        } else {
            deleteMarker _markerNameOpfTactic;
            pl_marta_dic set [_callsign, [_opfGrp, [_markerNameGroup, _markerNameStrength]]];
        };

        _opfGrp setVariable ["pl_active_recon_markers", [_markerNameGroup, _markerNameStrength, _markerNameOpfTactic]];
    };
};

pl_marta_spotrep = {
    params ["_grp", "_unitText", "_opfDir"];

    if !(pl_active_recon_groups isEqualTo []) then {
        _group = selectRandom pl_active_recon_groups;
        _grid = toupper (mapGridPosition (getPos (leader _grp)));
        _unitText = toUpper _unitText;
        private _message = format ["SPOTREP: Enemy %1 at %2", _unitText, _grid];
        if !(_opfDir == -1) then {
            _message = _message + format [" Direction %1", round _opfDir];
        };

        if (pl_enable_beep_sound) then {playSound "radioinc"};
        if (pl_enable_beep_sound) then {playSound "beep"};
        if (pl_enable_chat_radio) then {(leader _group) sideChat _message};
        if (pl_enable_map_radio) then {[_group, _message, 30] call pl_map_radio_callout};
        sleep 0.5;
        if (pl_enable_beep_sound) then {playSound "radioina"};
        if (pl_enable_beep_sound) then {playSound "beep"};
    }
};