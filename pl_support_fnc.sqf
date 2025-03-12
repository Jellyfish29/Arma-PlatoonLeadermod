sleep 3;

pl_cas_cords = [0,0,0];
pl_arty_cords = [0,0,0];
pl_mapClicked = false;
pl_cas_gun_cd = 0;
pl_cas_gun_rocket_cd = 0;
pl_cas_cluster_cd = 0;
pl_cas_jdam_cd = 0;
pl_plane_sad_cd = 0;
pl_helo_sad_cd = 0;
pl_uav_sad_cd = 0;
pl_medevac_sad_cd = 0;
pl_gun_enabled = 1;
pl_gun_rocket_enabled = 1;
pl_cluster_enabled = 1;
pl_jdam_enabled = 1;
pl_plane_sad_enabled = 1;
pl_helo_sad_enabled = 1;
pl_uav_sad_enabled = 1;
pl_medevac_sad_enabled = 1;
pl_supply_sad_enabled = 1;
pl_sorties = parseNumber pl_sorties;
pl_arty_ammo = parseNumber pl_arty_ammo;
pl_cancel_strike = false;
pl_arty_rounds = 6;
pl_arty_dispersion = 100;
pl_arty_delay = 5;
pl_mortar_rounds = 4;
pl_arty_cords = [0,0,0];
pl_cas_active = 1;
pl_cas_cd = 0;
pl_current_med_evac_heli = objNull;
pl_current_supply_heli = objNull;
pl_jtac_arty_cd = 0;

// if (isNil{pl_support_module_active}) then {
//     pl_arty_ammo = 30;
//     pl_sorties = 15;
// };

pl_support_status = {
    _gunCd = "ON STATION";
    _gunColor = "#66ff33";
    _gunRocketCd = "ON STATION";
    _gunRocketColor = "#66ff33";
    _clusterCd = "ON STATION";
    _clusterColor = "#66ff33";
    _jdamCd = "ON STATION";
    _jdamColor = "#66ff33";
    _sadPlaneCd = "ON STATION";
    _sadPlaneColor = "#66ff33";
    _sadHeloCd = "ON STATION";
    _sadHeloColor = "#66ff33";
    _sadUavCd = "ON STATION";
    _sadUavColor = "#66ff33";
    _sadMedevacCd = "ON STATION";
    _sadMedevacColor = "#66ff33";
    _time = time + 8;
    while {time < _time} do {
        if (time < pl_cas_cd) then {
            _gunCd = format ["%1s", round (pl_cas_cd - time)];
            _gunColor = '#b20000';
        };
        if (time < pl_cas_cd) then {
            _gunRocketCd = format ["%1s", round (pl_cas_cd - time)];
            _gunRocketColor = '#b20000';
        };
        if (time < pl_cas_cd) then {
            _clusterCd = format ["%1s", round (pl_cas_cd - time)];
            _clusterColor = '#b20000';
        };
        if (time < pl_cas_cd) then {
            _jdamCd = format ["%1s", round (pl_cas_cd - time)];
            _jdamColor = '#b20000';
        };
        if (time < pl_cas_cd) then {
            _sadPlaneCd = format ["%1s", round (pl_cas_cd - time)];
            _sadPlaneColor = '#b20000';
        };
        if (time < pl_cas_cd) then {
            _sadHeloCd = format ["%1s", round (pl_cas_cd - time)];
            _sadHeloColor = '#b20000';
        };
        if (time < pl_uav_sad_cd) then {
            _sadUavCd = format ["%1s", round (pl_uav_sad_cd - time)];
            _sadUavColor = '#b20000';
        };
        if (time < pl_medevac_sad_cd) then {
            _sadMedevacCd = format ["%1s", round (pl_medevac_sad_cd - time)];
            _sadMedevacColor = '#b20000';
        };
        _batteryRounds = [(pl_arty_groups#pl_active_arty_group_idx) getVariable ["pl_active_arty_guns", []]] call pl_get_arty_ammo;

        _batteryRoundsFinal = createHashMap;
        {
            _batteryRoundsFinal set [[_x] call pl_get_arty_type_to_name, _y];
        } forEach _batteryRounds;
        // _batteryRounds = _batteryRounds apply {[_x] call pl_get_arty_type_to_name};
         _message = format ["
            <t color='#004c99' size='1.3' align='center' underline='1'>CAS</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Sorties:</t><t color='#00ff00' size='0.8' align='right'>%10</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Viper 1 (Gun Run)</t><t color='%1' size='0.8' align='right'>%2</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Viper 4 (Attack Run)</t><t color='%3' size='0.8' align='right'>%4</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Black Knight 1-2 (Cluster)</t><t color='%5' size='0.8' align='right'>%6</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Stroke 3 (JDAM)</t><t color='%7' size='0.8' align='right'>%8</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Reaper 1 (SAD Plane)</t><t color='%11' size='0.8' align='right'>%12</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Black Jack 4 (SAD HELO)</t><t color='%13' size='0.8' align='right'>%14</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Sentry 3 (UAV Recon)</t><t color='%15' size='0.8' align='right'>%16</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Angel 6 (MEDEVAC)</t><t color='%17' size='0.8' align='right'>%18</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Harvester 2 (Supply)</t><t color='%17' size='0.8' align='right'>%18</t>
            <br /><br />
            <t color='#004c99' size='1.3' align='center' underline='1'>Artillery</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Available Rounds</t><t color='#ffffff' size='0.8' align='right'>%9x</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Available Rounds %19:</t><t color='#ffffff' size='0.8' align='right'></t>
            <t color='#ffffff' size='0.8' align='left'>%20</t><t color='#ffffff' size='0.8' align='right'></t>
        ", _gunColor, _gunCd, _gunRocketColor, _gunRocketCd, _clusterColor, _clusterCd, _jdamColor, _jdamCd,  pl_arty_ammo, pl_sorties, _sadPlaneColor, _sadPlaneCd, _sadHeloColor, _sadHeloCd, _sadUavColor, _sadUavCd, _sadMedevacColor, _sadMedevacCd, groupId (pl_arty_groups#pl_active_arty_group_idx), _batteryRoundsFinal];

        hintSilent parseText _message;
        sleep 1;
    };
    hintSilent "";
};

pl_cas = {
    params ["_key"];
    private ["_sortiesCost", "_cords", "_dir", "_support", "_casType", "_plane", "_cs", "_markerName", "_mPos"];

    switch (_key) do { 
        case 1 : {_sortiesCost = 1}; 
        case 2 : {_sortiesCost = 2};
        case 3 : {_sortiesCost = 4}; 
        case 4 : {_sortiesCost = 5}; 
        default {_sortiesCost = 1}; 
    };

    if (pl_sorties < _sortiesCost) exitWith {hint "Not enough Sorties Left"};

    if (visibleMap or !(isNull findDisplay 2000)) then {

        if (pl_sorties < _sortiesCost) exitWith {hint "Not enough Sorties Left"};

        hintSilent "";
        // hint "Select STRIKE location on MAP (SHIFT + LMB to cancel)";
        _message = "Select STRIKE Location <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>";
        hint parseText _message;

        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;

        onMapSingleClick {
            pl_cas_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {sleep 0.1;};
        pl_mapClicked = false;
        // hint "Select APPROACH Vector for Strike (SHIFT + LMB to cancel)";
        _message = "Select APPROACH Vector <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>";
        hint parseText _message;

        sleep 0.1;
        _cords = pl_cas_cords;
        _markerName = format ["cas%1", _key];
        createMarker [_markerName, _cords];
        _markerName setMarkerType "mil_arrow2";
        _markerName setMarkerColor "colorRED";
        if (pl_cancel_strike) exitWith {};

        onMapSingleClick {
            pl_cas_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {
            if (visibleMap) then {
                _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            } else {
                _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
            };
            _dir = _cords getDir _mPos;
            _markerName setMarkerDir _dir;
        };
        pl_mapClicked = false;

    }
    else
    {
        _cords =  screenToWorld [0.5,0.5];
        _dir = player getDir _cords;
        _markerName = format ["cas%1", _key];
        createMarker [_markerName, _cords];
        _markerName setMarkerType "mil_arrow2";
        _markerName setMarkerColor "colorRED";
        _markerName setMarkerDir _dir;
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName};
    pl_sorties = pl_sorties - _sortiesCost;

    switch (_key) do { 
        case 1 : {pl_cas_active = 0, _casType = 0, _plane = pl_cas_plane_1, _cs = 'Viper 1'};
        case 2 : {pl_cas_active = 0, _casType = 2, _plane = pl_cas_plane_1, _cs = 'Viper 4'};
        case 3 : {pl_cas_active = 0,  _casType = 3, _plane = pl_cas_plane_3, _cs = 'Black Knight 2'}; 
        case 4 : {pl_cas_active = 0,  _casType = 3, _plane = pl_cas_plane_2, _cs = 'Stroke 3'};
        default {sleep 0.1}; 
    };
    sleep 1;
    _group = createGroup [playerSide, true];
    _support = _group createUnit ["ModuleCAS_F", _cords, [],0 , ""];
    
    _support setVariable ["vehicle", _plane];
    _support setVariable ["type", _casType];

    if (pl_enable_beep_sound) then {playSound "beep"};
    [playerSide, "HQ"] sideChat "Strike Aircraft on the Way!";
    sleep 1;
    _support setDir _dir;
    sleep 5;
    _vicGroup = group (driver (_support getVariable "plane"));
    if (isNil "_vicGroup") exitWith {
        deleteVehicle _support;
        hint "Defined Plane Class not supported!";
        deleteMarker _markerName;
    };
    [_vicGroup, true] call pl_change_to_vic_symbols;
    _vicGroup setGroupId [_cs];
    _vicGroup setVariable ["pl_not_addalbe", true];
    waitUntil {sleep 0.5; _support isEqualTo objNull};
    deleteMarker _markerName;
    sleep 8;
    switch (_key) do {
        case 1 : {
        pl_cas_cd = time + 60;//80;
     }; 
        case 2 : {
        pl_cas_cd = time + 60;//120;
     }; 
        case 3 : {
        pl_cas_cd = time + 60;//200;
    };
        case 4 : {
        pl_cas_cd = time + 60;//360;
    };
        default {pl_cas_cd = time + 60;}; 
    };

    waitUntil {sleep 1; time > pl_cas_cd};
    pl_cas_active = 1;

    if (pl_enable_beep_sound) then {playSound "beep"};
    [playerSide, "HQ"] sideChat format ["%1, is back on Station", _cs];
};

pl_arty = {
    private ["_salvos", "_markerName", "_mPos"];

    if (pl_arty_ammo < pl_arty_rounds) exitWith {
        // if (pl_enable_beep_sound) then {playSound "beep"};
        hint "Not enough ammunition left!";
    };
    if (visibleMap or !(isNull findDisplay 2000)) then {

        _message = "Select STRIKE Location <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>";
        hint parseText _message;

        _markerName = createMarker ["pl_arty_marker", pl_arty_cords];
        _markerName setMarkerColor pl_side_color;
        _markerName setMarkerShape "ELLIPSE";
        _markerName setMarkerBrush "Border";
        // _markerName setMarkerAlpha 0.9;
        _markerName setMarkerSize [pl_arty_dispersion, pl_arty_dispersion];
        pl_cancel_strike = false;
        onMapSingleClick {
            pl_arty_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hint "";
            onMapSingleClick "";
        };
        while {!pl_mapClicked} do {
            if (visibleMap) then {
                _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            } else {
                _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
            };
            _markerName setMarkerPos _mPos;
        };
        pl_mapClicked = false;
    }
    else
    {
        pl_arty_cords = screenToWorld [0.5,0.5];

        _markerName = createMarker ["pl_arty_marker", pl_arty_cords];
        _markerName setMarkerColor pl_side_color;
        _markerName setMarkerShape "ELLIPSE";
        _markerName setMarkerBrush "Border";
        // _markerName setMarkerAlpha 0.9;
        _markerName setMarkerSize [pl_arty_dispersion, pl_arty_dispersion];
    };
    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName};
    pl_arty_enabled = 0;
    
    _markerName setMarkerAlpha 0.4;
    createMarker ["pl_arty_center", pl_arty_cords];
    "pl_arty_center" setMarkerType "mil_destroy";
    "pl_arty_center" setMarkerText format ["%1 HE / %2 m / %3 s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay];

    pl_arty_ammo = pl_arty_ammo - pl_arty_rounds;
    if (pl_enable_beep_sound) then {playSound "beep"};
    [playerSide, "HQ"] sideChat format ["Fire Mission Confirmend // ETA 40 Seconds"];
    sleep 40;
    if (pl_enable_beep_sound) then {playSound "beep"};
    [playerSide, "HQ"] sideChat format ["Splash"];

    _artyGroup = createGroup east;

    _salvos = pl_arty_rounds / 3;
    if (pl_arty_rounds == 1) then {
        _salvos = 1;
    };
    for "_i" from 1 to (_salvos) do {
        for "_j" from 1 to 3 do {
            _cords = [[[(pl_arty_cords), (pl_arty_dispersion + 45)]],[]] call BIS_fnc_randomPos;
            _support = _artyGroup createUnit ["ModuleOrdnance_F", _cords, [],0 , ""];
            _support setVariable ["type", "ModuleOrdnanceHowitzer_F_Ammo"];
            if (pl_arty_rounds == 1) exitWith {};
            sleep 0.8;
        };
        sleep pl_arty_delay; 
    };

    sleep 5;

    deleteMarker _markerName;
    deleteMarker "pl_arty_center";
    sleep 30;
    pl_arty_enabled = 1;
    [] call pl_show_fire_support_menu;
    // [playerSide, "HQ"] sideChat format ["Battery is ready for Fire Mission, over"];
};



pl_fire_on_map_arty = {
    params [["_cords", []], ["_fireMissionInfo", []]];
    private ["_mpos", "_ammoTypes", "_ammoType", "_eh", "_markerName", "_centerMarkerName", "_eta", "_battery", "_guns", "_volleys", "_isHc", "_ammoTypestr", "_ammoType"];

    // if (pl_arty_ammo < pl_arty_rounds) exitWith {
    //     // if (pl_enable_beep_sound) then {playSound "beep"};
    //     hint "Not enough ammunition left!";
    // };

    if (_cords isnotEqualTo []) then {
        pl_arty_dispersion = _fireMissionInfo#0;
        pl_arty_rounds = _fireMissionInfo#1;
        pl_arty_delay = _fireMissionInfo#2;
        pl_arty_round_type = _fireMissionInfo#3;
    };

    _markerName = createMarker [str (random 4), [0,0,0]];
    _markerName setMarkerColor pl_side_color;
    _markerName setMarkerShape "ELLIPSE";
    _markerName setMarkerBrush "Border";
    // _markerName setMarkerAlpha 1;
    _markerName setMarkerSize [pl_arty_dispersion, pl_arty_dispersion];

    switch (pl_arty_round_type) do { 
        case 1 : {_ammoTypestr = "HE"}; 
        case 2 : {_ammoTypestr = "SMK"}; 
        case 3 : {_ammoTypestr = "IL"};
        case 4 : {_ammoTypestr = "GUI"};
        case 5 : {_ammoTypestr = "MINE"};
        case 6 : {_ammoTypestr = "CLT"};
        default {_ammoTypestr = "HE"}; 
    };

    _markerName setMarkerAlpha 0.4;
    _centerMarkerName = createMarker [str (random 4), [0,0,0]];
    _centerMarkerName setMarkerType "mil_destroy";
    _centerMarkerName setMarkerText format ["%1 %4 / %2 m / %3 s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, _ammoTypestr];
    _centerMarkerName setMarkerColor pl_side_color;

    if (_cords isEqualTo []) then {

        if (visibleMap or !(isNull findDisplay 2000)) then {

            _message = "Select STRIKE Location <br /><br />
            <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>";
            hint parseText _message;

            pl_cancel_strike = false;
            onMapSingleClick {
                pl_arty_cords = _pos;
                pl_mapClicked = true;
                if (_shift) then {pl_cancel_strike = true};
                hint "";
                onMapSingleClick "";
            };
            while {!pl_mapClicked} do {
                if (visibleMap) then {
                    _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
                } else {
                    _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
                };
                _markerName setMarkerPos _mPos;
                _centerMarkerName setMarkerPos _mPos;
            };
            pl_mapClicked = false;
        }
        else
        {
            pl_arty_cords = screenToWorld [0.5,0.5];
            _markerName setMarkerPos pl_arty_cords;
            _centerMarkerName setMarkerPos pl_arty_cords;
        };


        _cords = pl_arty_cords;
        _battery = pl_arty_groups#pl_active_arty_group_idx;
    } else {

        _markerName setmarkerPos _cords;
        _centerMarkerName setmarkerPos _cords;
        _battery = selectRandom pl_arty_groups;

    };

    _isHc = false;
    if (hcLeader _battery == player) then {
        _isHc = true;
        player hcRemoveGroup _battery;
        if (_battery getVariable "setSpecial") then {
            _battery setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\destroy_ca.paa"];
        };
    };

    _guns = _battery getVariable ["pl_active_arty_guns", []];
    if (_guns isEqualTo []) exitWith {Hint "No active Guns"};

    _ammoType = (getArray (configFile >> "CfgVehicles" >> typeOf (_guns#0) >> "Turrets" >> "MainTurret" >> "magazines")) select 0;
    _eta = (_guns#0) getArtilleryETA [_cords, _ammoType];
    if (_eta == -1) exitWith {
        hint "Not in Range";
        deleteMarker _markerName;
        deleteMarker _centerMarkerName;
    };

    _eta = _eta + 5;

    // [_eta, _centerMarkerName, _ammoTypestr] spawn {
    //     params ["_eta", "_centerMarkerName", "_ammoTypestr"];
    //     _time = time +_eta;
    //     while {time < _time} do {
    //         _centerMarkerName setMarkerText format ["%1 %5 / %2 m / %3 s ETA: %4s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, round (_time - time), _ammoTypestr];
    //         sleep 1;
    //     };
    //     _centerMarkerName setMarkerText format ["%1 %4 / %2 m / %3 s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, _ammoTypestr];;
    // };

    if (pl_enable_beep_sound) then {playSound "beep"};
    if (pl_enable_chat_radio) then {(gunner (_guns#0)) sideChat format ["...Fire Mission Confimed ETA: %1s", round _eta]};
    if (pl_enable_map_radio) then {[group (gunner (_guns#0)), format ["...Fire Mission Confimed ETA: %1s", round _eta], 25] call pl_map_radio_callout};

    _volleys = round (pl_arty_rounds / (count _guns));
    _dispersion = pl_arty_dispersion;
    _delay = pl_arty_delay;
    _missionType = pl_arty_mission;

    _weapon = (getArray (configfile >> "CfgVehicles" >> typeOf (_guns#0) >> "Turrets" >> "MainTurret" >> "weapons"))#0;
    // _allMagazines = getArray (configfile >> "CfgWeapons" >> _weapon >> "Magazines"); "BWA3_RH155mm_AMOS" getArray (configfile >> "CfgWeapons" >> "BWA3_RH155mm_AMOS" >> "Magazines");
    _allMagazines = magazines (_guns#0) + [currentMagazine (_guns#0)];

    // player sideChat (str _allMagazines);

    _ammoType = "";

    switch (pl_arty_round_type) do { 
        case 1 : {_ammoTypes = _allMagazines select {["he", _x] call BIS_fnc_inString}}; 
        case 2 : {_ammoTypes = (_allMagazines select {["smoke", _x] call BIS_fnc_inString}) + (_allMagazines select {["smk", _x] call BIS_fnc_inString})}; 
        case 3 : {_ammoTypes = _allMagazines select {["illum", _x] call BIS_fnc_inString} + _allMagazines select {["flare", _x] call BIS_fnc_inString}};
        case 4 : {_ammoTypes = _allMagazines select {["guid", _x] call BIS_fnc_inString}};
        case 5 : {_ammoTypes = _allMagazines select {["mine", _x] call BIS_fnc_inString}};
        case 6 : {_ammoTypes = (_allMagazines select {["cluster", _x] call BIS_fnc_inString}) + _allMagazines select {["icm", _x] call BIS_fnc_inString}};
        default {_ammoType = (currentMagazine (_guns#0))}; 
    };

    if ((count _ammoTypes) > 0) then {
        _ammoType = ([_ammoTypes, [], {parseNumber _x}, "DESCEND"] call BIS_fnc_sortBy)#0;
    };

    if (_ammoType isEqualTo "") exitWith {format ["Battery cant Fire %1 Rounds", _ammoTypestr]};

    // private _availableMagazinesLeader = magazinesAmmo [_guns#0, true];
    // {
    //     private _availableMagazines = magazinesAmmo [_x, true];

    //     for "_i" from 0 to (count _availableMagazinesLeader) - 1 do{
    //         if (((_availableMagazinesLeader#_i)#0) isEqualTo ((_availableMagazines#_i)#0)) then {
    //             (_availableMagazinesLeader#_i) set [1, ((_availableMagazinesLeader#_i)#1) + ((_availableMagazines#_i)#1)]
    //         };
    //     }
    // } forEach (_guns - [_guns#0]);

    // private _ammoAmount = 0;

    // player sideChat (str _availableMagazinesLeader);
    // {
    //     if (_ammoType isEqualTo (_x#0)) then {
    //         _ammoAmount = _x#1;
    //     };
    // } forEach _all;

    _allAmmo = [_guns] call pl_get_arty_ammo;

    private _ammoAmount = _allAmmo get _ammoType;

    if (_ammoAmount <= 0) exitWith {hint "No Ammo Left"};

    sleep 1;

    if !(_ammoType isEqualTo (currentMagazine (_guns#0))) then {
        // Force Reolad Hack
        {

            // player sideChat _ammoType;
            // player sideChat (currentMagazine _x);

            // _x doArtilleryFire [_cords, _ammoType, 1];

            _x loadMagazine [[0], _weapon, _ammoType];
            _x setWeaponReloadingTime [gunner _x, _weapon, 0];
            // sleep 1;
        } forEach _guns;

        sleep 1;

        if (((weaponState [_guns#0, [0]])#6) > 0) then {

             

            _centerMarkerName setMarkerColor "colorCivilian";

            waitUntil {sleep 1; _centerMarkerName setMarkerText format ["%1 %5 / %2 m / %3 s ETA: %4s RELOAD: %6%7", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, round _eta, _ammoTypestr, round ((1 - ((weaponState [_guns#0, [0]])#6)) * 100), "%"]; ((weaponState [_guns#0, [0]])#6) <= 0};

            _centerMarkerName setMarkerColor pl_side_color;

            sleep 5;
        };

    };

    [_eta, _centerMarkerName, _ammoTypestr] spawn {
        params ["_eta", "_centerMarkerName", "_ammoTypestr"];
        _time = time +_eta;
        while {time < _time} do {
            _centerMarkerName setMarkerText format ["%1 %5 / %2 m / %3 s ETA: %4s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, round (_time - time), _ammoTypestr];
            sleep 1;
        };
        _centerMarkerName setMarkerText format ["%1 %4 / %2 m / %3 s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, _ammoTypestr];;
    };

    switch (_missionType) do { 
        case "SUP" : {

            for "_i" from 1 to _volleys do {
                {
                    _firePos = [[[_cords, _dispersion]],[]] call BIS_fnc_randomPos;
                    _x setVariable ["pl_waiting_for_fired", true];
                    _x doArtilleryFire [_firePos, _ammoType, 1];
                    _eh = _x addEventHandler ["Fired", {
                        params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
                        _unit setVariable ["pl_waiting_for_fired", false];
                    }];
                    // sleep 1;
                } forEach _guns;


                _MaxDelay = time + 40;
                _minDelay = time + _delay;
                waitUntil {({_x getVariable ["pl_waiting_for_fired", true]} count _guns == 0 and time >= _minDelay) or time >= _MaxDelay};
                _centerMarkerName setMarkerColor "colorOrange";
                // waitUntil {time >= _minDelay or time >= _MaxDelay};

                // pl_arty_ammo = pl_arty_ammo - 1;
            };

            {
                // _x addMagazineTurret [_ammoType, [-1]];
                _x removeEventHandler ["Fired", _eh];
                // _x setVehicleAmmo 1;
            } forEach _guns;
        }; 
        case "ANI" : {
            {
                _firePos = [[[_cords, 30]],[]] call BIS_fnc_randomPos;
                _x doArtilleryFire [_firePos, _ammoType, _volleys];
                sleep 1;
            } forEach _guns;
            _centerMarkerName setMarkerColor "colorOrange";
        }; 
        case "BLK" : {
            
        }; 
        default {}; 
    };
    
    if (_isHc) then {
        player hcSetGroup [_battery];
        if (_battery getVariable "setSpecial") then {
            _battery setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\defend_ca.paa"];
        };
    };

    sleep (_eta + 20);
    deleteMarker _markerName;
    deleteMarker _centerMarkerName;
};




pl_interdiction_cas = {
    params ["_casTypeSad", ["_cords", []], ["_dir", 0]];
    private ["_height", "_cd", "_mPos", "_cdType", "_ehPad", "_spawnDistance", "_markerName", "_areaMarkerName", "_evacHeight", "_spawnPos", "_groupId", "_sadWp", "_planeType", "_casGroup", "_plane", "_targets", "_sortiesCost", "_onStationTime", "_sadAreaSize", "_wpType", "_flyHeight", "_ccpGroup"];

    switch (_casTypeSad) do { 
        case 1 : {
            _height = 1500;
            _flyHeight = 100;
            _spawnDistance = 6000;
            _planeType = pl_cas_plane_1;
            // _planeType = "B_Plane_Fighter_01_F";
            _sortiesCost = 2;
            _groupId = "Reaper 1";
            _evacHeight = 45;
            _cd = 300;
            _onStationTime = 30;
            _sadAreaSize = 1000;
            _wpType = "SAD";
        }; 
        case 2 : {
            _height = 100;
            _flyHeight = 100;
            _spawnDistance = 3000;
            _planeType = pl_cas_Heli_1;
            _sortiesCost = 2;
            _groupId = "Black Jack 4";
            _evacHeight = 30;
            _onStationTime = 60;
            _sadAreaSize = 500;
            _wpType = "SAD";
        };
        case 3 : {
            _height = 1700;
            _flyHeight = 1700;
            _spawnDistance = 4500;
            _planeType = pl_uav_1;
            _sortiesCost = 3;
            _groupId = "Sentry 3";
            _evacHeight = 1700;
            _onStationTime = 300;
            _sadAreaSize = 0;
            _wpType = "LOITER";
        };
        case 4 : {
            _height = 100;
            _flyHeight = 25;
            _spawnDistance = 3000;
            _planeType = pl_medevac_Heli_1;
            _sortiesCost = 4;
            _groupId = "Angel 6";
            _evacHeight = 150;
            _onStationTime = 240;
            _sadAreaSize = 300;
            // _wpType = "TR UNLOAD";
            _wpType = "MOVE";
        };

        case 5 : {
            _height = 100;
            _flyHeight = 25;
            _spawnDistance = 3000;
            _planeType = pl_supply_Heli_1;
            _sortiesCost = 4;
            _groupId = "Harvester 2";
            _evacHeight = 150;
            _onStationTime = 500;
            _sadAreaSize = 50;
            // _wpType = "TR UNLOAD";
            _wpType = "MOVE";
        };
        default {}; 
    };

    if (pl_sorties < _sortiesCost) exitWith {hint "Not enough Sorties Left"};

    if (_cords isEqualTo []) then {

        if (visibleMap or !(isNull findDisplay 2000)) then {

            if (pl_sorties < _sortiesCost) exitWith {hint "Not enough Sorties Left"};

            hintSilent "";
            _message = "Select STRIKE Location <br /><br />
            <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>";
            hint parseText _message;
            _areaMarkerName = format ["%1casarea", _casTypeSad];
            createMarker [_areaMarkerName, [0,0,0]];
            _areaMarkerName setMarkerShape "ELLIPSE";
            _areaMarkerName setMarkerBrush "Border";
            _areaMarkerName setMarkerColor "ColorOrange";
            // _areaMarkerName setMarkerAlpha 0.7;
            _areaMarkerName setMarkerSize [_sadAreaSize, _sadAreaSize];

            onMapSingleClick {
                pl_cas_cords = _pos;
                pl_mapClicked = true;
                if (_shift) then {pl_cancel_strike = true};
                hintSilent "";
                onMapSingleClick "";
            };

            while {!pl_mapClicked} do {
                if (visibleMap) then {
                    _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
                } else {
                    _mPos = (findDisplay 2000 displayCtrl 2000) ctrlMapScreenToWorld getMousePosition;
                };
                _areaMarkerName setMarkerPos _mPos;
            };
            pl_mapClicked = false;
            _areaMarkerName setMarkerAlpha 0.28;
            _message = "Select APPROACH Vector <br /><br />
            <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>";
            hint parseText _message;

            sleep 0.1;
            _cords = pl_cas_cords;
            _markerName = format ["cassad%1", _casTypeSad];
            createMarker [_markerName, _cords];
            _markerName setMarkerType "mil_arrow2";
            _markerName setMarkerColor "colorRED";

            if (pl_cancel_strike) exitWith {};
            onMapSingleClick {
                pl_cas_cords = _pos;
                pl_mapClicked = true;
                if (_shift) then {pl_cancel_strike = true};
                hintSilent "";
                onMapSingleClick "";
            };

            while {!pl_mapClicked} do {
                _dir = [_cords, ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)] call BIS_fnc_dirTo;
                _markerName setMarkerDir _dir;
            };
            pl_mapClicked = false;


        }
        else
        {
            _cords =  screenToWorld [0.5,0.5];
            _dir = player getDir _cords;
            _markerName = format ["cassad%1", _casTypeSad];
            createMarker [_markerName, _cords];
            _markerName setMarkerType "mil_arrow2";
            _markerName setMarkerColor "colorRED";
            _markerName setMarkerDir _dir;
        };

    } else {

        _markerName = format ["cassad%1", _casTypeSad];
        createMarker [_markerName, _cords];
        _markerName setMarkerType "mil_destroy";
        _markerName setMarkerColor "colorRED";
        // _markerName setMarkerDir _dir;

        _areaMarkerName = format ["%1casarea", _casTypeSad];
        createMarker [_areaMarkerName, _cords];
        _areaMarkerName setMarkerShape "ELLIPSE";
        _areaMarkerName setMarkerBrush "Border";
        _areaMarkerName setMarkerColor "ColorOrange";
        // _areaMarkerName setMarkerAlpha 0.7;
        _areaMarkerName setMarkerSize [_sadAreaSize, _sadAreaSize];
    };

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName; deleteMarker _areaMarkerName};
        
    if (pl_enable_beep_sound) then {playSound "radioina"};
    [playerSide, "HQ"] sideChat "Strike Aircraft on the Way!";

    pl_sorties = pl_sorties - _sortiesCost;

    switch (_casTypeSad) do { 
        case 1 : {pl_cas_active = 0;}; 
        case 2 : {pl_cas_active = 0;};
        case 3 : {pl_uav_sad_enabled = 0;};
        case 4 : {pl_medevac_sad_enabled = 0;};
        case 5 : {pl_supply_sad_enabled = 0;}; 
        default {}; 
    };

    _spawnPos = [_spawnDistance*(sin (_dir - 180)), _spawnDistance*(cos (_dir - 180)), 0] vectorAdd _cords;

    _casGroup = createGroup playerside;
    _casGroup setGroupId [_groupId];
    _casGroup setVariable ["pl_not_addalbe", true];
    _casGroup setVariable ["onTask", true];

    if (_casTypeSad == 3) then {
        _casGroup setCombatMode "BLUE";
        _casGroup setVariable ["pl_combat_mode", true];
        _casGroup setVariable ["pl_hold_fire", true];
    };

    _p = [_spawnPos, _dir, _planeType, _casGroup] call BIS_fnc_spawnVehicle;
    sleep 1;
    _plane = _p#0;

    if (isNil "_plane") exitWith {
        deleteMarker _markerName;
        deleteMarker _areaMarkerName;
        hint "Defined Plane Class not supported!";
    }; 

    [_plane, _height] call BIS_fnc_setHeight;
    _plane forceSpeed 140;
    _plane flyInHeight _flyHeight;
    sleep 0.1;
    _plane setUnloadInCombat [false, false];

    {
        _x setSkill 1;
    } forEach crew (_plane);

    _sadWp = _casGroup addWaypoint [_cords, 0];
    _sadWp setWaypointType _wpType;

    private _weapons = [];
    {
        if (tolower ((_x call bis_fnc_itemType) select 1) in ["bomblauncher", "missilelauncher", "machinegun", "rocketLauncher", "LaserDesignator"]) then {
            _modes = getarray (configfile >> "cfgweapons" >> _x >> "modes");
            if (count _modes > 0) then {
                _mode = _modes select 0;
                if (_mode == "this") then {_mode = _x;};
                    _weapons set [count _weapons,[_x,_mode]];
            };
        };
    } foreach ((typeOf _plane) call bis_fnc_weaponsEntityType);

    pl_rtb = false;

    switch (_casTypeSad) do { 
        case 1 : {
            // _casGroup setBehaviour "COMBAT";
            sleep 1;
            waitUntil {(_plane distance2D _cords) < 4000 or pl_rtb};
            deleteWaypoint _sadWp;

            (driver _plane) disableAI "AUTOTARGET";
            (driver _plane) disableAI "TARGET";

            if !(pl_rtb) then {

                [_plane, _cords, _sadAreaSize, _weapons, _casGroup, _spawnPos,_flyHeight] spawn {
                    params ["_plane", "_cords", "_sadAreaSize", "_weapons", "_casGroup", "_spawnPos","_flyHeight"];
                    _targets = (nearestObjects [_cords, ["Car", "Tank"], _sadAreaSize, true]) select {side _x != playerSide};

                    {
                        _target = _x;

                        if (!alive _target) then {continue};

                        if (_plane distance2D _target < 3000) then {
                            _plane doMove ((getpos _plane) getPos [3000, _plane getDir _spawnPos]);


                            waitUntil {sleep 0.25; !alive _plane or (getposasl _plane) distance2D _target > 2000 or !(_casGroup getVariable ["onTask", false])};
                        };

                        _plane doMove (getPos _target);
                        _plane reveal _target;
                        _plane dowatch _target;
                        _plane dotarget _target;

                        _plane flyInHeight _flyHeight;

                        waitUntil {sleep 0.25; !alive _plane or (getposasl _plane) distance2D _target < 1500 or !(_casGroup getVariable ["onTask", false])};

                        if (!alive _plane or !(_casGroup getVariable ["onTask", false])) exitWith {};

                        sleep 2;

                        {
                            _plane fireattarget [_target,(_x select 0)];
                        } foreach _weapons;

                        _plane doTarget objNull;
                        _plane doWatch objNull;

                    } forEach _targets;
                };
            };
        }; 
        case 2 : {
            _casGroup setBehaviour "COMBAT";
            sleep 1;
            waitUntil {(_plane distance2D _cords) < 3000 or pl_rtb};
        };
        case 3 : {
            [_casGroup, true] spawn pl_recon;
            [_casGroup, "f_uav_pl"] call pl_change_group_icon;
        };
        case 4 : {
            // "Land_HelipadEmpty_F" createVehicle _cords;
            _casGroup setBehaviour "CARELESS";
            pl_current_med_evac_heli = _plane;

            _pad = createVehicle ["Land_HelipadEmpty_F", _cords, [], 0, "CAN_COLLIDE"];
            player setVariable ["pl_landing_pad", _pad];

            _ehPad = player addEventHandler ["FiredMan", {
                 params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];

                 if (_weapon isEqualTo "Throw") then {

                    _grenadeType = typeOf _projectile;

                    if ((["green", _grenadeType] call BIS_fnc_inString) or (["yellow", _grenadeType] call BIS_fnc_inString) or (["blue", _grenadeType] call BIS_fnc_inString)) then {

                        [_projectile] spawn {
                            params ["_projectile"];
                            sleep 5;
                            _pad = player getVariable ["pl_landing_pad", objNull];
                            _pad setVehiclePosition [getPos _projectile, [], 0, "CAN_COLLIDE"];
                            
                        };
                        _unit removeEventHandler [_thisEvent, _thisEventHandler];
                    };
                };
            }];

            waitUntil {sleep 1; !alive _plane or (_plane distance2D _cords) <= 500};

            _successLanding = _plane landAt [_pad, "Land", _onStationTime];

            sleep 1;
            waitUntil {sleep 1; (isTouchingGround _plane) or !(alive _plane) or !(canmove _plane) or ((fullCrew _plane) isEqualTo []) or pl_rtb};

            // _plane flyInHeight 0;

            if ((alive _plane) and (canmove _plane) and ((fullCrew _plane) isNotEqualTo []) and !pl_rtb and _successLanding) then {

                (driver _plane) disableAI "PATH";

                
                private _gunner = gunner _plane;
                private _medic = _casGroup createUnit [typeOf _gunner, [0,0,0], [], 0, "CAN_COLLIDE"];
                _medic setUnitTrait ["Medic",true];
                _medic moveInCargo _plane;
                sleep 3;
                _ccpGroup = createGroup playerSide;
                sleep 2;
                _ccpGroup setGroupId ["Angel 6 Medic"];
                _ccpGroup setVariable ["MARTA_customIcon", ["b_med"]];
                _ccpGroup setVariable ["pl_not_addalbe", true];
                {
                    [_x] joinSilent _ccpGroup;
                    unassignVehicle _x;
                    doGetOut _x;
                } forEach [_medic, _gunner];
                _ccpGroup selectLeader _gunner;
                [_ccpGroup] call pl_set_up_ai;
                sleep 0.5;
                player hcRemoveGroup _ccpGroup;
                _ccpGroup setVariable ["MARTA_customIcon", ["b_med"]];
                _ccpGroup setVariable ["pl_not_addalbe", true];
                [_ccpGroup, true, _gunner, _sadAreaSize, 50] spawn pl_ccp;
            };
        };
        case 5 : {

            _casGroup setBehaviour "CARELESS";
            _pad = createVehicle ["Land_HelipadEmpty_F", _cords, [], 0, "CAN_COLLIDE"];
            player setVariable ["pl_landing_pad", _pad];
            pl_current_supply_heli = _plane;

            _ehPad = player addEventHandler ["FiredMan", {
                 params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_vehicle"];

                 if (_weapon isEqualTo "Throw") then {

                    _grenadeType = typeOf _projectile;

                    if ((["green", _grenadeType] call BIS_fnc_inString) or (["yellow", _grenadeType] call BIS_fnc_inString) or (["blue", _grenadeType] call BIS_fnc_inString)) then {

                        [_projectile] spawn {
                            params ["_projectile"];
                            sleep 5;
                            _pad = player getVariable ["pl_landing_pad", objNull];
                            _pad setVehiclePosition [getPos _projectile, [], 0, "CAN_COLLIDE"];

                        };
                        _unit removeEventHandler [_thisEvent, _thisEventHandler];
                    };
                };
            }];

            waitUntil {sleep 1; !alive _plane or (_plane distance2D _cords) <= 500};

            _successLanding = _plane landAt [_pad, "Land"];

            sleep 1;
            waitUntil {sleep 1; (isTouchingGround _plane) or !(alive _plane) or !(canmove _plane) or ((fullCrew _plane) isEqualTo []) or pl_rtb};

            // waitUntil {(isTouchingGround _plane) or !alive _plane or pl_rtb};
            if (alive _plane and !pl_rtb) then {
                _plane setVariable ["pl_is_supply_vehicle", true];
                _plane setVariable ["pl_supplies", pl_max_supplies_per_vic];
                _plane setVariable ["pl_avaible_reinforcements", pl_max_reinforcement_per_vic];

                [_casGroup] spawn pl_supply_point;
            };
        };
        default {}; 
    };

    // sleep 40;

    [_casGroup, true] call pl_change_to_vic_symbols;
    _time = time + _onStationTime;
    waitUntil {sleep 1; time > _time or pl_rtb};
    deleteMarker _markerName;
    deleteMarker _areaMarkerName;

    switch (_casTypeSad) do { 
        case 1 : {
            pl_cas_cd = time + 120;
            if (pl_rtb) then {pl_cas_cd = pl_cas_cd * (time / _time)};
            _cd = pl_cas_cd;
        }; 
        case 2 : {
            pl_cas_cd = time + 120;
            if (pl_rtb) then {pl_cas_cd = pl_cas_cd * (time / _time)};
            _cd = pl_cas_cd;
        };
        case 3 : {
            pl_uav_sad_cd = time + 360;
            if (pl_rtb) then {pl_uav_sad_cd = pl_uav_sad_cd * (time / _time)};
            _cd = pl_uav_sad_cd;
            player disableUAVConnectability [_plane, true];
        };
        case 4 : {
            pl_medevac_sad_cd = time + 400;
            if (pl_rtb) then {pl_medevac_sad_cd = pl_medevac_sad_cd * (time / _time)};
            _cd = pl_medevac_sad_cd;
            pl_current_med_evac_heli = objNull;
        };
        case 5 : {
            pl_supply_sad_cd = time + 400;
            if (pl_rtb) then {pl_supply_sad_cd = pl_supply_sad_cd * (time / _time)};
            _cd = pl_supply_sad_cd;
            pl_current_supply_heli = objNull;
        }; 
        default {}; 
    };

    if (alive _plane) then {
        // _targets = (driver _plane) targetsQuery [objNull, sideUnknown, "", [], 0];
        [_casGroup] call pl_reset;
        sleep 0.2;
        if (pl_enable_beep_sound) then {playSound "radioina"};
        (driver _plane) sideChat format ["%1: RTB", _groupId];
        if (pl_enable_map_radio) then {[group (driver _plane), "...RTB!", 25] call pl_map_radio_callout};

        switch (_casTypeSad) do { 
            case 1 : {}; 
            case 2 : {};
            case 3 : {};
            case 4 : {
            
                player removeEventHandler ["FiredMan", _ehPad];

                if !(isNil "_ccpGroup") then {
                    [_ccpGroup] call pl_reset;
                    sleep 1;
                    [_ccpGroup] call pl_reset;
                    sleep 1;
                    // _ccpGroup setVariable ["MARTA_customIcon", nil];
                    {
                        _x assignAsCargo _plane;
                        [_x] allowGetIn true;
                        [_x] orderGetIn true;
                        [_x] joinSilent _casGroup;
                    } forEach (units _ccpGroup);

                    _casGroup setGroupId [_groupId];

                    sleep 2;
                    _time = time + 40;
                    waitUntil {sleep 0.5; ({_x in _plane} count (units _casGroup)) == (count (units _casGroup)) or time >= _time};
                    sleep 1;
                    (driver _plane) enableAI "PATH";
                    _casGroup setBehaviour "CARELESS";
                    _plane flyInHeight _flyHeight;
                };
            };
            case 5 : {
                player removeEventHandler ["FiredMan", _ehPad];
                _time = time + 40;
                waitUntil {sleep 0.5; ({_x in _plane} count (units _casGroup)) == (count (units _casGroup)) or time >= _time};
            }; 
            default {}; 
        };

        _plane allowDamage false;
        _plane flyInHeight _evacHeight;
        _plane forceSpeed 300;
        _evacWp = _casGroup addWaypoint [_spawnPos, 0];
        _plane doMove _spawnPos;
        _despawnTime = time + 90;
        _casGroup setBehaviourStrong "CARELESS";
        while {(alive _plane) and ((_plane distance2D _spawnPos) > 100) and (time < _despawnTime)} do {
            // _targets = (driver _plane) targetsQuery [objNull, sideUnknown, "", [], 0];
            // {
            //     _casGroup forgetTarget (_x#1);
            // } forEach _targets;
            sleep 0.5;
        };
        {
            _plane deleteVehicleCrew _x;
        } forEach (crew _plane);

        {
            deleteVehicle _x;
        } forEach (units _casGroup);

        deleteVehicle _plane;
        deleteGroup _casGroup;
    };

    waitUntil {time > _cd};
    switch (_casTypeSad) do { 
        case 1 : {pl_cas_active = 1}; 
        case 2 : {pl_cas_active = 1};
        case 3 : {pl_uav_sad_enabled = 1};
        case 4 : {pl_medevac_sad_enabled = 1};
        case 5 : {pl_supply_sad_enabled = 1};
        default {}; 
    };
};

pl_add_uav_terminal = {
    //BY: [AWC] Chief Wiggum

    private ["_addGPS", "_termianlclass", "_marker", "_marker_distance", "_has_terminal"];

    _addGPS = false;
    _termianlclass = "";
    _has_terminal = false;
    _terminalPos = getPos player;
    _terminalPos = +_terminalPos;
    _terminalDistance = player distance2D _terminalPos;

    switch (side player) do {
    case WEST: {_termianlclass = "B_UavTerminal";};
    case EAST: {_termianlclass = "O_UavTerminal";};
    case INDEPENDENT: {_termianlclass = "I_UavTerminal";};
    };

    If("ItemGPS" in assignedItems player OR "ItemGPS" in items player) then 
    {
    _addGPS = true;
    };

    If(_termianlclass in assignedItems player) then 
    {
    _has_terminal = true;
    };

    player addItem _termianlclass;
    player assignItem _termianlclass;
    player action ["UAVTerminalOpen", player];

    If ((_addGPS) && !("ItemGPS" in items player)) then 
    {
    player addItem "ItemGPS";
    };

    WaitUntil {sleep 1; player distance2D _terminalPos >= _terminalDistance + 1};
    If !(_has_terminal) then 
    {
        player unassignitem _termianlclass;
        player removeItem _termianlclass;
    };

};

pl_deploy_small_uav = {
    private _group = (hcSelected player) select 0;

    _uavOperator = {
        if (((backpack _x) in ["B_UAV_01_backpack_F", "O_UAV_01_backpack_F", "I_UAV_01_backpack_F", "I_E_UAV_01_backpack_F"]) or (_x getVariable ["pl_is_uav_operator", false])) exitWith {_x};
        objNull
    } forEach (units _group);

    if (isNull _uavOperator) exitWith {hint "Group has no UAV"}; 

    [_group] spawn pl_reset;

    sleep 0.5;

    [_group] spawn pl_reset;

    sleep 1;

    if (_group != (group player)) then {
        {
            [_x, 20, getDir _x] spawn pl_find_cover;
        } forEach (units _group) - [_uavOperator];
    };

    _group setVariable ["onTask", true];
    _group setVariable ["setSpecial", true];
    _group setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\intel_ca.paa"];

    sleep 3;
    private _uavClass = "B_UAV_01_F";
    switch (side player) do {
        case WEST: {_uavClass = "B_UAV_01_F";};
        case EAST: {_uavClass = "O_UAV_01_F";};
        case INDEPENDENT: {_uavClass = "I_UAV_01_F";};
        };

    private _uavBag = unitBackpack _uavOperator;
    _uavOperator action ["PutBag"];
    
    sleep 3;

    private _laptop = createVehicle ["Land_Laptop_03_olive_F", (getPos _uavOperator) getPos [1, getDir _uavOperator], [], 2, "CAN_COLLIDE"];
    private _antenna = createVehicle ["SatelliteAntenna_01_Small_Olive_F", (getPos _uavOperator) getPos [2, (getDir _uavOperator) + 90], [], 2, "CAN_COLLIDE"];

    sleep 1;

    private _uav = createVehicle [_uavClass, getPos _uavOperator, [], 2, "NONE"];

    private _uavGroup = createVehicleCrew _uav;
    player hcSetGroup [_uavGroup];
    _uavGroup setGroupId [format ["%1 UAV", groupId _group]];
    _uav flyInHeight 150;
    private _actionId = _laptop addAction ["Use UAV-Terminal", {[] spawn pl_add_uav_terminal}];

    _uavOperator disableAI "PATH";
    _uavOperator setUnitPos "MIDDLE";
    sleep 2;
    _uavOperator playAction "Gear";
    _uavGroup addWaypoint [(getpos _uavOperator) getPos [25, getDir _uavOperator], 0];
    [_uavGroup, true] spawn pl_recon;

    sleep 3;
    [_uavGroup, "f_uav_pl"] call pl_change_group_icon;

    waitUntil {sleep 0.5; !(_group getVariable ["onTask", true]) or !alive _uav or !alive _uavOperator};


    [_group] spawn pl_reset;

    _laptop removeAction _actionId;
    _uavOperator playAction "";
    if !(alive _uav) then {
        deleteVehicle objectParent _uavBag;
        _uavOperator setVariable ["pl_is_uav_operator", false];
        sleep 1;
    } else {
        _uavOperator action ["TakeBag", _uavBag];
    };
    deleteVehicle _uav;
    deleteGroup _uavGroup;
    deleteVehicle _laptop;
    deleteVehicle _antenna;
};

pl_defense_jtac = {
    params ["_group", "_cords", "_defDir"];
    private ["_vic"];

    sleep 8;

    private _jtac = (leader _group);

    private _jtacWatchPos = _cords getpos [600, _defDir];

    private _jtacAreaMarker = createMarker [str (random 5), _jtacWatchPos];
    _jtacAreaMarker setMarkerShape "RECTANGLE";
    _jtacAreaMarker setMarkerBrush "Border";
    _jtacAreaMarker setMarkerColor pl_side_color;
    _jtacAreaMarker setMarkerSize [1500, 1000];
    _jtacAreaMarker setMarkerDir _defDir;


    private _trpMarker = createMarker [str (random 5), _jtacWatchPos]; 
    _trpMarker setMarkerType "mil_destroy";
    _trpMarker setMarkerColor pl_side_color;
    _trpMarker setMarkerText format ["TRP %1",(toupper (mapGridPosition _jtacWatchPos))];

    private _enyTanks = [];
    private _enyAFVs = [];
    private _enyCars = [];
    private _enyInf = [];

    private _target = objNull;
    private _targetPos = [];
    private _supportCalledIn = false;
    private _minCd = 0;

    while {_group getVariable ["onTask", false]} do {

        // waitUntil {sleep 1; pl_cas_active == 1 or !(_group getVariable ["onTask", false])};

        if (_supportCalledIn) then {
            _minCd = time + 60;
        } else {
            _minCd = time + 15;
        };
        waitUntil {sleep 1; (time >= (_group getVariable ["pl_jtac_timeout", 0]) and time >= _minCd) or !(_group getVariable ["onTask", false]) or (pl_cas_active == 1 and time >= _minCd)};
    
        if (!(_group getVariable ["onTask", false])) exitWith {};

        _targetGroups = allgroups select {(getpos (leader _x)) inArea _jtacAreaMarker and ([side _x, playerside] call BIS_fnc_sideIsEnemy) and ({(_jtac knowsAbout (vehicle _x)) > 0.2} count (units _x) > 0) and ({alive (vehicle _x)} count (units _x) > 0)};

        // systemChat (str _targetGroups);

        {
            if (vehicle (leader _x) != (leader _x)) then {
                _vic = vehicle (leader _x);

                switch (getText (configFile >> "CfgVehicles" >> typeOf _vic >> "textSingular")) do { 
                    case "tank" : {_enyTanks pushBack _vic}; 
                    case "APC" : {_enyAFVs pushBack _vic};
                    case "IFV" : {_enyAFVs pushBack _vic};
                    case "car" : {_enyCars pushBack _vic};
                    case "truck" : {_enyCars pushBack _vic};
                    case "Air" : {};
                    default {}; 
                };


            } else {
                _enyInf pushBack _x;
            }
        } forEach _targetGroups;


        // systemChat (str _enyInf);

        if (pl_cas_active == 1 and pl_sorties >= 2) then {

            if (_enyTanks isNotEqualTo []) then {

                _target = ([_enyTanks, [], {_x distance2D _cords}, "ASCEND"] call BIS_fnc_sortBy)#0;

                if (alive _target) then {

                    [_target, 2, _jtac] call pl_confirm_jtac_target_wait;

                    if (pl_confirm_cas) then {
                        _targetPos = (getPos _target) getPos [20, getDir _target];
                        [1, _targetPos, _jtac getDir _targetPos] spawn pl_interdiction_cas;
                        _supportCalledIn = true;
                    };
                };

            } else {
                if (_enyAFVs isNotEqualTo []) then {

                    _target = ([_enyAFVs, [], {_x distance2D _cords}, "ASCEND"] call BIS_fnc_sortBy)#0;

                    if (alive _target) then {

                        if (speed _target <= 3 and pl_arty_groups isNotEqualTo [] and time >= pl_jtac_arty_cd) then {

                            [_target, 3, _jtac, true] call pl_confirm_jtac_target_wait;

                            sleep 0.1;

                            if (pl_confirm_cas) then {
                                [getPos _target, [0, 3, 0, 1]] spawn pl_fire_on_map_arty;
                                _supportCalledIn = true;
                                pl_jtac_arty_cd = time + 70;
                            };

                        } else {

                            [_target, 2, _jtac] call pl_confirm_jtac_target_wait;

                            if (pl_confirm_cas) then {
                                _targetPos = (getPos _target) getPos [20, getDir _target];
                                [selectRandom [1, 2], _targetPos, _jtac getDir _targetPos] spawn pl_interdiction_cas;
                                _supportCalledIn = true;
                            };
                        };
                    };

                } else {
                    if (_enyCars isNotEqualTo []) then {

                        _target = ([_enyCars, [], {_x distance2D _cords}, "ASCEND"] call BIS_fnc_sortBy)#0;

                        if (alive _target) then {

                            if (speed _target <= 3 and pl_arty_groups isNotEqualTo [] and time >= pl_jtac_arty_cd) then {

                                [_target, 3, _jtac, true] call pl_confirm_jtac_target_wait;

                                if (pl_confirm_cas) then {
                                    [getPos _target, [0, 3, 0, 1]] spawn pl_fire_on_map_arty;
                                    _supportCalledIn = true;
                                    pl_jtac_arty_cd = time + 70;
                                };

                            } else {

                                [_target, 2, _jtac] call pl_confirm_jtac_target_wait;

                                if (pl_confirm_cas) then {
                                    _targetPos = (getPos _target) getPos [20, getDir _target];
                                    [selectRandom [1, 2], _targetPos, _jtac getDir _targetPos] spawn pl_interdiction_cas;
                                    _supportCalledIn = true;
                                };
                            };
                        };

                    } else {
                        if (pl_arty_groups isNotEqualTo [] and time >= pl_jtac_arty_cd) then {

                            if (_enyInf isNotEqualTo []) then {

                                _target = leader (([_enyInf, [], {{alive _x} count ((getPos (leader _x)) nearEntities ["Man", 100])}, "DESCEND"] call BIS_fnc_sortBy)#0);

                                [_target, 3, _jtac, true] call pl_confirm_jtac_target_wait;

                                if (pl_confirm_cas) then {
                                    [getPos _target, [50, 3, 5, 1]] spawn pl_fire_on_map_arty;
                                    _supportCalledIn = true;
                                    pl_jtac_arty_cd = time + 70;
                                };
                            };
                        };
                    };
                };
            };
        } else {
            if (pl_arty_groups isNotEqualTo [] and time >= pl_jtac_arty_cd) then {

                if (_enyInf isNotEqualTo []) then {

                    _target = leader (([_enyInf, [], {{alive _x} count ((getPos (leader _x)) nearEntities ["Man", 100])}, "DESCEND"] call BIS_fnc_sortBy)#0);

                    [_target, 4, _jtac, true] call pl_confirm_jtac_target_wait;

                    if (pl_confirm_cas) then {
                        [getPos _target, [50, 3, 5, 1]] spawn pl_fire_on_map_arty;
                        _supportCalledIn = true;
                        pl_jtac_arty_cd = time + 70;
                    };
                };
            };
        };

        private _timeAdd = 200 - 10 * (count _targetGroups);
        if (_timeAdd < 60) then {_timeAdd = 60};
        private _time = time + _timeAdd;
        _group setVariable ["pl_jtac_timeout", _time];
    };

    deleteMarker _jtacAreaMarker;
    deleteMarker _trpMarker;
    // pl_jtac_active = false;
};

pl_cas_req_ack = false;
pl_confirm_cas = false;
pl_cas_req_ack_num = 0;
pl_jtac_active = false;
pl_cas_auto_confirm = false;

pl_confirm_jtac_target_wait = {
    params ["_target", "_cost", "_jtac", ["_isArty", false]];

    private _targetType = getText (configFile >> "CfgVehicles" >> typeOf _target >> "displayName");


    private _cM = createMarker [str (random 5), getPos _target]; 
    _cM setMarkerType "mil_destroy";
    _cM setMarkerColor "colorRED";

    if !(_isArty) then {
        _cM setMarkerText format ["CAS Req. %1/%2", _cost, pl_sorties];
        if (pl_enable_chat_radio) then {leader (group _jtac) sideChat format ["%1: Requesting CAS at enemy %2", groupId (group _jtac), _targetType]};
        if (pl_enable_map_radio) then {[group _jtac, format ["...Requesting CAS at %1", _targetType], 20] call pl_map_radio_callout};
    } else {
        _cM setMarkerText format ["ARTY Req. %1 Rnds", _cost];
        if (pl_enable_chat_radio) then {leader (group _jtac) sideChat format ["%1: Requesting Artillery Strike", groupId (group _jtac), _targetType]};
        if (pl_enable_map_radio) then {[group _jtac, format ["...Requesting Artilley Strike", _targetType], 20] call pl_map_radio_callout};
    };

    if (pl_enable_beep_sound) then {playSound "radioina"};
    [group _jtac, "requestHelp", 0] call pl_voice_radio_answer;

    private _laser = createVehicle [[playerside] call pl_get_laser_target ,[0,0,0], [], 0, "CAN_COLLIDE"];
    _laser attachTo [_target,[0,0,0]];

    if !(pl_cas_auto_confirm) then {

        pl_cas_req_ack_num = 1;

        sleep 0.1;

        [] call pl_show_fire_support_menu;

        private _timeout = time + 20;

        waitUntil {sleep 0.5; pl_cas_req_ack or time >= _timeout};
    } else {
        pl_confirm_cas = true;
    };

    sleep 0.5;

    deleteMarker _cM;

    [_laser] spawn {
        params ["_laser"];

        sleep 80;

        deleteVehicle _laser;
    };

};


pl_confirm_jtac_target = {
    params ["_answer"];

    pl_cas_req_ack = true;
    pl_cas_req_ack_num = 0;

    pl_confirm_cas = _answer;

    sleep 3;

    pl_cas_req_ack = false;
    pl_confirm_cas = false;

};

pl_auto_confirm_jtac_target = {

    if !(pl_cas_auto_confirm) then {
        pl_cas_req_ack = true;
        pl_confirm_cas = true;
        pl_cas_auto_confirm = true;
        pl_cas_req_ack_num = 0;
    } else {
        pl_cas_req_ack = false;
        pl_confirm_cas = false;
        pl_cas_auto_confirm = false;
    };
};

pl_designate_jtac = {
    params [["_group", (hcSelected player) select 0]];

    if (_group getVariable ["pl_sop_is_jtac", false]) then {
        _group setVariable ["pl_sop_is_jtac", nil];
        pl_jtac_active = false;
    } else {
        if !(pl_jtac_active) then {
            _group setVariable ["pl_sop_is_jtac", true];
            pl_jtac_active = true;
        } else {
            hint "Only One Group can be JTAC at a time!";
        };
    };
};

