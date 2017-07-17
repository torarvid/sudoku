#!/usr/bin/ruby

class SudokuHelper < Array
	def row( number )
		if block_given?
			self[ number ].each { |n| yield n }
			self
		else
			return self[ number ]
		end
	end
	
	def row_with_index( number )
		index = 0
		row( number ) do |r| 
			r.each { |n| yield n, index }
			index += 1
		end
		self
	end
	
	def row!( number )
		edited = false
		self[ number ].collect! do |n| 
			val = n.dup
			yield n
			edited = val != n unless edited
			n
		end
		return edited ? self[ number ] : nil
	end
	
	def col( number )
		if block_given?
			(0...9).each { |r| yield self[ r ][ number ] }
			self
		else
			carr = []
			col( number ) { |r| carr << r }
			return carr
		end
	end
	
	def col_with_index( number )
		index = 0
		col( number ) do |c|
			c.each { |n| yield n, index }
			index += 1	
		end
		self
	end
	
	def col!( number )
		edited = false
		(0...9).each do |r|
			val = self[ r ][ number ].dup
			self[ r ][ number ] = yield self[ r ][ number ]
			edited = self[ r ][ number ] != val unless edited
		end
		return edited ? col( number ) : nil
	end
	
	def square( number )
		if block_given?
			cs = ( number % 3 ) * 3
			rs = ( number / 3 ) * 3
			(0...3).each do |m|
				(0...3).each do |n|
					yield self[ m + rs ][ n + cs ]
				end
			end
			self
		else
			sarr = []
			square( number ) { |n| sarr << n }
			return sarr
		end
	end
	
	def square!( number )
		cs = ( number % 3 ) * 3
		rs = ( number / 3 ) * 3
		edited = false
		(0...3).each do |m|
			(0...3).each do |n|
				val = self[ m + rs ][ n + cs ].dup
				self[ m + rs ][ n + cs ] = yield self[ m + rs ][ n + cs ]
				edited = self[ m + rs ][ n + cs ] != val unless edited
			end
		end
		return edited ? square( number ) : nil
	end
end

def validate
	for i in (0...9)
		for j in (0...9)
			num = $sudoku[i][j]
			return false if num == 0 and $helper[i][j].length < 1
			next if num == 0
			for k in (0...9)
				unless k == i
					return false if $sudoku[k][j] == num
				end
				unless k == j
					return false if $sudoku[i][k] == num
				end
				icorner = (i/3)*3
				jcorner = (j/3)*3
			end
			for k in (0...3)
				for l in (0...3)
					r = icorner + k
					c = jcorner + l
					unless r == i and c == j
						return false if $sudoku[r][c] == num
					end
				end
			end
		end
	end
	return true
end

def isDone
	9.times { |i| return false if $sudoku[ i ].include?( 0 ) }
	return true
end

def initHelper
	$helper = SudokuHelper.new
	for i in (0...9)
		$helper << Array.new
		9.times { $helper[i] << (1..9).to_a }
	end
end

def max( l, r )
	return l unless r > l
	return r
end

def alen( object )
	return object.length if object.class == Array
	return 1
end

def astr( object )
	if object.class == Array
		tmp = object.collect { |n| n.to_s + ',' }.join
		tmp.chop! unless tmp == nil
		return tmp
	else
		return object == 0 ? ' ' : object.to_s
	end
end

def prettyprint( arr )
	colwidth = Array.new( 9, 1 )
	for i in 0...9
		for j in 0...9
			val = alen( arr[ i ][ j ] )
			colwidth[ j ] = max( val, colwidth[ j ] )
		end
	end
	print "╔═" + '══' * max( colwidth[ 0 ] - 1, 1 )
	(1...9).each { |i| print (i % 3 == 0 ? '╦═' : '╤═') + '══' * max( colwidth[ i ] - 1, 1 ) }
	print "╗\n"
	for i in 0...9
		for j in 0...9
			print j % 3 == 0 ? '║' : '│'
			numbers = astr( arr[ i ][ j ] )
			numbers == '  ' if numbers == nil
			print numbers.center( max( colwidth[ j ] * 2 - 1, 3 ) )
		end
		print "║\n"
		break if i >= 8
		print (( i + 1 ) % 3 == 0 ? "╠" : "║")
		for j in 0...8
			cw = max( colwidth[ j ] - 1, 1 )
			if ( i + 1 ) % 3 == 0
				print '══' * cw, (( j + 1 ) % 3 == 0 ? '═╬' : '═╪')
			else
				print '──' * cw, ( j + 1 ) % 3 == 0 ? '─╫' : '─┼'
			end
		end
		cw = max( colwidth[ 8 ] - 1, 1 )
		( i + 1 ) % 3 == 0 ? ( print '══' * cw, '═╣' ) : ( print '──' * cw, '─╢')
		print "\n"
	end
	print "╚"
	for j in 0...8
		cw = max( colwidth[ j ] - 1, 1 )
		print '══' * cw, (( j + 1 ) % 3 == 0 ? '═╩' : '═╧')
	end
	cw = max( colwidth[ 8 ] - 1, 1 )
	print '══' * cw, '═╝'
	print "\n"
end

def updateHelper
	for i in 0...9
		for j in 0...9
			next if $sudoku[ i ][ j ] == 0
			for k in 0...9
				$sudoku[ i ][ j ]
				$helper[ i ][ k ].delete( $sudoku[ i ][ j ] )
				$helper[ k ][ j ].delete( $sudoku[ i ][ j ] )
			end
			icorner = ( i / 3 ) * 3
			jcorner = ( j / 3 ) * 3
			for k in 0...3
				for l in 0...3
					hx, hy = icorner + k, jcorner + l
					$helper[ hx ][ hy ].delete( $sudoku[ i ][ j ] )
				end
			end
			$helper[ i ][ j ].clear
		end
	end
end

def makeDict( row, col, value, reason )
	dict = Hash.new
	dict[ 'row' ] = row
	dict[ 'col' ] = col
	dict[ 'value' ] = value
	dict[ 'reason' ] = reason
	return dict
end

class AlgEasyUpdate
	def algorithm
		dict = Hash.new
		for i in 0...9
			for j in 0...9
				next unless $helper[ i ][ j ].length == 1
				dict[ 'row' ] = i
				dict[ 'col' ] = j
				dict[ 'value' ] = $sudoku[ i ][ j ] = $helper[ i ][ j ][ 0 ]
				dict[ 'reason' ] = "( #{i+1}, #{j+1} ) set to #{$sudoku[i][j]}, " \
					"only possible value"
				return dict
			end
		end
		return dict
	end
end

class AlgSectorUpdate
	def checkHelper( x, y, val, str )
		if $helper[ x ][ y ].include? val
			return makeDict( x, y, $sudoku[ x ][ y ] = val, \
				"( #{x+1}, #{y+1} ) set to #{val}, only possible in #{str}" )
		end
		return nil
	end

	def algorithm
		for i in 0...9
			rowarr = Array.new( 9, 0 )
			colarr = Array.new( 9, 0 )
			sqarr = Array.new( 9, 0 )
			$helper.row( i ) do |cur| 
				cur.each { |num| rowarr[ num - 1 ] += 1 }
			end
			$helper.col( i ) do |cur|
				cur.each { |num| colarr[ num - 1 ] += 1 }
			end
			$helper.square( i ) do |cur|
				cur.each { |num| sqarr[ num - 1 ] += 1 }
			end
			num = rowarr.index( 1 )
			if num != nil
				num += 1
				for j in 0...9
					val = checkHelper( i, j, num, 'row' )
					return val unless val == nil
				end
			end
			num = colarr.index( 1 )
			if num != nil
				num += 1
				for j in 0...9
					val = checkHelper( j, i, num, 'col' )
					return val unless val == nil
				end
			end
			rs = ( i / 3 ) * 3
			cs = ( i % 3 ) * 3
			num = sqarr.index( 1 )
			if num != nil
				num += 1
				for m in 0...3
					for n in 0...3
						mx = m + rs
						ny = n + cs
						val = checkHelper( mx, ny, num, 'square' )
						return val unless val == nil
					end
				end
			end
		end
		return {}
	end
end

class AlgCheckOwning
	def sqRow( row, col )
		rc = ( row / 3 ) * 3
		cc = ( col / 3 ) * 3
		owninrow = []
		(cc...cc+3).each { |c| owninrow << $helper[ row ][ c ] }
		owninrow.flatten!.uniq!
		(rc...rc+3).each do |r|
			next if r == row
			(cc...cc+3).each do |c|
				$helper[ r ][ c ].each{ |num| owninrow.delete( num ) }
			end
		end
		return owninrow
	end

	def sqCol( row, col )
		rc = ( row / 3 ) * 3
		cc = ( col / 3 ) * 3
		ownincol = []
		(rc...rc+3).each { |r| ownincol << $helper[ r ][ col ] }
		ownincol.flatten!.uniq!
		(rc...rc+3).each do |r|
			(cc...cc+3).each do |c|
				next if c == col
				$helper[ r ][ c ].each{ |num| ownincol.delete( num ) }
			end
		end
		return ownincol
	end

	def algorithm
		(0...9).each do |i|
			0.step( 8, 3 ) do |nr|
				ownrow = sqRow( i, nr )
				taken = []
				(0...6).each do |j|
					index = ( nr + j + 3 ) % 9
					ownrow.each do |num|
						next unless $helper[ i ][ index ].include? num
						$helper[ i ][ index ].delete num
						taken << num unless taken.include? num
					end
				end
				if taken.length > 0
					rc = ( i / 3 ) * 3
					return { "reason" => "#{taken} taken in row #{i+1} by " +
						"square ( #{rc+1}, #{nr+1} ) -> ( #{rc+3}, #{nr+3} )" }
				end
				owncol = sqCol( nr, i )
				(0...6).each do |j|
					index = ( nr + j + 3 ) % 9
					owncol.each do |num|
						next unless $helper[ index ][ i ].include? num
						$helper[ index ][ i ].delete num
						taken << num unless taken.include? num
					end
				end
				if taken.length > 0
					rc = ( i / 3 ) * 3
					return { "reason" => "#{taken} taken in col #{i+1} by " +
						"square ( #{nr+1}, #{rc+1} ) -> ( #{nr+3}, #{rc+3} )" }
				end
			end
		end
		return {}
	end
end

class AlgCheckNakedTuple
	def remove( val, index, str )
		result = nil
		case str
			when 'row'
				result = $helper.row!( index ) do |r|
					val.each { |n| r.delete( n ) } unless val == r
					r
				end

			when 'col'
				result = $helper.col!( index ) do |c|
					val.each { |n| c.delete( n ) } unless val == c
					c
				end

			when 'square'
				result = $helper.square!( index ) do |s|
					val.each { |n| s.delete( n ) } unless val == s
					s
				end
		end
		if result
			return { 'reason' => "found tuple #{val} in #{str} #{index+1}" }
		end
		return nil
	end
	
	def algorithm
		(0...9).each do |i|
			currow = $helper[ i ]
			curcol = []
			(0...9).each { |j| curcol << $helper[ j ][ i ] }
			cursqr = []
			rs = ( i / 3 ) * 3
			cs = ( i % 3 ) * 3
			(0...3).each do |m|
				(0...3).each { |n| cursqr << $helper[ m + rs ][ n + cs ] }
			end
			tdict = { 'row' => currow, 'col' => curcol, 'square' => cursqr }
			tdict.each do |key,val|
				val.each do |row|
					temp = val.select { |r| r == row }
					if temp.size == row.size
						dict = remove( temp[ 0 ], i, key )
						return dict unless dict == nil
					end
				end
			end
		end
		return {}
	end
end

class AlgCheckHiddenTuple
	def algorithm # only 2-tuples for now
		(0...9).each do |i|
			occurrow = {}
			occurcol = {}
			$helper.row_with_index( i ) do |val, index|
				( occurrow[ val ] ||= [] ) << index
			end
			$helper.col_with_index( i ) do |val, index|
				( occurcol[ val ] ||= [] ) << index
			end
			numbers = occurrow.keys
			(0...numbers.size).each do |a|
				(a+1...numbers.size).each do |b|
					if occurrow[ numbers[ a ] ] == occurrow[ numbers[ b ] ] \
					   and occurrow[ numbers[ a ] ].size == 2
						row = i
						removed = false
						k, l = occurrow[ numbers[ a ] ]
						if $helper[ row ][ k ].size > 2
							removed = true
							$helper[ row ][ k ] = [ numbers[ a ], numbers[ b ] ]
						end
						if $helper[ row ][ l ].size > 2
							removed = true
							$helper[ row ][ l ] = [ numbers[ a ], numbers[ b ] ]
						end
						if removed
							return {'reason' => "found hidden tuple " +
								"( #{numbers[ a ]}, #{numbers[ b ]} ) in row" +
								" #{row+1}" }
						end
					end
				end
			end
			numbers = occurcol.keys
			(0...numbers.size).each do |a|
				(a+1...numbers.size).each do |b|
					if occurcol[ numbers[ a ] ] == occurcol[ numbers[ b ] ] \
					   and occurcol[ numbers[ a ] ].size == 2
						col = i
						removed = false
						k, l = occurcol[ numbers[ a ] ]
						if $helper[ k ][ col ].size > 2
							removed = true
							$helper[ k ][ col ] = [ numbers[ a ], numbers[ b ] ]
						end
						if $helper[ l ][ col ].size > 2
							removed = true
							$helper[ l ][ col ] = [ numbers[ a ], numbers[ b ] ]
						end
						if removed
							return {'reason' => "found hidden tuple " +
								"( #{numbers[ a ]}, #{numbers[ b ]} ) in col" +
								" #{col+1}" }
						end
					end
				end
			end
		end
		return {}
	end
end

def tmain( file )
	$sudoku = Array.new
	IO.foreach( file ) do |line|
		$sudoku << line.chomp.split(//).collect { |str| str.to_i }
	end
	unless validate()
		puts "ERROR IN INPUTDATA!"
		exit( 1 )
	end
	algorithms = []
	algorithms << AlgEasyUpdate.new
	algorithms << AlgSectorUpdate.new
	algorithms << AlgCheckOwning.new
	algorithms << AlgCheckNakedTuple.new
	algorithms << AlgCheckHiddenTuple.new

	until isDone
		dict = Hash.new
		prettyprint( $sudoku )
		updateHelper
		prettyprint( $helper )
		updated = false
		algorithms.each do |alg|
			dict = alg.algorithm
			if dict.length > 0
				puts "ERROR IN ALGORTIHM #{alg.class}" unless validate()
				updated = true
				break
			end
		end
		if updated
			puts dict[ 'reason' ]
			puts "Press [Enter] to proceed"
			gets
		else
			puts "Can't update more"
			break
		end
	end
	if isDone
		if validate
			puts "SOLUTION:"
			prettyprint( $sudoku )
		else
			puts "INVALID"
		end
	else
		puts "I'm either too dumb to solve this or it is unsolvable"
	end
end

initHelper()
tmain( ARGV.shift )
