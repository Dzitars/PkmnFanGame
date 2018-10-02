#===============================================================================
#  Elite Battle system
#    by Luka S.J.
# ----------------
#  BitmapWrapper Script
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
#  New animation methods for Pokemon sprites
#  * supports both animated, and static sprites
#  * does NOT support the usage of GIFs (officially)
#  * any one frame of sprite HAS to be of equal width and height
#  * all sprites need to be in 1*1 px resolution
#    or if you don't want to do that, you can change the value of
#    POKEMONSPRITESCALE to change the size of the bitmaps
#  * allows the use of custom looping points
#  Use dragonnite's(Lucy's) GIF to PNG converter to properly format your sprites
#===============================================================================
class AnimatedBitmapWrapper
  attr_reader :width
  attr_reader :height
  attr_reader :totalFrames
  attr_reader :animationFrames
  attr_reader :currentIndex
  attr_accessor :scale
  
  @@disableBitmapAnimation = false
  
  def initialize(file,scale=2)
    raise "filename is nil" if file==nil
    raise ".gif files are not supported!" if File.extname(file)==".gif"
    
    @scale = scale
    @width = 0
    @height = 0
    @frame = 0
    @frames = 2
    @direction = +1
    @animationFinish = false
    @totalFrames = 0
    @currentIndex = 0
    @speed = 1
      # 0 - not moving at all
      # 1 - normal speed
      # 2 - medium speed
      # 3 - slow speed
    bmp = BitmapCache.load_bitmap(file)
    @bitmapFile=Bitmap.new(bmp.width,bmp.height); @bitmapFile.blt(0,0,bmp,Rect.new(0,0,bmp.width,bmp.height))
  bmp.dispose
    # initializes full Pokemon bitmap
    @bitmap=Bitmap.new(@bitmapFile.width,@bitmapFile.height)
    @bitmap.blt(0,0,@bitmapFile,Rect.new(0,0,@bitmapFile.width,@bitmapFile.height))
    @width=@bitmapFile.height*@scale
    @height=@bitmap.height*@scale
    
    @totalFrames=@bitmap.width/@bitmap.height
    @animationFrames=@totalFrames*@frames
    # calculates total number of frames
    @loop_points=[0,@totalFrames]
    # first value is start, second is end
    
    @actualBitmap=Bitmap.new(@width,@height)
    @actualBitmap.clear
    @actualBitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmap,Rect.new(@currentIndex*(@width/@scale),0,@width/@scale,@height/@scale))
  end
  alias initialize_elite initialize unless self.method_defined?(:initialize_elite)
    
  def length; @totalFrames; end
  def disposed?; @actualBitmap.disposed?; end
  def dispose
    @bitmap.dispose
  @bitmapFile.dispose
    @actualBitmap.dispose
  end
  def copy; @actualBitmap.clone; end
  def bitmap; @actualBitmap; end
  def bitmap=(val); @actualBitmap=val; end
  def each; end
  def alterBitmap(index); return @strip[index]; end
    
  def prepareStrip
    @strip=[]
    for i in 0...@totalFrames
      bitmap=Bitmap.new(@width,@height)
      bitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmapFile,Rect.new((@width/@scale)*i,0,@width/@scale,@height/@scale))
      @strip.push(bitmap)
    end
  end
  def compileStrip
    @bitmap.clear
    for i in 0...@strip.length
      @bitmap.stretch_blt(Rect.new((@width/@scale)*i,0,@width/@scale,@height/@scale),@strip[i],Rect.new(0,0,@width,@height))
    end
  end
  
  def reverse
    if @direction  >  0
      @direction=-1
    elsif @direction < 0
      @direction=+1
    end
  end
  
  def setLoop(start, finish)
    @loop_points=[start,finish]
  end
  
  def setSpeed(value)
    @speed=value
  end
  
  def toFrame(frame)
    if frame.is_a?(String)
      if frame=="last"
        frame=@totalFrames-1
      else
        frame=0
      end
    end
    frame=@totalFrames if frame > @totalFrames
    frame=0 if frame < 0
    @currentIndex=frame
    @actualBitmap.clear
    @actualBitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmap,Rect.new(@currentIndex*(@width/@scale),0,@width/@scale,@height/@scale))
  end
  
  def play
    return if @currentIndex >= @loop_points[1]-1
    self.update
  end
  
  def finished?
    return (@currentIndex==@totalFrames-1)
  end
  
  def update
  return false if @@disableBitmapAnimation
    return false if @actualBitmap.disposed?
    return false if @speed < 1
    case @speed
    # frame skip
    when 1
      @frames=2
    when 2
      @frames=4
    when 3
      @frames=5
    end
    @frame+=1
    if @frame >= @frames
      # processes animation speed
      @currentIndex+=@direction
      @currentIndex=@loop_points[0] if @currentIndex >=@loop_points[1]
      @currentIndex=@loop_points[1]-1 if @currentIndex < @loop_points[0]
      @frame=0
    end
    @actualBitmap.clear
    @actualBitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmap,Rect.new(@currentIndex*(@width/@scale),0,@width/@scale,@height/@scale))
    # updates the actual bitmap
  end
  alias update_elite update unless self.method_defined?(:update_elite)
    
  # returns bitmap to original state
  def deanimate
    @frame=0
    @currentIndex=0
    @actualBitmap.clear
    @actualBitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmap,Rect.new(@currentIndex*(@width/@scale),0,@width/@scale,@height/@scale))
  end
end
#===============================================================================
#  New Sprite class to utilize the animated bitmap wrappers
#===============================================================================
class BitmapWrapperSprite < Sprite
  
  def setBitmap(file,scale=POKEMONSPRITESCALE)
    @animatedBitmap = AnimatedBitmapWrapper.new(file,scale)
    self.bitmap = @animatedBitmap.bitmap.clone
  end
  
  def setSpeciesBitmap(species,female=false,form=0,shiny=false,shadow=false,back=false,egg=false)
    if species > 0
      pokemon = PokeBattle_Pokemon.new(species,5)
      @animatedBitmap = pbLoadPokemonBitmapSpecies(pokemon, species, back)
    else
      @animatedBitmap = AnimatedBitmapWrapper.new("Graphics/Battlers/000")
    end
    self.bitmap = @animatedBitmap.bitmap.clone
  end
  
  def play
    @animatedBitmap.play
    self.bitmap = @animatedBitmap.bitmap.clone
  end
  
  def finished?; return @animatedBitmap.finished?; end
  def animatedBitmap; return @animatedBitmap; end
  
  alias update_wrapper update unless self.method_defined?(:update_wrapper)
  def update
    update_wrapper
    return if @animatedBitmap.nil?
    @animatedBitmap.update
    self.bitmap = @animatedBitmap.bitmap.clone
  end
  
end

class AnimatedSpriteWrapper < BitmapWrapperSprite; end
#===============================================================================
#  Aliases old PokemonBitmap generating functions and creates new ones,
#  utilizing the new BitmapWrapper
#===============================================================================
alias pbLoadPokemonBitmap_ebs pbLoadPokemonBitmap unless defined?(:pbLoadPokemonBitmap_ebs)
def pbLoadPokemonBitmap(pokemon, back=false,scale=POKEMONSPRITESCALE)
  return pbLoadPokemonBitmapSpecies(pokemon,pokemon.species,back,scale)
end

# Note: Returns an AnimatedBitmap, not a Bitmap
alias pbLoadPokemonBitmapSpecies_ebs pbLoadPokemonBitmapSpecies unless defined?(:pbLoadPokemonBitmapSpecies_ebs)
def pbLoadPokemonBitmapSpecies(pokemon, species, back=false, scale=POKEMONSPRITESCALE)
  ret=nil
  pokemon = pokemon.pokemon if pokemon.respond_to?(:pokemon)
  if pokemon.isEgg?
    bitmapFileName=sprintf("Graphics/Battlers/Eggs/%s",getConstantName(PBSpecies,species)) rescue nil
    if !pbResolveBitmap(bitmapFileName)
      bitmapFileName=sprintf("Graphics/Battlers/Eggs/%03d",species)
      if !pbResolveBitmap(bitmapFileName)
        bitmapFileName=sprintf("Graphics/Battlers/Eggs/000")
      end
    end
    bitmapFileName=pbResolveBitmap(bitmapFileName)
  else
    bitmapFileName=pbCheckPokemonBitmapFiles([species,back,
                                              (pokemon.isFemale?),
                                              pokemon.isShiny?,
                                              (pokemon.form rescue 0),
                                              (pokemon.isShadow? rescue false)])    
  end
  raise missingPokeSpriteError(pokemon,back) if bitmapFileName.nil?
  animatedBitmap=AnimatedBitmapWrapper.new(bitmapFileName,scale) if bitmapFileName
  ret=animatedBitmap if bitmapFileName
  # Full compatibility with the alterBitmap methods is maintained
  # but unless the alterBitmap method gets rewritten and sprite animations get
  # hardcoded in the system, the bitmap alterations will not function properly
  # as they will not account for the sprite animation itself
  
  # alterBitmap methods for static sprites will work just fine
  alterBitmap=(MultipleForms.getFunction(species,"alterBitmap") rescue nil) if !pokemon.isEgg? && animatedBitmap && animatedBitmap.totalFrames==1 # remove this totalFrames clause to allow for dynamic sprites too
  if bitmapFileName && alterBitmap
    animatedBitmap.prepareStrip
    for i in 0...animatedBitmap.totalFrames
      alterBitmap.call(pokemon,animatedBitmap.alterBitmap(i))
    end
    animatedBitmap.compileStrip
    ret=animatedBitmap
  end
  return ret
end

# Note: Returns an AnimatedBitmap, not a Bitmap
def pbLoadSpeciesBitmap(species,female=false,form=0,shiny=false,shadow=false,back=false,egg=false,scale=POKEMONSPRITESCALE)
  ret = nil
  if egg
    bitmapFileName=sprintf("Graphics/Battlers/Eggs/%s",getConstantName(PBSpecies,species)) rescue nil
    if !pbResolveBitmap(bitmapFileName)
      bitmapFileName=sprintf("Graphics/Battlers/Eggs/%03d",species)
      if !pbResolveBitmap(bitmapFileName)
        bitmapFileName=sprintf("Graphics/Battlers/Eggs/000")
      end
    end
    bitmapFileName=pbResolveBitmap(bitmapFileName)
  else
    bitmapFileName = pbCheckPokemonBitmapFiles([species,back,female,shiny,form,shadow])
  end
  if bitmapFileName
    ret = AnimatedBitmapWrapper.new(bitmapFileName,scale)
  end
  return ret
end

# returns error message upon missing sprites
def missingPokeSpriteError(pokemon,back)
  error_b = back ? "Back" : "Front"
  error_b += "Shiny" if pokemon.isShiny?
  error_b += "/Female/" if pokemon.isFemale?
  error_b += " shadow" if pokemon.isShadow?
  error_b += " form #{pokemon.form} " if pokemon.form > 0
  return "Woops, looks like you're missing the #{error_b} sprite for #{PBSpecies.getName(pokemon.species)}!"
end

# new methods of handing Pokemon sprite name references
def pbCheckPokemonBitmapFiles(params)
  species = params[0]
  back = params[1]
  factors = []
  factors.push([5,params[5],false]) if params[5] && params[5]!=false # shadow
  factors.push([2,params[2],false]) if params[2] && params[2]!=false # gender
  factors.push([3,params[3],false]) if params[3] && params[3]!=false # shiny
  factors.push([4,params[4].to_s,""]) if params[4] && params[4].to_s!="" && params[4].to_s!="0" # form
  tshadow = false
  tgender = false
  tshiny = false
  tform = ""
  for i in 0...2**factors.length
    for j in 0...factors.length
      case factors[j][0]
      when 2   # gender
        tgender = ((i/(2**j))%2==0) ? factors[j][1] : factors[j][2]
      when 3   # shiny
        tshiny = ((i/(2**j))%2==0) ? factors[j][1] : factors[j][2]
      when 4   # form
        tform = ((i/(2**j))%2==0) ? factors[j][1] : factors[j][2]
      when 5   # shadow
        tshadow = ((i/(2**j))%2==0) ? factors[j][1] : factors[j][2]
      end
    end
    folder = "Graphics/Battlers/"
    if tshiny && back
      folder += "BackShiny/"
    elsif tshiny
      folder += "FrontShiny/"
    elsif back
      folder += "Back/"
    else
      folder += "Front/"
    end
    folder += "Female/" if tgender
    bitmapFileName = sprintf("#{folder}%s%s%s",getConstantName(PBSpecies,species),(tform!="" ? "_"+tform : ""),tshadow ? "_shadow" : "") rescue nil
    ret = pbResolveBitmap(bitmapFileName)
    return ret if ret
    bitmapFileName = sprintf("#{folder}%03d%s%s",species,(tform!="" ? "_"+tform : ""),tshadow ? "_shadow" : "")
    ret = pbResolveBitmap(bitmapFileName)
    return ret if ret
  end
  return nil
end

def pbPokemonBitmapFile(species, shiny, back=false)
  folder = "Graphics/Battlers/"
  if shiny && back
    folder += "BackShiny/"
  elsif shiny
    folder += "FrontShiny/"
  elsif back
    folder += "Back/"
  else
    folder += "Front/"
  end
  name = sprintf("#{folder}%s",getConstantName(PBSpecies,species)) rescue nil
  ret = pbResolveBitmap(name)
  return ret if ret
  name = sprintf("#{folder}%03d",species)
  return pbResolveBitmap(name)
end
#===============================================================================
#  Pokedex Fix
#===============================================================================
unless isVersion17?
  class PokedexFormScene
    alias pbStartScene_fix pbStartScene unless self.method_defined?(:pbStartScene_fix)
    def pbStartScene(species)
      return pbStartScene_fix(species) if INCLUDEGEN6
      @skipupdate = true
      pbStartScene_fix(species)
      viewport = (INCLUDEGEN6 && @viewport2) ? @viewport2 : @viewport
      @sprites["front"].dispose if @sprites["front"]
      @sprites["front"] = BitmapWrapperSprite.new(viewport)
      @sprites["back"].dispose if @sprites["back"]
      @sprites["back"] = BitmapWrapperSprite.new(viewport)
      @skipupdate = false
      pbUpdate
      return true
    end
    
    alias pbUpdate_ebs pbUpdate unless self.method_defined?(:pbUpdate_ebs)
    def pbUpdate
      return pbUpdate_ebs if INCLUDEGEN6
      return if @skipupdate
      @sprites["info"].bitmap.clear
      pbSetSystemFont(@sprites["info"].bitmap)
      name=""
      for i in @available
        if i[1]==@gender && i[2]==@form
          name=i[0]
          break
        end
      end
      text=[
         [_INTL("{1}",PBSpecies.getName(@species)),
            (Graphics.width+72)/2,Graphics.height-86,2,
            Color.new(88,88,80),Color.new(168,184,184)],
         [_INTL("{1}",name),
            (Graphics.width+72)/2,Graphics.height-54,2,
            Color.new(88,88,80),Color.new(168,184,184)],
      ]
      pbDrawTextPositions(@sprites["info"].bitmap,text)
      frontBitmap=pbCheckPokemonBitmapFiles([@species,false,(@gender==1),false,@form,false])
      if frontBitmap
        @sprites["front"].setBitmap(frontBitmap)
      end
      backBitmap=pbCheckPokemonBitmapFiles([@species,true,(@gender==1),false,@form,false])
      if backBitmap
        @sprites["back"].setBitmap(backBitmap)
      end
      metrics=load_data("Data/metrics.dat")
      backMetric=metrics[0][@species]
      pbPositionPokemonSprite(@sprites["front"],74,96)
      pbPositionPokemonSprite(@sprites["back"],310,96)
    end
  end
  
  class PokemonPokedexScene  
    alias pbStartScene_fix pbStartScene unless self.method_defined?(:pbStartScene_fix)
    def pbStartScene
      return pbStartScene_fix if INCLUDEGEN6
      @sprites={}
      @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z=99999
      @sprites["pokedex"]=Window_Pokedex.new(214,18,268,332)
      @sprites["pokedex"].viewport=@viewport
      @sprites["dexentry"]=IconSprite.new(0,0,@viewport)
      @sprites["dexentry"].setBitmap(_INTL("Graphics/Pictures/pokedexEntry"))
      @sprites["dexentry"].visible=false
      @sprites["overlay"]=BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
      pbSetSystemFont(@sprites["overlay"].bitmap)
      @sprites["overlay"].x=0
      @sprites["overlay"].y=0
      @sprites["overlay"].visible=false
      @sprites["searchtitle"]=Window_AdvancedTextPokemon.newWithSize("",2,-18,Graphics.width,64,@viewport)
      @sprites["searchtitle"].windowskin=nil
      @sprites["searchtitle"].baseColor=Color.new(248,248,248)
      @sprites["searchtitle"].shadowColor=Color.new(0,0,0)
      @sprites["searchtitle"].text=_ISPRINTF("<ac>Search Mode</ac>")
      @sprites["searchtitle"].visible=false
      @sprites["searchlist"]=Window_ComplexCommandPokemon.newEmpty(-6,32,284,352,@viewport)
      @sprites["searchlist"].baseColor=Color.new(248,248,248)
      @sprites["searchlist"].shadowColor=Color.new(0,0,0)
      @sprites["searchlist"].visible=false
      @sprites["auxlist"]=Window_CommandPokemonWhiteArrow.newEmpty(256,32,284,224,@viewport)
      @sprites["auxlist"].baseColor=Color.new(248,248,248)
      @sprites["auxlist"].shadowColor=Color.new(0,0,0)
      @sprites["auxlist"].visible=false
      @sprites["messagebox"]=Window_UnformattedTextPokemon.newWithSize("",254,256,264,128,@viewport)
      @sprites["messagebox"].baseColor=Color.new(248,248,248)
      @sprites["messagebox"].shadowColor=Color.new(0,0,0)
      @sprites["messagebox"].visible=false
      @sprites["messagebox"].letterbyletter=false
      @sprites["dexname"]=Window_AdvancedTextPokemon.newWithSize("",2,-18,Graphics.width,64,@viewport)
      @sprites["dexname"].windowskin=nil
      @sprites["dexname"].baseColor=Color.new(248,248,248)
      @sprites["dexname"].shadowColor=Color.new(0,0,0)
      @sprites["species"]=Window_AdvancedTextPokemon.newWithSize("",38,22,160,64,@viewport)
      @sprites["species"].windowskin=nil
      @sprites["species"].baseColor=Color.new(88,88,80)
      @sprites["species"].shadowColor=Color.new(168,184,184)
      @sprites["seen"]=Window_AdvancedTextPokemon.newWithSize("",38,242,164,64,@viewport)
      @sprites["seen"].windowskin=nil
      @sprites["seen"].baseColor=Color.new(88,88,80)
      @sprites["seen"].shadowColor=Color.new(168,184,184)
      @sprites["owned"]=Window_AdvancedTextPokemon.newWithSize("",38,282,164,64,@viewport)
      @sprites["owned"].windowskin=nil
      @sprites["owned"].baseColor=Color.new(88,88,80)
      @sprites["owned"].shadowColor=Color.new(168,184,184)
      addBackgroundPlane(@sprites,"searchbg",_INTL("pokedexSearchbg"),@viewport)
      @sprites["searchbg"].visible=false
      @searchResults=false
      addBackgroundPlane(@sprites,"background",_INTL("pokedexbg"),@viewport)
      @sprites["slider"]=IconSprite.new(Graphics.width-44,62,@viewport)
      @sprites["slider"].setBitmap(sprintf("Graphics/Pictures/pokedexSlider"))
      @sprites["icon"] = BitmapWrapperSprite.new(@viewport)
      @sprites["icon"].x = 116
      @sprites["icon"].y = 164
      @sprites["entryicon"]=PokemonSprite.new(@viewport)
      pbRefreshDexList($PokemonGlobal.pokedexIndex[pbGetSavePositionIndex])
      pbDeactivateWindows(@sprites)
      pbFadeInAndShow(@sprites)
    end
    
    alias pbChangeToDexEntry_ebs pbChangeToDexEntry unless self.method_defined?(:pbChangeToDexEntry_ebs)
    def pbChangeToDexEntry(species)
      return pbChangeToDexEntry_ebs(species) if INCLUDEGEN6
      @sprites["dexentry"].visible=true
      @sprites["overlay"].visible=true
      @sprites["overlay"].bitmap.clear
      basecolor=Color.new(88,88,80)
      shadowcolor=Color.new(168,184,184)
      indexNumber=pbGetRegionalNumber(pbGetPokedexRegion(),species)
      indexNumber=species if indexNumber==0
      indexNumber-=1 if DEXINDEXOFFSETS.include?(pbGetPokedexRegion)
      textpos=[
         [_ISPRINTF("{1:03d}{2:s} {3:s}",indexNumber," ",PBSpecies.getName(species)),
            244,40,0,Color.new(248,248,248),Color.new(0,0,0)],
         [sprintf(_INTL("HT")),318,158,0,basecolor,shadowcolor],
         [sprintf(_INTL("WT")),318,190,0,basecolor,shadowcolor]
      ]
      if $Trainer.owned[species]
        dexdata=pbOpenDexData
        pbDexDataOffset(dexdata,species,8)
        type1=dexdata.fgetb
        type2=dexdata.fgetb
        pbDexDataOffset(dexdata,species,33)
        height=dexdata.fgetw
        weight=dexdata.fgetw
        dexdata.close
        kind=pbGetMessage(MessageTypes::Kinds,species)
        dexentry=pbGetMessage(MessageTypes::Entries,species)
        inches=(height/0.254).round
        pounds=(weight/0.45359).round
        textpos.push([_ISPRINTF("{1:s} Pokꮯn",kind),244,74,0,basecolor,shadowcolor])
        if pbGetCountry()==0xF4 # If the user is in the United States
          textpos.push([_ISPRINTF("{1:d}'{2:02d}\"",inches/12,inches%12),456,158,1,basecolor,shadowcolor])
          textpos.push([_ISPRINTF("{1:4.1f} lbs.",pounds/10.0),490,190,1,basecolor,shadowcolor])
        else
          textpos.push([_ISPRINTF("{1:.1f} m",height/10.0),466,158,1,basecolor,shadowcolor])
          textpos.push([_ISPRINTF("{1:.1f} kg",weight/10.0),478,190,1,basecolor,shadowcolor])
        end
        drawTextEx(@sprites["overlay"].bitmap,
           42,240,Graphics.width-(42*2),4,dexentry,basecolor,shadowcolor)
        footprintfile=pbPokemonFootprintFile(species)
        if footprintfile
          footprint=BitmapCache.load_bitmap(footprintfile)
          @sprites["overlay"].bitmap.blt(226,136,footprint,footprint.rect)
          footprint.dispose
        end
        pbDrawImagePositions(@sprites["overlay"].bitmap,[["Graphics/Pictures/pokedexOwned",212,42,0,0,-1,-1]])
        typebitmap=AnimatedBitmap.new(_INTL("Graphics/Pictures/pokedexTypes"))
        type1rect=Rect.new(0,type1*32,96,32)
        type2rect=Rect.new(0,type2*32,96,32)
        @sprites["overlay"].bitmap.blt(296,118,typebitmap.bitmap,type1rect)
        @sprites["overlay"].bitmap.blt(396,118,typebitmap.bitmap,type2rect) if type1!=type2
        typebitmap.dispose
      else
        textpos.push([_INTL("????? Pokꮯn"),244,74,0,basecolor,shadowcolor])
        if pbGetCountry()==0xF4 # If the user is in the United States
          textpos.push([_INTL("???'??\""),456,158,1,basecolor,shadowcolor])
          textpos.push([_INTL("????.? lbs."),490,190,1,basecolor,shadowcolor])
        else
          textpos.push([_INTL("????.? m"),466,158,1,basecolor,shadowcolor])
          textpos.push([_INTL("????.? kg"),478,190,1,basecolor,shadowcolor])
        end
      end
      pbDrawTextPositions(@sprites["overlay"].bitmap,textpos)
      file=pbPokemonBitmapFile(species,false)
      pkmnbitmap=AnimatedBitmapWrapper.new(file)
      @sprites["overlay"].bitmap.blt(
         40-(pkmnbitmap.width-128)/2,
         70-(pkmnbitmap.height-128)/2,
         pkmnbitmap.bitmap,pkmnbitmap.bitmap.rect)
      pkmnbitmap.dispose
      pbPlayCry(species)
    end
  end
end
#===============================================================================
#  Use this to automatically scale down any 2*2 px resolution sprites you may
#  have, to the smaller 1*1 px resolution, for full compatibility with the new
#  bitmap wrappers utilized in displaying and animating sprites
#===============================================================================
def resizePngs(scale=0.5)
  destination="./Convert/"
  Dir.mkdir(destination+"New/") if !FileTest.directory?(destination+"New/")
  search_for=["*.png"]
 
  @files=readDirectoryFiles(destination,search_for)
  @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
  @viewport.z=999999
  
  @bar=Sprite.new(@viewport)
  @bar.bitmap=Bitmap.new(Graphics.width,34)
  pbSetSystemFont(@bar.bitmap)
 
  for i in 0...@files.length
    @files[i]=@files[i].gsub(/.png/) {""}
  end
  
  return false if !Kernel.pbConfirmMessage(_INTL("There is a total of #{@files.length} PNG(s) available for conversion. Would you like to begin the process?"))
  for i in 0...@files.length
    file=@files[i]
    
    width=((i*1.000)/@files.length)*Graphics.width
    @bar.bitmap.clear
    @bar.bitmap.fill_rect(0,0,Graphics.width,34,Color.new(255,255,255))
    @bar.bitmap.fill_rect(0,0,Graphics.width,32,Color.new(0,0,0))
    @bar.bitmap.fill_rect(0,0,width,32,Color.new(25*4,90*2,25*4))
    text=[["#{i}/#{@files.length}",Graphics.width/2,2,2,Color.new(255,255,255),nil]]
    pbDrawTextPositions(@bar.bitmap,text)
    
    next if RTP.exists?("#{destination}New/#{file}.png")
    
    sprite=pbBitmap("#{destination}#{file}.png")
    width=sprite.width
    height=sprite.height
      
    bitmap=Bitmap.new(width*scale,height*scale)
    bitmap.stretch_blt(Rect.new(0,0,width*scale,height*scale),sprite,Rect.new(0,0,width,height))
    bitmap.saveToPng("#{destination}New/#{file}.png")
    sprite.dispose
    pbWait(1)
    RPG::Cache.clear
  end
  @bar.dispose
  @viewport.dispose
  Kernel.pbMessage(_INTL("Done!"))
end 
#===============================================================================
#  Utility to cut sprite reels into static ones
#===============================================================================
def pbCutSpriteReel
  dir="./Graphics/Battlers/"
  new_dir=dir+"Cut/"
  Dir.mkdir(new_dir) if !FileTest.directory?(new_dir)
  search_for=["*.png"]
 
  @files=readDirectoryFiles(dir,search_for)
  @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
  @viewport.z=999999
  
  @bar=Sprite.new(@viewport)
  @bar.bitmap=Bitmap.new(Graphics.width,34)
  pbSetSystemFont(@bar.bitmap)
 
  for i in 0...@files.length
    @files[i]=@files[i].gsub(/.png/) {""}
  end
  
  return false if !Kernel.pbConfirmMessage(_INTL("There is a total of #{@files.length} PNG(s) available for conversion. Would you like to begin the process?"))
  for i in 0...@files.length
    file=@files[i]
    
    width=((i*1.000)/@files.length)*Graphics.width
    @bar.bitmap.clear
    @bar.bitmap.fill_rect(0,0,Graphics.width,34,Color.new(255,255,255))
    @bar.bitmap.fill_rect(0,0,Graphics.width,32,Color.new(0,0,0))
    @bar.bitmap.fill_rect(0,0,width,32,Color.new(25*4,90*2,25*4))
    text=[["#{i}/#{@files.length}",Graphics.width/2,2,2,Color.new(255,255,255),nil]]
    pbDrawTextPositions(@bar.bitmap,text)
    
    next if RTP.exists?("#{new_dir}#{file}.png")
    
    sprite=pbBitmap("#{dir}#{file}.png")
    width=sprite.width
    height=sprite.height
      
    bitmap=Bitmap.new(height,height)
    bitmap.blt(0,0,sprite,Rect.new(0,0,height,height))
    bitmap.saveToPng("#{new_dir}#{file}.png")
    sprite.dispose
    pbWait(1)
    RPG::Cache.clear
  end
  @bar.dispose
  @viewport.dispose
  Kernel.pbMessage(_INTL("Done! All your converted sprites are saved in the Graphics/Battlers/Cut/ folder."))
end