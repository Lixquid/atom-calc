## Dependencies ################################################################

{ CompositeDisposable } = require "atom"
vm = require "vm"

## Package #####################################################################

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

	## Fields ##################################################################

	events: null
	sandbox: null

	## Activator / Deactivator #################################################

	activate: ->
		# Register Command event handlers
		@events = new CompositeDisposable
		@events.add( atom.commands.add( "atom-text-editor", {
			"calc:replace": => @editorReplace()
			"calc:evaluate": => @editorEvaluate()
			"calc:count": => @editorCount()
		} ) )

		# Create Sandbox
		@sandbox = vm.createContext()
		vm.runInContext(
			"""
				Math.pwd = function( len ) {
					var out = "";
					for ( var x = 0; x < ( len || 20 ); x++ ) {
						out += String.fromCharCode( Math.random() * 95 + 32 );
					}
					return out;
				}
				Math.password = Math.pwd;
			""",
			@sandbox
		)

	deactivate: ->
		@events.dispose()

	## Util ####################################################################

	previous: null
	count: null

	calculateResult: ( expression ) ->

		# `extendedVariables`
		if atom.config.get( "calc.extendedVariables" )
			expression = "
				i = #{@count};
				_#{++@count} = _ = " + expression

		# `withMath`
		if atom.config.get( "calc.withMath" )
			expression = """
				with ( Math ) {
					#{expression}
				}
			"""

		try
			@previous = vm.runInContext( expression, @sandbox )
		catch ex
			console.error expression, ex

	iterateSelections: ( func, options = {} ) ->
		{ include_empty } = options

		# Get the current editor
		editor = atom.workspace.getActiveTextEditor()
		if not editor?
			return

		# Reset the expression count
		@count = atom.config.get( "calc.countStartIndex" )

		cur_pos = null

		# Iterate over selections, replace with result of `func`
		editor.getBuffer().transact ->
			# If the selection's empty and we have splitOnEmpty set to true,
			# select all and split into selections
			if atom.config.get( "calc.evaluateAllOnEmptySelection" ) and
			  editor.getSelections().length == 1 and
			  editor.getSelections()[0].isEmpty()

				# Store the current cursor position for later
				cur_pos = editor.getCursorScreenPosition()
				editor.selectAll()
				editor.splitSelectionsIntoLines()

			for sel in editor.getSelections().sort( ( a, b ) -> a.compare( b ) )
				# If we're ignoring empty selections, skip
				if not include_empty and
				  ( sel.isEmpty() or /^\s*\/\//.test( sel.getText() ) )
					continue

				out = func( sel )
				if out?
					sel.insertText( out.toString() )

		# Set cursor back to where it was if we moved it
		if atom.config.get( "calc.evaluateAllOnEmptySelection" ) and cur_pos?
			editor.setCursorScreenPosition( cur_pos )

	## Commands ################################################################

	editorEvaluate: ->
		@iterateSelections( ( sel ) =>
			result = @calculateResult( sel.getText() )
			if not result?
				return

			return sel.getText() + " = " + result
		)

	editorReplace: ->
		@iterateSelections( ( sel ) =>
			result = @calculateResult( sel.getText() )
			if not result?
				return
			if parseInt(result) == parseInt(parseInt(result), 10)
				result = parseFloat(result.toFixed(4))
			return result
		)

	editorCount: ->
		i = atom.config.get( "calc.countStartIndex" )
		@iterateSelections( ( ( sel ) => i++ ), include_empty: true )
