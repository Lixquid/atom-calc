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
		evaluateAllOnEmptySelection:
			type: "boolean"
			default: true
			description: "If this is enabled, calling a command with an empty
				selection will run each line as an expression."
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
		vm.runInContext "Math.pwd = function( len ) {
				out = \"\";
				for ( var x = 0; x < ( len || 20 ); x++ )
					out += String.fromCharCode(
					  Math.floor( Math.random() * 95 + 32 ) );
				return out;
			};
			Math.password = Math.pwd;", @sandbox

	deactivate: ->
		@events.dispose()



	## Util Functions ##########################################################

	previous: null
	count: null

	calculateResult: (str) ->
		# extendedVariables
		if atom.config.get "calc.extendedVariables"
			str = "
				_ = #{@previous};
				_#{@count} = _;
				i = #{@count++};
				#{str}"

		# withMath
		if atom.config.get "calc.withMath"
			str = "with (Math) {#{str}}"

		try @previous = vm.runInContext( str, @sandbox )

	iterateSelections: (editor, fn) ->
		# Reset Count
		@count = atom.config.get "calc.countStartIndex"

		# If selection's empty, select all and split
		if atom.config.get( "calc.evaluateAllOnEmptySelection" ) and
		  editor.getSelections().length == 1 and
		  editor.getSelections()[0].getText() == ""

			cur_pos = editor.getCursorScreenPosition()
			editor.selectAll()
			editor.splitSelectionsIntoLines()

		# Iterate over selections, replace with result
		for sel in editor.getSelections().sort( (a, b) -> a.compare( b ) )
			out = fn( sel )
			sel.insertText( out.toString() ) if out?

		if atom.config.get "calc.evaluateAllOnEmptySelection"
			editor.setCursorScreenPosition cur_pos



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
