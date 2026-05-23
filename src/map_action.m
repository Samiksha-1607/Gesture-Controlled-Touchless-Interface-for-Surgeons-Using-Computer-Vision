function action = map_action(label)

    switch char(label)

        case '01_palm'
            action = 'Stop / Open';

        case '02_l'
            action = 'L Shape Command';

        case '03_fist'
            action = 'Close / Grab';

        case '04_fist_moved'
            action = 'Move Object';

        case '05_thumb'
            action = 'Thumbs Up';

        case '06_index'
            action = 'Select / Point';

        case '07_ok'
            action = 'OK Confirm';

        case '08_palm_moved'
            action = 'Swipe / Navigate';

        case '09_c'
            action = 'Capture / Copy';

        case '10_down'
            action = 'Scroll Down';

        otherwise
            action = 'Unknown Gesture';

    end

end