describe "calc", ->

	activatePromise = null
	editor = null
	editor_view = null

	exec = ( command, callback ) ->
		atom.commands.dispatch( editor_view, command )
		waitsForPromise ->
			return activatePromise
		runs( callback )

	beforeEach ->
		waitsForPromise ->
			atom.workspace.open()

		runs ->
			editor = atom.workspace.getActiveTextEditor()
			editor_view = atom.views.getView( editor )

			activatePromise = atom.packages.activatePackage( "calc" )

		atom.config.set( "calc.evaluateAllOnEmptySelection", true )

	describe "when the 'calc:evaluate' command is run", ->

		it "evaluates expressions selected", ->
			editor.setText( """
				1 + 2
				2 + 3
			""" )
			editor.setCursorBufferPosition [ 0, 0 ]
			editor.selectToEndOfLine()

			exec( "calc:evaluate", ->
				expect( editor.getText() ).toBe( """
					1 + 2 = 3
					2 + 3
				""" )
			)

		it "evaluates expressions selected in-line", ->
			editor.setText( "TEST1 + 2TEXT" )
			editor.setCursorBufferPosition [ 0, 4 ]
			editor.selectRight( 5 )

			exec( "calc:evaluate", ->
				expect( editor.getText() ).toBe( "TEST1 + 2 = 3TEXT" )
			)


		it "evaluates expressions in multiple selections", ->
			editor.setText( """
				1 + 2
				2 + 3
			""" )
			editor.setCursorBufferPosition [ 0, 0 ]
			editor.addCursorAtBufferPosition [ 1, 0 ]
			editor.selectToEndOfLine()

			exec( "calc:evaluate", ->
				expect( editor.getText() ).toBe ( """
					1 + 2 = 3
					2 + 3 = 5
				""" )
			)

		it "can access javascript functions", ->
			editor.setText( "Math.pow( 3, 2 )" )
			editor.selectAll()

			exec( "calc:evaluate", ->
				expect( editor.getText() ).toBe( "Math.pow( 3, 2 ) = 9" )
			)

	describe "when the 'calc:replace' command is run", ->

		it "replaces expressions selected", ->
			editor.setText( """
				1 + 2
				2 + 3
			""" )
			editor.setCursorBufferPosition [ 0, 0 ]
			editor.selectToEndOfLine()

			exec( "calc:replace", ->
				expect( editor.getText() ).toBe( """
					3
					2 + 3
				""" )
			)

		it "replaces expressions in multiple selections", ->
			editor.setText( """
				1 + 2
				2 + 3
			""" )
			editor.setCursorBufferPosition [ 0, 0 ]
			editor.addCursorAtBufferPosition [ 1, 0 ]
			editor.selectToEndOfLine()

			exec( "calc:replace", ->
				expect( editor.getText() ).toBe ( """
					3
					5
				""" )
			)

		it "ignores empty selections", ->
			editor.setText( """
				1 + 2

				2 + 3
			""" )
			editor.setCursorBufferPosition [ 0, 0 ]
			editor.addCursorAtBufferPosition [ 1, 0 ]
			editor.addCursorAtBufferPosition [ 2, 0 ]
			editor.selectToEndOfLine()

			exec( "calc:replace", ->
				expect( editor.getText() ).toBe ( """
					3

					5
				""" )
			)

	describe "when the 'calc:evaluate' command is run", ->

		it "evaluates expressions selected", ->
			editor.setText( """
				1 + 2
				2 + 3
			""" )
			editor.setCursorBufferPosition [ 0, 0 ]
			editor.selectToEndOfLine()

			exec( "calc:evaluate", ->
				expect( editor.getText() ).toBe( """
					1 + 2 = 3
					2 + 3
				""" )
			)

		it "replaces expressions in multiple selections", ->
			editor.setText( """
				1 + 2
				2 + 3
			""" )
			editor.setCursorBufferPosition [ 0, 0 ]
			editor.addCursorAtBufferPosition [ 1, 0 ]
			editor.selectToEndOfLine()

			exec( "calc:evaluate", ->
				expect( editor.getText() ).toBe ( """
					1 + 2 = 3
					2 + 3 = 5
				""" )
			)

		it "ignores empty selections", ->
			editor.setText( """
				1 + 2

				2 + 3
			""" )
			editor.setCursorBufferPosition [ 0, 0 ]
			editor.addCursorAtBufferPosition [ 1, 0 ]
			editor.addCursorAtBufferPosition [ 2, 0 ]
			editor.selectToEndOfLine()

			exec( "calc:evaluate", ->
				expect( editor.getText() ).toBe ( """
					1 + 2 = 3

					2 + 3 = 5
				""" )
			)

	describe "when the 'calc:count' command is run", ->

		beforeEach ->
			atom.config.set( "calc.countStartIndex", 0 )

		it "appends a number for each selection", ->
			editor.setText( "\n\n\n" )
			editor.setCursorBufferPosition [ 0, 0 ]
			for i in [1..3]
				editor.addCursorAtBufferPosition [ i, 0 ]

			exec( "calc:count", ->
				expect( editor.getText() ).toBe( """
					0
					1
					2
					3
				""" )
			)

		it "does not ignore empty selections", ->
			editor.setText( """
				1 + 2

				2 + 3
			""" )
			editor.setCursorBufferPosition [ 0, 0 ]
			editor.addCursorAtBufferPosition [ 1, 0 ]
			editor.addCursorAtBufferPosition [ 2, 0 ]
			editor.selectToEndOfLine()

			exec( "calc:count", ->
				expect( editor.getText() ).toBe ( """
					0
					1
					2
				""" )
			)

	describe "'calc.evaluateAllOnEmptySelection'", ->

		describe "when true", ->

			beforeEach ->
				atom.config.set( "calc.evaluateAllOnEmptySelection", true )

			it "evalues each line as an expression when there's no selection", ->
				editor.setText( """
					1 + 2
					2 + 3
					3 + 4
				""" )

				exec( "calc:evaluate", ->
					expect( editor.getText() ).toBe( """
						1 + 2 = 3
						2 + 3 = 5
						3 + 4 = 7
					""" )
				)

			it "still only evaluates inside a selection if one is present", ->
				editor.setText( """
					1 + 2
					2 + 3
					3 + 4
				""" )
				editor.setCursorBufferPosition [ 0, 0 ]
				editor.selectToEndOfLine()

				exec( "calc:evaluate", ->
					expect( editor.getText() ).toBe( """
						1 + 2 = 3
						2 + 3
						3 + 4
					""" )
				)

		describe "when false", ->

			beforeEach ->
				atom.config.set( "calc.evaluateAllOnEmptySelection", false )

			it "does nothing when there's no selection", ->
				editor.setText( """
					1 + 2
					2 + 3
					3 + 4
				""" )

				exec( "calc:evaluate", ->
					expect( editor.getText() ).toBe( """
						1 + 2
						2 + 3
						3 + 4
					""" )
				)

			it "still evaluates inside a selection if one is present", ->
				editor.setText( """
					1 + 2
					2 + 3
					3 + 4
				""" )
				editor.setCursorBufferPosition [ 0, 0 ]
				editor.selectToEndOfLine()

				exec( "calc:evaluate", ->
					expect( editor.getText() ).toBe( """
						1 + 2 = 3
						2 + 3
						3 + 4
					""" )
				)

	describe "'calc.extendedVariables'", ->

		describe "when true", ->

			beforeEach ->
				atom.config.set( "calc.extendedVariables", true )

			it "makes '_' contain the result of the previous expression", ->
				editor.setText( """
					2 + 4
					_ + 2
					_ + 3
				""" )

				exec( "calc:evaluate", ->
					expect( editor.getText() ).toBe( """
						2 + 4 = 6
						_ + 2 = 8
						_ + 3 = 11
					""" )
				)

			it "makes '_n' contain the result of the `_n`th expression", ->
				editor.setText( """
					1 + 2
					2 + 3
					_1 + _2
					_1 + _3
				""" )

				exec( "calc:evaluate", ->
					expect( editor.getText() ).toBe( """
						1 + 2 = 3
						2 + 3 = 5
						_1 + _2 = 8
						_1 + _3 = 11
					""" )
				)

			it "makes 'i' contain the id number of the expression being evaluated", ->
				atom.config.set( "calc.countStartIndex", 0 )
				editor.setText( """
					i * i
					i * i
					i * i
					i * i
				""" )

				exec( "calc:evaluate", ->
					expect( editor.getText() ).toBe( """
						i * i = 0
						i * i = 1
						i * i = 4
						i * i = 9
					""" )
				)

		describe "when false", ->

			beforeEach ->
				atom.config.set( "calc.extendedVariables", false )

			it "makes '_', '_n', and 'i' have no special value", ->
				editor.setText( """
					typeof _
					typeof _1
					typeof i
				""" )

				exec( "calc:evaluate", ->
					expect( editor.getText() ).toBe( """
						typeof _ = undefined
						typeof _1 = undefined
						typeof i = undefined
					""" )
				)

	describe "'calc.withMath'", ->

		describe "when true", ->

			beforeEach ->
				atom.config.set( "calc.withMath", true )

			it "allows accessing of Math functions with a 'Math' prefix", ->
				editor.setText( """
					pow( 2, 2 )
					pow( 3, 2 )
					max( 1, 4, 2 )
					floor( 0.5 )
				""" )

				exec( "calc:evaluate", ->
					expect( editor.getText() ).toBe( """
						pow( 2, 2 ) = 4
						pow( 3, 2 ) = 9
						max( 1, 4, 2 ) = 4
						floor( 0.5 ) = 0
					""" )
				)

			it "still allows access to Math functions via the 'Math' object", ->
				editor.setText( """
					Math.pow( 2, 2 )
					Math.pow( 3, 2 )
					Math.max( 1, 4, 2 )
					Math.floor( 0.5 )
				""" )

				exec( "calc:evaluate", ->
					expect( editor.getText() ).toBe( """
						Math.pow( 2, 2 ) = 4
						Math.pow( 3, 2 ) = 9
						Math.max( 1, 4, 2 ) = 4
						Math.floor( 0.5 ) = 0
					""" )
				)

			it "does not error with expressions containing comments", ->
				editor.setText( """
					1 + 2 // Math
				""" )

				exec( "calc:evaluate", ->
					expect( editor.getText() ).toBe( """
						1 + 2 // Math = 3
					""" )
				)

		describe "when false", ->

			beforeEach ->
				atom.config.set( "calc.withMath", false )

			it "does not allow access to 'Math' functions without a 'Math' prefix", ->
				editor.setText( """
					typeof pow
					typeof max
				""" )

				exec( "calc:evaluate", ->
					expect( editor.getText() ).toBe( """
						typeof pow = undefined
						typeof max = undefined
					""" )
				)

			it "still allows access to Math functions via the 'Math' object", ->
				editor.setText( """
					Math.pow( 2, 2 )
					Math.pow( 3, 2 )
					Math.max( 1, 4, 2 )
					Math.floor( 0.5 )
				""" )

				exec( "calc:evaluate", ->
					expect( editor.getText() ).toBe( """
						Math.pow( 2, 2 ) = 4
						Math.pow( 3, 2 ) = 9
						Math.max( 1, 4, 2 ) = 4
						Math.floor( 0.5 ) = 0
					""" )
				)

	describe "'calc.countStartIndex'", ->

		describe "when 0", ->

			it "starts the expression count at 0", ->
				atom.config.set( "calc.countStartIndex", 0 )
				editor.setText( "\n\n" )
				exec( "calc:count", ->
					expect( editor.getText() ).toBe( "0\n1\n" )
				)

		describe "when 1", ->

			it "starts the expression count at 1", ->
				atom.config.set( "calc.countStartIndex", 1 )
				editor.setText( "\n\n" )
				exec( "calc:count", ->
					expect( editor.getText() ).toBe( "1\n2\n" )
				)

	describe "'Math.pwd'", ->

		describe "when given a number argument", ->

			it "generates a random string of a given length", ->
				editor.setText( """
					Math.pwd( 10 ).length
					Math.pwd( 20 ).length
					Math.pwd( 50 ).length
				""" )
				exec( "calc:evaluate", ->
					expect( editor.getText() ).toBe( """
						Math.pwd( 10 ).length = 10
						Math.pwd( 20 ).length = 20
						Math.pwd( 50 ).length = 50
					""" )
				)

		describe "when given no arguments", ->

			it "generates a password of length 20", ->
				editor.setText( "Math.pwd().length" )
				exec( "calc:evaluate", ->
					expect( editor.getText() ).toBe( "Math.pwd().length = 20" )
				)
