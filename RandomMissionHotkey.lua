if managers.player then
    if Network:is_server() and TimerManager and TimerManager:game() and
        (managers.player._random_mission_hotkey_t == nil or ((TimerManager:game():time() - managers.player._random_mission_hotkey_t) > 5)) and
        managers.player:local_player_in_camp() and managers.raid_job and managers.progression and managers.raid_job:is_camp_loaded() and
        not (managers.raid_job:current_job() and managers.raid_job:current_job().job_type == OperationsTweakData.JOB_TYPE_OPERATION) then
        managers.player._random_mission_hotkey_t = TimerManager:game():time()

        -- check operation unlock status
        local unlocked_through_operations = {}
        if managers.progression:operations_unlocked() then
            for _, mission_name in pairs(tweak_data.operations:get_operations_index()) do
                local operation = tweak_data.operations.missions[mission_name]
                if operation.events then
                    for event_id, _ in pairs(operation.events) do
                        if not unlocked_through_operations[event_id] then
                            unlocked_through_operations[event_id] = true
                        end
                    end
                end
            end
        end

        local function is_unlocked_raid(job_type, job_id)
            return (job_type == OperationsTweakData.JOB_TYPE_RAID) and
                (unlocked_through_operations[job_id] or managers.progression:mission_unlocked(OperationsTweakData.JOB_TYPE_RAID, job_id))
        end

        -- build random mission pool, respecting unlock status
        local mission_pool = {}
        for _, tbl in pairs(tweak_data.operations.missions.random_long.events_index_template) do
            for _, job_id in ipairs(tbl) do
                if not table.contains(mission_pool, job_id) then
                    local job_data = tweak_data.operations.missions[job_id]
                    if job_data and is_unlocked_raid(job_data.job_type, job_id) and not job_data.consumable then
                        table.insert(mission_pool, job_id)
                    end
                end
            end
        end

        -- pick random mission and start it up
        local job_id = table.random(mission_pool)
        managers.challenge_cards:remove_active_challenge_card()
        managers.network:session():chk_server_joinable_state()
        managers.network:update_matchmake_attributes()
        managers.raid_job._next_event_index = nil
        managers.raid_job:set_selected_job(job_id, tweak_data.operations:mission_data(job_id))

        managers.raid_menu:close_all_menus()
        return
    end

    -- no player unit while in the main menu or loading
    local player = managers.player:local_player()
    if player then
        player:sound():play("generic_fail_sound")
    end
end
