{ div, button, input } = React.DOM
newClass = (spec) -> React.createFactory React.createClass spec

# Board of the game. Simply an array of integers
# A few helper functions are provided to access and edit the values
class GOLBoard
  # Constructor, takes the width and height of the array in parameters.
  # The last parameter is reserved for copy construction
  constructor: (@width, @height, arr) ->
    if arr
      @map = arr
    else
      @map = (0 for i in [0...@width * @height])
      
  # Returns the full value of the cell at the given coordinates 
  at: (x, y) ->
    @map[@pos x, y]
    
  # Replace the cell at the given coordinates by the result of the application
  # of the function
  set: (x, y, func) ->
    p = @pos(x, y)
    @map[p] = func(@map[p])
    
  # Clamp the coordinates to the board and hash them into their integer value
  pos: (x, y) ->
    if x < 0 
      x += @width while x < 0
    else if x >= @width
      x -= @width while x >= @width
    if y < 0
      y += @height while y < 0
    else if y >= @height
      y -= @height while y >= @height
    return y * @width + x
  # Duplicate self
  clone: ->
    new GOLBoard @width, @height, @map.slice 0
# end class GOLBoard  
    
  

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
  load: (dump) ->
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

# Interface between the board and the view
# Might be doing too many things
class Controller
  constructor: ->
    @observed = {}
    @cells = []
    @board = new GOLContext 40,35
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
      #Not the right place for this but well
      temp = JSON.parse loadFile
      arr = []
      for k, v of temp.board.map
        arr.push v || 0
      temp.board.map = arr
      temp.board.at = GOLBoard.prototype.at
      temp.board.pos = GOLBoard.prototype.pos
      temp.board.set = GOLBoard.prototype.set
      temp.board.clone = GOLBoard.prototype.clone
      @board.load temp 
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
    
controller = new Controller

# View of an individual Cell
# State: status -> "alive" | "dead"
Cell = newClass
  getInitialState: ->
    status: "dead"
  #Register the handle to update individual cells
  componentWillMount: ->
    @props.controller.registerCell @props.coords.x, @props.coords.y, (state) =>
      @setState status: state
  render: ->
    div
      className: "game-cell #{@state.status}"
      key: "#{@props.coords.x}-#{@props.coords.y}"
      onMouseDown: => @props.controller.cellSelected(@props.coords.x, @props.coords.y)

# View of the game Grid
# Hold individual cells but no state on its own
Grid = newClass
  getInitialState: ->
    height: @props.controller.board.height
    width: @props.controller.board.width
  componentWillMount: ->
    @props.controller.registerObs("dimensions", (w, h) => @setState(height: h, width: w))
  render: ->
    grid = (for i in [0...@state.height]
              div 
                className: "game-row"
                (for j in [0...@state.width]
                  Cell 
                    coords: {x: j, y: i}
                    controller: @props.controller
                )
            )
    div { className: "mx-auto grid", style: width: @state.width * 20 }, [grid].concat @props.children
    
# Component displaying the current generation 
GenerationLabel = newClass
  getInitialState: ->
    value: @props.generation || 0
  componentWillMount: ->
    @props.controller.registerObs "generation", (n) =>
      @setState value: n
  render: ->
    div
      className: "generation mx-auto"
      "Generation: #{@state.value}"
    
# Control button for play/pause
StartButton = newClass
  getInitialState: ->
    paused: true
  componentWillMount: ->
    @props.controller.registerObs "start", => @setState paused: false
    @props.controller.registerObs "pause", => @setState paused: true
  render: ->
    button
      onClick: 
        if @state.paused then (=> @props.controller.start()) 
        else (=> @props.controller.pause())
      className: "btn btn-success"
      if @state.paused then "Start" else "Pause"
      
# UI component above the grid
UpperUI = newClass
  render: ->
    div
      className: "ui upper"
      GenerationLabel
        generation: 0
        controller: @props.controller
        
# UI component under the griddiv
LowerUI = newClass
  render: ->
    div
      className: "ui lower "
      div
        className: "btn-group col-12 col-md-6 col-lg-5 offset-lg-1 col-xl-4 offset-xl-2"
        StartButton
          controller: @props.controller
        button
          onClick: => @props.controller.playSingleTurn()
          className: "btn btn-primary"
          type: "button"
          "One turn"
        button
          onClick: => @props.controller.reset()
          className: "btn btn-warning"
          type: "button"
          "Reset"
        button
          onClick: => @props.controller.clear()
          className: "btn btn-danger"
          type: "button"
          "Clear"
      div
        className: "btn-group col-12 col-md-6 col-lg-5 col-xl-4"
        button
          onClick: => @props.controller.save()
          className: "btn btn-secondary"
          type: "button"
          "Save"
        button
          onClick: => @props.controller.load()
          className: "btn btn-secondary"
          type: "button"
          "Load"
        button
          onClick: => @props.controller.randomize()
          className: "btn btn-secondary"
          type: "button"
          "Randomize"
      
# Top level component of the view. No state      
View = newClass
  render: ->
    div
      className: "container-fluid"
      UpperUI
        controller: @props.controller
      Grid
        controller: @props.controller
      LowerUI
        controller: @props.controller
      
        

ReactDOM.render (View { controller: controller }), document.getElementsByTagName("body")[0]

controller.randomize()
controller.start()
