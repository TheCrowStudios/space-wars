extends Node


enum BulletType {
	LIGHT,
	MEDIUM,
	HEAVY,
	PELLET,
	SLUG,
	POWER_BEAM
}

const bulletDamages = {BulletType.LIGHT: 10, BulletType.MEDIUM: 20, BulletType.HEAVY: 30, BulletType.PELLET: 4, BulletType.SLUG: 50, BulletType.POWER_BEAM: 20}
const bulletPenetrations = {BulletType.LIGHT: 4, BulletType.MEDIUM: 8, BulletType.HEAVY: 15, BulletType.PELLET: 1, BulletType.SLUG: 30, BulletType.POWER_BEAM: 100}
const bulletMaxPenetration = {BulletType.LIGHT: 60, BulletType.MEDIUM: 100, BulletType.HEAVY: 200, BulletType.PELLET: 30, BulletType.SLUG: 100, BulletType.POWER_BEAM: 1000}
const DEBUG: bool = false