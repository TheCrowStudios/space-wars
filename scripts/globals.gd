extends Node


enum BulletType {
	LIGHT,
	MEDIUM,
	HEAVY,
	PELLET,
	SLUG,
	POWER_BEAM
}

const bulletDamages = {BulletType.LIGHT: 10.0, BulletType.MEDIUM: 20.0, BulletType.HEAVY: 30.0, BulletType.PELLET: 4.0, BulletType.SLUG: 50.0, BulletType.POWER_BEAM: 20.0}
const bulletPenetrations = {BulletType.LIGHT: 4.0, BulletType.MEDIUM: 8.0, BulletType.HEAVY: 15.0, BulletType.PELLET: 1.0, BulletType.SLUG: 30.0, BulletType.POWER_BEAM: 100.0}
const bulletMaxPenetration = {BulletType.LIGHT: 60.0, BulletType.MEDIUM: 100.0, BulletType.HEAVY: 200.0, BulletType.PELLET: 30.0, BulletType.SLUG: 100.0, BulletType.POWER_BEAM: 1000.0}
const DEBUG: bool = true
const BULLET_DEBUG: bool = true