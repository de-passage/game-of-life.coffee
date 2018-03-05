
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

  # Turn a string into a board
  @deserialize = (loadFile) ->
      temp = JSON.parse loadFile
      arr = []
      for k, v of temp.board.map
        arr.push v || 0
      temp.board.map = arr
      temp.board.at = GOLBoard.prototype.at
      temp.board.pos = GOLBoard.prototype.pos
      temp.board.set = GOLBoard.prototype.set
      temp.board.clone = GOLBoard.prototype.clone
      return temp

# end class GOLBoard


module.exports = GOLBoard
