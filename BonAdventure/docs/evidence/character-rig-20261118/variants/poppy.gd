extends "res://scripts/characters/sheep_sculpt.gd"
## EXPERIMENT (18 Nov 2026): Poppy with limbs moved toward the five reference characters' band
## (shoulder 1.16–1.22 except Leo, mitten size 0.9–1.0, round feet 0.18–0.22 wide). Face, body,
## ears, tail and colours are the production sculpt's; only arm height / size and paw size change.
## Production: sheep_sculpt.gd. Notes: arms 1.04 / 0.72 -> 1.13 / 0.86 (hooves were buried low in the wool), paws x1.18.

const ARM_Y := 1.13
const ARM_SIZE := 0.86
const PAW_SCALE := 1.18


func _mitten_arm(sign_x: float, y: float, size: float, material: Material, z: float = 0.0) -> ArrayMesh:
	return super._mitten_arm(sign_x, ARM_Y, ARM_SIZE, material, z)


func _mitten_tip(sign_x: float, y: float, size: float) -> Vector3:
	return super._mitten_tip(sign_x, ARM_Y, ARM_SIZE)


func _paw(sign_x: float, x: float, z: float, height: float, rx: float, rz: float, material: Material) -> ArrayMesh:
	return super._paw(sign_x, x, z, height, rx * PAW_SCALE, rz * PAW_SCALE, material)
