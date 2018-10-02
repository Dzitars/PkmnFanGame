#===============================================================================
#  Elite Battle system
#    by Luka S.J.
# ----------------
#  Sprites Script
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
#  New methods for creating in-battle Pokemon sprites.
#  * creates fixed shadows in the sprite itself
#  * calculates correct positions according to metric data in here
#  * sprites have a different focal point for more precise base placement
#===============================================================================
class DynamicPokemonSprite
  attr_accessor :shadow
  attr_accessor :sprite
  attr_accessor :showshadow
  attr_accessor :status
  attr_accessor :hidden
  attr_accessor :fainted
  attr_accessor :anim
  attr_accessor :charged
  attr_accessor :isShadow
  attr_reader :loaded
  attr_reader :selected
  attr_reader :isSub
  attr_reader :viewport
  attr_reader :pulse

  def initialize(doublebattle,index,viewport=nil)
    @viewport=viewport
    @metrics=load_data("Data/metrics.dat")
    @selected=0
    @frame=0
    @frame2=0
    @frame3=0
    
    @status=0
    @loaded=false
    @charged=false
    @index=index
    @doublebattle=doublebattle
    @showshadow=true
    @altitude=0
    @yposition=0
    @shadow=Sprite.new(@viewport)
    @sprite=Sprite.new(@viewport)
      back=(@index%2==0)
    @substitute=AnimatedBitmapWrapper.new("Graphics/Battlers/"+(back ? "substitute_back" : "substitute"),POKEMONSPRITESCALE)
    @overlay=Sprite.new(@viewport)
    @isSub=false
    @lock=false
    @pokemon=nil
    @still=false
    @hidden=false
    @fainted=false
    @anim=false
    @isShadow=false
    
    @fp = {}
    for i in 0...16
      @fp["#{i}"] = Sprite.new(@viewport)
      @fp["#{i}"].bitmap = pbBitmap("Graphics/Animations/ebShadow")
      @fp["#{i}"].ox = @fp["#{i}"].bitmap.width/4
      @fp["#{i}"].oy = @fp["#{i}"].bitmap.height/2
      @fp["#{i}"].src_rect.set(0,0,@fp["#{i}"].bitmap.width/2,@fp["#{i}"].bitmap.height)
      @fp["#{i}"].opacity = 0
    end
    
    for i in 0...16
      @fp["c#{i}"] = Sprite.new(@viewport)
      @fp["c#{i}"].bitmap = pbBitmap("Graphics/Animations/ebCharged")
      @fp["c#{i}"].ox = @fp["c#{i}"].bitmap.width/8
      @fp["c#{i}"].oy = @fp["c#{i}"].bitmap.height
      @fp["c#{i}"].src_rect.set(0,0,@fp["c#{i}"].bitmap.width/4,@fp["c#{i}"].bitmap.height)
      @fp["c#{i}"].opacity = 0
    end
    
    for j in 0...4
      @fp["r#{j}"] = Sprite.new(viewport)
      @fp["r#{j}"].bitmap = pbBitmap("Graphics/Animations/ebRipple")
      @fp["r#{j}"].ox = @fp["r#{j}"].bitmap.width/2
      @fp["r#{j}"].oy = @fp["r#{j}"].bitmap.height/2
      @fp["r#{j}"].zoom_x = 0
      @fp["r#{j}"].zoom_y = 0
      @fp["r#{j}"].param = 0
    end
    
    @pulse = 8
    @k = 1
  end
  
  def battleIndex; return @index; end
  def x; @sprite.x; end
  def y; @sprite.y; end
  def z; @sprite.z; end
  def ox; @sprite.ox; end
  def oy; @sprite.oy; end
  def zoom_x; @sprite.zoom_x; end
  def zoom_y; @sprite.zoom_y; end
  def visible; @sprite.visible; end
  def opacity; @sprite.opacity; end
  def width; @bitmap.width; end
  def height; @bitmap.height; end
  def tone; @sprite.tone; end
  def bitmap; @bitmap.bitmap; end
  def actualBitmap; @bitmap; end
  def disposed?; @sprite.disposed?; end
  def color; @sprite.color; end
  def src_rect; @sprite.src_rect; end
  def blend_type; @sprite.blend_type; end
  def angle; @sprite.angle; end
  def mirror; @sprite.mirror; end
  def src_rect; return @sprite.src_rect; end
  def src_rect=(val)
    @sprite.src_rect=val
  end
  def lock
    @lock=true
  end
  def bitmap=(val)
    @bitmap.bitmap=val
  end
  def x=(val)
    @sprite.x=val
    @shadow.x=val
  end
  def ox=(val)
    @sprite.ox=val
    self.formatShadow
  end
  def addOx(val)
    @sprite.ox+=val
    self.formatShadow
  end
  def oy=(val)
    @sprite.oy=val
    self.formatShadow
  end
  def addOy(val)
    @sprite.oy+=val
    self.formatShadow
  end
  def y=(val)
    @sprite.y=val
    @shadow.y=val
  end
  def z=(val)
    @shadow.z=(val==32) ? 31 : 10
    @sprite.z=val
  end
  def zoom_x=(val)
    @sprite.zoom_x=val
    self.formatShadow
  end
  def zoom_y=(val)
    @sprite.zoom_y=val
    self.formatShadow
  end
  def visible=(val)
    return if @hidden
    @sprite.visible=val
    if @fp
      val = false if @hidden || @fainted
      for key in @fp.keys
        if key.include?("c") || key.include?("r")
          val = false if !@charged
        else
          val = false if !@isShadow
        end
        @fp[key].visible=val
      end
    end
    self.formatShadow
  end
  def opacity=(val)
    @sprite.opacity=val
    self.formatShadow
  end
  def tone=(val)
    @sprite.tone=val
  end
  def color=(val)
    @sprite.color=val
    if @fp
      for key in @fp.keys
        @fp[key].color=val
      end
    end
  end
  def blend_type=(val)
    @sprite.blend_type=val
    self.formatShadow
  end
  def angle=(val)
    @sprite.angle=(val)
    self.formatShadow
  end
  def mirror=(val)
    @sprite.mirror=(val)
    self.formatShadow
  end
  def dispose
    @sprite.dispose
    @shadow.dispose
  @overlay.dispose
  @substitute.dispose if @substitute
    pbDisposeSpriteHash(@fp) if @fp
  end
  def selected=(val)
    @selected=val
    @sprite.visible=true if !@hidden
  end
  def toneAll(val)
    @sprite.tone.red+=val
    @sprite.tone.green+=val
    @sprite.tone.blue+=val
  end
  
  def setBitmap(file,shadow=false)
    self.resetParticles
    @showshadow = shadow
    @bitmap = AnimatedBitmapWrapper.new(file)
    @sprite.bitmap = @bitmap.bitmap.clone
    @shadow.bitmap = @bitmap.bitmap.clone    
    @loaded = true
    self.formatShadow
  end
  
  def setPokemonBitmap(pokemon,back=false,species=nil)
    self.resetParticles
    return if !pokemon || pokemon.nil?
    @pokemon = pokemon
    @isShadow = true if @pokemon.isShadow?
    @altitude = @metrics[2][pokemon.species]
    if back
      @yposition = @metrics[0][pokemon.species]
      @altitude *= 0.5
    else
      @yposition = @metrics[1][pokemon.species]
    end
    scale = back ? BACKSPRITESCALE : POKEMONSPRITESCALE
    if !species.nil?
      @bitmap = pbLoadPokemonBitmapSpecies(pokemon,species,back,scale)
    else
      @bitmap = pbLoadPokemonBitmap(pokemon,back,scale)
    end
    @sprite.bitmap = @bitmap.bitmap.clone
    @shadow.bitmap = @bitmap.bitmap.clone
    @sprite.ox = @bitmap.width/2
    @sprite.oy = @bitmap.height
    @sprite.oy += @altitude
    @sprite.oy -= @yposition
    @sprite.oy -= pokemon.formOffsetY if pokemon.respond_to?(:formOffsetY)
    
    @fainted = false
    @loaded = true
    @hidden = false
    self.visible = true
    @pulse = 8
    @k = 1
    self.formatShadow
  end
  
  def resetParticles
    if @fp
      for key in @fp.keys
        @fp[key].visible = false
      end
    end
    @isShadow = false
    @charged = false
  end
  
  def refreshMetrics(metrics)
    @metrics = metrics
    @altitude = @metrics[2][@pokemon.species]
    if (@index%2==0)
      @yposition = @metrics[0][@pokemon.species]
      @altitude *= 0.5
    else
      @yposition = @metrics[1][@pokemon.species]
    end
    
    @sprite.ox = @bitmap.width/2
    @sprite.oy = @bitmap.height
    @sprite.oy += @altitude
    @sprite.oy -= @yposition
    @sprite.oy -= @pokemon.formOffsetY if @pokemon.respond_to?(:formOffsetY)
  end
  
  def setSubstitute
    @isSub = true
    @sprite.bitmap = @substitute.bitmap.clone
    @shadow.bitmap = @substitute.bitmap.clone
    @sprite.ox = @substitute.width/2
    @sprite.oy = @substitute.height
    self.formatShadow
  end
  
  def removeSubstitute
    @isSub = false
    @sprite.bitmap = @bitmap.bitmap.clone
    @shadow.bitmap = @bitmap.bitmap.clone
    @sprite.ox = @bitmap.width/2
    @sprite.oy = @bitmap.height
    @sprite.oy += @altitude
    @sprite.oy -= @yposition
    @sprite.oy -= @pokemon.formOffsetY if @pokemon && @pokemon.respond_to?(:formOffsetY)
    self.formatShadow
  end
  
  def still
    @still = true
  end
  
  def clear
    @sprite.bitmap.clear
    @bitmap.dispose
  end
  
  def formatShadow
    @shadow.zoom_x = @sprite.zoom_x*0.90
    @shadow.zoom_y = @sprite.zoom_y*0.30
    @shadow.ox = @sprite.ox - 6
    @shadow.oy = @sprite.oy - 6
    @shadow.opacity = @sprite.opacity*0.3
    @shadow.tone = Tone.new(-255,-255,-255,255)
    @shadow.visible = @sprite.visible
    @shadow.mirror = @sprite.mirror
    @shadow.angle = @sprite.angle
    
    @shadow.visible = false if !@showshadow
  end
  
  def update(angle=74)
    if @still
      @still = false
      return
    end
    return if @lock
    return if !@bitmap || @bitmap.disposed?
    if @isSub
      @substitute.update
      @sprite.bitmap=@substitute.bitmap.clone
      @shadow.bitmap=@substitute.bitmap.clone
    else
      @bitmap.update
      @sprite.bitmap=@bitmap.bitmap.clone
      @shadow.bitmap=@bitmap.bitmap.clone
    end
    @shadow.skew(angle)
    if !@anim && !@pulse.nil?
      @pulse += @k
      @k *= -1 if @pulse == 128 || @pulse == 8
      case @status
      when 0
        @sprite.color = Color.new(0,0,0,0)
      when 1 #PSN
        @sprite.color = Color.new(109,55,130,@pulse)
      when 2 #PAR
        @sprite.color = Color.new(204,152,44,@pulse)
      when 3 #FRZ
        @sprite.color = Color.new(56,160,193,@pulse)
      when 4 #BRN
        @sprite.color = Color.new(206,73,43,@pulse)
      end
    end
    @anim = false
    # Pokꮯn sprite blinking when targeted or damaged
    @frame += 1
    @frame = 0 if @frame > 256
    if @selected==2 # When targeted or damaged
      @sprite.visible = (@frame%10<7) && !@hidden
    end
    self.formatShadow
  end  
  
  def shadowUpdate
    return if !@loaded
    return if self.disposed? || @bitmap.disposed?
    for i in 0...16
      next if i > @frame2/4
      @fp["#{i}"].visible = @showshadow
      @fp["#{i}"].visible = false if @hidden
      @fp["#{i}"].visible = false if !@isShadow
      next if !@isShadow
      if @fp["#{i}"].opacity <= 0
        @fp["#{i}"].toggle = 2
        z = [0.5,0.6,0.7,0.8,0.9,1.0][rand(6)]
        @fp["#{i}"].param = z
        @fp["#{i}"].x = self.x - self.bitmap.width*self.zoom_x/2 + rand(self.bitmap.width)*self.zoom_x
        @fp["#{i}"].y = self.y - 64*self.zoom_y + rand(64)*self.zoom_y
        @fp["#{i}"].z = (rand(2)==0) ? self.z - 1 : self.z + 1
        @fp["#{i}"].speed = (rand(2)==0) ? +1 : -1
        @fp["#{i}"].src_rect.x = rand(2)*@fp["#{i}"].bitmap.width/2
      end
      @fp["#{i}"].zoom_x = @fp["#{i}"].param*self.zoom_x
      @fp["#{i}"].zoom_y = @fp["#{i}"].param*self.zoom_y
      @fp["#{i}"].param -= 0.01
      @fp["#{i}"].y -= 1
      @fp["#{i}"].opacity += 8*@fp["#{i}"].toggle
      @fp["#{i}"].toggle = -1 if @fp["#{i}"].opacity >= 255
    end
    @frame2 += 1 if @frame2 < 128
  end
  
  def chargedUpdate
    return if !@loaded
    return if self.disposed? || @bitmap.disposed?
    for i in 0...16
      next if i > @frame3/16
      @fp["c#{i}"].visible = @showshadow
      @fp["c#{i}"].visible = false if @hidden
      @fp["c#{i}"].visible = false if !@charged
      next if !@charged
      if @fp["c#{i}"].opacity <= 0
        x = @sprite.x - @sprite.ox + rand(@sprite.bitmap.width)
        y = @sprite.y - @sprite.oy*0.7 + rand(@sprite.bitmap.height*0.8)
        @fp["c#{i}"].x = x
        @fp["c#{i}"].y = y
        @fp["c#{i}"].z = (rand(2)==0) ? self.z - 1 : self.z + 1
        @fp["c#{i}"].src_rect.x = rand(4)*@fp["c#{i}"].bitmap.width/4
        @fp["c#{i}"].zoom_y = 0.6
        @fp["c#{i}"].opacity = 166 + rand(90)
        @fp["c#{i}"].mirror = (x < @sprite.x) ? false : true
      end
      @fp["c#{i}"].zoom_y += 0.1
      @fp["c#{i}"].opacity -= 16
    end
    for j in 0...4
      next if j > @frame3/32
      @fp["r#{j}"].visible = @showshadow
      @fp["r#{j}"].visible = false if @hidden
      @fp["r#{j}"].visible = false if !@charged
      if @fp["r#{j}"].opacity <= 0
        @fp["r#{j}"].opacity = 255
        @fp["r#{j}"].zoom_x = 0
        @fp["r#{j}"].zoom_y = 0
        @fp["r#{j}"].param = 0
      end
      @fp["r#{j}"].param += 0.01
      @fp["r#{j}"].zoom_x = @fp["r#{j}"].param*self.zoom_x
      @fp["r#{j}"].zoom_y = @fp["r#{j}"].param*self.zoom_x
      @fp["r#{j}"].x = self.x
      @fp["r#{j}"].y = self.y
      @fp["r#{j}"].opacity -= 2
    end
    @frame3 += 1 if @frame3 < 256
  end
end
#-------------------------------------------------------------------------------
#  Animated trainer sprites
#-------------------------------------------------------------------------------
class DynamicTrainerSprite  <  DynamicPokemonSprite
  
  def initialize(doublebattle,index,viewport=nil,trarray=false)
    @viewport=viewport
    @trarray=trarray
    @selected=0
    @frame=0
    @frame2=0
    
    @status=0
    @loaded=false
    @index=index
    @doublebattle=doublebattle
    @showshadow=true
    @altitude=0
    @yposition=0
    @shadow=Sprite.new(@viewport)
    @sprite=Sprite.new(@viewport)
    @overlay=Sprite.new(@viewport)
    @lock=false
  end
  
  def totalFrames; @bitmap.animationFrames; end
  def toLastFrame 
    @bitmap.toFrame(@bitmap.totalFrames-1)
    self.update
  end
  def selected; end
    
  def setTrainerBitmap(file)
    @bitmap=AnimatedBitmapWrapper.new(file,TRAINERSPRITESCALE)
    @sprite.bitmap=@bitmap.bitmap.clone
    @shadow.bitmap=@bitmap.bitmap.clone
    @sprite.ox=@bitmap.width/2
    if @doublebattle && @trarray
      if @index==-2
        @sprite.ox-=50
      elsif @index==-1
        @sprite.ox+=50
      end
    end
    @sprite.oy=@bitmap.height-16
    
    self.formatShadow
    @shadow.skew(74)
  end

end
#-------------------------------------------------------------------------------
#  New class used to configure and animate battle backgrounds
#-------------------------------------------------------------------------------
class AnimatedBattleBackground < Sprite
  
  def setBitmap(backdrop,scene)
    blur = 4; blur = BLURBATTLEBACKGROUND if BLURBATTLEBACKGROUND.is_a?(Numeric)
    @eff = {}
    @scene = scene
    if $INEDITOR
      @defaultvector = VECTOR1
    else
      @defaultvector = (@scene.battle.doublebattle ? VECTOR2 : VECTOR1)
    end
    @canAnimate = !pbResolveBitmap("Graphics/BattleBacks/Animation/eff1"+backdrop).nil?
    bg = pbBitmap("Graphics/BattleBacks/battlebg/"+backdrop)
    @bmp = Bitmap.new(bg.width*BACKGROUNDSCALAR,bg.width*BACKGROUNDSCALAR)
    @bmp.stretch_blt(Rect.new(0,0,@bmp.width,@bmp.height),bg,Rect.new(0,0,bg.width,bg.height))
    self.bitmap = @bmp.clone
    self.blur_sprite(blur) if BLURBATTLEBACKGROUND
    sx, sy = @scene.vector.spoof(@defaultvector)
    self.ox = 256 + sx
    self.oy = 192 + sy
    for i in 1..3
      next if !@canAnimate
      @eff["#{i}"] = Sprite.new(self.viewport)
      bmp = pbBitmap("Graphics/BattleBacks/Animation/eff#{i}"+backdrop)
      @eff["#{i}"].bitmap = Bitmap.new(@bmp.width*2,@bmp.height)
      @eff["#{i}"].bitmap.stretch_blt(Rect.new(0,0,@bmp.width*2,@bmp.height),bmp,Rect.new(0,0,bmp.width,bmp.height))
      @eff["#{i}"].src_rect.set([0,128,0,-128][i]*BACKGROUNDSCALAR,0,bmp.width*BACKGROUNDSCALAR/2,bmp.height*BACKGROUNDSCALAR)
      @eff["#{i}"].ox = self.ox
      @eff["#{i}"].oy = self.oy
      @eff["#{i}"].blur_sprite(blur) if BLURBATTLEBACKGROUND
    end
    self.update
  end
  
  def update
    if @canAnimate
      @eff["1"].src_rect.x -= 1
      @eff["1"].src_rect.x = 512*BACKGROUNDSCALAR if @eff["1"].src_rect.x <= -256*BACKGROUNDSCALAR
      @eff["2"].src_rect.x += 1
      @eff["2"].src_rect.x = -256*BACKGROUNDSCALAR if @eff["2"].src_rect.x >= 512*BACKGROUNDSCALAR
      @eff["3"].src_rect.x -= 2
      @eff["3"].src_rect.x = 512*BACKGROUNDSCALAR if @eff["3"].src_rect.x <= -256*BACKGROUNDSCALAR
    end    
    # coordinates
    self.x = @scene.vector.x2
    self.y = @scene.vector.y2
    self.angle = ((@scene.vector.angle - @defaultvector[2])*0.5).to_i if $PokemonSystem.screensize < 2 && @scene.sendingOut
    sx, sy = @scene.vector.spoof(@defaultvector)
    self.zoom_x = ((@scene.vector.x2 - @scene.vector.x)*1.0/(sx - @defaultvector[0])*1.0)**0.6
    self.zoom_y = ((@scene.vector.y2 - @scene.vector.y)*1.0/(sy - @defaultvector[1])*1.0)**0.6
    for i in 1..3
      next if !@canAnimate
      @eff["#{i}"].x = self.x
      @eff["#{i}"].y = self.y
      @eff["#{i}"].zoom_x = self.zoom_x
      @eff["#{i}"].zoom_y = self.zoom_y
      @eff["#{i}"].visible = true
      @eff["#{i}"].tone = self.tone
      if self.angle!=0
        @eff["#{i}"].opacity -= 51
      else
        @eff["#{i}"].opacity += 51
      end
    end
  end
  
  alias dispose_bg_ebs dispose unless self.method_defined?(:dispose_bg_ebs)
  def dispose
    pbDisposeSpriteHash(@eff)
    dispose_bg_ebs
  end
  
  alias :color_bg= :color= unless self.method_defined?(:color_bg=)
  def color=(val)
    for i in 1..3
      next if !@canAnimate
      @eff["#{i}"].color = val
    end
    self.color_bg = val
  end
end
#===============================================================================
#  New functions for the Sprite class
#  adds new bitmap transformations
#===============================================================================
def setPictureSpriteEB(sprite,picture)
  sprite.visible = picture.visible
  # Set sprite coordinates
  sprite.y = picture.y
  sprite.z = picture.number
  # Set zoom rate, opacity level, and blend method
  sprite.zoom_x = picture.zoom_x / 100.0
  sprite.zoom_y = picture.zoom_y / 100.0
  sprite.opacity = picture.opacity
  sprite.blend_type = picture.blend_type
  # Set rotation angle and color tone
  angle = picture.angle
  sprite.tone = picture.tone
  sprite.color = picture.color
  while angle < 0
    angle += 360
  end
  angle %= 360
  sprite.angle=angle
end
#-------------------------------------------------------------------------------
#  New class used to render the Sun & Moon styled VS background
#-------------------------------------------------------------------------------
class SunMoonDefaultBackground
  attr_reader :speed
  # main method to create the background
  def initialize(viewport,trainerid,evilteam=false,teamskull=false)
    @viewport = viewport
    @trainerid = trainerid
    @evilteam = evilteam
    @teamskull = teamskull
    @disposed = false
    @speed = 1
    @sprites = {}
    # reverts to default
    bg = ["Graphics/Transitions/SunMoon/Default/background",
          "Graphics/Transitions/SunMoon/Default/layer",
          "Graphics/Transitions/SunMoon/Default/final"
         ]
    # gets specific graphics
    for i in 0...3
      str = sprintf("%s%03d",bg[i],trainerid)
      evl = bg[i] + "Evil"
      skl = bg[i] + "Skull"
      bg[i] = evl if pbResolveBitmap(evl) && @evilteam
      bg[i] = skl if pbResolveBitmap(skl) && @teamskull
      bg[i] = str if pbResolveBitmap(str)
    end
    # creates the 3 background layers
    for i in 0...3
      @sprites["bg#{i}"] = ScrollingSprite.new(@viewport)
      @sprites["bg#{i}"].setBitmap(bg[i],false,(i > 0))
      @sprites["bg#{i}"].z = 200
      @sprites["bg#{i}"].ox = @sprites["bg#{i}"].src_rect.width/2
      @sprites["bg#{i}"].oy = @sprites["bg#{i}"].src_rect.height/2
      @sprites["bg#{i}"].x = viewport.rect.width/2
      @sprites["bg#{i}"].y = viewport.rect.height/2
      @sprites["bg#{i}"].angle = - 8 if $PokemonSystem.screensize < 2
      @sprites["bg#{i}"].color = Color.new(0,0,0)
    end
  end
  # sets the speed of the sprites
  def speed=(val)
    for i in 0...3
      @sprites["bg#{i}"].speed = val*(i + 1)
    end
  end
  # updates the background
  def update
    return if self.disposed?
    for i in 0...3
      @sprites["bg#{i}"].update
    end
  end
  # used to fade in from black
  def reduceAlpha(factor)
    for i in 0...3
      @sprites["bg#{i}"].color.alpha -= factor
    end
  end
  # disposes of everything
  def dispose
    @disposed = true
    pbDisposeSpriteHash(@sprites)
  end
  # checks if disposed
  def disposed?; return @disposed; end
  # used to show other elements
  def show; end
end
#-------------------------------------------------------------------------------
#  New class used to render the special Sun & Moon styled VS background
#-------------------------------------------------------------------------------
class SunMoonSpecialBackground
  attr_reader :speed
  # main method to create the background
  def initialize(viewport,trainerid,evilteam=false)
    @viewport = viewport
    @trainerid = trainerid
    @evilteam = evilteam
    @disposed = false
    @speed = 1
    @sprites = {}
    # creates the background
    @sprites["background"] = RainbowSprite.new(@viewport)
    @sprites["background"].setBitmap("Graphics/Transitions/SunMoon/Special/background")
    @sprites["background"].color = Color.new(0,0,0)
    @sprites["background"].z = 200
    # handles the particles for the animation
    @vsFp = {}
    @fpDx = []
    @fpDy = []
    @fpIndex = 0
    # loads ring effect
    @sprites["ring"] = Sprite.new(@viewport)
    @sprites["ring"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Special/ring")
    @sprites["ring"].ox = @sprites["ring"].bitmap.width/2
    @sprites["ring"].oy = @sprites["ring"].bitmap.height/2
    @sprites["ring"].x = @viewport.rect.width/2
    @sprites["ring"].y = @viewport.rect.height
    @sprites["ring"].zoom_x = 0
    @sprites["ring"].zoom_y = 0
    @sprites["ring"].z = 500
    @sprites["ring"].visible = false
    @sprites["ring"].color = Color.new(0,0,0)
    # loads sparkle particles
    for j in 0...32
      @sprites["s#{j}"] = Sprite.new(@viewport)
      @sprites["s#{j}"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Special/particle")
      @sprites["s#{j}"].ox = @sprites["s#{j}"].bitmap.width/2
      @sprites["s#{j}"].oy = @sprites["s#{j}"].bitmap.height/2
      @sprites["s#{j}"].opacity = 0
      @sprites["s#{j}"].z = 220
      @sprites["s#{j}"].color = Color.new(0,0,0)
      @fpDx.push(0)
      @fpDy.push(0)
    end
    @fpSpeed = []
    @fpOpac = []
    # loads scrolling particles
    for j in 0...3
      k = j+1
      speed = 2 + rand(5)
      @sprites["p#{j}"] = ScrollingSprite.new(@viewport)
      @sprites["p#{j}"].setBitmap("Graphics/Transitions/SunMoon/Special/glow#{j}")
      @sprites["p#{j}"].speed = speed*4
      @sprites["p#{j}"].direction = -1
      @sprites["p#{j}"].opacity = 0
      @sprites["p#{j}"].z = 220
      @sprites["p#{j}"].zoom_y = 1 + rand(10)*0.005
      @sprites["p#{j}"].color = Color.new(0,0,0)
      @fpSpeed.push(speed)
      @fpOpac.push(4) if j > 0
    end
  end
  # sets the speed of the sprites
  def speed=(val)
    val = 16 if val > 16
    for j in 0...3
      @sprites["p#{j}"].speed = val*2
    end
  end
  # updates the background
  def update
    return if self.disposed?
    # updates background
    @sprites["background"].update
    # updates ring
    if @sprites["ring"].visible && @sprites["ring"].opacity > 0
      @sprites["ring"].zoom_x += 0.2
      @sprites["ring"].zoom_y += 0.2
      @sprites["ring"].opacity -= 16
    end
    # updates sparkle particles
    for j in 0...32
      next if !@sprites["ring"].visible
      next if !@sprites["s#{j}"] || @sprites["s#{j}"].disposed?
      next if j > @fpIndex/4
      if @sprites["s#{j}"].opacity <= 1
        width = @viewport.rect.width
        height = @viewport.rect.height
        x = rand(width*0.75) + width*0.125
        y = rand(height*0.50) + height*0.25
        @fpDx[j] = x + rand(width*0.125)*(x < width/2 ? -1 : 1)
        @fpDy[j] = y - rand(height*0.25)
        z = [1,0.75,0.5,0.25][rand(4)]
        @sprites["s#{j}"].zoom_x = z
        @sprites["s#{j}"].zoom_y = z
        @sprites["s#{j}"].x = x
        @sprites["s#{j}"].y = y
        @sprites["s#{j}"].opacity = 255
        @sprites["s#{j}"].angle = rand(360)
      end
      @sprites["s#{j}"].x -= (@sprites["s#{j}"].x - @fpDx[j])*0.05
      @sprites["s#{j}"].y -= (@sprites["s#{j}"].y - @fpDy[j])*0.05
      @sprites["s#{j}"].opacity -= @sprites["s#{j}"].opacity*0.05
      @sprites["s#{j}"].zoom_x -= @sprites["s#{j}"].zoom_x*0.05
      @sprites["s#{j}"].zoom_y -= @sprites["s#{j}"].zoom_y*0.05
    end
    # updates scrolling particles
    for j in 0...3
      next if !@sprites["p#{j}"] || @sprites["p#{j}"].disposed?
      @sprites["p#{j}"].update
      if j == 0
        @sprites["p#{j}"].opacity += 5 if @sprites["p#{j}"].opacity < 155
      else
        @sprites["p#{j}"].opacity += @fpOpac[j-1]*(@fpSpeed[j]/2)
      end
      next if @fpIndex < 24
      @fpOpac[j-1] *= -1 if (@sprites["p#{j}"].opacity >= 255 || @sprites["p#{j}"].opacity < 65)
    end
    @fpIndex += 1 if @fpIndex < 150
  end
  # used to fade in from black
  def reduceAlpha(factor)
    for key in @sprites.keys
      @sprites[key].color.alpha -= factor
    end
  end
  # disposes of everything
  def dispose
    @disposed = true
    pbDisposeSpriteHash(@sprites)
  end
  # checks if disposed
  def disposed?; return @disposed; end
  # used to show other elements
  def show
    for j in 0...3
      @sprites["p#{j}"].visible = true
    end
    @sprites["ring"].visible = true
    @fpIndex = 0
  end
end
#-------------------------------------------------------------------------------
#  New class used to render the Sun & Moon kahuna VS background
#-------------------------------------------------------------------------------
class SunMoonEliteBackground
  attr_reader :speed
  # main method to create the background
  def initialize(viewport,trainerid,evilteam=false)
    @viewport = viewport
    @trainerid = trainerid
    @evilteam = evilteam
    @disposed = false
    @speed = 1
    @sprites = {}
    @fpIndex = 0
    # checks for appropriate files
    bg = ["Graphics/Transitions/SunMoon/Elite/background",
          "Graphics/Transitions/SunMoon/Elite/vacuum"
         ]
    for i in 0...2
      str = sprintf("%s%03d",bg[i],trainerid)
      bg[i] = str if pbResolveBitmap(str)
    end
    # creates the background
    @sprites["background"] = Sprite.new(@viewport)
    @sprites["background"].bitmap = pbBitmap(bg[0])
    @sprites["background"].center
    @sprites["background"].x = @viewport.rect.width/2
    @sprites["background"].y = @viewport.rect.height/2
    @sprites["background"].color = Color.new(0,0,0)
    @sprites["background"].z = 200
    # creates particles flying out of the center
    for j in 0...16
      @sprites["e#{j}"] = Sprite.new(@viewport)
      bmp = pbBitmap("Graphics/Transitions/SunMoon/Elite/particle")
      @sprites["e#{j}"].bitmap = Bitmap.new(bmp.width,bmp.height)
      w = bmp.width/(1 + rand(3))
      @sprites["e#{j}"].bitmap.stretch_blt(Rect.new(0,0,w,bmp.height),bmp,Rect.new(0,0,bmp.width,bmp.height))
      @sprites["e#{j}"].oy = @sprites["e#{j}"].bitmap.height/2
      @sprites["e#{j}"].angle = rand(360)
      @sprites["e#{j}"].opacity = 0
      @sprites["e#{j}"].x = @viewport.rect.width/2
      @sprites["e#{j}"].y = @viewport.rect.height/2
      @sprites["e#{j}"].speed = (4 + rand(5))
      @sprites["e#{j}"].z = 220
      @sprites["e#{j}"].color = Color.new(0,0,0)
    end
    # creates vacuum waves
    for j in 0...3
      @sprites["ec#{j}"] = Sprite.new(@viewport)
      @sprites["ec#{j}"].bitmap = pbBitmap(bg[1])
      @sprites["ec#{j}"].ox = @sprites["ec#{j}"].bitmap.width/2
      @sprites["ec#{j}"].oy = @sprites["ec#{j}"].bitmap.height/2
      @sprites["ec#{j}"].x = @viewport.rect.width/2
      @sprites["ec#{j}"].y = @viewport.rect.height/2
      @sprites["ec#{j}"].zoom_x = 1.5
      @sprites["ec#{j}"].zoom_y = 1.5
      @sprites["ec#{j}"].opacity = 0
      @sprites["ec#{j}"].z = 205
      @sprites["ec#{j}"].color = Color.new(0,0,0)
    end
    # creates center glow
    @sprites["shine"] = Sprite.new(@viewport)
    @sprites["shine"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Elite/shine")
    @sprites["shine"].ox = @sprites["shine"].src_rect.width/2
    @sprites["shine"].oy = @sprites["shine"].src_rect.height/2
    @sprites["shine"].x = @viewport.rect.width/2
    @sprites["shine"].y = @viewport.rect.height/2
    @sprites["shine"].z = 210
    @sprites["shine"].visible = false
  end
  # sets the speed of the sprites
  def speed=(val); end
  # updates the background
  def update
    return if self.disposed?
    # background and shine
    @sprites["background"].angle += 1 if $PokemonSystem.screensize < 2
    @sprites["shine"].angle -= 1 if $PokemonSystem.screensize < 2
    # updates (and resets) the particles flying from the center
    for j in 0...16
      next if !@sprites["shine"].visible
      if @sprites["e#{j}"].ox < -(@sprites["e#{j}"].viewport.rect.width/2)
        @sprites["e#{j}"].speed = 4 + rand(5)
        @sprites["e#{j}"].opacity = 0
        @sprites["e#{j}"].ox = 0
        @sprites["e#{j}"].angle = rand(360)
        bmp = pbBitmap("Graphics/Transitions/SunMoon/Elite/particle")
        @sprites["e#{j}"].bitmap.clear
        w = bmp.width/(1 + rand(3))
        @sprites["e#{j}"].bitmap.stretch_blt(Rect.new(0,0,w,bmp.height),bmp,Rect.new(0,0,bmp.width,bmp.height))
      end
      @sprites["e#{j}"].opacity += @sprites["e#{j}"].speed
      @sprites["e#{j}"].ox -=  @sprites["e#{j}"].speed
    end
    # updates the vacuum waves
    for j in 0...3
      next if j > @fpIndex/50
      if @sprites["ec#{j}"].zoom_x <= 0
        @sprites["ec#{j}"].zoom_x = 1.5
        @sprites["ec#{j}"].zoom_y = 1.5
        @sprites["ec#{j}"].opacity = 0
      end
      @sprites["ec#{j}"].opacity +=  8
      @sprites["ec#{j}"].zoom_x -= 0.01
      @sprites["ec#{j}"].zoom_y -= 0.01
    end
    @fpIndex += 1 if @fpIndex < 150
  end
  # used to show other elements
  def show
    @sprites["shine"].visible = true
  end
  # used to fade in from black
  def reduceAlpha(factor)
    for key in @sprites.keys
      @sprites[key].color.alpha -= factor
    end
  end
  # disposes of everything
  def dispose
    @disposed = true
    pbDisposeSpriteHash(@sprites)
  end
  # checks if disposed
  def disposed?; return @disposed; end
  
end
#-------------------------------------------------------------------------------
#  New class used to render the Mother Beast Lusamine styled VS background
#-------------------------------------------------------------------------------
class SunMoonCrazyBackground
  attr_accessor :speed
  # main method to create the background
  def initialize(viewport,trainerid,evilteam=false)
    @viewport = viewport
    @trainerid = trainerid
    @evilteam = evilteam
    @disposed = false
    @speed = 1
    @sprites = {}
    # draws a black backdrop
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].drawRect(@viewport.rect.width,@viewport.rect.height,Color.new(0,0,0))
    @sprites["bg"].z = 200
    @sprites["bg"].color = Color.new(0,0,0)
    # draws the 3 circular patterns that change hue
    for j in 0...3
      @sprites["b#{j}"] = RainbowSprite.new(@viewport)
      @sprites["b#{j}"].setBitmap("Graphics/Transitions/SunMoon/Crazy/ring#{j}",8)
      @sprites["b#{j}"].ox = @sprites["b#{j}"].bitmap.width/2
      @sprites["b#{j}"].oy = @sprites["b#{j}"].bitmap.height/2
      @sprites["b#{j}"].x = @viewport.rect.width/2
      @sprites["b#{j}"].y = @viewport.rect.height/2
      @sprites["b#{j}"].zoom_x = 0.6 + 0.6*j
      @sprites["b#{j}"].zoom_y = 0.6 + 0.6*j
      @sprites["b#{j}"].opacity = 64 + 64*(1+j)
      @sprites["b#{j}"].z = 250
      @sprites["b#{j}"].color = Color.new(0,0,0)
    end
    # draws all the particles
    for j in 0...64
      @sprites["p#{j}"] = Sprite.new(@viewport)
      @sprites["p#{j}"].z = 300
      width = 16 + rand(48)
      height = 16 + rand(16)
      @sprites["p#{j}"].bitmap = Bitmap.new(width,height)
      bmp = pbBitmap("Graphics/Transitions/SunMoon/Crazy/particle")
      @sprites["p#{j}"].bitmap.stretch_blt(Rect.new(0,0,width,height),bmp,Rect.new(0,0,bmp.width,bmp.height))
      @sprites["p#{j}"].bitmap.hue_change(rand(360))
      @sprites["p#{j}"].ox = width/2
      @sprites["p#{j}"].oy = height + 192 + rand(32)
      @sprites["p#{j}"].angle = rand(360)
      @sprites["p#{j}"].speed = 1 + rand(4)
      @sprites["p#{j}"].x = @viewport.rect.width/2
      @sprites["p#{j}"].y = @viewport.rect.height/2
      @sprites["p#{j}"].zoom_x = (@sprites["p#{j}"].oy/192.0)*1.5
      @sprites["p#{j}"].zoom_y = (@sprites["p#{j}"].oy/192.0)*1.5
      @sprites["p#{j}"].color = Color.new(0,0,0)
    end
    @frame = 0
  end
  # sets the speed of the sprites
  def speed=(val); end
  # updates the background
  def update
    return if self.disposed?
    # updates the 3 circular patterns changing their hue
    for j in 0...3
      @sprites["b#{j}"].zoom_x -= 0.025
      @sprites["b#{j}"].zoom_y -= 0.025
      @sprites["b#{j}"].opacity -= 4
      if @sprites["b#{j}"].zoom_x <= 0 || @sprites["b#{j}"].opacity <= 0
        @sprites["b#{j}"].zoom_x = 2.25
        @sprites["b#{j}"].zoom_y = 2.25
        @sprites["b#{j}"].opacity = 255
      end
      @sprites["b#{j}"].update if @frame%8==0
    end
    # animates all the particles
    for j in 0...64
      @sprites["p#{j}"].angle -= @sprites["p#{j}"].speed
      @sprites["p#{j}"].opacity -= @sprites["p#{j}"].speed
      @sprites["p#{j}"].oy -= @sprites["p#{j}"].speed/2 if @sprites["p#{j}"].oy > @sprites["p#{j}"].bitmap.height
      @sprites["p#{j}"].zoom_x = (@sprites["p#{j}"].oy/192.0)*1.5
      @sprites["p#{j}"].zoom_y = (@sprites["p#{j}"].oy/192.0)*1.5
      if @sprites["p#{j}"].zoom_x <= 0 || @sprites["p#{j}"].oy <= 0 || @sprites["p#{j}"].opacity <= 0
        @sprites["p#{j}"].angle = rand(360)
        @sprites["p#{j}"].oy = @sprites["p#{j}"].bitmap.height + 192 + rand(32)
        @sprites["p#{j}"].zoom_x = (@sprites["p#{j}"].oy/192.0)*1.5
        @sprites["p#{j}"].zoom_y = (@sprites["p#{j}"].oy/192.0)*1.5
        @sprites["p#{j}"].opacity = 255
        @sprites["p#{j}"].speed = 1 + rand(4)
      end
    end
    @frame += 1
    @frame = 0 if @frame > 128
  end
  # used to fade in from black
  def reduceAlpha(factor)
    for key in @sprites.keys
      @sprites[key].color.alpha -= factor
    end
  end
  # disposes of everything
  def dispose
    @disposed = true
    pbDisposeSpriteHash(@sprites)
  end
  # checks if disposed
  def disposed?; return @disposed; end
  # used to show other elements
  def show; end
  
end
#-------------------------------------------------------------------------------
#  New class used to render the ultra squad Sun & Moon styled VS background
#-------------------------------------------------------------------------------
class SunMoonUltraBackground
  attr_reader :speed
  # main method to create the background
  def initialize(viewport,trainerid,evilteam=false)
    @viewport = viewport
    @trainerid = trainerid
    @evilteam = evilteam
    @disposed = false
    @speed = 1
    @fpIndex = 0
    @sprites = {}
    # creates the background layer
    @sprites["background"] = RainbowSprite.new(@viewport)
    @sprites["background"].setBitmap("Graphics/Transitions/SunMoon/Ultra/background",2)
    @sprites["background"].color = Color.new(0,0,0)
    @sprites["background"].z = 200
    @sprites["paths"] = RainbowSprite.new(@viewport)
    @sprites["paths"].setBitmap("Graphics/Transitions/SunMoon/Ultra/overlay",2)
    @sprites["paths"].center
    @sprites["paths"].x = @viewport.rect.width/2
    @sprites["paths"].y = @viewport.rect.height/2
    @sprites["paths"].color = Color.new(0,0,0)
    @sprites["paths"].z = 200
    @sprites["paths"].opacity = 215
    @sprites["paths"].toggle = 1
    @sprites["paths"].visible = false
    # creates the shine effect
    @sprites["shine"] = Sprite.new(@viewport)
    @sprites["shine"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Ultra/shine")
    @sprites["shine"].center
    @sprites["shine"].x = @viewport.rect.width/2
    @sprites["shine"].y = @viewport.rect.height/2
    @sprites["shine"].color = Color.new(0,0,0)
    @sprites["shine"].z = 200
    # creates the hexagonal zoom patterns
    for i in 0...12
      @sprites["h#{i}"] = Sprite.new(@viewport)
      @sprites["h#{i}"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Ultra/ring")
      @sprites["h#{i}"].center
      @sprites["h#{i}"].x = @viewport.rect.width/2
      @sprites["h#{i}"].y = @viewport.rect.height/2
      @sprites["h#{i}"].color = Color.new(0,0,0)
      @sprites["h#{i}"].z = 220
      z = 1
      @sprites["h#{i}"].zoom_x = z
      @sprites["h#{i}"].zoom_y = z
      @sprites["h#{i}"].opacity = 255
    end
    for i in 0...16
      @sprites["p#{i}"] = Sprite.new(@viewport)
      @sprites["p#{i}"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Ultra/particle")
      @sprites["p#{i}"].oy = @sprites["p#{i}"].bitmap.height/2
      @sprites["p#{i}"].x = @viewport.rect.width/2
      @sprites["p#{i}"].y = @viewport.rect.height/2
      @sprites["p#{i}"].angle = rand(360)
      @sprites["p#{i}"].color = Color.new(0,0,0)
      @sprites["p#{i}"].z = 210
      @sprites["p#{i}"].visible = false
    end
    160.times do
      self.update(true)
    end
  end
  # sets the speed of the sprites
  def speed=(val)
  end
  # updates the background
  def update(skip=false)
    return if self.disposed?
    if !skip
      @sprites["background"].update
      @sprites["shine"].angle -= 1 if $PokemonSystem.screensize < 2
      @sprites["paths"].update
      @sprites["paths"].opacity -= @sprites["paths"].toggle*2
      @sprites["paths"].toggle *= -1 if @sprites["paths"].opacity <= 85 || @sprites["paths"].opacity >= 215
    end
    for i in 0...12
      next if i > @fpIndex/32
      if @sprites["h#{i}"].opacity <= 0
        @sprites["h#{i}"].zoom_x = 1
        @sprites["h#{i}"].zoom_y = 1
        @sprites["h#{i}"].opacity = 255
      end
      @sprites["h#{i}"].zoom_x += 0.003*(@sprites["h#{i}"].zoom_x**2)
      @sprites["h#{i}"].zoom_y += 0.003*(@sprites["h#{i}"].zoom_y**2)
      @sprites["h#{i}"].opacity -= 1
    end
    for i in 0...16
      next if i > @fpIndex/8
      if @sprites["p#{i}"].opacity <= 0
        @sprites["p#{i}"].ox = 0
        @sprites["p#{i}"].angle = rand(360)
        @sprites["p#{i}"].zoom_x = 1
        @sprites["p#{i}"].zoom_y = 1
        @sprites["p#{i}"].opacity = 255
      end
      @sprites["p#{i}"].opacity -= 2
      @sprites["p#{i}"].ox -= 4
      @sprites["p#{i}"].zoom_x += 0.001
      @sprites["p#{i}"].zoom_y += 0.001
    end
    @fpIndex += 1 if @fpIndex < 512
  end
  # used to fade in from black
  def reduceAlpha(factor)
    for key in @sprites.keys
      @sprites[key].color.alpha -= factor
    end
  end
  # disposes of everything
  def dispose
    @disposed = true
    pbDisposeSpriteHash(@sprites)
  end
  # checks if disposed
  def disposed?; return @disposed; end
  # used to show other elements
  def show
    for i in 0...16
      @sprites["p#{i}"].visible = true
    end
    @sprites["paths"].visible = true
  end
end
#-------------------------------------------------------------------------------
#  New class used to render a custom Sun & Moon styled VS background
#-------------------------------------------------------------------------------
class SunMoonDigitalBackground
  attr_reader :speed
  # main method to create the background
  def initialize(viewport,trainerid,evilteam=false)
    @viewport = viewport
    @trainerid = trainerid
    @evilteam = evilteam
    @disposed = false
    @speed = 1
    @sprites = {}
    @tiles = []
    @data = []
    @fpIndex = 0
    # allows for custom graphics as well
    files = ["Graphics/Transitions/SunMoon/Digital/background",
             "Graphics/Transitions/SunMoon/Digital/particle",
             "Graphics/Transitions/SunMoon/Digital/shine"
    ]
    for i in 0...files.length
      str = sprintf("%s%03d",files[i],trainerid)
      files[i] = str if pbResolveBitmap(str)
    end
    # creates the background layer
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].bitmap = pbBitmap(files[0])
    @sprites["bg"].z = 200
    @sprites["bg"].color = Color.new(0,0,0)
    for i in 0...16
      @sprites["p#{i}"] = Sprite.new(@viewport)
      @sprites["p#{i}"].bitmap = pbBitmap(files[1])
      @sprites["p#{i}"].z = 205
      @sprites["p#{i}"].color = Color.new(0,0,0)
      @sprites["p#{i}"].oy = @sprites["p#{i}"].bitmap.height/2
      @sprites["p#{i}"].x = @viewport.rect.width/2
      @sprites["p#{i}"].y = @viewport.rect.height/2
      @sprites["p#{i}"].angle = rand(16)*22.5
      @sprites["p#{i}"].visible = false
    end
    @sprites["shine"] = Sprite.new(@viewport)
    @sprites["shine"].bitmap = pbBitmap(files[2])
    @sprites["shine"].center
    @sprites["shine"].x = @viewport.rect.width/2
    @sprites["shine"].y = @viewport.rect.height/2
    @sprites["shine"].color = Color.new(0,0,0)
    @sprites["shine"].z = 210
    @sprites["shine"].toggle = 1
    # draws all the little tiles
    tile_size = 32.0
    opacity = 25
    offset = 2
    @x = (@viewport.rect.width/tile_size).ceil
    @y = (@viewport.rect.height/tile_size).ceil
    for i in 0...@x
      for j in 0...@y
        sprite = Sprite.new(@viewport)
        sprite.bitmap = Bitmap.new(tile_size,tile_size)
        sprite.bitmap.fill_rect(offset,offset,tile_size-offset*2,tile_size-offset*2,Color.new(255,255,255,opacity))
        sprite.x = i * tile_size
        sprite.y = j * tile_size
        sprite.color = Color.new(0,0,0)
        sprite.visible = false
        sprite.z = 220
        o = opacity + rand(156)
        sprite.opacity = 0
        @tiles.push(sprite)
        @data.push([o,rand(5)+4])
      end
    end
  end
  # sets the speed of the sprites
  def speed=(val)
  end
  # updates the background
  def update(skip=false)
    return if self.disposed?
    for i in 0...@tiles.length
      @tiles[i].opacity += @data[i][1]
      @data[i][1] *= -1 if @tiles[i].opacity <= 0 || @tiles[i].opacity >= @data[i][0]
    end
    for i in 0...16
      next if i > @fpIndex/16
      if @sprites["p#{i}"].ox < - @viewport.rect.width/2
        @sprites["p#{i}"].angle = rand(16)*22.5
        @sprites["p#{i}"].ox = 0
        @sprites["p#{i}"].opacity = 255
        @sprites["p#{i}"].zoom_x = 1
        @sprites["p#{i}"].zoom_y = 1
      end
      @sprites["p#{i}"].zoom_x += 0.001
      @sprites["p#{i}"].zoom_y += 0.001
      @sprites["p#{i}"].opacity -= 4
      @sprites["p#{i}"].ox -= 4
    end
    @sprites["shine"].zoom_x += 0.04*@sprites["shine"].toggle
    @sprites["shine"].zoom_y += 0.04*@sprites["shine"].toggle
    @sprites["shine"].toggle *= -1 if @sprites["shine"].zoom_x <= 1 || @sprites["shine"].zoom_x >= 1.4
    @fpIndex += 1 if @fpIndex < 256
  end
  # used to fade in from black
  def reduceAlpha(factor)
    for tile in @tiles
      tile.color.alpha -= factor
    end
    for key in @sprites.keys
      next if key == "bg"
      @sprites[key].color.alpha -= factor
    end
    self.update
  end
  # disposes of everything
  def dispose
    @disposed = true
    for tile in @tiles
      tile.dispose
    end
    pbDisposeSpriteHash(@sprites)
  end
  # checks if disposed
  def disposed?; return @disposed; end
  # used to show other elements
  def show
    for i in 0...16
      @sprites["p#{i}"].visible = true
    end
    for tile in @tiles
      tile.visible = true
    end
    @sprites["bg"].color.alpha = 0
  end
end
#-------------------------------------------------------------------------------
#  New class used to render a custom Sun & Moon styled VS background
#-------------------------------------------------------------------------------
class SunMoonPlasmaBackground
  attr_reader :speed
  # main method to create the background
  def initialize(viewport,trainerid,evilteam=false)
    @viewport = viewport
    @trainerid = trainerid
    @evilteam = evilteam
    @disposed = false
    @speed = 1
    @sprites = {}
    @tiles = []
    @data = []
    @fpIndex = 0
    # allows for custom graphics as well
    files = ["Graphics/Transitions/SunMoon/Plasma/background",
             "Graphics/Transitions/SunMoon/Plasma/beam",
             "Graphics/Transitions/SunMoon/Plasma/streaks",
             "Graphics/Transitions/SunMoon/Plasma/shine",
             "Graphics/Transitions/SunMoon/Plasma/particle"
    ]
    for i in 0...files.length
      str = sprintf("%s%03d",files[i],trainerid)
      files[i] = str if pbResolveBitmap(str)
    end
    # creates the background layer
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].bitmap = pbBitmap(files[0])
    @sprites["bg"].z = 200
    @sprites["bg"].color = Color.new(0,0,0)
    # creates plasma beam
    for i in 0...2
      @sprites["beam#{i}"] = ScrollingSprite.new(@viewport)
      @sprites["beam#{i}"].setBitmap(files[i+1])
      @sprites["beam#{i}"].speed = [32,48][i]
      @sprites["beam#{i}"].center
      @sprites["beam#{i}"].x = @viewport.rect.width/2
      @sprites["beam#{i}"].y = @viewport.rect.height/2 - 16
      @sprites["beam#{i}"].zoom_y = 0
      @sprites["beam#{i}"].z = 210
      @sprites["beam#{i}"].color = Color.new(0,0,0)
    end
    @sprites["shine"] = Sprite.new(@viewport)
    @sprites["shine"].bitmap = pbBitmap(files[3])
    @sprites["shine"].center
    @sprites["shine"].x = @viewport.rect.width
    @sprites["shine"].y = @viewport.rect.height/2 - 16
    @sprites["shine"].z = 220
    @sprites["shine"].visible = false
    @sprites["shine"].toggle = 1
    for i in 0...32
      @sprites["p#{i}"] = Sprite.new(@viewport)
      @sprites["p#{i}"].bitmap = pbBitmap(files[4])
      @sprites["p#{i}"].center
      @sprites["p#{i}"].opacity = 0
      @sprites["p#{i}"].z = 215
      @sprites["p#{i}"].visible = false
    end
  end
  # sets the speed of the sprites
  def speed=(val)
    @speed = val
  end
  # updates the background
  def update(skip=false)
    return if self.disposed?
    @sprites["shine"].angle += 8 if $PokemonSystem.screensize < 2
    @sprites["shine"].zoom_x -= 0.04*@sprites["shine"].toggle
    @sprites["shine"].zoom_y -= 0.04*@sprites["shine"].toggle
    @sprites["shine"].toggle *= -1 if @sprites["shine"].zoom_x <= 0.8 || @sprites["shine"].zoom_x >= 1.2
    for i in 0...2
      @sprites["beam#{i}"].update
    end
    for i in 0...32
      next if i > @fpIndex/4
      if @sprites["p#{i}"].opacity <= 0
        @sprites["p#{i}"].x = @sprites["shine"].x
        @sprites["p#{i}"].y = @sprites["shine"].y
        r = 256 + rand(129)
        cx, cy = randCircleCord(r)
        @sprites["p#{i}"].ex = @sprites["shine"].x - (cx - r).abs
        @sprites["p#{i}"].ey = @sprites["shine"].y - r/2 + cy/2
        z = 0.4 + rand(7)/10.0
        @sprites["p#{i}"].zoom_x = z
        @sprites["p#{i}"].zoom_y = z
        @sprites["p#{i}"].opacity = 255
      end
      @sprites["p#{i}"].opacity -= 8
      @sprites["p#{i}"].x -= (@sprites["p#{i}"].x - @sprites["p#{i}"].ex)*0.1
      @sprites["p#{i}"].y -= (@sprites["p#{i}"].y - @sprites["p#{i}"].ey)*0.1
    end
    @fpIndex += 1 if @fpIndex < 512
  end
  # used to fade in from black
  def reduceAlpha(factor)
    for key in @sprites.keys
      next if key == "bg"
      @sprites[key].color.alpha -= factor
    end
    for i in 0...2
      @sprites["beam#{i}"].zoom_y += 0.1 if @sprites["beam#{i}"].color.alpha <= 164 && @sprites["beam#{i}"].zoom_y < 1
    end
  end
  # disposes of everything
  def dispose
    @disposed = true
    pbDisposeSpriteHash(@sprites)
  end
  # checks if disposed
  def disposed?; return @disposed; end
  # used to show other elements
  def show
    @sprites["bg"].color.alpha = 0
    for key in @sprites.keys
      @sprites[key].visible = true
    end
  end
end
#-------------------------------------------------------------------------------
#  Utilities used for move animations
#-------------------------------------------------------------------------------
class PokeBattle_Scene  
  def getCenter(sprite,zoom=false)
    zoom = zoom ? sprite.zoom_y : 1
    x = sprite.x
    y = sprite.y + (sprite.bitmap.height-sprite.oy)*zoom - sprite.bitmap.height*zoom/2
    return x, y
  end
  
  def alignSprites(sprite,target)
    sprite.ox = sprite.src_rect.width/2
    sprite.oy = sprite.src_rect.height/2
    sprite.x, sprite.y = getCenter(target)
    sprite.zoom_x, sprite.zoom_y = target.zoom_x/2, target.zoom_y/2
  end
  
  def getRealVector(targetindex,player)
    vector = (player ? PLAYERVECTOR : ENEMYVECTOR).clone
    if @battle.doublebattle && !USEBATTLEBASES
      case targetindex
      when 0
        vector[0] = vector[0] + 80
      when 1
        vector[0] = vector[0] + 192
      when 2
        vector[0] = vector[0] - 64
      when 3
        vector[0] = vector[0] - 36
      end
    end
    return vector
  end
  
  def applySpriteProperties(sprite1,sprite2)
    sprite2.x = sprite1.x
    sprite2.y = sprite1.y
    sprite2.z = sprite1.z
    sprite2.zoom_x = sprite1.zoom_x
    sprite2.zoom_y = sprite1.zoom_y
    sprite2.opacity = sprite1.opacity
    sprite2.angle = sprite1.angle
    sprite2.tone = sprite1.tone
    sprite2.color = sprite1.color
    sprite2.visible = sprite1.visible
  end
end
#===============================================================================
#  Misc. scripting tools
#===============================================================================
def checkEBFolderPath
  if !pbResolveBitmap("Graphics/Pictures/EBS/pokeballs").nil?
    return "Graphics/Pictures/EBS"
  else
    return "Graphics/Pictures"
  end
end

def checkEBFolderPathDS
  if !pbResolveBitmap("Graphics/Pictures/EBS/DS/background").nil?
    return "Graphics/Pictures/EBS/DS"
  else
    return "Graphics/Pictures"
  end
end