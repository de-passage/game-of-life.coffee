{ div } = React.DOM
newClass = (spec) -> React.createFactory React.createClass spec

GenerationLabel = require "./generation_label.coffee"
      
# UI component above the grid
UpperUI = newClass
  render: ->
    div
      className: "ui upper"
      GenerationLabel
        generation: 0
        controller: @props.controller

module.exports = UpperUI
