

[
    "pl_ai_skill",
    "SLIDER", 
    ["Player Side Ai Skill", "Ai Skill Level for Player Side"], "Platoon Leader", 
    [0, 1, 0.8, 2],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_radio_range", 
    "SLIDER", 
    ["Radio Range", 
    "Set the maximum range for ai info sharing"], "Platoon Leader", 
    [0, 2000, 700, 0], 
    nil,
    {},
    true
] call CBA_fnc_addSetting;

// [
//     "pl_support_enabled_setting",
//     "CHECKBOX", 
//     ["Enable All Support Options", "enable or disable Platoon Leader Fire Supports"], 
//     "Platoon Leader", 
//     true,
//     nil,
//     {},
//     true
// ] call CBA_fnc_addSetting;

[
    "pl_arty_enabled",
    "CHECKBOX",
    ["Enable Artillery","enable or disable Platoon Leader Artillery Supports"],
    "Platoon Leader",
    true,
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_cas_enabled",
    "CHECKBOX",
    ["Enable CAS","enable or disable Platoon Leader Close Air Support"],
    "Platoon Leader",
    true,
    nil,
    {},
    true
] call CBA_fnc_addSetting;

