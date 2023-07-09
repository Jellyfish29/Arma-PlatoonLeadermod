pl_marked_mines = [];

pl_continous_mine_detection = {
    params ["_engGroup"];

    while {!(isnull _engGroup) and ({alive _x} count (units _engGroup)) > 0} do {


        _detectedMines = allMines select {(_x distance2D (vehicle (leader _engGroup))) < 40 and !(_x in pl_marked_mines)};


        {
            if ((random 1) > 0.75 or _x mineDetectedBy playerSide) then {
                playerSide revealMine _x;
                pl_marked_mines pushBack _x;
                _cm = createMarker [str (random 3), getPos _x];
                _cm setMarkerType "mil_triangle";
                _cm setMarkerSize [0.4, 0.4];
                _cm setMarkerDir -180;
                _cm setMarkerShadow false;
                _cm setMarkerColor "colorRED";
                pl_engineering_markers pushBack _cm;
            };
        } forEach _detectedMines;


        sleep 15;

    };
};

[g1] spawn pl_continous_mine_detection;