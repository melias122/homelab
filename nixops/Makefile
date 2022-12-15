NIX_BUILD_CORES=8

deploy-dry-run:
	nixops deploy -d homelab --dry-run

deploy:
	nixops deploy -d homelab

deploy-server:
	nixops deploy -d homelab --include server

deploy-router:
	nixops deploy -d homelab --include router

create:
	nixops create -d homelab ./*.nix
