# Safe Zones
Compatible with DayZ Epoch 1.0.6.2 +

## Information
* Uses built in safe zone array (DZE_SafeZonePosArray)
* Allows configuration of a timer when leaving the safe zone
	* Timer can be disabled
	* All protection will remain in place during this time
	* Timer only occurs if the player is in the safe zone for more than 60 seconds
* Allows server owners to prevent theft in safe zones
	*  Driver of the vehicle automatically becomes the owner when they enter
	*  Only group members of the owner and the owner themselves can access the vehicle or its gear
	*  Those who are not in the group of the owner are automatically removed from the vehicle and forbidden from opening its gear
* Allows configuration of a speed limit
* Allows creation of safe zone markers
* Allows server owners to define "bad weapons" that will be removed from players hands
* Basic functionalities:
	* God mode
	* Vehicle god mode
	* Gear protection
	* Prevents firing in safe zone

## Installation

#### **Note:** This script is dependent upon community localizations, which can be found [here](https://github.com/oiad/communityLocalizations).

#### Step 1:
In your init.sqf (mission file), find the following:
```
initialized = true;
```
Right above it, add the following:
```
execVM "scripts\safe_zones.sqf";
```
#### Step 2:
[>> Download Files <<](https://github.com/BigEgg17/Safe-Zones/archive/master.zip "Download Files")

Take the scripts folder and merge it into your mission file.
#### Installation Completed!

## Optional
##### If you wish to set the owner of a vehicle as soon as it is purchased:
In \z\addons\dayz_server\compile\server_publishVehicle2.sqf, find the following:
```
_object call fnc_veh_ResetEH;
```
Below it, add the following:
```
_object setVariable ["Owner", [_playerUID], true];
```
