extends Node
## 粒子特效管理器
## 单例，用于在游戏中播放各种粒子特效

const HitParticlesScript = preload("res://scripts/vfx/hit_particles.gd")
const DeathParticlesScript = preload("res://scripts/vfx/death_particles.gd")
const PickupParticlesScript = preload("res://scripts/vfx/pickup_particles.gd")

## 播放攻击命中粒子
func play_hit_effect(position: Vector3) -> void:
	var particles = CPUParticles3D.new()
	particles.set_script(HitParticlesScript)

	# 添加到场景树根节点
	get_tree().root.add_child(particles)

	# 播放
	particles.play_at(position)

## 播放敌人死亡粒子
func play_death_effect(position: Vector3) -> void:
	var particles = CPUParticles3D.new()
	particles.set_script(DeathParticlesScript)

	get_tree().root.add_child(particles)
	particles.play_at(position)

## 播放道具拾取粒子
func play_pickup_effect(position: Vector3, is_gold: bool = true) -> void:
	var particles = CPUParticles3D.new()
	particles.set_script(PickupParticlesScript)

	get_tree().root.add_child(particles)

	var type = PickupParticlesScript.ParticleType.GOLD if is_gold else PickupParticlesScript.ParticleType.GREEN
	particles.play_at(position, type)

## 播放金币拾取粒子
func play_coin_pickup(position: Vector3) -> void:
	play_pickup_effect(position, true)

## 播放药水拾取粒子
func play_potion_pickup(position: Vector3) -> void:
	play_pickup_effect(position, false)
