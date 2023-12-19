<p align="center"><img width="350px" src="res/logo.png"></p>
<p align="center">A Brainfuck interpreter in Elixir</p>

<p align="center">
	<a href="./LICENSE">
		<img alt="License" src="https://img.shields.io/badge/license-GPL v3-26c374?style=for-the-badge">
	</a>
	<a href="https://github.com/LordOfTrident/exbf/issues">
		<img alt="Issues" src="https://img.shields.io/github/issues/LordOfTrident/exbf?style=for-the-badge&color=4f79e4">
	</a>
	<a href="https://github.com/LordOfTrident/exbf/pulls">
		<img alt="GitHub pull requests" src="https://img.shields.io/github/issues-pr/LordOfTrident/exbf?style=for-the-badge&color=4f79e4">
	</a>
	<br><br><br>
</p>

> [!WARNING]
> This interpreter is pretty slow. If you want a fast one, try [brainfcxx](http://github.com/lordoftrident/brainfcxx)

An interpreter for the [Brainfuck](https://en.wikipedia.org/wiki/Brainfuck) esoteric programming
language written in [Elixir](https://elixir-lang.org/). I wrote this purely to practice Elixir
and to see how good it is for CLI app developement (spoiler: not very good, should probably stick
to server related stuff).

## Table of contents
* [Quickstart](#quickstart)
* [Bugs](#bugs)

## Quickstart
```sh
$ git clone https://github.com/LordOfTrident/exbf
$ cd exbf
$ mix escript.install
$ exbf -h
```

You can alternatively use `mix escript.build` to just build the app without installing.

## Bugs
If you find any bugs, please create an issue and report them.
