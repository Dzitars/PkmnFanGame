module PokeBattle_BattleCommon
  def pbStorePokemon(pokemon)
    if !(pokemon.isShadow? rescue false)
      if pbDisplayConfirm(_INTL("Would you like to give a nickname to {1}?",pokemon.name))
        species=PBSpecies.getName(pokemon.species)
        nickname=@scene.pbNameEntry(_INTL("{1}'s nickname?",species),pokemon)
        pokemon.name=nickname if nickname!=""
      end
    end
    if $Trainer.party.length<6
      $Trainer.party[$Trainer.party.length] = pokemon
    elsif pbDisplayConfirm(_INTL("Would you like to keep {1} in your party?",pokemon.name))
      pokemon2 = pokemon
      pbDisplayPaused(_INTL("Please select a Pokémon to swap from your party."))
      pbChoosePokemon(1,2)
      cancel = pbGet(1)
      if cancel >= 0
        swap = true
        pokemon = $Trainer.pokemonParty[pbGet(1)]
        pbRemovePokemonAt(pbGet(1))
      end
      oldcurbox = $PokemonStorage.currentBox
      storedbox = $PokemonStorage.pbStoreCaught(pokemon)
      curboxname = $PokemonStorage[oldcurbox].name
      boxname = $PokemonStorage[storedbox].name
      creator = nil
      creator = Kernel.pbGetStorageCreator if $PokemonGlobal.seenStorageCreator
      if storedbox!=oldcurbox
        if creator
          pbDisplayPaused(_INTL("Box \"{1}\" on {2}'s PC was full.",curboxname,creator))
        else
          pbDisplayPaused(_INTL("Box \"{1}\" on someone's PC was full.",curboxname))
        end
        pbDisplayPaused(_INTL("{1} was transferred to box \"{2}\".",pokemon.name,boxname))
      else
        if creator
          pbDisplayPaused(_INTL("{1} was transferred to {2}'s PC.",pokemon.name,creator))
        else
          pbDisplayPaused(_INTL("{1} was transferred to someone's PC.",pokemon.name))
        end
        pbDisplayPaused(_INTL("It was stored in box \"{1}\".",boxname))
      end
      if swap
        self.pbPlayer.party[self.pbPlayer.party.length]=pokemon2
        pbDisplayPaused(_INTL("{2} has added to {1}'s party!",$Trainer.name,pokemon2.name))
      end
    end
  end
end

def pbStorePokemon(pokemon)
  if pbBoxesFull?
    Kernel.pbMessage(_INTL("There's no more room for Pokémon!\1"))
    Kernel.pbMessage(_INTL("The Pokémon Boxes are full and can't accept any more!"))
    return
  end
  pokemon.pbRecordFirstMoves
  if $Trainer.party.length<6
    $Trainer.party[$Trainer.party.length] = pokemon
  else
    if Kernel.pbConfirmMessage(_INTL("Would you like to keep {1} in your party?",pokemon.name))
      pokemon2 = pokemon
      Kernel.pbMessage(_INTL("Please select a Pokémon to swap from your party."))
      pbChoosePokemon(1,2)
      cancel = pbGet(1)
      if cancel >= 0
        swap = true
        pokemon = $Trainer.pokemonParty[pbGet(1)]
        pbRemovePokemonAt(pbGet(1))
      end
    end
    oldcurbox = $PokemonStorage.currentBox
    storedbox = $PokemonStorage.pbStoreCaught(pokemon)
    curboxname = $PokemonStorage[oldcurbox].name
    boxname = $PokemonStorage[storedbox].name
    creator = nil
    creator = Kernel.pbGetStorageCreator if $PokemonGlobal.seenStorageCreator
    if storedbox!=oldcurbox
      if creator
        Kernel.pbMessage(_INTL("Box \"{1}\" on {2}'s PC was full.\1",curboxname,creator))
      else
        Kernel.pbMessage(_INTL("Box \"{1}\" on someone's PC was full.\1",curboxname))
      end
      Kernel.pbMessage(_INTL("{1} was transferred to box \"{2}.\"",pokemon.name,boxname))
    else
      if creator
        Kernel.pbMessage(_INTL("{1} was transferred to {2}'s PC.\1",pokemon.name,creator))
      else
        Kernel.pbMessage(_INTL("{1} was transferred to someone's PC.\1",pokemon.name))
      end
      Kernel.pbMessage(_INTL("It was stored in box \"{1}.\"",boxname))
    end
    if swap
      $Trainer.party[$Trainer.party.length] = pokemon2
      Kernel.pbMessage(_INTL("\\me[Pkmn get]{2} has added to {1}'s party!",$Trainer.name,pokemon2.name))
    end
  end
end