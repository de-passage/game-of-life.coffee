Controller = require "./controller.coffee"
GOLContext = require "./logic/gol_context.coffee"
View = require "./views/top_level.coffee"

controller = new Controller(new GOLContext 40,35)

ReactDOM.render (View { controller: controller }), document.getElementsByTagName("body")[0]

controller.randomize()
controller.start()
