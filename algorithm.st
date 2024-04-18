PROGRAM Controller

    VAR
        temperatures : ARRAY [30, 40, 60, 95] OF INT;
        temperature_id : INT = 0;
        washing_started : BOOL;
    END_VAR

    VAR_INPUT
        temperature_button : BOOL;
        start_pause_button : BOOL;
        hatch_lock_switch : BOOL;
        pressostat : BOOL;
        tachometer : BOOL;
        thermistor : BOOL;
    END_VAR

	VAR_OUTPUT
        // =========== LEDs ===============
		washing_state_leds : ARRAY [0..4] OF BOOL; // Is the specified washing status LED on
		temperature_leds: ARRAY[0..3] OF BOOL;     // Is the specified temperature LED on
		error_led : BOOL := FALSE;				   // Is the error LED on	

        // =========== Actuators ===============
        drum_state: INT := 0;
        filling_valve_open: BOOL;
        hatch_lock_open: BOOL := TRUE;
        drain_pump_on: BOOL;
        heater_on: BOOL;
	END_VAR

    PROCESS Washing_machine

        STATE Wait

            IF temperature_button AND NOT washing_started THEN
                SET STATE Temperature_change;
            END_IF

            IF start_pause_button AND NOT washing_started THEN
                SET STATE Close_hatch_lock;
            END_IF

        END_STATE

        STATE Temperature_change
            temperature_leds[temperature_id] := FALSE;
            temperature_id := (temperature_id + 1) MOD 4;
            temperature_leds[temperature_id] := TRUE;
            SET STATE Wait;
        END_STATE

        STATE Close_hatch_lock
            hatch_lock_open := FALSE;
            SET STATE Start_washing;
        END_STATE

        STATE Start_washing
            washing_started := TRUE;
            SET STATE WAIT;
        END_STATE

    END_PROCESS

    PROCESS Temperature_control
    END_PROCESS

    PROCESS Washing_program
    END_PROCESS
	
END_PROGRAM