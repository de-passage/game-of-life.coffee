{ button } = React.DOM
newClass = (spec) -> React.createFactory React.createClass spec
    
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

module.exports = StartButton
