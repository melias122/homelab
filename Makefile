flake-switch-box:
	sudo nixos-rebuild switch --flake ./machines/box

flake-update-switch-box:
	nix flake update --flake ./machines/box
	sudo nixos-rebuild switch --flake ./machines/box

flake-update-boot-box:
	nix flake update --flake ./machines/box
	sudo nixos-rebuild boot --flake ./machines/box

deploy-all: deploy-server deploy-router-home deploy-router

deploy-server:
	rsync -avh --exclude={'.git','flake*','*oddin*'} --delete-excluded . root@server:/etc/nixos --delete
	ssh root@server -C "ln -sf /etc/nixos/machines/server/configuration.nix /etc/nixos && \
nixos-rebuild switch"

deploy-router:
	rsync -avh --exclude={'.git','flake*','*oddin*'} --delete-excluded . root@router:/etc/nixos --delete
	ssh root@router -C "ln -sf /etc/nixos/machines/router/configuration.nix /etc/nixos/ && \
nixos-rebuild boot"

deploy-router-home:
	rsync -avh --exclude={'.git','flake*','*oddin*'} --delete-excluded . root@router-home:/etc/nixos --delete
	ssh root@router-home -C "ln -sf /etc/nixos/machines/router-home/configuration.nix /etc/nixos/ && \
nixos-rebuild boot"

flake-switch-MacBook-Air:
	nix flake update --flake ./machines/MacBook-Air
	nix develop ./machines/MacBook-Air --command apply-nix-darwin-configuration

# usage: make edit-secret name=caddy-env
edit-secret:
	cd secrets && nix run github:ryantm/agenix/0.15.0 -- -e $(name).age -i ~/.ssh/id_ed25519

# re-encrypt all secrets after changing recipients in secrets/secrets.nix
rekey-secrets:
	cd secrets && nix run github:ryantm/agenix/0.15.0 -- --rekey -i ~/.ssh/id_ed25519
