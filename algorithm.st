PROGRAM Controller
    VAR
        temperature : INT := 30;
        washing_started : BOOL;
        washing_state : INT := 0;
        error : BOOL;
    END_VAR

    VAR_INPUT
        (* BUTTONS *)
        start_button : BOOL;
        temperature_button : BOOL;
        power_button : BOOL;

        (* SENSORS *)
        hatch_lock_switch : BOOL;
        thermistor : INT;
        pressostat : BOOL;
        tachometer : BOOL;
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

    (* Starting processes *)
    PROCESS Init
        STATE begin
            START PROCESS Control_panel;
            START PROCESS Indication;
            START PROCESS Washing_process;
            START PROCESS Temperature_control;
            START PROCESS Filling_valve_control;
            START PROCESS Error_control;
            START PROCESS Drum_check;
            START PROCESS Heater_check;
            START PROCESS Drain_pump_check;
            START PROCESS Hatch_lock_check;
            START PROCESS Filling_valve_check;
            STOP;
        END_STATE
    END_PROCESS

    (* Control Panel processing *)
    PROCESS Control_panel
        VAR  
            prev_temp_btn_state : BOOL;
            prev_start_btn_state : BOOL;
        END_VAR

        STATE Init
            prev_temp_btn_state := temperature_button;
            prev_start_btn_state := start_button;
            hatch_lock_open := TRUE;
            SET NEXT;
        END_STATE

        STATE Wait
            (* Resetting the system when the power is turned off *)
            IF NOT power_button THEN
                washing_state := 0;
                temperature := 30;
                drum_state := 0;
                filling_valve_open := FALSE;
                washing_started := FALSE;
                hatch_lock_open := TRUE;
                drain_pump_on := FALSE;
                heater_on := FALSE;
                error := FALSE;

            (* Handling clicks when washing is not started *)
            ELSIF NOT washing_started THEN
                SET STATE Button_control;
            END_IF
        END_STATE

        STATE Button_control
            IF temperature_button AND NOT prev_temp_btn_state THEN  
               SET STATE Temperature_change;  

            ELSIF start_button AND NOT prev_start_btn_state THEN
               SET STATE Hatch_lock_control;

            ELSE
                SET STATE Wait;
            END_IF

            prev_start_btn_state := start_button;
            prev_temp_btn_state := temperature_button;
        END_STATE

        (* Changing the water temperature by pressing the button *)
        STATE Temperature_change
            CASE temperature OF
                30: temperature := 40;
                40: temperature := 60;
                60: temperature := 95;
                95: temperature := 30;
            END_CASE

            SET STATE Wait;
        END_STATE

        (* Closing the hatch lock device if the hatch is closed *)
        STATE Hatch_lock_control
            IF hatch_lock_switch THEN
                hatch_lock_open := FALSE;
                error := FALSE;
                SET STATE Start_washing;
            ELSE
                error := TRUE;
                SET STATE Wait;
            END_IF
        END_STATE

        (* Starting the washing process after closing the hatch lock device *)
        STATE Start_washing
            washing_started := TRUE;
            filling_valve_open := TRUE;
            washing_state := 1;
            SET STATE Wait;
        END_STATE
    END_PROCESS

    (* Control of the display on the control panel *)
    PROCESS Indication
        STATE Wait
            (* Turning off all LEDs when the power is turned off *)
            IF NOT power_button THEN
                temperature_led0 := FALSE;
                temperature_led1 := FALSE;
                temperature_led2 := FALSE;
                temperature_led3 := FALSE;

                washing_state_led0 := FALSE;
                washing_state_led1 := FALSE;
                washing_state_led2 := FALSE;
                washing_state_led3 := FALSE;
                washing_state_led4 := FALSE;

                error_led := FALSE;       
            ELSE    
                SET STATE Indicate;
            END_IF
        END_STATE

        (* Switching on the LEDs depending on the system status *)
        STATE Indicate
            CASE temperature OF
                30: temperature_led0 := TRUE;
                    temperature_led1 := FALSE;
                    temperature_led2 := FALSE;
                    temperature_led3 := FALSE;

                40: temperature_led0 := FALSE;
                    temperature_led1 := TRUE;
                    temperature_led2 := FALSE;
                    temperature_led3 := FALSE;

                60: temperature_led0 := FALSE;
                    temperature_led1 := FALSE;
                    temperature_led2 := TRUE;
                    temperature_led3 := FALSE;

                95: temperature_led0 := FALSE;
                    temperature_led1 := FALSE;
                    temperature_led2 := FALSE;
                    temperature_led3 := TRUE;
            END_CASE

            CASE washing_state OF
                0: washing_state_led0 := FALSE;
                   washing_state_led1 := FALSE;
                   washing_state_led2 := FALSE;
                   washing_state_led3 := FALSE;
                   washing_state_led4 := FALSE;

                1: washing_state_led0 := TRUE;
                   washing_state_led1 := FALSE;
                   washing_state_led2 := FALSE;
                   washing_state_led3 := FALSE;
                   washing_state_led4 := FALSE;

                2: washing_state_led0 := FALSE;
                   washing_state_led1 := TRUE;
                   washing_state_led2 := FALSE;
                   washing_state_led3 := FALSE;
                   washing_state_led4 := FALSE;

                3: washing_state_led0 := FALSE;
                   washing_state_led1 := FALSE;
                   washing_state_led2 := TRUE;
                   washing_state_led3 := FALSE;
                   washing_state_led4 := FALSE;

                4: washing_state_led0 := FALSE;
                   washing_state_led1 := FALSE;
                   washing_state_led2 := FALSE;
                   washing_state_led3 := TRUE;
                   washing_state_led4 := FALSE;

                5: washing_state_led0 := FALSE;
                   washing_state_led1 := FALSE;
                   washing_state_led2 := FALSE;
                   washing_state_led3 := FALSE;
                   washing_state_led4 := TRUE;
            END_CASE

            IF error THEN
                error_led := TRUE;
            ELSE
                error_led := FALSE;
            END_IF

            SET STATE Wait;
        END_STATE    
    END_PROCESS

    (* Washing program *)
    PROCESS Washing_process
        VAR  
            dir_changes_cnt : INT;
        END_VAR

        STATE Wait
            (* Switching between washing stages *)
            CASE washing_state OF
                1: SET STATE Supply;
                2: SET STATE Washing;
                3: SET STATE Release;
                4: SET STATE Water_extraction;
                5: SET STATE Finishing;
            END_CASE
        END_STATE

        STATE Supply
            (* Waiting for drum filling and water heating *)
            IF pressostat AND thermistor > temperature - 2 THEN
                washing_state := 2;
                drum_state := 1;
            END_IF

            SET STATE Wait;
        END_STATE

        STATE Washing
            IF NOT power_button OR error THEN
                RESET TIMER;
                SET STATE Wait;
            END_IF

            (* Rotation of the drum alternately in two directions *)
            TIMEOUT T#7s THEN
                IF drum_state = 2 THEN
                    drum_state := 1;
                    washing_state := 3;
                    drain_pump_on := TRUE;
                    SET STATE Wait;
                ELSE
                    drum_state := 2;
                    RESET TIMER;
                END_IF                
            END_TIMEOUT
        END_STATE

        STATE Release
            IF NOT power_button OR error THEN
                RESET TIMER;
                SET STATE Wait;
            END_IF

            TIMEOUT T#15s THEN
                washing_state := 4;
                SET STATE Wait;
            END_TIMEOUT
        END_STATE

        STATE Water_extraction
            IF dir_changes_cnt = 4 THEN
                washing_state := 5;
                drum_state := 0;
                drain_pump_on := FALSE;
                SET STATE Wait;   
            END_IF

            IF NOT power_button OR error THEN
                dir_changes_cnt := 0;
                RESET TIMER;
                SET STATE Wait; 
            END_IF

            (* Rotating the tank in different directions for 20 seconds *)
            TIMEOUT T#5s THEN
                dir_changes_cnt := dir_changes_cnt + 1;

                IF drum_state = 1 THEN
                    drum_state := 2;
                ELSE
                    drum_state := 1;
                END_IF

                RESET TIMER;
            END_TIMEOUT
        END_STATE

        STATE Finishing
            (* Waiting 2 seconds to finish washing *)
            TIMEOUT T#2s THEN
                hatch_lock_open := TRUE;
                washing_started := FALSE;
                washing_state := 0;

                SET STATE Wait;
            END_TIMEOUT

        END_STATE
    END_PROCESS

    PROCESS Temperature_control
        STATE Wait
            (* Turning on the heater only during the first two stages of washing *)
            IF washing_state = 1 OR washing_state = 2 THEN
                SET NEXT;
            ELSE
                heater_on := FALSE;
            END_IF
        END_STATE

        (* Turning on the heater depending on the current water temperature *)
        STATE Work
            IF thermistor < temperature THEN
                heater_on := TRUE;
            ELSE
                heater_on := FALSE;
            END_IF

            SET STATE Wait;
        END_STATE
    END_PROCESS

    (* Closing of the filling valve upon actuation of the pressostat *)
    PROCESS Filling_valve_control
        STATE Work LOOPED
            IF pressostat THEN
                filling_valve_open := FALSE;
            END_IF
        END_STATE
    END_PROCESS

    (* Tracking system errors *)
    PROCESS Error_control
        VAR  
            prev_error : BOOL;
        END_VAR

        STATE Wait
            IF error AND NOT prev_error THEN
                SET STATE Error;
            END_IF

            prev_error := error;
        END_STATE

        (* Stopping the entire system if there is an error *)
        STATE Error
            drum_state := 0;
            washing_state := 0;
            filling_valve_open := FALSE;
            washing_started := FALSE;
            drain_pump_on := FALSE;
            heater_on := FALSE;

            SET STATE Wait;
        END_STATE
    END_PROCESS

    (* Checking the hatch closure throughout the washing process *)
    PROCESS Hatch_lock_check
        STATE Check LOOPED
            IF NOT hatch_lock_switch AND washing_state > 0 THEN
                error := TRUE;
            END_IF
        END_STATE
    END_PROCESS

    (* Checking the drum's operability *)
    PROCESS Drum_check
        STATE Wait
            IF drum_state <> 0 THEN
                SET STATE Check;
            END_IF
        END_STATE

        STATE Check
            IF tachometer THEN
                SET STATE Wait;
            END_IF

            TIMEOUT T#1s THEN
                error := TRUE;
                SET STATE Wait;
            END_TIMEOUT   
        END_STATE  
    END_PROCESS

    (* Checking the water supply system *)
    PROCESS Filling_valve_check
        VAR  
            prev_filling_valve : BOOL;
        END_VAR

        STATE Wait
            IF filling_valve_open AND NOT prev_filling_valve THEN
                SET STATE Check;
            END_IF

            prev_filling_valve := filling_valve_open;
        END_STATE

        STATE Check
            IF pressostat OR NOT filling_valve_open THEN
                SET STATE Wait;
            END_IF

            TIMEOUT T#5s THEN
                error := TRUE;
                SET STATE Wait;
            END_TIMEOUT   
        END_STATE  
    END_PROCESS

    (* Checking the heater's operability *)
    PROCESS Heater_check
        VAR  
            prev_heater : BOOL;
            prev_temperature : INT; 
        END_VAR

        STATE Wait
            IF heater_on AND NOT prev_heater THEN
                SET STATE Check;
            END_IF

            prev_heater := heater_on;
        END_STATE

        STATE Check
            IF NOT heater_on THEN
                SET STATE Wait;
            END_IF

            TIMEOUT T#1s THEN
                IF thermistor - prev_temperature <= 0 THEN 
                    error := TRUE;
                END_IF

                SET STATE Wait;
            END_TIMEOUT       
        END_STATE  
    END_PROCESS

    (* Checking the operability of the drain pump *)
    PROCESS Drain_pump_check
        VAR  
            prev_drain_pump : BOOL;
        END_VAR

        STATE Wait
            IF drain_pump_on AND NOT prev_drain_pump THEN
                SET STATE Check;
            END_IF

            prev_drain_pump := drain_pump_on;
        END_STATE

        STATE Check
            IF NOT drain_pump_on THEN
                SET STATE Wait;
            END_IF

            TIMEOUT T#5s THEN
                IF pressostat THEN 
                    error := TRUE;
                END_IF

                SET STATE Wait;
            END_TIMEOUT  
        END_STATE  
    END_PROCESS
END_PROGRAM