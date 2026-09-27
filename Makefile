SRC_YAML	= srcs/docker-compose.yml

all:
	@mkdir -p /home/wal-deek/data/wordpress
	@mkdir -p /home/wal-deek/data/mariadb
	docker compose -f $(SRC_YAML) up --build -d

up:
	docker compose -f $(SRC_YAML) up -d

down:
	docker compose -f $(SRC_YAML) down

start:
	docker compose -f $(SRC_YAML) start

stop:
	docker compose -f $(SRC_YAML) stop

clean:
	docker compose -f $(SRC_YAML) down --volumes --rmi all

fclean: clean
	@sudo rm -rf /home/wal-deek/data/wordpress/*
	@sudo rm -rf /home/wal-deek/data/mariadb/*

re: fclean
	$(MAKE) all


.PHONY: all up down start stop clean fclean re
