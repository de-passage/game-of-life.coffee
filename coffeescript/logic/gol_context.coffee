GOLBoard = require "./gol_board.coffee"

# Holds the board and rules associated
# The underlying principle of this class is to store in each cell not only
# the status of the current cell (alive or dead), but also the list of its neighbors.
# This is achieved within a single integer per cell by encoding the status of a cell per bit.
# The 3 first bits (starting from the right) encode the status of the upper neighbors,
# the 3 next encode the left neighbor, the cell itself and the  right neighbor respectively.
# The last 3 encode the lower neighbors.
# All the information can then easily be accessed in constant time by bitwise operations
class GOLContext
  constructor: (@width, @height) ->
    @clear()

  # Empties the board, concretely rebuilding one
  clear: ->
    @map = new GOLBoard(@width, @height)
    @computeNextGen()
    #@nextGen = new GOLBoard(@width, @height)
    #@changes = []
    @generation = 0
    #@stable = true

  # Dump the current state of the board
  dump: ->
    board: @map.clone()
    generation: @generation

  # Regenerate the board from a dump
  load: (loadFile) ->
    dump = GOLBoard.deserialize(loadFile)
    @map = dump.board
    @generation = dump.generation
    @computeNextGen()
    @width = @map.width
    @height = @map.height

  # Return true if the cell at the given coordinates is "alive", otherwise false
  isAlive: (x, y) ->
    !!(@map.at(x,y) & 16) # Coerce the value of the 5th bit to boolean

  # Returns the number of neighbors of a cell
  neighbors: (x, y) ->
    i = @map.at(x, y) & (0x1FF - 16) # Get the value minus the 5th bit
    i = i - ((i >> 1) & 0x55555555) # popcount, see wikipedia for details
    i = (i & 0x33333333) + ((i >> 2) & 0x33333333)
    (((i + (i >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24

  # Update stability cache and call birth
  birth: (x, y) ->
    birth(x, y, @map)
    @computeNextGen()

  # Sets the cell at the given coordinates to "alive" and notifies the adjacent cells
  # Doesn't update stability cache
  birth = (x, y, map) ->
    f = (i) -> (p) -> p | 1 << i # Switches the i-th bit on
    apply x, y, f, map

  # Update stability cache and call kill
  kill: (x, y) ->
    kill(x, y, @map)
    @computeNextGen()

  # Sets the cell at the given coordinates to "dead" and notifies the adjacent cells
  kill = (x, y, map) ->
    f = (i) -> (p) -> p & (0x1FF - (1 << i)) #Switches the i-th bit off
    apply x, y, f, map

  # Apply @set with the given function to a 9-cell square centered around
  # the given coordinates
  apply = (x, y, f, map) ->
    for i in [-1..1]
      for j in [-1..1]
        map.set x + i, y + j, f((i + 1) * 3 + j + 1)

  # Returns true if the game is stable, i.e. no change will happen from one
  # generation to the next
  isStable: ->
    @stable

  # Compute the next generation of the game
  computeNextGen: () ->
    nGen = @map.clone()
    @changes = []
    stable = true
    for i in [0...@width]
      for j in [0...@height]
        n = @neighbors i, j
        a  = @isAlive i, j
        if a
          if n < 2 or n > 3
            kill i, j, nGen
            stable = false
            @changes.push [i, j, a, false]
          else
            @changes.push [i, j, a, true]
        else
          if n == 3
            birth i, j, nGen
            stable = false
            @changes.push [i, j, a, true]
          else
            @changes.push [i, j, a, false]
    @nextGen = nGen
    @stable = stable

  # Sets the game to its next generation pass data about the changes to the callback
  # (for every cell currently)
  # The arguments given to the callback are: callback(x, y, prevAlive, nextAlive)
  # with x and y the coordinates of the cell, and the remaining arguments booleans indicating
  # whether or not the cell is alive in the previous generation and in the one being computed
  nextGeneration: (callback) ->
    return if @stable
    @generation++
    @map = @nextGen
    for change in @changes
      callback.apply null, change
    @computeNextGen()
# end class GOLContext

module.exports = GOLContext
