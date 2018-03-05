{ div } = React.DOM
newClass = (spec) -> React.createFactory React.createClass spec

Cell = require "./cell.coffee"

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

module.exports = Grid
