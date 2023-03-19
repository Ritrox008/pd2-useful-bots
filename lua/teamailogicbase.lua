local tmp_vec = Vector3()
Hooks:PostHook(TeamAILogicBase, "_set_attention_obj", "_set_attention_obj_ub", function (data, att, react)
	if not att or not att.verified or not react then
		return
	end

	-- early abort
	if data.cool or data.internal_data.acting or data.objective and data.objective.type == "revive" then
		return
	end

	if data.unit:movement():chk_action_forbidden("action") or data.unit:anim_data().reload or data.unit:character_damage():is_downed() then
		return
	end

	if not alive(att.unit) or not att.unit:character_damage() or att.unit:character_damage():dead() then
		return
	end

	mvector3.set(tmp_vec, att.unit:movement():m_head_pos())
	mvector3.subtract(tmp_vec, data.unit:movement():m_head_pos())
	if tmp_vec:angle(data.unit:movement():m_rot():y()) > 50 then
		return
	end

	-- intimidate
	if react == AIAttentionObject.REACT_ARREST and (not data._next_intimidate_t or data._next_intimidate_t < data.t) then
		local key = att.unit:key()
		local intimidate = TeamAILogicIdle._intimidate_progress[key]
		if not intimidate or intimidate + 1 < data.t then
			TeamAILogicIdle.intimidate_cop(data, att.unit)
			TeamAILogicIdle._intimidate_progress[key] = data.t
			data._next_intimidate_t = data.t + 2
			return
		end
	end

	-- mark
	if UsefulBots.settings.mark_specials and (not data._next_mark_t or data._next_mark_t < data.t) then
		if att.char_tweak and att.char_tweak.priority_shout and not att.unit:contour():find_id_match("^mark_enemy") then
			if att.unit:character_damage():health_ratio() > 0.5 and att.dis <= tweak_data.player.long_dis_interaction.highlight_range then
				if not TeamAILogicIdle.is_high_priority(att.unit:movement()) then
					if not World:raycast("ray", data.m_pos, att.m_pos, "slot_mask", managers.slot:get_mask("AI_visibility"), "report") then
						TeamAILogicAssault.mark_enemy(data, data.unit, att.unit)
						att.mark_t = data.t
						data._next_mark_t = data.t + 16
						return
					end
				end
			end
		end
	end
end)

Hooks:PostHook(TeamAILogicBase, "on_new_objective", "on_new_objective_ub", function (data)
	local objective = data.objective
	if not objective then
		return
	end

	if objective.type == "follow" then
		data._latest_follow_unit = objective.follow_unit
	end

	if objective.type == "revive" or objective.assist_unit then
		data.brain:action_request({
			body_part = 3,
			type = "idle",
			skip_wait = true
		})
	end
end)

-- This function is disabled in vanilla but is not part of TeamAILogicBase so it might crash in other logics when called with data.logic._upd_sneak_spotting
function TeamAILogicBase._upd_sneak_spotting() end

-- This may be called due to enemy detection update in logics that don't have this function so add it to base
function TeamAILogicBase.chk_should_turn() end
