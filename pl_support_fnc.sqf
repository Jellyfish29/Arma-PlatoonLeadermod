sleep 1;

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
pl_sorties = parseNumber pl_sorties;
pl_arty_ammo = parseNumber pl_arty_ammo;
pl_cancel_strike = false;
pl_arty_rounds = 9;
pl_arty_dispersion = 200;
pl_arty_delay = 10;
pl_mortar_rounds = 4;
pl_arty_cords = [0,0,0];

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
        if (time < pl_cas_gun_cd) then {
            _gunCd = format ["%1s", round (pl_cas_gun_cd - time)];
            _gunColor = '#b20000';
        };
        if (time < pl_cas_gun_rocket_cd) then {
            _gunRocketCd = format ["%1s", round (pl_cas_gun_rocket_cd - time)];
            _gunRocketColor = '#b20000';
        };
        if (time < pl_cas_cluster_cd) then {
            _clusterCd = format ["%1s", round (pl_cas_cluster_cd - time)];
            _clusterColor = '#b20000';
        };
        if (time < pl_cas_jdam_cd) then {
            _jdamCd = format ["%1s", round (pl_cas_jdam_cd - time)];
            _jdamColor = '#b20000';
        };
        if (time < pl_plane_sad_cd) then {
            _sadPlaneCd = format ["%1s", round (pl_plane_sad_cd - time)];
            _sadPlaneColor = '#b20000';
        };
        if (time < pl_helo_sad_cd) then {
            _sadHeloCd = format ["%1s", round (pl_helo_sad_cd - time)];
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
         _message = format ["
            <t color='#004c99' size='1.3' align='center' underline='1'>CAS</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Sorties:</t><t color='%1' size='0.8' align='right'>%10</t>
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
            <t color='#004c99' size='1.3' align='center' underline='1'>Artillery</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>155m Battery</t><t color='#ffffff' size='0.8' align='right'>%9x</t>
        ", _gunColor, _gunCd, _gunRocketColor, _gunRocketCd, _clusterColor, _clusterCd, _jdamColor, _jdamCd,  pl_arty_ammo, pl_sorties, _sadPlaneColor, _sadPlaneCd, _sadHeloColor, _sadHeloCd, _sadUavColor, _sadUavCd, _sadMedevacColor, _sadMedevacCd];

        hintSilent parseText _message;
        sleep 1;
    };
    hintSilent "";
};

pl_cas = {
    params ["_key"];
    private ["_sortiesCost", "_cords", "_dir", "_support", "_casType", "_plane", "_cs", "_markerName"];

    switch (_key) do { 
        case 1 : {_sortiesCost = 1}; 
        case 2 : {_sortiesCost = 2};
        case 3 : {_sortiesCost = 4}; 
        case 4 : {_sortiesCost = 5}; 
        default {_sortiesCost = 1}; 
    };

    if (visibleMap) then {

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
            _dir = [_cords, ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)] call BIS_fnc_dirTo;
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
        case 1 : {pl_gun_enabled = 0, _casType = 0, _plane = pl_cas_plane_1, _cs = 'Viper 1'};
        case 2 : {pl_gun_rocket_enabled = 0, _casType = 2, _plane = pl_cas_plane_1, _cs = 'Viper 4'};
        case 3 : {pl_cluster_enabled = 0,  _casType = 3, _plane = pl_cas_plane_3, _cs = 'Black Knight 2'}; 
        case 4 : {pl_jdam_enabled = 0,  _casType = 3, _plane = pl_cas_plane_2, _cs = 'Stroke 3'};
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
    _vicGroup setGroupId [_cs];
    _vicGroup setVariable ["pl_not_addalbe", true];
    waitUntil {sleep 0.1; _support isEqualTo objNull};
    deleteMarker _markerName;
    sleep 8;
    switch (_key) do {
        case 1 : {
        pl_cas_gun_cd = time + 120;
        // if (pl_enable_beep_sound) then {playSound "beep"};
        // [playerSide, "HQ"] sideChat format ["%1 will be back on Station in 2 MINUTES, over", _cs];
        waitUntil {sleep 1; time > pl_cas_gun_cd};
        pl_gun_enabled = 1;
     }; 
        case 2 : {
        pl_cas_gun_rocket_cd = time + 240;
        // if (pl_enable_beep_sound) then {playSound "beep"};
        // [playerSide, "HQ"] sideChat format ["%1 will be back on Station in 4 MINUTES, over", _cs];
        waitUntil {sleep 1; time > pl_cas_gun_rocket_cd};
        pl_gun_rocket_enabled = 1;
     }; 
        case 3 : {
        pl_cas_cluster_cd = time + 480;
        // if (pl_enable_beep_sound) then {playSound "beep"};
        // [playerSide, "HQ"] sideChat format ["%1 will be back on Station in 8 MINUTES, over", _cs];
        waitUntil {sleep 1; time > pl_cas_cluster_cd};
        pl_cluster_enabled = 1;
    };
        case 4 : {
        pl_cas_jdam_cd = time + 720;
        // if (pl_enable_beep_sound) then {playSound "beep"};
        // [playerSide, "HQ"] sideChat format ["%1 will be back on Station in 12 MINUTES, over", _cs];
        waitUntil {sleep 1; time > pl_cas_jdam_cd};
        pl_jdam_enabled = 1;
    };
        default {pl_cas_cd = time + 240;}; 
    };
    if (pl_enable_beep_sound) then {playSound "beep"};
    [playerSide, "HQ"] sideChat format ["%1, is back on Station", _cs];
};

pl_arty = {
    private ["_salvos", "_markerName"];

    if (pl_arty_ammo < pl_arty_rounds) exitWith {
        // if (pl_enable_beep_sound) then {playSound "beep"};
        hint "Not enough ammunition left!";
    };
    if (visibleMap) then {

        _message = "Select STRIKE Location <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>";
        hint parseText _message;

        _markerName = createMarker ["pl_arty_marker", pl_arty_cords];
        _markerName setMarkerColor "colorRed";
        _markerName setMarkerShape "ELLIPSE";
        _markerName setMarkerBrush "BDiagonal";
        _markerName setMarkerAlpha 0.9;
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
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            _markerName setMarkerPos _mPos;
        };
        pl_mapClicked = false;
    }
    else
    {
        pl_arty_cords = screenToWorld [0.5,0.5];
    };
    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName};
    pl_arty_enabled = 0;
    
    _markerName setMarkerAlpha 0.4;
    createMarker ["pl_arty_center", pl_arty_cords];
    "pl_arty_center" setMarkerType "mil_destroy";
    "pl_arty_center" setMarkerText format ["%1 R / %2 m / %3 s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay];

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
    private ["_cords", "_ammoType", "_eh", "_markerName", "_centerMarkerName", "_eta", "_battery", "_guns", "_volleys"];

    if (visibleMap) then {

        _message = "Select STRIKE Location <br /><br />
        <t size='0.8' align='left'> -> SHIFT + LMB</t><t size='0.8' align='right'>CANCEL</t>";
        hint parseText _message;

        _markerName = createMarker [str (random 4), pl_arty_cords];
        _markerName setMarkerColor "colorRed";
        _markerName setMarkerShape "ELLIPSE";
        _markerName setMarkerBrush "BDiagonal";
        _markerName setMarkerAlpha 0.9;
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
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            _markerName setMarkerPos _mPos;
        };
        pl_mapClicked = false;
    }
    else
    {
        pl_arty_cords = screenToWorld [0.5,0.5];
    };

    _markerName setMarkerAlpha 0.4;
    _centerMarkerName = createMarker [str (random 4), pl_arty_cords];
    _centerMarkerName setMarkerType "mil_destroy";
    _centerMarkerName setMarkerText format ["%1 R / %2 m / %3 s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay];

    _cords = pl_arty_cords;
    _battery = pl_arty_groups#pl_active_arty_group_idx;
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

    [_eta, _centerMarkerName] spawn {
        params ["_eta", "_centerMarkerName"];
        _time = time +_eta;
        while {time < _time} do {
            _centerMarkerName setMarkerText format ["%1 R / %2 m / %3 s ETA: %4s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay, round (_time - time)];
            sleep 1;
        };
        _centerMarkerName setMarkerText "";
    };

    if (pl_enable_beep_sound) then {playSound "beep"};
    if (pl_enable_chat_radio) then {(gunner (_guns#0)) sideChat format ["...Fire Mission Confimed ETA: %1s", round _eta]};
    if (pl_enable_map_radio) then {[group (gunner (_guns#0)), format ["...Fire Mission Confimed ETA: %1s", round _eta], 25] call pl_map_radio_callout};

    _volleys = round (pl_arty_rounds / (count _guns));
    _dispersion = pl_arty_dispersion;
    _delay = pl_arty_delay;

    sleep 1;


    for "_i" from 1 to _volleys do {
        {
            switch (pl_arty_round_type) do { 
                case 1 : {_ammoType = (getArray (configFile >> "CfgVehicles" >> typeOf _x >> "Turrets" >> "MainTurret" >> "magazines")) select 0}; 
                case 2 : {_ammoType = ((getArray (configFile >> "CfgVehicles" >> typeOf _x >> "Turrets" >> "MainTurret" >> "magazines")) select {["smoke", _x] call BIS_fnc_inString})#0}; 
                case 3 : {_ammoType = ((getArray (configFile >> "CfgVehicles" >> typeOf _x >> "Turrets" >> "MainTurret" >> "magazines")) select {["illum", _x] call BIS_fnc_inString})#0};
                default {_ammoType = (getArray (configFile >> "CfgVehicles" >> typeOf _x >> "Turrets" >> "MainTurret" >> "magazines")) select 0}; 
            };
            if (isNil "_ammoType") exitWith {};

            _firePos = [[[_cords, _dispersion + 20]],[]] call BIS_fnc_randomPos;
            _x setVariable ["pl_waiting_for_fired", true];
            _x commandArtilleryFire [_firePos, _ammoType, 1];
            _eh = _x addEventHandler ["Fired", {
                params ["_unit", "_weapon", "_muzzle", "_mode", "_ammo", "_magazine", "_projectile", "_gunner"];
                _unit setVariable ["pl_waiting_for_fired", false];
            }];
            sleep 1;
        } forEach _guns;


        sleep 1;
        _MaxDelay = time + 40;
        _minDelay = time + _delay;
        waitUntil {({_x getVariable ["pl_waiting_for_fired", true]} count _guns == 0 and time >= _minDelay) or time >= _MaxDelay};
        sleep 2;
    };

    sleep 20;
    deleteMarker _markerName;
    deleteMarker _centerMarkerName;

    {
        _x addMagazineTurret [_ammoType, [-1]];
        _x removeEventHandler ["Fired", _eh];
    } forEach _guns;
};



pl_interdiction_cas = {
    params ["_casTypeSad"];
    private ["_height", "_cd", "_cdType", "_dir", "_spawnDistance", "_markerName", "_areaMarkerName", "_evacHeight", "_spawnPos", "_groupId", "_cords", "_sadWp", "_planeType", "_casGroup", "_plane", "_targets", "_sortiesCost", "_onStationTime", "_sadAreaSize", "_wpType", "_flyHeight", "_ccpGroup"];

    switch (_casTypeSad) do { 
        case 1 : {
            _height = 1500;
            _flyHeight = 200;
            _spawnDistance = 6000;
            _planeType = pl_cas_plane_1;
            // _planeType = "B_Plane_Fighter_01_F";
            _sortiesCost = 3;
            _groupId = "Reaper 1";
            _evacHeight = 2000;
            _cd = 300;
            _onStationTime = 110;
            _sadAreaSize = 1300;
            _wpType = "SAD";
        }; 
        case 2 : {
            _height = 100;
            _flyHeight = 100;
            _spawnDistance = 3000;
            _planeType = pl_cas_Heli_1;
            _sortiesCost = 7;
            _groupId = "Black Jack 4";
            _evacHeight = 200;
            _onStationTime = 90;
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
            _onStationTime = 240;
            _sadAreaSize = 700;
            _wpType = "LOITER";
        };
        case 4 : {
            _height = 100;
            _flyHeight = 80;
            _spawnDistance = 3000;
            _planeType = pl_medevac_Heli_1;
            _sortiesCost = 4;
            _groupId = "Angel 6";
            _evacHeight = 150;
            _onStationTime = 180;
            _sadAreaSize = 650;
            _wpType = "TR UNLOAD";
        };
        default {}; 
    };

    if (visibleMap) then {

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
            _mPos = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
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

    if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _markerName; deleteMarker _areaMarkerName};
        
    if (pl_enable_beep_sound) then {playSound "beep"};
    [playerSide, "HQ"] sideChat "Strike Aircraft on the Way!";

    pl_sorties = pl_sorties - _sortiesCost;

    switch (_casTypeSad) do { 
        case 1 : {pl_plane_sad_enabled = 0;}; 
        case 2 : {pl_helo_sad_enabled = 0;};
        case 3 : {pl_uav_sad_enabled = 0;};
        case 4 : {pl_medevac_sad_enabled = 0;}; 
        default {}; 
    };

    // sleep 15;

    _spawnPos = [_spawnDistance*(sin (_dir - 180)), _spawnDistance*(cos (_dir - 180)), 0] vectorAdd _cords;

    _casGroup = createGroup playerside;
    _casGroup setGroupId [_groupId];
    _casGroup setVariable ["pl_not_addalbe", true];
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
    // {
    //     _plane removeWeaponTurret [_x, [-1]];
    // } forEach ["Gatling_30mm_Plane_CAS_01_F", "Rocket_04_HE_Plane_CAS_01_F", "Rocket_04_AP_Plane_CAS_01_F"];
    // {
    //     _plane removeMagazinesTurret [_x, [-1]];
    // } forEach ["1000Rnd_Gatling_30mm_Plane_CAS_01_F", "7Rnd_Rocket_04_HE_F", "7Rnd_Rocket_04_AP_F"];

    {
        _x setSkill 1;
    } forEach crew (_plane);

    _sadWp = _casGroup addWaypoint [_cords, 0];
    _sadWp setWaypointType _wpType;

    _allVics = nearestObjects [_cords, ["Tank", "Car", "Truck"], _sadAreaSize, true];
    if (_casTypeSad == 3) then {
        _allVics = nearestObjects [_cords, ["Tank", "Car", "Truck", "Man"], _sadAreaSize, true];
    };
    sleep 3;
    _casGroup setBehaviour "COMBAT";

    // [_plane, _cords, _casGroup, _sadAreaSize] spawn {
    //     params ["_plane", "_cords", "_casGroup", "_sadAreaSize"];

    //     while {alive _plane} do {

    //         // hintSilent str (magazines _plane);

    //         _targets = (driver _plane) targetsQuery [objNull, sideUnknown, "", [], 0];
    //         {
    //             // hintSilent str _targets;
    //             if (((_x select 1) distance2D _cords) > _sadAreaSize) then {
    //                 _casGroup forgetTarget (_x#1);
    //             };
    //         } forEach _targets;
    //     };
    // };

    if (_casTypeSad != 4) then {
        waitUntil {(_plane distance2D _cords) < 3000};
    }
    else
    {
        "Land_HelipadEmpty_F" createVehicle _cords;
        sleep 3;
        waitUntil {(isTouchingGround _plane) or !alive _plane };
        if (alive _plane) then {
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
            sleep 5;
            [_ccpGroup, true, _gunner] spawn pl_ccp;
        };
    };

    {
        if ((side (driver _x)) != playerSide) then {
            (driver _plane) reveal [_x, 4];
            {
                (driver _plane) reveal [_x, 4];
            } forEach (crew _x);
        };
    } forEach _allVics;

    pl_test_plane = _plane;

    sleep 40;

    deleteMarker _markerName;
    _time = time + _onStationTime;
    waitUntil { time > _time };

    deleteMarker _areaMarkerName;

    switch (_casTypeSad) do { 
        case 1 : {
            pl_plane_sad_cd = time + 120;
            _cd = pl_plane_sad_cd;
        }; 
        case 2 : {
            pl_helo_sad_cd = time + 240;
            _cd = pl_helo_sad_cd;
        };
        case 3 : {
            pl_uav_sad_cd = time + 360;
            _cd = pl_uav_sad_cd;
        };
        case 4 : {
            pl_medevac_sad_cd = time + 400;
            _cd = pl_medevac_sad_cd;
        }; 
        default {}; 
    };

    if (alive _plane) then {
        // _targets = (driver _plane) targetsQuery [objNull, sideUnknown, "", [], 0];
        [_casGroup] call pl_reset;
        sleep 0.2;
        if (pl_enable_beep_sound) then {playSound "beep"};
        (driver _plane) sideChat format ["%1: RTB", _groupId];
        if (pl_enable_map_radio) then {[group (driver _plane), "...RTB!", 25] call pl_map_radio_callout};
        {
            _x disableAI "AUTOCOMBAT";
            _x disableAI "TARGET";
            _x disableAI "AUTOTARGET";
        } forEach (units _casGroup);

        if (_casTypeSad == 4) then {
            [_ccpGroup] call pl_reset;

            sleep 0.2;

            _ccpGroup setVariable ["MARTA_customIcon", nil];
            {
                _x assignAsCargo _plane;
                [_x] allowGetIn true;
                [_x] orderGetIn true;
                [_x] joinSilent _casGroup;
            } forEach (units _ccpGroup);

            _casGroup setGroupId [_groupId];

            sleep 2;
            _time = time + 40;
            waitUntil {({_x in _plane} count (units _casGroup)) == (count (units _casGroup)) or time >= _time};
            sleep 1;
        };

        _plane flyInHeight _evacHeight;
        _plane forceSpeed 300;
        _evacWp = _casGroup addWaypoint [_spawnPos, 0];
        _despawnTime = time + 90;
        while {(alive _plane) and ((_plane distance2D _spawnPos) > 100) and (time < _despawnTime)} do {
            _targets = (driver _plane) targetsQuery [objNull, sideUnknown, "", [], 0];
            {
                _casGroup forgetTarget (_x#1);
            } forEach _targets;
            sleep 0.1;
        };
        {
            _plane deleteVehicleCrew _x;
        } forEach (crew _plane);
        deleteVehicle _plane;
        deleteGroup _casGroup;
    };
    waitUntil {time > _cd};
    switch (_casTypeSad) do { 
        case 1 : {pl_plane_sad_enabled = 1}; 
        case 2 : {pl_helo_sad_enabled = 1};
        case 3 : {pl_uav_sad_enabled = 1};
        case 4 : {pl_medevac_sad_enabled = 1}; 
        default {}; 
    };
};