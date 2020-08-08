
pl_rearm = {

    params ["_unit", "_target"];

    if !(isNull _target) then {
        if (_unit getVariable "pl_wia") exitWith {};
        createMarker ["sup_zone_marker", (getPos _target)];
        "sup_zone_marker" setMarkerType "b_support";
        "sup_zone_marker" setMarkerText "Supply Point";

        _unit disableAI "AUTOCOMBAT";
        _unit doMove (position _target);
        _unit moveTo (position _target);

        waitUntil {sleep 0.1; ((_unit distance2D  _target) < 8) or !((group _unit) getVariable ["onTask", true])};
        _unit action ["rearm",_target];
        0 = [_unit, "Rearming..."] remoteExecCall ["groupChat",[0,-2] select isDedicated,false];
        sleep 1;
        if ((secondaryWeapon _unit) != "") then {
            sleep 3;
            _unit action ["rearm",_target];
            0 = [_unit, "Rearming..."] remoteExecCall ["groupChat",[0,-2] select isDedicated,false];
        };

        _unit enableAI "AUTOCOMBAT";

        _time = time + 20;
        waitUntil {sleep 0.1; (time > _time) or !((group _unit) getVariable ["onTask", true])};
        deleteMarker "sup_zone_marker";
        (group _unit) setVariable ["setSpecial", false];
        (group _unit) setVariable ["onTask", true];
    };
};

pl_spawn_rearm = {
    private ["_box", "_magAmount"];
    {
        if (vehicle (leader _x) != leader _x) exitWith {hint "Infantry ONLY Task!"};
        if (visibleMap) then {
            _cords = (findDisplay 12 displayCtrl 51) ctrlMapScreenToWorld getMousePosition;
            _supplies = _cords nearSupplies 100;
            _magAmount = 0;

            if (count _supplies > 0) then {
                {
                    if !(_x isKindOf "Man") then {
                        _cargo = magazineCargo _x;
                        if (count _cargo > _magAmount) then {
                            _magAmount = count _cargo;
                            _box = _x;
                        };
                    };
                } forEach _supplies;

                [_x] call pl_reset;
                sleep 0.2;

                playSound "beep";

                _x setVariable ["setSpecial", true];
                _x setVariable ["onTask", true];
                _x setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\rearm_ca.paa"];    
            
                _boxName = getText (configFile >> "CfgVehicles" >> typeOf _box >> "displayName");
                playSound "beep";
                (leader _x) sideChat format ["%1: Resupplying at %2", (groupId _x), _boxName];

                {
                    [_x, _box] spawn pl_rearm; 
                } forEach units _x;
            }
            else
            {
                playSound "beep";
                leader _x sideChat "Negativ, There are no avaiable Supplies, Over";
            };
        }
        else
        {
            _supplies = cursorTarget nearSupplies 10;
            if (count _supplies > 0) then {
                _box = cursorTarget;
                if !(_box isKindOf "Man") then {

                    [_x] call pl_reset;
                    sleep 0.2;

                    _x setVariable ["setSpecial", true];
                    _x setVariable ["onTask", true];
                    _x setVariable ["specialIcon", "\A3\ui_f\data\igui\cfg\simpleTasks\types\rearm_ca.paa"];
                    _boxName = getText (configFile >> "CfgVehicles" >> typeOf _box >> "displayName");
                    playSound "beep";
                    (leader _x) sideChat format ["%1: Resupplying at %2", (groupId _x), _boxName];
                    {
                        [_x, _box] spawn pl_rearm; 
                    } forEach units _x;
                }
                else
                {
                    // playSound "beep";
                    hint "No avaiable Supplies!";
                };
            }
            else
            {
                // playSound "beep";
                hint "No avaiable Supplies!";
            };
        };

    } forEach hcSelected player;
};

// call pl_spawn_rearm;
