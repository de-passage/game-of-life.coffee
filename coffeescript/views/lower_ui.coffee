{ div, button } = React.DOM
newClass = (spec) -> React.createFactory React.createClass spec

StartButton = require "./start_button.coffee"

        
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

module.exports = LowerUI
