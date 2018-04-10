# Installation
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
Take the scripts folder and merge it into your mission file.
#### Installation Completed!

# Optional
##### If you wish to set the owner of a vehicle as soon as it is purchased:
In \z\addons\dayz_server\compile\server_publishVehicle2.sqf, find the following:
```
_object call fnc_veh_ResetEH;
```
Below it, add the following:
```
_object setVariable ["Owner", _playerUID, true];
```