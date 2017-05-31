#!/bin/bash

update_images () { 
	# update infrastructure
	docker-compose -f infra/docker-compose.yml -f infra/uaa/docker-compose.yml --project-name nimbleinfra pull

	# update services
	docker-compose -f services/docker-compose.yml --project-name nimbleservices pull

}

# run infrastructure
if [[ "$1" = "infrastructure" ]]; then

	update_images
	docker-compose -f infra/docker-compose.yml -f infra/uaa/docker-compose.yml --project-name nimbleinfra up --build

elif [[ "$1" = "services" ]]; then

	update_images
	docker-compose -f services/docker-compose.yml --project-name nimbleservices up --build

elif [[ "$1" = "start" ]]; then

	update_images

	# start infrastructure
	docker-compose -f infra/docker-compose.yml -f infra/uaa/docker-compose.yml --project-name nimbleinfra up -d --build

	# wait for gateway proxy (last service started before)
	echo "Stalling for Gateway Proxy"
	docker run --rm --net=nimbleinfra_default -it mcandre/docker-wget --retry-connrefused --waitretry=5 --read-timeout=20 --timeout=15 --tries 60 gateway-proxy:80

	# start services
	docker-compose -f services/docker-compose.yml --project-name nimbleservices up -d --build

elif [[ "$1" = "stop" ]]; then
	
	docker-compose -f services/docker-compose.yml --project-name nimbleservices down
	docker-compose -f infra/docker-compose.yml -f infra/uaa/docker-compose.yml --project-name nimbleinfra down

elif [[ "$1" = "services-logs" ]]; then

	docker-compose -f services/docker-compose.yml --project-name nimbleservices logs -f
	
else
    echo Usage: $0 COMMAND
    echo Commands:
    echo "  infrastructure to start only infastructure components"
    echo "  services to start actual services"
    echo "  start to start everything"
    echo "  stop to stop everything"
    exit 2
fi
