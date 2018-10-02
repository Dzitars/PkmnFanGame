#===============================================================================
#  Elite Battle system
#    by Luka S.J.
# ----------------
#  UI Script
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
#  A brand new interface for Pokemon Essentials, to be used with the dynamic
#  battle system. Command and Fight windows are not based upon the previous
#  versions. Keep that in mind if you did (or plan to do) any alterations to the
#  interfaces.
#===============================================================================
module PokeBattle_SceneConstants
  if EBUISTYLE > 0
    MESSAGEBASECOLOR        = Color.new(255,255,255)
    MESSAGESHADOWCOLOR      = Color.new(32,32,32)
    MENUBASECOLOR           = MESSAGEBASECOLOR
    MENUSHADOWCOLOR         = MESSAGESHADOWCOLOR
    BOXTEXTBASECOLOR        = MESSAGEBASECOLOR
    BOXTEXTSHADOWCOLOR      = MESSAGESHADOWCOLOR
    HPGAUGESIZE             = 168
    EXPGAUGESIZE            = 260
  end
end
#===============================================================================
#  Pokemon data battle boxes
#  UI overhaul
#===============================================================================
class PokemonNewDataBox  <  SpriteWrapper
  attr_reader :battler
  attr_accessor :selected
  attr_accessor :appearing
  attr_reader :animatingHP
  attr_reader :animatingEXP
 
  def initialize(battler,doublebattle,viewport=nil,player=nil,scene=nil)
    view = Viewport.new(viewport.rect.x,viewport.rect.y,viewport.rect.width,viewport.rect.height)
    view.z = viewport.z + 1
    viewport = view
    super(viewport)
    @scene=scene
    @explevel=0
    @player=player
    @battler=battler
    @doublebattle=doublebattle
    @selected=0
    @frame=0
    @showhp=false
    @showexp=false
    @appearing=false
    @animatingHP=false
    @starthp=0
    @currenthp=0
    @endhp=0
    @expflash=0
    if (@battler.index&1)==0 # if player's Pokémon
      @spritebaseX=34
      @playerpoke=true
    else
      @spritebaseX=16
      @playerpoke=false
    end
    if !doublebattle && @battler.index==0
      @showhp=true
      @showexp=true
    end
    @statuses=pbBitmap("#{checkEBFolderPath}/newStatuses")
    @contents=BitmapWrapper.new(264,78)
    self.bitmap=@contents
    self.visible=false
    self.z=50
    refreshExpLevel
    refresh
  end
 
  def dispose
    @statuses.dispose
    @contents.dispose
    super
  end
 
  def refreshExpLevel
    if !@battler.pokemon
      @explevel=0
    else
      growthrate=@battler.pokemon.growthrate
      startexp=PBExperience.pbGetStartExperience(@battler.pokemon.level,growthrate)
      endexp=PBExperience.pbGetStartExperience(@battler.pokemon.level+1,growthrate)
      if startexp==endexp
        @explevel=0
      else
        @explevel=(@battler.pokemon.exp-startexp)*PokeBattle_SceneConstants::EXPGAUGESIZE/(endexp-startexp)
      end
    end
  end
 
  def exp
    return @animatingEXP ? @currentexp : @explevel
  end
 
  def hp
    return @animatingHP ? @currenthp : @battler.hp
  end
 
  def animateHP(oldhp,newhp)
    @starthp=oldhp
    @currenthp=oldhp
    @endhp=newhp
    @animatingHP=true
  end
 
  def animateEXP(oldexp,newexp)
    @currentexp=oldexp
    @endexp=newexp
    @animatingEXP=true
  end
 
  def appear
    refreshExpLevel
    refresh
    self.visible=true
    self.opacity=255
  end
  
  def getBattler(battler)
    return battler.effects[PBEffects::Illusion] if PBEffects.const_defined?(:Illusion) && battler.respond_to?('effects') && !battler.effects[PBEffects::Illusion].nil?
    return battler
  end
 
  def refresh
    self.bitmap.clear
    return if !@battler.pokemon
    if @playerpoke # Player Pokemon box
      isOutsider=(@battler.pokemon.trainerID!=@player.id || (@battler.pokemon.language!=0 && @battler.pokemon.language!=@player.language))
      y=0; y=1 if isOutsider;
      self.bitmap.blt(22,0,pbBitmap("#{checkEBFolderPath}/bbtrans"),Rect.new(0,0,242,54))
      y=0; y=32 if @doublebattle;
      self.bitmap.blt(0,36,pbBitmap("#{checkEBFolderPath}/exparea"),Rect.new(0,y,262,32))
      self.bitmap.blt(2,32,pbBitmap("#{checkEBFolderPath}/expbar"),Rect.new(0,y*34,self.exp,34)) if !@doublebattle
      self.bitmap.blt(54,40,pbBitmap("#{checkEBFolderPath}/hparea"),Rect.new(0,0,180,16))
     
      hpGaugeSize=PokeBattle_SceneConstants::HPGAUGESIZE
      hpgauge=@battler.totalhp==0 ? 0 : (self.hp*hpGaugeSize/@battler.totalhp)
      hpgauge=2 if hpgauge==0 && self.hp > 0
      hpzone=0
      hpzone=1 if self.hp <=(@battler.totalhp/2).floor
      hpzone=2 if self.hp <=(@battler.totalhp/3.5).floor
      self.bitmap.blt(54,40,pbBitmap("#{checkEBFolderPath}/hpbars"),Rect.new(0,20*hpzone,6,20)) if self.hp > 0
      self.bitmap.blt(60,40,pbBitmap("#{checkEBFolderPath}/hpbars"),Rect.new(6,20*hpzone,hpgauge,20))
      self.bitmap.blt(60+hpgauge,40,pbBitmap("#{checkEBFolderPath}/hpbars"),Rect.new(174,20*hpzone,6,20)) if self.hp > 0
      y=58; y-=26 if @doublebattle;
      self.bitmap.blt(44,y,@statuses,Rect.new(0,17*(@battler.status-1),52,17)) if @battler.status > 0
      self.bitmap.blt(22,34,pbBitmap("#{checkEBFolderPath}/mega_sym"),Rect.new(0,0,30,30)) if @battler.isMega?
      if @battler.respond_to?(:isPrimal?) && @battler.isPrimal?
        path=nil
        path="Graphics/Pictures/battlePrimalKyogreBox.png" if @battler.species == getConst(PBSpecies,:KYOGRE)
        path="Graphics/Pictures/battlePrimalGroudonBox.png" if @battler.species == getConst(PBSpecies,:GROUDON)
        #define any custom Primal graphics here
        self.bitmap.blt(22,34,pbBitmap(path),Rect.new(0,0,30,30))
      end
      self.bitmap.blt(148,52,pbBitmap("#{checkEBFolderPath}/hpind"),Rect.new(0,0,76,22)) if !@doublebattle
      pbSetSmallFont(self.bitmap)
      textpos=[
         ["#{self.hp}/#{@battler.totalhp}",152+34,50,2,Color.new(23,28,31),Color.new(185,185,185)]
      ]
      pbDrawTextPositions(self.bitmap,textpos) if !@doublebattle
      pbSetSystemFont(self.bitmap)
      pokename=getBattler(@battler).name
      textpos=[
         [pokename,8+44,5,false,Color.new(255,255,255),Color.new(32,32,32)]
      ]
      genderX=self.bitmap.text_size(pokename).width
      genderX+=14+44
      if getBattler(@battler).gender==0 # Male
        textpos.push([_INTL("♂"),genderX,5,false,Color.new(48+30,96+30,216),Color.new(32,32,32)])
      elsif getBattler(@battler).gender==1 # Female
        textpos.push([_INTL("♀"),genderX,5,false,Color.new(248,88+30,40+30),Color.new(32,32,32)])
      end
      textpos.push([_INTL("Lv{1}",@battler.level),242,5,true,Color.new(255,255,255),Color.new(32,32,32)])
      pbDrawTextPositions(self.bitmap,textpos)
     
    else # Enemy Pokemon box
     
      self.bitmap.blt(0,0,pbBitmap("#{checkEBFolderPath}/bbtrans_opp"),Rect.new(0,0,242,54))
      y=0; y=32 if @doublebattle;
      self.bitmap.blt(2,36,pbBitmap("#{checkEBFolderPath}/exparea_opp"),Rect.new(0,y,262,32))
      self.bitmap.blt(30,40,pbBitmap("#{checkEBFolderPath}/hparea"),Rect.new(0,0,180,16))
     
      hpGaugeSize=PokeBattle_SceneConstants::HPGAUGESIZE
      hpgauge=@battler.totalhp==0 ? 0 : (self.hp*hpGaugeSize/@battler.totalhp)
      hpgauge=2 if hpgauge==0 && self.hp > 0
      hpzone=0
      hpzone=1 if self.hp <=(@battler.totalhp/2).floor
      hpzone=2 if self.hp <=(@battler.totalhp/3.5).floor
      self.bitmap.blt(30,40,pbBitmap("#{checkEBFolderPath}/hpbars"),Rect.new(0,20*hpzone,6,20)) if self.hp > 0
      self.bitmap.blt(36,40,pbBitmap("#{checkEBFolderPath}/hpbars"),Rect.new(6,20*hpzone,hpgauge,20))
      self.bitmap.blt(36+hpgauge,40,pbBitmap("#{checkEBFolderPath}/hpbars"),Rect.new(174,20*hpzone,6,20)) if self.hp > 0
      self.bitmap.blt(214,34,pbBitmap("#{checkEBFolderPath}/battleBoxOwned.png"),Rect.new(0,0,14,14)) if @battler.owned
      self.bitmap.blt(212,34,pbBitmap("#{checkEBFolderPath}/mega_sym"),Rect.new(0,0,30,30)) if @battler.isMega?
      if @battler.respond_to?(:isPrimal?) && @battler.isPrimal?
        path=nil
        path="Graphics/Pictures/battlePrimalKyogreBox.png" if @battler.species == getConst(PBSpecies,:KYOGRE)
        path="Graphics/Pictures/battlePrimalGroudonBox.png" if @battler.species == getConst(PBSpecies,:GROUDON)
        #define any custom Primal graphics here
        self.bitmap.blt(212,34,pbBitmap(path),Rect.new(0,0,30,30))
      end
      y=58; y-=26 if @doublebattle;
      self.bitmap.blt(20,y,@statuses,Rect.new(0,17*(@battler.status-1),52,17)) if @battler.status > 0
      pbSetSystemFont(self.bitmap)
      pokename=getBattler(@battler).name
      textpos=[
         [pokename,8+20,5,false,Color.new(255,255,255),Color.new(32,32,32)]
      ]
      genderX=self.bitmap.text_size(pokename).width
      genderX+=14+20
      if getBattler(@battler).gender==0 # Male
        textpos.push([_INTL("♂"),genderX,5,false,Color.new(48+30,96+30,216),Color.new(32,32,32)])
      elsif getBattler(@battler).gender==1 # Female
        textpos.push([_INTL("♀"),genderX,5,false,Color.new(248,88+30,40+30),Color.new(32,32,32)])
      end
      textpos.push([_INTL("Lv{1}",@battler.level),218,5,true,Color.new(255,255,255),Color.new(32,32,32)])
      pbDrawTextPositions(self.bitmap,textpos)
    end
  end
 
  def update
    super
    @frame+=1
    if @animatingHP
      if @currenthp < @endhp
        @currenthp += (@endhp - @currenthp)/10.0
        @currenthp = @currenthp.ceil
        @currenthp = @endhp if @currenthp > @endhp
      elsif @currenthp > @endhp        
        @currenthp -= (@currenthp - @endhp)/10.0
        @currenthp = @currenthp.floor
        @currenthp = @endhp if @currenthp < @endhp
      end
      refresh
      @animatingHP=false if @currenthp==@endhp
    end
    if @animatingEXP
      if !@showexp
        @currentexp=@endexp
      elsif @currentexp < @endexp   # Gaining Exp
        if @endexp >=PokeBattle_SceneConstants::EXPGAUGESIZE ||
           @endexp-@currentexp >=PokeBattle_SceneConstants::EXPGAUGESIZE/4
          @currentexp+=4
        else
          @currentexp+=2
        end
        @currentexp=@endexp if @currentexp > @endexp
      elsif @currentexp > @endexp   # Losing Exp
        if @endexp==0 ||
           @currentexp-@endexp >=PokeBattle_SceneConstants::EXPGAUGESIZE/4
          @currentexp-=4
        elsif @currentexp > @endexp
          @currentexp-=2
        end
        @currentexp=@endexp if @currentexp < @endexp
      end
      refresh
      if @currentexp==@endexp
        if @currentexp==PokeBattle_SceneConstants::EXPGAUGESIZE
          if @expflash==0
            pbSEPlay(isVersion17? ? "Pkmn exp full" : "expfull")
            self.flash(Color.new(64,200,248),8)
            @expflash=8
          else
            @expflash-=1
            if @expflash==0
              @animatingEXP=false
              refreshExpLevel
            end
          end
        else
          @animatingEXP=false
        end
      end
    end
  end
end

class NewSafariDataBox < SpriteWrapper
  attr_accessor :selected
  attr_reader :appearing

  def initialize(battle,viewport=nil)
    view = Viewport.new(viewport.rect.x,viewport.rect.y,viewport.rect.width,viewport.rect.height)
    view.z = viewport.z + 1
    viewport = view
    super(viewport)
    @selected=0
    @battle=battle
    @spriteX=PokeBattle_SceneConstants::SAFARIBOX_X
    @spriteY=PokeBattle_SceneConstants::SAFARIBOX_Y
    @appearing=false
    @contents=BitmapWrapper.new(264,78)
    self.bitmap=@contents
    pbSetSystemFont(self.bitmap)
    self.visible=false
    self.z=50
    refresh
  end

  def appear
    refresh
    self.visible=true
    self.opacity=255
  end

  def refresh
    self.bitmap.clear
    if EBUISTYLE==2
      bmp = pbBitmap("#{checkEBFolderPath}/nextGen/safariBar")
      self.bitmap.blt((self.bitmap.width-bmp.width)/2,self.bitmap.height-bmp.height,bmp,Rect.new(0,0,bmp.width,bmp.height))
      str = _INTL("Safari Balls: {1}",@battle.ballcount)
      pbDrawOutlineText(self.bitmap,0,0,self.bitmap.width,self.bitmap.height,str,Color.new(255,255,255),Color.new(0,0,0),1)
    else
      self.bitmap.blt(22,0,pbBitmap("#{checkEBFolderPath}/bbtrans"),Rect.new(0,0,242,54))
      self.bitmap.blt(0,36,pbBitmap("#{checkEBFolderPath}/exparea"),Rect.new(0,32,262,32))
      textpos=[]
      base=PokeBattle_SceneConstants::BOXTEXTBASECOLOR
      shadow=PokeBattle_SceneConstants::BOXTEXTSHADOWCOLOR
      textpos.push([_INTL("Safari Balls:    {1}",@battle.ballcount),54,8,false,base,shadow])
      pbDrawTextPositions(self.bitmap,textpos)
    end
  end

  def update
  end
end
#===============================================================================
#  Party arrow
#  creates an arrow indicating the amount of Pokemon a trainer has
#===============================================================================
class NewPartyArrow
  
  def initialize(viewport,party,player=false,doublebattle=false,secondparty=nil)
    @viewport = viewport
    @party = party
    @player = player
    @index = 0
    
    self.draw(party,player,doublebattle,secondparty)
    self.x = @player ? Graphics.width+@arrow.ox : -@arrow.bitmap.width
    self.y = @player ? 232 : 64
    
    @disposed = false
  end
  
  def x
    return @arrow.x
  end
  
  def y
    return @arrow.y - 28
  end
  
  def x=(val)
    @arrow.x = val
    for i in 0...6
      @ball["#{i}"].x = val - @arrow.ox + 12 + (i*(@ball["#{i}"].bitmap.width+2)) + @ball["#{i}"].ox
      @ball["#{i}"].x += 24 if @player
    end
  end
  
  def y=(val)
    @arrow.y = val + 28
    for i in 0...6
      @ball["#{i}"].y = @arrow.y - (@ball["#{i}"].bitmap.height-4) + @ball["#{i}"].oy
    end
  end
  
  def dispose
    @arrow.dispose
    for i in 0...6
      @ball["#{i}"].dispose
    end
    @disposed = true
  end
  
  def disposed?
    return @disposed
  end
  
  def color; return @arrow.color; end
  def color=(val); @arrow.color=val; end
  def tone; return @arrow.tone; end
  def tone=(val); @arrow.tone=val; end
  def visible; return @arrow.visible; end
  def visible=(val); @arrow.visible=val; end
  
  def draw(party,player=false,doublebattle=false,secondparty=nil)
    @arrow = Sprite.new(@viewport)
    @arrow.bitmap = pbBitmap("#{checkEBFolderPath}/partyArrow")
    @arrow.ox = @player ? 240 : 0
    @arrow.mirror = @player
    @ball = {}
    for i in 0...6
      k = i
      if !player && doublebattle && i >= 3 && !secondparty.nil?
        k = (i%3) + secondparty
      end
      @ball["#{i}"] = Sprite.new(@viewport)
      if k < party.length && party[k]
        if party[k].hp <=0 || party[k].isEgg?
          @ball["#{i}"].bitmap = pbBitmap("Graphics/Pictures/ballfainted")
        elsif party[k].status > 0
          @ball["#{i}"].bitmap = pbBitmap("Graphics/Pictures/ballstatus")
        else
          @ball["#{i}"].bitmap = pbBitmap("Graphics/Pictures/ballnormal")
        end
      else
        @ball["#{i}"].bitmap = pbBitmap("Graphics/Pictures/ballempty")
      end
      @ball["#{i}"].ox = @ball["#{i}"].bitmap.width/2
      @ball["#{i}"].oy = @ball["#{i}"].bitmap.height/2
      @ball["#{i}"].angle = @player ? -360 : 360
    end
  end
  
  def show
    pbSEPlay("SE_Party",75) if @index%3==0 && @index < 18
    self.x += @player ? -15 : 15
    for i in 0...6
      @ball["#{i}"].angle -= @player ? -22.5 : 22.5
    end    
    @index += 1
  end
  
  def hide
    @arrow.zoom_x += 0.032
    @arrow.opacity -= 16
    for i in 0...6
      @ball["#{i}"].angle -= @player ? -22.5 : 22.5
      @ball["#{i}"].opacity -= 16
      @ball["#{i}"].x += @player ? -(5-i) : i
    end
  end
  
end
#===============================================================================
#  Command Menu
#  UI ovarhaul
#===============================================================================
KleinCommandWindow = NewCommandWindow.clone if defined?(NewCommandWindow)=='constant'
class NewCommandWindow
  attr_accessor :index
  attr_accessor :overlay
  attr_accessor :backdrop
  attr_accessor :coolDown
  
  def initialize(viewport=nil,battle=nil,safari=false,viewport_top=nil)
    if !viewport.nil?
      view = Viewport.new(viewport.rect.x,viewport.rect.y,viewport.rect.width,viewport.rect.height)
      view.z = viewport.z
      view2 = Viewport.new(viewport.rect.x,viewport.rect.y,viewport.rect.width,viewport.rect.height)
      view2.z = viewport.z + 2
      viewport = view
    end
    @battle=battle
    @safaribattle=safari
    @viewport=viewport
    @viewport2=(viewport.nil?) ? viewport : view2
    @viewport3 = viewport_top
    @index=0
    @coolDown=0
    @over=false
   
    @buttonBitmap=pbBitmap("#{checkEBFolderPath}/commandMenuButtons")
   
    @texts=[
      [_INTL("Fight"),_INTL("Bag"),_INTL("Pokemon"),_INTL("Run")],
      [_INTL("Ball"),_INTL("Bait"),_INTL("Rock"),_INTL("Call")]
    ]
   
    @helpText=Sprite.new(@viewport)
    @helpText.bitmap=Bitmap.new(Graphics.width,36)
    @helpText.y=VIEWPORT_HEIGHT-(104)
    @helpText.x=Graphics.width+8
    @helpText.z=100
    pbSetSystemFont(@helpText.bitmap)
    
    @backdrop=Sprite.new(@viewport)
    @backdrop.bitmap=Bitmap.new(@viewport.rect.width,@viewport.rect.height)
    pbSetSystemFont(@backdrop.bitmap)
   
    @background=Sprite.new(@viewport)
    @background.bitmap=pbBitmap("#{checkEBFolderPath}/newCommandBox")
    @background.y=VIEWPORT_HEIGHT-68
    @background.z=100
   
    @bgText=Sprite.new(@viewport)
    @bgText.bitmap=Bitmap.new(512,98)
    @bgText.y=VIEWPORT_HEIGHT-68
    @bgText.z=110
    pbSetSystemFont(@bgText.bitmap)
    text=[]
   
    @selHand=Sprite.new(@viewport2)
    @selHand.bitmap=pbBitmap("#{checkEBFolderPath}/selHand")
    @selHand.oy=@selHand.bitmap.height
    @selHand.ox=@selHand.bitmap.width/2
    @selHand.z=150
    @selHand.visible=false
    @animdata=[0.1,0]
    
    @overlay=Sprite.new(@viewport2)
    @overlay.bitmap = Bitmap.new(@viewport2.rect.width,@viewport2.rect.height)
    @overlay.bitmap.blt(0,0,@backdrop.bitmap,Rect.new(0,0,@backdrop.bitmap.width,@backdrop.bitmap.height))
    bmp=pbBitmap("#{checkEBFolderPath}/shadeFull")
    @overlay.blur_sprite(3)
    @overlay.z = 200
   
    @button={}
    ds_x=[100,38,200,362]
    ds_y=[92,284,296,284]
    for i in 0...4
      @button["#{i}"]=Sprite.new(@viewport)
      @button["#{i}"].bitmap=@buttonBitmap
      row=(@safaribattle) ? 1 : 0
      row=0 if i==3
      
      @button["#{i}"].src_rect.set(i*116,row*48,116,48)
      @button["#{i}"].z=120
      @button["#{i}"].x=16+(i*122)
      @button["#{i}"].y=@background.y+12
      y=(i<1) ? 110 : 42
      x=(i<1) ? 158 : 58
      text.push(["#{@texts[row][i]}",78+(i*122),40,2,PokeBattle_SceneConstants::MESSAGEBASECOLOR,Color.new(41,71,77)])
    end
    pbDrawTextPositions(@bgText.bitmap,text)
    @bgText.x=@button["#{@index}"].x
    @bgText.src_rect.set((@index*122)+16,0,116,98)
  end
  
  def refreshCommands(index)
    poke=@battle.battlers[index]
    for i in 0...4
      @button["#{i}"].dispose if @button["#{i}"] && !@button["#{i}"].disposed?
    end
    @bgText.bitmap.clear
    text=[]
    ds_x=[100,38,200,362]
    ds_y=[92,284,296,284]
    for i in 0...4
      @button["#{i}"]=Sprite.new(@viewport)
      @button["#{i}"].bitmap=@buttonBitmap
      row=(@safaribattle) ? 1 : 0
      if i==3
        if poke.isShadow? && poke.inHyperMode?
          row=1
        else
          row=0
        end
      end
      @button["#{i}"].src_rect.set(i*116,row*48,116,48)
      @button["#{i}"].z=120
      @button["#{i}"].x=16+(i*122)
      @button["#{i}"].y=@background.y+12
      y=(i<1) ? 110 : 42
      x=(i<1) ? 158 : 58
      text.push(["#{@texts[row][i]}",78+(i*122),40,2,PokeBattle_SceneConstants::MESSAGEBASECOLOR,Color.new(41,71,77)])
    end
    pbDrawTextPositions(@bgText.bitmap,text)
  end
 
  def visible; end; def visible=(val); end
  def disposed?; end
  def dispose
    @viewport.dispose
    @viewport2.dispose
    @viewport3.dispose
    @helpText.dispose
    @backdrop.dispose
    @background.dispose
    @bgText.dispose
    @selHand.dispose
    pbDisposeSpriteHash(@button)
  end
  def color; end; def color=(val); end
   
  def showText
    return if @helpText.x <= 0
    @helpText.opacity=255
    @helpText.x-=52
  end
 
  def text=(msg)
    bitmap=pbBitmap("#{checkEBFolderPath}/newBattleMessageSmall")
    balls=pbBitmap("#{checkEBFolderPath}/newPartyBalls")
    @helpText.bitmap.clear
    @helpText.bitmap.blt(0,0,bitmap,Rect.new(0,0,bitmap.width,bitmap.height))
    x = EBUISTYLE==2 ? bitmap.width - 12 : bitmap.width/2
    a = EBUISTYLE==2 ? 1 : 2
    text=[["#{msg}",x,2,a,PokeBattle_SceneConstants::MESSAGEBASECOLOR,PokeBattle_SceneConstants::MESSAGESHADOWCOLOR]]
    pbDrawTextPositions(@helpText.bitmap,text)
    for i in 0...6
      next if @safaribattle
      o=3
      if i < @battle.party1.length && @battle.party1[i]
        if @battle.party1[i].hp <=0 || @battle.party1[i].isEgg?
          o=2
        elsif @battle.party1[i].status > 0
          o=1
        else
          o=0
        end
      end
      @helpText.bitmap.blt(404+(i*18),18,balls,Rect.new(o*18,0,18,18))
      next if !@battle.opponent
      enemyindex=i
      if @battle.doublebattle && i >=3
        enemyindex=(i%3)+@battle.pbSecondPartyBegin(1)
      end
      o=3
      if enemyindex < @battle.party2.length && @battle.party2[enemyindex]
        if @battle.party2[enemyindex].hp <=0 || @battle.party2[enemyindex].isEgg?
          o=2
        elsif @battle.party2[enemyindex].status > 0
          o=1
        else
          o=0
        end
      end
      @helpText.bitmap.blt(i*18,0,balls,Rect.new(o*18,0,18,18))
    end
  end
 
  def show
    @overlay.opacity -= 25.5
    return if @background.y <= VIEWPORT_HEIGHT-68
    @selHand.visible=false
    @background.y-=7
    @bgText.y-=7
    @helpText.y-=7 
    for i in 0...4
      @button["#{i}"].y=@background.y+12
    end
  end
 
  def hide(skip=false)
    @selHand.visible=false
    @helpText.opacity-=25.5
    @helpText.y+=7
    @helpText.x=Graphics.width+8 if @helpText.opacity <=0
    return if skip
    @background.y+=7
    @bgText.y+=7
    for i in 0...4
      @button["#{i}"].y=@background.y+12
    end
  end
  
  def hide_ds(initialize=false)
    if initialize
      bmp = pbBitmap("#{checkEBFolderPath}/DS/background")
      @overlay.bitmap.clear
      @overlay.bitmap.blt(0,0,bmp,Rect.new(0,0,bmp.width,bmp.height))
      bmp=pbBitmap("#{checkEBFolderPath}/shadeFull")
      @overlay.blur_sprite(3)
      @overlay.bitmap.blt(0,0,bmp,Rect.new(0,0,bmp.width,bmp.height))
    else
      @overlay.opacity+=25.5
    end
  end
 
  def update
    @coolDown=0
    @selHand.x=@button["#{@index}"].x+@button["#{@index}"].src_rect.width/2
    @selHand.y=@button["#{@index}"].y
    @selHand.zoom_y-=@animdata[0]
    @selHand.visible=true
    @bgText.x=@button["#{@index}"].x
    @bgText.src_rect.set((@index*122)+16,0,116,98)
    @animdata[0]=-0.1 if @selHand.zoom_y <=0.5
    if @selHand.zoom_y >=1
      @animdata[0]=0
      @animdata[1]+=1
      if @animdata[1] > 14
        @animdata[0]=0.1
        @animdata[1]=0
      end
    end
    @over=false
    for i in 0...4
      if defined?($mouse)
        if $mouse.over?(@button["#{i}"])
          @over=true
          @index = i
        end
      end
      if @index==i
        @button["#{i}"].y-=1 if @button["#{i}"].y > @background.y+2
      else
        @button["#{i}"].y+=1 if @button["#{i}"].y < @background.y+12
      end
    end
  end
  
  def mouseOver?
    return false if !defined?($mouse)
    return @over
  end
 
end
 
class PokeBattle_Scene
 
  alias pbCommandMenu_ebs pbCommandMenu unless self.method_defined?(:pbCommandMenu_ebs)
  def pbCommandMenu(index)
    @orgPos=[@vector.x,@vector.y,@vector.angle,@vector.scale,@vector.zoom1] if @orgPos.nil?
    @idleTimer=0 if @idleTimer < 0
    return pbCommandMenu_ebs(index)
  end  
    
  alias pbCommandMenuEx_ebs pbCommandMenuEx unless self.method_defined?(:pbCommandMenuEx_ebs)
  def pbCommandMenuEx(index,texts,mode=0)
    return pbCommandMenuEx_ebs(index,texts,mode) if EBUISTYLE==0
    @ret=0
    clearMessageWindow
    @vector.reset(@battle.doublebattle)
    if EBUISTYLE==2 && @battle.doublebattle
      @sprites["battlebox0"].visible = (index==0) ? true : false
      @sprites["battlebox2"].visible = (index==2) ? true : false
      @sprites["battlebox0"].positionX = (index==0) ? 0 : Graphics.width
      @sprites["battlebox2"].positionX = (index==2) ? 0 : Graphics.width
    end
    @sprites["battlebox0"].visible = true if !@battle.doublebattle
    if @battle.doublebattle && !USEBATTLEBASES && !@inCMx
      moveRight if index==0
      moveLeft if index==2
    end
    @inCMx=true
    cw=@commandWindow
    cw.refreshCommands(index)
    name=(@safaribattle) ? $Trainer.name : @battle.battlers[index].name
    cw.text=_INTL("What will {1} do?",name)
    pbSEPlay("SE_Zoom2",50)
    10.times do                                
      cw.showText
      animateBattleSprites(true)
      pbGraphicsUpdate
    end
    pbSEPlay("SE_Zoom4",50)
    10.times do                              
      cw.show
      animateBattleSprites(true)
      pbGraphicsUpdate
    end
    pbRefresh
    loop do
      pbGraphicsUpdate
      pbInputUpdate
      animateBattleSprites(true)
      cw.update
      # Update selected command
      if (defined?($mouse) && $mouse.active? && cw.mouseOver?)
      elsif Input.trigger?(Input::LEFT) && cw.coolDown <= 0
        if cw.index > 0
          pbSEPlay("SE_Select1")
          cw.index-=1
        elsif cw.index <=0
          pbSEPlay("SE_Select1")
          cw.index=3
        end
        cw.triggerLeft if EBUISTYLE==2
        cw.coolDown=1
      elsif Input.trigger?(Input::RIGHT) && cw.coolDown <= 0
        if cw.index < 3
          pbSEPlay("SE_Select1")
          cw.index+=1
        elsif cw.index >=3
          pbSEPlay("SE_Select1")
          cw.index=0
        end
        cw.triggerRight if EBUISTYLE==2
        cw.coolDown=1
      end
      if Input.press?(Input::CTRL) && Input.trigger?(Input::B) && $DEBUG
        self.moveAnimationsSelector if PokeBattle_Scene.method_defined?(:moveAnimationsSelector)
      end
      if Input.trigger?(Input::C) || (defined?($mouse) && cw.mouseOver? && $mouse.leftClick?)  # Confirm choice
        pbSEPlay("SE_Select2")
        @ret=cw.index
        @inCMx=false if @battle.doublebattle && !USEBATTLEBASES && @ret > 0
        @lastcmd[index]=@ret
        break
      elsif (Input.trigger?(Input::B) || (defined?($mouse) && $mouse.rightClick?)) && index==2 && @lastcmd[0]!=2 # Cancel
        pbSEPlay("SE_Select2")
        if @battle.doublebattle && !USEBATTLEBASES
          moveRight if index==2
          moveLeft if index==0
          @inCMx=false
        end
        @ret=-1
        break
      end
    end
    10.times do                              
      cw.hide(false)
      animateBattleSprites(true)
      pbGraphicsUpdate
    end
    if @ret > 0
      vector = @battle.doublebattle ? VECTOR2 : VECTOR1
      @vector.set(vector)
      @vector.inc=0.2
      if EBUISTYLE==2 && @battle.doublebattle
        @sprites["battlebox0"].positionX = 0
        @sprites["battlebox0"].visible = false
        @sprites["battlebox2"].positionX = Graphics.width
        @sprites["battlebox2"].visible = false
      end
    end
    return @ret
  end
  
  def movePlayerBoxes(amt=6)
    @commandWindow.hide_ds(true) if amt < 0
    10.times do
      @sprites["battlebox0"].y += amt if @sprites["battlebox0"]
      @sprites["battlebox2"].y += amt if @sprites["battlebox2"]
      @commandWindow.hide_ds(false) if amt < 0
      animateBattleSprites(true)
      pbGraphicsUpdate
    end
    if amt < 0
      10.times do; @commandWindow.hide(false); end
      @commandWindow.backdrop.visible = false
    end
  end
end
#===============================================================================
#  Fight Menu
#  UI ovarhaul
#===============================================================================
KleinFightWindow = NewFightWindow.clone if defined?(NewFightWindow)=='constant'
class NewFightWindow
  attr_accessor :index
  attr_accessor :battler
  attr_accessor :refreshpos
  attr_reader :nummoves
 
  def initialize(viewport=nil)
    if !viewport.nil?
      view = Viewport.new(viewport.rect.x,viewport.rect.y,viewport.rect.width,viewport.rect.height)
      view.z = viewport.z
      view2 = Viewport.new(viewport.rect.x,viewport.rect.y,viewport.rect.width,viewport.rect.height)
      view2.z = viewport.z + 2
      viewport = view
    end
    @viewport=viewport
    @viewport2=(viewport.nil?) ? viewport : view2
    @index=0
    @over=false
    @refreshpos=false
    @battler=nil
    @nummoves=0
   
    if EBUISTYLE==2
      @buttonBitmap=pbBitmap("#{checkEBFolderPath}/nextGen/moveSelButtons")
    else
      @buttonBitmap=pbBitmap("#{checkEBFolderPath}/moveSelButtons")
    end
    @categoryBitmap=pbBitmap("Graphics/Pictures/category")
    
    @backdrop=Sprite.new(@viewport)
    @backdrop.bitmap=Bitmap.new(@viewport.rect.width,@viewport.rect.height)
    @backdrop.opacity=0
    @backdrop.tone=Tone.new(64,64,64)
   
    @background=Sprite.new(@viewport)
    if EBUISTYLE==2
      @background.bitmap=pbBitmap("#{checkEBFolderPath}/nextGen/newBattleMessageBox")
    else
      @background.bitmap=pbBitmap("#{checkEBFolderPath}/newCommandBox")
    end
    @background.y=VIEWPORT_HEIGHT-98+(EBUISTYLE==2 ? 2 : 0)
    @background.z=100
   
   
    @selHand=Sprite.new(@viewport2)
    @selHand.bitmap=pbBitmap("#{checkEBFolderPath}/selHand")
    @selHand.oy=@selHand.bitmap.height
    @selHand.ox=@selHand.bitmap.width/2
    @selHand.z=150
    @selHand.visible=false
    @animdata=[0.1,0]
   
    @arrow1=Sprite.new(@viewport)
    @arrow1.bitmap=pbBitmap("#{checkEBFolderPath}/dirArrow")
    @arrow1.y=@background.y+2
    @arrow1.z=140
    @arrow1.mirror=true
    @arrow1.opacity=0
   
    @arrow2=Sprite.new(@viewport)
    @arrow2.bitmap=pbBitmap("#{checkEBFolderPath}/dirArrow")
    @arrow2.y=@background.y+2
    @arrow2.z=140
    @arrow2.x=Graphics.width-20
    @arrow2.opacity=0
   
    @megaButton=Sprite.new(@viewport)
    path = (EBUISTYLE==2) ? "nextGen/" : ""
    @megaButton.bitmap=pbBitmap("#{checkEBFolderPath}/#{path}megaEvoButton")
    @megaButton.y=252
    @megaButton.x=-16
    @megaButton.z=145
    @megaButton.src_rect.set(0,0,116,48)
   
    @button={}
    @moved=false
    @showMega=false
    @position=[]
    @alternate=[0,0]
   
  end
 
  def generateButtons
    @moves=@battler.moves
    @nummoves=0
    @position.clear
    for i in 0...4
      @button["#{i}"].dispose if @button["#{i}"]
      @button["#{i}_2"].dispose if @button["#{i}_2"]
      @nummoves+=1 if @moves[i] && @moves[i].id > 0
    end
    @button={}
    for i in 0...@moves.length
      @position.push(30+(i*220)-(@index*220))
    end
    if @index==3
      for j in 0...@position.length
        @position[j]+=220
      end
    end
    pos_y=[80,80,212,212]
    for i in 0...@nummoves 
      movedata=PBMoveData.new(@moves[i].id)
      @button["#{i}"]=Sprite.new(@viewport)
      @button["#{i}"].bitmap=Bitmap.new(214,88)
      pbSetSystemFont(@button["#{i}"].bitmap)
      @button["#{i}"].z=120
      @button["#{i}"].x=@position[i]
      @button["#{i}"].y=@background.y+10
      baseColor=@buttonBitmap.get_pixel(4,32+(@moves[i].type*88))
      shadowColor=@buttonBitmap.get_pixel(20,4+(@moves[i].type*88))
      @button["#{i}"].bitmap.blt(0,0,@buttonBitmap,Rect.new(0,@moves[i].type*88,214,88))
      text=[
        ["#{@moves[i].name}",103,10,2,baseColor,shadowColor],
        ["PP: #{@moves[i].pp}/#{@moves[i].totalpp}",103-18,38,2,baseColor,shadowColor]
      ]
      pbDrawTextPositions(@button["#{i}"].bitmap,text)
      
      @button["#{i}_2"]=Sprite.new(@viewport)
      @button["#{i}_2"].bitmap=Bitmap.new(214,88)
      @button["#{i}_2"].z=120
      @button["#{i}_2"].x=@position[i]
      @button["#{i}_2"].y=@background.y+10
      @button["#{i}_2"].visible=false
      @button["#{i}_2"].visible=true if @index==i
      @button["#{i}_2"].bitmap.blt(148,58,@categoryBitmap,Rect.new(0,movedata.category*28,64,28))
    end
  end
   
  def formatBackdrop
    @backdrop.bitmap.clear
    bmp = Graphics.snap_to_bitmap
    @backdrop.bitmap.blt(0,0,bmp,Rect.new(0,VIEWPORT_HEIGHT+VIEWPORT_OFFSET,bmp.width,bmp.height))
    bmp=pbBitmap("#{checkEBFolderPath}/shadeFull")
    @backdrop.blur_sprite(3)
    @backdrop.bitmap.blt(0,0,bmp,Rect.new(0,0,bmp.width,bmp.height))
  end
  
  def show
    @backdrop.opacity+=25.5
    @selHand.visible=false
    @background.y-=10
    @arrow1.y-=10
    @arrow2.y-=10
    for i in 0...5
      next if !@button["#{i}"]
      @button["#{i}"].y=@background.y+10 if @button["#{i}"] && !@button["#{i}"].disposed?
      @button["#{i}_2"].y=@background.y+10 if @button["#{i}_2"] && !@button["#{i}_2"].disposed?
    end
  end
 
  def hide
    @backdrop.opacity-=25.5
    @selHand.visible=false
    @background.y+=10
    @megaButton.x-=10
    @arrow1.y+=10
    @arrow2.y+=10
    @showMega=false
    for i in 0...5
      next if !@button["#{i}"]
      @button["#{i}"].y=@background.y+10 if @button["#{i}"] && !@button["#{i}"].disposed?
      @button["#{i}_2"].y=@background.y+10 if @button["#{i}_2"] && !@button["#{i}_2"].disposed?
    end
  end
 
  def megaButton
    @showMega=true
  end
 
  def megaButtonTrigger
    @megaButton.src_rect.y+=48
    @megaButton.src_rect.y=0 if @megaButton.src_rect.y >=96
  end
 
  def update
    if @index==0 or @index==1
      @arrow2.opacity+=25.5 if @arrow2.opacity < 255
    elsif @index==2 or @index==3
      @arrow2.opacity-=25.5 if @arrow2.opacity > 0
    end
    if @index==1 or @index==2 or @index==3
      @arrow1.opacity+=25.5 if @arrow1.opacity < 255
    elsif @index==0
      @arrow1.opacity-=25.5 if @arrow1.opacity > 0
    end
    for i in 0...@position.length
      @position[i]=30+(i*220)-(@index*220) if @index < 3 or @refreshpos
    end
    @refreshpos=false
    for i in 0...@nummoves
      @button["#{i}_2"].visible=false
      @button["#{i}_2"].visible=true if @index==i
      if @index==i
        @button["#{i}"].y-=1 if @button["#{i}"].y > @background.y+2
      else
        @button["#{i}"].y+=1 if @button["#{i}"].y < @background.y+10
      end
      distance=@button["#{i}"].x-@position[i]
      @button["#{i}"].x-=distance/10  
      @button["#{i}_2"].x=@button["#{i}"].x
      @button["#{i}_2"].y=@button["#{i}"].y
    end
    if @showMega
      @megaButton.x+=10 if @megaButton.x < -16
    end
    @selHand.x=@button["#{@index}"].x+@button["#{@index}"].src_rect.width/2
    @selHand.y=@button["#{@index}"].y
    @selHand.zoom_y-=@animdata[0]
    @selHand.visible=true
    @animdata[0]=-0.1 if @selHand.zoom_y <=0.5
    if @selHand.zoom_y >=1
      @animdata[0]=0
      @animdata[1]+=1
      if @animdata[1] > 14
        @animdata[0]=0.1
        @animdata[1]=0
      end
    end
    if defined?($mouse)
      @over = false
      for i in 0...5
        next if !@button["#{i}"]
        if $mouse.over?(@button["#{i}"])
          @over = true
          @index = i
        end
      end
    end
          
  end
  
  def dispose
    @viewport.dispose
    @viewport2.dispose
    @selHand.dispose
    @backdrop.dispose
    @background.dispose
    @arrow1.dispose
    @arrow2.dispose
    @megaButton.dispose
    pbDisposeSpriteHash(@button)
  end
  
  def overMega?
    return false if !defined?($mouse)
    return $mouse.over?(@megaButton)
  end
  
  def mouseOver?
    return false if !defined?($mouse)
    return @over
  end
  
  def goBack?
    return false
  end
end
 
class PokeBattle_Scene
 
  alias pbFightMenu_ebs pbFightMenu unless self.method_defined?(:pbFightMenu_ebs)
  def pbFightMenu(index)
    return pbFightMenu_ebs(index) if EBUISTYLE==0
    clearMessageWindow
    if EBUISTYLE==2
      @sprites["battlebox0"].visible = false if @sprites["battlebox0"]
      @sprites["battlebox2"].visible = false if @sprites["battlebox2"]
    end
    cw = @fightWindow
    mega = false
    battler=@battle.battlers[index]
    cw.megaButton if @battle.pbCanMegaEvolve?(index)
    cw.battler=battler
    lastIndex=@lastmove[index]
    if battler.moves[lastIndex].id!=0
      cw.index=lastIndex
    else
      cw.index=0
    end
    cw.generateButtons
    pbSelectBattler(index)
    pbSEPlay("SE_Zoom4",50)
    moveUpperRight(cw)
    pbRefresh
    loop do
      pbGraphicsUpdate
      pbInputUpdate
      animateBattleSprites(true)
      cw.update
      # Update selected command
      if (defined?($mouse) && $mouse.active? && cw.mouseOver?)
      elsif (Input.trigger?(Input::LEFT) || Input.trigger?(Input::RIGHT)) && (EBUISTYLE==2)
        pbSEPlay("SE_Select1")
        cw.index=[0,1,2,3][[1,0,3,2].index(cw.index)]
        cw.index=(cw.nummoves-1) if cw.index < 0
        cw.index=0 if cw.index > (cw.nummoves-1)
      elsif (Input.trigger?(Input::UP) || Input.trigger?(Input::DOWN)) && (EBUISTYLE==2)
        pbSEPlay("SE_Select1")
        cw.index=[0,1,2,3][[2,3,0,1].index(cw.index)]
        cw.index=0 if cw.index < 0
        cw.index=(cw.nummoves-1) if cw.index > (cw.nummoves-1)
      elsif Input.trigger?(Input::LEFT) && cw.index < 4
        if cw.index > 0
          pbSEPlay("SE_Select1")
          cw.index-=1
        else
          pbSEPlay("SE_Select1")
          cw.index=cw.nummoves-1
          cw.refreshpos=true
        end
      elsif Input.trigger?(Input::RIGHT) && cw.index < 4
        if cw.index < (cw.nummoves-1)
          pbSEPlay("SE_Select1")
          cw.index+=1
        else
          pbSEPlay("SE_Select1")
          cw.index=0
        end
      end
      if Input.trigger?(Input::C) || (defined?($mouse) && cw.mouseOver? && $mouse.leftClick?)  # Confirm choice
        if cw.index < 4
          @ret=cw.index
          @battle.pbRegisterMegaEvolution(index) if mega
          pbSEPlay("SE_Select2")
          @lastmove[index]=@ret
          @idleTimer=-1
          @inCMx=false
          break
        else
          @lastmove[index]=cw.index
          pbPlayCancelSE()
          @ret=-1
          break
        end
      elsif Input.trigger?(Input::A) || (defined?($mouse) && cw.overMega? && $mouse.leftClick?) # Use Mega Evolution
        if @battle.pbCanMegaEvolve?(index)
          if mega
            mega = false
          else
            mega = true
          end
          cw.megaButtonTrigger
          pbSEPlay("SE_Select3")
        end
      elsif Input.trigger?(Input::B) || (defined?($mouse) && (cw.goBack? || $mouse.rightClick?))  # Cancel fight menu
        @lastmove[index]=cw.index
        pbPlayCancelSE()
        @ret=-1
        break
      end
    end
    if @ret > -1
      vector = @battle.doublebattle ? VECTOR2 : VECTOR1
      @vector.set(vector)
      @orgPos=nil
      @vector.inc=0.2
      @vector.lock
      10.times do
        cw.hide
        wait(1,true)
      end
    else
      moveLowerLeft(cw)
    end
    if EBUISTYLE==2 && !@battle.doublebattle
      @sprites["battlebox0"].visible = true if @sprites["battlebox0"]
      @sprites["battlebox2"].visible = true if @sprites["battlebox2"]
    end
    @sprites["battlebox#{index}"].visible = true if EBUISTYLE==2 && @doublebattle
    if EBUISTYLE==2 && @battle.doublebattle
      @sprites["battlebox0"].positionX = 0
      @sprites["battlebox2"].positionX = Graphics.width
    end
    return @ret
  end
 
  alias pbChooseTarget_ebs pbChooseTarget unless self.method_defined?(:pbChooseTarget_ebs)
  def pbChooseTarget(*args)
    if EBUISTYLE==0
      return pbChooseTarget_ebs(*args)
    end
    index, targettype = args
    curwindow=pbFirstTarget(*args)
    if curwindow==-1
      raise RuntimeError.new(_INTL("No targets somehow..."))
    end
    loop do
      pbGraphicsUpdate
      pbInputUpdate
      pbUpdateSelected(curwindow)
      if Input.trigger?(Input::C)
        pbUpdateSelected(-1)
        @ret=curwindow
        break
      end
      if Input.trigger?(Input::B)
        pbUpdateSelected(-1)
        @ret=-1
        break
      end
      if Input.trigger?(Input::RIGHT) && !(curwindow==3 or curwindow==2)
        pbPlayCursorSE()
        newcurwindow=3 if curwindow==1 
        newcurwindow=2 if curwindow==0
        curwindow=newcurwindow if ((newcurwindow!=index) || (targettype==PBTargets::UserOrPartner)) && !@battle.battlers[newcurwindow].isFainted?
      elsif Input.trigger?(Input::DOWN) && !(curwindow==0 or curwindow==2) 
        pbPlayCursorSE()
        newcurwindow=0 if curwindow==1
        newcurwindow=2 if curwindow==3
        curwindow=newcurwindow if ((newcurwindow!=index) || (targettype==PBTargets::UserOrPartner)) && !@battle.battlers[newcurwindow].isFainted?
      elsif Input.trigger?(Input::LEFT) && !(curwindow==1 or curwindow==0)
        pbPlayCursorSE()
        newcurwindow=1 if curwindow==3
        newcurwindow=0 if curwindow==2
        curwindow=newcurwindow if ((newcurwindow!=index) || (targettype==PBTargets::UserOrPartner)) && !@battle.battlers[newcurwindow].isFainted?
      elsif Input.trigger?(Input::UP) && !(curwindow==3 or curwindow==1)
        pbPlayCursorSE()
        newcurwindow=3 if curwindow==2
        newcurwindow=1 if curwindow==0
        curwindow=newcurwindow if ((newcurwindow!=index) || (targettype==PBTargets::UserOrPartner)) && !@battle.battlers[newcurwindow].isFainted?
      end
      #
      @sprites["shades"].opacity+=15 if @sprites["shades"].opacity < 150
      for i in 0...4
        if @sprites["pokemon#{i}"]
          if index==i or curwindow==i
            increaseTone(@sprites["pokemon#{i}"],-10) if @sprites["pokemon#{i}"].tone.red > 0
          else
            increaseTone(@sprites["pokemon#{i}"],10) if @sprites["pokemon#{i}"].tone.red < 80
          end
        end
      end
      #
    end
    10.times do
     @sprites["shades"].opacity-=15 if @sprites["shades"].opacity > 0
      for i in 0...4
        increaseTone(@sprites["pokemon#{i}"],-10) if @sprites["pokemon#{i}"] && @sprites["pokemon#{i}"].tone.red > 0
      end
      animateBattleSprites(true)
      pbGraphicsUpdate
    end
    if EBUISTYLE==2 && @battle.doublebattle
      @sprites["battlebox0"].positionX = 0
      @sprites["battlebox2"].positionX = Graphics.width
    end
    return @ret
  end
 
end

def increaseTone(sprite,amount)
  sprite.tone.red+=amount
  sprite.tone.green+=amount
  sprite.tone.blue+=amount
end
#===============================================================================
#  Command Choices
#  UI ovarhaul
#===============================================================================
class NewChoiceSel
  attr_accessor :index
  attr_reader :over
  
  def initialize(viewport,commands)
    @commands=commands
    @index=0
    @over=false
    offset = 0
    @viewport=Viewport.new(0,offset,Graphics.width,VIEWPORT_HEIGHT)
    @viewport.z=viewport.z+5
    @sprites={}
    @sprites["back"]=Sprite.new(@viewport)
    @sprites["back"].bitmap=pbBitmap(EBUISTYLE==2 ? "#{checkEBFolderPath}/nextGen/shadeRest" : "#{checkEBFolderPath}/shadeRest")
    @sprites["back"].opacity=0
    bitmap=pbBitmap("#{checkEBFolderPath}/choiceSel")
    baseColor=PokeBattle_SceneConstants::MESSAGEBASECOLOR
    shadowColor=PokeBattle_SceneConstants::MESSAGESHADOWCOLOR
    @sprites["sel"]=Sprite.new(@viewport)
    @sprites["sel"].bitmap=bitmap
    @sprites["sel"].src_rect.set(160,0,160,62)
    @sprites["sel"].y=220
    @sprites["sel"].x=-150
    for i in 0...@commands.length
      @sprites["choice#{i}"]=Sprite.new(@viewport)
      @sprites["choice#{i}"].x=80+(i*192)
      @sprites["choice#{i}"].y=VIEWPORT_HEIGHT
      @sprites["choice#{i}"].bitmap=Bitmap.new(160,62)
      choice=@sprites["choice#{i}"].bitmap
      pbSetSystemFont(choice)
      choice.blt(0,0,bitmap,Rect.new(0,0,160,62))
      pbDrawOutlineText(choice,0,0,160,62,@commands[i],baseColor,shadowColor,1)
    end
  end
  
  def dispose(scene)
    5.times do
      @sprites["back"].opacity-=51
      @sprites["sel"].opacity-=51
      for i in 0...@commands.length
        @sprites["choice#{i}"].opacity-=51
      end
      @sprites["choice#{@index}"].y+=2
      scene.animateBattleSprites(true)
      scene.pbGraphicsUpdate
    end
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
  
  def update
    @sprites["sel"].x=@sprites["choice#{@index}"].x
    @sprites["back"].opacity+=25.5 if @sprites["back"].opacity < 255
    if (defined?($mouse) && $mouse.active? && @over)
    elsif Input.trigger?(Input::LEFT)
      pbSEPlay("SE_Select1")
      @index-=1
      @index=@commands.length-1 if @index < 0
      @sprites["choice#{@index}"].src_rect.y+=6
    elsif Input.trigger?(Input::RIGHT)
      pbSEPlay("SE_Select1")
      @index+=1
      @index=0  if @index >=@commands.length
      @sprites["choice#{@index}"].src_rect.y+=6
    end
    @over=false
    if defined?($mouse)
      for i in 0...2
        if $mouse.over?(@sprites["choice#{i}"])
          @index = i
          @over=true
        end
      end
    end
    for i in 0...@commands.length
      @sprites["choice#{i}"].src_rect.y-=1 if @sprites["choice#{i}"].src_rect.y > 0
      @sprites["choice#{i}"].y-=(@sprites["choice#{i}"].y-220)*0.4
    end
  end
  
end
#===============================================================================
#  Battle Bag interface
#  UI ovarhaul
#===============================================================================
def pbIsMedicine?(item)
  return $ItemData[item] && !($ItemData[item][ITEMTYPE]==5) &&($ItemData[item][ITEMBATTLEUSE]==1)
end

def pbIsBattleItem?(item)
  return $ItemData[item] && !($ItemData[item][ITEMTYPE]==3 || $ItemData[item][ITEMTYPE]==4) && ($ItemData[item][ITEMBATTLEUSE]==2)
end

class NewBattleBag
  attr_reader :index
  attr_reader :ret
  attr_reader :finished
  
  def pbDisplayMessage(msg)
    @scene.changeMessageViewport(@viewport)
    @scene.pbDisplayMessage(msg)
    @scene.clearMessageWindow
    @scene.changeMessageViewport
  end
    
  def initialize(scene,viewport)
    @scene=scene
    $lastUsed=0 if $lastUsed.nil?
    offset=0
    @background=Viewport.new(0,offset,Graphics.width,VIEWPORT_HEIGHT)
    @background.z=viewport.z+5
    @viewport=Viewport.new(0,offset,Graphics.width,VIEWPORT_HEIGHT)
    @viewport.z=viewport.z+5
    @lastUsed=$lastUsed
    @index=0
    @item=0
    @finished=false
    @disposed=true
    @page=-1
    @selPocket=0
    @ret=nil
    @over=false
    @baseColor=PokeBattle_SceneConstants::MESSAGEBASECOLOR
    @shadowColor=PokeBattle_SceneConstants::MESSAGESHADOWCOLOR
    
    @sprites={}
    @items={}
    path = (EBUISTYLE==2) ? "nextGen/" : ""
    @bitmaps=[pbBitmap("#{checkEBFolderPath}/battleBagChoices"),pbBitmap("#{checkEBFolderPath}/battleBagLast"),pbBitmap("#{checkEBFolderPath}/#{path}battleBackButtons")]
    @sprites["back"]=Sprite.new(@background)
    @sprites["back"].bitmap=pbBitmap("#{checkEBFolderPath}/shadeFull")
    @sprites["back"].opacity=0
    @sprites["sel"]=Sprite.new(@viewport)
    @sprites["sel"].x=-216
    @sprites["sel"].y=34
    @sprites["name"]=Sprite.new(@viewport)
    @sprites["name"].bitmap=Bitmap.new(380,44)
    pbSetSystemFont(@sprites["name"].bitmap)
    @sprites["name"].x=-380
    @sprites["name"].y=328
    for i in 0...4
      @sprites["pocket#{i}"]=Sprite.new(@viewport)
      @sprites["pocket#{i}"].bitmap=@bitmaps[0]
      @sprites["pocket#{i}"].src_rect.set(216*i,0,216,92)
      @sprites["pocket#{i}"].x=24+(i%2)*244+((i%2==0) ? -260 : 260)
      @sprites["pocket#{i}"].y=34+(i/2)*118+(i%2)*42
    end
    @sprites["pocket4"]=Sprite.new(@viewport)
    @sprites["pocket4"].bitmap=Bitmap.new(356,60)
    pbSetSystemFont(@sprites["pocket4"].bitmap)
    @sprites["pocket4"].x=24
    @sprites["pocket4"].y=316+80
    self.refresh
    @sprites["pocket5"]=Sprite.new(@viewport)
    @sprites["pocket5"].bitmap=@bitmaps[2]
    @sprites["pocket5"].src_rect.set(0,0,120,52)
    @sprites["pocket5"].x=384
    @sprites["pocket5"].y=320+80
    @sprites["pocket5"].z=5
    
    @sprites["confirm"]=Sprite.new(@viewport)
    @sprites["confirm"].bitmap=Bitmap.new(466,156)
    pbSetSmallFont(@sprites["confirm"].bitmap)
    @sprites["confirm"].x=26-520
    @sprites["confirm"].y=80
    @sprites["cancel"]=Sprite.new(@viewport)
    @sprites["cancel"].bitmap=pbBitmap("#{checkEBFolderPath}/battleItemConfirm")
    @sprites["cancel"].src_rect.set(466,0,466,72)
    @sprites["cancel"].x=26-520
    @sprites["cancel"].y=234
  end
  
  def dispose
    keys = ["back","sel","name","confirm","cancel"]
    for i in 0..5
      keys.push("pocket#{i}")
    end
    for key in keys
      @sprites[key].dispose
    end
    pbDisposeSpriteHash(@items)
    @disposed = true
  end
  
  def disposed?; return @disposed; end
  
  def checkPockets
    @mergedPockets = []
    for i in 0...$PokemonBag.pockets.length
      @mergedPockets+=$PokemonBag.pockets[i]
    end
  end
  
  def drawPocket(pocket,index)
    @pocket=[]
    @pgtrigger=false
    self.checkPockets
    for item in @mergedPockets
      next if item.nil?
      next if !(ItemHandlers.hasUseInBattle(item[0]) || ItemHandlers.hasBattleUseOnPokemon(item[0]) || ItemHandlers.hasBattleUseOnBattler(item[0]))
      case index
      when 0 # Medicine
        @pocket.push([item[0],item[1]]) if pbIsMedicine?(item[0])
      when 1 # Pokeballs
        @pocket.push([item[0],item[1]]) if pbIsPokeBall?(item[0])
      when 2 # Berries
        @pocket.push([item[0],item[1]]) if pbIsBerry?(item[0])
      when 3 # Battle Items
        @pocket.push([item[0],item[1]]) if pbIsBattleItem?(item[0])
      end        
    end
    if @pocket.length < 1
      pbDisplayMessage(_INTL("You have no usable items in this pocket."))
      return
    end
    @xpos=[]
    @pages=@pocket.length/6
    @pages+=1 if @pocket.length%6 > 0
    @page=0
    @item=0
    @back=false
    @selPocket=pocket
    pbDisposeSpriteHash(@items)
    @pname=pbPocketNames[pocket]
    x=0
    y=0
    for j in 0...@pocket.length
      i=j
      @items["#{j}"]=Sprite.new(@viewport)
      @items["#{j}"].bitmap=Bitmap.new(216,92)
      pbSetSystemFont(@items["#{j}"].bitmap)
      @items["#{j}"].bitmap.blt(0,0,@bitmaps[0],Rect.new(216*5,0,216,92))
      @items["#{j}"].bitmap.blt(156,32,pbBitmap(sprintf("Graphics/Icons/item%03d",@pocket[i][0])),Rect.new(0,0,48,48))
      pbDrawOutlineText(@items["#{j}"].bitmap,8,8,200,38,"#{PBItems.getName(@pocket[i][0])}",@baseColor,@shadowColor,1)
      pbDrawOutlineText(@items["#{j}"].bitmap,8,46,200,38,"x#{@pocket[i][1]}",@baseColor,@shadowColor,1)
      
      @items["#{j}"].x=28+x*246+(i/6)*512+512
      @xpos.push(@items["#{j}"].x-512)
      @items["#{j}"].y=28+y*90
      @items["#{j}"].opacity=255
      x+=1
      y+=1 if x > 1
      x=0 if x > 1
      y=0 if y > 2
    end
  end
  
  def name
    bitmap=@sprites["name"].bitmap
    bitmap.clear
    bitmap.blt(0,0,pbBitmap("#{checkEBFolderPath}/battleLastItem"),Rect.new(0,0,320,44))
    pbDrawOutlineText(bitmap,0,0,320,36,@pname,@baseColor,@shadowColor,1)
    pbDrawOutlineText(bitmap,300,0,80,36,"#{@page+1}/#{@pages}",@baseColor,@shadowColor,1)
    @sprites["name"].x+=38 if @sprites["name"].x < 0
  end
  
  def updatePocket
    @page=@item/6
    self.name
    for i in 0...@pocket.length
      @items["#{i}"].x-=(@items["#{i}"].x-(@xpos[i]-@page*512))*0.2
      @items["#{i}"].src_rect.y-=1 if @items["#{i}"].src_rect.y > 0
    end
    if @back
      @sprites["sel"].bitmap=@bitmaps[2]
      @sprites["sel"].src_rect.set(120*2,0,120,52)
      @sprites["sel"].x=@sprites["pocket5"].x
      @sprites["sel"].y=@sprites["pocket5"].y
    else
      @sprites["sel"].bitmap=@bitmaps[0]
      @sprites["sel"].src_rect.set(216*4,0,216,92)
      @sprites["sel"].x=@items["#{@item}"].x
      @sprites["sel"].y=@items["#{@item}"].y
    end
    @sprites["pocket5"].src_rect.y-=1 if @sprites["pocket5"].src_rect.y > 0
    if (defined?($mouse) && $mouse.active? && @over)
    elsif Input.trigger?(Input::LEFT) && !@back
      pbSEPlay("SE_Select1")
      if ![0,2,4].include?(@item)
        if @item%2==0
          @item-=5
        else
          @item-=1
        end
      else
        @item-=1 if @item < 0
      end
      @item=0 if @item < 0
      @items["#{@item}"].src_rect.y+=6
    elsif Input.trigger?(Input::RIGHT) && !@back
      pbSEPlay("SE_Select1")
      if @page < (@pocket.length)/6
        if @item%2==1
          @item+=5
        else
          @item+=1
        end
      else
        @item+=1 if @item < @pocket.length-1 
      end
      @item=@pocket.length-1 if @item > @pocket.length-1
      @items["#{@item}"].src_rect.y+=6
    elsif Input.trigger?(Input::UP)
      pbSEPlay("SE_Select1")
      if @back
        @item+=4 if (@item%6) < 2
        @back=false
      else
        @item-=2
        if (@item%6) > 3
          @item+=6
          @back=true
        end
      end
      @item=0 if @item < 0
      @item=@pocket.length-1 if @item > @pocket.length-1
      @items["#{@item}"].src_rect.y+=6 if !@back
      @sprites["pocket5"].src_rect.y+=6 if @back
    elsif Input.trigger?(Input::DOWN)
      pbSEPlay("SE_Select1")
      if @back
        @item-=4 if (@item%6) > 3
        @back=false
      else
        @item+=2
        if (@item%6) < 2
          @item-=6
          @back=true
        end
        @back=true if @item > @pocket.length-1
      end
      @item=@pocket.length-1 if @item > @pocket.length-1
      @item=0 if @item < 0
      @items["#{@item}"].src_rect.y+=6 if !@back
      @sprites["pocket5"].src_rect.y+=6 if @back
    end
    @over=false
    if defined?($mouse)
      for i in 0...@pocket.length
        if $mouse.over?(@items["#{i}"])
          @item = i
          @back=false
          @over=true
        end
      end
      if $mouse.inArea?(Graphics.width-32,@viewport.rect.y,32,@viewport.rect.height) && @page < (@pocket.length)/6
        if !@pgtrigger
          @item+=5 if !(@item+5 > @pocket.length-1)
          @item=@pocket.length-1 if @item > @pocket.length-1
        end
        @pgtrigger=true
      elsif $mouse.inArea?(0,@viewport.rect.y,32,@viewport.rect.height) && @page > 0
        if !@pgtrigger
          @item-=5 if !(@item-5 < 0)
          @item=0 if @item < 0
        end
        @pgtrigger=true
      end
      @pgtrigger=false if !$mouse.inArea?(Graphics.width-32,@viewport.rect.y,32,@viewport.rect.height) && !$mouse.inArea?(0,@viewport.rect.y,32,@viewport.rect.height)
      if $mouse.over?(@sprites["pocket5"])
        @back=true
        @over=true
      end
    end
    if (@back && (Input.trigger?(Input::C) || (defined?($mouse) && @over && $mouse.leftClick?))) || Input.trigger?(Input::B)
      pbSEPlay("SE_Select3")
      @selPocket=0
      @page=-1
      @back=false
      @doubleback=true
    end
  end
  
  def closeCurrent
    @selPocket=0
    @page=-1
    @back=false
    @ret=nil
    self.refresh
  end
  
  def show
    @ret=nil
    self.refresh
    for i in 0...6
      @sprites["pocket#{i}"].opacity=255
    end
    @sprites["pocket4"].y=316+80
    @sprites["pocket5"].y=320+80
    pbSEPlay("SE_Zoom4",60)
    10.times do
      for i in 0...4
        @sprites["pocket#{i}"].x+=((i%2==0) ? 26 : -26)
      end
      for i in 4...6
        @sprites["pocket#{i}"].y-=8
      end
      @sprites["back"].opacity+=25.5
      @scene.animateBattleSprites(true)
      @scene.pbGraphicsUpdate
    end
  end
  
  def hide
    @sprites["sel"].x=Graphics.width
    10.times do
      for i in 0...4
        @sprites["pocket#{i}"].x-=((i%2==0) ? 26 : -26)
      end
      for i in 4...6
        @sprites["pocket#{i}"].y+=8
      end
      if @pocket
        for i in 0...@pocket.length
          @items["#{i}"].opacity-=25.5
        end
      end
      @sprites["name"].x-=38 if @sprites["name"].x > -380
      @sprites["back"].opacity-=25.5
      @scene.animateBattleSprites(true)
      @scene.pbGraphicsUpdate
    end
  end
  
  def useItem?
    Input.update
    bitmap=@sprites["confirm"].bitmap
    bitmap.clear
    bitmap.blt(0,0,pbBitmap("#{checkEBFolderPath}/battleItemConfirm"),Rect.new(0,0,466,156))
    bitmap.blt(20,30,pbBitmap(sprintf("Graphics/Icons/item%03d",@ret)),Rect.new(0,0,48,48))
    drawTextEx(bitmap,80,12,364,3,pbGetMessage(MessageTypes::ItemDescriptions,@ret),@shadowColor,Color.new(200,200,200))
    @sprites["sel"].bitmap=pbBitmap("#{checkEBFolderPath}/battleItemConfirm")
    @sprites["sel"].x=Graphics.width
    @sprites["sel"].src_rect.width=466
    10.times do
      @sprites["confirm"].x+=52
      @sprites["cancel"].x+=52
      if @pocket
        for i in 0...@pocket.length
          @items["#{i}"].opacity-=25.5
        end
      end
      for i in 0...4
        @sprites["pocket#{i}"].opacity-=51 if @sprites["pocket#{i}"].opacity > 0
      end
      @sprites["pocket4"].y+=8 if @sprites["pocket4"].y < 316+80
      @sprites["pocket5"].y+=8 if @sprites["pocket5"].y < 400
      @sprites["name"].x-=38
      @scene.animateBattleSprites
      @scene.pbGraphicsUpdate
    end
    @sprites["name"].x=-380
    index=0
    choice=(index==0) ? "confirm" : "cancel"
    loop do
      @sprites["sel"].x=@sprites["#{choice}"].x
      @sprites["sel"].y=@sprites["#{choice}"].y
      @sprites["sel"].src_rect.x=(466*(index+2))
      @sprites["#{choice}"].src_rect.y-=1 if @sprites["#{choice}"].src_rect.y > 0
      if (defined?($mouse) && $mouse.active? && @over)
      elsif Input.trigger?(Input::UP)
        pbSEPlay("SE_Select1")
        index-=1
        index=1 if index < 0
        choice=(index==0) ? "confirm" : "cancel"
        @sprites["#{choice}"].src_rect.y+=6
      elsif Input.trigger?(Input::DOWN)
        pbSEPlay("SE_Select1")
        index+=1
        index=0 if index > 1
        choice=(index==0) ? "confirm" : "cancel"
        @sprites["#{choice}"].src_rect.y+=6
      end
      @over=false
      for i in 0...2
        if defined?($mouse)
          c=(i==0) ? "confirm" : "cancel"
          if $mouse.over?(@sprites["#{c}"])
            choice=(i==0) ? "confirm" : "cancel"
            index = i
            @over=true
          end
        end
      end
      if Input.trigger?(Input::C) || (defined?($mouse) && @over && $mouse.leftClick?)
        pbSEPlay("SE_Select2")
        break
      end
      Input.update
      @scene.animateBattleSprites
      @scene.pbGraphicsUpdate
    end
    @sprites["sel"].x=Graphics.width
    self.refresh
    10.times do
      @sprites["confirm"].x-=52
      @sprites["cancel"].x-=52
      @sprites["pocket5"].y-=8 if index > 0
      @scene.animateBattleSprites
      @scene.pbGraphicsUpdate
    end
    if index > 0
      @ret=nil
      return false
    else
      @index=0 if @index==4 && @lastUsed==0
      return true
    end
  end
  
  def refresh
    bitmap=@sprites["pocket4"].bitmap
      bitmap.clear
    i=(@lastUsed > 0 ? 1 : 0)
    text=["","#{PBItems.getName(@lastUsed)}"]
    bitmap.blt(0,0,@bitmaps[1],Rect.new(i*356,0,356,60))
    bitmap.blt(28,6,pbBitmap(sprintf("Graphics/Icons/item%03d",@lastUsed)),Rect.new(0,0,48,48)) if @lastUsed>0
    pbDrawOutlineText(bitmap,0,0,356,60,text[i],@baseColor,@shadowColor,1)
  end
  
  def update
    if @selPocket==0
      updateMain
      for i in 0...4
        @sprites["pocket#{i}"].opacity+=51 if @sprites["pocket#{i}"].opacity < 255
      end
      @sprites["pocket4"].y-=8 if @sprites["pocket4"].y > 316
      @sprites["pocket5"].y-=8 if @sprites["pocket5"].y > 320
      if @pocket
        for i in 0...@pocket.length
          @items["#{i}"].opacity-=51 if @items["#{i}"] && @items["#{i}"].opacity > 0
        end
      end
      @sprites["name"].x-=38 if @sprites["name"].x > -380
    else
      if defined?($mouse) && @over
        self.intoPocket if !@back && $mouse.leftClick?
      elsif Input.trigger?(Input::C) && !@back
        self.intoPocket
      end
      updatePocket
      for i in 0...4
        @sprites["pocket#{i}"].opacity-=51 if @sprites["pocket#{i}"].opacity > 0
      end
      @sprites["pocket4"].y+=8 if @sprites["pocket4"].y < 316+80
      for i in 0...@pocket.length
        @items["#{i}"].opacity+=51 if @items["#{i}"] && @items["#{i}"].opacity < 255
      end
    end
  end
  
  def updateMain
    if @index < 4
      @sprites["sel"].bitmap=@bitmaps[0]
      @sprites["sel"].src_rect.set(216*4,0,216,92)
    elsif @index==4
      @sprites["sel"].bitmap=@bitmaps[1]
      @sprites["sel"].src_rect.set(356*2,0,356,60)
    else
      @sprites["sel"].bitmap=@bitmaps[2]
      @sprites["sel"].src_rect.set(120*2,0,120,52)
    end
    @sprites["sel"].x=@sprites["pocket#{@index}"].x
    @sprites["sel"].y=@sprites["pocket#{@index}"].y
    if (defined?($mouse) && $mouse.active? && @over)
    elsif Input.trigger?(Input::LEFT)
      pbSEPlay("SE_Select1")
      @index-=1
      @index+=2 if @index%2==1
      @index=3 if @index==4 && !(@lastUsed > 0)
      @sprites["pocket#{@index}"].src_rect.y+=6
    elsif Input.trigger?(Input::RIGHT)
      pbSEPlay("SE_Select1")
      @index+=1
      @index-=2 if @index%2==0
      @index=2 if @index==4 && !(@lastUsed > 0)
      @sprites["pocket#{@index}"].src_rect.y+=6
    elsif Input.trigger?(Input::UP)
      pbSEPlay("SE_Select1")
      @index-=2
      @index+=6 if @index < 0
      @index=5 if @index==4 && !(@lastUsed > 0)
      @sprites["pocket#{@index}"].src_rect.y+=6
    elsif Input.trigger?(Input::DOWN)
      pbSEPlay("SE_Select1")
      @index+=2
      @index-=6 if @index > 5
      @index=5 if @index==4 && !(@lastUsed > 0)
      @sprites["pocket#{@index}"].src_rect.y+=6
    end
    @over = false
    for i in 0...6
      if defined?($mouse)
        if $mouse.over?(@sprites["pocket#{i}"])
          @index = i if i!=4 || (i==4 && @lastUsed > 0)
          @over = true
        end
      end
      @sprites["pocket#{i}"].src_rect.y-=1 if @sprites["pocket#{i}"].src_rect.y > 0
    end
    @doubleback = false
    @finished = false
    if defined?($mouse) && @over
      if $mouse.leftClick? && !@doubleback
        if @index < 5
          self.confirm
        elsif @index==5 && @selPocket==0
          self.finish
        end
      end
    elsif Input.trigger?(Input::C) && !@doubleback && @index < 5
      self.confirm
    elsif (Input.trigger?(Input::B) || (Input.trigger?(Input::C) && @index==5)) && @selPocket==0 && !@doubleback
      self.finish
    end
  end
  
  def finish
    pbSEPlay("SE_Select3")
    @finished = true
    Input.update
  end
  
  def confirm
    pbSEPlay("SE_Select2")
    if @index < 4
      cmd=[2,3,5,7]
      cmd=[2,1,4,5] if pbPocketNames.length==6
      self.drawPocket(cmd[@index],@index)
    else
      @selPocket=0
      @page=-1
      @ret=@lastUsed
      @lastUsed=0 if !($PokemonBag.pbQuantity(@lastUsed) > 1)
    end
  end
  
  def intoPocket
    pbSEPlay("SE_Select2")
    @selPocket=0
    @page=-1
    @lastUsed=0
    @lastUsed=@pocket[@item][0] if @pocket[@item][1] > 1
    $lastUsed=@lastUsed
    @ret=@pocket[@item][0]
  end

end

class PokeBattle_Scene
  alias pbItemMenu_ebs pbItemMenu unless self.method_defined?(:pbItemMenu_ebs)
  def pbItemMenu(index)
    @idleTimer=-1
    vector = @battle.doublebattle ? VECTOR2 : VECTOR1
    @vector.set(vector)
    @vector.inc=0.2
    Input.update
    return pbItemMenu_ebs(index) if EBUISTYLE==0
    ret=0
    retindex=-1
    pkmnid=-1
    @bagWindow.show
    loop do
      Input.update
      @bagWindow.update
      break if @bagWindow.finished
      if !@bagWindow.ret.nil? && @bagWindow.useItem?
        item=@bagWindow.ret
        usetype=$ItemData[item][ITEMBATTLEUSE]
        if usetype==1 || usetype==3
          modparty=[]
          for i in 0...6
            partyorder = @battle.respond_to?(:partyorder) ? @battle.partyorder[i] : @battle.party1order[i]
            modparty.push(@battle.party1[partyorder])
          end
          if isVersion17?
            pkmnlist  = PokemonParty_Scene.new
            pkmnlist.addPriority  = true
            pkmnscreen  = PokemonPartyScreen.new(pkmnlist,modparty)
          else
            pkmnlist  = PokemonScreen_Scene.new
            pkmnlist.addPriority  = true
            pkmnscreen  = PokemonScreen.new(pkmnlist,modparty)
          end
          pbFadeOutIn(999999) { 
            pkmnscreen.pbStartScene(_INTL("Use on which Pokémon?"),@battle.doublebattle)
          }
          activecmd=pkmnscreen.pbChoosePokemon
          partyorder = @battle.respond_to?(:partyorder) ? @battle.partyorder : @battle.party1order
          pkmnid=partyorder[activecmd]
          if activecmd>=0 && pkmnid>=0 && ItemHandlers.hasBattleUseOnPokemon(item)
            pkmnlist.pbEndScene
            ret=item
            retindex=pkmnid
            break
          end
          pkmnlist.pbEndScene
          @bagWindow.closeCurrent
          #itemscene.pbStartScene($PokemonBag)
        elsif usetype==2 || usetype==4
          if ItemHandlers.hasBattleUseOnBattler(item)
            ret=item
            retindex=index
            break
          end
        end
      end
      animateBattleSprites
      pbGraphicsUpdate
    end
    @bagWindow.hide
    pbConsumeItemInBattle($PokemonBag,ret) if ret > 0
    return [ret,retindex]
  end
end

module EBS_ScenePriority
  def self.included base
    base.class_eval do
      attr_accessor :addPriority
      alias pbStartScene_ebs pbStartScene unless self.method_defined?(:pbStartScene_ebs)
      def pbStartScene(*args)
        pbStartScene_ebs(*args)
        @viewport.z += 6 if @addPriority
      end
    end
  end
end

if defined?(PokemonParty_Scene)
  PokemonParty_Scene.send(:include,EBS_ScenePriority)
end

if defined?(PokemonScreen_Scene)
  PokemonScreen_Scene.send(:include,EBS_ScenePriority)
end
#===============================================================================
#  Pokemon data battle boxes (Next Generation)
#  UI overhaul
#===============================================================================
class NextGenDataBox  <  SpriteWrapper
  attr_reader :battler
  attr_accessor :selected
  attr_accessor :appearing
  attr_accessor :charged
  attr_reader :animatingHP
  attr_reader :animatingEXP
  
  def initialize(battler,doublebattle,viewport=nil,player=nil,scene=nil)
    view = Viewport.new(viewport.rect.x,viewport.rect.y,viewport.rect.width,viewport.rect.height)
    view.z = viewport.z# + 1
    @viewport = view
    @scene = scene
    @player = player
    @battler = battler
    @doublebattle = doublebattle
    @playerpoke = (@battler.index&1)==0
    @vector = (@battler.index&1)==0 ? @scene.vector.x : @scene.vector.x2
    @sprites = {}
    @path = "#{checkEBFolderPath}/nextGen/"
    @showhp = (@battler.index&1)==0
    @showexp = (@battler.index&1)==0
    @explevel=0
    @selected=0
    @frame=0
    @appearing=false
    @animatingHP=false
    @starthp=0.0
    @currenthp=0.0
    @endhp=0.0
    @expflash=0
    @loaded = false
    @showing = false
    @second = false
    @charged = false
    @Mbreathe = 1
    @Mlock = false
  end
  
  def disposed?
    return @sprites["layer1"].disposed? if @sprites["layer1"]
    return true
  end
  
  def dispose
    pbDisposeSpriteHash(@sprites)
  end
 
  def refreshExpLevel
    if !@battler.pokemon
      @explevel=0
    else
      growthrate=@battler.pokemon.growthrate
      startexp=PBExperience.pbGetStartExperience(@battler.pokemon.level,growthrate)
      endexp=PBExperience.pbGetStartExperience(@battler.pokemon.level+1,growthrate)
      if startexp==endexp
        @explevel=0
      else
        @explevel=(@battler.pokemon.exp-startexp)*@sprites["exp"].bitmap.width/(endexp-startexp)
      end
    end
  end
 
  def exp
    return @animatingEXP ? @currentexp : @explevel
  end
 
  def hp
    return @animatingHP ? @currenthp : @battler.hp
  end
 
  def animateHP(oldhp,newhp)
    @starthp=oldhp.to_f
    @currenthp=oldhp.to_f
    @endhp=newhp.to_f
    @animatingHP=true
  end
 
  def animateEXP(oldexp,newexp)
    @currentexp=oldexp
    @endexp=newexp
    @animatingEXP=true
  end
  
  def show; @showing = true; end
 
  def appear
    # used to call the set-up procedure from the battle scene
    self.setUp
    @loaded = true
    refreshExpLevel
    if @playerpoke
      @sprites["layer1"].x = -@sprites["layer1"].bitmap.width - 32
      @sprites["layer1"].y = @viewport.rect.height + @sprites["layer1"].bitmap.height + 32
    else
      @sprites["layer1"].x = @viewport.rect.width + @sprites["layer1"].bitmap.width + 32
      @sprites["layer1"].y = -@sprites["layer1"].bitmap.height - 32
    end
    self.x = @sprites["layer1"].x
    self.y = @sprites["layer1"].y
    self.refresh
  end
  
  def getBattler(battler)
    return battler.effects[PBEffects::Illusion] if PBEffects.const_defined?(:Illusion) && battler.respond_to?('effects') && !battler.effects[PBEffects::Illusion].nil?
    return battler
  end
  
  def setUp
    # reset of the set-up procedure
    @loaded = false
    @showing = false
    @second = false
    pbDisposeSpriteHash(@sprites)
    @sprites.clear
    # initializes all the necessary components
    @sprites["mega"] = Sprite.new(@viewport)
    @sprites["mega"].opacity = 0
    
    @sprites["layer1"] = Sprite.new(@viewport)
    @sprites["layer1"].bitmap = pbBitmap(@path+"layer1")
    @sprites["layer1"].src_rect.height = 64 if !@showexp
    @sprites["layer1"].mirror = !@playerpoke
    
    @sprites["shadow"] = Sprite.new(@viewport)
    @sprites["shadow"].bitmap = Bitmap.new(@sprites["layer1"].bitmap.width,@sprites["layer1"].bitmap.height)
    @sprites["shadow"].z = -1
    @sprites["shadow"].opacity = 255*0.25
    @sprites["shadow"].color = Color.new(0,0,0,255)
    
    @sprites["hp"] = Sprite.new(@viewport)
    @hpBarBmp = pbBitmap(@path+"hpBar")
    @hpBarChr = pbBitmap(@path+"hpBarCharged")
    c = @hpBarChr.get_pixel(2,0)
    @sprites["hp"].bitmap = Bitmap.new(@hpBarBmp.width,@hpBarBmp.height)
    @sprites["hp"].mirror = !@playerpoke
    
    for i in 0...46
      step = rand(129)/4.0
      @sprites["chr#{i}"] = Sprite.new(@viewport)
      @sprites["chr#{i}"].bitmap = Bitmap.new(4,14)
      @sprites["chr#{i}"].bitmap.fill_rect(0,0,4,14,c)
      @sprites["chr#{i}"].oy = @sprites["chr#{i}"].bitmap.height
      @sprites["chr#{i}"].opacity = 256*step/12.0
      @sprites["chr#{i}"].zoom_y = 1.0*step/24.0
      @sprites["chr#{i}"].z = 8
    end
    
    @sprites["exp"] = Sprite.new(@viewport)
    @sprites["exp"].bitmap = pbBitmap(@path+"expBar")
    @sprites["exp"].src_rect.y = @sprites["exp"].bitmap.height*-1 if !@showexp
    
    @sprites["text"] = Sprite.new(@viewport)
    @sprites["text"].bitmap = Bitmap.new(@sprites["layer1"].bitmap.width,@sprites["layer1"].bitmap.height)
    @sprites["text"].z = 9
    pbSetSystemFont(@sprites["text"].bitmap)
  end
   
  def x; return @sprites["layer1"].x; end
  def y; return @sprites["layer1"].y; end
  def z; return @sprites["layer1"].z; end
  def visible; return @sprites["layer1"] ? @sprites["layer1"].visible : false; end
  def opacity; return @sprites["layer1"].opacity; end
  def color; return @sprites["layer1"].color; end
  def x=(val)
    return if !@loaded
    # calculates the relative X positions of all elements
    @sprites["layer1"].x = val
    @sprites["text"].x = @sprites["layer1"].x
    @sprites["hp"].x = @sprites["layer1"].x + 28 + (!@playerpoke ? 4 : 0)
    @sprites["exp"].x = @sprites["layer1"].x + 40
    @sprites["mega"].x = @sprites["layer1"].x + (!@playerpoke ? -8 : 222)
    @sprites["shadow"].x = @sprites["layer1"].x + 2
  end
  def y=(val)
    return if !@loaded
    # calculates the relative Y positions of all elements
    @sprites["layer1"].y = val
    @sprites["text"].y = @sprites["layer1"].y
    @sprites["hp"].y = @sprites["layer1"].y + 46
    @sprites["exp"].y = @sprites["layer1"].y + 68
    @sprites["mega"].y = @sprites["layer1"].y + 38
    @sprites["shadow"].y = @sprites["layer1"].y + 2
  end
  def visible=(val)
    for key in @sprites.keys
      next if key=="layer0"
      next if !@sprites[key]
      if key.include?("chr")
        @sprites[key].visible = val if @charged
      else
        @sprites[key].visible = val
      end
    end
  end
  def opacity=(val)
    for key in @sprites.keys
      next if key=="layer0"
      next if key=="mega" && !@battler.isMega?
      next if !@sprites[key]
      @sprites[key].opacity = val
      @sprites[key].opacity *= 0.25 if key=="shadow"
    end
  end
  def color=(val)
    for sprite in @sprites.values
      sprite.color = val
    end
  end
  def positionX=(val)
    val = 4 if val < 4
    val = (@viewport.rect.width - @sprites["layer1"].bitmap.width) if val > (@viewport.rect.width - @sprites["layer1"].bitmap.width)
    self.x = val
  end
  
  def updateChargeAnimation
    return if !@charged || !self.visible
    for i in 0...46
      if @sprites["chr#{i}"].zoom_y >= 1.0
        @sprites["chr#{i}"].zoom_y = 0
        @sprites["chr#{i}"].opacity = 255
      end
      @sprites["chr#{i}"].opacity -= 256/48.0
      @sprites["chr#{i}"].zoom_y += 1.0/24.0
      @sprites["chr#{i}"].x = @sprites["hp"].x + 2 + i*4
      @sprites["chr#{i}"].y = @sprites["hp"].y + 2
      @sprites["chr#{i}"].color.alpha -= 16 if @sprites["chr#{i}"].color.alpha > 0
    end
  end
  
  def charge
    @charged = true
    @sprites["hp"].color = Color.new(255,255,255)
    for i in 0...46
      @sprites["chr#{i}"].color = Color.new(255,255,255)
    end
    self.updateHpBar
    self.visible = self.visible
  end
  
  def stopCharge
    @charged = false
    @sprites["hp"].color = Color.new(255,255,255)
    self.updateHpBar
    self.visible = self.visible
  end
  
  def updateHpBar
    # updates the current state of the HP bar
    # the bar's colour hue gets dynamically adjusted (i.e. not through sprites)
    # HP bar is mirrored for opposing Pokemon
    hpbar = @battler.totalhp==0 ? 0 : (1.0*self.hp*@sprites["hp"].bitmap.width/@battler.totalhp).ceil
    @sprites["hp"].src_rect.x = @sprites["hp"].bitmap.width - hpbar if !@playerpoke
    @sprites["hp"].src_rect.width = hpbar
    hue = (0-120)*(1-(self.hp.to_f/@battler.totalhp))
    @sprites["hp"].bitmap.clear
    bmp = @charged ? @hpBarChr : @hpBarBmp
    @sprites["hp"].bitmap.blt(0,0,bmp,Rect.new(0,0,bmp.width,bmp.height))
    @sprites["hp"].bitmap.hue_change(hue) if !@charged
    for i in 0...46
      @sprites["chr#{i}"].zoom_x = (i >= (46*(self.hp.to_f/@battler.totalhp)).floor) ? 0 : 1
      @sprites["chr#{i}"].zoom_x = 0 if !@charged
    end
  end
  
  def refresh
    # exits the refresh if the databox isn't fully set up yet
    return if !@loaded
    # update for HP/EXP bars
    self.updateHpBar
    @sprites["exp"].src_rect.width = self.exp
    # clears the current bitmap containing text and adjusts its font
    @sprites["text"].bitmap.clear
    pbSetSystemFont(@sprites["text"].bitmap)
    # used to calculate the potential offset of elements should they exceed the
    # width of the HP bar
    str = ""
    str = _INTL("♂") if getBattler(@battler).gender==0
    str = _INTL("♀") if getBattler(@battler).gender==1
    w = @sprites["text"].bitmap.text_size("#{getBattler(@battler).name}#{str}Lv.#{getBattler(@battler).level}").width
    o = (w > @sprites["hp"].bitmap.width+4) ? (w-(@sprites["hp"].bitmap.width+4))/2.0 : 0; o = o.ceil
    o += 2 if getBattler(@battler).level == 100
    # additional layer to draw extra things onto the databox (unused by default)
    bmp = pbBitmap(@path+"layer2")
    @sprites["text"].bitmap.blt(@playerpoke ? 0 : 4,@playerpoke ? 0 : 4,bmp,Rect.new(0,0,bmp.width,@showexp ? bmp.height : 62))
    # writes the Pokemon's name
    str = getBattler(@battler).name
    str += " "
    x = @playerpoke ? 28 : 32
    pkmn = getBattler(@battler); pkmn = pkmn.pokemon if pkmn.respond_to?(:pokemon)
    color = pkmn.isShiny? ? Color.new(222,197,95) : Color.new(255,255,255) if !pkmn.nil?
    pbDrawOutlineText(@sprites["text"].bitmap,x-o,-20,@sprites["text"].bitmap.width,@sprites["text"].bitmap.height,str,color,Color.new(0,0,0),0)
    # writes the Pokemon's gender
    x = @sprites["text"].bitmap.text_size(str).width + (@playerpoke ? 28 : 32)
    str = ""
    str = _INTL("♂") if getBattler(@battler).gender==0
    str = _INTL("♀") if getBattler(@battler).gender==1
    color = (getBattler(@battler).gender==0) ? Color.new(53,107,208) : Color.new(180,37,77)
    pbDrawOutlineText(@sprites["text"].bitmap,x-o,-20,@sprites["text"].bitmap.width,@sprites["text"].bitmap.height,str,color,Color.new(0,0,0),0)
    # writes the Pokemon's level
    str = "#{getBattler(@battler).level}"
    x = @playerpoke ? -30 : -26
    pbDrawOutlineText(@sprites["text"].bitmap,x+o,-20,@sprites["text"].bitmap.width,@sprites["text"].bitmap.height,str,Color.new(255,255,255),Color.new(0,0,0),2)
    x -= @sprites["text"].bitmap.text_size(str).width+(@playerpoke ? 3 : 2)
    pbSetSmallFont(@sprites["text"].bitmap)
    str = _INTL("Lv.")
    pbDrawOutlineText(@sprites["text"].bitmap,x+o+2,-19,@sprites["text"].bitmap.width,@sprites["text"].bitmap.height,str,Color.new(222,197,95),Color.new(0,0,0),2)    
    # writes the number of the Pokemon's current/total HP
    str = "#{self.hp}/#{@battler.totalhp}"
    pbDrawOutlineText(@sprites["text"].bitmap,-40,13,@sprites["text"].bitmap.width,@sprites["text"].bitmap.height,str,Color.new(255,255,255),Color.new(0,0,0),1) if @showhp
    # draws Pokeball if Pokemon is caught
    @sprites["text"].bitmap.blt(12,46,pbBitmap(@path+"battleBoxOwned.png"),Rect.new(0,0,14,14)) if !@playerpoke && @battler.owned && !@scene.battle.opponent
    # draws the status conditions
    @sprites["text"].bitmap.blt(160,54,pbBitmap(@path+"statuses"),Rect.new(0,18*(@battler.status-1),52,18)) if @battler.status > 0
    # re-draws the databox shadow
    @sprites["shadow"].bitmap.clear
    bmp = @sprites["layer1"].bitmap.clone
    @sprites["shadow"].bitmap.blt(@playerpoke ? 0 : 4,0,bmp,Rect.new(0,0,bmp.width,@showexp ? bmp.height : 64))
    bmp = @sprites["text"].bitmap.clone
    @sprites["shadow"].bitmap.blt(0,0,bmp,Rect.new(0,0,bmp.width,bmp.height))
    # changes the Mega symbol graphics (depending on Mega or Primal)
    if @battler.isMega?
      @sprites["mega"].bitmap = pbBitmap("#{checkEBFolderPath}/mega_sym")
    elsif @battler.respond_to?(:isPrimal?) && @battler.isPrimal?
      path=nil
      path="Graphics/Pictures/battlePrimalKyogreBox.png" if @battler.species == getConst(PBSpecies,:KYOGRE)
      path="Graphics/Pictures/battlePrimalGroudonBox.png" if @battler.species == getConst(PBSpecies,:GROUDON)
      @sprites["mega"].bitmap = pbBitmap(path)      
    end
    @sprites["mega"].x = @sprites["layer1"].x + (!@playerpoke ? -8 : 222)
  end
  
  def update
    # updates the HP increase/decrease animation
    if @animatingHP
      if @currenthp < @endhp
        @currenthp += (@endhp - @currenthp)/10.0
        @currenthp = @currenthp.ceil
        @currenthp = @endhp if @currenthp > @endhp
      elsif @currenthp > @endhp        
        @currenthp -= (@currenthp - @endhp)/10.0
        @currenthp = @currenthp.floor
        @currenthp = @endhp if @currenthp < @endhp
      end
      self.refresh
      @animatingHP = false if @currenthp==@endhp
    end
    # updates the EXP increase/decrease animation
    if @animatingEXP
      if !@showexp
        @currentexp = @endexp
      elsif @currentexp < @endexp
        @currentexp += (@endexp - @currentexp)/10.0
        @currentexp = @currentexp.ceil
        @currentexp = @endexp if @currentexp > @endexp
      elsif @currentexp > @endexp
        @currentexp -= (@currentexp - @endexp)/10.0
        @currentexp = @currentexp.floor
        @currentexp = @endexp if @currentexp < @endexp
      end
      self.refresh
      if @currentexp == @endexp
        # tints the databox blue and plays a sound when EXP is full
        if @currentexp >= @sprites["exp"].bitmap.width
          pbSEPlay(isVersion17? ? "Pkmn exp full" : "expfull")
          @sprites["layer1"].tone = Tone.new(0,80,210)
          @sprites["text"].tone = Tone.new(0,80,210)
          @animatingEXP = false
          refreshExpLevel
        else
          @animatingEXP = false
        end
      end
    end
    return if !@loaded
    # animates the movement of the databox to its screen position
    # this position is dependant on the battle scene vector
    if @showing && !@second
      y = @playerpoke ? @viewport.rect.height - @sprites["layer1"].bitmap.height - 2 : 6
      x = @vector + @sprites["layer1"].bitmap.width/2
      if @scene.battle.doublebattle
        x = 0 if @battler.index==1
        x = @viewport.rect.width if @battler.index==2
      end
      x = 4 if x < 4
      x = (@viewport.rect.width - @sprites["layer1"].bitmap.width) if x > (@viewport.rect.width - @sprites["layer1"].bitmap.width)
      self.x -= (self.x - x)/4
      self.y += (y - self.y)/4
      @second = true if self.x <= x+2 && self.x >= x-2
    end
    # shows the Mega/Primal symbols when activated
    if (@battler.isMega? || (@battler.respond_to?(:isPrimal?) && @battler.isPrimal?)) && !@Mlock
      @sprites["mega"].opacity = 255
      @Mlock = true
    end  
    # charged bar animation
    self.updateChargeAnimation
    @sprites["hp"].color.alpha -= 16 if @sprites["hp"].color.alpha > 0
    # animates a glow for the Mega/Primal symbols
    if @battler.isMega? || (@battler.respond_to?(:isPrimal?) && @battler.isPrimal?)
      @sprites["mega"].tone.red += @Mbreathe
      @sprites["mega"].tone.green += @Mbreathe
      @sprites["mega"].tone.blue += @Mbreathe
      @Mbreathe = -1 if @sprites["mega"].tone.red >= 100
      @Mbreathe = 1 if @sprites["mega"].tone.red <= 0
    end     
    # gets rid of the level up tone
    @sprites["layer1"].tone.green -= 4 if @sprites["layer1"].tone.green > 0
    @sprites["layer1"].tone.blue -= 21 if @sprites["layer1"].tone.blue > 0
    @sprites["text"].tone.green -= 4 if @sprites["text"].tone.green > 0
    @sprites["text"].tone.blue -= 21 if @sprites["text"].tone.blue > 0
  end
end
#===============================================================================
#  Command Menu (Next Generation)
#  UI ovarhaul
#===============================================================================
class NextGenCommandWindow
  attr_accessor :index
  attr_accessor :overlay
  attr_accessor :backdrop
  attr_accessor :coolDown
  
  def initialize(viewport=nil,battle=nil,safari=false,viewport_top=nil)
    if !viewport.nil?
      @viewport = Viewport.new(viewport.rect.x,viewport.rect.y,viewport.rect.width,viewport.rect.height)
      @viewport.z = viewport.z# + 1
    end
    @battle=battle
    @safaribattle=safari
    @index=0
    @oldindex=0
    @coolDown=0
    @over=false
    @path="#{checkEBFolderPath}/nextGen/"
    
    @background=Sprite.new(@viewport)
    @background.bitmap=pbBitmap(@path+"commandMenu")
    @background.x=@viewport.rect.width-@background.bitmap.width
    @background.y=@viewport.rect.height-@background.bitmap.height
    @yO=(@background.bitmap.height/10.0).round*10
   
    @helpText=Sprite.new(@viewport)
    @helpText.bitmap=Bitmap.new(@background.bitmap.width,@background.bitmap.height)
    @helpText.y=@background.y
    @helpText.x=@background.x
    @helpText.z=9
    pbSetSmallFont(@helpText.bitmap)
   
    @buttons=Sprite.new(@viewport)
    @buttons.x=@background.x+(@background.bitmap.width-222)
    @buttons.y=@background.y
    
    @arrowLeft=Sprite.new(@viewport)
    @arrowLeft.bitmap=pbBitmap(@path+"arrowLeft")
    @arrowLeft.x=@background.x-2
    @arrowLeft.y=@background.y+4
    
    @arrowRight=Sprite.new(@viewport)
    @arrowRight.bitmap=pbBitmap(@path+"arrowRight")
    @arrowRight.x=@background.x+@background.bitmap.width-@arrowRight.bitmap.width-5
    @arrowRight.y=@background.y+4
    
    @barGraphic = pbBitmap(@path+"partyBar")
    @ballGraphic = pbBitmap(@path+"partyIndicators")
    
    @partyLine1 = Sprite.new(@viewport)
    @partyLine1.bitmap = Bitmap.new(@barGraphic.width,14)
    @partyLine1.x = -6
    @partyLine1.end_x = @partyLine1.x
    @partyLine1.y = 274
    @partyLine1.opacity = 255*0.8
    @partyLine2 = Sprite.new(@viewport)
    @partyLine2.bitmap = Bitmap.new(@barGraphic.width,14)
    @partyLine2.x = @viewport.rect.width - 140
    @partyLine2.end_x = @partyLine2.x
    @partyLine2.y = 80
    @partyLine2.opacity = 255*0.8
    
    @arrowsShow = true
    
    @aL=@arrowLeft.x
    @aR=@arrowRight.x
    @orgx=@buttons.x
    self.update
  end
  
  def refreshCommands(index)
    poke = @battle.battlers[index]
    cmds = []
    cmds.push(@safaribattle ? _INTL("BALL") : _INTL("FIGHT"))
    cmds.push(@safaribattle ? _INTL("BAIT") : _INTL("BAG"))
    cmds.push(@safaribattle ? _INTL("ROCK") : _INTL("PARTY"))
    cmds.push((poke.isShadow? && poke.inHyperMode?) ? _INTL("CALL") : _INTL("RUN"))
    bmp = pbBitmap(@path+"cmdButtons")
    bitmap = Bitmap.new(188,176)
    pbSetSmallFont(bitmap)
    for i in 0...4
      bitmap.blt(30*i,44*i,bmp,Rect.new(0,44*i,98,44))
      outline = self.darkenColor(bmp.get_pixel(52,22+(44*i)),0.6)
      pbDrawOutlineText(bitmap,30*i,(44*i)-1,98,44,cmds[i],Color.new(255,255,255),outline,1)
      for j in 0...4
        next if i==j
        x = (j > i) ? ((30*i) + 74 + (30*(j-i))) : (30*j)
        bitmap.blt(x,44*i,bmp,Rect.new(98,44*j,22,44))
      end
    end
    @buttons.bitmap = bitmap.clone
    @buttons.src_rect.height = bitmap.height/4
    @buttons.src_rect.y = 44*@index
  end
 
  def visible; end; def visible=(val); end
  def disposed?; end
  def dispose
    @viewport.dispose
    @helpText.dispose
    @background.dispose
    @buttons.dispose
    @arrowLeft.dispose
    @arrowRight.dispose
    @partyLine1.dispose
    @partyLine2.dispose
  end
  def color; end; def color=(val); end
   
  def showText
    @helpText.y-=@yO/10
    self.showArrows
  end
  
  def lineupY(y)
    @partyLine1.y += y
    #@partyLine2.y += y
  end
  
  def drawLineup
    return if @safaribattle || !SHOWPARTYARROWS
    @partyLine1.bitmap.clear
    @partyLine2.bitmap.clear
    # start drawing the player party preview
    @partyLine1.bitmap.blt(0,2,@barGraphic,Rect.new(0,0,@barGraphic.width,@barGraphic.height))
    for i in 0...6
      o=3
      if i < @battle.party1.length && @battle.party1[i]
        if @battle.party1[i].hp <=0 || @battle.party1[i].isEgg?
          o=2
        elsif @battle.party1[i].status > 0
          o=1
        else
          o=0
        end
      end
      @partyLine1.bitmap.blt(18+i*18,0,@ballGraphic,Rect.new(14*o,0,14,14))
    end
    # start drawing the opponent party preview
    return if !@battle.opponent
    @partyLine2.bitmap.blt(0,2,@barGraphic,Rect.new(0,0,@barGraphic.width,@barGraphic.height))
    for i in 0...6
      enemyindex=i
      if @battle.doublebattle && i >=3
        enemyindex=(i%3)+@battle.pbSecondPartyBegin(1)
      end
      o=3
      if enemyindex < @battle.party2.length && @battle.party2[enemyindex]
        if @battle.party2[enemyindex].hp <=0 || @battle.party2[enemyindex].isEgg?
          o=2
        elsif @battle.party2[enemyindex].status > 0
          o=1
        else
          o=0
        end
      end
      @partyLine2.bitmap.blt(18+i*18,0,@ballGraphic,Rect.new(14*o,0,14,14))
    end
  end
  
  def darkenColor(color=nil,amt=0.2)
    return nil if color.nil?
    red = color.red - color.red*amt
    green = color.green - color.green*amt
    blue = color.blue - color.blue*amt
    return Color.new(red,green,blue)
  end
 
  def text=(msg)
    self.drawLineup
    @helpText.bitmap.clear
    pbDrawOutlineText(@helpText.bitmap,-2,20,@helpText.bitmap.width,@helpText.bitmap.height,msg,Color.new(255,255,255),Color.new(0,0,0),1)
  end
 
  def show
    @background.y-=@yO/10
    @buttons.y-=@yO/10
    @arrowLeft.y-=@yO/10
    @arrowRight.y-=@yO/10
  end
  
  def showArrows
    @partyLine1.end_x = -6
    @partyLine2.end_x = @viewport.rect.width - 140
    @partyLine1.x += (@partyLine1.end_x - @partyLine1.x)*0.4
    @partyLine2.x -= (@partyLine2.x - @partyLine2.end_x)*0.4
  end
  
  def hideArrows
    @partyLine1.end_x = -6 - @partyLine1.bitmap.width
    @partyLine2.end_x = @viewport.rect.width - 140 + @partyLine2.bitmap.width
    @partyLine1.x += (@partyLine1.end_x - @partyLine1.x)*0.4
    @partyLine2.x -= (@partyLine2.x - @partyLine2.end_x)*0.4
  end
 
  def hide(skip=false)
    @background.y+=@yO/10
    @buttons.y+=@yO/10
    @helpText.y+=@yO/10
    @arrowLeft.y+=@yO/10
    @arrowRight.y+=@yO/10
    self.hideArrows
  end
   
  def update
    @over=$mouse.over?(@buttons) if defined?($mouse)
    # animation for when the index changes
    if @oldindex!=@index
      @buttons.x+=2
      if @buttons.x==@orgx+6
        @buttons.src_rect.y = (@buttons.bitmap.height/4)*@index
        @oldindex=@index
      end
    else
      @buttons.x-=2 if @buttons.x > @orgx
      @coolDown=0 if @buttons.x==@orgx
    end
    @arrowRight.x-=2 if @arrowRight.x > @aR
    @arrowLeft.x+=2 if @arrowLeft.x < @aL
    # mouse functions for compatibility with the Easy Mouse System
    if defined?($mouse) && $mouse.leftClick?(@arrowLeft) && @coolDown < 1
      self.triggerLeft
      if @index > 0
        pbSEPlay("SE_Select1")
        @index-=1
      elsif @index <=0
        pbSEPlay("SE_Select1")
        @index=3
      end
      @coolDown=1
    elsif defined?($mouse) && $mouse.leftClick?(@arrowRight) && @coolDown < 1
      self.triggerRight
      if @index < 3
        pbSEPlay("SE_Select1")
        @index+=1
      elsif @index >=3
        pbSEPlay("SE_Select1")
        @index=0
      end
      @coolDown=1
    end
  end
  
  def triggerLeft; @arrowLeft.x=@aL-8; end
  def triggerRight; @arrowRight.x=@aR+8; end
  
  def mouseOver?
    return false if !defined?($mouse)
    return @over
  end
 
end
#===============================================================================
#  Fight Menu (Next Generation)
#  UI ovarhaul
#===============================================================================
class NextGenFightWindow
  attr_accessor :index
  attr_accessor :battler
  attr_accessor :refreshpos
  attr_reader :nummoves
 
  def initialize(viewport=nil,battle=nil)
    if !viewport.nil?
      view = Viewport.new(viewport.rect.x,viewport.rect.y,viewport.rect.width,viewport.rect.height)
      view.z = viewport.z
      view2 = Viewport.new(viewport.rect.x,viewport.rect.y,viewport.rect.width,viewport.rect.height)
      view2.z = viewport.z# + 2
      viewport = view
    end
    @viewport=viewport
    @viewport2=(viewport.nil?) ? viewport : view2
    @battle=battle
    @index=0
    @oldindex=-1
    @over=false
    @refreshpos=false
    @battler=nil
    @nummoves=0
    
    @opponent=nil
    @player=nil
    @opponent=@battle.battlers[1] if !@battle.doublebattle
    @player=@battle.battlers[0] if !@battle.doublebattle
   
    @buttonBitmap=pbBitmap("#{checkEBFolderPath}/nextGen/moveSelButtons")
   
    @background=Sprite.new(@viewport)
    @background.bitmap=pbBitmap("#{checkEBFolderPath}/nextGen/newBattleMessageBox")
    @background.y=VIEWPORT_HEIGHT-96
    @background.z=100
    
    @megaButton=Sprite.new(@viewport)
    @megaButton.bitmap=pbBitmap("#{checkEBFolderPath}/nextGen/megaEvoButton")
    @megaButton.z=101
    @megaButton.x=10
    @megaButton.y=316 + 100
    @megaButton.src_rect.set(0,0,44,44)
    
    @backButton=Sprite.new(@viewport)
    @backButton.bitmap=pbBitmap("#{checkEBFolderPath}/nextGen/backButton")
    @backButton.z=101
    @backButton.x=462
    @backButton.y=316
      
    @button={}
    @moved=false
    @showMega=false
    @ox=[60,258,60,258]
    @oy=[294,294,338,338]
    # If you're coming from Thundaga's tutorial to add your custom type's
    # text to the @types array, this step is no longer necessary, and EBS
    # will take care of that for you automatically
    @category=[_INTL("PHYS"),_INTL("SPEC"),_INTL("STAT")]
    
    eff=[_INTL("Normal damage"),_INTL("Not very effective"),_INTL("Super effective")]
    @typeInd=Sprite.new(@viewport)
    @typeInd.bitmap=Bitmap.new(192,24*3)
    pbSetSmallFont(@typeInd.bitmap)
    for i in 0...3
      pbDrawOutlineText(@typeInd.bitmap,0,24*i,192,24,eff[i],Color.new(255,255,255),Color.new(0,0,0),1)
    end
    @typeInd.src_rect.set(0,0,192,24)
    @typeInd.ox=96
    @typeInd.oy=16
    @typeInd.z=103
    @typeInd.visible=false
   
  end
 
  def generateButtons
    @moves=@battler.moves
    @nummoves=0
    @oldindex=-1
    for i in 0...4
      @button["#{i}"].dispose if @button["#{i}"]
      @nummoves+=1 if @moves[i] && @moves[i].id > 0
    end
    @x = @ox.clone
    @y = @oy.clone
    for i in 0...4
      @y[i] += 22 if @nummoves < 3
    end
    @button={}
    for i in 0...@nummoves 
      movedata = PBMoveData.new(@moves[i].id)
      move = @moves[i]
      @button["#{i}"] = Sprite.new(@viewport)
      @button["#{i}"].z = 102
      @button["#{i}"].bitmap = Bitmap.new(198*2,78)
      @button["#{i}"].bitmap.blt(0,0,@buttonBitmap,Rect.new(0,move.type*78,198,78))
      @button["#{i}"].bitmap.blt(198,0,@buttonBitmap,Rect.new(198,move.type*78,198,78))
      baseColor=self.darkenColor(@buttonBitmap.get_pixel(16,8+(@moves[i].type*78)))
      baseColor2=@buttonBitmap.get_pixel(16,8+(@moves[i].type*78))
      shadowColor=self.darkenColor(@buttonBitmap.get_pixel(18,10+(@moves[i].type*78)))
      pbSetSmallFont(@button["#{i}"].bitmap)
      pbDrawOutlineText(@button["#{i}"].bitmap,198,0,196,42,"#{move.name}",Color.new(255,255,255),baseColor,1)
      pbDrawOutlineText(@button["#{i}"].bitmap,6,52,186,22,self.typename(move.type),Color.new(255,255,255),baseColor2,0)
      pbDrawOutlineText(@button["#{i}"].bitmap,6,52,186,22,@category[movedata.category],Color.new(255,255,255),baseColor2,2)
      pp = "#{move.pp}/#{move.totalpp}"
      text=[
        [pp,98,40,2,baseColor,shadowColor]
      ]
      pbDrawTextPositions(@button["#{i}"].bitmap,text)
      pbSetSystemFont(@button["#{i}"].bitmap)
      text=[
        ["#{move.name}",98,12,2,baseColor,shadowColor]
      ]
      pbDrawTextPositions(@button["#{i}"].bitmap,text)
      @button["#{i}"].src_rect.set(198,0,198,78)
      @button["#{i}"].x = @x[i] - ((i%2==0) ? 260 : -260)
      @button["#{i}"].y = @y[i]
    end
    
  end
  
  def typename(type)
    name = PBTypes.getName(type).upcase
    return _INTL("ELECTR") if name == "ELECTRIC"
    return _INTL("PSYCH") if name == "PSYCHIC"
    arr = name.scan(/./)
    return name if arr.length < 7
    n = ""
    for i in 0...6
      n += arr[i]
    end
    return n
  end
   
  def formatBackdrop
  end
  
  def darkenColor(color=nil,amt=0.2)
    return nil if color.nil?
    red = color.red - color.red*amt
    green = color.green - color.green*amt
    blue = color.blue - color.blue*amt
    return Color.new(red,green,blue)
  end
  
  def show
    @typeInd.visible=false
    @background.y -= 10
    @backButton.y -= 10
    for i in 0...@nummoves
      @button["#{i}"].x += ((i%2==0) ? 26 : -26) 
    end
  end
 
  def hide
    @typeInd.visible=false
    @background.y += 10
    @megaButton.y += 10
    @backButton.y += 10
    for i in 0...@nummoves
      @button["#{i}"].x -= ((i%2==0) ? 26 : -26)
    end
    @showMega=false
  end
 
  def megaButton
    @showMega=true
  end
 
  def megaButtonTrigger
    @megaButton.src_rect.x+=44
    @megaButton.src_rect.x=0 if @megaButton.src_rect.x > 44
    @megaButton.src_rect.y = -4
  end
 
  def update
    if @showMega
      @megaButton.y -= 10 if @megaButton.y > 316
      @megaButton.src_rect.y += 1 if @megaButton.src_rect.y < 0
    end      
    if @oldindex!=@index
      @button["#{@index}"].src_rect.y = -4
      if SHOWTYPEADVANTAGE && !@battle.doublebattle
        move = @battler.moves[@index]
        @modifier = move.pbTypeModifier(move.type,@player,@opponent)
      end
      @oldindex = @index
    end
    for i in 0...@nummoves
      @button["#{i}"].src_rect.x = 198*(@index == i ? 0 : 1)
      @button["#{i}"].y = @y[i]
      @button["#{i}"].src_rect.y += 1 if @button["#{i}"].src_rect.y < 0
      next if i!=@index
      if [0,1].include?(i)
        @button["#{i}"].y = @y[i] - ((@nummoves < 3) ? 18 : 34)
      elsif [2,3].include?(i)
        @button["#{i}"].y = @y[i] - 34
        @button["#{i-2}"].y = @y[i-2] - 34
      end
    end
    if SHOWTYPEADVANTAGE && !@battle.doublebattle
      @typeInd.visible = true
      @typeInd.y = @button["#{@index}"].y
      @typeInd.x = @button["#{@index}"].x + @button["#{@index}"].src_rect.width/2
      eff=0
      if @modifier<8
        eff=1   # "Not very effective"
      elsif @modifier>8
        eff=2   # "Super effective"
      end
      @typeInd.src_rect.y = 24*eff
    end
    if defined?($mouse)
      @over = false
      for i in 0...@nummoves
        if $mouse.overPixel?(@button["#{i}"])
          @index = i
          @over = true
        end
      end
    end
  end
  
  def dispose
    @viewport.dispose
    @viewport2.dispose
    @background.dispose
    @megaButton.dispose
    @backButton.dispose
    @typeInd.dispose
    pbDisposeSpriteHash(@button)
  end
  
  def overMega?
    return false if !defined?($mouse)
    return $mouse.over?(@megaButton)
  end
  
  def mouseOver?
    return false if !defined?($mouse)
    return @over
  end
  
  def goBack?
    return $mouse.over?(@backButton) && Input.triggerex?($mouse.button?)
  end
end