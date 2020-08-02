

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

[
    "pl_additional_ammoBearer",
    "EDITBOX",
    ["Additional Ammobearer classnames","Define unit classes that can be used as ammobearers: Format ['example_class_1', 'example_class_2']"],
    "Platoon Leader",
    ["[]"],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_enabled_medical",
    "CHECKBOX",
    ["Enable Medical System","enable or disable Medical System"],
    "Platoon Leader",
    true,
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_enable_vehicle_recovery",
    "CHECKBOX",
    ["Enable Vehicle Recovery","enable or disable Vehicle Recovery"],
    "Platoon Leader",
    true,
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_additional_engVic",
    "EDITBOX",
    ["Additional Repair Vehicles classnames","Define Vehicles that can repair/recover other Vehicles: Format ['example_class_1', 'example_class_2']"],
    "Platoon Leader",
    ["[]"],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

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
    "pl_arty_ammo",
    "EDITBOX",
    ["155mm Artillery Ammo","Set Amount of Rounds for 155mm Artillery Support"],
    "Platoon Leader",
    ["24"],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_cas_enabled",
    "CHECKBOX",
    ["Enable CAS","enable or disable Platoon Leader Close Air Support"],
    "Platoon Leader",
    [true],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_sorties",
    "EDITBOX",
    ["CAS Sortie Amount","Different CAS Strikes cost different amount of 'Sorties' select Amount"],
    "Platoon Leader",
    ["25"],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_enable_3d_icons",
    "CHECKBOX",
    ["Enable 3D Icons","Enable Extra 3D Icons when selecting or hovering over a group"],
    "Platoon Leader",
    [true],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

// [
//     "pl_permanent_3d_icons",
//     "CHECKBOX",
//     ["Enable Permanent 3D Icons","If off only shows 3D Icons when hovering over a Groupicon with the mouse"],
//     "Platoon Leader",
//     [true],
//     nil,
//     {},
//     true
// ] call CBA_fnc_addSetting;



