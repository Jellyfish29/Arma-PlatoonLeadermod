pl_support_cords = [0,0,0];
pl_mapClicked = false;
pl_cas_gun_cd = 0;
pl_cas_cluster_cd = 0;
pl_cas_jdam_cd = 0;
pl_arty_ammo = 32;
pl_cancel_strike = false;
pl_arty_rounds = 4;
pl_arty_dispersion = 75;
pl_arty_delay = 5;
pl_gun_enabled = 1;
pl_cluster_enabled = 1;
pl_jdam_enabled = 1;

pl_support_status = {
    _gunCd = "ON STATION";
    _gunColor = "#66ff33";
    _clusterCd = "ON STATION";
    _clusterColor = "#66ff33";
    _jdamCd = "ON STATION";
    _jdamColor = "#66ff33";
    _time = time + 8;
    while {time < _time} do {
        if (time < pl_cas_gun_cd) then {
            _gunCd = format ["%1s", round (pl_cas_gun_cd - time)];
            _gunColor = '#b20000';
        };
        if (time < pl_cas_cluster_cd) then {
            _clusterCd = format ["%1s", round (pl_cas_cluster_cd - time)];
            _clusterColor = '#b20000';
        };
        if (time < pl_cas_jdam_cd) then {
            _jdamCd = format ["%1s", round (pl_cas_jdam_cd - time)];
            _jdamColor = '#b20000';
        };
         _message = format ["
            <t color='#004c99' size='1.3' align='center' underline='1'>CAS</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Viper 1-1 (Attack Run)</t><t color='%1' size='0.8' align='right'>%2</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Black Knight 1-2 (Cluster)</t><t color='%3' size='0.8' align='right'>%4</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>Stroke 3 (JDAM)</t><t color='%5' size='0.8' align='right'>%6</t>
            <br /><br />
            <t color='#004c99' size='1.3' align='center' underline='1'>Artillery</t>
            <br /><br />
            <t color='#ffffff' size='0.8' align='left'>155m Battery</t><t color='#ffffff' size='0.8' align='right'>%7x</t>
        ",_gunColor, _gunCd, _clusterColor, _clusterCd, _jdamColor, _jdamCd,  pl_arty_ammo];

        hintSilent parseText _message;
        sleep 1;
    };
    hintSilent "";
};

pl_cas = {
    params ["_key"];
    private ["_cords", "_dir", "_support", "_type", "_plane", "_cs"];

    if (visibleMap) then {
        hintSilent "";
        hint "Select STRIKE location on MAP (SHIFT + LMB to cancel)";

        _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;

        onMapSingleClick {
            pl_support_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {sleep 0.1;};
        pl_mapClicked = false;
        if (pl_cancel_strike) exitWith {pl_cancel_strike = false};
        hint "Select APPROACH Vector for Strike (SHIFT + LMB to cancel)";

        sleep 0.1;
        _cords = pl_support_cords;
        _makerName = format ["cas%1", _key];
        createMarker [_makerName, _cords];
        _makerName setMarkerType "mil_arrow";
        _makerName setMarkerColor "colorBLUFOR";

        onMapSingleClick {
            pl_support_cords = _pos;
            pl_mapClicked = true;
            if (_shift) then {pl_cancel_strike = true};
            hintSilent "";
            onMapSingleClick "";
        };

        while {!pl_mapClicked} do {
            _dir = [_cords, ((findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition)] call BIS_fnc_dirTo;
            _makerName setMarkerDir _dir;
            sleep 0.05;
        };
        pl_mapClicked = false;

        if (pl_cancel_strike) exitWith {pl_cancel_strike = false; deleteMarker _makerName};

        switch (_key) do { 
            case 1 : {pl_gun_enabled = 0, _type = 2, _plane = 'B_Plane_CAS_01_F', _cs = 'Viper 1-1'};
            case 2 : {pl_cluster_enabled = 0,  _type = 3, _plane = 'B_Plane_Fighter_01_Cluster_F', _cs = 'Black Knight 1-2'}; 
            case 3 : {pl_jdam_enabled = 0,  _type = 3, _plane = 'B_Plane_Fighter_01_F', _cs = 'Stroke 3'};
            default {sleep 0.1}; 
        };
        sleep 1;
        _group = createGroup playerSide;
        _support = _group createUnit ["ModuleCAS_F", _cords, [],0 , ""];
        _support setVariable ["vehicle", _plane];
        _support setVariable ["type", _type];
        playSound "beep";
        [playerSide, "HQ"] sideChat "Copy that, Strike Aircraft on the Way, out";
        sleep 1;
        _support setDir _dir;
        sleep 5;
        _vicGroup = group (driver (_support getVariable "plane"));
        _vicGroup setGroupId [_cs];
        waitUntil {_support isEqualTo objNull};
        deleteMarker _makerName;
        sleep 8;
        switch (_key) do { 
            case 1 : {
            pl_cas_gun_cd = time + 240;
            playSound "beep";
            [playerSide, "HQ"] sideChat format ["%1 will be back on Station in 4 MINUTES, over", _cs];
            waitUntil {time >= pl_cas_gun_cd};
            pl_gun_enabled = 1;
         }; 
            case 2 : {
            pl_cas_cluster_cd = time + 480;
            playSound "beep";
            [playerSide, "HQ"] sideChat format ["%1 will be back on Station in 8 MINUTES, over", _cs];
            waitUntil {time >= pl_cas_cluster_cd};
            pl_cluster_enabled = 1;
        };
            case 3 : {
            pl_cas_jdam_cd = time + 720;
            playSound "beep";
            [playerSide, "HQ"] sideChat format ["%1 will be back on Station in 12 MINUTES, over", _cs];
            waitUntil {time >= pl_cas_jdam_cd};
            pl_jdam_enabled = 1;
        };
            default {pl_cas_cd = time + 240;}; 
        };
        playSound "beep";
        [playerSide, "HQ"] sideChat format ["%1, is back on Station, ready for tasking, over", _cs];
    }
    else
    {
        hint "Open Map to call CAS";
    };
};

pl_arty = {

    if (pl_arty_ammo < pl_arty_rounds) exitWith {
        playSound "beep";
        [playerSide, "HQ"] sideChat format ["Negativ, there isn´t enough ammunition left for requested Fire Mission"];
    };
    if (visibleMap) then {
        hint "Select STRIKE location on MAP";
        onMapSingleClick {
            pl_support_cords = _pos;
            pl_mapClicked = true;
            hint "";
            onMapSingleClick "";
        };
        while {!pl_mapClicked} do {sleep 0.5;};
        pl_mapClicked = false;
    }
    else
    {
        pl_support_cords = screenToWorld [0.5,0.5];
    };
    pl_arty_enabled = 0;
    
    createMarker ["pl_arty_area", pl_support_cords];
    "pl_arty_area" setMarkerColor "colorRed";
    "pl_arty_area" setMarkerShape "ELLIPSE";
    "pl_arty_area" setMarkerBrush "BDiagonal";
    "pl_arty_area" setMarkerAlpha 0.5;
    "pl_arty_area" setMarkerSize [pl_arty_dispersion, pl_arty_dispersion];
    createMarker ["pl_arty_center", pl_support_cords];
    "pl_arty_center" setMarkerType "mil_destroy";
    "pl_arty_center" setMarkerText format ["%1 R / %2 m / %3 s", pl_arty_rounds, pl_arty_dispersion, pl_arty_delay];

    pl_arty_ammo = pl_arty_ammo - pl_arty_rounds;
    playSound "beep";
    [playerSide, "HQ"] sideChat format ["Fire Mission Confirmend, ETA 20 Seconds"];
    sleep 18;
    playSound "beep";
    [playerSide, "HQ"] sideChat format ["Splash"];

    _artyGroup = createGroup east;

    for "_i" from 0 to (pl_arty_rounds - 1) do {
        _cords = [[[pl_support_cords, pl_arty_dispersion]],[]] call BIS_fnc_randomPos;
        _support = _artyGroup createUnit ["ModuleOrdnance_F", _cords, [],0 , ""];
        _support setVariable ["type", "ModuleOrdnanceHowitzer_F_Ammo"];
        sleep pl_arty_delay; 
    };

    sleep 5;

    deleteMarker "pl_arty_area";
    deleteMarker "pl_arty_center";
    sleep 30;
    pl_arty_enabled = 1;
    [playerSide, "HQ"] sideChat format ["Battery is ready for Fire Mission, over"];
};