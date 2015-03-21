{CompositeDisposable} = require "atom"
vm = require "vm"

module.exports = Calc =

	## Config ##################################################################

	config:
		withMath:
			type: "boolean"
			default: true
			description: "Allows use of Math functions such as `pow` without
				prepending Math."

	## Events ##################################################################

	events: null
	sandbox: null

	activate: ->
		# Register Command event handlers
		@events = new CompositeDisposable
		@events.add( atom.commands.add( "atom-text-editor", {
			"calc:evaluate": => @evaluate()
			"calc:replace": => @replace()
			"calc:count": => @count()
		} ) )

		# Create Sandbox and populate with functions
		@sandbox = vm.createContext()

	deactivate: ->
		@events.dispose()



	## Util Functions ##########################################################

	calculateResult: (str) ->
		str = "with (Math) {#{str}}" if atom.config.get "calc.withMath"
		try vm.runInThisContext( str, @sandbox )

	iterateSelections: (editor, fn) ->
		for sel in editor.getSelections().sort( (a, b) -> a.compare( b ) )
			out = fn( sel )
			sel.insertText( out.toString() ) if out?



	## Commands ################################################################

	evaluate: ->
		editor = atom.workspace.getActiveTextEditor()
		return unless editor?

		@iterateSelections( editor, (sel) =>
			out = @calculateResult sel.getText()
			return unless out?

			sel.getText() + " = " + out )

	replace: ->
		editor = atom.workspace.getActiveTextEditor()
		return unless editor?

		@iterateSelections( editor, (sel) =>
			out = @calculateResult sel.getText()

			return out )

	count: ->
		editor = atom.workspace.getActiveTextEditor()
		return unless editor?

		i = 0
		@iterateSelections( editor, (sel) => i++ )
