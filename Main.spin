                                                                                                {{               
******************************************
* main                                   *
* Author: David Gitz                     *
* Copyright (c) 2012 David Gitz          *     
******************************************

TODO
- Test for proper operation of pass-through with new PWM Cables
- Ultrasonic Sensor Data Validation
- Watchdog on PWM Inputs
- 

'' DPG 31-DEC-2012
'' Added in heartbeat code.
'' DPG 24-AUG-2013
'' Started changeover of ICARUS error codes.  Initial work on setting up variables for Obstacle Avoidance.
'' DPG 25-AUG-2013
'' UART Troubleshooting, Mode/State Changes
'' DPG 29-AUG-2013
'' Found at least one of the UART issues is that the "pcFullDuplexSerial4FC" driver can't support 2 ports at 115200, but can do one at 115200 and one at 57600.  Added in FAST
'' MEDIUM, and SLOW loops to take care of UART receive errors.  Although FSM Mode changes are still buggy, motor passthru from measured pwm input from FC to pwm output on MC
'' appears to be working correctly with all 4 motors.
'' DPG 16-SEP-2013
'' Inserted CAM packet.  Need to put all UART read lines in the FAST Loop.
'' DPG 10-OCT-2013
'' Installed Motion Controller onto Flyer.  Configured as a pass-thru (mode:  MAV_MODE_MANUAL_ARMED).  Works ok, although sometimes a motor doesn't turn.  Troubleshooting doesn't
'' help, as the motor will move in other tests.  The only "fix" so far is to move the PWM output connector over 1 pin, check it, then put it back.
'' DPG 5-DEC-2013
'' Release: 0.1
'' Configured as a pass-through for Flight Controller to Motor Outputs
'' DPG 5-DEC-2013
'' Release: 0.2
'' Configured as a pass-through for Flight Controller to Motor Outputs
'' DPG 13-DEC-2013
'' Worked on implementing Obstacle Avoidance (Front,Left,Right,Back) as Forces (using Matlab).  Worked on documenting/cleaning up code.
'' DPG 20-JAN-2014
'' Worked on implementing an arm/disarm pin and a flight mode pin
'' DPG 21-JAN-2014
'' Added Sonar Trigger Pin for Maxbotix Sonar Daisy Chain: http://www.maxbotix.com/documents/LV_Chaining_Constantly_Looping_AN_Out.pdf
'' DPG 7-FEB-2014
'' Removed code for Sonar Board.  Removed all irrelevant code.  Calibrated Ultrasonic Sensors.
'' DPG 11-FEB-2014
'' First real testing of OA code (no propellers).  Motor movements may be wrong, but is executing each case (roll/pitch) correctly.  Unknown with Throttle(Altitude) as sensors
'' are not installed yet.
'' Release 0.3
'' DPG 12-FEB-2014
'' Release 0.4
'' DPG 21-APR-2014
'' Migrated to ICARUS_Jet code.  Removed everything with UART comm with APM, Sonar, Obstacle Avoidance.
}}
{{
INDICATOR LIGHTS
LED1: Blinks during MC startup, is off otherwise.
LED2: Blinks when in MANUAL-DISARMED, is ON when in MANUAL-ARMED, off otherwise.
LED3: Blinks when in TEST-DISARMED, is ON when in TEST-ARMED, off otherwise.
LED4: Blinks during an Error Condition, is OFF otherwise.
}}
CON

' Timing             
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000 
  
' ASCII Constants
  CR = 13
  LF = 10
  SPACE = 32
  PERIOD = 46
  COMMA =  44      
    
  ' Pin Names
  PINNOTUSED = -1                    

  ' UART Stuff
  usbtx = 30  'USB TX Line
  usbrx = 31  'USB RX Line

  pc_port = 0


  'Loop Rates
  FAST_LOOP = 1 '100 Hz, 10 mS
  MEDIUM_LOOP = 10 '10 Hz, 50 mS
  SLOW_LOOP = 100 '1 Hz, 200 mS

  PRIORITY_HIGH = 0
  PRIORITY_MEDIUM = 1
  PRIORITY_LOW = 2

' Led's

  Startup_LED = 17
  ManualMode_LED = 18
  TestMode_LED = 19
  Error_LED = 20

' Motor In Pin: Set to -1 if not used
  FrontMotorInPin = 10
  LeftMotorInPin = 11
  BackMotorInPin = 9
  RightMotorInPin = 12

' Motor Out Pin: Set to -1 if not used
  FrontMotorOutPin = 4
  LeftMotorOutPin = 3
  BackMotorOutPin = 5
  RightMotorOutPin = 2

  FrontMotorCh = 0
  LeftMotorCh = 1
  BackMotorCh = 2
  RightMotorCh = 3 

  'ADC Pins/Misc
  ADCuartPin = 21
  ADCclkPin = 22
  ADCcsPin = 23
  ADCmode = $00FF

  'Analog Sensors-Not Used, for reference only  
  AnalogSense1 = 0
  AnalogSense2 = 1
  AnalogSense3 = 2
  AnalogSense4 = 3
  AnalogSense5 = 4
  AnalogSense6 = 5
  AnalogSense7 = 6
  AnalogSense8 = 7

  FlightMode_Ch = AnalogSense7
  ArmDisarm_Ch = AnalogSense8

  'SONIC_THRESHOLD = 500   
  ADC_VOLTAGE_CONVERSION = 18
  ADC_CURRENT_CONVERSION = 1
  ADC_SONAR_CONVERSION = 8 'Convert ADC Measurement of Sonic Channel to Inches

  ADC_LOWER_THRESHOLD = 100  'Threshold for converting Analog Input to Boolean states.  Below this is FALSE.
  ADC_UPPER_THRESHOLD = 3900   'Threshold for converting Analog Input to Boolean states.  Above this is TRUE.
  'CurrentSense = 1
  'VoltageSense = 0

''MAVLink Constants
  
  'MAVlink Modes

  MAV_MODE_MANUAL = 0
  MAV_MODE_TEST = 1
  
  MAV_MODE_UNDEFINED = -1
  MAV_MODE_PREFLIGHT = 0 ' System is not ready to fly, booting, calibrating, etc. No flag is set.
  MAV_MODE_MANUAL_DISARMED = 64 ' System is allowed to be active, under manual (RC) control, no stabilization
  MAV_MODE_TEST_DISARMED = 66 ' UNDEFINED mode. This solely depends on the autopilot - use with caution, intended for developers only.
  MAV_MODE_STABILIZE_DISARMED = 80 ' System is allowed to be active, under assisted RC control.
  MAV_MODE_GUIDED_DISARMED = 88 ' System is allowed to be active, under autonomous control, manual setpoint
  MAV_MODE_AUTO_DISARMED = 92 ' System is allowed to be active, under autonomous control and
                       ' navigation (the trajectory is decided
                        ' onboard and not pre-programmed by MISSIONs)
  MAV_MODE_MANUAL_ARMED = 192 ' System is allowed to be active, under manual (RC) control, no
                        ' stabilization
  MAV_MODE_TEST_ARMED = 194 ' UNDEFINED mode. This solely depends on the autopilot - use with
                        ' caution, intended for developers only.
  MAV_MODE_STABILIZE_ARMED = 208 ' System is allowed to be active, under assisted RC control.
  MAV_MODE_GUIDED_ARMED = 216 ' System is allowed to be active, under autonomous control, manual
                        ' setpoint
  MAV_MODE_AUTO_ARMED = 220 ' System is allowed to be active, under autonomous control and
                        ' navigation (the trajectory is decided
                        ' onboard and not pre-programmed by MISSIONs)
  'MAVlink States
  MAV_STATE_UNINIT = 0 'Uninitialized system, state is unknown.
  MAV_STATE_BOOT = 1 'System is booting up.
  MAV_STATE_CALIBRATING = 2 'System is calibrating and not flight-ready.
  MAV_STATE_STANDBY = 3 'System is grounded and on standby. It can be launched any time.
  MAV_STATE_ACTIVE = 4 'System is active and might be already airborne. Motors are engaged.
  MAV_STATE_CRITICAL = 5 'System is in a non-normal flight mode. It can however still navigate.
  MAV_STATE_EMERGENCY = 6 'System is in a non-normal flight mode. It lost control over parts or
                        'over the whole airframe. It is in mayday and
                        ' going down.
  MAV_STATE_POWEROFF = 7 'System just initialized its power-down sequence, will shut down now. 

  'MAVlink Flight Modes
  MAV_CMD_NAV_WAYPOINT = 16
  MAV_CMD_NAV_LOITER_UNLIM = 17
  MAV_CMD_NAV_LOITER_TURNS = 18
  MAV_CMD_NAV_LOITER_TIME = 19
  MAV_CMD_NAV_RETURN_TO_LAUNCH = 20
  MAV_CMD_NAV_LAND = 21
  MAV_CMD_NAV_TAKEOFF = 22
  MAV_CMD_NAV_ROI = 80
  MAV_CMD_NAV_PATHPLANNING = 81
  MAV_CMD_NAV_LAST = 95
  MAV_CMD_CONDITION_DELAY = 112
  MAV_CMD_CONDITION_CHANGE_ALT = 113
  MAV_CMD_CONDITION_DISTANCE = 114
  MAV_CMD_CONDITION_YAW = 115
  MAV_CMD_CONDITION_LAST = 159
  MAV_CMD_NAV_CONTINUE = 1'Not MAVLINK Protocol.

OBJ
  uart:         "pcFullDuplexSerial4FC"
  pwmout:       "PWM_32_v4"
  pwmin:        "PWMin.spin"
  util:         "Util"
  math:         "DynamicMathLib"
  fstring:      "FloatString"
  adc:          "MCP3208"
  timer:        "Timer"
  sd:           "fsrw"
  str:          "STRINGS2"

VAR
  'Program Variables
  byte cogsused

  'Timing Variables
  long wait_mS
  long elapsedtime
  long slow_loop_count
  long medium_loop_count
  long fast_loop_count
  byte prioritylevel
  word ontime
  long armedtimer
  byte armedstart

  'UART Variables
  long stack[10]  
  byte rxbyte,rxinit  
  byte tempbyte
  byte tempstr1[50]
  byte  stringbuffer[100]

  'MAVLink Processing Variables
  byte mavlink_mode
  long mavlink_mode_armed
  long mavlink_state
  byte mavlink_arm_command
  byte mavlink_mode_command
  byte mavlink_flightmode  

  'Motor Variables
  long MotorInPWM[4] 'Front,Left,Back,Right
  long MotorOutPWM[4] 'Front,Left,Back,Right
  long MotorAdjustPWM[4] 'Front,Left,Back,Right

PUB init | i,sum, tempstr, temp1,fileerror
  waitcnt(5*clkfreq + cnt) ' Wait 1 seconds for board to power up
  i := 0
  wait_mS := clkfreq/1000 '1 mS   
  cogsused := 0
  slow_loop_count := medium_loop_count := fast_loop_count := 0
  mavlink_state := MAV_STATE_BOOT
  'mavlink_mode_armed := MAV_MODE_UNDEFINED
  mavlink_mode := MAV_MODE_MANUAL
  mavlink_flightmode := MAV_CMD_NAV_LAND 'By default the command is to land the UAV.  

  'mavlink_mode_armed := MAV_MODE_TEST_ARMED

  ''Make sure Motion Controller starts off in DISARMED mode
  if mavlink_mode == MAV_MODE_MANUAL
    mavlink_mode_armed :=  MAV_MODE_MANUAL_DISARMED
  elseif mavlink_mode == MAV_MODE_TEST
    mavlink_mode_armed := MAV_MODE_TEST_DISARMED
  else
    mavlink_mode_armed := MAV_MODE_MANUAL_DISARMED
  'mavlink_mode_armed := MAV_MODE_MANUAL_ARMED

  'bytemove(@stringbuffer,@@SYSTEM_MC,strlen(@@SYSTEM_MC))  

  'Set LED Pins as outputs if they should be.  We don't know if they are contiguous or not.
  DIRA[Startup_LED]~~
  DIRA[ManualMode_LED]~~
  DIRA[TestMode_LED]~~
  DIRA[Error_LED]~~
  OUTA[Startup_LED] := TRUE
  OUTA[ManualMode_LED] := FALSE
  OUTA[TestMode_LED] := FALSE
  OUTA[Error_LED] := FALSE



  'Set Motor Output Pins as Outputs
  if FrontMotorOutPin <> -1
    dira[FrontMotorOutPin]~~
  if LeftMotorOutPin <> -1
    dira[LeftMotorOutPin]~~
  if BackMotorOutPin <> -1
    dira[BackMotorOutPin]~~
  if RightMotorOutPin <> -1
    dira[RightMotorOutPin]~~

   'Initialize all Ports
  uart.init                    

  uart.AddPort(pc_port,usbrx,usbtx,uart#PINNOTUSED,uart#PINNOTUSED,uart#DEFAULTTHRESHOLD,uart#NOMODE,uart#BAUD115200)
  'uart.AddPort(pc_port, usbrx,usbtx, -1,-1, 0, %000000, uart#BAUD115200)
  'uart.AddPort(pc_port,comrx,comtx,-1,-1,0,-%000000,uart#BAUD115200)
                         
  'Transmit MAVLink State
   uart.str(pc_port,string("$STA,STATE,"))
   uart.dec(pc_port,mavlink_state)
   uart.str(pc_port,string("*",CR,LF))
  
  if (temp1 := uart.Start) 
      cogsused += 1 'Should be 1
      uart.rxflush(pc_port)
      uart.rxflush(pc_port)  

  if (temp1 := pwmout.start) 'servo.start
    cogsused += 1 'Should be 2
  else
    uart.str(pc_port,string("pwmout not started"))
    uart.dec(pc_port,temp1)
  
  if (temp1 := timer.start)
    timer.run
    cogsused += 1 'Should be 3
  else
    uart.str(pc_port,string("timer not started"))
    uart.dec(pc_port,temp1)

  {if (temp1 := ledpwm.start)
    cogsused += 1 'Should be 4
  else
    uart.str(pc_port,string("ledpwm not started"))
    uart.dec(pc_port,temp1)
    }

  'pwmin.Start(FrontMotorInPin)
  
  if (temp1 := pwmin.Start)
    cogsused := cogsused
    uart.str(pc_port,string("PWM measure okay!"))
  else
    uart.str(pc_port,string("PWM measure not started"))
    uart.dec(pc_port,temp1)
  repeat i from 0 to 3
    MotorInPWM[i] := -1
  
  'Start sensors

  if (temp1 := adc.start(ADCuartPin, ADCclkPin, ADCcsPin, ADCmode))
    cogsused += 1 'Should be 5
  else
    uart.str(pc_port,string("adc not started"))
    uart.dec(pc_port,temp1)
    

  uart.str(pc_port,string("Cog's Used:"))
  uart.dec(pc_port,cogsused)
  uart.str(pc_port,string(CR,LF))

    mavlink_state := MAV_STATE_CALIBRATING
  'Transmit MAVLink State
   uart.str(pc_port,string("$STA,STATE,"))
   uart.dec(pc_port,mavlink_state)
   uart.str(pc_port,string("*",CR,LF))
  
  if cogsused == 4 ' Check Initializing for Errors
    mavlink_state := MAV_STATE_STANDBY
    'Transmit MAVLink State
   uart.str(pc_port,string("$STA,STATE,"))
   uart.dec(pc_port,mavlink_state)
   uart.str(pc_port,string("*",CR,LF))
   OUTA[Startup_LED] := FALSE
   mainloop
  else
    
    repeat
      waitcnt(clkfreq/4 + cnt)
      !outa[Error_LED] 'Error on startup, couldn't initialize 
{OUTA[Startup_LED] := TRUE
  OUTA[ManualMode_LED] := FALSE
  OUTA[TestMode_LED] := FALSE
  OUTA[Error_LED] := FALSE
}      
PUB mainloop | i, j, value1, value2, value3,bootmode,ledmode,ledpin , tempstrA,tempstrB,tempstrC,storagecount,temp1, lasttime
''DPG 31-DEC-2012
'' Added basic ICARUS comm protocol stuff, heartbeat
''DPG 3-JAN-2013
'' Added in more ICARUS comm protocol stuff, Error Checking

  ontime := 0
  prioritylevel := -1
  fast_loop_count := medium_loop_count := slow_loop_count := 0
  lasttime := 0
  temp1 := 0
  armedstart := FALSE
  armedtimer := 0
  'bytefill(@sdtextbuffer,0,500)
  'bytemove(@sdtextbuffer,0,0)

  {repeat i from 0 to 7   ' Set all Servo PWM's to Neutral
    apm_servocmd[i] := 1500
    servo_min[i] := 1000
    servo_center[i] := 1500
    servo_max[i] := 2000
   } 

  bootmode := 0
  repeat i from 0 to 3
      MotorInPWM[i] := 0
  repeat' until strcomp(@rxbuffer,string("done"))
    waitcnt(1*wait_mS + cnt) ' Wait 100 mS
    ontime++
    if ontime > 1000
      ontime := 1
      fast_loop_count := medium_loop_count := slow_loop_count := 0
    if (ontime - fast_loop_count) > FAST_LOOP
      fast_loop_count := ontime 
      prioritylevel := PRIORITY_HIGH        
     
    elseif (ontime - medium_loop_count) > MEDIUM_LOOP
      medium_loop_count := ontime
      prioritylevel := PRIORITY_MEDIUM      
     
    elseif (ontime - slow_loop_count) > SLOW_LOOP
      slow_loop_count := ontime
      prioritylevel := PRIORITY_LOW 
    else
      prioritylevel := -1

   
    case prioritylevel
           
      PRIORITY_HIGH: 'Read Mode (Arm/Disarm) Commands
        'uart.dec(pc_port,1)  
        armedhandler(mavlink_mode)
        flightmodehandler
    
        
      PRIORITY_MEDIUM: 'Read Sensors        
        if FrontMotorInPin <> -1

          'MotorInPWM[FrontMotorCh] := pwmin.GetPWM(FrontMotorInPin)
          'MotorInPWM[LeftMotorCh] := pwmin.GetPWM(LeftMotorInPin)
          'MotorInPWM[BackMotorCh] := pwmin.GetPWM(BackMotorInPin)
          'MotorInPWM[RightMotorCh] := pwmin.getPWM(RightMotorInPin)
                                                                                
        
        
        'mavlink_mode_armed := MAV_MODE_MANUAL_ARMED  
        case mavlink_mode_armed ''Pass-Through Mode
          MAV_MODE_MANUAL_DISARMED:
               repeat i from 0 to 3
                    MotorOutPWM[i] := 1000
          MAV_MODE_TEST_DISARMED:
               repeat i from 0 to 3
                    MotorOutPWM[i] := 1000
          MAV_MODE_MANUAL_ARMED:
            repeat i from 0 to 3
              MotorOutPWM[i] := MotorInPWM[i]

        pwmout.Servo(FrontMotorOutPin,MotorOutPWM[FrontMotorCh])
        pwmout.Servo(LeftMotorOutPin,MotorOutPWM[LeftMotorCh])
        pwmout.Servo(BackMotorOutPin,MotorOutPWM[BackMotorCh])
        pwmout.Servo(RightMotorOutPin,MotorOutPWM[RightMotorCh])
      

      PRIORITY_LOW:  'Reply to PC and FC

        
        'Transmit Measured PWM Input Values
        'uart.txflush(pc_port)
        if FrontMotorInPin <> -1
          uart.str(pc_port,string("$PWMIN"))
          repeat i from 0 to 3
            uart.str(pc_port,string(","))
            uart.dec(pc_port,MotorInPWM[i])      
          uart.str(pc_port,string("*",CR,LF))
          uart.str(pc_port,string("$PWMOUT"))
          repeat i from 0 to 3
            uart.str(pc_port,string(","))
            uart.dec(pc_port,MotorOutPWM[i])
          uart.str(pc_port,string("*",CR,LF))

        case mavlink_mode_armed
          MAV_MODE_MANUAL_ARMED:
            OUTA[ManualMode_LED] := TRUE
            OUTA[TestMode_LED] := FALSE
            'uart.str(pc_port,string("MAV-MANUAL-ARMED",CR,LF))
            
          MAV_MODE_MANUAL_DISARMED:
            !OUTA[ManualMode_LED]
            OUTA[TestMode_LED] := FALSE
            'uart.str(pc_port,string("MAV-MANUAL-DISARMED",CR,LF))
          MAV_MODE_TEST_ARMED:
            OUTA[ManualMode_LED] := FALSE
            OUTA[TestMode_LED] := TRUE
           ' uart.str(pc_port,string("MAV-TEST-ARMED",CR,LF))
          MAV_MODE_TEST_DISARMED:
            OUTA[ManualMode_LED] := FALSE
            !OUTA[TestMode_LED]
           ' uart.str(pc_port,string("MAV-TEST-DISARMED",CR,LF))   
        'Make sure PWM Input is still valid
 {
  OUTA[ManualMode_LED] := FALSE
  OUTA[TestMode_LED] := FALSE
 }        

      'Data Logging
      OTHER:
        'uart.dec(pc_port,0)
pub flightmodehandler
'' DPG 20-JAN-2014
'' Sets Flight Mode, mainly used for Obstacle Avoidance routines
  
  if adc.in(FlightMode_Ch) > ADC_UPPER_THRESHOLD
    mavlink_flightmode := MAV_CMD_NAV_LAND
  elseif adc.in(FlightMode_Ch) < ADC_LOWER_THRESHOLD
    mavlink_flightmode := MAV_CMD_NAV_CONTINUE
pub armedhandler(mav_mode)
'' DPG 20-JAN-2014
'' Sets Armed/Disarmed mavlink mode based on Arming Pin and current mavlink mode.

  
  if  (adc.in(ArmDisarm_Ch) > ADC_UPPER_THRESHOLD)
    if armedstart == FALSE
      armedstart := TRUE
      armedtimer := 0
    else
      armedtimer++
  if (adc.in(ArmDisarm_Ch) < ADC_LOWER_THRESHOLD)
    armedstart := FALSE
    armedtimer := 0

  if armedtimer > 500   
    if mav_mode == MAV_MODE_MANUAL
      mavlink_mode_armed := MAV_MODE_MANUAL_ARMED
    elseif mav_mode == MAV_MODE_TEST
      mavlink_mode_armed := MAV_MODE_TEST_ARMED
    else
      mavlink_mode_armed := MAV_MODE_MANUAL_ARMED
  else
    if mav_mode == MAV_MODE_MANUAL
      mavlink_mode_armed := MAV_MODE_MANUAL_DISARMED
    elseif mav_mode == MAV_MODE_TEST
      mavlink_mode_armed := MAV_MODE_TEST_DISARMED
    else
      mavlink_mode_armed := MAV_MODE_MANUAL_DISARMED


PUB TestMotors | veryslowspeed,i
'' DPG 12-FEB-2014
'' Spins each motor one at a time
  veryslowspeed := 1150
  waitcnt(5*clkfreq + cnt)
  pwmout.Servo(FrontMotorOutPin,1000)
  pwmout.Servo(LeftMotorOutPin,1000)
  pwmout.Servo(BackMotorOutPin,1000)
  pwmout.Servo(RightMotorOutPin,1000)
  repeat i from 1 to 3
    waitcnt(3*clkfreq + cnt)
    !OUTA[Startup_LED]
    pwmout.Servo(FrontMotorOutPin,veryslowspeed)
    waitcnt(clkfreq + cnt)
    pwmout.Servo(FrontMotorOutPin,1000)
    waitcnt(clkfreq + cnt)

    !OUTA[Startup_LED]
    pwmout.Servo(LeftMotorOutPin,veryslowspeed)
    waitcnt(clkfreq + cnt)
    pwmout.Servo(LeftMotorOutPin,1000)
    waitcnt(clkfreq + cnt)

    !OUTA[Startup_LED]
    pwmout.Servo(BackMotorOutPin,veryslowspeed)
    waitcnt(clkfreq + cnt)
    pwmout.Servo(BackMotorOutPin,1000)
    waitcnt(clkfreq + cnt)

    !OUTA[Startup_LED]
    pwmout.Servo(RightMotorOutPin,veryslowspeed)
    waitcnt(clkfreq + cnt)
    pwmout.Servo(RightMotorOutPin,1000)
    waitcnt(clkfreq + cnt)

  pwmout.Servo(FrontMotorOutPin,1000)
  pwmout.Servo(LeftMotorOutPin,1000)
  pwmout.Servo(BackMotorOutPin,1000)
  pwmout.Servo(RightMotorOutPin,1000)