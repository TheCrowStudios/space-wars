extends Node


enum BulletType {
	LIGHT,
	MEDIUM,
	HEAVY,
	PELLET,
	SLUG,
	POWER_BEAM
}

const bulletPenetrations = {BulletType.LIGHT: 4, BulletType.MEDIUM: 8, BulletType.HEAVY: 15, BulletType.PELLET: 1, BulletType.SLUG: 30, BulletType.POWER_BEAM: 100}
const DEBUG: bool = false