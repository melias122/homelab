flake-switch: flake-update
	sudo nixos-rebuild switch --flake .

flake-update:
	nix flake update

flake-boot:
	sudo nixos-rebuild boot --flake .

deploy-server:
	rsync -avh --exclude={'.git','flake*'} . root@server:/etc/nixos --delete
	ssh root@server -C "ln -s /etc/nixos/machines/server/configuration.nix /etc/nixos && \
nixos-rebuild boot"

deploy-router:
	rsync -avh --exclude={'.git','flake*'} . root@router:/etc/nixos --delete
	ssh root@router -C "ln -s /etc/nixos/machines/router/configuration.nix /etc/nixos/ && \
nixos-rebuild boot"

deploy-router-home:
	rsync -avh --exclude={'.git','flake*'} . root@router-home:/etc/nixos --delete
	ssh root@router-home -C "ln -s /etc/nixos/machines/router-home/configuration.nix /etc/nixos/ && \
nixos-rebuild boot"
