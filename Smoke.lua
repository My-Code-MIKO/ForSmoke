-- Auto deploy with: pastebin get <your_pastebin_id> startup.lua
-- GitHub: https://raw.githubusercontent.com/Rwa/main/smoke_launcher.lua

local VERSION = "1.2"
local CONFIG_FILE = "smoke_cfg.dat"

-- 配置结构
local config = {
    fuse_time = 1,          -- 引信时间（刻）
    spawn_offset = { x=1, y=0, z=0 }, -- 生成位置偏移（相对电脑右侧）
    motion = { x=0.0, y=0.5, z=0.0 }, -- 运动矢量
    require_gps = true      -- 是否强制需要GPS
}

-- 初始化系统
local function init()
    if config.require_gps and not peripheral.find("modem") then
        error("GPS modem required!")
    end
    
    rednet.open(peripheral.find("modem"))
    print("System initialized v"..VERSION)
end

-- 获取电脑坐标（带偏移计算）
local function getPositionWithOffset()
    local x, y, z = gps.locate()
    if not x then return nil end
    
    return {
        x = x + config.spawn_offset.x,
        y = y + config.spawn_offset.y,
        z = z + config.spawn_offset.z
    }
end

-- 红石信号监听
local function redstoneListener()
    while true do
        if redstone.getInput("top") then
            local pos = getPositionWithOffset()
            if pos then
                local cmd = string.format(
                    "execute at @p run summon create:smoke_grenade %d %d %d {Fuse:%db,Motion:[%.1f,%.1f,%.1f]}",
                    pos.x, pos.y, pos.z,
                    config.fuse_time,
                    config.motion.x, config.motion.y, config.motion.z
                )
                commands.execAsync(cmd)
                print("Smoke grenade launched at "..textutils.serialise(pos))
            end
            sleep(0.5) -- 防重复触发
        end
        sleep(0.1)
    end
end

-- 主程序
local function main()
    init()
    parallel.waitForAll(
        redstoneListener,
        function() -- 状态显示
            while true do
                term.clear()
                term.setCursorPos(1,1)
                print("Redstone Smoke System")
                print("Status: ACTIVE")
                print("Waiting for top signal...")
                sleep(5)
            end
        end
    )
end

-- 自动运行
if shell and not _TEST_MODE then
    main()
end

return config
