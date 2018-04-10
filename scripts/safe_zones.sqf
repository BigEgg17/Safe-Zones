/*
	File: safe_zones.sqf
	Creates safe zones in predefined areas (DZE_SafeZonePosArray)

	Author: BigEgg
	https://github.com/BigEgg17
*/

private ["_bubbles", "_limitSpeed", "_speedLimit", "_preventTheft", "_timer", "_disableWeps", "_badWeps"];

/**************************************************** Config ****************************************************/
_bubbles = true; // Creates a circle of bubbles marking the circumference of the safe zone.
_limitSpeed = true; // Limits the speed of vehicles in the safe zone.
_speedLimit = 30; // Speed limit in safe zones. Only used if _limitSpeed = true.
_preventTheft = true; // Prevent vehicles from being stolen by assigning them an owner (this includes gear).
_timer = 10; // Delay ending safe zone protection for this many seconds upon leaving. Set to 0 to disable timer.

_disableWeps = true; // Drops any weapons in _badWeps array.
_badWeps = [ // Will remove these weapons from the player if they try to select them. Only used if _disableWeps = true.
	"Vil_RPG29", "Vil_RPO_A", "Vil_RPG16", "Vil_RPG7V_PGO", "Vil_Panzerfaust3", "M136", "RPG7V", "vil_CG84T", "vilas_rpg22", "vilas_rpg26", "MAAWS", "Vil_RPG7d_PGO",
	"RPG18", "MeleeHatchet", "MeleeCrowbar","MeleeMachete", "MeleeFishingPole", "MeleeSledge", "MeleeBaseBallBatNails", "MeleeBaseBallBatBarbed", "MeleeBaseBallBat"
];
/****************************************************************************************************************/

if (isServer && {_bubbles}) then {
	private "_count";

	_count = 0;
	{
		private ["_pos", "_rad"];

		_pos = _x select 0;
		_rad = _x select 1;

		for "_i" from 0 to 360 step (1440 / _rad) do
		{
			private ["_loc", "_obj"];
			
			_loc = [(_pos select 0) + ((cos _i) * _rad), (_pos select 1) + ((sin _i) * _rad), 0];

			_obj = "Sign_sphere100cm_EP1" createVehicle [0,0,0];
			_obj setPosATL _loc;

			_count = _count + 1;
		};
	} count DZE_SafeZonePosArray;

	diag_log format["INFO: Created %1 safe zone bubbles", [_count] call BIS_fnc_numberText];
};

if (!isDedicated) then {
	private ["_enter", "_exit"];

	safezone_enabled = false;
	safezone_count = 0;

	_enter = {
		private "_msg";

		safezone_enabled = true;
		isInTraderCity = true;
		canbuild = false;
		safezone_time = diag_tickTime;

		if (!DZE_BackpackAntiTheft) then {DZE_BackpackAntiTheft = true;};

		_msg = "You entered a safe zone!";
		taskHint [_msg, [0,1,0,1], "taskDone"];
		_msg call dayz_rollingMessages;

		if (_preventTheft) then {
			private "_vehicle";

			_vehicle = vehicle player;

			if (isNil "fn_gearMenuChecks1") then { // Make sure vehicle gear checks aren't already disabled
				fn_gearMenuChecks1 = fn_gearMenuChecks;
			};

			if (_vehicle != player) then { // Reset owner when entering
				if (driver _vehicle == player) then {
					_vehicle setVariable ["Owner", "0", true];
				};
			};
			
			fn_gearMenuChecks = { // Prevent player from accessing gear of vehicles that aren't their's
				if (vehicle player == player) then {
					private ["_cursorTarget", "_dis"];
					disableSerialization;
					
					_display = _this select 0;
					_cursorTarget = cursorTarget;
					_dis = if (_cursorTarget isKindOf "USEC_ch53_E" || {_cursorTarget isKindOf "MV22"}) then {25} else {12};
					
					if ((player distance _cursorTarget <= _dis) && {_cursorTarget isKindOf "Air" || {_cursorTarget isKindOf "LandVehicle"} || {_cursorTarget isKindOf "Ship"}}) then {
						private ["_owner", "_deny"];
						
						_owner = _cursorTarget getVariable ["Owner", "0"];
						
						// Allow group members of the owner to access gear
						_deny = true;
						{
							if (getPlayerUID _x == _owner) exitWith {_deny = false;};
						} count (units group player);
						
						if (_deny) then {
							_display closeDisplay 2;
							"You cannot open the gear of another player's vehicle!" call dayz_rollingMessages;
						};
					};
				};
				
				// Pass array on to normal gearMenuChecks
				_this call fn_gearMenuChecks1;
			};
		};

		if (isNil "fnc_usec_damageHandler1") then {
			fnc_usec_damageHandler1 = fnc_usec_damageHandler;
		};
		fnc_usec_damageHandler = {0}; // God mode

		if (isNil "player_zombieCheck1") then {
			player_zombieCheck1 = player_zombieCheck;
		};
		player_zombieCheck = {false}; // No zombie aggro

		if (isNil "player_fired1") then {
			player_fired1 = player_fired;
		};
		player_fired = { // Block firing in safe zone
			deleteVehicle (_this select 6);
			cutText ["You cannot fire your weapon in a safe zone!", "WHITE IN"];
		};

		[_limitSpeed, _speedLimit, _disableWeps, _badWeps, _preventTheft] spawn {
			while {safezone_enabled} do
			{
				private "_vehicle";

				_vehicle = vehicle player;

				if (_this select 2) then {
					private "_currentWeapon";

					_currentWeapon = currentWeapon player;

					if (_currentWeapon in (_this select 3)) then {
						player action ["dropWeapon", player, _currentWeapon]; // Drops the weapon and the ammo for it
					};
				};

				if (_vehicle != player) then {
					// Speed Limit
					if (_this select 0) then {
						if !(_vehicle isKindOf "Air") then {
							private "_speed";

							_speed = abs(speed _vehicle);

							if (_speed > (_this select 1)) then {
								private ["_velocity", "_mod"];

								_velocity = velocity _vehicle;
								_mod = if (_speed > 50) then {0.1} else {0.8};

								_vehicle setVelocity [(_velocity select 0) * _mod, (_velocity select 1) * _mod, (_velocity select 2) * _mod];
							};
						};
					};
					// Remove player from vehicle if they lack ownership or aren't in owner's group
					if (_this select 4) then {
						private ["_owner", "_deny"];

						_owner = _vehicle getVariable ["Owner", "0"];

						if (driver _vehicle == player && {_owner == "0"}) then { // Set an owner if one doesn't exist
							_vehicle setVariable ["Owner", getPlayerUID player, true];
							"You have been set as this vehicle's owner." call dayz_rollingMessages;
							_owner = _vehicle getVariable ["Owner", "0"];
						};

						_deny = true;
						{
							if (getPlayerUID _x == _owner) exitWith {_deny = false;};
						} count (units group player);

						if (_deny) then {
							player action ["Eject", _vehicle];
						};
					};
					// Prevent player from firing vehicle guns in safe zone
					if !(_vehicle getVariable ["safezoneEH", false]) then {
						_vehicle setVariable ["safezoneEH", true];
						_vehicle addEventHandler ["Fired", {_this call player_fired}];
					};
				};

				// Prevent player from being unconscious in safe zone
				{
					player setVariable [_x, false, false];
				} count ["NORRN_unconscious", "USEC_isCardiac"];

				r_player_unconscious = false;
				r_player_cardiac = false;

				uiSleep 0.1;
			};
		};
	};

	_exit = {
		private ["_msg", "_time", "_vehicle"];

		safezone_enabled = false;
		isInTraderCity = false;
		canbuild = true;

		_msg = "You left the safe zone!";
		taskHint [_msg, [1,0,0,1], "taskFailed"];
		_msg call dayz_rollingMessages;

		_time = diag_tickTime - safezone_time;
		_vehicle = vehicle player;

		if (_timer > 0) then {
			if (_time >= 60) then {
				if (_vehicle != player) then {
					[_vehicle, _timer] spawn {
						(_this select 0) setVariable ["sz_immunity", true, true];
						uiSleep (_this select 1);
						(_this select 0) setVariable ["sz_immunity", false, true];
					};
				};
				for "_x" from _timer to 1 step -1 do
				{
					[format["Protection ending in %1 second(s)!", _x], 1] call dayz_rollingMessages;
					uiSleep 1;
					if ({_vehicle distance (_x select 0) <= (_x select 1)} count DZE_SafeZonePosArray > 0) exitWith {};
				};
			} else {
				format["You were only in the safe zone for %1 second(s)!", round _time] call dayz_rollingMessages;
			};
		};

		"Protection disabled!" call dayz_rollingMessages;

		fnc_usec_damageHandler = fnc_usec_damageHandler1;
		player_zombieCheck = player_zombieCheck1;
		player_fired = player_fired1;
		if (_preventTheft) then {
			fn_gearMenuChecks = fn_gearMenuChecks1;
		};

		if (_vehicle != player) then {
			_vehicle setVariable ["safezoneEH", false];
			_vehicle removeAllEventHandlers "Fired";
		};
	};

	while {69 == 69} do
	{
		private "_vehicle";

		_vehicle = vehicle player;

		if (!safezone_enabled) then {
			if ({_vehicle distance (_x select 0) <= (_x select 1)} count DZE_SafeZonePosArray > 0) then {
				call _enter;
			};
		} else {
			if !({_vehicle distance (_x select 0) <= (_x select 1)} count DZE_SafeZonePosArray > 0) then {
				call _exit;
			};
		};

		uiSleep 1;
	};
};

// Needed on both client and server for vehicle protection
fnc_veh_handleDam2 = fnc_veh_handleDam;
fnc_veh_handleDam = {
	if ({(_this select 0) distance (_x select 0) <= (_x select 1)} count DZE_SafeZonePosArray > 0 || {(_this select 0) getVariable ["sz_immunity", false]}) exitWith {0};
	_this call fnc_veh_handleDam2;
};