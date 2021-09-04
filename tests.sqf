_animations = configFile >> "CfgVehicles" >> typeOf v1 >> "AnimationSources";
{
    player sideChat str _x;
} forEach _animations;