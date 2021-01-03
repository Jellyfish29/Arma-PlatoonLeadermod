

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
    "pl_opfor_info_share_enabled",
    "CHECKBOX",
    ["Enable Enemy Info sharing","Enable the sharing of information among enemy groups"],
    "Platoon Leader",
    true,
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
    "pl_enable_reinforcements",
    "CHECKBOX",
    ["Enable Reinforcements","enable or disable Reinforcements from Supply Points"],
    "Platoon Leader",
    true,
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_max_reinforcement_per_vic",
    "EDITBOX",
    ["Max Reinforcements","Max Reinforcements per Supply Vehicle"],
    "Platoon Leader",
    ["20"],
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
    "pl_cas_plane_1",
    "EDITBOX",
    ["CAS Plane 1","Define Classname for CAS Plane 1 (Gun, Attack, SAD)"],
    "Platoon Leader",
    ['B_Plane_CAS_01_F'],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_cas_plane_2",
    "EDITBOX",
    ["CAS Plane 2","Define Classname for CAS Plane 2 (JDAM)"],
    "Platoon Leader",
    ['B_Plane_Fighter_01_F'],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_cas_plane_3",
    "EDITBOX",
    ["CAS Plane 3","Define Classname for CAS Plane 3 (Cluster)"],
    "Platoon Leader",
    ['B_Plane_Fighter_01_Cluster_F'],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_cas_Heli_1",
    "EDITBOX",
    ["CAS Heli 1","Define Classname for CAS Heli 1 (SAD)"],
    "Platoon Leader",
    ['B_Heli_Attack_01_F'],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_medevac_Heli_1",
    "EDITBOX",
    ["MEDEVAC Heli","Define Classname for MEDEVAC Heli"],
    "Platoon Leader",
    ['B_Heli_Transport_01_F'],
    nil,
    {},
    true
] call CBA_fnc_addSetting;

[
    "pl_uav_1",
    "EDITBOX",
    ["UAV","Define Classname for UAV"],
    "Platoon Leader",
    ['B_UAV_02_dynamicLoadout_F'],
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



