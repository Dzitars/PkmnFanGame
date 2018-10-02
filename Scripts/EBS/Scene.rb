#===============================================================================
#  Elite Battle system
#    by Luka S.J.
# ----------------
#  Scene Script
# ----------------  
#  system is based off the original Essentials battle system, made by
#  Poccil & Maruno
#  No additional features added to AI, mechanics 
#  or functionality of the battle system.
#  This update is purely cosmetic, and includes a B/W like dynamic scene with a 
#  custom interface.
#
#  Enjoy the script, and make sure to give credit!
#  (DO NOT ALTER THE NAMES OF THE INDIVIDUAL SCRIPT SECTIONS OR YOU WILL BREAK
#   YOUR SYSTEM!)
#===============================================================================                           
class PokeBattle_Scene
  attr_accessor :idleTimer
  attr_accessor :safaribattle
  attr_accessor :vector
  attr_accessor :sendingOut
  attr_accessor :afterAnim
  attr_accessor :lowHPBGM
  attr_accessor :briefmessage
  attr_accessor :sprites
  attr_reader :smTrainerSequence
  attr_reader :battle
  attr_reader :commandWindow
  alias initialize_ebs initialize unless self.method_defined?(:initialize_ebs)
  def initialize
    @safaribattle = false
    initialize_ebs
  end
  # Retained to prevent any potential conflicts
  # Returns whether the party line-ups are currently appearing on-screen
  alias inPartyAnimation_ebs inPartyAnimation? unless self.method_defined?(:inPartyAnimation_ebs)
  def inPartyAnimation?; return false; end
  # Shows the party line-ups appearing on-screen
  alias partyAnimationUpdate_ebs partyAnimationUpdate unless self.method_defined?(:partyAnimationUpdate_ebs)
  def partyAnimationUpdate; end
  # used to dispose of everything
  def pbDisposeSprites
    pbDisposeSpriteHash(@sprites)
    @bagWindow.dispose
    @commandWindow.dispose
    @fightWindow.dispose
  end
  #=============================================================================
  #  A slightly different way to loading backdrops
  #  Backdrops now get tinted according to the daytime
  #=============================================================================
  alias pbBackdrop_ebs pbBackdrop unless self.method_defined?(:pbBackdrop_ebs)
  def pbBackdrop
    environ = @battle.environment
    terrain = $game_player.terrain_tag
    # Choose backdrop
    backdrop = "Field"
    if environ == PBEnvironment::Cave && pbGetMetadata($game_map.map_id,MetadataDarkMap)
      backdrop = "CaveDark"
    elsif environ == PBEnvironment::Cave
      backdrop = "Cave"
    elsif ($game_map.name.downcase).include?("city") || ($game_map.name.downcase).include?("town")
      backdrop = "City"
    elsif environ == PBEnvironment::MovingWater || environ == PBEnvironment::StillWater
      backdrop = "Water"
    elsif environ == PBEnvironment::Underwater
      backdrop = "Underwater"
    elsif environ == PBEnvironment::Rock
      backdrop = "Mountain"
    elsif environ == PBEnvironment::Snow
      backdrop = "Snow"
    elsif environ == PBEnvironment::Forest
      backdrop = "Forest"
    else
      if !$game_map || !pbGetMetadata($game_map.map_id,MetadataOutdoor)
        backdrop = "IndoorA"
      end
    end
    if $game_map
      back = pbGetMetadata($game_map.map_id,MetadataBattleBack)
      if back && back!=""
        backdrop=back
      end
    end
    if $PokemonGlobal && $PokemonGlobal.nextBattleBack
      backdrop = $PokemonGlobal.nextBattleBack
    end
    # Choose bases
    base = ""
    trialname = ""
    if environ == PBEnvironment::Grass || environ == PBEnvironment::TallGrass
      trialname = "Grass"
    elsif environ == PBEnvironment::Sand
      trialname = "Sand"
    elsif terrain == PBTerrain::Puddle
      trialname = "Puddle"
    elsif $PokemonGlobal.surfing
      trialname = "Water"
    elsif @battle.opponent && backdrop == "City"
      trialname = "Concrete"
    elsif terrain == PBTerrain::Rock
      trialname = "Dirt"
    end
    if pbResolveBitmap(sprintf("Graphics/Battlebacks/playerbase/"+backdrop+trialname))
      base = trialname
    end
    # Apply graphics
    enemybase = USEBATTLEBASES ? "Graphics/Battlebacks/enemybase/"+backdrop+base : nil
    playerbase = USEBATTLEBASES ? "Graphics/Battlebacks/playerbase/"+backdrop+base : nil
    @sprites["battlebg"] = AnimatedBattleBackground.new(@viewport)
    @sprites["battlebg"].setBitmap(backdrop,self)
    pbAddSprite("playerbase",0,0,playerbase,@viewport)
    @sprites["playerbase"].bitmap = Bitmap.new(1,1) if !USEBATTLEBASES
    pbAddSprite("enemybase",0,0,enemybase,@viewport)
    @sprites["enemybase"].bitmap = Bitmap.new(1,1) if !USEBATTLEBASES
    @sprites["playerbase"].visible = !@safaribattle
    @sprites["shades"] = Sprite.new(@viewport)
    @sprites["shades"].bitmap = Bitmap.new(Graphics.width,VIEWPORT_HEIGHT)
    @sprites["shades"].bitmap.fill_rect(0,0,Graphics.width,VIEWPORT_HEIGHT,Color.new(255,255,255))
    @sprites["shades"].z = 2
    @sprites["shades"].opacity = 0
    
    pbDayNightTint(@sprites["battlebg"])
    pbDayNightTint(@sprites["playerbase"])
    pbDayNightTint(@sprites["enemybase"])
    
    @sprites["enemybase"].ox = @sprites["enemybase"].bitmap.width/2
    @sprites["enemybase"].oy = @sprites["enemybase"].bitmap.height/2
    @sprites["playerbase"].ox = @sprites["playerbase"].bitmap.width/2
    @sprites["playerbase"].oy = @sprites["playerbase"].bitmap.height/2
  end
  #=============================================================================
  #  Initialization of the battle scene
  #=============================================================================
  def pbLoadUIElements(battle)
    if [1,2].include?(EBUISTYLE)
      args = battle.battlers[0],battle.doublebattle,@viewport,battle.pbPlayer,self
      @sprites["battlebox0"] = EBUISTYLE==2 ? NextGenDataBox.new(*args) : PokemonNewDataBox.new(*args)
      args = battle.battlers[1],battle.doublebattle,@viewport,battle.pbPlayer,self
      @sprites["battlebox1"] = EBUISTYLE==2 ? NextGenDataBox.new(*args) : PokemonNewDataBox.new(*args)
      if @battle.doublebattle
        args = battle.battlers[2],battle.doublebattle,@viewport,battle.pbPlayer,self
        @sprites["battlebox2"] = EBUISTYLE==2 ? NextGenDataBox.new(*args) : PokemonNewDataBox.new(*args)
        args = battle.battlers[3],battle.doublebattle,@viewport,battle.pbPlayer,self
        @sprites["battlebox3"] = EBUISTYLE==2 ? NextGenDataBox.new(*args) : PokemonNewDataBox.new(*args)
      end
      pbAddSprite("messagebox",0,VIEWPORT_HEIGHT-96,EBUISTYLE==2 ? "#{checkEBFolderPath}/nextGen/newBattleMessageBox" : "#{checkEBFolderPath}/newBattleMessageBox",@msgview)
      @sprites["messagebox"].z=99999
      @sprites["messagebox"].visible=false
    
      @sprites["helpwindow"]=Window_UnformattedTextPokemon.newWithSize("",0,0,32,32,@msgview)
      @sprites["helpwindow"].visible=false
      @sprites["helpwindow"].z=@sprites["messagebox"].z+1
    
      @sprites["messagewindow"]=Window_AdvancedTextPokemon.new("")
      @sprites["messagewindow"].letterbyletter=true
      @sprites["messagewindow"].viewport=@msgview
      @sprites["messagewindow"].z=@sprites["messagebox"].z+1 
    
      @sprites["commandwindow"]=CommandMenuDisplay.new(@msgview) # Retained for compatibility
      @sprites["commandwindow"].visible=false # Retained for compatibility
      @sprites["fightwindow"]=FightMenuDisplay.new(nil,@msgview) # Retained for compatibility
      @sprites["fightwindow"].visible=false # Retained for compatibility
      @commandWindow = (EBUISTYLE==2) ? NextGenCommandWindow.new(@viewport,@battle,@safaribattle,@viewport) : NewCommandWindow.new(@viewport,@battle,@safaribattle,@viewport)
      @fightWindow = (EBUISTYLE==2) ? NextGenFightWindow.new(@viewport,@battle) : NewFightWindow.new(@viewport)
      @bagWindow=NewBattleBag.new(self,@viewport)
      10.times do
        @commandWindow.hide
        @fightWindow.hide
      end
    else
      @sprites["battlebox0"]=PokemonDataBox.new(battle.battlers[0],battle.doublebattle,@viewport)
      @sprites["battlebox1"]=PokemonDataBox.new(battle.battlers[1],battle.doublebattle,@viewport)
      if battle.doublebattle
        @sprites["battlebox2"]=PokemonDataBox.new(battle.battlers[2],battle.doublebattle,@viewport)
        @sprites["battlebox3"]=PokemonDataBox.new(battle.battlers[3],battle.doublebattle,@viewport)
      end
      pbAddSprite("messagebox",0,VIEWPORT_HEIGHT-96,"Graphics/Pictures/battleMessage",@viewport)
      @sprites["messagebox"].z=90
      @sprites["helpwindow"]=Window_UnformattedTextPokemon.newWithSize("",0,0,32,32,@viewport)
      @sprites["helpwindow"].visible=false
      @sprites["helpwindow"].z=90
      @sprites["messagewindow"]=Window_AdvancedTextPokemon.new("")
      @sprites["messagewindow"].letterbyletter=true
      @sprites["messagewindow"].viewport=@viewport
      @sprites["messagewindow"].z=100
      @sprites["commandwindow"]=CommandMenuDisplay.new(@viewport)
      @sprites["commandwindow"].z=100
      @sprites["fightwindow"]=FightMenuDisplay.new(nil,@viewport)
      @sprites["fightwindow"].z=100
      pbShowWindow(MESSAGEBOX)
    end
    # Party arrows
    if @battle.opponent
      @sprites["oppArrow"] = NewPartyArrow.new(@msgview,@battle.party2,false,@battle.doublebattle,@battle.pbSecondPartyBegin(1))
      @sprites["plArrow"] = NewPartyArrow.new(@msgview,@battle.party1,true,@battle.doublebattle)
    end
    # Compatibility for gen 6 Effect messages
    if INCLUDEGEN6 || EFFECTMESSAGES
      if INCLUDEGEN6 && EBUISTYLE==0
        #Draw message effect sprites
        #not shown here
        pbAddSprite("EffectFoe",0,90,"Graphics/Pictures/battleEffectFoe",@viewport)
        pbAddSprite("EffectPlayer",Graphics.width-192,158,"Graphics/Pictures/battleEffectPlayer",@viewport)
        @sprites["EffectFoe"].visible=false
        @sprites["EffectFoe"].z=95
        @sprites["EffectPlayer"].visible=false
        @sprites["EffectPlayer"].z=95
      else
        @sprites["abilityMessage"]=Sprite.new(@viewport)
        @sprites["abilityMessage"].bitmap=Bitmap.new(280,68)
        pbSetSystemFont(@sprites["abilityMessage"].bitmap)
        @sprites["abilityMessage"].oy=@sprites["abilityMessage"].bitmap.height/2+6
        @sprites["abilityMessage"].zoom_y=0
        @sprites["abilityMessage"].z=99999
      end
    end
  end
  
  alias pbStartBattle_ebs pbStartBattle unless self.method_defined?(:pbStartBattle_ebs)
  def pbStartBattle(battle)
    @battle=battle
    $specialSpecies=false if @battle.doublebattle
    angle=($PokemonSystem.screensize < 1) ? 10 : 25
    @vector = Vector.new(-Graphics.width*1.0,VIEWPORT_HEIGHT*1.5,angle,Graphics.width*1.5,2,1)
    @firstsendout=true
    @lastcmd=[0,0,0,0]
    @lastmove=[0,0,0,0]
    @orgPos=nil
    @shadowAngle=60
    @idleTimer=0
    @idleSpeed=[40,0]
    @animationCount=1
    @showingplayer=true
    @showingenemy=true
    @briefmessage=false
    @lowHPBGM=false
    @sprites.clear
    @viewport=Viewport.new(0,0,Graphics.width,VIEWPORT_HEIGHT)
    @viewport.z=99999
    @sprites["weather"] = RPG::BattleWeather.new(@viewport) if !@safaribattle && EBUISTYLE > 0
    @msgview=Viewport.new(0,0,Graphics.width,VIEWPORT_HEIGHT)
    @msgview.z=99999
    @msgview2=Viewport.new(0,VIEWPORT_HEIGHT+VIEWPORT_OFFSET,Graphics.width,VIEWPORT_HEIGHT)
    @msgview2.z=99999
    @traineryoffset=(VIEWPORT_HEIGHT-320) # Adjust player's side for screen size
    @foeyoffset=(@traineryoffset*3/4).floor  # Adjust foe's side for screen size
    # special Sun & Moon styled VS sequences
    if $smAnim && @battle.opponent && !@battle.opponent.is_a?(Array)
      @smTrainerSequence = SunMoonBattleTransitions.new(@viewport,@msgview,self,@battle.opponent.trainertype)
    end
    pbBackdrop
    if @battle.player.is_a?(Array)
      trainerfile=pbPlayerSpriteBackFile(@battle.player[0].trainertype)
      pbAddSprite("player",0,0,trainerfile,@viewport)
      trainerfile=pbTrainerSpriteBackFile(@battle.player[1].trainertype)
      pbAddSprite("playerB",0,0,trainerfile,@viewport)
    else
      trainerfile=pbPlayerSpriteBackFile(@battle.player.trainertype)
      pbAddSprite("player",0,0,trainerfile,@viewport)
    end
    @sprites["player"].x=40
    @sprites["player"].y=VIEWPORT_HEIGHT-@sprites["player"].bitmap.height
    @sprites["player"].z=30
    @sprites["player"].opacity=0
    @sprites["player"].src_rect.set(0,0,@sprites["player"].bitmap.width/4,@sprites["player"].bitmap.height)
    if @sprites["playerB"]
      @sprites["playerB"].x=140
      @sprites["playerB"].y=VIEWPORT_HEIGHT-@sprites["playerB"].bitmap.height
      @sprites["playerB"].z=30
      @sprites["playerB"].opacity=0
      @sprites["playerB"].src_rect.set(0,0,@sprites["playerB"].bitmap.width/4,@sprites["playerB"].bitmap.height)
    end
    if @battle.opponent
      if @battle.opponent.is_a?(Array)
        trainerfile=pbTrainerSpriteFile(@battle.opponent[1].trainertype)
        @sprites["trainer2"]=DynamicTrainerSprite.new(@battle.doublebattle,-2,@viewport,true)
        @sprites["trainer2"].setTrainerBitmap(trainerfile)
        @sprites["trainer2"].z=16
        @sprites["trainer2"].tone=Tone.new(-255,-255,-255,-255)
        trainerfile=pbTrainerSpriteFile(@battle.opponent[0].trainertype)
        @sprites["trainer"]=DynamicTrainerSprite.new(@battle.doublebattle,-1,@viewport,true)
        @sprites["trainer"].setTrainerBitmap(trainerfile)
        @sprites["trainer"].z=11
        @sprites["trainer"].tone=Tone.new(-255,-255,-255,-255)
      else
        trainerfile=pbTrainerSpriteFile(@battle.opponent.trainertype)
        @sprites["trainer"]=DynamicTrainerSprite.new(@battle.doublebattle,-1,@viewport)
        @sprites["trainer"].setTrainerBitmap(trainerfile)
        @sprites["trainer"].z=11
        @sprites["trainer"].tone=Tone.new(-255,-255,-255,-255)
      end
    end
    @sprites["pokemon0"]=DynamicPokemonSprite.new(battle.doublebattle,0,@viewport)
    @sprites["pokemon0"].z=21 
    @sprites["pokemon1"]=DynamicPokemonSprite.new(battle.doublebattle,1,@viewport)
    @sprites["pokemon1"].z=11
    if battle.doublebattle
      @sprites["pokemon2"]=DynamicPokemonSprite.new(battle.doublebattle,2,@viewport)
      @sprites["pokemon2"].z=26
      @sprites["pokemon3"]=DynamicPokemonSprite.new(battle.doublebattle,3,@viewport)
      @sprites["pokemon3"].z=16
    end
    
    pbLoadUIElements(battle)
    
    pbSetMessageMode(false)
    trainersprite1=@sprites["trainer"]
    trainersprite2=@sprites["trainer2"]
    if !@battle.opponent
      if @battle.party2.length >=1
        if @battle.party2.length==1
          # wild (single) battle initialization
          @sprites["pokemon1"].setPokemonBitmap(@battle.party2[0],false)
          @sprites["pokemon1"].tone=Tone.new(-255,-255,-255,-255) 
          @sprites["pokemon1"].visible=true
          trainersprite1=@sprites["pokemon1"]
        elsif @battle.party2.length==2
          # wild (double battle initialization)
          @sprites["pokemon1"].setPokemonBitmap(@battle.party2[0],false)
          @sprites["pokemon1"].tone=Tone.new(-255,-255,-255,-255)
          @sprites["pokemon1"].visible=true
          trainersprite1=@sprites["pokemon1"]
          @sprites["pokemon3"].setPokemonBitmap(@battle.party2[1],false)
          @sprites["pokemon3"].tone=Tone.new(-255,-255,-255,-255)
          @sprites["pokemon3"].visible=true
          trainersprite2=@sprites["pokemon3"]
        end
      end
    end
    #################
    # Position for initial transition
    #--------------------------------------------
    black=Sprite.new(@viewport)
    black.z = 99999
    black.bitmap=Bitmap.new(Graphics.width,VIEWPORT_HEIGHT)
    black.bitmap.fill_rect(0,0,Graphics.width,VIEWPORT_HEIGHT,Color.new(0,0,0))
    #--------------------------------------------
    if @safaribattle
      @sprites["player"].x-=240
      @sprites["player"].y+=120
    end
    #################
    # Play battle entrance
    vector = @battle.doublebattle ? VECTOR2 : VECTOR1
    @vector.force
    @vector.set(vector)
    @vector.inc=0.1
    for i in 0...22
      if @safaribattle
        @sprites["player"].opacity+=25.5
        @sprites["player"].zoom_x=@vector.zoom1
        @sprites["player"].zoom_y=@vector.zoom1
        @sprites["player"].x+=10
        @sprites["player"].y-=5
      end
      if !@battle.opponent && i > 11
        @sprites["pokemon1"].tone.red+=255*0.05 if @sprites["pokemon1"].tone.red < 0
        @sprites["pokemon1"].tone.blue+=255*0.05 if @sprites["pokemon1"].tone.blue < 0
        @sprites["pokemon1"].tone.green+=255*0.05 if @sprites["pokemon1"].tone.green < 0
        @sprites["pokemon1"].tone.gray+=255*0.05 if @sprites["pokemon1"].tone.gray < 0
        if @battle.party2.length==2 
          @sprites["pokemon3"].tone.red+=255*0.05 if @sprites["pokemon3"].tone.red < 0
          @sprites["pokemon3"].tone.blue+=255*0.05 if @sprites["pokemon3"].tone.blue < 0
          @sprites["pokemon3"].tone.green+=255*0.05 if @sprites["pokemon3"].tone.green < 0
          @sprites["pokemon3"].tone.gray+=255*0.05 if @sprites["pokemon3"].tone.gray < 0
        end
      end
      if @battle.opponent && i > 11
        @sprites["trainer"].tone.red+=255*0.05 if @sprites["trainer"].tone.red < 0
        @sprites["trainer"].tone.blue+=255*0.05 if @sprites["trainer"].tone.blue < 0
        @sprites["trainer"].tone.green+=255*0.05 if @sprites["trainer"].tone.green < 0
        @sprites["trainer"].tone.gray+=255*0.05 if @sprites["trainer"].tone.gray < 0
        if @battle.opponent.is_a?(Array)
          @sprites["trainer2"].tone.red+=255*0.05 if @sprites["trainer2"].tone.red < 0
          @sprites["trainer2"].tone.blue+=255*0.05 if @sprites["trainer2"].tone.blue < 0
          @sprites["trainer2"].tone.green+=255*0.05 if @sprites["trainer2"].tone.green < 0
          @sprites["trainer2"].tone.gray+=255*0.05 if @sprites["trainer2"].tone.gray < 0
        end
      end
      black.opacity-=12 if black.opacity>0
      wait(1,true)
    end
    @vector.inc=0.2
    #################
    # Play cry for wild Pokémon
    if !@battle.opponent
      playBattlerCry(@battle.party2[0]) if !$specialSpecies
      playBattlerCry(@battle.party2[1]) if @battle.doublebattle
      for i in 0...10
        @sprites["pokemon1"].tone.red+=255*0.05 if @sprites["pokemon1"].tone.red < 0
        @sprites["pokemon1"].tone.blue+=255*0.05 if @sprites["pokemon1"].tone.blue < 0
        @sprites["pokemon1"].tone.green+=255*0.05 if @sprites["pokemon1"].tone.green < 0
        @sprites["pokemon1"].tone.gray+=255*0.05 if @sprites["pokemon1"].tone.gray < 0
        if @battle.party2.length==2 
          @sprites["pokemon3"].tone.red+=255*0.05 if @sprites["pokemon3"].tone.red < 0
          @sprites["pokemon3"].tone.blue+=255*0.05 if @sprites["pokemon3"].tone.blue < 0
          @sprites["pokemon3"].tone.green+=255*0.05 if @sprites["pokemon3"].tone.green < 0
          @sprites["pokemon3"].tone.gray+=255*0.05 if @sprites["pokemon3"].tone.gray < 0
        end
        wait(1,true)
      end
    end
    if @battle.opponent
      frames1=0
      frames2=0
      frames1=@sprites["trainer"].totalFrames if @sprites["trainer"]
      frames2=@sprites["trainer2"].totalFrames if @sprites["trainer2"]
      if frames1  >  frames2
        maxframes=frames1
      else
        maxframes=frames2
      end
      maxframes = 17 if maxframes < 17
      for i in 1...maxframes
        @sprites["trainer"].update if @sprites["trainer"] && i < frames1
        @sprites["trainer2"].update if @sprites["trainer2"] && i < frames2
        if SHOWPARTYARROWS && EBUISTYLE < 2
          @sprites["oppArrow"].show if i < 17
          @sprites["plArrow"].show if i < 17
        end
        @sprites["trainer"].tone.red+=255*0.05 if @sprites["trainer"].tone.red < 0
        @sprites["trainer"].tone.blue+=255*0.05 if @sprites["trainer"].tone.blue < 0
        @sprites["trainer"].tone.green+=255*0.05 if @sprites["trainer"].tone.green < 0
        @sprites["trainer"].tone.gray+=255*0.05 if @sprites["trainer"].tone.gray < 0
        if @battle.opponent.is_a?(Array)
          @sprites["trainer2"].tone.red+=255*0.05 if @sprites["trainer2"].tone.red < 0
          @sprites["trainer2"].tone.blue+=255*0.05 if @sprites["trainer2"].tone.blue < 0
          @sprites["trainer2"].tone.green+=255*0.05 if @sprites["trainer2"].tone.green < 0
          @sprites["trainer2"].tone.gray+=255*0.05 if @sprites["trainer2"].tone.gray < 0
        end
        wait(1,true)
      end
    else
      @sprites["battlebox1"].x=-264-10
      @sprites["battlebox1"].y=24
      @sprites["battlebox1"].appear if !$specialSpecies
      if @battle.party2.length==2
        @sprites["battlebox1"].y=60
        @sprites["battlebox3"].x=-264-8
        @sprites["battlebox3"].y=8
        @sprites["battlebox3"].appear
      end
      10.times do
        if EBUISTYLE==2
          @sprites["battlebox1"].show
        elsif EBUISTYLE==0
          @sprites["battlebox1"].update
        else
          @sprites["battlebox1"].x+=26
        end
        if @battle.party2.length==2
          if EBUISTYLE==2
            @sprites["battlebox3"].show
          elsif EBUISTYLE==0
            @sprites["battlebox3"].update
          else
            @sprites["battlebox3"].x+=26
          end
        end
        wait(1,true)
      end
      # Show shiny animation for wild Pokémon
      if shinyBattler?(@battle.battlers[1]) && @battle.battlescene
        pbCommonAnimation("Shiny",@battle.battlers[1],nil)
      end
      if @battle.party2.length==2
        if shinyBattler?(@battle.battlers[3]) && @battle.battlescene
          pbCommonAnimation("Shiny",@battle.battlers[3],nil)
        end
      end
    end
    @smTrainerSequence.start if @smTrainerSequence
    ebSpecialSpecies_start(@msgview) if $specialSpecies
  end
  #=============================================================================
  #  Additional changes to opponent's sprites
  #=============================================================================
  alias pbShowOpponent_ebs pbShowOpponent unless self.method_defined?(:pbShowOpponent_ebs)
  def pbShowOpponent(index=0,speech=false)
    if @battle.opponent
      if @battle.opponent.is_a?(Array)
        trainerfile=pbTrainerSpriteFile(@battle.opponent[index].trainertype)
      else
        trainerfile=pbTrainerSpriteFile(@battle.opponent.trainertype)
      end
    else
      trainerfile = nil
    end
    @sprites["battlebox0"].visible=false if @sprites["battlebox0"]
    @sprites["battlebox1"].visible=false if @sprites["battlebox1"]
    @sprites["battlebox2"].visible=false if @sprites["battlebox2"]
    @sprites["battlebox3"].visible=false if @sprites["battlebox3"]
    
    @sprites["opponent"]=DynamicTrainerSprite.new(false,-1,@viewport)
    @sprites["opponent"].setTrainerBitmap(trainerfile) if !trainerfile.nil?
    @sprites["opponent"].toLastFrame
    @sprites["opponent"].lock
    @sprites["opponent"].z=16
    @sprites["opponent"].x=@sprites["enemybase"].x+120
    @sprites["opponent"].y=@sprites["enemybase"].y+((!USEBATTLEBASES && !speech && @battle.endspeechwin == "") ? 0 : 50)
    @sprites["opponent"].opacity=0
    20.times do
      moveEntireScene(-3,-2,true,true)
      @sprites["opponent"].opacity+=12.8
      @sprites["opponent"].x-=4
      @sprites["opponent"].y-=2
      animateBattleSprites(true)
      pbGraphicsUpdate
      pbInputUpdate
    end
  end  
  
  alias pbHideOpponent_ebs pbHideOpponent unless self.method_defined?(:pbHideOpponent_ebs)
  def pbHideOpponent(showboxes=false)
    20.times do
      moveEntireScene(+3,+2,true,true)
      @sprites["opponent"].opacity-=12.8
      @sprites["opponent"].x+=4
      @sprites["opponent"].y+=2
      animateBattleSprites(true)
      pbGraphicsUpdate
      pbInputUpdate
    end
    if showboxes
      @sprites["battlebox0"].visible=true if @sprites["battlebox0"]
      @sprites["battlebox1"].visible=true if @sprites["battlebox1"]
      @sprites["battlebox2"].visible=true if @sprites["battlebox2"]
      @sprites["battlebox3"].visible=true if @sprites["battlebox3"]
    end
    @sprites["opponent"].dispose
  end  
  
  def pbTrainerBattleSpeech
    @briefmessage=false
    if !@battle.doublebattle && @battle.opponent && @battle.midspeech!="" && !@battle.midspeech_done
      speech=@battle.midspeech
      pokemon=@battle.battlers[1]
      if @battle.party2.length > 1
        val=@battle.pbPokemonCount(@battle.party2)
        canspeak=(val==1) ? true : false
      else
        canspeak=(pokemon.hp < pokemon.totalhp*0.5) ? true : false
      end
      if canspeak
        pbBGMPlay(@battle.cuedbgm) if !@battle.cuedbgm.nil?
        pbShowOpponent(0,true)
        @battle.pbDisplayPaused(speech)
        clearMessageWindow
        pbHideOpponent(true)
        @battle.midspeech_done=true
      end
    end
  end
  #=============================================================================
  #  New methods of displaying the pbRecall animation
  #=============================================================================
  alias pbRecall_ebs pbRecall unless self.method_defined?(:pbRecall_ebs)
  def pbRecall(battlerindex)
    balltype = @battle.battlers[battlerindex].pokemon.ballused
    poke = @sprites["pokemon#{battlerindex}"]
    poke.resetParticles
    pbSEPlay(isVersion17? ? "Battle recall" : "recall") if !@sprites["pokemon#{battlerindex}"].hidden
    zoom = poke.zoom_x/20.0
    @sprites["battlebox#{battlerindex}"].visible = false if EBUISTYLE==2
    ballburst = EBBallBurst.new(poke.viewport,poke.x,poke.y,29,poke.zoom_x,balltype)
    ballburst.recall if !@sprites["pokemon#{battlerindex}"].hidden
    for i in 0...32
      next if @sprites["pokemon#{battlerindex}"].hidden
      if i < 20
        poke.tone.red+=25.5
        poke.tone.green+=25.5
        poke.tone.blue+=25.5
        if battlerindex%2==0
          @sprites["battlebox#{battlerindex}"].x+=26
        else
          @sprites["battlebox#{battlerindex}"].x-=26
        end
        @sprites["battlebox#{battlerindex}"].opacity-=25.5
        poke.zoom_x-=zoom
        poke.zoom_y-=zoom
      end
      ballburst.update
      wait(1)
    end
    ballburst.dispose
    ballburst = nil
    poke.visible=false
    if @lowHPBGM
      $game_system.bgm_restore
      @lowHPBGM = false   
    end
  end
  #=============================================================================
  #  New Pokemon damage animations
  #=============================================================================
  alias pbDamageAnimation_ebs pbDamageAnimation unless self.method_defined?(:pbDamageAnimation_ebs)
  def pbDamageAnimation(pkmn,effectiveness)
    @briefmessage = false
    self.afterAnim = false
    pkmnsprite = @sprites["pokemon#{pkmn.index}"]
    databox = @sprites["battlebox#{pkmn.index}"]
    wait(4,true)
    case effectiveness
    when 0
      mult = 2
      pbSEPlay(isVersion17? ? "Battle damage normal" : "normaldamage")
    when 1
      mult = 1
      pbSEPlay(isVersion17? ? "Battle damage weak" : "notverydamage")
    when 2
      mult = 3
      pbSEPlay(isVersion17? ? "Battle damage super" : "superdamage")
    end
    once = false
    (effectiveness==2 ? 3 : 2).times do
      for i in 0...8
        if i < 2
          c = -255*(mult/3.0)
          pkmnsprite.tone = Tone.new(c,c,c)
        elsif i < 4
          c = 255*(mult/3.0)
          pkmnsprite.tone = Tone.new(c,c,c)
        elsif i < 6
          pkmnsprite.visible = false
          pkmnsprite.tone = Tone.new(0,0,0)
        else
          pkmnsprite.visible = true
        end
        if !once
          databox.x += mult*(i.between?(0,1) || i.between?(4,5) ? 1 : -1)*(pkmn.index%2==0 ? -1 : 1)
          databox.y -= mult*(i.between?(0,1) || i.between?(4,5) ? 1 : -1)*(pkmn.index%2==0 ? -1 : 1)
          once = true if i == 7
        end
        pkmnsprite.still
        wait(1,true)
      end
    end
    # animations for triggering Substitute
    if pkmn.effects[PBEffects::Substitute]==0 && pkmnsprite.isSub
      self.setSubstitute(pkmn.index,false)
    elsif pkmn.effects[PBEffects::Substitute]>0 && !pkmnsprite.isSub
      self.setSubstitute(pkmn.index,true)
    end
  end
  #=============================================================================
  #  New methods of displaying the pbFainted animation
  #=============================================================================
  alias pbFainted_ebs pbFainted unless self.method_defined?(:pbFainted_ebs)
  def pbFainted(pkmn)
    clearMessageWindow
    @vector.reset
    battlerindex=pkmn.index
    frames=pbCryFrameLength(pkmn.pokemon)
    pbPlayCry(pkmn.pokemon)
    poke = @sprites["pokemon#{battlerindex}"]
    poke.resetParticles
    frames.times do
      animateBattleSprites
      pbGraphicsUpdate
      pbInputUpdate
    end
    pbSEPlay(isVersion17? ? "Pkmn faint" : "faint")
    zoom=poke.zoom_x/(20.0*2)
    poke.showshadow=false
    poke.sprite.src_rect.height=poke.oy
    20.times do
      poke.still
      poke.sprite.src_rect.y-=6
      poke.opacity-=12.8
      @sprites["battlebox#{battlerindex}"].opacity-=25.5
      wait(1,true)
    end
    poke.src_rect.set(0,0,poke.bitmap.width,poke.bitmap.height)
    poke.fainted=true
  end
  #=============================================================================
  #  Allow for sprite animation during Battlebox HP changes
  #=============================================================================
  alias pbHPChanged_ebs pbHPChanged unless self.method_defined?(:pbHPChanged_ebs)
  def pbHPChanged(pkmn,oldhp,anim=false)
    @briefmessage=false
    hpchange=pkmn.hp-oldhp
    if hpchange < 0
      hpchange=-hpchange
      PBDebug.log("[#{pkmn.pbThis} lost #{hpchange} HP, now has #{pkmn.hp} HP]") if $INTERNAL
    else
      PBDebug.log("[#{pkmn.pbThis} gained #{hpchange} HP, now has #{pkmn.hp} HP]") if $INTERNAL
    end
    if anim && @battle.battlescene
      if pkmn.hp > oldhp
        pbCommonAnimation("HealthUp",pkmn,nil)
      elsif pkmn.hp < oldhp
        pbCommonAnimation("HealthDown",pkmn,nil)
      end
    end
    sprite=@sprites["battlebox#{pkmn.index}"]
    sprite.animateHP(oldhp,pkmn.hp)
    while sprite.animatingHP
      animateBattleSprites(true)
      pbGraphicsUpdate
      pbInputUpdate
      sprite.update
    end
    if USELOWHPBGM && !@battle.doublebattle && pkmn.index%2==0
      if pkmn.hp <= pkmn.totalhp*0.25 && pkmn.hp > 0
        $game_system.bgm_memorize
        pbBGMPlay("lowhpbattle")
        @lowHPBGM = true
      elsif @lowHPBGM
        $game_system.bgm_restore
        @lowHPBGM = false        
      end
    end
  end
  #=============================================================================
  #  Allow for sprite animation during Battlebox EXP changes
  #=============================================================================
  alias pbEXPBar_ebs pbEXPBar unless self.method_defined?(:pbEXPBar_ebs)
  def pbEXPBar(pokemon,battler,startexp,endexp,tempexp1,tempexp2)
    clearMessageWindow
    if battler
      @sprites["battlebox#{battler.index}"].refreshExpLevel
      exprange=(endexp-startexp)
      startexplevel=0
      endexplevel=0
      if exprange!=0
        width = EBUISTYLE==2 ? pbBitmap("#{checkEBFolderPath}/nextGen/expBar").width : PokeBattle_SceneConstants::EXPGAUGESIZE
        startexplevel=(tempexp1-startexp)*width/exprange
        endexplevel=(tempexp2-startexp)*width/exprange
      end
      pbSEPlay("BW_exp") if !@battle.doublebattle
      @sprites["battlebox#{battler.index}"].animateEXP(startexplevel,endexplevel)
      while @sprites["battlebox#{battler.index}"].animatingEXP
        animateBattleSprites(true)
        pbGraphicsUpdate
        pbInputUpdate
        @sprites["battlebox#{battler.index}"].update
      end
      Audio.se_stop
      20.times do
        pbGraphicsUpdate
        animateBattleSprites
      end
    end
  end
  
  alias pbLevelUp_ebs pbLevelUp unless self.method_defined?(:pbLevelUp_ebs)
  def pbLevelUp(*args)
    pbMEPlay("BW_lvup",80)
    pbLevelUp_ebs(*args)
  end
  
  def pbTopRightWindow(text)
    viewport=Viewport.new(0,0,Graphics.width,VIEWPORT_HEIGHT)
    viewport.z=@viewport.z+6
    window=Window_AdvancedTextPokemon.new(text)
    window.viewport=viewport
    window.width=198
    window.y=0
    window.x=Graphics.width-window.width
    pbPlayDecisionSE()
    loop do
      Graphics.update
      Input.update
      window.update
      animateBattleSprites
      if Input.trigger?(Input::C)
        break
      end
    end
    window.dispose
    viewport.dispose
  end
  
  def setSubstitute(index,set=true)
    10.times do
      @sprites["pokemon#{index}"].x += (index%2==0) ? -4 : 2
      @sprites["pokemon#{index}"].y -= (index%2==0) ? -2 : 1
      @sprites["pokemon#{index}"].opacity -= 25.5
      wait(1)
    end
    if set
      @sprites["pokemon#{index}"].setSubstitute
    else
      @sprites["pokemon#{index}"].removeSubstitute
    end
    10.times do
      @sprites["pokemon#{index}"].x -= (index%2==0) ? -4 : 2
      @sprites["pokemon#{index}"].y += (index%2==0) ? -2 : 1
      @sprites["pokemon#{index}"].opacity += 25.5
      wait(1)
    end
  end
  
  def pbGraphicsUpdate
    Graphics.update
  end
  #=============================================================================
  # Shows the player's Poké Ball being thrown to capture a Pokémon.
  #=============================================================================
  alias pbThrowAndDeflect_ebs pbThrowAndDeflect unless self.method_defined?(:pbThrowAndDeflect_ebs)
  def pbThrowAndDeflect(ball,targetBattler)
  end
  alias pbHideCaptureBall_ebs pbHideCaptureBall unless self.method_defined?(:pbHideCaptureBall_ebs)
  def pbHideCaptureBall
  end
  
  alias pokeballThrow_ebs pokeballThrow unless self.method_defined?(:pokeballThrow_ebs)
  def pokeballThrow(*args)
    if PokeBattle_Scene.instance_method(:pokeballThrow_ebs).arity <= -7
      ball, shakes, critical, targetBattler, scene, battler, burst, showplayer = args
    else
      ball, shakes, targetBattler, scene, battler, burst, showplayer = args
    end
    burst = -1 if burst.nil?; showplayer = false if showplayer.nil?
    @orgPos=nil
    if @safaribattle
      @playerfix=false
    end
    balltype=pbGetBallType(ball)
    ballframe=0
    # sprites
    spritePoke = @sprites["pokemon#{targetBattler}"]
    @sprites["ballshadow"] = Sprite.new(@viewport)
    @sprites["ballshadow"].bitmap = Bitmap.new(34,34)
    @sprites["ballshadow"].bitmap.drawCircle(Color.new(0,0,0))
    @sprites["ballshadow"].ox = @sprites["ballshadow"].bitmap.width/2
    @sprites["ballshadow"].oy = @sprites["ballshadow"].bitmap.height/2
    @sprites["ballshadow"].z = 32
    @sprites["ballshadow"].opacity = 255*0.25
    @sprites["ballshadow"].visible = false
    @sprites["captureball"] = Sprite.new(@viewport)
    @sprites["captureball"].bitmap=BitmapCache.load_bitmap("#{checkEBFolderPath}/pokeballs")
    balltype = 0 if balltype*41 >= @sprites["captureball"].bitmap.width
    @sprites["captureball"].src_rect.set(balltype*41,ballframe*40,41,40)
    @sprites["captureball"].ox = 20
    @sprites["captureball"].oy = 20
    @sprites["captureball"].z = 32
    @sprites["captureball"].zoom_x = 4
    @sprites["captureball"].zoom_y = 4
    @sprites["captureball"].visible = false
    pokeball = @sprites["captureball"]
    shadow = @sprites["ballshadow"]
    # position "camera"
    @sprites["battlebox0"].visible = false if @sprites["battlebox0"]
    @sprites["battlebox2"].visible = false if @sprites["battlebox2"]
    vector = @battle.doublebattle ? VECTOR2 : VECTOR1
    sx, sy = @vector.spoof(ENEMYVECTOR)
    curve = calculateCurve(sx-260,sy-160,sx-60,sy-200,sx,sy-140,24)
    # position pokeball
    pokeball.x = sx - 260
    pokeball.y = sy - 100
    pokeball.visible = true
    shadow.x = pokeball.x
    shadow.y = pokeball.y
    shadow.zoom_x = 0
    shadow.zoom_y = 0
    shadow.visible = true
    # throwing animation
    critical ? pbSEPlay("throw_critical") : pbSEPlay("throw")
    for i in 0...28
      @vector.set(ENEMYVECTOR) if i == 4
      if @safaribattle && i < 16
        @sprites["player"].x -= 75
        @sprites["player"].y += 38
        @sprites["player"].zoom_x += 0.125
        @sprites["player"].zoom_y += 0.125
      end
      ballframe += 1
      ballframe = 0 if ballframe > 7
      if i < 24
        pokeball.x = curve[i][0]
        pokeball.y = curve[i][1]
        pokeball.zoom_x -= (pokeball.zoom_x - spritePoke.zoom_x)*0.2
        pokeball.zoom_y -= (pokeball.zoom_y - spritePoke.zoom_y)*0.2
        shadow.x = pokeball.x
        shadow.y = pokeball.y + 140 + 16 + (24-i)
        shadow.zoom_x += 0.8/24
        shadow.zoom_y += 0.3/24
      end
      pokeball.src_rect.set(balltype*41,ballframe*40,41,40)
      wait(1,true)
    end    
    for i in 0...4
      pokeball.src_rect.set(balltype*41,(7+i)*40,41,40)
      wait(1)
    end
    pbSEPlay(isVersion17? ? "Battle recall" : "recall")
    # Burst animation here
    if burst >=0 && scene.battle.battlescene && CUSTOMANIMATIONS
      scene.pbCommonAnimation("BallBurst#{burst}",battler,nil)
    end
    pokeball.z=spritePoke.z-1
    shadow.z=pokeball.z-1
    spritePoke.showshadow=false
    if !CUSTOMANIMATIONS
      ballburst = EBBallBurst.new(pokeball.viewport,pokeball.x,pokeball.y,50,@vector.zoom1,balltype)
      ballburst.catching
    end
    for i in 0...(CUSTOMANIMATIONS ? 20 : 32)
      if i < 20
        spritePoke.zoom_x -= 0.075
        spritePoke.zoom_y -= 0.075
        spritePoke.tone.red += 25.5
        spritePoke.tone.green += 25.5
        spritePoke.tone.blue += 25.5
        spritePoke.y -= 8
      end
      ballburst.update if !CUSTOMANIMATIONS
      wait(1)
    end
    if !CUSTOMANIMATIONS
      ballburst.dispose
      ballburst = nil
    end
    spritePoke.y += 160
    pokeball.src_rect.y -= 40
    wait(1)
    pokeball.src_rect.y = 0
    wait(1)
    t = 0
    i = 51
    10.times do
      t += i
      i =- 51 if t >= 255
      pokeball.tone=Tone.new(t,t,t)
      wait(1)
    end
    #################
    pbSEPlay(isVersion17? ? "Battle jump to ball" : "jumptoball")
    for i in 0...20
      pokeball.src_rect.y = 40*(((i-6)/2)+1) if i%2==0 && i >= 6
      pokeball.y += 7
      shadow.zoom_x += 0.01
      shadow.zoom_y += 0.01
      wait(1)
    end
    pokeball.src_rect.y = 0
    pbSEPlay(isVersion17? ? "Battle ball drop" : "balldrop")
    for i in 0...14
      pokeball.src_rect.y = 40*((i/2)+1) if i%2==0
      pokeball.y -= 6 if i < 7
      pokeball.y += 6 if i >= 7
      if i <= 7
        shadow.zoom_x -= 0.005
        shadow.zoom_y -= 0.005
      else
        shadow.zoom_x += 0.005
        shadow.zoom_y += 0.005
      end
      wait(1)
    end
    pokeball.src_rect.y = 0
    pbSEPlay(isVersion17? ? "Battle ball drop" : "balldrop",80)
    [shakes,3].min.times do
      wait(40)
      pbSEPlay(isVersion17? ? "Battle ball shake" : "ballshake")
      pokeball.src_rect.y = 11*40
      wait(1)
      for i in 0...2
        2.times do
          pokeball.src_rect.y += 40*(i < 1 ? 1 : -1)
          wait(1)
        end
      end
      pokeball.src_rect.y = 14*40
      wait(1)
      for i in 0...2
        2.times do
          pokeball.src_rect.y += 40*(i < 1 ? 1 : -1)
          wait(1)
        end
      end
      pokeball.src_rect.y = 0
      wait(1)
    end
    if shakes < 4
      wait(40)
      pokeball.src_rect.y=9*40
      pbGraphicsUpdate
      pokeball.src_rect.y+=40
      pbGraphicsUpdate
      pbSEPlay(isVersion17? ? "Battle recall" : "recall")
      spritePoke.showshadow=true
      ballburst = EBBallBurst.new(pokeball.viewport,pokeball.x,pokeball.y,50,@vector.zoom1,balltype)
      for i in 0...32
        if i < 20
          pokeball.opacity -= 25.5
          shadow.opacity -= 4
          spritePoke.zoom_x += 0.075
          spritePoke.zoom_y += 0.075
          spritePoke.tone.red -= 12.8
          spritePoke.tone.green -= 12.8
          spritePoke.tone.blue -= 12.8
        end
        ballburst.update
        wait(1)
      end
      ballburst.dispose
      ballburst = nil
      @sprites["battlebox0"].visible = true if @sprites["battlebox0"]
      @sprites["battlebox2"].visible = true if @sprites["battlebox2"]
      clearMessageWindow
      @vector.set(vector)
      20.times do
        if @safaribattle
          @sprites["player"].x += 60
          @sprites["player"].y -= 30
          @sprites["player"].zoom_x -= 0.1
          @sprites["player"].zoom_y -= 0.1
        end
        wait(1,true)
      end
    else
      spritePoke.visible=false
      wait(40)
      pbSEPlay(isVersion17? ? "Battle ball drop" : "balldrop",80)
      pokeball.color = Color.new(0,0,0,0)
      fp = {}
      for j in 0...3
        fp["#{j}"] = Sprite.new(pokeball.viewport)
        fp["#{j}"].bitmap = pbBitmap("Graphics/Animations/ebStar")
        fp["#{j}"].ox = fp["#{j}"].bitmap.width/2
        fp["#{j}"].oy = fp["#{j}"].bitmap.height/2
        fp["#{j}"].x = pokeball.x
        fp["#{j}"].y = pokeball.y
        fp["#{j}"].opacity = 0
        fp["#{j}"].z = pokeball.z + 1
      end
      for i in 0...16
        for j in 0...3
          fp["#{j}"].y -= [3,4,3][j]
          fp["#{j}"].x -= [3,0,-3][j]
          fp["#{j}"].opacity += 32*(i < 8 ? 1 : -1)
          fp["#{j}"].angle += [4,2,-4][j]
        end
        @sprites["battlebox#{targetBattler}"].opacity-=25.5
        pokeball.color.alpha += 8
        wait(1)
      end
      if @battle.opponent
        5.times do
          pokeball.opacity -= 51
          shadow.opacity -= 13
          wait(1)
        end
        @vector.set(vector)
        wait(20,true)
      end
      spritePoke.clear
    end
    @playerfix=true if @safaribattle
  end
  
  alias pbThrowSuccess_ebs pbThrowSuccess unless self.method_defined?(:pbThrowSuccess_ebs)
  def pbThrowSuccess
    if !@battle.opponent
      @briefmessage = true
      pbMEPlay("BW_captured",70)
      pbBGMPlay("#{CAPTUREBGM}") if !CAPTUREBGM.nil?
      frames = (3.5*Graphics.frame_rate).to_i
      wait(frames)
    end
    clearMessageWindow
    @sprites["ballshadow"].dispose
    @sprites["captureball"].dispose
    vector = @battle.doublebattle ? VECTOR2 : VECTOR1
    @vector.set(vector)
  end
  #=============================================================================
  #  New methods of displaying TrainerSendOut animations
  #=============================================================================
  alias pbTrainerSendOut_ebs pbTrainerSendOut unless self.method_defined?(:pbTrainerSendOut_ebs)
  def pbTrainerSendOut(battlerindex,pkmn)
    @smTrainerSequence.sendout if @smTrainerSequence
    # initial configuration of used variables
    metrics=load_data("Data/metrics.dat")
    balltype = []
    ballframe = 0
    dig = []
    alt = []
    curve = []
    orgcord = []
    burst = {}
    dust = {}
    # the amount of current Pokemon handled
    max = @firstsendout ? (@battle.doublebattle ? 2 : 1) : 1
    # sets up Pokemon sprites, Pokeballs and databoxes
    for m in 0...max
      m = @firstsendout ? m : 0
      i = @firstsendout ? [1,3][m] : battlerindex
      @sprites["battlebox#{i}"].x = -264 - [0,8,0,10][i]
      @sprites["battlebox#{i}"].y = @battle.doublebattle ? [0,60,0,8][i] : [0,24,0,8][i]
      
      @sprites["pokeball#{i}"] = Sprite.new(@viewport)
      @sprites["pokeball#{i}"].bitmap=BitmapCache.load_bitmap("#{checkEBFolderPath}/pokeballs")
      balltype.push(@battle.battlers[i].pokemon.ballused)
      balltype[m] = 0 if balltype[m]*41 >= @sprites["pokeball#{i}"].bitmap.width
      @sprites["pokeball#{i}"].src_rect.set(balltype[m]*41,ballframe*40,41,40)
      @sprites["pokeball#{i}"].ox = 20
      @sprites["pokeball#{i}"].oy = 20
      @sprites["pokeball#{i}"].zoom_x = 0.75
      @sprites["pokeball#{i}"].zoom_y = 0.75
      @sprites["pokeball#{i}"].z = 19
      @sprites["pokeball#{i}"].opacity = 0
      
      species = getBattlerPokemon(@battle.battlers[i]).species
      handled = false
      for poke in [:DIGLETT,:DUGTRIO]
        num = getConst(PBSpecies,poke)
        next if num.nil? || handled
        if species == num
          dig.push(true)
          handled = true
        end
      end
      dig.push(false) if !handled
      
      @sprites["pokemon#{i}"].setPokemonBitmap(getBattlerPokemon(@battle.battlers[i]),false)
      @sprites["pokemon#{i}"].showshadow = false
      orgcord.push(@sprites["pokemon#{i}"].oy)
      @sprites["pokemon#{i}"].oy = @sprites["pokemon#{i}"].height/2 if !dig[m]
      @sprites["pokemon#{i}"].tone = Tone.new(255,255,255)
      @sprites["pokemon#{i}"].opacity = 255
      @sprites["pokemon#{i}"].visible = false
      curve.push(
        calculateCurve(
            @sprites["pokemon#{i}"].x,@sprites["enemybase"].y-50-(orgcord[m]-@sprites["pokemon#{i}"].oy),
            @sprites["pokemon#{i}"].x,@sprites["enemybase"].y-100-(orgcord[m]-@sprites["pokemon#{i}"].oy),
            @sprites["pokemon#{i}"].x,@sprites["enemybase"].y-50-(orgcord[m]-@sprites["pokemon#{i}"].oy),30
        )
      )
    end
    # initial trainer fade and Pokeball throwing animation
    pbSEPlay("throw")
    for j in 0...30
      ballframe += 1
      ballframe = 0 if ballframe > 7
      for m in 0...max
        m = @firstsendout ? m : 0
        i = @firstsendout ? [1,3][m] : battlerindex
        t = ["","2"][m]
        if @firstsendout && @sprites["trainer#{t}"]
          @sprites["trainer#{t}"].zoom_x -= 0.02
          @sprites["trainer#{t}"].zoom_y -= 0.02
          @sprites["trainer#{t}"].x += 1
          @sprites["trainer#{t}"].y -= 2
          @sprites["trainer#{t}"].opacity -= 12.8
        end
        @sprites["pokeball#{i}"].src_rect.set(balltype[m]*41,ballframe*40,41,40)
        @sprites["pokeball#{i}"].x = curve[m][j][0]
        @sprites["pokeball#{i}"].y = curve[m][j][1]
        @sprites["pokeball#{i}"].opacity += 51
      end
      @sprites["oppArrow"].hide if @battle.opponent && SHOWPARTYARROWS && EBUISTYLE < 2
      wait(1)
    end
    # configuring the Y position of Pokemon sprites
    for m in 0...max
      m = @firstsendout ? m : 0
      i = @firstsendout ? [1,3][m] : battlerindex
      @sprites["pokemon#{i}"].visible = true
      @sprites["pokemon#{i}"].y -= 50 + (orgcord[m] - @sprites["pokemon#{i}"].oy) if !dig[m]
      @sprites["pokemon#{i}"].zoom_x = 0
      @sprites["pokemon#{i}"].zoom_y = 0
      @sprites["battlebox#{i}"].appear
      
      burst["#{i}"] = EBBallBurst.new(@viewport,@sprites["pokeball#{i}"].x,@sprites["pokeball#{i}"].y,19,1,balltype[m])
    end
    # starting Pokemon release animation
    pbSEPlay(isVersion17? ? "Battle recall" : "recall")
    @sendingOut = false
    clearMessageWindow
    for j in 0...16
      for m in 0...max
        m = @firstsendout ? m : 0
        i = @firstsendout ? [1,3][m] : battlerindex
        burst["#{i}"].update
        next if j < 4
        @sprites["pokeball#{i}"].opacity -= 51
        @sprites["pokemon#{i}"].zoom_x += 0.1*@vector.zoom1
        @sprites["pokemon#{i}"].zoom_y += 0.1*@vector.zoom1
        @sprites["pokemon#{i}"].still
        if EBUISTYLE==2
          @sprites["battlebox#{i}"].show
        elsif EBUISTYLE==0
          @sprites["battlebox#{i}"].update
        else
          @sprites["battlebox#{i}"].x += 22
        end
      end
      wait(1)
    end
    for j in 0...2
      for m in 0...max
        m = @firstsendout ? m : 0
        i = @firstsendout ? [1,3][m] : battlerindex
        @sprites["pokemon#{i}"].zoom_x -= 0.1*@vector.zoom1
        @sprites["pokemon#{i}"].zoom_y -= 0.1*@vector.zoom1
        @sprites["pokemon#{i}"].still
        burst["#{i}"].update
        @sprites["battlebox#{i}"].x -= 2 if EBUISTYLE==1
        playBattlerCry(@battle.battlers[i]) if j == 0
      end
      wait(1)
    end
    for j in 0...18
      for m in 0...max
        m = @firstsendout ? m : 0
        i = @firstsendout ? [1,3][m] : battlerindex
        burst["#{i}"].update
        burst["#{i}"].dispose if j == 17
        next if j < 8
        @sprites["pokemon#{i}"].tone.red -= 51 if @sprites["pokemon#{i}"].tone.red > 0
        @sprites["pokemon#{i}"].tone.green -= 51 if @sprites["pokemon#{i}"].tone.green > 0
        @sprites["pokemon#{i}"].tone.blue -= 51 if @sprites["pokemon#{i}"].tone.blue > 0
      end
      wait(1)
    end
    burst = nil
    # dropping Pokemon onto the ground
    for j in 0...12
      for m in 0...max
        m = @firstsendout ? m : 0
        i = @firstsendout ? [1,3][m] : battlerindex
        if j == 11
          @sprites["pokemon#{i}"].showshadow = true
        elsif j > 0
          @sprites["pokemon#{i}"].y += 5 if !dig[m]
        else
          @sprites["pokemon#{i}"].y += orgcord[m] - @sprites["pokemon#{i}"].oy if !dig[m]
          @sprites["pokemon#{i}"].oy = orgcord[m] if !dig[m]
        end
      end
      wait(1) if j > 0 && j < 11
    end
    # handler for screenshake (and weight animation upon entry)
    for m in 0...max
      m = @firstsendout ? m : 0
      i = @firstsendout ? [1,3][m] : battlerindex
      val = getBattlerMetrics(metrics,@battle.battlers[i]); val = 1 if dig[m]
      dust["#{i}"] = EBDustParticle.new(@viewport,@sprites["pokemon#{i}"],1)
      @sprites["pokeball#{i}"].dispose
      alt.push(val)
    end
    shake = false
    heavy = false
    onlydig = false
    for m in 0...max
      i = @firstsendout ? [1,3][m] : battlerindex
      shake = true if alt[m] < 1 && !dig[m]
      heavy = true if @battle.battlers[i].weight*0.1 >= 291 && alt[m] < 1 && !dig[m]
    end
    for m in 0...max; onlydig = true if !shake && dig[m]; end
    pbSEPlay("drop") if shake && !heavy
    pbSEPlay("drop_heavy") if heavy
    mult = heavy ? 2 : 1
    for i in 0...8
      next if onlydig
      for m in 0...max
        m = @firstsendout ? m : 0
        j = @firstsendout ? [1,3][m] : battlerindex
        next if alt[m] < 1
        @sprites["pokemon#{j}"].y += (i/4 < 1) ? 4 : -4
      end
      if shake
        y=(i/4 < 1) ? 2 : -2
        moveEntireScene(0,y*mult)
      end
      wait(1)
    end
    # dust animation upon entry of heavy pokemon
    for j in 0..24
      next if !heavy
      for m in 0...max
        m = @firstsendout ? m : 0
        i = @firstsendout ? [1,3][m] : battlerindex
        dust["#{i}"].update if @battle.battlers[i].weight*0.1 >= 291 && alt[m] < 1
        dust["#{i}"].dispose if j == 24
      end
      wait(1,true) if j < 24
    end
    dust = nil
    # shiny animation upon entry
    for m in 0...max
      m = @firstsendout ? m : 0
      i = @firstsendout ? [1,3][m] : battlerindex
      pbCommonAnimation("Shiny",@battle.battlers[i],nil) if shinyBattler?(@battle.battlers[i])
    end
    @sendingOut = false
    return true
  end
  #=============================================================================
  #  New methods of displaying PokemonSendOut animations
  #=============================================================================
  alias pbSendOut_ebs pbSendOut unless self.method_defined?(:pbSendOut_ebs)
  def pbSendOut(battlerindex,pkmn) # Player sending out Pokémon
    # initial configuration of used variables
    metrics=load_data("Data/metrics.dat")
    balltype = []
    ballframe = 0
    dig = []
    alt = []
    curve = []
    orgcord = []
    burst = {}
    dust = {}
    # the amount of current Pokemon handled
    max = @firstsendout ? (@battle.doublebattle ? 2 : 1) : 1
    defaultvector = @battle.doublebattle ? VECTOR2 : VECTOR1
    # sets up Pokemon sprites, Pokeballs and databoxes
    for m in 0...max
      m = @firstsendout ? m : 0
      i = @firstsendout ? [0,2][m] : battlerindex
      @sprites["battlebox#{i}"].x = @viewport.rect.width + 10
      @sprites["battlebox#{i}"].y = @battle.doublebattle ? [180,0,232,0][i] : [204,0,232,0][i]
      
      @sprites["pokeball#{i}"] = Sprite.new(@viewport)
      @sprites["pokeball#{i}"].bitmap=BitmapCache.load_bitmap("#{checkEBFolderPath}/pokeballs")
      balltype.push(@battle.battlers[i].pokemon.ballused)
      balltype[m] = 0 if balltype[m]*41 >= @sprites["pokeball#{i}"].bitmap.width
      @sprites["pokeball#{i}"].src_rect.set(balltype[m]*41,ballframe*40,41,40)
      @sprites["pokeball#{i}"].ox = 20
      @sprites["pokeball#{i}"].oy = 20
      @sprites["pokeball#{i}"].zoom_x = 0.75
      @sprites["pokeball#{i}"].zoom_y = 0.75
      @sprites["pokeball#{i}"].z = 19
      @sprites["pokeball#{i}"].opacity = 0
      
      species = getBattlerPokemon(@battle.battlers[i]).species
      handled = false
      for poke in [:DIGLETT,:DUGTRIO]
        num = getConst(PBSpecies,poke)
        next if num.nil? || handled
        if species == num
          dig.push(true)
          handled = true
        end
      end
      dig.push(false) if !handled
      
      @sprites["pokemon#{i}"].setPokemonBitmap(getBattlerPokemon(@battle.battlers[i]),true)
      @sprites["pokemon#{i}"].showshadow = false
      orgcord.push(@sprites["pokemon#{i}"].oy)
      @sprites["pokemon#{i}"].oy = @sprites["pokemon#{i}"].height/2 if !dig[m]
      @sprites["pokemon#{i}"].tone = Tone.new(255,255,255)
      @sprites["pokemon#{i}"].opacity = 255
      @sprites["pokemon#{i}"].visible = false
    end
    # vector alignment
    @vector.set(@firstsendout ? SENDOUTVECTOR1 : SENDOUTVECTOR2)
    (@firstsendout ? 44 : 20).times do
      for m in 0...max
        next if !@firstsendout
        t = ["","B"][m]
        @sprites["player#{t}"].opacity += 25.5 if @sprites["player#{t}"]
      end
      wait(1,true)
    end
    # player throw animation
    for j in 0...7
      next if !@firstsendout
      for m in 0...max
        t = ["","B"][m]
        if @sprites["player#{t}"]
          @sprites["player#{t}"].src_rect.x += @sprites["player#{t}"].bitmap.width/4 if j == 0
          @sprites["player#{t}"].x -= 2 if j > 0
        end
      end
      wait(1,true)
    end
    wait(6,true) if @firstsendout
    for j in 0...4
      next if !@firstsendout
      for m in 0...max
        t = ["","B"][m]
        if @sprites["player#{t}"]
          @sprites["player#{t}"].src_rect.x += @sprites["player#{t}"].bitmap.width/4 if j%2==0
          @sprites["player#{t}"].x += 3
        end
      end
      wait(1,true)
    end
    pbSEPlay("throw")
    addzoom = @sprites["playerbase"].zoom_x*2
    # calculating the curve for the Pokeball trajectory
    posX = @firstsendout ? [80,30] : [100,40]
    posY = @firstsendout ? [40,160,120] : [70,170,120]
    z1 = @firstsendout ? addzoom : 1
    z2 = @firstsendout ? addzoom : 2
    z3 = @firstsendout ? 1 : 2
    for m in 0...max
      m = @firstsendout ? m : 0
      i = @firstsendout ? [0,2][m] : battlerindex
      curve.push(
        calculateCurve(
            @sprites["pokemon#{i}"].x-posX[0],@sprites["playerbase"].y-posY[0]*z1-(orgcord[m]-@sprites["pokemon#{i}"].oy)*z2,
            @sprites["pokemon#{i}"].x-posX[1],@sprites["playerbase"].y-posY[1]*z1-(orgcord[m]-@sprites["pokemon#{i}"].oy)*z2,
            @sprites["pokemon#{i}"].x,@sprites["playerbase"].y-posY[2]*z1-(orgcord[m]-@sprites["pokemon#{i}"].oy)*z2,28
        )
      )
      @sprites["pokeball#{i}"].zoom_x *= addzoom
      @sprites["pokeball#{i}"].zoom_y *= addzoom
    end
    # initial Pokeball throwing animation
    for j in 0...48
      ballframe += 1
      ballframe = 0 if ballframe > 7
      for m in 0...max
        m = @firstsendout ? m : 0
        i = @firstsendout ? [0,2][m] : battlerindex
        t = ["","2"][m]
        @sprites["pokeball#{i}"].src_rect.set(balltype[m]*41,ballframe*40,41,40)
        @sprites["pokeball#{i}"].x = curve[m][j][0] if j < 28
        @sprites["pokeball#{i}"].y = curve[m][j][1] if j < 28
        @sprites["pokeball#{i}"].opacity += 42
      end
      @sprites["plArrow"].hide if @battle.opponent && SHOWPARTYARROWS && EBUISTYLE < 2
      wait(1)
    end
    # configuring the Y position of Pokemon sprites
    for m in 0...max
      m = @firstsendout ? m : 0
      i = @firstsendout ? [0,2][m] : battlerindex
      @sprites["pokemon#{i}"].visible = true
      @sprites["pokemon#{i}"].y -= 120 + (orgcord[m] - @sprites["pokemon#{i}"].oy)*z3 if !dig[m]
      @sprites["pokemon#{i}"].zoom_x = 0
      @sprites["pokemon#{i}"].zoom_y = 0
      @sprites["battlebox#{i}"].appear
      
      burst["#{i}"] = EBBallBurst.new(@viewport,@sprites["pokeball#{i}"].x,@sprites["pokeball#{i}"].y,29,(@firstsendout ? 1 : 2),balltype[m])
    end
    # starting Pokemon release animation
    pbSEPlay(isVersion17? ? "Battle recall" : "recall")
    clearMessageWindow(true)
    for j in 0...16
      for m in 0...max
        m = @firstsendout ? m : 0
        i = @firstsendout ? [0,2][m] : battlerindex
        t = ["","B"][m]
        @sprites["player#{t}"].opacity -= 25.5 if @firstsendout if @sprites["player#{t}"]
        burst["#{i}"].update
        next if j < 4
        @sprites["pokeball#{i}"].opacity -= 51
        if @firstsendout
          @sprites["pokemon#{i}"].zoom_x += 0.05*addzoom*2
          @sprites["pokemon#{i}"].zoom_y += 0.05*addzoom*2
        else
          @sprites["pokemon#{i}"].zoom_x += 0.1*@vector.zoom1*2
          @sprites["pokemon#{i}"].zoom_y += 0.1*@vector.zoom1*2
        end
        @sprites["pokemon#{i}"].still
        if EBUISTYLE==2
          @sprites["battlebox#{i}"].show
        elsif EBUISTYLE==0
          @sprites["battlebox#{i}"].update
        else
          @sprites["battlebox#{i}"].x -= 22
        end
      end
      wait(1)
    end
    for j in 0...2
      for m in 0...max
        m = @firstsendout ? m : 0
        i = @firstsendout ? [0,2][m] : battlerindex
        if @firstsendout
          @sprites["pokemon#{i}"].zoom_x -= 0.05*addzoom*2
          @sprites["pokemon#{i}"].zoom_y -= 0.05*addzoom*2
        else
          @sprites["pokemon#{i}"].zoom_x -= 0.1*@vector.zoom1*2
          @sprites["pokemon#{i}"].zoom_y -= 0.1*@vector.zoom1*2
        end
        @sprites["pokemon#{i}"].still
        burst["#{i}"].update
        @sprites["battlebox#{i}"].x += 2 if EBUISTYLE==1
        playBattlerCry(@battle.battlers[i]) if j == 0
      end
      wait(1)
    end
    for j in 0...18
      for m in 0...max
        m = @firstsendout ? m : 0
        i = @firstsendout ? [0,2][m] : battlerindex
        burst["#{i}"].update
        burst["#{i}"].dispose if j == 17
        next if j < 8
        @sprites["pokemon#{i}"].tone.red -= 51 if @sprites["pokemon#{i}"].tone.red > 0
        @sprites["pokemon#{i}"].tone.green -= 51 if @sprites["pokemon#{i}"].tone.green > 0
        @sprites["pokemon#{i}"].tone.blue -= 51 if @sprites["pokemon#{i}"].tone.blue > 0
      end
      wait(1)
    end
    burst = nil
    # dropping Pokemon onto the ground
    if !@firstsendout
      for m in 0...max
        m = @firstsendout ? m : 0
        i = @firstsendout ? [0,2][m] : battlerindex
        @sprites["pokemon#{i}"].y += (orgcord[m] - @sprites["pokemon#{i}"].oy)*2 if !dig[m]
        @sprites["pokemon#{i}"].oy = orgcord[m] if !dig[m]
      end
    end
    for j in 0...12
      for m in 0...max
        m = @firstsendout ? m : 0
        i = @firstsendout ? [0,2][m] : battlerindex
        if j == 11
          @sprites["pokemon#{i}"].showshadow = true
        elsif j > 0
          @sprites["pokemon#{i}"].y += 12 if !dig[m]
        else
          @sprites["pokemon#{i}"].y += orgcord[m] - @sprites["pokemon#{i}"].oy if !dig[m]
          @sprites["pokemon#{i}"].oy = orgcord[m] if !dig[m]
        end
      end
      wait(1) if j > 0 && j < 11
    end
    # handler for screenshake (and weight animation upon entry)
    for m in 0...max
      m = @firstsendout ? m : 0
      i = @firstsendout ? [0,2][m] : battlerindex
      val = getBattlerMetrics(metrics,@battle.battlers[i]); val = 1 if dig[m]
      dust["#{i}"] = EBDustParticle.new(@viewport,@sprites["pokemon#{i}"],(@firstsendout ? 1 : 2))
      @sprites["pokeball#{i}"].dispose
      alt.push(val)
    end
    shake = false
    heavy = false
    onlydig = false
    for m in 0...max
      i = @firstsendout ? [0,2][m] : battlerindex
      shake = true if alt[m] < 1 && !dig[m]
      heavy = true if @battle.battlers[i].weight*0.1 >= 291 && alt[m] < 1 && !dig[m]
    end
    for m in 0...max; onlydig = true if !shake && dig[m]; end
    pbSEPlay("drop") if shake && !heavy
    pbSEPlay("drop_heavy") if heavy
    mult = heavy ? 2 : 1
    for i in 0...8
      next if onlydig
      for m in 0...max
        m = @firstsendout ? m : 0
        j = @firstsendout ? [0,2][m] : battlerindex
        next if alt[m] < 1
        @sprites["pokemon#{j}"].y += (i/4 < 1) ? 4 : -4
      end
      if shake
        y=(i/4 < 1) ? 2 : -2
        moveEntireScene(0,y*mult)
      end
      wait(1)
    end
    # dust animation upon entry of heavy pokemon
    for j in 0..24
      next if !heavy
      for m in 0...max
        m = @firstsendout ? m : 0
        i = @firstsendout ? [0,2][m] : battlerindex
        dust["#{i}"].update if @battle.battlers[i].weight*0.1 >= 291 && alt[m] < 1
        dust["#{i}"].dispose if j == 24
      end
      wait(1,true) if j < 24
    end
    dust = nil
    # shiny animation upon entry
    for m in 0...max
      m = @firstsendout ? m : 0
      i = @firstsendout ? [0,2][m] : battlerindex
      pbCommonAnimation("Shiny",@battle.battlers[i],nil) if shinyBattler?(@battle.battlers[i])
    end
    @vector.set(defaultvector)
    wait(20,true)
    if USELOWHPBGM && !@battle.doublebattle
      pkmn = @battle.battlers[@firstsendout ? 0 : battlerindex]
      if pkmn.hp <= pkmn.totalhp*0.25 && pkmn.hp > 0
        $game_system.bgm_memorize
        pbBGMPlay("lowhpbattle")
        @lowHPBGM = true
      end
    end
    @sendingOut = false
    @firstsendout = false
    return true
  end
  #=============================================================================
  #  All the various types of displaying messages in battle
  #=============================================================================
  def clearMessageWindow(force=false)
    unless force
      return if @sendingOut
    end
    @sprites["messagewindow"].text=""
    @sprites["messagewindow"].refresh
    @sprites["messagebox"].visible=false
  end  
  
  def windowVisible?
    return @sprites["messagebox"].visible
  end
  
  def changeMessageViewport(viewport=nil)
    @sprites["messagebox"].viewport=(@sprites["messagebox"].viewport==@msgview) ? viewport : @msgview
    @sprites["messagewindow"].viewport=(@sprites["messagewindow"].viewport==@msgview) ? viewport : @msgview
  end
  
  alias pbFrameUpdate_ebs pbFrameUpdate unless self.method_defined?(:pbFrameUpdate_ebs)
  def pbFrameUpdate(cw=nil)
    cw.update if cw
    animateBattleSprites(true)
  end
  
  alias pbShowWindow_ebs pbShowWindow unless self.method_defined?(:pbShowWindow_ebs)
  def pbShowWindow(windowtype)
    if EBUISTYLE==0
      return pbShowWindow_ebs(windowtype)
    end
    @sprites["messagebox"].visible = (windowtype==MESSAGEBOX ||
                                      windowtype==COMMANDBOX ||
                                      windowtype==FIGHTBOX)# ||
                                      #windowtype==BLANK )
    @sprites["messagewindow"].visible = (windowtype==MESSAGEBOX)
  end
  
  alias pbWaitMessage_ebs pbWaitMessage unless self.method_defined?(:pbWaitMessage_ebs)
  def pbWaitMessage; end
  
  def databoxVisible(val=true,omit=false)
    if !omit
      @sprites["messagebox"].visible = false if val && @messagemode
    end
    return if EBUISTYLE < 2
    for i in 0...4
      next if i%2==1
      @sprites["battlebox#{i}"].visible = val if @sprites["battlebox#{i}"]
    end
  end
  
  alias pbDisplay_ebs pbDisplay unless self.method_defined?(:pbDisplay_ebs)
  def pbDisplay(msg,brief=false)
    databoxVisible(false)
    pbDisplayMessage(msg,brief)
    clearMessageWindow
    databoxVisible(!windowVisible?)
  end

  alias pbDisplayMessage_ebs pbDisplayMessage unless self.method_defined?(:pbDisplayMessage_ebs)
  def pbDisplayMessage(msg,brief=false)
    return clearMessageWindow if msg==""
    pbWaitMessage
    pbRefresh
    pbShowWindow(MESSAGEBOX)
    cw=@sprites["messagewindow"]
    cw.text=msg
    i=0
    loop do
      animateBattleSprites(true)
      pbGraphicsUpdate
      pbInputUpdate
      cw.update
      if i==40
        cw.text=""
        cw.visible=false
        return
      end
      if Input.trigger?(Input::C) || (defined?($mouse) && $mouse.leftClick?) || @abortable
        if cw.pausing?
          pbPlayDecisionSE() if !@abortable
          cw.resume
        end
      end
      if !cw.busy?
        if brief
          10.times do
            pbGraphicsUpdate
            pbFrameUpdate(cw)
          end
          #@briefmessage=true
          return
        end
        i+=1
      end
    end
  end

  alias pbDisplayPausedMessage_ebs pbDisplayPausedMessage unless self.method_defined?(:pbDisplayPausedMessage_ebs)
  def pbDisplayPausedMessage(msg)
    return clearMessageWindow if msg==""
    pbWaitMessage
    pbRefresh
    pbShowWindow(MESSAGEBOX)
    if @messagemode
      @switchscreen.pbDisplay(msg)
      return
    end
    cw=@sprites["messagewindow"]
    cw.text=_ISPRINTF("{1:s}\1",msg)
    loop do
      animateBattleSprites(true)
      pbGraphicsUpdate
      pbInputUpdate
      if Input.trigger?(Input::C) || (defined?($mouse) && $mouse.leftClick?) || @abortable
        if cw.busy?
          pbPlayDecisionSE() if cw.pausing? && !@abortable
          cw.resume
        elsif !inPartyAnimation?
          cw.text=""
          pbPlayDecisionSE()
          cw.visible=false if @messagemode
          return
        end
      end
      cw.update
    end
  end

  alias pbShowCommands_ebs pbShowCommands unless self.method_defined?(:pbShowCommands_ebs)
  def pbShowCommands(msg,commands,defaultValue)
    return pbShowCommands_ebs(msg,commands,defaultValue) if EBUISTYLE==0
    pbWaitMessage
    pbRefresh
    self.databoxVisible(false)
    pbShowWindow(MESSAGEBOX)
    dw=@sprites["messagewindow"]
    dw.text=msg
    cw = NewChoiceSel.new(@viewport,commands)
    pbRefresh
    loop do
      animateBattleSprites(true)
      pbGraphicsUpdate
      pbInputUpdate
      cw.update
      dw.update
      if Input.trigger?(Input::B) && defaultValue >=0
        if dw.busy?
          pbPlayDecisionSE() if dw.pausing?
          dw.resume
        else
          pbSEPlay("SE_Select2")
          cw.dispose(self)
          dw.text=""
          self.databoxVisible(!self.windowVisible?)
          return defaultValue
        end
      end
      if Input.trigger?(Input::C) || (defined?($mouse) && cw.over && $mouse.leftClick?)
        if dw.busy?
          pbPlayDecisionSE() if dw.pausing?
          dw.resume
        else
          pbSEPlay("SE_Select2")
          cw.dispose(self)
          dw.text=""
          self.databoxVisible(!self.windowVisible?)
          return cw.index
        end
      end
    end
  end
  
  alias pbForgetMove_ebs pbForgetMove unless self.method_defined?(:pbForgetMove_ebs)
  def pbForgetMove(pokemon,moveToLearn)
    for i in 0...4
      @sprites["battlebox#{i}"].visible=false if @sprites["battlebox#{i}"]
    end
    ret = pbForgetMove_ebs(pokemon,moveToLearn)
    for i in 0...4
      @sprites["battlebox#{i}"].visible=true if @sprites["battlebox#{i}"]
    end
    return ret
  end
  
  alias pbNameEntry_ebs pbNameEntry unless self.method_defined?(:pbNameEntry_ebs)
  def pbNameEntry(*args)
    vis = [false,false,false,false]
    for i in 0...4
      if @sprites["battlebox#{i}"]
        vis[i] = @sprites["battlebox#{i}"].visible
        @sprites["battlebox#{i}"].visible=false
      end
    end
    ret = pbNameEntry_ebs(*args)
    for i in 0...4
      @sprites["battlebox#{i}"].visible=vis[i] if @sprites["battlebox#{i}"]
    end
    return ret
  end
  
  alias pbShowPokedex_ebs pbShowPokedex unless self.method_defined?(:pbShowPokedex_ebs)
  def pbShowPokedex(*args)
    vis = [false,false,false,false]
    for i in 0...4
      if @sprites["battlebox#{i}"]
        vis[i] = @sprites["battlebox#{i}"].visible
        @sprites["battlebox#{i}"].visible=false
      end
    end
    ret = pbShowPokedex_ebs(*args)
    for i in 0...4
      @sprites["battlebox#{i}"].visible=vis[i] if @sprites["battlebox#{i}"]
    end
    return ret
  end
  #=============================================================================
  #  Ability messages
  #=============================================================================
  def showAbilityMessage(battler,hide=true)
    return if battler.pokemon.nil? || (!EFFECTMESSAGES && !INCLUDEGEN6)
    effect=PBAbilities.getName(battler.ability)
    bitmap=pbBitmap("#{checkEBFolderPath}/abilityMessage")
      rect=(battler.index%2==0) ? Rect.new(0,56,280,56) : Rect.new(0,0,280,56)
      baseColor=PokeBattle_SceneConstants::MESSAGEBASECOLOR
      shadowColor=PokeBattle_SceneConstants::MESSAGESHADOWCOLOR
    @sprites["abilityMessage"].bitmap.clear
    @sprites["abilityMessage"].bitmap.blt(0,0,bitmap,rect)
      bitmap=@sprites["abilityMessage"].bitmap
      pbDrawOutlineText(bitmap,38,-3,280-38,bitmap.font.size,_INTL("{1}'s",battler.pokemon.name),baseColor,shadowColor,0)
      pbDrawOutlineText(bitmap,0,27,280-28,bitmap.font.size,"#{effect}",baseColor,shadowColor,2)
    @sprites["abilityMessage"].x=(battler.index%2==0) ? -280 : Graphics.width
    o = @battle.doublebattle ? 30 : 0
    @sprites["abilityMessage"].y=(battler.index%2==0) ? @vector.y - 128 - o : @vector.y2 - 64 + o
    pbSEPlay("BW_ability")
    10.times do
      @sprites["abilityMessage"].x+=(battler.index%2==0) ? 28 : -28
      @sprites["abilityMessage"].zoom_y+=0.1
      animateBattleSprites
      pbGraphicsUpdate
    end
    t=255
    @sprites["abilityMessage"].tone=Tone.new(t,t,t)
    50.times do
      t-=25.5 if t > 0
      @sprites["abilityMessage"].tone=Tone.new(t,t,t)
      animateBattleSprites
      pbGraphicsUpdate
    end
    pbHideEffect(battler) if hide
  end
  
  def hideAbilityMessage(battler)
    return if !EFFECTMESSAGES && !INCLUDEGEN6
    10.times do
      @sprites["abilityMessage"].x+=(battler.index%2==0) ? -28 : 28
      @sprites["abilityMessage"].zoom_y-=0.1
      animateBattleSprites
      pbGraphicsUpdate
    end
  end
  
  if INCLUDEGEN6 || EFFECTMESSAGES
    alias displayEffMsg pbDisplayEffect unless !self.method_defined?(:displayEffMsg)
    def pbDisplayEffect(battler,hide=true)
      return displayEffMsg(battler,hide) if INCLUDEGEN6 && EBUISTYLE==0
      return showAbilityMessage(battler,hide)
    end
    alias hideEffMsg pbHideEffect  unless !self.method_defined?(:hideEffMsg)
    def pbHideEffect(battler)
      return hideEffMsg(battler) if INCLUDEGEN6 && EBUISTYLE==0
      return hideAbilityMessage(battler)
    end
  end
  #=============================================================================
  #  Safari Zone visuals
  #=============================================================================
  alias pbSafariStart_ebs pbSafariStart unless self.method_defined?(:pbSafariStart_ebs)
  def pbSafariStart
    return pbSafariStart_ebs if EBUISTYLE==0
    @briefmessage=false
    @sprites["battlebox0"]=NewSafariDataBox.new(@battle,@viewport)
    @sprites["battlebox0"].x=Graphics.width+10
    @sprites["battlebox0"].y=204
    @sprites["battlebox0"].appear
    12.times do
      @sprites["battlebox0"].x-=22
      animateBattleSprites
      Graphics.update
    end
    2.times do
      @sprites["battlebox0"].x+=2
      animateBattleSprites
      Graphics.update
    end
    pbRefresh
  end
  
  alias pbSafariCommandMenu_ebs pbSafariCommandMenu unless self.method_defined?(:pbSafariCommandMenu_ebs)
  def pbSafariCommandMenu(index)
    @orgPos=[@vector.x,@vector.y,@vector.angle,@vector.scale,@vector.zoom1] if @orgPos.nil?
    cmd=pbSafariCommandMenu_ebs(index)
    @idleTimer=-1
    vector = @battle.doublebattle ? VECTOR2 : VECTOR1
    @vector.set(vector)
    @vector.inc=0.2
    return cmd
  end
    
  def pbThrowBait
    @briefmessage=false
    frame=0
    ball=sprintf("Graphics/Pictures/battleBait")
    # sprites
    coords=[@sprites["pokemon1"].x,@sprites["pokemon1"].y]
    spritePoke=@sprites["pokemon1"]
    spriteBall=IconSprite.new(0,0,@viewport)
    spriteBall.visible=false
    # pictures
    pictureBall=PictureEx.new(spritePoke.z+1)
    picturePoke=PictureEx.new(spritePoke.z)
    dims=[spritePoke.x,spritePoke.y]
    pokecenter=getSpriteCenter(@sprites["pokemon1"])
    ballendy=PokeBattle_SceneConstants::FOEBATTLER_Y-4
    # starting positions
    pictureBall.moveVisible(1,true)
    pictureBall.moveName(1,ball)
    pictureBall.moveOrigin(1,PictureOrigin::Center)
    pictureBall.moveXY(0,1,64,256)
    picturePoke.moveVisible(1,true)
    picturePoke.moveXY(0,1,coords[0],coords[1])
    # directives
    picturePoke.moveSE(1,"Audio/SE/throw")
    pictureBall.moveCurve(30,1,64,256,Graphics.width/2,48,pokecenter[0]-(14*6),pokecenter[1])
    pictureBall.moveAngle(30,1,-720)
    pictureBall.moveAngle(0,pictureBall.totalDuration,0)
    # Show Pokémon jumping before eating the bait
    picturePoke.moveSE(50,"Audio/SE/jump")
    picturePoke.moveXY(8,50,coords[0],coords[1]-8)
    picturePoke.moveXY(8,58,coords[0],coords[1])
    pictureBall.moveVisible(66,false)
    picturePoke.moveSE(66,"Audio/SE/jump")
    picturePoke.moveXY(8,66,coords[0],coords[1]-8)
    picturePoke.moveXY(8,74,coords[0],coords[1])
    # TODO: Show Pokémon eating the bait (pivots at the bottom right corner)
    @playerfix=false
    loop do
      frame+=1
      @sprites["player"].x-=8 if frame < 31
      if frame%2==0 && frame >= (2*1) && frame <= (2*3)
        @sprites["player"].src_rect.x+=(@sprites["player"].bitmap.width/4)
      end
      pictureBall.update
      picturePoke.update
      setPictureIconSprite(spriteBall,pictureBall)
      setPictureSpriteEB(spritePoke,picturePoke)
      moveEntireScene(-6,0,false) if frame<15
      animateBattleSprites
      pbGraphicsUpdate
      pbInputUpdate
      break if !pictureBall.running? && !picturePoke.running?
    end
    @vector.setXY(@orgPos[0],@orgPos[1])
    @sprites["player"].src_rect.x=0
    @playerfix=true
    spriteBall.dispose
  end
  
  def pbThrowRock
    @briefmessage=false
    frame=0
    ball=sprintf("Graphics/Pictures/battleRock")
    anger=sprintf("Graphics/Pictures/battleAnger")
    coords=[@sprites["pokemon1"].x,@sprites["pokemon1"].y]
    # sprites
    spritePoke=@sprites["pokemon1"]
    spriteBall=IconSprite.new(0,0,@viewport)
    spriteBall.visible=false
    spriteAnger=IconSprite.new(0,0,@viewport)
    spriteAnger.visible=false
    # pictures
    pictureBall=PictureEx.new(spritePoke.z+1)
    picturePoke=PictureEx.new(spritePoke.z)
    pictureAnger=PictureEx.new(spritePoke.z+1)
    dims=[spritePoke.x,spritePoke.y]
    pokecenter=getSpriteCenter(@sprites["pokemon1"])
    ballendy=PokeBattle_SceneConstants::FOEBATTLER_Y-4
    # starting positions
    pictureBall.moveVisible(1,true)
    pictureBall.moveName(1,ball)
    pictureBall.moveOrigin(1,PictureOrigin::Center)
    pictureBall.moveXY(0,1,64,256)
    picturePoke.moveVisible(1,true)
    picturePoke.moveXY(0,1,coords[0],coords[1])
    pictureAnger.moveVisible(1,false)
    pictureAnger.moveName(1,anger)
    pictureAnger.moveXY(0,1,pokecenter[0]-56-(14*6),pokecenter[1]-48)
    pictureAnger.moveOrigin(1,PictureOrigin::Center)
    pictureAnger.moveZoom(0,1,100)
    # directives
    picturePoke.moveSE(1,"Audio/SE/throw")
    pictureBall.moveCurve(30,1,64,256,Graphics.width/2,48,pokecenter[0]-(14*6),pokecenter[1])
    pictureBall.moveAngle(30,1,-720)
    pictureBall.moveAngle(0,pictureBall.totalDuration,0)
    pictureBall.moveSE(30,"Audio/SE/notverydamage")
    pictureBall.moveVisible(40,false)
    # Show Pokémon being angry
    pictureAnger.moveSE(48,"Audio/SE/jump")
    pictureAnger.moveVisible(48,true)
    pictureAnger.moveZoom(8,48,130)
    pictureAnger.moveZoom(8,56,100)
    pictureAnger.moveXY(0,64,pokecenter[0]+56-(14*6),pokecenter[1]-64)
    pictureAnger.moveSE(64,"Audio/SE/jump")
    pictureAnger.moveZoom(8,64,130)
    pictureAnger.moveZoom(8,72,100)
    pictureAnger.moveVisible(80,false)
    @playerfix=false
    loop do
      frame+=1
      @sprites["player"].x-=8 if frame < 31
      if frame%2==0 && frame >= (2*1) && frame <= (2*3)
        @sprites["player"].src_rect.x+=(@sprites["player"].bitmap.width/4)
      end
      pictureBall.update
      picturePoke.update
      pictureAnger.update
      setPictureIconSprite(spriteBall,pictureBall)
      setPictureIconSprite(spriteAnger,pictureAnger)
      setPictureSpriteEB(spritePoke,picturePoke)
      moveEntireScene(-6,0,false) if frame<15
      animateBattleSprites
      pbGraphicsUpdate
      pbInputUpdate
      break if !pictureBall.running? && !picturePoke.running? && !pictureAnger.running?
    end
    @vector.setXY(@orgPos[0],@orgPos[1])
    @sprites["player"].src_rect.x=0
    @playerfix=true
    spriteBall.dispose
  end
end
#===============================================================================  
#  Safari Zone compatibility
#===============================================================================
class PokeBattle_SafariZone
  alias initialize_ebs initialize unless self.method_defined?(:initialize_ebs)
  
  def initialize(scene,player,party2)
    scene.safaribattle=true
    initialize_ebs(scene,player,party2)
  end
end
#===============================================================================  
#  Evolution scene
#===============================================================================
class PokemonEvolutionScene
  # main update function
  def update(poke=true,bar=false)
    self.updateBackground
    @sprites["poke"].update if poke
    @sprites["poke2"].update if poke
    if bar
      @sprites["bar1"].y -= 8 if @sprites["bar1"].y > -@viewport.rect.height*0.5
      @sprites["bar2"].y += 8 if @sprites["bar2"].y < @viewport.rect.height*1.5
    end
  end
  # background update function
  def updateBackground
    for j in 0...6
      @sprites["l#{j}"].y = @viewport.rect.height if @sprites["l#{j}"].y <= 0
      t = (@sprites["l#{j}"].y.to_f/@viewport.rect.height)*255
      @sprites["l#{j}"].tone = Tone.new(t,t,t)
      z = ((@sprites["l#{j}"].y.to_f - @viewport.rect.height/2)/(@viewport.rect.height/2))*1.0
      @sprites["l#{j}"].angle = (z < 0) ? 180 : 0
      @sprites["l#{j}"].zoom_y = z.abs
      @sprites["l#{j}"].y -= 2
    end
  end
  # update for the particle effects
  def updateParticles
    for j in 0...16
      @sprites["s#{j}"].visible = true
      if @sprites["s#{j}"].opacity == 0
        @sprites["s#{j}"].opacity = 255
        @sprites["s#{j}"].speed = 1
        @sprites["s#{j}"].x = @sprites["poke"].x
        @sprites["s#{j}"].y = @sprites["poke"].y
        x, y = randCircleCord(256)
        @sprites["s#{j}"].end_x = @sprites["poke"].x - 256 + x
        @sprites["s#{j}"].end_y = @sprites["poke"].y - 256 + y
      end
      @sprites["s#{j}"].x -= (@sprites["s#{j}"].x - @sprites["s#{j}"].end_x)*0.01*@sprites["s#{j}"].speed
      @sprites["s#{j}"].y -= (@sprites["s#{j}"].y - @sprites["s#{j}"].end_y)*0.01*@sprites["s#{j}"].speed
      @sprites["s#{j}"].opacity -= 4*@sprites["s#{j}"].speed
    end
  end
  # update for the rays going out of the Pokemon
  def updateRays(i)
    for j in 0...8
      next if j > i/8
      if @sprites["r#{j}"].opacity == 0
        @sprites["r#{j}"].opacity = 255
        @sprites["r#{j}"].zoom_x = 0
        @sprites["r#{j}"].zoom_y = 0
      end
      @sprites["r#{j}"].opacity -= 4
      @sprites["r#{j}"].zoom_x += 0.04
      @sprites["r#{j}"].zoom_y += 0.04
    end
  end
  # initializes the evolution sequence
  def pbStartScreen(pokemon,newspecies)
    @pokemon = pokemon
    @newspecies = newspecies
    @sprites = {}
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @viewport.color = Color.new(0,0,0,0)
    # initial fading transition
    16.times do
      @viewport.color.alpha += 16
      pbWait(1)
    end
    # initializes bars for cutting the screen off
    @sprites["bar1"] = Sprite.new(@viewport)
    @sprites["bar1"].drawRect(@viewport.rect.width,@viewport.rect.height/2,Color.new(0,0,0))
    @sprites["bar1"].z = 99999
    @sprites["bar2"] = Sprite.new(@viewport)
    @sprites["bar2"].drawRect(@viewport.rect.width,@viewport.rect.height/2,Color.new(0,0,0))
    @sprites["bar2"].y = @viewport.rect.height/2
    @sprites["bar2"].z = 99999
    # initializes messages window
    @sprites["msgwindow"] = Kernel.pbCreateMessageWindow(@viewport)
    @sprites["msgwindow"].visible = false
    @sprites["msgwindow"].z = 9999
    # background graphics
    @sprites["bg1"] = Sprite.new(@viewport)
    @sprites["bg1"].bitmap = pbBitmap("Graphics/Pictures/EBS/evobg")
    @sprites["bg2"] = Sprite.new(@viewport)
    @sprites["bg2"].bitmap = pbBitmap("Graphics/Pictures/EBS/overlay")
    @sprites["bg2"].z = 5
    # particles for the background
    for j in 0...6
      @sprites["l#{j}"] = Sprite.new(@viewport)
      @sprites["l#{j}"].bitmap = pbBitmap("Graphics/Pictures/EBS/line1")
      @sprites["l#{j}"].y = (@viewport.rect.height/6)*j
      @sprites["l#{j}"].ox = @sprites["l#{j}"].bitmap.width/2
      @sprites["l#{j}"].x = @viewport.rect.width/2
    end
    # original Pokemon sprite
    @sprites["poke"] = defined?(DynamicPokemonSprite) ? DynamicPokemonSprite.new(false,0,@viewport) : PokemonBattlerSprite.new(false,0,@viewport)
    @sprites["poke"].setPokemonBitmap(@pokemon)
    @sprites["poke"].showshadow = false if defined?(DynamicPokemonSprite)
    @sprites["poke"].ox = @sprites["poke"].bitmap.width/2
    @sprites["poke"].oy = @sprites["poke"].bitmap.height/2
    @sprites["poke"].x = @viewport.rect.width/2
    @sprites["poke"].y = @viewport.rect.height/2
    @sprites["poke"].z = 50
    # evolved Pokemon sprite
    @sprites["poke2"] = defined?(DynamicPokemonSprite) ? DynamicPokemonSprite.new(false,0,@viewport) : PokemonBattlerSprite.new(false,0,@viewport)
    @sprites["poke2"].setPokemonBitmap(@pokemon,false,@newspecies)
    @sprites["poke2"].showshadow = false if defined?(DynamicPokemonSprite)
    @sprites["poke2"].ox = @sprites["poke2"].bitmap.width/2
    @sprites["poke2"].oy = @sprites["poke2"].bitmap.height/2
    @sprites["poke2"].x = @viewport.rect.width/2
    @sprites["poke2"].y = @viewport.rect.height/2
    @sprites["poke2"].z = 50
    @sprites["poke2"].zoom_x = 0
    @sprites["poke2"].zoom_y = 0
    @sprites["poke2"].tone = Tone.new(255,255,255)
    # initializes the shine at the beginning animation
    @sprites["shine"] = Sprite.new(@viewport)
    @sprites["shine"].bitmap = pbBitmap("Graphics/Pictures/EBS/shine1")
    @sprites["shine"].ox = @sprites["shine"].bitmap.width/2
    @sprites["shine"].oy = @sprites["shine"].bitmap.height/2
    @sprites["shine"].x = @sprites["poke"].x
    @sprites["shine"].y = @sprites["poke"].y
    @sprites["shine"].zoom_x = 0
    @sprites["shine"].zoom_y = 0
    @sprites["shine"].opacity = 0
    @sprites["shine"].z = 60
    # initializes the shine during animation
    @sprites["shine2"] = Sprite.new(@viewport)
    @sprites["shine2"].bitmap = pbBitmap("Graphics/Pictures/EBS/shine3")
    @sprites["shine2"].ox = @sprites["shine2"].bitmap.width/2
    @sprites["shine2"].oy = @sprites["shine2"].bitmap.height/2
    @sprites["shine2"].x = @sprites["poke"].x
    @sprites["shine2"].y = @sprites["poke"].y
    @sprites["shine2"].zoom_x = 0
    @sprites["shine2"].zoom_y = 0
    @sprites["shine2"].opacity = 0
    @sprites["shine2"].z = 40
    # initializes the shine at the end
    @sprites["shine3"] = Sprite.new(@viewport)
    @sprites["shine3"].bitmap = pbBitmap("Graphics/Pictures/EBS/shine4")
    @sprites["shine3"].ox = @sprites["shine3"].bitmap.width/2
    @sprites["shine3"].oy = @sprites["shine3"].bitmap.height/2
    @sprites["shine3"].x = @sprites["poke"].x
    @sprites["shine3"].y = @sprites["poke"].y
    @sprites["shine3"].zoom_x = 0.5
    @sprites["shine3"].zoom_y = 0.5
    @sprites["shine3"].opacity = 0
    @sprites["shine3"].z = 60
    # initializes particles
    for j in 0...16
      @sprites["s#{j}"] = Sprite.new(@viewport)
      @sprites["s#{j}"].bitmap = pbBitmap("Graphics/Pictures/EBS/shine2")
      @sprites["s#{j}"].ox = @sprites["s#{j}"].bitmap.width/2
      @sprites["s#{j}"].oy = @sprites["s#{j}"].bitmap.height/2
      @sprites["s#{j}"].x = @sprites["poke"].x
      @sprites["s#{j}"].y = @sprites["poke"].y
      @sprites["s#{j}"].z = 60
      s = rand(4) + 1
      x, y = randCircleCord(192)
      @sprites["s#{j}"].end_x = @sprites["s#{j}"].x - 192 + x
      @sprites["s#{j}"].end_y = @sprites["s#{j}"].y - 192 + y
      @sprites["s#{j}"].speed = s
      @sprites["s#{j}"].visible = false
    end
    # initializes light rays
    rangle = []
    for i in 0...8; rangle.push((360/8)*i +  15); end
    for j in 0...8
      @sprites["r#{j}"] = Sprite.new(@viewport)
      @sprites["r#{j}"].bitmap = BitmapCache.load_bitmap("Graphics/Pictures/EBS/ray")
      @sprites["r#{j}"].ox = 0
      @sprites["r#{j}"].oy = @sprites["r#{j}"].bitmap.height/2
      @sprites["r#{j}"].opacity = 0
      @sprites["r#{j}"].zoom_x = 0
      @sprites["r#{j}"].zoom_y = 0
      @sprites["r#{j}"].x = @viewport.rect.width/2
      @sprites["r#{j}"].y = @viewport.rect.height/2
      a = rand(rangle.length)
      @sprites["r#{j}"].angle = rangle[a]
      @sprites["r#{j}"].z = 60
      rangle.delete_at(a)
    end
    @viewport.color.alpha = 0
  end

  # closes the evolution screen.
  def pbEndScreen
    $game_temp.message_window_showing = false if $game_temp
    @viewport.color = Color.new(0,0,0,0)
    16.times do
      Graphics.update
      self.update
      @viewport.color.alpha += 16
    end
    pbDisposeSpriteHash(@sprites)
    16.times do
      Graphics.update
      @viewport.color.alpha -= 16
    end
    @viewport.dispose
  end
  # initial animation when starting evolution
  def glow
    t = 0
    pbSEPlay("#{SE_EXTRA_PATH}Flash")
    16.times do
      Graphics.update
      self.update(false)
      @sprites["shine"].zoom_x += 0.08
      @sprites["shine"].zoom_y += 0.08
      @sprites["shine"].opacity += 16
      t += 16
      @sprites["poke"].tone = Tone.new(t,t,t)
      @sprites["bar1"].y += 3
      @sprites["bar2"].y -= 3
    end
    16.times do
      Graphics.update
      self.update(false)
      @sprites["shine"].zoom_x -= 0.02
      @sprites["shine"].zoom_y -= 0.02
      @sprites["shine"].opacity -= 16
      t -= 16
      @sprites["poke"].tone = Tone.new(t,t,t)
      @sprites["bar1"].y += 3
      @sprites["bar2"].y -= 3
      self.updateParticles
    end
  end
  # aniamtion to flash the screen after evolution is completed
  def flash(cancel)
    srt = cancel ? "poke" : "poke2"
    pbSEPlay("#{SE_EXTRA_PATH}Flash3") if !cancel
    for key in @sprites.keys
      next if ["bar1","bar2","bg1","bg2","l0","l1","l2","l3","l4","l5"].include?(key)
      @sprites[key].visible = false
    end
    @sprites[srt].visible = true
    @sprites[srt].zoom_x = 1
    @sprites[srt].zoom_y = 1
    @sprites[srt].tone = Tone.new(0,0,0)
    for i in 0...(cancel ? 32 : 64)
      Graphics.update
      @viewport.color.alpha -= cancel ? 8 : 4
      self.update(true,true)
    end
    return if cancel
    pbSEPlay("#{SE_EXTRA_PATH}Saint6")
    for j in 0...64
      @sprites["p#{j}"] = Sprite.new(@viewport)
      n = [5,2][rand(2)]
      @sprites["p#{j}"].bitmap = pbBitmap("Graphics/Pictures/EBS/shine#{n}")
      @sprites["p#{j}"].z = 10
      @sprites["p#{j}"].ox = @sprites["p#{j}"].bitmap.width/2
      @sprites["p#{j}"].oy = @sprites["p#{j}"].bitmap.height/2
      @sprites["p#{j}"].x = rand(@viewport.rect.width + 1)
      @sprites["p#{j}"].y = @viewport.rect.height/2 + rand(@viewport.rect.height/2 - 64)
      z = [0.2,0.4,0.5,0.6,0.8,1.0][rand(6)]
      @sprites["p#{j}"].zoom_x = z
      @sprites["p#{j}"].zoom_y = z
      @sprites["p#{j}"].opacity = 0
      @sprites["p#{j}"].speed = 2 + rand(5)
    end
    for i in 0...64
      Graphics.update
      self.update
      for j in 0...64
        @sprites["p#{j}"].opacity += (i < 32 ? 2 : -2)*@sprites["p#{j}"].speed
        @sprites["p#{j}"].y -= 1 if i%@sprites["p#{j}"].speed == 0
        if @sprites["p#{j}"].opacity > 128
          @sprites["p#{j}"].zoom_x /= 1.5
          @sprites["p#{j}"].zoom_y /= 1.5
        end
      end
    end
  end
  # starts the evolution screen
  def pbEvolution(cancancel=true)
    # stops BGM and displays message
    pbBGMStop()
    16.times do
      Graphics.update
      self.update
      @sprites["bar1"].y -= @sprites["bar1"].bitmap.height/16
      @sprites["bar2"].y += @sprites["bar2"].bitmap.height/16
    end
    @sprites["msgwindow"].visible = true
    Kernel.pbMessageDisplay(@sprites["msgwindow"],_INTL("\\se[]What?\r\n{1} is evolving!\\^",@pokemon.name)) { self.update }
    Kernel.pbMessageWaitForInput(@sprites["msgwindow"],100,true) { self.update }
    @sprites["msgwindow"].visible = false
    # plays Pokemon's cry
    pbPlayCry(@pokemon)
    pbCryFrameLength(@pokemon.species).times do
      Graphics.update
      self.update
    end
    pbBGMPlay("evolv")
    canceled = false
    # beginning glow effect
    self.glow
    k1 = 1 # zoom factor for the Pokemon
    k2 = 1 # zoom factor for the shine
    s = 1 # speed of the animation
    @viewport.color = Color.new(255,255,255,0)
    pbSEPlay("#{SE_EXTRA_PATH}Heal4")
    # main animation loop
    for i in 0...256
      k1 *= -1 if i%(32/s) == 0
      k2 *= -1 if i%(16) == 0
      s *= 2 if i%64 == 0 && i > 0 && s < 8
      Graphics.update
      Input.update
      self.update(false)
      self.updateParticles
      self.updateRays(i)
      @sprites["poke"].zoom_x += 0.03125*k1*s
      @sprites["poke"].zoom_y += 0.03125*k1*s
      @sprites["poke"].tone.red += 16
      @sprites["poke"].tone.green += 16
      @sprites["poke"].tone.blue += 16
      @sprites["poke2"].zoom_x -= 0.03125*k1*s
      @sprites["poke2"].zoom_y -= 0.03125*k1*s
      if @sprites["shine2"].opacity < 255
        @sprites["shine2"].opacity += 16
        @sprites["shine2"].zoom_x += 0.08
        @sprites["shine2"].zoom_y += 0.08
      else
        @sprites["shine2"].zoom_x += 0.01*k2
        @sprites["shine2"].zoom_y += 0.01*k2
        @sprites["shine2"].tone.red += 0.5
        @sprites["shine2"].tone.green += 0.5
        @sprites["shine2"].tone.blue += 0.5
      end
      if i >= 240
        @sprites["shine3"].opacity += 16
        @sprites["shine3"].zoom_x += 0.1
        @sprites["shine3"].zoom_y += 0.1
      end
      @viewport.color.alpha += 32 if i >= 248
      if Input.trigger?(Input::B) && cancancel
        pbBGMStop()
        canceled = true
        break
      end
    end
    @viewport.color = Color.new(255,255,255)
    self.flash(canceled)
    if canceled
      # prints message when evolution is cancelled
      @sprites["msgwindow"].visible = true
      Kernel.pbMessageDisplay(@sprites["msgwindow"],_INTL("Huh?\r\n{1} stopped evolving!",@pokemon.name)) { self.update }
    else
      # creates the actual evolved Pokemon
      self.createEvolved
    end
  end
  # function used to create the newly evolved Pokemon
  def createEvolved
    frames = pbCryFrameLength(@newspecies)
    # plays Pokemon's cry
    pbBGMStop()
    pbPlayCry(@newspecies)
    frames.times do
      Graphics.update
      self.update
    end
    pbMEPlay("EvolutionSuccess")
    # gets info of the new species
    newspeciesname = PBSpecies.getName(@newspecies)
    oldspeciesname = PBSpecies.getName(@pokemon.species)
    @sprites["msgwindow"].visible = true
    Kernel.pbMessageDisplay(@sprites["msgwindow"],_INTL("\\se[]Congratulations! Your {1} evolved into {2}!\\wt[80]",@pokemon.name,newspeciesname)) { self.update }
    @sprites["msgwindow"].text = ""
    removeItem = false
    createSpecies = pbCheckEvolutionEx(@pokemon){|pokemon,evonib,level,poke|
      if evonib == PBEvolution::Shedinja
        # checks if a Pokeball is available for Shedinja
        next poke if $PokemonBag.pbQuantity(getConst(PBItems,:POKEBALL))>0
      elsif evonib == PBEvolution::TradeItem || evonib == PBEvolution::DayHoldItem || evonib == PBEvolution::NightHoldItem
        # consumes evolutionary item
        removeItem = true if poke == @newspecies
      end
      next -1
    }
    @pokemon.setItem(0) if removeItem
    @pokemon.species = @newspecies
    $Trainer.seen[@newspecies] = true
    $Trainer.owned[@newspecies] = true
    pbSeenForm(@pokemon)
    @pokemon.name = newspeciesname if @pokemon.name == oldspeciesname
    @pokemon.calcStats
    # checking moves for new species
    movelist = @pokemon.getMoveList
    for i in movelist
      if i[0] == @pokemon.level
        # learning new moves
        pbLearnMove(@pokemon,i[1],true) { self.update }
      end
    end
    # adding new species of Pokemon to the party
    if createSpecies>0 && $Trainer.party.length<6
      newpokemon = @pokemon.clone
      newpokemon.iv = @pokemon.iv.clone
      newpokemon.ev = @pokemon.ev.clone
      newpokemon.species = createSpecies
      newpokemon.name = PBSpecies.getName(createSpecies)
      newpokemon.setItem(0)
      newpokemon.clearAllRibbons
      newpokemon.markings = 0
      newpokemon.ballused = 0
      newpokemon.calcStats
      newpokemon.heal
      $Trainer.party.push(newpokemon)
      $Trainer.seen[createSpecies] = true
      $Trainer.owned[createSpecies] = true
      pbSeenForm(newpokemon)
      $PokemonBag.pbDeleteItem(getConst(PBItems,:POKEBALL))
    end
  end
end
#===============================================================================  
#  Hatching scene
#===============================================================================
module EBS_EggHatching
  def self.included base
    base.class_eval do
      # main update function
      def update
        self.updateBackground
        @sprites["poke"].update
        return if @frame >= 5
        if defined?(AnimatedBitmapWrapper)
          @sprites["poke"].sprite.bitmap.blt((@sprites["poke"].bitmap.width - @cracks.width)/2,(@sprites["poke"].bitmap.height - @cracks.height)/2,@cracks.bitmap,Rect.new(0,0,@cracks.width,@cracks.height))
        else
          @sprites["poke"].bitmap.blt((@sprites["poke"].bitmap.width - @cracks.height)/2,(@sprites["poke"].bitmap.height - @cracks.height)/2,@cracks.bitmap,Rect.new(@cracks.height*@frame,0,@cracks.height,@cracks.height))
        end
        #@sprites["poke"].update
      end
      # background update function
      def updateBackground
        for j in 0...6
          @sprites["l#{j}"].y = @viewport.rect.height if @sprites["l#{j}"].y <= 0
          t = (@sprites["l#{j}"].y.to_f/@viewport.rect.height)*255
          @sprites["l#{j}"].tone = Tone.new(t,t,t)
          z = ((@sprites["l#{j}"].y.to_f - @viewport.rect.height/2)/(@viewport.rect.height/2))*1.0
          @sprites["l#{j}"].angle = (z < 0) ? 180 : 0
          @sprites["l#{j}"].zoom_y = z.abs
          @sprites["l#{j}"].y -= 2
        end
      end
      # advancing the frames
      def advance
        @frame += 1
        2.times do
          @cracks.update
        end
      end
      # initializes sprites for animation
      def pbStartScene(pokemon)
        @frame = 0
        @sprites = {}
        @pokemon = pokemon
        @nicknamed = false
        @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
        @viewport.z = 99999
        @viewport.color = Color.new(0,0,0,0)
        # initial fading transition
        16.times do
          @viewport.color.alpha += 16
          pbWait(1)
        end
        # initializes bars for cutting the screen off
        @sprites["bar1"] = Sprite.new(@viewport)
        @sprites["bar1"].drawRect(@viewport.rect.width,@viewport.rect.height/2,Color.new(0,0,0))
        @sprites["bar1"].z = 99999
        @sprites["bar2"] = Sprite.new(@viewport)
        @sprites["bar2"].drawRect(@viewport.rect.width,@viewport.rect.height/2,Color.new(0,0,0))
        @sprites["bar2"].y = @viewport.rect.height/2
        @sprites["bar2"].z = 99999
        # background graphics
        @sprites["bg1"] = Sprite.new(@viewport)
        @sprites["bg1"].bitmap = pbBitmap("Graphics/Pictures/EBS/hatchbg")
        @sprites["bg2"] = Sprite.new(@viewport)
        @sprites["bg2"].bitmap = pbBitmap("Graphics/Pictures/EBS/overlay")
        @sprites["bg2"].z = 5
        # initializes messages window
        @sprites["msgwindow"] = Kernel.pbCreateMessageWindow(@viewport)
        @sprites["msgwindow"].visible = false
        @sprites["msgwindow"].z = 9999
        # particles for the background
        for j in 0...6
          @sprites["l#{j}"] = Sprite.new(@viewport)
          @sprites["l#{j}"].bitmap = pbBitmap("Graphics/Pictures/EBS/line2")
          @sprites["l#{j}"].y = (@viewport.rect.height/6)*j
          @sprites["l#{j}"].ox = @sprites["l#{j}"].bitmap.width/2
          @sprites["l#{j}"].x = @viewport.rect.width/2
        end
        eggs = @pokemon.eggsteps
        @pokemon.eggsteps = 1
        @sprites["poke"] = defined?(DynamicPokemonSprite) ? DynamicPokemonSprite.new(false,0,@viewport) : PokemonBattlerSprite.new(false,0,@viewport)
        @sprites["poke"].setPokemonBitmap(@pokemon) # Egg sprite
        @sprites["poke"].z = 50
        @sprites["poke"].ox = @sprites["poke"].bitmap.width/2
        @sprites["poke"].oy = @sprites["poke"].bitmap.height
        @sprites["poke"].x = @viewport.rect.width/2
        @sprites["poke"].y = @viewport.rect.height/2 + @sprites["poke"].bitmap.height*0.5
        @sprites["poke"].showshadow = false if defined?(DynamicPokemonSprite)
        crackfilename = sprintf("Graphics/Battlers/Eggs/%scracks",getConstantName(PBSpecies,@pokemon.species)) rescue nil
        if !pbResolveBitmap(crackfilename)
          crackfilename = sprintf("Graphics/Battlers/Eggs/%03dcracks",@pokemon.species)
          if !pbResolveBitmap(crackfilename)
            crackfilename = sprintf("Graphics/Battlers/Eggs/000cracks")
          end
        end
        @cracks = defined?(AnimatedBitmapWrapper) ? AnimatedBitmapWrapper.new(crackfilename) : pbBitmap(crackfilename)
        @pokemon.eggsteps = eggs
        @viewport.color.alpha = 0
        
        @sprites["rect"] = Sprite.new(@viewport)
        @sprites["rect"].drawRect(@viewport.rect.width,@viewport.rect.height,Color.new(255,255,255))
        @sprites["rect"].opacity = 0
        @sprites["rect"].z = 100
      end
    
      def pbMain
        # stops BGM and displays message
        pbBGMStop()
        16.times do
          Graphics.update
          self.update
          @sprites["bar1"].y -= @sprites["bar1"].bitmap.height/16
          @sprites["bar2"].y += @sprites["bar2"].bitmap.height/16
        end    
        pbBGMPlay("evolv")
        wait(32)
        # Egg bounce animation
        2.times do
          3.times do
            @sprites["poke"].zoom_y += 0.04
            wait
          end
          for i in 0...6
            @sprites["poke"].y -= 6 * (i < 3 ? 1 : -1)
            wait
          end
          for i in 0...6
            @sprites["poke"].zoom_y -= 0.04 * (i < 3 ? 2 : -1)
            @sprites["poke"].y -= 2 if i >= 3
            wait
          end
          3.times do
            @sprites["poke"].y += 2
            wait
          end
          self.advance
          pbSEPlay("eb_ice2",80)
          wait(24)
        end
        # Egg shake animation
        m = 16; n = 2; k = -1
        for j in 0...3
          self.advance if j < 2
          pbSEPlay("eb_ice2",80) if j < 2
          for i in 0...m
            k *= -1 if i%n == 0
            @sprites["poke"].x += k * 4
            @sprites["rect"].opacity += 64 if j == 2 && i >= (m - 5)
            wait
          end
          k = j < 1 ? 1.5 : 2
          n = 3
          m = 42
          wait(24) if j < 1
        end
        # Egg burst animation
        self.advance
        pbSEPlay(isVersion17? ? "Battle recall" : "recall")
        @sprites["poke"].setPokemonBitmap(@pokemon) # Egg sprite
        @sprites["poke"].ox = @sprites["poke"].bitmap.width/2
        @sprites["poke"].oy = @sprites["poke"].bitmap.height
        @sprites["poke"].x = @viewport.rect.width/2
        @sprites["poke"].y = @viewport.rect.height/2 + @sprites["poke"].bitmap.height*0.5
        @sprites["ring"] = Sprite.new(@viewport)
        @sprites["ring"].z = 200
        @sprites["ring"].bitmap = pbBitmap("Graphics/Pictures/EBS/shine7")
        @sprites["ring"].ox = @sprites["ring"].bitmap.width/2
        @sprites["ring"].oy = @sprites["ring"].bitmap.height/2
        @sprites["ring"].color = Color.new(232,92,42)
        @sprites["ring"].opacity = 0
        @sprites["ring"].x = @viewport.rect.width/2
        @sprites["ring"].y = @viewport.rect.height/2
        for j in 0...16
          @sprites["s#{j}"] = Sprite.new(@viewport)
          @sprites["s#{j}"].z = 200
          @sprites["s#{j}"].bitmap = pbBitmap("Graphics/Pictures/EBS/shine6")
          @sprites["s#{j}"].ox = @sprites["s#{j}"].bitmap.width/2
          @sprites["s#{j}"].oy = @sprites["s#{j}"].bitmap.height/2
          @sprites["s#{j}"].color = Color.new(232,92,42)
          @sprites["s#{j}"].x = @viewport.rect.width/2
          @sprites["s#{j}"].y = @viewport.rect.height/2
          @sprites["s#{j}"].opacity = 0
          r = 96 + rand(64)
          x, y = randCircleCord(r)
          @sprites["s#{j}"].end_x = @sprites["s#{j}"].x - r + x
          @sprites["s#{j}"].end_y = @sprites["s#{j}"].y - r + y - 32
          z = 1 - rand(20)*0.01
          @sprites["s#{j}"].zoom_x = z
          @sprites["s#{j}"].zoom_y = z
        end
        16.times do
          for j in 0...16
            @sprites["s#{j}"].x -= (@sprites["s#{j}"].x - @sprites["s#{j}"].end_x)*0.05
            @sprites["s#{j}"].y -= (@sprites["s#{j}"].y - @sprites["s#{j}"].end_y)*0.05
            @sprites["s#{j}"].color.alpha -= 16
            @sprites["s#{j}"].opacity += 32
          end
          @sprites["ring"].color.alpha -= 16
          @sprites["ring"].opacity += 32
          @sprites["ring"].zoom_x += 0.5
          @sprites["ring"].zoom_y += 0.5
          wait
        end
        for i in 0...48
          for j in 0...16
            @sprites["s#{j}"].x -= (@sprites["s#{j}"].x - @sprites["s#{j}"].end_x)*0.05
            @sprites["s#{j}"].y -= (@sprites["s#{j}"].y - @sprites["s#{j}"].end_y)*0.05
            @sprites["s#{j}"].end_y += 2
            @sprites["s#{j}"].zoom_x -= 0.01
            @sprites["s#{j}"].zoom_y -= 0.01
            @sprites["s#{j}"].opacity -= 16 if i >= 32
          end
          @sprites["ring"].zoom_x += 0.5
          @sprites["ring"].zoom_y += 0.5
          @sprites["ring"].opacity -= 32
          wait
        end
        16.times do
          @sprites["rect"].opacity -= 16
          wait
        end
        wait(32)
        # Finish scene
        frames = pbCryFrameLength(@pokemon.species)
        pbBGMStop()
        pbPlayCry(@pokemon)
        frames.times do
          Graphics.update
          self.update
        end
        pbMEPlay("EvolutionSuccess")
        @sprites["msgwindow"].visible = true
        cmd = [_INTL("Yes"),_INTL("No")]
        Kernel.pbMessageDisplay(@sprites["msgwindow"],_INTL("\\se[]{1} hatched from the Egg!\\wt[80]",@pokemon.name)) { self.update }
        Kernel.pbMessageDisplay(@sprites["msgwindow"],_INTL("Would you like to nickname the newly hatched {1}?",@pokemon.name)) { self.update }
        if Kernel.pbShowCommands(@sprites["msgwindow"],cmd,1,0) { self.update } == 0
          nickname = pbEnterPokemonName(_INTL("{1}'s nickname?",@pokemon.name),0,10,"",@pokemon,true)
          @pokemon.name = nickname if nickname != ""
          @nicknamed = true
        end
        @sprites["msgwindow"].text = ""
        @sprites["msgwindow"].visible = false
      end
      
      def wait(frames=1)
        frames.times do
          Graphics.update
          self.update
        end
      end
      
      def pbEndScene
        $game_temp.message_window_showing = false if $game_temp
        16.times do
          @viewport.color.alpha += 16
          wait
        end
        pbDisposeSpriteHash(@sprites)
        16.times do
          @viewport.color.alpha -= 16
          pbWait(1)
        end
        @viewport.dispose
      end
    end
  end
end
if defined?(PokemonEggHatch_Scene)
  PokemonEggHatch_Scene.send(:include,EBS_EggHatching)
end
if defined?(PokemonEggHatchScene)
  PokemonEggHatchScene.send(:include,EBS_EggHatching)
end