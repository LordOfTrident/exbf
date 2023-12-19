defmodule Exbf do
	def default_tape_size, do: 30000
	def default_cell_bits, do: 8

	@inst_inc        "+"
	@inst_dec        "-"
	@inst_left       "<"
	@inst_right      ">"
	@inst_output     "."
	@inst_input      ","
	@inst_loop_start "["
	@inst_loop_end   "]"

	defmodule Tape do
		defstruct cells: [], ptr: 0, cell_max: 255

		defmodule InvalidAccess do
			defexception message: "Access outside of tape boundaries"
		end

		def inc(tape), do:
			%{tape | cells: tape.cells |> List.update_at(tape.ptr, &(rem(&1 + 1, tape.cell_max)))}

		def dec(tape), do:
			%{tape | cells: tape.cells |> List.update_at(tape.ptr, &(rem(&1 - 1, tape.cell_max)))}

		def left!(tape) do
			new_ptr = tape.ptr - 1
			if new_ptr < 0, do:
				raise InvalidAccess

			%{tape | ptr: new_ptr}
		end

		def right!(tape) do
			new_ptr = tape.ptr + 1
			if new_ptr >= length(tape.cells), do:
				raise InvalidAccess

			%{tape | ptr: new_ptr}
		end

		def write(tape, value), do:
			%{tape | cells: tape.cells |> List.replace_at(tape.ptr, rem(value, tape.cell_max))}

		def read(tape), do:
			tape.cells |> Enum.at(tape.ptr)

		def clear(tape), do:
			%{tape | cells: tape.cells |> Enum.map(fn _ -> 0 end)}

		def new(size, cell_bits) do
			%Tape{
				cells:    List.duplicate(0, size),
				cell_max: trunc(:math.pow(2, cell_bits)) - 1,
			}
		end
	end

	defmodule Loc do
		defstruct row: 1, col: 1, from: ""

		def next_col(loc), do: %{loc | col: loc.col + 1}
		def next_row(loc), do: %{loc | row: loc.row + 1, col: 1}
	end

	defmodule ExecError do
		defexception message: "", loc: %Loc{}
	end

	defp match_loop_end(program, loc), do: program |> match_loop_end(1, 0, loc)

	defp match_loop_end(_, 0, pos, loc), do: {pos, loc}

	defp match_loop_end("", _, _, loc) do
		raise ExecError, message: "Unmatched \"[\"", loc: loc
	end

	defp match_loop_end(@inst_loop_start <> rest, depth, pos, loc), do:
		rest |> match_loop_end(depth + 1, pos + 1, loc |> Loc.next_col)

	defp match_loop_end(@inst_loop_end <> rest, depth, pos, loc), do:
		rest |> match_loop_end(depth - 1, pos + 1, loc |> Loc.next_col)

	defp match_loop_end("\n" <> rest, depth, pos, loc), do:
		rest |> match_loop_end(depth, pos + 1, loc |> Loc.next_row)

	defp match_loop_end(<<_>> <> rest, depth, pos, loc), do:
		rest |> match_loop_end(depth, pos + 1, loc |> Loc.next_col)

	defp exec_next(@inst_inc <> rest, loc, tape), do:
		rest |> exec_next(loc |> Loc.next_col, tape |> Tape.inc)

	defp exec_next(@inst_dec <> rest, loc, tape), do:
		rest |> exec_next(loc |> Loc.next_col, tape |> Tape.dec)

	defp exec_next(@inst_left <> rest, loc, tape) do
		try do
			rest |> exec_next(loc |> Loc.next_col, tape |> Tape.left!)
		rescue
			e in Tape.InvalidAccess -> raise ExecError, message: e.message, loc: loc
		end
	end

	defp exec_next(@inst_right <> rest, loc, tape) do
		try do
			rest |> exec_next(loc |> Loc.next_col, tape |> Tape.right!)
		rescue
			e in Tape.InvalidAccess -> raise ExecError, message: e.message, loc: loc
		end
	end

	defp exec_next(@inst_output <> rest, loc, tape) do
		IO.write <<tape |> Tape.read::utf8>>

		rest |> exec_next(loc |> Loc.next_col, tape)
	end

	defp exec_next(@inst_input <> rest, loc, tape) do
		input = IO.getn ""
		value =
			if input == :eof do
				0
			else
				input
				|> :binary.bin_to_list
				|> Enum.at(0)
			end

		rest |> exec_next(loc |> Loc.next_col, tape |> Tape.write(value))
	end

	defp exec_next(@inst_loop_start <> rest, loc, tape) do
		{end_pos, end_loc} = rest |> match_loop_end(loc)
		case tape |> Tape.read do
			0 -> rest
				|> String.slice(end_pos .. -1)
				|> exec_next(end_loc |> Loc.next_col, tape)

			_ ->
				tape = rest
					|> String.slice(0 .. end_pos - 1)
					|> exec_next(loc |> Loc.next_col, tape)

				@inst_loop_start <> rest |> exec_next(loc, tape)
		end
	end

	defp exec_next("\n"  <> rest, loc, tape), do: exec_next(rest, loc |> Loc.next_row, tape)
	defp exec_next(<<_>> <> rest, loc, tape), do: exec_next(rest, loc |> Loc.next_col, tape)
	defp exec_next("",           _loc, tape), do: tape

	def exec!(program, from, tape), do:
		program |> exec_next(%Loc{from: from}, tape)

	def exec(program, from, tape) do
		try do
			{:ok, program |> exec!(from, tape), nil, nil}
		rescue
			e in ExecError -> {:error, tape, e.loc, e.message}
		end
	end
end
