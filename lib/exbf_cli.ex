defmodule Exbf.CLI do
	@flag_help      :help
	@flag_tape_size :tapesize
	@flag_cell_bits :cellbits

	@alias_help      :h
	@alias_tape_size :s
	@alias_cell_bits :b

	@logo_color_a IO.ANSI.reset <> IO.ANSI.bright <> IO.ANSI.magenta
	@logo_color_b IO.ANSI.reset <> IO.ANSI.bright <> IO.ANSI.white
	@prompt_color IO.ANSI.reset <> IO.ANSI.bright <> IO.ANSI.blue

	def error(msg) do
		title = "#{IO.ANSI.bright}#{IO.ANSI.red}Error:#{IO.ANSI.reset}"
		IO.puts :stderr, "#{title} #{msg}"
	end

	def error_from(loc, msg) do
		error("#{IO.ANSI.bright}#{loc.from}:#{loc.row}:#{loc.col}: #{IO.ANSI.reset}#{msg}")
	end

	defp prompt(str) do
		IO.write str <> " "
		IO.read(:stdio, :line) |> String.trim
	end

	defp flag_or_default(flags, flag, default) do
		result = flags |> Enum.find(fn {name, _} -> name == flag end)

		if result == nil do
			default
		else
			elem(result, 1)
		end
	end

	defp usage() do
		IO.puts "" <>
"            #{@logo_color_b}_      __
 #{@logo_color_a}  _____  _#{@logo_color_b}| |__  / _|
 #{@logo_color_a} / _ \\ \\/ /#{@logo_color_b} '_ \\| |_
 #{@logo_color_a}|  __/>  <#{@logo_color_b}| |_) |  _|
 #{@logo_color_a} \\___/_/\\_\\#{@logo_color_b}_.__/|_|   #{IO.ANSI.reset}A brainfuck interpreter
 (#{IO.ANSI.underline}#{IO.ANSI.blue}https://github.com/lordoftrident/exbf#{IO.ANSI.reset})

Usage: exbf [FILE...] [OPTIONS]
Options:
  -#{@alias_help}, --#{@flag_help}
  -#{@alias_tape_size}, --#{@flag_tape_size} <NUMBER>    Set the tape size (default #{Exbf.default_tape_size})
  -#{@alias_cell_bits}, --#{@flag_cell_bits} <NUMBER>    Set the cell bit size (default #{Exbf.default_cell_bits})"

	end

	defp exec_file(file, tape) do
		case File.read(file) do
			{:ok, content} ->
				{result, tape, err_loc, err_msg} = content |> Exbf.exec(file, tape)
				if result == :error do
					error_from(err_loc, err_msg)
					{:error, tape}
				else
					{:ok, tape}
				end

			{:error, _} ->
				error("Could not read file \"#{file}\"")
				{:error, tape}
		end
	end

	defp insert_newline(), do:
		IO.puts IO.ANSI.bright <> IO.ANSI.light_black <> "⏎" <> IO.ANSI.reset

	defp repl(tape) do
		case prompt("#{@prompt_color}(#{IO.ANSI.reset},#{@prompt_color})#{IO.ANSI.reset}") do
			"exit" -> IO.puts "Exited."

			"exec " <> file ->
				{result, tape} = file |> exec_file(tape)
				if result == :error do
					:timer.sleep(16)
				else
					insert_newline()
				end
				repl(tape)

			"ptr" ->
				IO.puts "#{tape.ptr}"
				repl(tape)

			"help" ->
				IO.puts "help           Show the commands"
				IO.puts "exit           Exit the REPL"
				IO.puts "clear          Clear the tape"
				IO.puts "exec <FILE>    Execute a file"
				IO.puts "ptr            Print the current tape pointer position"
				repl(tape)

			"clear" ->
				IO.puts "Cleared the tape."
				repl(tape |> Exbf.Tape.clear)

			input ->
				{result, tape, err_loc, err_msg} = input |> Exbf.exec("stdin", tape)
				if result == :error do
					error_from(err_loc, err_msg)
					:timer.sleep(16) # Elixir does not have IO flushing, so i have to use this bad
					                 # bad dirty workaround. My fault for using a language designed
					                 # for servers.
				else
					if input
						|> String.graphemes
						|> Enum.find(fn x -> x == "." end),
					do:
						insert_newline()
				end

				repl(tape)
		end
	end

	defp start_repl(tape) do
		IO.puts ">> #{@logo_color_a}ex#{@logo_color_b}bf#{IO.ANSI.reset} REPL"
		IO.puts "Type \"help\" to show all commands"
		IO.puts ""

		repl(tape)
	end

	defp parse_args(args) do
		{flags, files, invalid} = args |> OptionParser.parse(
			aliases: [
				{@alias_help,      @flag_help},
				{@alias_tape_size, @flag_tape_size},
				{@alias_cell_bits, @flag_cell_bits},
			],
			strict: [
				{@flag_help,      :boolean},
				{@flag_tape_size, :integer},
				{@flag_cell_bits, :integer},
			]
		)

		if invalid != [] do
			{flag, value} = invalid |> Enum.at(0)
			error("Invalid value for flag \"#{flag}\": #{value}")
			System.halt(1)
		end

		{flags, files}
	end

	def main(args \\ []) do
		{flags, files} = args |> parse_args

		help      = flags |> flag_or_default(@flag_help,      false)
		tape_size = flags |> flag_or_default(@flag_tape_size, Exbf.default_tape_size)
		cell_bits = flags |> flag_or_default(@flag_cell_bits, Exbf.default_cell_bits)

		if help do
			usage()
			System.halt(0)
		end

		tape = Exbf.Tape.new(tape_size, cell_bits)

		if files != [] do
			for file <- files do
				{result, _} = file |> exec_file(tape)
				if result == :error, do:
					System.halt(1)
			end
		else
			start_repl(tape)
		end
	end
end
