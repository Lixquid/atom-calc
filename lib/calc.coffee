{CompositeDisposable} = require "atom"
vm = require "vm"

module.exports = Calc =

	## Config ##################################################################

	config:
		extendedVariables:
			type: "boolean"
			default: true
			description: "Enables the use of some \"magic\" variables, such as
				i and _."
		withMath:
			type: "boolean"
			default: true
			description: "Allows use of Math functions such as `pow` without
				prepending Math."
		countStartIndex:
			type: "integer"
			default: 0
			description: "The starting number to count from when using `count`."

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

	previous: null
	count: null

	calculateResult: (str) ->
		# extendedVariables
		if atom.config.get "calc.extendedVariables"
			str = "i = #{@count++}; _ = #{@previous}; #{str}"

		# withMath
		str = "with (Math) {#{str}}" if atom.config.get "calc.withMath"

		try @previous = vm.runInThisContext( str, @sandbox )

	iterateSelections: (editor, fn) ->
		@count = atom.config.get "calc.countStartIndex"
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

		i = atom.config.get "calc.countStartIndex"
		@iterateSelections( editor, (sel) => i++ )
