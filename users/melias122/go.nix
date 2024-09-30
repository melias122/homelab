{ config, pkgs, ... }:

let
  pprofbench = pkgs.writeScriptBin "pprofbench"
    ''
			#!/bin/bash
			set -ex
			go test -bench=''${1:-.} -cpuprofile=cpu.pprof -memprofile=mem.pprof -count=5
		'';

  scripts = [
    pprofbench
  ];

in {
  home.packages = with pkgs; [
    delve
    gopls
  ] ++ scripts;

  programs.go = {
    enable = true;
  };

  home.sessionPath = [
    "$HOME/code/go/bin" # For custom go version's
    "$HOME/go/bin"
  ];
}
