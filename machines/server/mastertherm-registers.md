# Mastertherm pCO variable map

Source: the "Interní aplikace / Servisní aplikace" pages of mastertherm.online for an
AQ90I (pco5+, SW 64), read 2026-09-26. Variable codes (`A`nalog, `I`nteger, `D`igital) are
the pCO application indexes; they match our unit (W/W, pGDx, SW 163) wherever checked.
Cloud API names (`A_n`, `I_n`, `D_n`) use the same numbers.

Modbus TCP on the pGDx (192.168.1.86:502), holding registers, PDU address:
`A_n -> n+1` (value x10), `D_n -> 501+n`, `I_n -> 997+n`. Exporter config:
[mastertherm-modbus.yml](./mastertherm-modbus.yml).

Caveats on our unit: `A90/A91` (HC1 water) mirror `A77` (suction) and `A433` (brine
temperature) mirrors `A126` (DHW), because HC1 and brine control are not configured.
`A189` behaves like the well (source) water probe but has no label in these apps.
Unknown but compressor-linked: `A188`, `A444`, `A445`.

## Pump Settings (Heat Pump Settings, aid 13)

```
HEAT PUMP TIMING
Pump Before Compressor Start (I9) sec
Pump After Compressor Stop (I10) sec
Pump Run Type (D1): Compressor Only / Permanent
HEAT PUMP SPEED HEATING
Pump _H Minimum Speed (A157) %
Pump _H Maximum Speed (A158) %
HEAT PUMP ANTIFREEZE FUNCTION
Pump Water Temperature to Start (A498) °C
Pump Air Temperature to Start (A201) °C
HEAT PUMP FLOW ALARM
Pump Alarm (D31)
Pump Alarm On Time sec
Pump Alarm (D385): Flow/Alarm OK / Alarm ACTIVE
HEAT PUMP HW CONFIG
Pump Manual Speed (A499) %
```

## Heating water temperature (A1) °C

```
Outdoor temperature (A3) °C
Suction pressure (A79) bar
Discharge pressure (A24) bar
Evaporating temperature (A80) °C
Condensing temperature (A33) °C
Suction gas temperature SGT (A77) °C
Suction superheat SHT (A78) °C
Discharge gas temperature DGT (A2) °C
Discharge superheat DSHT (A7) °C
Requested suction superheat (A181) °C
Requested discharge superheat (A8) °C
Compressor run (D5)
Compressor speed (A475) rps
Reversing valve (D9) (0=heating, 1=cooling or defrost)
Heater 1 active (D6)
Heater 2 active (D7)
EEV position (I169) steps
Alarm active (D20)
3 alarms active (D21)
Reset 3 alarms (D19)
ALARMS (1 = OK, 0 = ALARM)
Low pressure (D17)
Low pressure memory (D368)
Low pressure alarm counter (I20)
High pressure (D16)
High pressure memory (D369)
High pressure alarm counter (I21)
High DGT memory (D55)
High DGT alarm counter (I25)
High condensing temperature memory (D56)
High condensing temperature alarm counter (I22)
Low evaporating temperature memory (D57)
Low evaporating temperature alarm counter (I23)
Antifreeze memory (D58)
Antifreeze alarm counter (I28)
Fan thermal protection (D13)
Fan thermal protection memory (D370)
Fan thermal protection alarm counter (I26)
Compressor thermal protection (D12)
Compressor thermal protection memory (D371)
Compressor thermal protection alarm counter (I27)
Flow (D14)  OK / Alarm or not requested
Flow memory (D372)
Flow alarm counter (I24)
Heater safety thermostat (D77)
Probes alarm (D370)
- Heating water probe alarm (1=Alarm)(D22)
- Antifreeze probe alarm (1=Alarm)(D59)
- Outdoor probe alarm (1=Alarm)(D350)
Probes alarm memory (D373)
High pressure switch (D351)
High pressure switch memory (D352)
High pressure switch alarm counter (I41)
Low pressure on high pressure side (D353)
Low pressure on high pressure side memory (D354)
Low pressure on high side counter (I39)
DC drive alarm (D355)
DC drive alarm memory (D356)
DC drive alarm counter (I42)
EVD EVO alarm (D25)
EVD EVO alarm memory (D359)
EVD EVO alarm counter (I40)
EVD EVO ALARMS
EVO online (pCO5: 1=OK, uPC: 0=OK)(D360)
Low superheat (1=Alarm)(D349)
Low superheat alarm counter (I176)
LOP (1=Alarm)(D387)
LOP alarm counter (I175)
MOP (1=Alarm)(D388)
MOP alarm counter (I174)
EEV motor (1=Alarm)(D389)
EEV motor alarm counter (I170)
Low suction temperature (1=Alarm)(D390)
Low suction temperature alarm counter (I171)
High condensing temperature (1=Alarm)(D392)
High condensing temperature alarm counter (I173)
EEPROM (1=Alarm)(D393)
S1, low pressure transducer (1=Alarm)(D396)
S1 alarm counter (I328)
S2, SGT probe (1=Alarm)(D397)
S2 alarm counter (I329)
S3, high pressure transducer (1=Alarm)(D398)
S3 alarm counter (I330)
S4, DGT probe (white) (1=Alarm)(D399)
S4 alarm counter (I331)
EVI alarm (1=OK)(D42)
EVI alarm counter (I413)
Configuration alarm (1=Alarm)(D391)
SW revision (I104)
SW revision subversion (I160)
EVD R407c set default parameters (SW 48+ only) (D89)
EVD R410a set default parameters (SW 48+ only) (D145)
DC DRIVE ALARM COUNTERS
Alarm code (I299)
Manual reset (D432)
Overcurrent (I350)
Motor overload (I351)
Overvoltage (I352)
Undervoltage (I353)
High temperature (I354)
Low temperature (I355)
Overcurrent HW (I356)
Motor High temperature (I357)
IGBT transistors (I358)
CPU / Memory (I359)
Parameters (I360)
DC BUS ripple (I361)
Data communication fault (I362)
Drive termistor (I363)
HP pressure switch (I365)
Motor phase fault (I366)
Internal fan fault (I367)
Speed fault (I368)
PFC - Current (I369)
PFC - Undervoltage (I370)
Unexpected stop (I371)
Unexpected restart (I422)
Ground fault (I421)
HW Overtemperature (I423)
Drive overload (I426)
STO 1 (I424)
STO 2 (I425)
Minimum RPS (I418)
Minimum pressure difference (I420)
Memory 1..4 (I427..I430) drive alarm code enum: 0 No alarm,1 Overcurrent,2 Motor overload,3 Overvoltage,4 Undervoltage,5 Drive overtemperature,6 Drive undertemperature,7 Overcurrent HW,8 Motor overtemperature,10 CPU error,11 Parameter default,12 DCbus ripple,13 Data communication fault,14 Drive thermistor fault,15 Autotuning fault,16 Drive disabled (STO),17 Motor phase fault,19 Speed fault,20 PFC module error,21 Power supply overvoltage,22 Power supply undervoltage,23 STO detection error,25 Ground fault,26 CPU sync error 1,27 CPU sync error 2,28 Drive overload
```

## EExpansion settings (aid 18)

```
Compressor model (I300): 0 GKT141,1 GJT240,2 GPT425DBA,3 GPT425DAA,4 AQ036,5 C-SBN26x,6 C-SBN30x,7 C-SBN37x,8 C-SBN453,9 C-SBS235,10 C-SCN603,11 C-SCN753,12 C-SCN903,13 ZH15,14 ZH21,15 ZH30,16 ZH38,17 ZH45,18 JBA068,19 GJT325,20 GPT330
E2V heating valve size (I301): 0 E2V14,1 E2V18,2 E2V24,3 E2V30,4 E2V35,5 E2V45,6 E2V55,7 E2V65,8 E2V9,9 E2V11
E2V cooling valve size (I302): same enum
Refrigerant type (I303): 0 R407c,1 R410a,2 R32,3 R290
Compressor capacity offset (A208) %
Compressor delay (I4) s
Glider time (I304) s
Evaporating reference of heating mode (A478) °C
Evaporating reference type of heating mode (I305): 0 Reference,1 Suction T,2 Glider
Evaporating reference of cooling mode (A479) °C
Evaporating reference type of cooling mode (I306)
Condensing reference of heating mode (A480) °C
Condensing reference type of heating mode (I307): 0 Reference T,1 Discharge T,2 Glider
Condensing reference of cooling mode (A481) °C
Condensing reference type of cooling mode (I308)
Manual steps of valve position (I168) steps
Mode (D49): 0 Auto,1 Manual
StandBy steps position - compressor OFF (I153) steps
StandBy delay (I309) s
Defrost steps (I103) steps
EEV Heating capacity (I165) %
EEV Cooling capacity (I164) %
EEV Defrost capacity (I166) %
EEV Automatic calculation result (I310) %
Control type mode (I191): 0 DGT,1 SGT,2 DGT/SGT,3 SDGT/SGT
DGT mode (D53): 0 EVD EVO automatic control,1 pCO5 custom (manual) control
S4 time (A482)
Actual control mode (D47): 0 Suction superheat,1 Discharge superheat
DGT temperature - Reference A (A483) °C
Requested discharge superheat A20 (A29) °C
Requested discharge superheat A50 (A30) °C
DGT temperature - Reference B (A484) °C
Requested discharge superheat B20 (A31) °C
Requested discharge superheat B50 (A32) °C
CT source (D54): 0 Discharge T (condensing temperature),1 Water (heating water temperature)
Inverter correction (A485) °C
DSHeat set - actual (A8) °C
DGT set - actual (A486) °C
EEV control proportional band (A26) °C
EEV control integration time (I3) s
EEV control derivation time (I2) s
PID control period (I311) ms
DGT Begin Time (I1) s
Defrost set (A25) %
EEV manual position during DGT mode (A9) %
DGT DSht (A17) °C
SGT DSht (A18) °C
Current mode (D45): 0 SGT,1 DGT
Superheat (A174) °C   [SGT MOP]
MOP HT (A169) °C
MOP CO (A168) °C
MOP DF (A170) °C
MOP alarm delay (I155) s
MOP Ti (A487) s
LOP Heating (A166) °C
LOP Cooling (A165) °C
LOP alarm delay (I154) s
LOP Ti (A488) s
SHL (A177) °C
SHL alarm delay (I156) s
SHL Ti (A489) s
StSht (A181) °C  requested suction superheat
StDSht (A8) °C
PV (I169) steps  EEV position
Power (I167) %   EEV power/opening %
Evd Evolution control type (I312): 1 SGT,2 DSheat,3 DGT
DGT Control (D340)
EEVDGTON (D341)
EEVDGTMan (D342)
A - Actual discharge superheat (A7) °C
R - Requested discharge superheat (A8) °C
O - Actual PID output of DGT control in % opening of valve (A490) %
PID control of DGT active (D343)
EEVSDGTON (D344)
O - Actual PID output of SDGT control in % opening of valve (A491) %
PID control of SDGT active (D346)
```

## Configuration (aid 19)

```
Heat pump type (I14): 0 Air/Water,1 Brine/Water,2 Water/Water,3 Direct evaporation/Water,4 A/W Reversible,5 B/W Reversible,6 W/W Reversible
Number of compressors (D40): 0 one,1 two
Number of refrigerant circuits (D39)
Hydraulic type of the unit (I208): 0 Mini,1 Mini SHW,2 Aku
Pump circulation time (I8) s
Compressor OFF time (I7) s
Compressors rotation (D206)
Delay of the 2nd compressor start (I209) s
Pump before compressor (I9) s
Pump after compressor (I10) s
Remote ON/OFF compressor (D75), auxiliary heater (D74), sanitary hot water (D76)
Maximum time in SHW mode (I53) min
Minimum time in H/C mode (I54) min
Total compressor starts (I12) x10
Service compressor operating hours (I11) h
Pump runtime (I13) h
Total heater 1 operating time (I100) h
Total heater 2 operating time (I101) h
Heat pump ID (I72)
SW release (I104)
```

## Pump settings (aid 20) - hot side pump

```
Pump start time before compressor start (I9) s
Pump stop time after compressor stop (I10) s
Type of the pump run (D1): 0 Compressor,1 Permanent
Minimum speed heating (A157) %
Maximum speed heating (A158) %
Minimum speed cooling (A496) %
Maximum speed cooling (A497) %
Water temperature to start antifreeze function (A498) °C
Outdoor air temperature to start antifreeze function (A201) °C
Pump alarm (D31): 0 Disabled,1 Enabled
Pump alarm time delay (I55) s
Pump alarm active (1=Alarm) (D385)
Manual pump activation (0% = AUTO) (A499) %
```

## Fan / Brine pump Settings (aid 21)

```
Fan/brine pump start time before compressor start (I30) s
Fan/brine pump stop time after compressor stop (I31) s
Minimum speed heating (A56) %
Maximum speed heating (A58) %
Evaporating temp. for minimum speed in EvapT control mode (A446) °C
Evaporating temp. for maximum speed in EvapT control mode (A447) °C
Control type (D439): 0 Related to compressor speed,1 Related to evaporating temperature
Minimum speed cooling (A60) %
Maximum speed cooling (A62) %
Temperature for minimum speed (A61) °C
Temperature for maximum speed (A63) °C
Start temperature cooling on/off (A65) °C
Stop temperature (A64) °C
Start temperature in manual defrost mode (A493) °C
Proportional Band (A494) °C
Integration time (I78) s
Derivative time (I76) s
Periodic run (D78)
Periodic on time (I414) s
Fan periodic run off time (I415) s
Starting from outdoor temperature (I416) °C
Manual speed (0% = AUTO) (A11) %
```

## Defrost Settings (aid 22) - A/W only

```
Outdoor reference temperature point A (A66) °C
Difference to start defrost min capacity A (A68) °C
Difference to start defrost max capacity A (A57) °C
Outdoor reference temperature point B (A67) °C
Difference to start defrost min capacity B (A69) °C
Difference to start defrost max capacity B (A59) °C
Activation delay (I45) s
Forced difference outdoor +10°C (A72) °C
Forced difference outdoor -20°C (A22) °C
Forced defrost activation delay (I38) s
Forced defrost - actual calculated difference to start (A23) °C
Enabled below outdoor temperature (A70) °C
Condensing temperature to end defrost (A71) °C
Heater activation water temp (A73) °C
Minimum time between two cycles (I32) min
Reversing valve and compressor delay (I34) s
Compressor OFF period after defrost end (I323) s
PT Swap Delay (I324) s
Maximum duration of defrost cycle (I33) min
Fan run time after defrost end (I102) s
SHW mode activation during defrost (D44)
Time from last defrost cycle (I35) min
Manual start of defrost cycle (D386)
```

## Speed Settings (aid 27)

```
Actual heating (or cooling) water temperature (A1) °C
Requested water temperature for speed control (A5) °C
Requested compressor speed (A450) rps
Real Requested compressor speed, considering speed limitations and speed timing (A159) rps
Manual requested speed of compressor (0=AUTO) (A148) rps
Outdoor temperature reference point A (A130) °C; min speed A (A132) rps; max speed A (A133) rps
Outdoor temperature reference point B (A131) °C; min speed B (A134) rps; max speed B (A135) rps
Maximum speed in generating hot water (SHW) (A16) rps
Minimum speed for cooling mode (A451) rps; Maximum speed for cooling mode (A452) rps
Offset from water setpoint for speed control heating (A429) °C; cooling (A430) °C
Speed PID: Proportional band (A136) °C, Integration time (I114) s, Derivation time (I113) s, PID control period (I115) ms, Direction (D80)
Defrost speed: min (A138) rps, max (A139) rps, manual (A137) rps, Defrost mode (D81) 0 Manual/1 Automatic
Requested evaporating temp. for speed control in defrost mode (A153) °C
Real evaporating temperature (A80) °C
Output of the defrost speed control (A159) rps
Defrost PID: A152, I118, I117, I119
Compressor start speed (A453) rps; Time to maintain starting speed (I120) s
Step of compressor speed change (A454) rps; Minimum time to maintain compressor speed (I124) s
Minimum compressor speed limit (A455) rps; Maximum compressor speed limit (A456) rps
Minimal speed limit for alarm activation (A105) rps; alarm delay (I417) s
Minimal pressure difference limit for alarm activation (A100) bar; alarm delay (I419) s
DRIVE STATUS
Request to start refrigeration circuit (D410)
Request to run the compressor (D411)
Requested compressor speed (A159) rps
Real compressor speed (A475) rps
Compressor voltage (I295) V
Compressor current (A476) A
Compressor power (A477) kW
DC drive voltage (I296) V
Drive temperature (I297) °C
Drive status: 0 Stop, 1 Run, 2 Alarm (I298)
Drive alarm code (I299)
COMPRESSOR MAP speed profiles 1-6: discharge pressure reference (A457-A462) bar, min speed (A463-A468) rps, max speed (A469-A474) rps
Brine control (D419) 0 DISABLED/1 ENABLED
Minimum speed limit for brine control (A437) rps; Maximum (A438) rps
Brine temperature control setpoint (A434) °C
Actual brine temperature (A433) °C
Result of brine temp. control speed limitation (A439)
```

## Room terminals (aid 28)

```
pAD01: Enabling (D182), Active (D242), ON/OFF (I16) 0 OFF/2 ON, Mode (I181) 0 None/1 Winter/2 Summer,
  Room setpoint (A191) °C, Actual room temperature (A190) °C, Actual room relative humidity (I185) %,
  Sleep mode setpoint (A263), hysterezis heating (A194), cooling (A195), Alarm temp probe (D198), Alarm humidity probe (D199)
pAD11: Enabling (D244), Active (D245), ON/OFF (I15), Mode (I218), setpoint (A219), actual (A220), humidity (I219), sleep (A264), hyst (A265/A266)
pAD12: Enabling (D247), Active (D248), ON/OFF (I6), Mode (I217), setpoint (A225), actual (A226), humidity (I220), sleep (A267), hyst (A268/A269)
pAD13: Enabling (D250), Active (D251), ON/OFF (I227), Mode (I228), setpoint (A231), actual (A232), humidity (I229), sleep (A270), hyst (A271/A272)
pAD14: Enabling (D253), Active (D254), ON/OFF (I230), Mode (I237), setpoint (A238), actual (A239), humidity (I238), sleep (A273), hyst (A274/A275)
pAD15: Enabling (D256), Active (D257), ON/OFF (I239), Mode (I240), setpoint (A247), actual (A248), humidity (I247), sleep (A276), hyst (A431/A432)
pAD16: Enabling (D258), Active (D259), ON/OFF (I210), Mode (I248), setpoint (A256), actual (A257), humidity (I249), sleep (A277), hyst (A278/A279)
Note: main circuit room temp on our unit is A211 (Heating settings: "Actual room temperature (A211)"), requested A210 (cloud map).
```

## Heating settings (aid 29) - main heating circuit

```
Point A outdoor (A35) °C, water (A37) °C; Point B outdoor (A36) °C, water (A38) °C
pAD01 Active status (D242)
Actual room temperature (A211) °C
Result of room compensation on requested heating water temperature (A198) °C
Maximum/Minimum water temperature compensation in heating mode (A196) °C
Room temperature proportional band for water compensation (A200) °C
Integration time of the water compensation (I180) s
Minimum water temperature limit for the unit setpoint (A299) °C
Maximum water temperature limit for the unit setpoint (A207) °C
Minimum Air temperature limit (A300) °C; Maximum Air temperature limit (A301) °C
Compressor control hysterezis (A43) °C
Negative offset of the Compressor 2 setpoint (A302) °C
Compressor operation limit for heating water 30°C (A44) °C; for 50°C (A45) °C
Actual calculated limit (A46) °C
Outdoor temperature limit for enabling auxiliary heater (A39) °C
Actual value of calculated missing heat integration (A10) °C*min
Heater control hysterezis (A27) °C; Heater setpoint offset from compressor setpoint (A28) °C
Integral activation (A40) °C*min; Integral deactivation (A41) °C*min
Antifreeze water setpoint for aux heater heating (A42) °C; cooling (A151) °C
Delay of the second heater stage (I5)
Control logic type (D30): 0 Setpoint +/- hysterezis,1 Setpoint - hysterezis
Delta T (integration step) (A303) °C; Geometric time (I43) s
Actual outdoor temperature (A3) °C
Actual geometric temperature (A34) °C
Outdoor temperature for activation of winter mode (A82) °C; summer mode (A83) °C
Enabling manual heating mode (D211); Manual heating water temperature setpoint (A214) °C
```

## Heating circuit 1 (aid 30)

```
Heating circuit 1 ON/OFF (D212)
Mode (I269): 0 Heating,1 Cooling,2 Auto,3 pAD
Requested room temperature (A215) °C
Actual room temperature (A216) °C
Requested water temperature (A96) °C
Actual water temperature (A90) °C   (own HC1 probe on AQ90I; on our unit mirrors A77)
Circulation pump output (D68)
Mixing valve servo position (A20) %
Water constant temperature mode heating (D215), setpoint (A218) °C; cooling (D214), setpoint (A217) °C
Heating curve: point A outdoor (A101), water (A106); point B outdoor (A102), water (A107)
Cooling curve: point A outdoor (A314), water (A315); point B outdoor (A316), water (A317)
Max/Min heating compensation (A327); cooling (A328); proportional band (A329)
Actual compensation heating (A325); cooling (A326)
Offset for heating (A318); cooling (A319)
Enabling of heating circuit 1 (D278)
HC1 type (I62): 0 None,1 Mixing UFH/Rad,2 Thermostatic,3 Hot water (SHW)
Heating hysterezis (A103); Cooling hysterezis (A320)
SHW priority (D61); Pool priority (D279)
PID: Proportional band (A104), Integration time (I61), Derivation time (I60), Reverse servo (D280)
Manual servo position (A321) %; Manually turn on the digital output (D281)
Heating run (D282); Cooling run (D283); AND logic (I391); Group management (D284)
HC1 group number (I275); HC1 group ON/OFF (D285); Group 1 active (D286); Group 2 active (D287)
Dew point protection (D288); active (D289); Dew point offset (A322)
Actual relative humidity (I219) %
DewPoint calculated (A323) °C; Water temperature limit from DewPoint (A324) °C
```

## Alarm settings (aid 38)

```
Antifreeze alarm heating mode (A52) °C; cooling mode (A150) °C
Low pressure alarm setpoint (A76) bar; hysterezis (A125) bar; delay (I18) s
High pressure alarm setpoint (A74) bar; hysterezis (A492) bar
Low pressure on high pressure side setpoint (A75) bar
Low evaporating temperature alarm heating (A54) °C; cooling (A128) °C; delay (I319) s
High condensing temperature alarm heating (A53) °C; cooling (A127) °C; delay (I320) s
High discharge gas temperature setpoint (A55) °C
Bypassing flow switch time after pump/submersible pump start (I17) s
Type of relay alarm activation (D384): 0 Some Error,1 Manual Reset Required
```

## Cooling settings (aid 39) - incl. passive cooling

```
Cooling curve: point A outdoor (A47), water (A49); point B outdoor (A48), water (A50)
pAD01 Active status (D242); Actual room temperature (A211) °C
Result of room compensation on requested cooling water temperature (A199) °C
Max/Min water temperature compensation in cooling mode (A197) °C; proportional band (A200) °C; integration (I180) s
Minimum water temperature limit (A305) °C; Maximum (A306) °C; Min air (A307) °C; Max air (A308) °C
Compressor control hysterezis cooling (A51) °C; Positive offset of the Compressor 2 setpoint (A309) °C
Antifreeze water setpoint for aux heater in cooling mode (A151) °C
Actual relative humidity measured by pGDx (or pAD01) (I185) %
Calculated dew point (A13) °C; Water temperature limit from dew point (A310) °C; Dew point offset (A14) °C
Current state of dew point protection (D197); Enabling dew point protection (D196)
Enabling passive cooling function (D276); Passive cooling mode (D84): 0 Heat recovery,1 Cooling
Brine pump ON circulation time (I105) s; Brine pump OFF cycle (I106) s
Actual water temperature measured by probe (A311) °C  (passive cooling control probe; mirrors A1 on our unit)
Requested water temperature (A312) °C
Brine pump run (D277)
Actual brine pump speed (A313) %
Enabling brine temperature control (D415); Brine temperature control setpoint (A434) °C; hysterezis (A435) °C
Actual brine temperature (A433) °C
Brine control function output (D417); Brine pump run type (D416): 0 Compressor,1 Permanent
Brine pump speed when compressor is Off by brine control and permanent run (A436)
Summer mode activation temperature (A83) °C
```

## Sanitary hot water (aid 40)

```
Actual sanitary hot water temperature (A126) °C
SHW setpoint (A129) °C
SHW ON/OFF (D29)
Push SHW (SW50+) (D166); Push SHW duration (I44) hours
Enabling scheduler (D88)
Enabling SHW function (D275)
Hysterezis (A12) °C
Minimum hot water setpoint limit (A296) °C; Maximum (A297) °C
Offset for heating water temperature setpoint (A298) °C
Maximum time the unit generates hot water (I53) min
Minimum time in heating/cooling before returning to hot water (I54) min
Delay of heating water setpoint after hot water mode stop (I71) s
Enabling antilegionella (D425); Function actually active (D426)
Setpoint of hot water for antilegionella (A443) °C
Day of the week antilegionella (I397): 0 Daily,1 Mon..7 Sun; start hour (I398); stop hour (I399)
Enabling solar period (D437); active (D438); start month (I400); stop month (I401); start hour (I402); stop hour (I403)
```

## Enabled functions (aid 41)

```
pGDx (I79): 0 DISABLED,1 ENABLED - Main HC,2 DISABLED - pGDx panel version,11 ENABLED - HC1,12 ENABLED - HC2
pAD01 (D182), pAD11 (D244), pAD12 (D247), pAD13 (D250), pAD14 (D253), pAD15 (D256), pAD16 (D258)
SHW (D275), Pool (D348), Solar (D433), Passive cooling (D276), Group management (D284)
HC1 (D278), HC2 (D436), HC3 (D298), HC4 (D307), HC5 (D316), HC6 (D326)
HTP (D260), UT1 (D263), UT2 (D266), UT3 (D269), DT4 (D271)
```
