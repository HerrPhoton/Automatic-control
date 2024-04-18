PROGRAM Controller

    VAR
        temperature : INT := 30;
        washing_started : BOOL;
    END_VAR

    VAR_INPUT
        (* BUTTONS *)
        start_pause_button : BOOL;
        temperature_button : BOOL;
        power_button : BOOL;

        (* SENSORS *)
        pressostat : BOOL;
        tachometer : BOOL;
        thermistor : BOOL;
    END_VAR

	VAR_OUTPUT
        (* Temperature LEDs *)
        temperature_led0 : BOOL;
        temperature_led1 : BOOL;
        temperature_led2 : BOOL;
        temperature_led3 : BOOL;

        (* Washing State LEDs *)
		washing_state_led0 : BOOL;   
        washing_state_led1 : BOOL;   
        washing_state_led2 : BOOL; 
        washing_state_led3 : BOOL;       
        washing_state_led4 : BOOL;                  
		error_led : BOOL;				                              	

        (* Actuators *)
        drum_state: INT;
        filling_valve_open: BOOL;
        hatch_lock_open: BOOL;
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

            CASE temperature OF
                30: temperature_led0 := FALSE;
                    temperature_led1 := TRUE;
                    temperature := 40;

                40: temperature_led1 := FALSE;
                    temperature_led2 := TRUE;
                    temperature := 60;

                60: temperature_led2 := FALSE;
                    temperature_led3 := TRUE;
                    temperature := 95;

                95: temperature_led2 := FALSE;
                    temperature_led0 := TRUE;
                    temperature := 30;

            END_CASE

            SET STATE Wait;
        END_STATE

        STATE Close_hatch_lock
            hatch_lock_open := FALSE;
            SET STATE Start_washing;
        END_STATE

        STATE Start_washing
            washing_started := TRUE;
            SET STATE Wait;
        END_STATE

    END_PROCESS
	
END_PROGRAM