extends "res://scripts/characters/cat_sculpt.gd"
## EXPERIMENT (18 Nov 2026): Miso with limbs moved toward the five reference characters' band
## (shoulder 1.16–1.22 except Leo, mitten size 0.9–1.0, round feet 0.18–0.22 wide). Face, body,
## ears, tail and colours are the production sculpt's; only arm height / size and paw size change.
## Production: cat_sculpt.gd. Notes: arms 1.08 / 0.85 -> 1.15 / 0.92, paws x1.08.

const ARM_Y := 1.15
const ARM_SIZE := 0.92
const PAW_SCALE := 1.08


func _mitten_arm(sign_x: float, y: float, size: float, material: Material, z: float = 0.0) -> ArrayMesh:
	return super._mitten_arm(sign_x, ARM_Y, ARM_SIZE, material, z)


func _mitten_tip(sign_x: float, y: float, size: float) -> Vector3:
	return super._mitten_tip(sign_x, ARM_Y, ARM_SIZE)


func _paw(sign_x: float, x: float, z: float, height: float, rx: float, rz: float, material: Material) -> ArrayMesh:
	return super._paw(sign_x, x, z, height, rx * PAW_SCALE, rz * PAW_SCALE, material)
