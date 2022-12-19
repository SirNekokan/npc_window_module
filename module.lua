NpcModule = {}

npcModuleOpcode = 254
npcModuleWindow = nil
npcModuleButton = nil
topPanel = nil
topLeftPanel = nil
npcImage = nil
topRightPanel = nil
npcLabel = nil
bottomPanel = nil
bottomPanelShow = nil
bottomSeparator = nil
startBottomPanelHeight = 40
bottomPanelHeight = startBottomPanelHeight

function init()
  connect(g_game, { onGameEnd = NpcModule.destroy })

  ProtocolGame.registerExtendedOpcode(npcModuleOpcode, NpcModule.parseTypeOfExtendedOpcode)
  -- Optional Button for top interface:
  --npcModuleButton = modules.client_topmenu.addRightGameToggleButton('NpcModuleButton', tr('NpcModule'), '/images/topbuttons/motd', function() NpcModule.create() end, false, 8)
end

function terminate()
  disconnect(g_game, { onGameEnd = NpcModule.destroy })
  NpcModule.destroy()

  if npcModuleButton then
    npcModuleButton:destroy()
  end

  NpcModule = nil
end

function NpcModule.create()
  NpcModule.destroy()

  npcModuleWindow = g_ui.displayUI('npcmodule.otui')
  topPanel = npcModuleWindow:getChildById("topPanel")
  topLeftPanel = topPanel:getChildById("leftPanel")
  npcImage = topLeftPanel:getChildById("npcImage")
  topRightPanel = topPanel:getChildById("rightPanel")
  npcLabel = topRightPanel:getChildById("npcLabel")
  bottomPanel = npcModuleWindow:getChildById("bottomPanel")
  bottomSeparator = npcModuleWindow:getChildById("bottomSeparator")
end

function NpcModule.parseTypeOfExtendedOpcode(protocol, opcode, buffer)
    local json_status, json_data =
        pcall(
        function()
            return json.decode(buffer)
        end
    )

    if not json_status then
        return
    end

    local typeOfMessage = json_data.type
    if (typeOfMessage == "clear") then
        NpcModule.clear()
    elseif (typeOfMessage == "create") then
        NpcModule.create()

        if (json_data.choices and #json_data.choices > 0) then
            for i=1, #json_data.choices do
                local choice = json_data.choices[i]
                if (choice) then
                    NpcModule.addChoice(choice)
                end
            end
        end
        NpcModule.setNpcText(json_data.text)
        NpcModule.setNpcName(json_data.npc)

        NpcModule.fixHeight()
    elseif (typeOfMessage == "destroy") then
        NpcModule.destroy()
    elseif (typeOfMessage == "talk") then
        g_game.talkChannel(MessageModes.NpcTo, 0, json_data.text)
    end
end

function NpcModule.fixHeight()
    bottomPanel:setHeight(bottomPanelHeight)
    
    bottomPanelShow = ((bottomPanel:getChildCount() > 0) and 1 or 0)
    if (bottomPanelShow == 0) then
        bottomPanel:hide()
        bottomSeparator:hide()
    else
        bottomPanel:show()
        bottomSeparator:show()
    end

    npcModuleWindow:setHeight(topPanel:getHeight() + (bottomPanelShow == 1 and bottomPanel:getHeight() or 150) + 25)
end

function NpcModule.clear()
    if (bottomPanel) then
        bottomPanel:destroyChildren()

        bottomPanelHeight = startBottomPanelHeight
    end
end

function NpcModule.addChoice(text)
    local npcChoiceLabel = g_ui.createWidget('npcChoice', bottomPanel)
    npcChoiceLabel:setText(text)
    npcChoiceLabel.onClick = function(widget)
        NpcModule.selectChoice(widget:getText())
    end

    bottomPanelHeight = bottomPanelHeight + npcChoiceLabel:getHeight()
end

function NpcModule.setNpcText(text)
    npcLabel:setText(text)
end

function NpcModule.setNpcName(text)
    npcModuleWindow:setText(text)

    local imagePath = "images/" .. text
	-- Internal png Path for each char:
    if (g_resources.fileExists("/modules/game_npcmodule/" .. imagePath .. ".png")) then
        npcImage:setImageSource(imagePath)
    end
end

function NpcModule.selectChoice(text)
    g_game.talkChannel(MessageModes.NpcTo, 0, text)
end

function NpcModule.destroy()
  if npcModuleWindow then
    npcModuleWindow:hide()
    npcModuleWindow:destroy()
    npcModuleWindow = nil
  end
end
