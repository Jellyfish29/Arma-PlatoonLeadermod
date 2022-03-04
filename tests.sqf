pl_draw_delay_array = [];
pl_draw_delay_arrow = {
    findDisplay 12 displayCtrl 51 ctrlAddEventHandler ["Draw","
        _display = _this#0;
            {
                _pos1 = _x#0;
                _pos2 = _x#1;
                _display drawArrow [
                    _pos1,
                    _pos2,
                    pl_side_color_rgb
                ];

                _textPos = _pos1 getPos [(_pos1 distance2D _pos2) / 2, _pos1 getDir _pos2];
                _display drawIcon [
                    '#(rgb,4,1,1)color(1,1,1,0)',
                    pl_side_color_rgb,
                    _textPos,
                    6,
                    6,
                    0,
                    'D',
                    0,
                    0.03,
                    'EtelkaMonospacePro',
                    'center'
                ];
            } forEach pl_draw_delay_array;
    "]; // "  
};

[] call pl_draw_delay_arrow;