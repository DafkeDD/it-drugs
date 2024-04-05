if not Config.EnableProcessing then return end

local tablePlacing = false
local proccessing = false

local RotationToDirection = function(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosOfRotX = math.abs(math.cos(rotX))
    return vector3(-math.sin(rotZ) * cosOfRotX, math.cos(rotZ) * cosOfRotX, math.sin(rotX))
end

local RayCastCamera = function(dist)
    local camRot = GetGameplayCamRot()
    local camPos = GetGameplayCamCoord()
    local dir = RotationToDirection(camRot)
    local dest = camPos + (dir * dist)
    local ray = StartShapeTestRay(camPos, dest, 17, -1, 0)
    local _, hit, endPos, surfaceNormal, entityHit = GetShapeTestResult(ray)
    if hit == 0 then endPos = dest end
    return hit, endPos, entityHit, surfaceNormal
end

RegisterNetEvent('it-drugs:client:placeProcessingTable', function(tableItem)
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 then
        ShowNotification(_U('NOTIFICATION__IN__VEHICLE'), "error")
        return
    end

    tablePlacing = true
    local hashModel = GetHashKey(Config.ProcessingTables[tableItem].model)
    RequestModel(hashModel)
    while not HasModelLoaded(hashModel) do Wait(0) end
    
    lib.showTextUI(_U('INTERACTION__PLACING__TEXT'), {
        position = "left-center",
        icon = "spoon",
    })

    local hit, dest, _, _ = RayCastCamera(Config.rayCastingDistance)
    local table = CreateObject(hashModel, dest.x, dest.y, dest.z - Config.ObjectZOffset, false, false, false)
    SetEntityCollision(table, false, false)
    SetEntityAlpha(table, 150, true)
    SetEntityHeading(table, 0.0)

    local placed = false
    local rotation = 0.0
    while not placed do
        Wait(0)
        hit, dest, _, _ = RayCastCamera(Config.rayCastingDistance)

        if hit == 1 then
            SetEntityCoords(table, dest.x, dest.y, dest.z - Config.ObjectZOffset)

            if IsControlJustPressed(0, 14) or IsControlJustPressed(0, 16) then
                rotation = rotation + 1.0
                if rotation >= 360.0 then
                    rotation = 0.0
                end
                SetEntityHeading(table, rotation)
            end

            if IsControlJustPressed(0, 15) or IsControlJustPressed(0, 17) then
                rotation = rotation - 1.0
                if rotation <= 0.0 then
                    rotation = 360.0
                end
                SetEntityHeading(table, rotation)
            end

            if IsControlJustPressed(0, 38) then
                placed = true
                lib.hideTextUI()

                DeleteObject(table)

                RequestAnimDict('amb@medic@standing@kneel@base')
                RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
                while 
                    not HasAnimDictLoaded('amb@medic@standing@kneel@base') or
                    not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@')
                do 
                    Wait(0) 
                end

                TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
                TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false, false, false)


                if lib.progressBar({
                    duration = 5000,
                    label = _U('PROGRESSBAR__PLACE__TABLE'),
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        car = true,
                        move = true,
                        combat = true,
                    },
                }) then
                    TriggerServerEvent('it-drugs:server:createNewTable', dest, tableItem, rotation)
                    tablePlacing = false
                    placed = true
                    ClearPedTasks(ped)
                    RemoveAnimDict('amb@medic@standing@kneel@base')
                    RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
                else
                    ShowNotification(_U('NOTIFICATION_CANCELED'), "error")
                    tablePlacing = false
                    placed = true
                    ClearPedTasks(ped)
                    RemoveAnimDict('amb@medic@standing@kneel@base')
                    RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
                end
            end

            if IsControlJustPressed(0, 47) then
                placed = true
                tablePlacing = false
                lib.hideTextUI()
                DeleteObject(table)
                return
            end
        end
    end
end)

RegisterNetEvent('it-drugs:client:useTable', function(data)
    local netId = NetworkGetNetworkIdFromEntity(data.entity)
    lib.callback('it-drugs:server:getTableData', false, function(result)
        if not result then return end
        TriggerEvent('it-drugs:client:showProcessingMenu', result)
    end, netId)
end)

RegisterNetEvent('it-drugs:client:processDrugs', function(args)
    local entity = args.entity
    local type = args.type
    if proccessing then return end

    local input = lib.inputDialog(_U('INPUT__AMOUNT__HEADER'), {
        {type = 'number', text = _U('INPUT__AMOUNT__TEXT'), desciption = _U('INPUT__AMOUNT__DESCRIPTION'), require = true, min = 1}
    })

    if not input then
        ShowNotification(_U('NOTIFICATION__NO__AMOUNT'), 'error')
        return
    end

    local amount = tonumber(input[1])
    for item, itemAmount in pairs(Config.ProcessingTables[type].ingrediants) do
        if not it.hasItem(item, itemAmount * amount) then
            ShowNotification(_U('NOTIFICATION__MISSING__INGIDIANT'), 'error')
            proccessing = false
            return
        end
    end

    local netId = NetworkGetNetworkIdFromEntity(entity)
    local ped = PlayerPedId()
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    Wait(1500)

    proccessing = true

    RequestAnimDict('amb@medic@standing@kneel@base')
    RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
    while 
        not HasAnimDictLoaded('amb@medic@standing@kneel@base') or
        not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@')
    do 
        Wait(0) 
    end
    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false, false, false)


    if Config.ProccesingSkillCheck then
        for i = 1, amount, 1 do
            local success = lib.skillCheck(Config.SkillCheck.difficulty, Config.SkillCheck.keys)
            if success then
                ShowNotification(_U('NOTIFICATION__SKILL__SUCCESS'), 'success')
                TriggerServerEvent('it-drugs:server:processDrugs', entity)
            else
                proccessing = false
                ShowNotification(_U('NOTIFICATION_SKILL_ERROR'), 'error')
                ClearPedTasks(ped)
                RemoveAnimDict('amb@medic@standing@kneel@base')
                RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
                return
            end
            Wait(1000)
        end
        proccessing = false
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    else
        for i = 1, amount, 1 do
            if lib.progressBar({
                duration = 5000,
                label = _U('PROGRESSBAR__PROCESS__DRUG'),
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true,
                },
            }) then
                TriggerServerEvent('it-drugs:server:processDrugs', entity)
            else
                ShowNotification(_U('NOTIFICATION__CANCELED'), "error")
                ClearPedTasks(ped)
                RemoveAnimDict('amb@medic@standing@kneel@base')
                RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
            end
            Wait(1000)
        end
        proccessing = false
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end
end)

RegisterNetEvent('it-drugs:client:removeTable', function(args)
    local entity = args.entity

    local ped = PlayerPedId()
    TaskTurnPedToFaceEntity(ped, entity, 1.0)
    Wait(1500)

    RequestAnimDict('amb@medic@standing@kneel@base')
    RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
    while 
        not HasAnimDictLoaded('amb@medic@standing@kneel@base') or
        not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@')
    do 
        Wait(0) 
    end
    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
    TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false, false, false)

    if lib.progressBar({
        duration = 5000,
        label = _U('PROGRESSBAR__REMOVE__TABLE'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
    }) then
        TriggerServerEvent('it-drugs:server:removeTable', entity)
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    else
        ShowNotification(_U('NOTIFICATION__CANCELED'), "error")
        ClearPedTasks(ped)
        RemoveAnimDict('amb@medic@standing@kneel@base')
        RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
    end
end)