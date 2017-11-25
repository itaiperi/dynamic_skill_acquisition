local classic = require 'classic'
local image = require 'image'
-- Do not install if luasocket missing
local hasSocket, socket = pcall(require, 'socket')
if not hasSocket then
  return nil
end
-- Do not require libMalmoLua for install
local hasLibMalmoLua, libMalmoLua = pcall(require, 'libMalmoLua')
-- require('nn.SpatialGlimpse')
-- require 'libMalmoLua'

local Minecraft, super = classic.class('Minecraft', Env)

local function sleep(sec)
  socket.select(nil, nil, sec)
end

-- Constructor
function Minecraft:_init(opts)
  -- Check libaMalmoLua is available locally
  if not hasLibMalmoLua then
    print("Requires libMalmoLua.so")
    os.exit()
  end

  opts = opts or {}
  self.height = opts.height * opts.zoom
  self.width = opts.width * opts.zoom

  self.shortSleep = 0.1

  self.mission_xml_pattern = [[<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<Mission xmlns="http://ProjectMalmo.microsoft.com" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

  <About>
    <Summary>Cliff walking mission based on Sutton and Barto.</Summary>
  </About>

  <ModSettings>
    <MsPerTick>25</MsPerTick>
  </ModSettings>

  <ServerSection>
      <ServerInitialConditions>
            <Time>
                <StartTime>6000</StartTime>
                <AllowPassageOfTime>false</AllowPassageOfTime>
            </Time>
            <Weather>clear</Weather>
            <AllowSpawning>false</AllowSpawning>
      </ServerInitialConditions>
    <ServerHandlers>
      <FlatWorldGenerator generatorString="3;7,220*1,5*3,2;3;,biome_1"/>
      <DrawingDecorator>
        <!-- STRUCTURE -->
        <DrawCuboid type="stone" x1="-6" x2="6" y1="226" y2="231" z1="-6" z2="6"/>
        <DrawCuboid type="air" x1="-5" x2="5" y1="227" y2="230" z1="-5" z2="5"/>
        <DrawCuboid type="glass" x1="-6" x2="6" y1="231" y2="231" z1="-6" z2="6"/>
        <DrawCuboid type="planks" x1="-6" x2="6" y1="226" y2="226" z1="-6" z2="6"/>
        <!-- /STRUCTURE -->
        <DrawCuboid type="bookshelf" x1="-3" x2="2" y1="227" y2="230" z1="5" z2="5"/>
        <DrawCuboid type="air" x1="-3" x2="2" y1="227" y2="228" z1="5" z2="5"/>
        <DrawCuboid type="air" x1="-1" x2="0" y1="229" y2="229" z1="5" z2="5"/>
        <DrawCuboid type="planks" variant="dark_oak" x1="-1" x2="0" y1="227" y2="227" z1="5" z2="5"/>
        <DrawBlock face="SOUTH" type="bed" variant="foot" x="-1" y="227" z="3"/>
        <DrawBlock face="SOUTH" type="bed" variant="head" x="-1" y="227" z="4"/>
        <DrawBlock face="SOUTH" type="bed" variant="foot" x="0" y="227" z="3"/>
        <DrawBlock face="SOUTH" type="bed" variant="head" x="0" y="227" z="4"/>
        <DrawCuboid type="wooden_slab" variant="dark_oak" x1="-1" x2="0" y1="227" y2="227" z1="2" z2="2"/>
        <DrawBlock face="UP" type="log" variant="spruce" x="-2" y="227" z="5"/>
        <DrawBlock face="UP" type="dark_oak_fence" x="-2" y="228" z="5"/>
        <DrawBlock face="UP" type="stone_slab" x="-2" y="229" z="5"/>
        <DrawBlock face="UP" type="log" variant="spruce" x="1" y="227" z="5"/>
        <DrawBlock face="UP" type="dark_oak_fence" x="1" y="228" z="5"/>
        <DrawBlock face="UP" type="stone_slab" x="1" y="229" z="5"/>
        <DrawBlock face="NORTH" type="wall_banner" x="-1" y="229" z="5"/>
        <DrawBlock face="NORTH" type="wall_banner" x="0" y="229" z="5"/>
        <DrawCuboid face="SOUTH" type="chest" x1="-5" x2="-4" y1="227" y2="227" z1="5" z2="5"/>
        <DrawCuboid type="glass_pane" x1="-5" x2="-4" y1="228" y2="229" z1="6" z2="6"/>
        <DrawBlock face="WEST" type="quartz_stairs" x="3" y="227" z="4"/>
        <DrawBlock face="EAST" type="quartz_stairs" x="4" y="227" z="4"/>
        <DrawCuboid type="quartz_block" x1="3" x2="4" y1="227" y2="227" z1="5" z2="5"/>
        <DrawCuboid type="glass_pane" x1="3" x2="4" y1="228" y2="229" z1="6" z2="6"/>
        <DrawBlock face="SOUTH" type="flower_pot" variant="poppy" x="-1" y="228" z="5"/>
        <DrawCuboid type="log" variant="spruce" x1="-2" x2="-1" y1="227" y2="228" z1="-5" z2="-4"/>
        <DrawCuboid face="SOUTH" type="wall_sign" x1="-2" x2="-1" y1="227" y2="228" z1="-3" z2="-3"/>
        <DrawCuboid face="SOUTH" type="stone" variant="smooth_andesite" x1="0" x2="2" y1="227" y2="227" z1="-5" z2="-4"/>
        <DrawBlock face="SOUTH" type="stone_stairs" variant="bottom" x="1" y="227" z="-4"/>
        <DrawBlock face="UP_Z" type="lever" x="1" y="228" z="-5"/>
        <DrawCuboid type="glass_pane" x1="0" x2="2" y1="228" y2="229" z1="-6" z2="-6"/>
        <DrawCuboid face="UP" type="hay_block" x1="3" x2="5" y1="227" y2="229" z1="-5" z2="-4"/>
        <DrawCuboid face="SOUTH" type="furnace" x1="3" x2="4" y1="227" y2="228" z1="-4" z2="-4"/>
        <DrawCuboid face="UP" type="hay_block" x1="-5" x2="-3" y1="227" y2="229" z1="-5" z2="-2"/>
        <DrawCuboid type="air" x1="-4" x2="-3" y1="227" y2="229" z1="-4" z2="-2"/>
        <DrawItem type="coal" x="^X" y="229" z="^Z"/>
        <!-- <DrawItem type="coal" x="-4" y="227" z="-4"/> -->
        <DrawCuboid type="glass_pane" x1="-6" x2="-6" y1="228" y2="229" z1="-1" z2="1"/>
        <DrawCuboid type="glass_pane" x1="-6" x2="-6" y1="228" y2="229" z1="4" z2="5"/>
        <DrawBlock face="NORTH" type="dark_oak_stairs" x="5" y="227" z="-1"/>
        <DrawBlock face="NORTH" type="dark_oak_fence" x="5" y="227" z="0"/>
        <DrawBlock face="UP" type="stone_pressure_plate" x="5" y="228" z="0"/>
        <DrawBlock face="SOUTH" type="dark_oak_stairs" x="5" y="227" z="1"/>
        <DrawCuboid type="glass_pane" x1="6" x2="6" y1="228" y2="229" z1="-1" z2="1"/>
      </DrawingDecorator>
      <ServerQuitFromTimeUp timeLimitMs="15000"/>
      <ServerQuitWhenAnyAgentFinishes/>
    </ServerHandlers>
  </ServerSection>

  <AgentSection mode="Survival">
    <Name>Cristina</Name>
    <AgentStart>
      <!-- <Placement pitch="30" x="-2" y="227" yaw="0" z="-2"/> -->
      <Placement pitch="30" x="^A_X" y="227" yaw="^YAW" z="^A_X"/>
      <Inventory/>
        <!--<InventoryItem slot="0" type="diamond_pickaxe"/>
      </Inventory>-->
    </AgentStart>
    <AgentHandlers>
      <ObservationFromFullStats/>
      <RewardForCollectingItem>
        <Item reward="1000" type="coal"/>
      </RewardForCollectingItem>
      <RewardForTimeTaken initialReward="220" delta="-1" density="MISSION_END"/>
      <VideoProducer want_depth="false">
          <Width>640</Width>
          <Height>480</Height>
      </VideoProducer>
      <ContinuousMovementCommands turnSpeedDegs="180">
      </ContinuousMovementCommands>
      <RewardForMissionEnd rewardForDeath="-100">
		  <Reward description="found_goal" reward="100"/>
      </RewardForMissionEnd>
      <!-- <RewardForSendingCommand reward="-1"/> -->
      <MissionQuitCommands quitDescription="give_up"/>
        <AgentQuitFromCollectingItem>
            <Item type="coal" description="Found coal!"/>
        </AgentQuitFromCollectingItem>
    </AgentHandlers>
  </AgentSection>

</Mission>
]]

  self.x_min_limit = opts.x_min_limit
  self.x_max_limit = opts.x_max_limit
  self.z_min_limit = opts.z_min_limit
  self.z_max_limit = opts.z_max_limit
  self.timeReward = opts.timeReward
  self.roundTime = opts.roundTime
  self.commandReward = opts.commandReward
  self.findReward = opts.findReward
  self.randomStart = opts.randomStart
  self.slowActions = opts.slowActions

  self.actions = opts.actions or {"left", "right", "forward", "swap"} --, "use 0", "turn 0", "move 1", "move 0"}
  -- self.actions = opts.actions or {"swap"} --, "use 0", "turn 0", "move 1", "move 0"}

  self.agent_host = AgentHost()

  self.client_pool = ClientPool()
  self.client_pool:add(ClientInfo("127.0.0.1", opts.port))

  -- Load mission XML from provided file
  if opts.mission_xml ~= "" then
    print(opts.mission_xml)
    print("Loading mission XML from: " .. opts.mission_xml)
    local f = assert(io.open(opts.mission_xml, "r"), "Error loading mission")
    self.mission_xml_pattern = f:read("*a")
  end
end

function Minecraft:getXML()
  local yaw = math.random(0, 4) * 90
  local agent_x = 0
  local agent_z = 0
  local x = 0
  local z = 0
  if (self.x_min_limit ~= "0") then
    if (self.randomStart) then
      agent_x = math.random(self.x_min_limit + 1,self.x_max_limit - 1)
      agent_z = math.random(self.z_min_limit + 1,self.z_max_limit - 1)
      print(agent_z)
      print(agent_x)
    end
    x = math.random(self.x_min_limit,self.x_max_limit)
    z = math.random(self.z_min_limit,self.z_max_limit)
    while agent_x == x and agent_z == z do
      x = math.random(self.x_min_limit,self.x_max_limit)
      z = math.random(self.z_min_limit,self.z_max_limit)
    end
  end
  delta = -1
  if self.timeReward == "0" or self.initialReward then
    delta = 0
  end
  return self.mission_xml_pattern:gsub("%^X", x):gsub("%^Z", z):gsub("%^A_X", agent_x):gsub("%^A_Z", agent_z):gsub("%^YAW", yaw):gsub("%^TIME", self.roundTime):gsub("%^F_R", self.findReward):gsub("%^T_R", self.timeReward):gsub("%^C_R", self.commandReward):gsub("%^DELTA", delta)
end

-- returned states are RGB images
function Minecraft:getStateSpec()
  return {'real', {3, self.height, self.width}, {0, 1}}
end

function Minecraft:getActionSpec()
  return {'int', 1, {1, #self.actions}}
end

-- Min and max reward
function Minecraft:getRewardSpec()
  return nil, nil
end

-- process video input from the world
function Minecraft:processFrames(world_video_frames)
  local proc_frames = {}

  for frame in world_video_frames do
    local ti = torch.FloatTensor(3, self.height, self.width)
    getTorchTensorFromPixels(frame, tonumber(torch.cdata(ti, true)))
    ti:div(255)
    table.insert(proc_frames, ti)
  end

  return proc_frames
end

function Minecraft:getRewards(world_rewards)
  local proc_rewards = {}

  for reward in world_rewards do
    table.insert(proc_rewards, reward:getValue())
  end

  return proc_rewards
end

-- Start new mission
function Minecraft:start()

  local world_state = self.agent_host:peekWorldState()

  -- check if a previous mission is still running before starting a new one
  if world_state.is_mission_running then
	  self.agent_host:sendCommand("quit")
	  sleep(0.5)
  end

  local mission = MissionSpec(self:getXML(), true)
  local mission_record = MissionRecordSpec()

  -- Request video
  mission:requestVideo(self.height, self.width)

  -- Add holes for interest
  for z = 3, 10, 2 do
    local x = torch.random(1, 3)
    mission:drawBlock(x, 45, z, "lava")
  end

  -- Channels, height, width of input frames
  local channels = mission:getVideoChannels(0)
  local height = mission:getVideoHeight(0)
  local width = mission:getVideoWidth(0)

  assert(channels == 3, "No RGB video output")
  assert(height == self.height or width == self.width, "Video output dimensions don't match those requested")

  local status, err = pcall(function() self.agent_host:startMission( mission, self.client_pool, mission_record, 0, "" ) end)
  if not status then
    print("Error starting mission: "..err)
    os.exit(1)
  end

  io.write("Waiting for mission to start")
  local world_state = self.agent_host:getWorldState()
  while not world_state.has_mission_begun do
    io.write(".")
    io.flush()
    sleep(0.05)
    world_state = self.agent_host:getWorldState()
    for error in world_state.errors do
      print("Error: "..error.text)
    end
  end
  io.write("\n")

  sleep(0.5)

  while world_state.number_of_video_frames_since_last_state < 1 do
	sleep(0.05)
    world_state = self.agent_host:peekWorldState()
  end

  self.proc_frames = self:processFrames(world_state.video_frames)

  self.rewards = self:getRewards(world_state.rewards)

  -- Return first state
  return self.proc_frames[1]
end

-- Select an action
function Minecraft:step(action)

  -- Do something
  local action = self.actions[action]
  local counterAction = "turn 0"

  value = "1"
  if action == "left" then
    action = "turn -" .. value
  elseif action == "right" then
    action = "turn " .. value
  elseif action == "forward" then
    action = "move " .. value
  elseif action == "swap" then
    self.agent_host:sendCommand(counterAction)
    action = "swapInventoryItems chest:0 1"
  else
    action = counterAction
  end

  self.agent_host:sendCommand(action)
  -- print(action)

  -- Wait for command to be received and world state to change
  -- sleep(0.05)

  -- Check the world state
  local world_state = self.agent_host:peekWorldState()

  -- Zero previous reward
  self.rewards[1] = 0
  -- Receive a reward
  local max_retries = 5
  while world_state.number_of_rewards_since_last_state < 1 and max_retries >= 0 do
    sleep(self.shortSleep)
    world_state = self.agent_host:peekWorldState()
    max_retries = max_retries - 1
  end
  if max_retries >= 0 then
    self.rewards = self:getRewards(world_state.rewards)
  else
	  -- print(max_retries)
  end

  -- Zero previous frame
  self.proc_frames[1]:zero()
  local max_retries = 5
  while world_state.number_of_video_frames_since_last_state < 1 and max_retries >= 0 do
	sleep(0.05)
    world_state = self.agent_host:peekWorldState()
    max_retries = max_retries - 1
  end
  if max_retries >= 0 then
    self.proc_frames = self:processFrames(world_state.video_frames)
  else
	print(max_retries)
  end

  local terminal = not world_state.is_mission_running

  world_state = self.agent_host:getWorldState()

  if terminal then
	sleep(0.5)
  end

  return self.rewards[1], self.proc_frames[1], terminal
end

return Minecraft
