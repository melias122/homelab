deploy-server:
	rsync -avh --exclude .git . root@server:/etc/nixos --delete
	ssh root@server -C "ln -s /etc/nixos/machines/server/configuration.nix /etc/nixos && \
nixos-rebuild switch"

deploy-router:
	rsync -avh --exclude .git . root@router:/etc/nixos --delete
	ssh root@router -C "ln -s /etc/nixos/machines/router/configuration.nix /etc/nixos/ && \
nixos-rebuild switch"
