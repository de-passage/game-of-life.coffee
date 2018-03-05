{ div } = React.DOM
newClass = (spec) -> React.createFactory React.createClass spec
    
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

module.exports = GenerationLabel
