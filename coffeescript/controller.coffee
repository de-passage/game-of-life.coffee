# Interface between the board and the view
# Might be doing too many things
class Controller
  constructor: (@board) ->
    @observed = {}
    @cells = []
    @speed = 300
    @strict_mode = true

  # Register an observable event
  registerObs: (name, item) ->
    @observed[name] = item

  # Generic update of the view
  emit: (name, data...) ->
    @observed[name]?(data...)

  # Register the callback needed to update the cells in the view
  registerCell: (x, y, f) ->
    @cells[y * @board.width + x] = f

  # Update the cells of the view
  updateCell: (x, y, status) ->
    @cells[y * @board.width + x](status)

  # Callback indicating that a cell has been selected
  # If the game is not running, switch the state of the cell
  cellSelected: (x, y) ->
    return if @strict_mode && @timer
    if @board.isAlive x, y
      @board.kill x, y
      @updateCell x, y, "dead"
    else
      @board.birth x, y
      @updateCell(x, y, "alive")

  # Update the board a single time
  playSingleTurn: ->
    return if @timer
    if @board.isStable()
      @emit "stable"
    else @playTurn()

  # Update the board by one generation
  playTurn: ->
    if @board.generation == 0
      @resetState = @board.dump()

    @board.nextGeneration (x, y, prev, next) =>
      if prev && !next
        @updateCell x, y, "dead"
      else if !prev && next
        @updateCell x, y, "alive"

    @emit "generation", @board.generation

  # Resets the board to its initial state
  reset: ->
    if @resetState
      @pause()
      @board.load @resetState
      @emit "reset"
      @resetDisplay()

  # Reset the display to the value of the board (useful after loading)
  resetDisplay: ->
    for i in [0...@board.width]
      for j in [0...@board.height]
        @updateCell(i, j, if @board.isAlive(i,j) then "alive" else "dead")
    @emit "generation", @board.generation

  # Save the current board
  save: ->
    localStorage["de-passage_game-of-life"] = JSON.stringify @board.dump()
    @emit "save"

  # Load the saved state
  load: ->
    loadFile = localStorage["de-passage_game-of-life"]
    if loadFile
      @pause()
      @board.load loadFile
      @emit "load"
      @resetDisplay()

  # Clear the board
  clear: ->
    @pause()
    for i in [0...@board.width]
      for j in [0...@board.height]
        @updateCell(i, j, "dead") if @board.isAlive i, j
    @board.clear()
    @emit "generation", 0

  # Start the game of life
  start: ->
    return if @timer
    if @board.isStable()
      @emit "stable"
    else
      @timer = setInterval (=> if @board.isStable() then @pause() else @playTurn()), @speed
      @emit "start"

  # Pause the game if life
  pause: ->
    @emit "pause"
    clearInterval @timer
    @timer = null

  # Set the board in a random state
  randomize: ->
    for i in [0...@board.width]
      for j in [0...@board.height]
        if Math.random() < 0.3
          @board.birth i, j
          @updateCell i, j, "alive"
        else
          @board.kill i, j
          @updateCell i, j, "dead"

module.exports = Controller
