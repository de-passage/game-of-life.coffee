{ div } = React.DOM
newClass = (spec) -> React.createFactory React.createClass spec

UpperUI = require "./upper_ui.coffee"
LowerUI = require "./lower_ui.coffee"
Grid = require "./grid.coffee"
      
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
      
module.exports = View

