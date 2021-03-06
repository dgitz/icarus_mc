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
}}
{{
INDICATOR LIGHTS
LED1:Initialization State.  Should be ON during initialization and Off afterwards.
LED2:   Pass-Through Mode: All Motor Commands being sent to MC are sent directly 
        to the PDB.  Will be ON if this mode is running and OFF otherwise.
LED3:   Obstacle Avoidance Mode.  Will be ON if this mode is running and OFF otherwise.
LED4:   Operational Status.  Will Blink if Operational.  Will Stay ON if there is an Error.
}}   
con

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
  comtx = 8  'APM TX Line, FIX
  comrx = 7  'APM RX Line, FIX

  pc_port = 0
  fc_port = 2
  debug_port = 1

  'Loop Rates
  FAST_LOOP = 1 '100 Hz, 10 mS
  MEDIUM_LOOP = 10 '10 Hz, 50 mS
  SLOW_LOOP = 20 '5 Hz, 200 mS

  PRIORITY_HIGH = 0
  PRIORITY_MEDIUM = 1
  PRIORITY_LOW = 2

' Led's
  
  LedPin1 = 17
  LedPin2 = 18
  LedPin3 = 19
  LedPin4 = 20                   

' Servo's:  Set to -1 if not used
  ServoPin1 =  -1
  ServoPin2 =  -1
  ServoPin3 =  -1
  ServoPin4 =  -1
  ServoPin5 =  -1
  ServoPin6 =  -1
  ServoPin7 =  -1
  ServoPin8 =  -1

' Motor In Pin: Set to -1 if not used
  FrontMotorInPin = 12
  LeftMotorInPin = 11
  BackMotorInPin = 10
  RightMotorInPin = 9

' Motor Out Pin: Set to -1 if not used
  FrontMotorOutPin = 2
  LeftMotorOutPin = 3
  BackMotorOutPin = 4
  RightMotorOutPin = 5

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

  'Sonic Channels/Misc
  SonicChannel1 = 0'Top Sensor 
  SonicChannel2 = 1'Bottom Sensor
  SonicChannel3 = 2'Left Sensor
  SonicChannel4 = 3'Right Sensor
  SonicChannel5 = 4'Front Sensor
  SonicChannel6 = 5'Back Sensor
  SonicTriggerPin = 6

  FlightMode_Ch = AnalogSense7
  ArmDisarm_Ch = AnalogSense8

  'SONIC_THRESHOLD = 500   
  ADC_VOLTAGE_CONVERSION = 18
  ADC_CURRENT_CONVERSION = 64
  ADC_SONAR_CONVERSION = 9 'Convert ADC Measurement of Sonic Channel to Inches

  ADC_LOWER_THRESHOLD = 100  'Threshold for converting Analog Input to Boolean states.  Below this is FALSE.
  ADC_UPPER_THRESHOLD = 3800   'Threshold for converting Analog Input to Boolean states.  Above this is TRUE.
  'CurrentSense = 1
  'VoltageSense = 0

 

  'SD Card Pins
  SDCS  = 27     
  SDDI  = 26                             
  SDCLK = 25                                   
  SDDO  = 24

  'Control Modes, Obsolete
  CON_TAKEOFFVTOL = 1
  CON_HOVER = 2
  CON_LANDVTOL = 3
  CON_CRUISE = 4
  CON_MANUAL = 5
  CON_BOOT1 = 6
  CON_BOOT2 = 7
  CON_BOOT3 = 8
  CON_RESET = 9
  CON_OFF = 10
  CON_HOVERtoCRUISE = 11
  CON_CRUISEtoHOVER = 12
  
  CON_mavlink_mode_armed = 13

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
' CLI MODE CONSTANTS
{  DEBUG_SERVO = 1
  DEBUG_SONIC = 2
  DEBUG_ANALOG = 3
  DEBUG_ALLIO = 4   
}  


obj
  uart:         "pcFullDuplexSerial4FC"
  'uart:        "FullDuplexSerial4port"
  'dio:           "dataIO4port"
  'ledpwm:       "PWM_32_v4"
  pwmout:     "PWM_32_v4"
  pwmin:        "PWMin.spin"
  'uart2:        "FullDuplexSerial"
  'servopwm:        "Servo32v7" 
  util:         "Util"
  math:         "DynamicMathLib"
  fstring:      "FloatString"
  adc:          "MCP3208"
  timer:        "Timer"
  sd:        "fsrw"
  str:        "STRINGS2"

var

  'Communication Variables
  byte fcrxbuffer[50]
  byte pcrxbuffer[100] 
  byte infopacket[50]
  
  'Timing Variables
  long wait_mS
  long elapsedtime
  byte curtimestamp[4] 'Time Stamp in the form of the following:  [Hours][Minutes][Seconds][MilliSeconds]
  byte hour,minute,sec,msec
  long slow_loop_count
  long medium_loop_count
  long fast_loop_count
  byte prioritylevel
  word ontime
   
  'Servo Variables 
  'long apm_servocmd[8]  'APM Servo Commands for each Servo Channel
  'long servo_min[8] 'Minimum Pulse for each Servo Channel
  'long servo_center[8] 'Center Pulse for each Servo Channel
  'long servo_max[8] 'Max Pulse for each Servo Channel
  'long servo_0Deg[8] 'Pulse for 0 Degree Rotation (Horizontal)
  'long servo_90deg[8] 'Pulse for 90 Degree Rotation (Vertical)
   
  'UART Variables
  long stack[10]  
  byte rxbyte,rxinit, cogsused  
  byte tempbyte
  byte tempstr1[50]
  byte  stringbuffer[100]
   
  'MAVLink Processing Variables
  long heartbeatnumber
  long lastheartbeatnumber
  byte missedheartbeatcounter
  long droppedpacketcounter
  byte mavlink_mode
  long mavlink_mode_armed
  long mavlink_state
  byte controlmode
  byte mavlink_arm_command
  byte mavlink_mode_command
  byte mavlink_flightmode
  
  'Error Handling Variables 
  long rcvderrorcode 
  byte curerrorcode[15]
  byte curerrorcodeindex    

  'Sonic Sensor Variables
  long sonicdist[6]
  long lastsonicdist[6]
  long frontdist,leftdist,backdist,rightdist,topdist,bottomdist

  'Camera Distance Variables
  long camdist[9]
  
  'Other Sensor Variables
  long batvoltage
  long batcurrent

  'SD Card Variables
  byte SDinsert_card
  byte LOG_EVERYTHING
  byte sdtextbuffer[500]
  long fdsDatPtr
  
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
  missedheartbeatcounter := 0
  heartbeatnumber := 0
  lastheartbeatnumber := 0
  curerrorcodeindex := 1
  droppedpacketcounter := 0
  controlmode := CON_mavlink_mode_armed
  mavlink_state := MAV_STATE_BOOT
  'mavlink_mode_armed := MAV_MODE_UNDEFINED
  mavlink_mode := MAV_MODE_MANUAL
  mavlink_flightmode := MAV_CMD_NAV_LAND 'By default the command is to land the UAV.  This way when the vehicle is ARMED it doesn't shoot straight up due to the Obstacle Avoidance on the Bottom Sonar.

  'mavlink_mode_armed := MAV_MODE_TEST_ARMED

  ''Make sure Motion Controller starts off in DISARMED mode
  if mavlink_mode == MAV_MODE_MANUAL
    mavlink_mode_armed :=  MAV_MODE_MANUAL_DISARMED
  elseif mavlink_mode == MAV_MODE_TEST
    mavlink_mode_armed := MAV_MODE_TEST_DISARMED
  else
    mavlink_mode_armed := MAV_MODE_MANUAL_DISARMED
  'mavlink_mode_armed := MAV_MODE_MANUAL_ARMED
  LOG_EVERYTHING := FALSE

  'curerrorcode := 12001 ' Initializing
  bytefill(@curerrorcode,0,15)
  str.Concatenate(@curerrorcode,@SYSTEM_FLYER_MC)
  str.Concatenate(@curerrorcode,string("-"))
  str.Concatenate(@curerrorcode,@ERRORTYPE_NOERROR)
  str.Concatenate(@curerrorcode,string("-"))
  str.Concatenate(@curerrorcode,@SEVERITY_CAUTION)
  str.Concatenate(@curerrorcode,string("-"))
  str.Concatenate(@curerrorcode,@MESSAGE_INITIALIZING)
  'bytemove(@stringbuffer,@@SYSTEM_MC,strlen(@@SYSTEM_MC))  

  'Set LED Pins as outputs if they should be.  We don't know if they are contiguous or not.
  if ledpin1 <> -1
    dira[ledpin1]~~
    outa[ledpin1] := 1 'Start Booting Up
  if ledpin2 <> -1
    dira[ledpin2]~~
  if ledpin3 <> -1
    dira[ledpin3]~~
  if ledpin4 <> -1
    dira[ledpin4]~~
     
  'Set Servo Pins as outputs if they should be.  We don't know if they are contiguous or not.
  if ServoPin1 <> -1
    dira[ServoPin1]~~
  if ServoPin2 <> -1
    dira[ServoPin2]~~
  if ServoPin3 <> -1
    dira[ServoPin3]~~
  if ServoPin4 <> -1
    dira[ServoPin4]~~
  if ServoPin5 <> -1
    dira[ServoPin1]~~
  if ServoPin6 <> -1
    dira[ServoPin2]~~    
  if ServoPin7 <> -1
    dira[ServoPin3]~~
  if ServoPin8 <> -1
    dira[ServoPin4]~~

  'Set Motor Output Pins as Outputs
  if FrontMotorOutPin <> -1
    dira[FrontMotorOutPin]~~
  if LeftMotorOutPin <> -1
    dira[LeftMotorOutPin]~~
  if BackMotorOutPin <> -1
    dira[BackMotorOutPin]~~
  if RightMotorOutPin <> -1           
    dira[RightMotorOutPin]~~

  'Start Sonar Daisy Chain
  waitcnt(clkfreq + cnt)
  dira[SonicTriggerPin]~~
  outa[SonicTriggerPin] := FALSE
  outa[SonicTriggerPin] := TRUE
  waitcnt(clkfreq/10 + cnt)
  outa[SonicTriggerPin] := FALSE
  dira[SonicTriggerPin]~ 
 
  'Initialize all Ports
  uart.init                    
  uart.AddPort(debug_port,usbrx,usbtx,uart#PINNOTUSED,uart#PINNOTUSED,uart#DEFAULTTHRESHOLD,uart#NOMODE,uart#BAUD115200)
  uart.AddPort(pc_port,comrx,comtx,uart#PINNOTUSED,uart#PINNOTUSED,uart#DEFAULTTHRESHOLD,uart#NOMODE,uart#BAUD57600)
  'uart.AddPort(debug_port, usbrx,usbtx, -1,-1, 0, %000000, uart#BAUD115200)
  'uart.AddPort(pc_port,comrx,comtx,-1,-1,0,-%000000,uart#BAUD115200)
                         
  'Transmit MAVLink State
   uart.str(pc_port,string("$STA,STATE,"))
   uart.dec(pc_port,mavlink_state)
   uart.str(pc_port,string("*",CR,LF))
  
  if (temp1 := uart.Start) 
      cogsused += 1 'Should be 1
      uart.rxflush(pc_port)
      uart.rxflush(debug_port)  

  if (temp1 := pwmout.start) 'servo.start
    cogsused += 1 'Should be 2
  else
    uart.str(debug_port,string("pwmout not started"))
    uart.dec(debug_port,temp1)
  
  if (temp1 := timer.start)
    timer.run
    cogsused += 1 'Should be 3
  else
    uart.str(debug_port,string("timer not started"))
    uart.dec(debug_port,temp1)

  {if (temp1 := ledpwm.start)
    cogsused += 1 'Should be 4
  else
    uart.str(debug_port,string("ledpwm not started"))
    uart.dec(debug_port,temp1)
    }

  'pwmin.Start(FrontMotorInPin)
  
  if (temp1 := pwmin.Start)
    cogsused := cogsused
    uart.str(debug_port,string("PWM measure okay!"))
  else
    uart.str(debug_port,string("PWM measure not started"))
    uart.dec(debug_port,temp1)
    bytefill(@curerrorcode,0,15)
    str.Concatenate(@curerrorcode,@SYSTEM_FLYER_MC)
    str.Concatenate(@curerrorcode,string("-"))
    str.Concatenate(@curerrorcode,@ERRORTYPE_ACTUATORS)
    str.Concatenate(@curerrorcode,string("-"))
    str.Concatenate(@curerrorcode,@SEVERITY_EMERGENCY)
    str.Concatenate(@curerrorcode,string("-"))
    str.Concatenate(@curerrorcode,@MESSAGE_DEVICENOTPRESORAVAIL)
    uart.str(pc_port,@curerrorcode)
    uart.str(debug_port,@curerrorcode)
  
  repeat i from 0 to 3
    MotorInPWM[i] := -1
  
  'Start sensors

  if (temp1 := adc.start(ADCuartPin, ADCclkPin, ADCcsPin, ADCmode))
    cogsused += 1 'Should be 5
  else
    uart.str(debug_port,string("adc not started"))
    uart.dec(debug_port,temp1)
    
  'Mount SD Card
  if LOG_EVERYTHING
    if (SDinsert_card := \sd.mount_explicit(SDDO, SDCLK, SDDI, SDCS)) <0
       'curerrorcode[curerrorcodeindex++] := 12361
    else
      sd.popen(string("Log_File.txt"),"w") 
                           

  uart.str(debug_port,string("Cog's Used:"))
  uart.dec(debug_port,cogsused)
  uart.str(debug_port,string(CR,LF))

    mavlink_state := MAV_STATE_CALIBRATING
  'Transmit MAVLink State
   uart.str(pc_port,string("$STA,STATE,"))
   uart.dec(pc_port,mavlink_state)
   uart.str(pc_port,string("*",CR,LF))
  
  if cogsused == 4 ' Check Initializing for Errors
    outa[ledpin1] := 0 'Finished initializing everything 
    mavlink_state := MAV_STATE_STANDBY
    'Transmit MAVLink State
   uart.str(pc_port,string("$STA,STATE,"))
   uart.dec(pc_port,mavlink_state)
   uart.str(pc_port,string("*",CR,LF))
   mainloop
  else
    outa[ledpin1] := 1 'Error on startup, couldn't initialize
    bytefill(@curerrorcode,0,15)
    str.Concatenate(@curerrorcode,@SYSTEM_FLYER_MC)
    str.Concatenate(@curerrorcode,string("-"))
    str.Concatenate(@curerrorcode,@ERRORTYPE_GENERALERROR)
    str.Concatenate(@curerrorcode,string("-"))
    str.Concatenate(@curerrorcode,@SEVERITY_EMERGENCY)
    str.Concatenate(@curerrorcode,string("-"))
    str.Concatenate(@curerrorcode,@MESSAGE_INITIALIZINGERROR)
    repeat
      uart.str(debug_port,@curerrorcode)
      waitcnt(clkfreq/4 + cnt)
      
    'curerrorcode[curerrorcodeindex++] := 12599 ' Initializing Error
  'mainloop
  'testadc
  'testboot
  
  'testadc

  {repeat until (rxbyte := uart.rxcheck(comport) == "s")
   waitcnt( waitdelay + cnt)
   datapacketmode}

{PUB testmotorinput2
    repeat
      SonarPWM := Sonar.GetPWM
      waitcnt(clkfreq/100 + cnt) 
      'Now do something with the distance
      uart.Str(debug_port,String("Distance of:"))
      uart.dec(debug_port,SonarPWM)
      uart.Str(debug_port,String(" inches",13))  }
{PUB testmotorinput | i
  'long MotorInPWM[4] 'Front,Left,Back,Right
  'long MotorOutPWM[4] 'Front,Left,Back,Right
  'FrontMotorInPin
  
  repeat
    waitcnt(clkfreq/100 + cnt)
    MotorInPWM[0] := pwmin.GetPWM(FrontMotorInPin)
    MotorInPWM[1] := pwmin.GetPWM(LeftMotorInPin)
    MotorInPWM[2] := pwmin.GetPWM(BackMotorInPin)
    MotorInPWM[3] := pwmin.getPWM(RightMotorInPin)
    uart.str(debug_port,string("PWM: "))
    repeat i from 0 to 3
      uart.dec(debug_port,MotorInPWM[i])
      uart.str(debug_port,string(","))
    uart.str(debug_port,string(CR,LF)) }     
{PUB testboot
'' DPG 23-AUG-2013
'' Created to test error codes
  repeat
    uart.str(pc_port,@curerrorcode)
    uart.str(pc_port,string("$STA,STATE,"))
    uart.dec(pc_port,mavlink_state)
    uart.str(pc_port,string("*",CR,LF))
    waitcnt(clkfreq/100 + cnt) ' Wait 100 mS }

{PUB testtimer
  hour := minute := sec := msec := 0
  ontime := 0
  prioritylevel := -1
  fast_loop_count := medium_loop_count := slow_loop_count := 0
  repeat
    waitcnt(1*wait_mS + cnt)
    ontime++

   if (ontime - fast_loop_count) > FAST_LOOP
     fast_loop_count := ontime 
     prioritylevel := PRIORITY_HIGH        

   if (ontime - medium_loop_count) > MEDIUM_LOOP
     medium_loop_count := ontime
     prioritylevel := PRIORITY_MEDIUM      

   if (ontime - slow_loop_count) > SLOW_LOOP
      slow_loop_count := ontime
      prioritylevel := PRIORITY_LOW 

   case prioritylevel
      PRIORITY_HIGH:
        uart.str(debug_port,string("1")) 
      PRIORITY_MEDIUM:
        uart.str(debug_port,string("2")) 
      PRIORITY_LOW:
        uart.str(debug_port,string("3")) }

PUB watchdog(wdpntr, limit) | t

' wdpntr = hub address of watchdog variable
' limit = milliseconds of "stuck" before Propeller reboot

  long[wdpntr] := 0                                             ' reset
  
  t := cnt                                                      ' sync
  repeat
    waitcnt(t += clkfreq/1_000)                                 ' wait 1ms
    long[wdpntr] += 1
    if (long[wdpntr] > limit)                                   ' exceed watchdog limit
      reboot                                                    ' yes, reboot

{PUB testsonic| i,tempstrA,tempstrC
  repeat i from 0 to 4 ' Set all Sonic Distances to 0 inches.
    sonicdist[i] := 0
    lastsonicdist[i] := 0
  repeat' until strcomp(@rxbuffer,string("done"))
    waitcnt(500*wait_mS + cnt) ' Wait 100 mS
    i := 0
    if SonicChannel1 <> -1
      sonicdist[i++] := adc.in(SonicChannel1)/ADC_SONAR_CONVERSION
    if SonicChannel2 <> -1
      sonicdist[i++] := adc.in(SonicChannel2)/ADC_SONAR_CONVERSION
    if SonicChannel3 <> -1
      sonicdist[i++] := adc.in(SonicChannel3)/ADC_SONAR_CONVERSION
    if SonicChannel4 <> -1
      sonicdist[i++] := adc.in(SonicChannel4)/ADC_SONAR_CONVERSION
    if SonicChannel5 <> -1
      sonicdist[i++] := adc.in(SonicChannel5)/ADC_SONAR_CONVERSION
    if SonicChannel6 <> -1
      sonicdist[i++] := adc.in(SonicChannel6)/ADC_SONAR_CONVERSION
    if SonicChannel1 <> -1
      tempstrA := string("$SEN,ULT")
      bytefill(@stringbuffer,0,100)
      bytemove(@stringbuffer,tempstrA,strsize(tempstrA))
      repeat i from 0 to 5
        str.Concatenate(@stringbuffer,string(","))
        str.Concatenate(@stringbuffer,util.dec2str(sonicdist[i],@tempstr1))
      tempstrC := string("*",CR)
      str.Concatenate(@stringbuffer,tempstrC)
      uart.str(debug_port,@stringbuffer)}   
PUB mainloop | i, j, value1, value2, value3,bootmode,ledmode,ledpin , tempstrA,tempstrB,tempstrC,storagecount,temp1, lasttime,rollflag_oa,pitchflag_oa,throttleflag_oa
''DPG 31-DEC-2012
'' Added basic ICARUS comm protocol stuff, heartbeat
''DPG 3-JAN-2013
'' Added in more ICARUS comm protocol stuff, Error Checking
  if mavlink_mode_armed == MAV_MODE_MANUAL_ARMED
    OUTA[ledpin2] := 1
    OUTA[ledpin3] := 0
  elseif mavlink_mode_armed == MAV_MODE_TEST_ARMED
    OUTA[ledpin2] := 0
    OUTA[ledpin3] := 1
  rollflag_oa := FALSE
  pitchflag_oa := FALSE
  throttleflag_oa := FALSE
  hour := minute := sec := msec := 0
  ontime := 0
  prioritylevel := -1
  fast_loop_count := medium_loop_count := slow_loop_count := 0
  lasttime := 0
  storagecount := 0
  temp1 := 0
  frontdist := 0
  leftdist := 0
  backdist := 0
  rightdist := 0
  topdist := 0
  bottomdist := 0
  'bytefill(@sdtextbuffer,0,500)
  'bytemove(@sdtextbuffer,0,0)
   
  bytefill(@curerrorcode,0,15)
  str.Concatenate(@curerrorcode,@SYSTEM_FLYER_MC)
  str.Concatenate(@curerrorcode,string("-"))
  str.Concatenate(@curerrorcode,@ERRORTYPE_NOERROR)
  str.Concatenate(@curerrorcode,string("-"))
  str.Concatenate(@curerrorcode,@SEVERITY_NOERROR)
  str.Concatenate(@curerrorcode,string("-"))
  str.Concatenate(@curerrorcode,@MESSAGE_NOERROR)
  uart.str(pc_port,@curerrorcode)
  {repeat i from 0 to 7   ' Set all Servo PWM's to Neutral
    apm_servocmd[i] := 1500
    servo_min[i] := 1000
    servo_center[i] := 1500
    servo_max[i] := 2000
   } 
  repeat i from 0 to 4 ' Set all Sonic Distances to 0 inches.
    sonicdist[i] := 0
    lastsonicdist[i] := 0
  bootmode := 0
  
  repeat' until strcomp(@rxbuffer,string("done"))
    waitcnt(1*wait_mS + cnt) ' Wait 100 mS
    ontime++
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


    
    hour := timer.hours
    minute := timer.minutes
    sec := timer.seconds
    msec := timer.mseconds    
    curtimestamp[0] := hour
    curtimestamp[1] := minute
    curtimestamp[2] := sec
    lasttime := curtimestamp[3]
    curtimestamp[3] := msec


    getpcrxbuffer(@pcrxbuffer)
    uart.dec(debug_port,mavlink_mode_armed)
    uart.str(debug_port,string(SPACE))
    uart.str(debug_port,@pcrxbuffer)
    uart.dec(debug_port,ontime)
    uart.str(debug_port,string(CR,LF))   
    case prioritylevel
           
      PRIORITY_HIGH: 'Read Mode (Arm/Disarm) Commands
        'uart.dec(debug_port,1)
        modehandler     
        if util.strncomp(@pcrxbuffer,string("$CON,"),0) 'Control Type, WORKS
          if util.strncomp(@pcrxbuffer,string("MODE"),5) ' MAVLink Mode
              temp1 := temp1 + 1
              'uart.str(debug_port,string(CR,LF))
              'uart.dec(debug_port,temp1)
              'uart.str(debug_port,string(CR,LF))
              controlmode :=  CON_mavlink_mode_armed
              mavlink_mode_armed :=  util.strntodec(util.strtok(@pcrxbuffer,2),0)
          else
            controlmode := -1
        armedhandler(mavlink_mode)
        flightmodehandler
        
      PRIORITY_MEDIUM: 'Read Sensors

        
        'uart.dec(debug_port,2)
        errorhandler
        if util.strncomp(@pcrxbuffer,string("$CAM,"),0) 'Camera Type
          if util.strncomp(@pcrxbuffer,string("DIST"),5) 'Distance Mode
          ''$CAM,DIST,20,0,18,27,115,200,30,30,30*  
            j := 9  'Position of 2nd comma
            i := 0
            temp1 := FALSE
            repeat while i < 9 '9 Distance values in this packet
              camdist[i++] := util.strntodec(@pcrxbuffer,j)
              j++
              repeat while ~temp1
                if util.strncomp(@pcrxbuffer,COMMA,j++)
                  temp1 := TRUE
                if j > 75
                  temp1 := FALSE
                  OUTA[ledpin4] := 1 'Debugging, Error!    
                
        
        if FrontMotorInPin <> -1

          {MotorInPWM[0] := pwmin.GetPWM(FrontMotorInPin)
          MotorInPWM[1] := pwmin.GetPWM(LeftMotorInPin)
          MotorInPWM[2] := pwmin.GetPWM(BackMotorInPin)
          MotorInPWM[3] := pwmin.getPWM(RightMotorInPin)}
          
          'Sonic Sensors
        i := 0
        repeat i from 0 to 5
          lastsonicdist[i] := sonicdist[i]
        
        
        if SonicChannel1 <> -1
          sonicdist[i++] := adc.in(SonicChannel1)/ADC_SONAR_CONVERSION 
        if SonicChannel2 <> -1
          sonicdist[i++] := adc.in(SonicChannel2)/ADC_SONAR_CONVERSION 
        if SonicChannel3 <> -1
          sonicdist[i++] := adc.in(SonicChannel3)/ADC_SONAR_CONVERSION 
        if SonicChannel4 <> -1
          sonicdist[i++] := adc.in(SonicChannel4)/ADC_SONAR_CONVERSION 
        if SonicChannel5 <> -1
          sonicdist[i++] := adc.in(SonicChannel5)/ADC_SONAR_CONVERSION 
        if SonicChannel6 <> -1
          sonicdist[i++] := adc.in(SonicChannel6)/ADC_SONAR_CONVERSION 
          
       repeat i from 0 to 5
          if sonicdist[i] < 1 'Check Sensors, if they are less than 1 use the old value
            sonicdist[i] := lastsonicdist[i]
          else  ' Otherwise average the current and last value
            sonicdist[i] := (sonicdist[i] + lastsonicdist[i])/2
          sonicdist[i] := sonicdist[i]
        frontdist := sonicdist[4] 
        leftdist := sonicdist[2]  
        backdist := sonicdist[5]  
        rightdist := sonicdist[3] 
        topdist := 1000'sonicdist[0] 
        bottomdist := 1000'sonicdist[1]
        'mavlink_mode_armed := MAV_MODE_MANUAL_ARMED  
        case mavlink_mode_armed ''Pass-Through Mode
          MAV_MODE_MANUAL_ARMED:
            repeat i from 0 to 3
              MotorOutPWM[i] := MotorInPWM[i]
          MAV_MODE_TEST_ARMED: ''All Obstacle Avoidance Stuff
            { switch on mavlink_flightmode: MAV_CMD_NAV_CONTINUE, MAV_CMD_NAV_LAND  }

            'Top Sensor (Throttle)
            if (throttleflag_oa == TRUE) AND (topdist < frontdist) AND (topdist < leftdist) AND (topdist < backdist) AND (topdist < rightdist) AND (topdist < bottomdist)
              repeat i from 0 to 3
                MotorAdjustPWM[i] := util.calc_opposingmotor(topdist)
             'Bottom Sensor (Throttle), add a "cushion"
            elseif (throttleflag_oa == TRUE) AND (mavlink_flightmode == MAV_CMD_NAV_CONTINUE) AND ( bottomdist < frontdist) AND (bottomdist < leftdist) AND (bottomdist < backdist) AND (bottomdist < rightdist) AND (bottomdist < topdist)    
              repeat i from 0 to 3
                MotorAdjustPWM[i] := util.calc_currentmotor(bottomdist)/3
            else 
              'Left/Right Sensor (Roll)
              if (leftdist < rightdist) AND (rollflag_oa == TRUE)
                MotorAdjustPWM[1] := util.calc_currentmotor(leftdist)
                MotorAdjustPWM[3] := util.calc_opposingmotor(leftdist)
              elseif (rightdist < leftdist) AND (rollflag_oa == TRUE)  
                MotorAdjustPWM[1] := util.calc_opposingmotor(rightdist)
                MotorAdjustPWM[3] := util.calc_currentmotor(rightdist)
              if (frontdist < backdist) AND (pitchflag_oa == TRUE)  
                MotorAdjustPWM[0] := util.calc_currentmotor(frontdist)
                MotorAdjustPWM[2] := util.calc_opposingmotor(frontdist)
              elseif (backdist < frontdist) AND (pitchflag_oa == TRUE)  
                MotorAdjustPWM[0] := util.calc_opposingmotor(backdist)
                MotorAdjustPWM[2] := util.calc_currentmotor(backdist)                                                
              {  
              else  
                MotorAdjustPWM[1] := util.calc_opposingmotor(rightdist)
                MotorAdjustPWM[3] := util.calc_currentmotor(rightdist)
              'Front/Back Motion  (Pitch)
              if frontdist < backdist
                MotorAdjustPWM[0] := util.calc_currentmotor(frontdist)
                MotorAdjustPWM[2] := util.calc_opposingmotor(frontdist)
              else
                MotorAdjustPWM[0] := util.calc_opposingmotor(backdist)
                MotorAdjustPWM[2] := util.calc_currentmotor(backdist)}

            repeat i from 0 to 3
              MotorOutPWM[i] := MotorInPWM[i] + MotorAdjustPWM[i]   

        pwmout.Servo(FrontMotorOutPin,MotorOutPWM[0])
        pwmout.Servo(LeftMotorOutPin,MotorOutPWM[1])
        pwmout.Servo(BackMotorOutPin,MotorOutPWM[2])
        pwmout.Servo(RightMotorOutPin,MotorOutPWM[3])      


        if SonicChannel1 <> -1
          tempstrA := string("$SEN,ULT")
          bytefill(@stringbuffer,0,100)
          bytemove(@stringbuffer,tempstrA,strsize(tempstrA))
          repeat i from 0 to 5
            str.Concatenate(@stringbuffer,string(","))
            str.Concatenate(@stringbuffer,util.dec2str(sonicdist[i],@tempstr1))
          tempstrC := string("*",CR,LF)
          str.Concatenate(@stringbuffer,tempstrC)
          uart.str(pc_port,@stringbuffer)
         
          {
          tempstrA := string("$CAM,DIST")
          bytefill(@stringbuffer,0,100)
          bytemove(@stringbuffer,tempstrA,strsize(tempstrA))
          repeat i from 0 to 8
            str.Concatenate(@stringbuffer,string(","))
            str.Concatenate(@stringbuffer,util.dec2str(camdist[i],@tempstr1))
          tempstrC := string("*",CR,LF)
          str.Concatenate(@stringbuffer,tempstrC)
          uart.str(debug_port,@stringbuffer)} 

        if (SonicChannel1 <> -1)' AND (mavlink_mode_armed == MAV_MODE_TEST_ARMED)
          tempstrA := string("$MOT")
          bytefill(@stringbuffer,0,100)
          bytemove(@stringbuffer,tempstrA,strsize(tempstrA))
          repeat i from 0 to 3
            str.Concatenate(@stringbuffer,string(","))
            str.Concatenate(@stringbuffer,util.dec2str(MotorOutPWM[i],@tempstr1))
          tempstrC := string("*",CR,LF)
          str.Concatenate(@stringbuffer,tempstrC)
          uart.str(pc_port,@stringbuffer)
          tempstrA := string("$MOTADJ")
          bytefill(@stringbuffer,0,100)
          bytemove(@stringbuffer,tempstrA,strsize(tempstrA))
          repeat i from 0 to 3
            str.Concatenate(@stringbuffer,string(","))
            str.Concatenate(@stringbuffer,util.dec2str(MotorAdjustPWM[i],@tempstr1))
          tempstrC := string("*",CR,LF)
          str.Concatenate(@stringbuffer,tempstrC)
          uart.str(pc_port,@stringbuffer)  
      PRIORITY_LOW:  'Reply to PC and FC
        'mavlink_mode_armed := MAV_MODE_TEST_ARMED
  'mavlink_mode_armed := MAV_MODE_MANUAL_ARMED
        
        ~OUTA[ledpin4]
             
        'uart.dec(debug_port,3)
          'Transmit MAVLink State
        uart.str(pc_port,string("$STA,STATE,"))
        uart.dec(pc_port,mavlink_state)
        uart.str(pc_port,string("*",CR,LF))

          'Transmit Current MAVLink Mode
        'uart.str(debug_port,string("$STA,MODE,"))
        'uart.dec(debug_port,mavlink_mode_armed)
        'uart.str(debug_port,string("*",CR,LF))
        uart.str(pc_port,string("$STA,MODE,"))
        uart.dec(pc_port,mavlink_flightmode)
        uart.str(pc_port,string("*",CR,LF))

        tempstrA := string("$SEN,ULT")
        bytefill(@stringbuffer,0,100)
        bytemove(@stringbuffer,tempstrA,strsize(tempstrA))
        repeat i from 0 to 5
            str.Concatenate(@stringbuffer,string(","))
            str.Concatenate(@stringbuffer,util.dec2str(sonicdist[i],@tempstr1))
        tempstrC := string("*",CR,LF)
        str.Concatenate(@stringbuffer,tempstrC)
        uart.str(debug_port,@stringbuffer)
        
       { uart.str(debug_port,string("$STA,MODE,"))
        uart.dec(debug_port,mavlink_flightmode)
        uart.str(debug_port,string("*",CR,LF))

        uart.str(debug_port,string("$STA,ARMED,"))
        uart.dec(debug_port,mavlink_mode_armed)
        uart.str(debug_port,string("*",CR,LF)) }
        {
        uart.str(debug_port,string("$STA,MODE,"))
        uart.dec(debug_port,mavlink_mode_armed)
        uart.str(debug_port,string("*",CR,LF))
        }

        if util.strncomp(@pcrxbuffer,string("$NET,"),0) ' Network Type,WORKS
        if util.strncomp(@pcrxbuffer,string("HRTBT"),5) ' Heartbeat Packet,WORKS
          lastheartbeatnumber := heartbeatnumber
          heartbeatnumber := util.strntodec(@pcrxbuffer, 11)       
          
          if ((heartbeatnumber - 1) <> lastheartbeatnumber) AND (heartbeatnumber <> 0)
          ' The current heartbeat number should be 1 higher than the last one.  If not, there was an error.
            missedheartbeatcounter++
        if util.strncomp(@pcrxbuffer,string("$SRV,"),0) 'Servo Packet,WORKS  
        if util.strncomp(@pcrxbuffer,string("$INF,"),0) 'Information Type, WORKS
          infopacket := util.strtok(@pcrxbuffer,1)
        if util.strncomp(@pcrxbuffer,string("ERR"),5) ' Error Packet, WORKS 
        if util.strncomp(@pcrxbuffer,string("QRY"),5) 'Status Query Packet

        
        'Transmit Measured PWM Input Values
        'uart.txflush(pc_port)
        if FrontMotorInPin <> -1
          uart.str(pc_port,string("$PWMIN"))
          repeat i from 0 to 3
            uart.str(pc_port,string(","))
            uart.dec(pc_port,MotorInPWM[i])      
          uart.str(pc_port,string("*",CR,LF))

        'Make sure PWM Input is still valid
        

      'Data Logging
      OTHER:
        'uart.dec(debug_port,0)
 
          
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
    if mav_mode == MAV_MODE_MANUAL
      mavlink_mode_armed := MAV_MODE_MANUAL_ARMED
    elseif mav_mode == MAV_MODE_TEST
      mavlink_mode_armed := MAV_MODE_TEST_ARMED
    else
      mavlink_mode_armed := MAV_MODE_MANUAL_ARMED
  elseif (adc.in(ArmDisarm_Ch) < ADC_LOWER_THRESHOLD)
    if mav_mode == MAV_MODE_MANUAL
      mavlink_mode_armed := MAV_MODE_MANUAL_DISARMED
    elseif mav_mode == MAV_MODE_TEST
      mavlink_mode_armed := MAV_MODE_TEST_DISARMED
    else
      mavlink_mode_armed := MAV_MODE_MANUAL_DISARMED   
pub errorhandler
  bytefill(@curerrorcode,0,15)
    str.Concatenate(@curerrorcode,@SYSTEM_FLYER_MC)
    str.Concatenate(@curerrorcode,string("-"))
    str.Concatenate(@curerrorcode,@ERRORTYPE_COMMUNICATION)
    str.Concatenate(@curerrorcode,string("-"))  
    if missedheartbeatcounter > 8
      str.Concatenate(@curerrorcode,@SEVERITY_EMERGENCY)
    elseif missedheartbeatcounter > 6
      str.Concatenate(@curerrorcode,@SEVERITY_SEVERE)
    elseif missedheartbeatcounter > 4
      str.Concatenate(@curerrorcode,@SEVERITY_CAUTION)
    elseif missedheartbeatcounter > 2
      str.Concatenate(@curerrorcode,@SEVERITY_MINIMAL)
    elseif missedheartbeatcounter > 0
      str.Concatenate(@curerrorcode,@SEVERITY_INFORMATION)
    else
      str.Concatenate(@curerrorcode,@SEVERITY_NOERROR)
    str.Concatenate(@curerrorcode,string("-"))
    str.Concatenate(@curerrorcode,@MESSAGE_MISSINGHEARTBEATS)
    'Transmit Current Error Code
   uart.str(pc_port,string("$ERR,"))
   uart.str(pc_port,@curerrorcode)
   uart.str(pc_port,string("*",CR,LF))
   
   bytefill(@curerrorcode,0,15)
    str.Concatenate(@curerrorcode,@SYSTEM_FLYER_MC)
    str.Concatenate(@curerrorcode,string("-"))
    str.Concatenate(@curerrorcode,@ERRORTYPE_COMMUNICATION)
    str.Concatenate(@curerrorcode,string("-"))  
    if droppedpacketcounter > 8
      str.Concatenate(@curerrorcode,@SEVERITY_EMERGENCY)
    elseif droppedpacketcounter > 6
      str.Concatenate(@curerrorcode,@SEVERITY_SEVERE)
    elseif droppedpacketcounter > 4
      str.Concatenate(@curerrorcode,@SEVERITY_CAUTION)
    elseif droppedpacketcounter > 2
      str.Concatenate(@curerrorcode,@SEVERITY_MINIMAL)
    elseif droppedpacketcounter > 0
      str.Concatenate(@curerrorcode,@SEVERITY_INFORMATION)
    else
      str.Concatenate(@curerrorcode,@SEVERITY_NOERROR)
    str.Concatenate(@curerrorcode,string("-"))
    str.Concatenate(@curerrorcode,@MESSAGE_DROPPEDPACKETS)
    'Transmit Current Error Code
   uart.str(pc_port,string("$ERR,"))
   uart.str(pc_port,@curerrorcode)
   uart.str(pc_port,string("*",CR,LF)) 

pub modehandler|i

case controlmode
  CON_mavlink_mode_armed:
    case mavlink_mode_armed
      MAV_MODE_UNDEFINED:
        mavlink_state := MAV_STATE_UNINIT
        uart.str(debug_port,string("MAV_STATE_UNINIT"))
      MAV_MODE_PREFLIGHT:
        OUTA[ledpin1] := 1
        uart.str(debug_port,string("MAV_STATE_BOOT"))
        uart.str(debug_port,string("I am rebooting now"))
        waitcnt(clkfreq/250 + cnt)
        REBOOT
      MAV_MODE_MANUAL_DISARMED:
        mavlink_state := MAV_STATE_STANDBY
        'uart.str(debug_port,string("MAV_MODE_MANUAL_DISARMED"))
      MAV_MODE_TEST_DISARMED:
        mavlink_state := MAV_STATE_STANDBY
        'uart.str(debug_port,string("MAV_MODE_TEST_DISARMED"))
      MAV_MODE_STABILIZE_DISARMED:
        mavlink_state := MAV_STATE_STANDBY
        'uart.str(debug_port,string("MAV_MODE_STABILIZE_DISARMED"))
      MAV_MODE_GUIDED_DISARMED:
        mavlink_state := MAV_STATE_STANDBY
        'uart.str(debug_port,string("MAV_MODE_GUIDED_DISARMED"))
      MAV_MODE_AUTO_DISARMED:
        mavlink_state := MAV_STATE_STANDBY
        'uart.str(debug_port,string("MAV_MODE_AUTO_DISARMED"))
      MAV_MODE_MANUAL_ARMED:
        mavlink_state := MAV_STATE_ACTIVE
        'uart.str(debug_port,string("MAV_MODE_MANUAL_ARMED"))
      MAV_MODE_TEST_ARMED:
        mavlink_state := MAV_STATE_ACTIVE
        'uart.str(debug_port,string("MAV_MODE_TEST_ARMED"))
        ''Start Obstacle Avoidance Mode
      MAV_MODE_STABILIZE_ARMED:
        mavlink_state := MAV_STATE_ACTIVE
        'uart.str(debug_port,string("MAV_MODE_STABILIZE_ARMED"))
      MAV_MODE_GUIDED_ARMED:
        mavlink_state := MAV_STATE_ACTIVE
        'uart.str(debug_port,string("MAV_MODE_GUIDED_ARMED"))
      MAV_MODE_AUTO_ARMED:
        mavlink_state := MAV_STATE_ACTIVE
        'uart.str(debug_port,string("MAV_MODE_AUTO_ARMED"))

{
  CON_MANUAL:  'Manual Control Mode
      'Set Actuators
    i := 0
    if ServoPin1 <> -1
      servo.Set(ServoPin1,apm_servocmd[i++])
    if ServoPin2 <> -1
      servo.Set(ServoPin2,apm_servocmd[i++])
    if ServoPin3 <> -1
      servo.Set(ServoPin3,apm_servocmd[i++])
    if ServoPin4 <> -1
      servo.Set(ServoPin4,apm_servocmd[i++])
    if ServoPin5 <> -1
      servo.Set(ServoPin5,apm_servocmd[i++])
    if ServoPin6 <> -1
      servo.Set(ServoPin6,apm_servocmd[i++])
    if ServoPin7 <> -1
      servo.Set(ServoPin7,apm_servocmd[i++])
    if ServoPin8 <> -1
      servo.Set(ServoPin8,apm_servocmd[i++])
  CON_TAKEOFFvtol: 'Takeoff Control Mode
    i := 0
    if ServoPin1 <> -1
      servo.Set(ServoPin1,servo_90deg[i++])
    if ServoPin2 <> -1
      servo.Set(ServoPin2,servo_90deg[i++])
    if ServoPin3 <> -1
      servo.Set(ServoPin3,servo_90deg[i++])
    if ServoPin4 <> -1
      servo.Set(ServoPin4,servo_90deg[i++])
  CON_HOVER:  'Hover Mode
    i := 0
    if ServoPin1 <> -1
      servo.Set(ServoPin1,servo_90deg[i++])
    if ServoPin2 <> -1
      servo.Set(ServoPin2,servo_90deg[i++])
    if ServoPin3 <> -1
      servo.Set(ServoPin3,servo_90deg[i++])
    if ServoPin4 <> -1
      servo.Set(ServoPin4,servo_90deg[i++])
  CON_LANDVTOL:  'Land Mode
    i := 0
    if ServoPin1 <> -1
      servo.Set(ServoPin1,servo_90deg[i++])
    if ServoPin2 <> -1
      servo.Set(ServoPin2,servo_90deg[i++])
    if ServoPin3 <> -1
      servo.Set(ServoPin3,servo_90deg[i++])
    if ServoPin4 <> -1
      servo.Set(ServoPin4,servo_90deg[i++])
  CON_CRUISE:  'Cruise Mode
    i := 0
    if ServoPin1 <> -1
      servo.Set(ServoPin1,servo_0deg[i++])
    if ServoPin2 <> -1
      servo.Set(ServoPin2,servo_0deg[i++])
    if ServoPin3 <> -1
      servo.Set(ServoPin3,servo_0deg[i++])
    if ServoPin4 <> -1
      servo.Set(ServoPin4,servo_0deg[i++])
  CON_HOVERtoCRUISE:  'Auto Transition from Hover to Cruise Mode
  CON_CRUISEtoHOVER:  'Auto Transition from Cruise to Hover Mode
}  
    
    
      

{pub errorhandler
  case curerrorcode[curerrorcodeindex]
  
    12000: ' Running Normal Operation
    12001: ' Initializing
    12131: ' Dropping Packets: Information Level
    12231: ' Dropping Packets: Minimal Level
    12331: ' Dropping Packets: Caution Level 
    12431: ' Dropping Packets: Severe Level
    12531: ' Dropping Packets: Emergency Level
    12599: ' Initializing Error
    12132: ' Missing Heartbeats: Information Level 
    12232: ' Missing Heartbeats: Minimal Level 
    12332: ' Missing Heartbeats: Caution Level 
    12432: ' Missing Heartbeats: Severe Level
    12532: ' Missing Heartbeats: Emergency Level
    12361: ' Logging Not present/Available

  if curerrorcode[curerrorcodeindex] <> 0
    uart.str(pc_port,string("$STA,ERR,"))
    uart.dec(pc_port,curerrorcode[curerrorcodeindex])
    uart.str(pc_port,string("*",CR,LF))}
     
{pub climode| i, exit
'' DPG 1-JAN-2013
'' Added Command Line Interface Mode
  exit := 0
  repeat
    !outa[ledpin3]
    repeat i from 0 to 3
      uart.str(pc_port,@@mainAddr[i])
      waitcnt(clkfreq/250 + cnt)
    getpcrxbuffer(@pcrxbuffer)
    if util.strncomp(@pcrxbuffer,string("debug"),0) 'Debug/Testing Menu
      repeat until exit == 1
        repeat i from 0 to 4
           uart.str(pc_port,@@debugAddr[i])
          waitcnt(clkfreq/250 + cnt)
        getpcrxbuffer(@pcrxbuffer)
        if util.strncomp(@pcrxbuffer,string("servo"),0)
          debugmode(DEBUG_SERVO)
        elseif util.strncomp(@pcrxbuffer,string("sonic"),0)
          debugmode(DEBUG_SONIC)
        elseif util.strncomp(@pcrxbuffer,string("analog"),0)

          debugmode(DEBUG_ANALOG)
        elseif util.strncomp(@pcrxbuffer,string("all"),0)
          debugmode(DEBUG_ALLIO)
        elseif util.strncomp(@pcrxbuffer,string("exit"),0)
          exit := 1
        else
          exit := 0          
    elseif util.strncomp(@pcrxbuffer,string("calib"),0)
    elseif util.strncomp(@pcrxbuffer,string("normal"),0)
      uart.str(pc_port,string("Entering Normal Mode"))
      mainloop }

{pri updateleds(mode,index)|dutycycle,leds,Cylon
DutyCycle:=100   '' Set to desired Brightness   0=off 100=Max Brightness
leds:=8         '' Set to Number of Leds in your Cylon

if mode == TRUE 
        ledpwm.Duty(index -2,DutyCycle-DutyCycle/100*99,5000) 
        ledpwm.Duty(index -1,DutyCycle-DutyCycle/100*90,5000)      
        ledpwm.Duty(index   ,DutyCycle    ,5000)
        ledpwm.Duty(index +1,DutyCycle-DutyCycle/100*90,5000)
        ledpwm.Duty(index +2,DutyCycle-DutyCycle/100*99,5000)            
        'repeat 20000   '' old style delay
elseif mode == FALSE 
        ledpwm.Duty(index -2,DutyCycle-DutyCycle/100*99,5000) 
        ledpwm.Duty(index -1,DutyCycle-DutyCycle/100*90,5000)      
        ledpwm.Duty(index   ,DutyCycle    ,5000)
        ledpwm.Duty(index +1,DutyCycle-DutyCycle/100*90,5000)
        ledpwm.Duty(index +2,DutyCycle-DutyCycle/100*99,5000)
}
{pri debugmode(debugoption)| exit,i,j,tempstr,temp1
  waitcnt(clkfreq*2 + cnt)
  i := 0 
  exit := 0
  repeat
    case debugoption
      DEBUG_ALLIO:
         if i == 0
          uart.txflush(pc_port)
          uart.str(pc_port,string("P0P1P2P3P4P5P6P7P8P9P10"))
          uart.str(pc_port,string("P11P12P13P14P15P16P17P18P19P20"))
          uart.str(pc_port,string("P21P22P23P24P25P26P27P28P29P30")) 
          uart.tx(pc_port,CR)
          uart.tx(pc_port,LF)
        repeat j from 0 to 31
          uart.bin(pc_port,outa[j],1)
          uart.tx(pc_port,SPACE)         
        uart.tx(pc_port,CR)
        uart.tx(pc_port,LF)
        i++
        if i => 50
          !outa[ledpin3]
          i := 0
      DEBUG_SERVO:
        
      DEBUG_SONIC:
        
      DEBUG_ANALOG:     
        
        
'repeat j from 0 to 30
'  uart.tx(pc_port,OUTA[j])
'  uart.str(pc_port,string("  "))  }
 
      
       
 
 
    
    
    
    
      
    

{pri mainmenu  | i, continue, id
  i := 0
  repeat 5
    uart2.str(comport,@@mainAddr[i])
    waitcnt(cnt + waitdelay)
    i++
  continue := true
    
  repeat until continue == false
    getrxbuffer(comport, @pcrxbuffer)   
    if strcomp(@pcrxbuffer,string("auto"))
      automenu
    elseif strcomp(@pcrxbuffer,string("debug"))
      debugmenu
    elseif strcomp(@pcrxbuffer,string("calibration"))
      calibmenu
    elseif strcomp(@pcrxbuffer,string("manual"))
      manumenu
      }  
PUB getfcrxbuffer(rxbuffptr) | i,char
''DPG 31-DEC-2012
''Fixed and verified operation
''DPG 25-AUG-2013
''Changed to fullDuplexSerial4port operation, much better, entire function is non-blocking finally.
  i := 0
  repeat
    char := uart.rxCheck(fc_port)
    if char < 0
      quit
    
    if (char > 31) and (char < 127)
      byte[rxbuffptr][i] := char
      i++
  until char == CR
PUB getpcrxbuffer(rxbuffptr) | i,j,done,char
''DPG 1-JAN-2013
''Added for USB operation
''DPG 25-AUG-2013
''Changed to fullDuplexSerial4port operation, much better, entire function is non-blocking finally.
  i := 0
  repeat
    char := uart.rxCheck(pc_port)
    if char < 0
      bytefill(@pcrxbuffer,0,100)
      quit
    
    if (char > 31) and (char < 127)
      uart.tx(debug_port,char)
      byte[rxbuffptr][i] := char
      i++
  until char == CR
  'uart.rxflush(pc_port)
                 

  'Validate Message using XOR
{  i := 0
  calc := 0
  repeat while byte[rxbuffptr][i] <> 42
    calc ^= byte[rxbuffptr][i]  

  if calc == checksum
    return 1
  else
    return 0}

            
{PUB testusb | temp
''MEC 07-APR-09
''Created to test datalogging functionality

  outa[ledpin2]~~
  waitcnt(3*waitdelay + cnt)
{   USB.start(USBrx,USBtx)                    ' start USB drive
'  LCD.str(USB.getErrorMessage)      
   uart.dec(comport,USB.checkErrorCode)
  if USB.checkErrorCode == 0
    USB.OpenForWrite(string("Test.txt"))
    USB.WriteLine(string("Hello World!"))
    USB.Close(string("Test.txt"))

} 
  temp := log.start( usbtx, usbrts, usbrx, usbcts)
  
  if( temp == 0)
    outa[ledpin3]~~ 
    uart.str(comport, string("Successfully started USB."))
    uart.tx(comport, CR)
    uart.tx(comport, LF)
  else
    uart.str(comport, string("Failed starting USB."))  

  temp := log.getSize(string("Test.txt"))
  uart.dec(comport, temp)

  temp := 0
  temp := log.OpenForWrite(string("Test.txt"))
  if (temp == FALSE)
     uart.str(comport, string("Failed to open file."))
  elseif (temp == TRUE)
    uart.str(comport, string("Opened File"))

  temp := log.WriteLine(string("Hello Stupid World!"))
  if (temp == FALSE)
     uart.str(comport, string("Failed to write to file."))
  elseif (temp == TRUE)
    uart.str(comport, string("Wrote To File"))


  temp := log.Close(string("Test.txt"))
  if (temp == FALSE)
     uart.str(comport, string("Failed to close file."))
  elseif (temp == TRUE)
    uart.str(comport, string("Closed File"))
      
  temp := log.OpenForRead(string("Test.txt"))
  if (temp == FALSE)
     uart.str(comport, string("Failed to open file."))
  elseif (temp == TRUE)
     uart.str(comport, string("Opened File"))

  log.Read(50,@datalogbuffer)
  uart.str(comport,@datalogbuffer)

      
  temp := log.Close(string("Test.txt"))
  if (temp == FALSE)
     uart.str(comport, string("Failed to close file."))
  elseif (temp == TRUE)
    uart.str(comport, string("Closed File"))
                                      
  repeat
    waitcnt(waitdelay + cnt)
  
            
PUB testsensor| Ax,Ay,Az,Aref,YawRate,PitchRate,GyroRef,CmpDegrees, GyroDegrees, tempstr1, tempstr2,tempstr3, temp1
''DPG 10-MAR-09
''Added in Accelerometer Calibration.  Need to calibrate gyro and compass
''DPG 11-MAR-09
''Added in support for Green Switch Mode Selector.
''DPG 14-MAR-09
''Accelerometer Calibrated.  Added in code to calculate sampling time for each loop.    
  GyroDegrees := comp.degrees
  elapsedtime := 0

  repeat
    'if ina[greenswitch] == datapacket
    '  datapacketmode
    '!outa[ledpin2]

    'getgpsrxbuffer(@gpsrxbuffer)
    'uart.str(comport,@gpsrxbuffer)
    'uart.tx(comport,CR)
    'uart.tx(comport,LF)
   
 {   dist := ping.Inches(pingpin)
    dist := fmath.fround(dist)
    uart.str(comport,string("$SEN,ULT,"))
    uart.dec(comport,dist)
    uart.str(comport,string("*"))
    uart.tx(comport,CR)
    uart.tx(comport,LF)
 }   
    Ax := (accel.x * 65 / 100)
    Ay := (accel.y * 65) / 100
    Az := ((accel.z + 150) * 65) / 100 
    
    uart.str(comport,string("$SEN,ACC,"))
    uart.dec(comport,Ax)
    uart.str(comport,string(","))
    uart.dec(comport,Ay) 
    uart.str(comport,string(","))
    uart.dec(comport,Az) 
    uart.str(comport,string("*"))
    uart.tx(comport,CR)
    uart.tx(comport,LF)

    CmpDegrees := comp.degrees-180
    if CmpDegrees > 180
       CmpDegrees += CmpDegrees
    if CmpDegrees < 0
       CmpDegrees += 360
         
    uart.str(comport,string("$SEN,CMP,"))
    uart.dec(comport,CmpDegrees)
    uart.str(comport,string("*"))
    uart.tx(comport,CR)
    uart.tx(comport,LF)

    YawRate := ADC.average(gyroyawpin,100)
    PitchRate := ADC.in(gyropitchpin)
    GyroRef := ADC.in(gyrorefpin)
    YawRate := (((YawRate - GyroRef) * 10) - 7770)/-100
    PitchRate := PitchRate - GyroRef - 410
    GyroRef := GyroRef - 1470 
    uart.str(comport,string("$SEN,GYR,"))
    uart.dec(comport,YawRate)
    uart.str(comport,string(","))
    uart.dec(comport,PitchRate)
    uart.str(comport,string(","))
    uart.dec(comport,GyroRef)
    uart.str(comport,string("*"))
    uart.tx(comport,CR)
    uart.tx(comport,LF)

    waitcnt(waitdelay + cnt)
    newtime := cnt
    elapsedtime := newtime - lasttime
    elapsedtime := (elapsedtime * 1000000000) / clkfreq 'in Micro-Seconds
}

{PUB teststring | i, j,tempstrA,tempstrB,tempstrC
  'tempstr1
  'tempstr2
  'stringbuffer
  i := 0
  repeat
    i++
    waitcnt(100*wait_mS + cnt)
    !outa[ledpin4]
    tempstrA := string("$STA,DUMB,")
    tempstrB := util.dec2str(i,@tempstr1)
    tempstrC := string("*",CR,LF)
    bytefill(@stringbuffer,0,100)
    bytemove(@stringbuffer,tempstrA,strsize(tempstrA))
    str.Concatenate(@stringbuffer,tempstrB)
    str.Concatenate(@stringbuffer,tempstrC)
    'bytemove(@stringbuffer,tempstrB,strsize(tempstrB))
    'str.Concatenate(@stringbuffer,tempstrB)
   ' bytemove(@stringbuffer,tempstrC,strsize(tempstrC))
   ' str.Concatenate(@stringbuffer,tempstrC)
    uart.str(pc_port,@stringbuffer)    }
 
   
{PUB testuart
  repeat
    getpcrxbuffer(@pcrxbuffer)
    uart.str(pc_port,string("Am I working? "))
    uart.str(pc_port,@pcrxbuffer)
    uart.tx(pc_port,CR)
    uart.tx(pc_port,LF)
    waitcnt(100*wait_mS + cnt) ' Wait 100 mS }
    
{PUB testsd | i,fileerror
  outa[ledpin4] := TRUE
  waitcnt(10*clkfreq + cnt)
  uart.str(pc_port,string("Mounting Error?: "))
  uart.dec(pc_port,SDinsert_card)
  if (SDinsert_card == 0)
    uart.str(pc_port,string("Creating File"))
    fileerror := sd.popen(string("TestFile.txt"), "w")
    uart.str(pc_port,string("File Error?: "))
    uart.dec(pc_port,fileerror)
    waitcnt(5*clkfreq + cnt)
    if fileerror == 0
      repeat i from 0 to 10
        uart.str(pc_port,string("Writing Test String: "))
        sd.pputs(string("Test-"))
        uart.dec(pc_port,i)
        sd.pputs(util.dec2str(i,@stringbuffer))
        uart.tx(pc_port,CR)
        sd.pputc(CR)
        uart.tx(pc_port,LF)
        sd.pputc(LF)

  uart.str(pc_port,string("Test File size: "))
  uart.dec(pc_port,sd.get_filesize)   
    uart.str(pc_port,string("Closing File")) 
    sd.pclose
    uart.str(pc_port,string("Dismounting Card")) 
  sd.unmount
  outa[ledpin4] := FALSE }
    
    
{PUB testservo | i
  repeat
    repeat i from 1 to 100
      uart.str(pc_port,string("Setting Servo 1-4: "))
      uart.dec(pc_port,i)
      uart.tx(pc_port,CR)
      uart.tx(pc_port,LF)
      servopwm.Duty(ServoPin1,i,976)
      servopwm.Duty(ServoPin2,i,976)
      servopwm.Duty(ServoPin3,i,976)
      servopwm.Duty(ServoPin4,i,976)
      'servopwm.Set(ServoPin1, i)
      'servo.Set(ServoPin2, i)
      'servo.Set(ServoPin3, i)
      'servo.Set(ServoPin4, i)
      uart.dec(pc_port,curerrorcode[curerrorcodeindex]) 
      waitcnt(100*wait_mS + cnt) ' Wait 100 mS
}      
    
PUB testadc
  repeat
    !outa[LedPin4]
    uart.dec(debug_port,adc.in(AnalogSense1))
    uart.tx(debug_port,SPACE)
    uart.dec(debug_port,adc.in(AnalogSense2))
    uart.tx(debug_port,SPACE)
    uart.dec(debug_port,adc.in(AnalogSense3))
    uart.tx(debug_port,SPACE)
    uart.dec(debug_port,adc.in(AnalogSense4))
    uart.tx(debug_port,SPACE)
    uart.dec(debug_port,adc.in(AnalogSense5))
    uart.tx(debug_port,SPACE)
    uart.dec(debug_port,adc.in(AnalogSense6))
    uart.tx(debug_port,SPACE)
    uart.dec(debug_port,adc.in(AnalogSense7))
    uart.tx(debug_port,SPACE)
    uart.dec(debug_port,adc.in(AnalogSense8))
    uart.tx(debug_port,SPACE)
    uart.tx(debug_port,CR)
    uart.tx(debug_port,LF)
    waitcnt(100*wait_mS + cnt) ' Wait 100 mS  
    

{PUB datalog(writestring,count)
  str.Concatenate(@sdtextbuffer,writestring)

  if LOG_EVERYTHING
    if ((count // 5)==0)
      'if sd.popen(string("Log_File.txt"),"w") == 0
        outa[ledpin4] := TRUE
        uart.str(pc_port,string("here-2"))  
        sd.pputs(@sdtextbuffer)
        uart.str(pc_port,@sdtextbuffer)
        bytefill(@sdtextbuffer,0,500)
        uart.str(telemport,string("End of Log"))          
        'sd.pclose
        outa[ledpin4] := FALSE
 } 
dat                   
{  maintitle byte 13,10,"Quickstart Main Menu",13,10,0
  main1 byte 32,32,"1) Debugging/Testing Mode Menu [debug]",13,10,0
  main2 byte 32,32,"2) Calibration Mode Menu [calib]",13,10,0
  main3 byte 32,32,"3) Normal Operation Mode [normal]",13,10,0
  mainAddr word @maintitle, @main1, @main2, @main3
  
  debugtitle byte 13,10,"Debug Menu [exit]",13,10,0
  debug1 byte 32,32,"1) Servo Outputs [servo]",13,10,0
  debug2 byte 32,32,"2) Ultrasonic Sensor Values [sonic]",13,10,0
  debug3 byte 32,32,"3) Analog Inputs [analog]",13,10,0
  debug4 byte 32,32,"4) All I/O [all]",13,10,0
  debugAddr word @debugtitle, @debug1, @debug2, @debug3, @debug4
 }
  logfile byte "Log_File_", 0
  stuff byte "Hello World!", 0

  'Error Code Definitions
  'Field 1: System and Subsystem
  SYSTEM_FLYER byte "10", 0
  SYSTEM_FLYER_PC byte "11", 0
  SYSTEM_FLYER_FC byte "12", 0
  SYSTEM_FLYER_MC byte "14", 0
  SYSTEM_GCS byte "50", 0
  SYSTEM_REMOTE byte "70", 0

  'Field 2: Error Type
  ERRORTYPE_NOERROR byte "0", 0
  ERRORTYPE_ELECTRICAL byte "1", 0
  ERRORTYPE_SOFTWARE byte "2", 0
  ERRORTYPE_COMMUNICATION byte "3", 0
  ERRORTYPE_SENSORS byte "4", 0
  ERRORTYPE_ACTUATORS byte "5", 0
  ERRORTYPE_DATASTORAGE byte "6", 0
  ERRORTYPE_GENERALERROR byte "9", 0

  'Field 3: Severity
  SEVERITY_NOERROR byte "0", 0
  SEVERITY_INFORMATION byte "1", 0
  SEVERITY_MINIMAL byte "2", 0
  SEVERITY_CAUTION byte "3", 0
  SEVERITY_SEVERE byte "4", 0
  SEVERITY_EMERGENCY byte "5", 0

  'Field 4: Message
  MESSAGE_NOERROR byte "0", 0
  MESSAGE_INITIALIZING byte "1", 0
  MESSAGE_INITIALIZINGERROR byte "2", 0
  MESSAGE_GENERALERROR byte "3", 0
  MESSAGE_DROPPEDPACKETS byte "4", 0
  MESSAGE_MISSINGHEARTBEATS byte "5", 0
  MESSAGE_DEVICENOTPRESORAVAIL byte "6", 0
  
  
  
  
  
  