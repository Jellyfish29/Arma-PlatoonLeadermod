sleep 1;

_time = time + 10;

waitUntil {time > _time};

// disable Pointless Tolltip
onGroupIconOverEnter {scriptname "HC: onGroupIconOverEnter";
    if !(hcshownbar) exitwith {};

    _is3D = _this select 0;
    _group = _this select 1;
    _wpID = _this select 2;
    _posx = _this select 3;
    _posy = _this select 4;
    _logic = player getvariable "BIS_HC_scope";

    if (_wpID < 0) then {
        _logic setvariable ["groupover",_group];
        _logic setvariable ["wpover",[grpnull]];
    } else {
        if (_group in hcallgroups player && !(_logic getvariable "LMB_hold")) then {
            _logic setvariable ["groupover",grpnull];
            _logic setvariable ["wpover",[_group,_wpID]];
        };
    };

};


// pl_hc_icon_changer = {
//     params ["_group"];
//     private ["_tester", "_unitText", "_unitSide", "_sideLetter", "_groupIcon"];

//     if (vehicle (leader _group) == leader _group) then {
//         _tester = leader _group;
//     }
//     else
//     {
//         _tester = vehicle (leader _group);
//     };

//     _unitText = getText (configFile >> "CfgVehicles" >> typeOf _tester >> "textSingular");
//     _vehicleClass = getText (configFile >> "CfgVehicles" >> typeOf _tester >> "VehicleClass");
//     _unitSide = side _tester;

//     if (_vehicleClass isEqualTo "Support") exitWith {};
//     if (_tester isKindOf "Air") exitWith {};

//     switch (_unitSide) do { 
//         case west : {_sideLetter = "b"}; 
//         case east : {_sideLetter = "o"};
//         default {_sideLetter = "n"}; 
//     };
//         // case guer : {_sideLetter = "n"}; 

//     switch (_unitText) do { 
//         case "specop" : {_groupIcon = format ["%1_recon", _sideLetter]}; 
//         case "APC" : {_groupIcon = format ["%1_mech_inf", _sideLetter]};
//         default {_groupIcon = format ["%1_inf", _sideLetter]}; 
//     };
//     _group setVariable ["MARTA_customIcon", [_groupIcon]]

// };
// {
//     [_x] call pl_hc_icon_changer;
// } forEach (allGroups select {side _x == playerSide});

pl_disable_create = {
    scriptName "HC\data\scripts\HC_local.sqf";


    textLogFormat ["Log: [High Command] Local script executed on %1",player];
    _logic = player getvariable "BIS_HC_scope";
    if (isnil "_logic") then {_logic = bis_hc_mainscope; player setvariable ["BIS_HC_scope",_logic,true]};
    _logicMARTA = BIS_Marta_mainscope;

    _groupicons = configfile >> "cfggroupicons";
    _groupiconnames = [];
    for "_i" from 0 to (count _groupicons - 1) do {
        _element = _groupicons select _i;
        if (isclass _element) then {
            _groupiconnames = _groupiconnames + [configname _element,gettext (_element >> "name")];
        };
    };



    //waituntil {player in (_logic getvariable "commanders")};
    //waituntil {count hcallgroups player > 0 || !isnil {player getvariable "hcdefaultcommander"}};
    waituntil {count hcallgroups player > 0};
    textLogFormat ["Log: [High Command] %1 is now commander",player];

    _logic setvariable ["commander",true];

    //-- Execute GUI control script
    [player] execvm ("hc\hc\data\scripts\HC_GUI.sqf");


    //--- Custom code when new enemy group is revealed
    _logicMARTA = BIS_Marta_mainscope;
    [_logicMARTA,"codein",[{
        _enemygroups = BIS_marta_mainscope getvariable "enemygroups";
        if (_this in _enemygroups) then {
            _grouptype = markertype (["MARKER",_this] call BIS_marta_getParams);
            ["enemy",_grouptype] execVM ("hc\HC\data\scripts\HC_sound.sqf");
        };
    }]] call BIS_fnc_variableSpaceAdd;




    //---------------------------------------------------------------------------------
    //--- Loop ------------------------------------------------------------------------
    //---------------------------------------------------------------------------------

    //--- Some new groups?
    _commandedGroups = [];
    _player = player;
    //while {player in (_logic getvariable "commanders")} do {
    _n = 0;
    while {count hcallgroups player > 0 && _player == player} do {

        scopename "loop";

        //--- Custom icon 
        _grp = group player;
        if (isnil {_grp getvariable "MARTA_customicon"}) then {
            _sideId = [east,west,resistance,civilian] find (side player);
            _type = ["o_hq","b_hq","n_hq","n_hq"] select _sideId;
            _grp setvariable ["MARTA_customicon",[_type],true];
        };


        // if (hcshownbar && (_n % 10) == 0) then {

        //  //--- Register 'Target' command menu
        //  _targets = bis_marta_mainscope getvariable "enemygroups";
        //  _targets = _targets - [objnull]; //--- EP1 - Remove null groups (just in case)
        //  _targetStrings = [];
        //  _targetNames = [];
        //  for "_i" from 0 to (count _targets - 1) do {
        //      _element = _targets select _i;
        //      if !(isnull _element) then {
        //          _targetStrings = _targetStrings + [str _element];

        //          _iconID = _element getvariable "BIS_MARTA_ICON_TYPE";
        //          _icon = (_element getgroupicon _iconID) select 0;
        //          _iconname = _groupiconnames select ((_groupiconnames find _icon)+1);
        //          _targetNames = _targetNames + [_iconname];
        //          //_targetNames = _targetNames + [format ["T%1",_i]];
        //      };
        //  };

        //  [
        //      localize "STR_WATCH_TARGET",        //--- Menu name
        //      "HC_Targets",               //--- Variable
        //      _targetNames,               //--- Items
        //      "",                 //--- Submenu
        //                          //--- Expression START
        //      "
        //          _groupString = %3 select %2;
        //          _group = grpnull;
        //          {
        //              if (_groupString == str _x) exitwith {_group = _x};
        //          } foreach allgroups;
        //          {[!visiblemap,_x,_group,false] spawn ((player getvariable 'BIS_HC_scope') getvariable 'GUI_WP_ATTACK')} foreach (hcselected player);
        
        //      ",                  //--- Expression END
        //      _targetStrings
        //  ] call bis_fnc_createmenu;
        // };



        //--- You and what army?
        _hcallgroups = hcallgroups player;
        _groupList = [];
        {if !(_x in _groupList) then {_groupList = _groupList + [_x]}} foreach (_commandedGroups + _hcallgroups);
        {
            _group = _x;

            //--- Add
            if (({alive _x} count units _group > 0) && !(_group in _commandedGroups)) then {    
                _commandedGroups = _commandedGroups + [_group];
                [_player,"MARTA_REVEAL",[_group],false,true] call BIS_fnc_variableSpaceAdd;
                _threatCount = 0;
                {_threatCount = _threatCount + (_x call bis_fnc_threat)} foreach units _group;
                _group setvariable ["BIS_HC_THREAT",count units _group];
            };

            //--- Remove
            if (({alive _x} count units _group == 0 || !(_group in _hcallgroups)) && (_group in _commandedGroups)) then {
                _commandedGroups = _commandedGroups - [_group];
                _group setvariable ["MARTA_waypoint",nil];
                [_player,"MARTA_REVEAL",[_group],false] call BIS_fnc_variableSpaceRemove;
                _player hcremovegroup _group;
            };

            sleep 0.001;

        } foreach _groupList;

        //sleep 0.001;
        _n = _n + 1;
        sleep 0.1;
    };


    //---------------------------------------------------------------------------------
    //--- No longer commander ---------------------------------------------------------
    //---------------------------------------------------------------------------------

    _logic setvariable ["commander",nil];

    //--- Remove 'selectable' markers
    _allgroups = allgroups;//_logicMARTA getvariable "allgroups";
    {
        _group = _x;
        _HCO = hcleader _group;
        _commandedGroups = _commandedGroups - [_group];
        //[_logicMARTA,"WPgroups",[_group],false] call BIS_fnc_variableSpaceRemove;
        if (!isnull _HCO && !isnil {_group getvariable "MARTA_REVEAL"}) then {[_HCO,"MARTA_REVEAL",[_group],false] call BIS_fnc_variableSpaceRemove};
    } foreach _allgroups;


    //--- Reset GUI
    {
        (uinamespace getvariable "_map") ctrlSetEventHandler [_x, ""];
    } foreach ["mousemoving","mouseholding","mousebuttondown","mousebuttonup","keydown","keyup"];

    //sleep 0.1;
    (uinamespace getvariable "_map") ctrlMapCursor ["Track","Track"];

    textLogFormat ["Log: [High Command] Local script terminated!"];

    //--- Restart
    [] execvm ("hc\HC\data\scripts\HC_local.sqf");
};


