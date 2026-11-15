--!strict
-- WeaponConfig.luau
-- Weapon ballistic parameters, kinetic impulses, and sound settings

local WeaponConfig = {
	Pistol = {
		Name = "Пистолет 9mm (Pistol)",
		Damage = 35,
		HeadshotMultiplier = 2.5,
		FireRate = 0.2, -- seconds between shots
		Range = 300,
		Spread = 0.015,
		ImpulseForce = 45, -- kinetic impulse applied to ragdoll body
		SoundId = "rbxassetid://131070686", -- gunshot
	},
	Shotgun = {
		Name = "Дробовик 12G (Shotgun)",
		DamagePerPellet = 15,
		PelletCount = 8,
		FireRate = 0.85,
		Range = 150,
		Spread = 0.08,
		ImpulseForce = 85, -- massive blast knockback
		SoundId = "rbxassetid://142494488", -- shotgun blast
	},
	PushTool = {
		Name = "Толкатель (Push Hands)",
		Cooldown = 1.0,
		Range = 8,
		ImpulseForward = 65,
		ImpulseUp = 25,
		SoundId = "rbxassetid://138090596", -- whoosh/hit
	},
	RagdollWand = {
		Name = "Жезл Рэгдолла (Ragdoll Wand)",
		Range = 100,
		FlingForce = 120,
		SoundId = "rbxassetid://131237241", -- magic hit
	},
}

return WeaponConfig
