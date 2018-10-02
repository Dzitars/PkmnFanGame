#===============================================================================
#  Elite Battle system
#    by Luka S.J.
# ----------------
#  Battle Script
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
#-------------------------------------------------------------------------------
#  BattleCore processing
#  aliasing and new def is called to account for several changes done to the
#  way Pokemon are initially sent into battle
#===============================================================================  
#SE_EXTRA_PATH = isVersion17? ? "Anim/" : ""
SE_EXTRA_PATH = ""
class PokeBattle_Battle
  attr_reader :midspeech
  attr_reader :cuedbgm
  attr_accessor :midspeech_done
  attr_accessor :abilityMessage
  attr_accessor :abilityChange
  attr_accessor :abilityTrick
  attr_accessor :abilityIntimidate
  
  def endspeech=(msg)
    @midspeech=""
    @cuedbgm=nil
    @midspeech_done=false
    if msg.is_a?(Array)
      @endspeech=msg[0]
      @midspeech=msg[1]
      @cuedbgm=msg[2] if msg.length > 2
    else
      @endspeech=msg
    end
  end
  
  alias pbStartBattleCore_ebs pbStartBattleCore unless self.method_defined?(:pbStartBattleCore_ebs)
  def pbStartBattleCore(canlose)
    if !@fullparty1 && @party1.length > MAXPARTYSIZE
      raise ArgumentError.new(_INTL("Party 1 has more than {1} Pokémon.",MAXPARTYSIZE))
    end
    if !@fullparty2 && @party2.length > MAXPARTYSIZE
      raise ArgumentError.new(_INTL("Party 2 has more than {1} Pokémon.",MAXPARTYSIZE))
    end
    if !@opponent
    #========================
    # Initialize wild Pokémon
    #========================
      if @party2.length==1
        if @doublebattle
          raise _INTL("Only two wild Pokémon are allowed in double battles")
        end
        wildpoke=@party2[0]
        @battlers[1].pbInitialize(wildpoke,0,false)
        @peer.pbOnEnteringBattle(self,wildpoke)
        pbSetSeen(wildpoke)
        @scene.pbStartBattle(self)
        @scene.sendingOut=true
        pbDisplayPaused(_INTL("Wild {1} appeared!",wildpoke.name))
        @scene.ebSpecialSpecies_end if $specialSpecies
      elsif @party2.length==2
        if !@doublebattle
          raise _INTL("Only one wild Pokémon is allowed in single battles")
        end
        @battlers[1].pbInitialize(@party2[0],0,false)
        @battlers[3].pbInitialize(@party2[1],0,false)
        @peer.pbOnEnteringBattle(self,@party2[0])
        @peer.pbOnEnteringBattle(self,@party2[1])
        pbSetSeen(@party2[0])
        pbSetSeen(@party2[1])
        @scene.pbStartBattle(self)
        pbDisplayPaused(_INTL("Wild {1} and\r\n{2} appeared!",
           @party2[0].name,@party2[1].name))
      else
        raise _INTL("Only one or two wild Pokémon are allowed")
      end
    elsif @doublebattle
    #=======================================
    # Initialize opponents in double battles
    #=======================================
      if @opponent.is_a?(Array)
        $smAnim = false
        if @opponent.length==1
          @opponent=@opponent[0]
        elsif @opponent.length!=2
          raise _INTL("Opponents with zero or more than two people are not allowed")
        end
      end
      if @player.is_a?(Array)
        if @player.length==1
          @player=@player[0]
        elsif @player.length!=2
          raise _INTL("Player trainers with zero or more than two people are not allowed")
        end
      end
      @scene.pbStartBattle(self)
      @scene.sendingOut=true
      if @opponent.is_a?(Array)
        pbDisplayPaused(_INTL("{1} and {2} want to battle!",@opponent[0].fullname,@opponent[1].fullname))
        sendout1=pbFindNextUnfainted(@party2,0,pbSecondPartyBegin(1))
        raise _INTL("Opponent 1 has no unfainted Pokémon") if sendout1 < 0
        sendout2=pbFindNextUnfainted(@party2,pbSecondPartyBegin(1))
        raise _INTL("Opponent 2 has no unfainted Pokémon") if sendout2 < 0
        @battlers[1].pbInitialize(@party2[sendout1],sendout1,false)
        @battlers[3].pbInitialize(@party2[sendout2],sendout2,false)
        @scene.smTrainerSequence.finish if @scene.smTrainerSequence
        pbDisplayBrief(_INTL("{1} sent\r\nout {2}! {3} sent\r\nout {4}!",@opponent[0].fullname,getBattlerPokemon(@battlers[1]).name,@opponent[1].fullname,getBattlerPokemon(@battlers[3]).name))
        pbSendOutInitial(@doublebattle,1,@party2[sendout1],3,@party2[sendout2])
      else
        pbDisplayPaused(_INTL("{1}\r\nwould like to battle!",@opponent.fullname))
        sendout1=pbFindNextUnfainted(@party2,0)
        sendout2=pbFindNextUnfainted(@party2,sendout1+1)
        if sendout1 < 0 || sendout2 < 0
          raise _INTL("Opponent doesn't have two unfainted Pokémon")
        end
        @battlers[1].pbInitialize(@party2[sendout1],sendout1,false)
        @battlers[3].pbInitialize(@party2[sendout2],sendout2,false)
        @scene.smTrainerSequence.finish if @scene.smTrainerSequence
        pbDisplayBrief(_INTL("{1} sent\r\nout {2} and {3}!",
           @opponent.fullname,getBattlerPokemon(@battlers[1]).name,getBattlerPokemon(@battlers[3]).name))
        pbSendOutInitial(@doublebattle,1,@party2[sendout1],3,@party2[sendout2])
      end
    else
    #======================================
    # Initialize opponent in single battles
    #======================================
      sendout=pbFindNextUnfainted(@party2,0)
      raise _INTL("Trainer has no unfainted Pokémon") if sendout < 0
      if @opponent.is_a?(Array)
        raise _INTL("Opponent trainer must be only one person in single battles") if @opponent.length!=1
        @opponent=@opponent[0]
      end
      if @player.is_a?(Array)
        raise _INTL("Player trainer must be only one person in single battles") if @player.length!=1
        @player=@player[0]
      end
      trainerpoke=@party2[0]
      @battlers[1].pbInitialize(trainerpoke,sendout,false)
      @scene.pbStartBattle(self)
      @scene.sendingOut=true
      pbDisplayPaused(_INTL("{1}\r\nwould like to battle!",@opponent.fullname))
      @scene.smTrainerSequence.finish if @scene.smTrainerSequence
      pbDisplayBrief(_INTL("{1} sent\r\nout {2}!",@opponent.fullname,getBattlerPokemon(@battlers[1]).name))
      pbSendOutInitial(@doublebattle,1,trainerpoke)
    end
    #=====================================
    # Initialize players in double battles
    #=====================================
    if @doublebattle
      @scene.sendingOut=true
      if @player.is_a?(Array)
        sendout1=pbFindNextUnfainted(@party1,0,pbSecondPartyBegin(0))
        raise _INTL("Player 1 has no unfainted Pokémon") if sendout1 < 0
        sendout2=pbFindNextUnfainted(@party1,pbSecondPartyBegin(0))
        raise _INTL("Player 2 has no unfainted Pokémon") if sendout2 < 0
        @battlers[0].pbInitialize(@party1[sendout1],sendout1,false)
        @battlers[2].pbInitialize(@party1[sendout2],sendout2,false)
        pbDisplayBrief(_INTL("{1} sent\r\nout {2}!  Go! {3}!",
           @player[1].fullname,getBattlerPokemon(@battlers[2]).name,getBattlerPokemon(@battlers[0]).name))
        pbSetSeen(@party1[sendout1])
        pbSetSeen(@party1[sendout2])
      else
        sendout1=pbFindNextUnfainted(@party1,0)
        sendout2=pbFindNextUnfainted(@party1,sendout1+1)
        if sendout1 < 0 || sendout2 < 0
          raise _INTL("Player doesn't have two unfainted Pokémon")
        end
        @battlers[0].pbInitialize(@party1[sendout1],sendout1,false)
        @battlers[2].pbInitialize(@party1[sendout2],sendout2,false)
        pbDisplayBrief(_INTL("Go! {1} and {2}!",getBattlerPokemon(@battlers[0]).name,getBattlerPokemon(@battlers[2]).name))
      end
      pbSendOutInitial(@doublebattle,0,@party1[sendout1],2,@party1[sendout2])
    else
    #====================================
    # Initialize player in single battles
    #====================================
      @scene.sendingOut=true
      sendout=pbFindNextUnfainted(@party1,0)
      if sendout < 0
        raise _INTL("Player has no unfainted Pokémon")
      end
      playerpoke=@party1[sendout]
      @battlers[0].pbInitialize(playerpoke,sendout,false)
      pbDisplayBrief(_INTL("Go! {1}!",getBattlerPokemon(@battlers[0]).name))
      pbSendOutInitial(@doublebattle,0,playerpoke)
    end
    #==================
    # Initialize battle
    #==================
    if @weather==PBWeather::SUNNYDAY
      pbDisplay(_INTL("The sunlight is strong."))
    elsif @weather==PBWeather::RAINDANCE
      pbDisplay(_INTL("It is raining."))
    elsif @weather==PBWeather::SANDSTORM
      pbDisplay(_INTL("A sandstorm is raging."))
    elsif @weather==PBWeather::HAIL
      pbDisplay(_INTL("Hail is falling."))
    elsif PBWeather.const_defined?(:HEAVYRAIN) && @weather==PBWeather::HEAVYRAIN
      pbDisplay(_INTL("It is raining heavily."))
    elsif PBWeather.const_defined?(:HARSHSUN) && @weather==PBWeather::HARSHSUN
      pbDisplay(_INTL("The sunlight is extremely harsh."))
    elsif PBWeather.const_defined?(:STRONGWINDS) && @weather==PBWeather::STRONGWINDS
      pbDisplay(_INTL("The wind is strong."))
    end
    pbOnActiveAll   # Abilities
    @turncount=0
    loop do   # Now begin the battle loop
      PBDebug.log("***Round #{@turncount+1}***") if $INTERNAL
      if @debug && @turncount >=100
        @decision=pbDecisionOnTime()
        PBDebug.log("***[Undecided after 100 rounds]")
        pbAbort
        break
      end
      PBDebug.logonerr{
         pbCommandPhase
      }
      break if @decision > 0
      PBDebug.logonerr{
         pbAttackPhase
      }
      break if @decision > 0
      @scene.clearMessageWindow
      PBDebug.logonerr{
         pbEndOfRoundPhase
      }
      break if @decision > 0
      @turncount+=1
    end
    return pbEndOfBattle(canlose)
  end
  
  def pbSendOutInitial(doublebattle,*args)
    index = args[0]
    pokemon = args[1]
    if doublebattle
      index2 = args[2]
      pokemon2 = args[3]
    end
    pbSetSeen(pokemon)
    pbSetSeen(pokemon2) if doublebattle
    @peer.pbOnEnteringBattle(self,pokemon)
    @peer.pbOnEnteringBattle(self,pokemon2) if doublebattle
    if pbIsOpposing?(index)
      @scene.pbTrainerSendOut(nil,nil)
    else
      @scene.pbSendOut(nil,nil)
    end
    @scene.pbResetMoveIndex(index)
    @scene.pbResetMoveIndex(index2) if doublebattle
    return if !self.respond_to?(:pbPrimalReversion)
    pbPrimalReversion(index)
    pbPrimalReversion(index2) if doublebattle
  end
  
  alias pbReplace_ebs pbReplace unless self.method_defined?(:pbReplace_ebs)
  def pbReplace(index,newpoke,batonpass=false)
    @abilityTrick = nil
    @scene.databoxVisible(false,true)
    if !@replaced
      @battlers[index].pbResetForm
      if !@battlers[index].isFainted?
        @scene.pbRecall(index)
      end
    end
    pbReplace_ebs(index,newpoke,batonpass)
    @replaced=false
  end

  alias pbRecallAndReplace_ebs pbRecallAndReplace unless self.method_defined?(:pbRecallAndReplace_ebs)
  def pbRecallAndReplace(*args)
    @replaced=true
    @scene.sendingOut=true if args[0]%2==0
    return pbRecallAndReplace_ebs(*args)
  end
  
  alias pbRun_ebs pbRun unless self.method_defined?(:pbRun_ebs)
  def pbRun(idxPokemon,duringBattle=false)
    ret=pbRun_ebs(idxPokemon,duringBattle=false)
    pbSEPlay("BW_flee",80) if ret==1 && !self.opponent
    return ret
  end
    
  alias pbCommandPhase_ebs pbCommandPhase unless self.method_defined?(:pbCommandPhase_ebs)
  def pbCommandPhase
    pbCommandPhase_ebs
    @scene.idleTimer=-1
  end
  
  alias pbEndOfRoundPhase_ebs pbEndOfRoundPhase unless self.method_defined?(:pbEndOfRoundPhase_ebs)
  def pbEndOfRoundPhase
    ret = pbEndOfRoundPhase_ebs
    @scene.clearMessageWindow
    @scene.pbTrainerBattleSpeech
    return ret
  end
  
  alias pbAttackPhase_ebs pbAttackPhase unless self.method_defined?(:pbAttackPhase_ebs)
  def pbAttackPhase
    $skipDatWait = true
    ret = pbAttackPhase_ebs
    @scene.afterAnim = false
    16.times do
      @scene.animateBattleSprites
      Graphics.update
    end    
    return ret
  end

  alias pbSwitch_ebs pbSwitch unless self.method_defined?(:pbSwitch_ebs)
  def pbSwitch(*args)
    show = false
    for index in 0...4
      next if @battlers[index] && !@battlers[index].isFainted?
      next if !pbCanChooseNonActive?(index)
      if !pbOwnedByPlayer?(index)
        if !pbIsOpposing?(index) || (@opponent && pbIsOpposing?(index))
          if !@doublebattle && @battlers[0].hp>0 && @shiftStyle && @opponent && @internalbattle && pbCanChooseNonActive?(0) && pbIsOpposing?(index) && @battlers[0].effects[PBEffects::Outrage]==0
            show = true
          end
        end
      end
    end
    if EBUISTYLE == 2 && self.opponent && show
      @scene.commandWindow.drawLineup
      10.times do; @scene.commandWindow.showArrows; @scene.wait(1); end
    end
    ret = pbSwitch_ebs(*args)
    return ret
  end
  
  def pbDisplay(msg)
    tricked=false
    if !@abilityTrick.nil?
      @scene.pbDisplayEffect(@abilityTrick)
      tricked=true
    end
    @scene.databoxVisible(false) if @abilityMessage.nil? || tricked
    if !@abilityMessage.nil? && @abilityTrick.nil?
      @scene.pbDisplayEffect(@abilityMessage)
    else
      @scene.pbDisplayMessage(msg)
    end
    if !@abilityIntimidate.nil?
      @scene.pbDisplayEffect(@abilityIntimidate)
      @scene.databoxVisible(false)
      @scene.pbDisplayMessage(msg)
    end
    @scene.clearMessageWindow if !@scene.briefmessage
    @scene.databoxVisible(!@scene.windowVisible?)
    @abilityTrick = nil
    @abilityMessage = nil
    @abilityIntimidate = nil
  end
  
  alias pbThrowPokeBall_ebs pbThrowPokeBall unless self.method_defined?(:pbThrowPokeBall_ebs)
  def pbThrowPokeBall(*args)
    @scene.briefmessage = true
    ret = pbThrowPokeBall_ebs(*args)
    @scene.briefmessage = false
    return ret
  end

  def pbDisplayPaused(msg)
    @scene.databoxVisible(false)
    @scene.pbDisplayPausedMessage(msg)
    @scene.clearMessageWindow if !@scene.briefmessage
    @scene.databoxVisible(!@scene.windowVisible?)
  end

  def pbDisplayBrief(msg)
    @scene.databoxVisible(false)
    @scene.pbDisplayMessage(msg,true)
    @scene.clearMessageWindow if !@scene.briefmessage
    @scene.databoxVisible(!@scene.windowVisible?)
  end

  def pbDisplayConfirm(msg)
    @scene.databoxVisible(false)
    ret = @scene.pbDisplayConfirmMessage(msg)
    @scene.clearMessageWindow if !@scene.briefmessage
    @scene.databoxVisible(!@scene.windowVisible?)
    return ret
  end

  def pbShowCommands(msg,commands,cancancel=true)
    @scene.databoxVisible(false)
    ret = @scene.pbShowCommands(msg,commands,cancancel)
    @scene.clearMessageWindow if !@scene.briefmessage
    @scene.databoxVisible(!@scene.windowVisible?)
    return ret
  end
end
# Different methods used to obtain pokemon data from battlers
# Added for Gen 6 Project compatibility
def getBattlerPokemon(battler)
  if battler.is_a?(Array)
    bat=PokeBattle_Battler.new(self,battler[1])
    bat.pbInitialize(battler[0],battler[1],false)
    battler=bat
  end
  if PBEffects.const_defined?(:Illusion) && battler.respond_to?('effects') && !battler.effects[PBEffects::Illusion].nil?
    return battler.effects[PBEffects::Illusion]
  else
    return battler
  end
end

def getBattlerMetrics(metrics,battler)
  pokemon = getBattlerPokemon(battler)
  pokemon = pokemon.pokemon if pokemon.respond_to?(:pokemon)
  return metrics[2][pokemon.species]
end

def playBattlerCry(battler)
  species = battler.species
  pokemon = getBattlerPokemon(battler)
  pokemon = pokemon.pokemon if pokemon.respond_to?(:pokemon)
  pbPlayCry(pokemon ? pokemon : species)
end

def shinyBattler?(battler)
  pokemon = getBattlerPokemon(battler)
  pokemon = pokemon.pokemon if pokemon.respond_to?(:pokemon)
  return pokemon.isShiny?
end
#===============================================================================
#  Used for the Illusion ability
#===============================================================================  
class PokeBattle_Battler
  attr_accessor :thisMoveHits
  
  def name
    if PBEffects.const_defined?(:Illusion) && @effects && !@effects[PBEffects::Illusion].nil?
      return @effects[PBEffects::Illusion].name
    else
      return @name
    end
  end
  
  alias pbThis_ebs pbThis unless self.method_defined?(:pbThis_ebs)
  def pbThis(lowercase=false)
    if @battle.pbIsOpposing?(@index)
      if @battle.opponent
        return lowercase ? _INTL("the foe {1}",self.name) : _INTL("The foe {1}",self.name)
      else
        return lowercase ? _INTL("the wild {1}",self.name) : _INTL("The wild {1}",self.name)
      end
    elsif @battle.pbOwnedByPlayer?(@index)
      return _INTL("{1}",self.name)
    else
      return lowercase ? _INTL("the ally {1}",self.name) : _INTL("The ally {1}",self.name)
    end
  end
  
  alias pbSuccessCheck_ebs pbSuccessCheck unless self.method_defined?(:pbSuccessCheck_ebs)
  def pbSuccessCheck(*args)
    index = args[1].index
    ret = pbSuccessCheck_ebs(*args)
    @battle.scene.revertMoveTransformations(index) if ret==false
    return ret
  end
  
  alias pbProcessMoveAgainstTarget_ebs pbProcessMoveAgainstTarget unless self.method_defined?(:pbProcessMoveAgainstTarget_ebs)
  def pbProcessMoveAgainstTarget(*args)
    @thisMoveHits = args[3]
    return pbProcessMoveAgainstTarget_ebs(*args)
  end
end
#===============================================================================
#  Ability Message handlers
#  used to display abilities in the style of Gen >= 5 games
#===============================================================================  
if EFFECTMESSAGES

class PokeBattle_Battler
  alias pbAbilitiesOnSwitchIn_ebs pbAbilitiesOnSwitchIn unless self.method_defined?(:pbAbilitiesOnSwitchIn_ebs)
  def pbAbilitiesOnSwitchIn(*args)
    if self.checkForAbilities(:FRISK,:FOREWARN,:BADDREAMS,:MOODY,:HARVEST,:TRACE,:INTIMIDATE)
      @battle.abilityTrick = self
    else
      @battle.abilityMessage = self
    end
    ret = pbAbilitiesOnSwitchIn_ebs(*args)
    @battle.abilityTrick = nil
    @battle.abilityMessage = nil
    return ret    
  end
  
  alias pbUseMove_ebs pbUseMove unless self.method_defined?(:pbUseMove_ebs)
  def pbUseMove(*args)
    if self.checkForAbilities(:STANCECHANGE)
      @battle.abilityChange = self
    end
    @battle.abilityTrick = nil
    @battle.abilityIntimidate = nil
    if self.checkForAbilities(:PROTEAN)
      @battle.abilityMessage = self
    end
    ret = pbUseMove_ebs(*args)
    @battle.abilityMessage = nil
    @battle.abilityChange = nil
    return ret
  end
    
  if self.method_defined?(:pbReduceAttackStatIntimidate) 
    alias pbReduceAttackStatIntimidate_ebs pbReduceAttackStatIntimidate unless self.method_defined?(:pbReduceAttackStatIntimidate_ebs)
    def pbReduceAttackStatIntimidate(*args)
      if self.checkForAbilities(:CLEARBODY,:WHITESMOKE,:HYPERCUTTER,:FLOWERVEIL)
        @battle.abilityIntimidate = self
        @battle.abilityTrick = nil
      end
      return pbReduceAttackStatIntimidate_ebs(*args)
    end
  else
    alias pbReduceAttackStatStageIntimidate_ebs pbReduceAttackStatStageIntimidate unless self.method_defined?(:pbReduceAttackStatStageIntimidate_ebs)
    def pbReduceAttackStatStageIntimidate(*args)
      if self.checkForAbilities(:CLEARBODY,:WHITESMOKE,:HYPERCUTTER,:FLOWERVEIL)
        @battle.abilityIntimidate = self
        @battle.abilityTrick = nil
      end
      return pbReduceAttackStatStageIntimidate_ebs(*args)
    end
  end

  def checkForAbilities(*args)
    return false if !PokeBattle_Battler.method_defined?(:hasWorkingAbility)
    ret = false
    for arg in args
      ret = true if self.hasWorkingAbility(arg)
    end
    return ret
  end
  
  alias pbAbilityCureCheck_ebs pbAbilityCureCheck unless self.method_defined?(:pbAbilityCureCheck_ebs)
  def pbAbilityCureCheck(*args)
    @battle.abilityTrick = self
    ret = pbAbilityCureCheck_ebs(*args)
    @battle.abilityTrick = nil
    return ret
  end
  
  if self.method_defined?(:pbEffectsAfterHit)
    alias pbEffectsAfterHit_ebs pbEffectsAfterHit unless self.method_defined?(:pbEffectsAfterHit_ebs)
    def pbEffectsAfterHit(*args)
      user = args[0]; target = args[1]
      @battle.abilityTrick = user if user.checkForAbilities(:MOXIE,:MAGICIAN)
      @battle.abilityTrick = target if target.checkForAbilities(:COLORCHANGE,:PICKPOCKET)
      ret = pbEffectsAfterHit_ebs(*args)
      @battle.abilityTrick = nil
      return ret
    end
  end
  
  if self.method_defined?(:pbEffectsOnDealingDamage)
    alias pbEffectsOnDealingDamage_ebs pbEffectsOnDealingDamage unless self.method_defined?(:pbEffectsOnDealingDamage_ebs)
    def pbEffectsOnDealingDamage(*args)
      target = args[2]
      @battle.abilityMessage = target if target.checkForAbilities(:AFTERMATH,:CUTECHARM,:EFFECTSPORE,:FLAMEBODY,:MUMMY,:POISONPOINT,:ROUGHSKIN,:IRONBARBS,:STATIC,:GOOEY,:POISONTOUCH,:CURSEDBODY,:JUSTIFIED,:RATTLED,:WEAKARMOR,:ANGERPOINT)
      ret = pbEffectsOnDealingDamage_ebs(*args)
      @battle.abilityMessage = nil
      return ret
    end
  end
    
end

class PokeBattle_Move
  if self.method_defined?(:pbTypeImmunityByAbility)
    alias pbTypeImmunityByAbility_ebs pbTypeImmunityByAbility unless self.method_defined?(:pbTypeImmunityByAbility_ebs)
    def pbTypeImmunityByAbility(*args)
      @battle.abilityMessage = args[2]
      ret = pbTypeImmunityByAbility_ebs(*args)
      @battle.abilityMessage = nil
      return ret
    end
  else
    alias pbTypeModMessages_ebs pbTypeModMessages unless self.method_defined?(:pbTypeModMessages_ebs)
    def pbTypeModMessages(*args)
      @battle.abilityMessage = args[2]
      ret = pbTypeModMessages_ebs(*args)
      @battle.abilityMessage = nil
      return ret
    end
  end
end

end
#-------------------------------------------------------------------------------
#  Automatic sprite name indexing for v4.3 and above
#-------------------------------------------------------------------------------
module EBS_SpriteConversion
  def self.included base
    base.class_eval do
      alias loadSpriteConversion pbStartLoadScreen if !self.method_defined?(:loadSpriteConversion)
      def pbStartLoadScreen(*args)
        # skips if not in debug mode
        return loadSpriteConversion(*args) if !$memDebug || Input.press?(Input::CTRL)
        # generates a list of all .png files
        allFiles = readDirectoryFiles("Graphics/Battlers/",["*.png"])
        files = []
        # pushes the necessary file names into the main processing list
        for i in 1..PBSpecies.maxValue
          next if !(getConstantName(PBSpecies,i) rescue nil)
          species = sprintf("%03d",i)
          species_name = getConstantName(PBSpecies,i)
          j = 0
          (allFiles.length).times do
            sprite = allFiles[j]
            if sprite.include?(species) || sprite.include?(species_name)
              files.push(sprite)
              allFiles.delete_at(j)
            else
              j += 1
            end
          end
        end
        # starts automatic renaming
        unless files.empty? && !allFiles.include?("egg.png") && !allFiles.include?("eggCracks.png")
          Kernel.pbMessage("The game has detected that you're running the Elite Battle System version 4.3 or above, but have sprites in your Graphics/Battlers that do not match the new naming convention. This will break your game!")
          if Kernel.pbConfirmMessage("Would you like to automatically resolve this issue?")
            dir = "Graphics/Battlers/"
            # creates new directories if necessary
            for ext in ["Front/","Back/","FrontShiny/","BackShiny/","Eggs/"]
              Dir.mkdir(dir+ext) if !FileTest.directory?(dir+ext)
              Dir.mkdir(dir+ext+"Female/") if !FileTest.directory?(dir+ext+"Female/") && ext != "Eggs/"
            end
            for file in files
              user = dir+file
              dest = dir
              # generates target directory and target name
              if file.include?("egg") || file.include?("Egg")
                dest = dir+"Eggs/"
                if file.include?("eggCracks")
                  new_name = file.gsub(/eggCracks/) {|s| "cracks" }
                elsif file.include?("Egg")
                  new_name = file.gsub(/Egg/) {|s| "" } 
                else
                  new_name = file.gsub(/egg/) {|s| "" }
                end
              elsif file.include?("s")
                if file.include?("b")
                  dest = dir+"BackShiny/"
                  new_name = file.gsub(/sb/) {|s| "" }
                else
                  dest = dir+"FrontShiny/"
                  new_name = file.gsub(/s/) {|s| "" }
                end
              else
                if file.include?("b")
                  dest = dir+"Back/"
                  new_name = file.gsub(/b/) {|s| "" }
                else
                  dest = dir+"Front/"
                  new_name = file
                end
              end
              if file.include?("f")
                dest += "Female/"
                new_name.gsub!(/f/) {|s| "" }
              end
              target = dest+new_name
              # moves the files into their appropriate folders
              File.rename(user,target)
            end
          end
          # Egg conversion
          allFiles = readDirectoryFiles("Graphics/Battlers/",["*.png"])
          for file in allFiles
            if file == "egg.png"
              File.rename("Graphics/Battlers/egg.png","Graphics/Battlers/Eggs/000.png")
            elsif file == "eggCracks.png"
              File.rename("Graphics/Battlers/eggCracks.png","Graphics/Battlers/Eggs/000cracks.png")
            end
          end
          Kernel.pbMessage("Conversion complete! Have fun using the new system!")
        end
        # goes back to the load screen
        return loadSpriteConversion(*args)
      end
    end
  end
end

if defined?(PokemonLoadScreen)
  PokemonLoadScreen.send(:include,EBS_SpriteConversion)
end

if defined?(PokemonLoad)
  PokemonLoad.send(:include,EBS_SpriteConversion)
end