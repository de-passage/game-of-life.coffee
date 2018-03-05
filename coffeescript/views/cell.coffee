{ div } = React.DOM
newClass = (spec) -> React.createFactory React.createClass spec

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

module.exports = Cell
