# Проект по развертыванию GLPI с помощью докера

![Docker Pulls](https://img.shields.io/docker/pulls/diouxx/glpi) ![Docker Stars](https://img.shields.io/docker/stars/diouxx/glpi) [![](https://images.microbadger.com/badges/image/diouxx/glpi.svg)](http://microbadger.com/images/diouxx/glpi "Get your own image badge on microbadger.com") ![Docker Cloud Automated build](https://img.shields.io/docker/cloud/automated/diouxx/glpi)

# Оглавление
- [Проект по развертыванию GLPI с помощью докера](#Проект-по-развертыванию-GLPI-с-помощью-докера)
- [Оглавление](#Оглавление)
- [Введение](#Введение)
  - [Аккаунты по умолчанию](#Аккаунты-по-умолчанию)
- [Развертывание при помощи CLI](#deploy-with-cli)
  - [Развертывание GLPI](#Развертывание-GLPI)
  - [Развертывание GLPI с существующей базой данных](#Развертывание-GLPI-с-существующей-базой-данных)
  - [Развертывание GLPI с базой данных и постоянными данными](#Развертывание-GLPI-с-базой-данных-и-постоянными-данными)
  - [Развертывание конкретной версии GLPI](#Развертывание-конкретной-версии-GLPI)
- [Развертывание при помощи docker-compose](#развертывание-при-помощи-docker-compose)
  - [Развертывание без сохраняемых данных (только для быстрого тестирования!)](#развертывание-без-сохраняемых-данных-только-для-быстрого-тестирования)
  - [Развертывание определенного релиза](#развертывание-определенного-релиза)
  - [Развертывание с постоянными данными для контейнера](#развертывание-с-постоянными-данными-для-контейнера)
    - [mariadb.env](#mariadbenv)
    - [docker-compose .yml](#docker-compose-yml)
- [Переменные среды](#Переменные-среды)
  - [TIMEZONE](#timezone)

# Введение

Установка и запуск GLPI в docker-контейнере.

## Аккаунты по умолчанию

Подробнее тут - 📄[Документация](https://glpi-install.readthedocs.io/en/latest/install/wizard.html#end-of-installation)

| Login/Password     	| Role              	|
|--------------------	|-------------------	|
| glpi/glpi          	| аккаунт админа     	|
| tech/tech          	| technical account 	|
| normal/normal      	| "normal" account  	|
| post-only/postonly 	| post-only account 	|

# Развертывание при помощи CLI

## Развертывание GLPI
```sh
docker run --name mariadb -e MARIADB_ROOT_PASSWORD=diouxx -e MARIADB_DATABASE=glpidb -e MARIADB_USER=glpi_user -e MARIADB_PASSWORD=glpi -d mariadb:10.7
docker run --name glpi --link mariadb:mariadb -p 80:80 -d diouxx/glpi
```

## Развертывание GLPI с существующей базой данных
```sh
docker run --name glpi --link yourdatabase:mariadb -p 80:80 -d diouxx/glpi
```

## Развертывание GLPI с базой данных и постоянными данными

Для использования в проде или постоянного использования на живом сервере, рекомендуется использовать контейнер с томами для постоянных данных.

* Сначала необходимо создать контейнер MariaDB с постоянным томом

```sh
docker run --name mariadb -e MARIADB_ROOT_PASSWORD=diouxx -e MARIADB_DATABASE=glpidb -e MARIADB_USER=glpi_user -e MARIADB_PASSWORD=glpi --volume /var/lib/mysql:/var/lib/mysql -d mariadb:10.7
```

* Далее создаём контейнер GLPI с постоянным томом и связываем его с контейнером MariaDB.

```sh
docker run --name glpi --link mariadb:mariadb --volume /var/www/html/glpi:/var/www/html/glpi -p 80:80 -d diouxx/glpi
```

Наслаждаемся результатом :)

## Развертывание конкретной версии GLPI
По умолчанию при запуске Docker будет использоваться последняя версия GLPI.
Для использования в проде рекомендуется установить конкретную версию.
Вот пример для версии 10.0.14 :
```sh
docker run --name glpi --hostname glpi --link mariadb:mariadb --volume /var/www/html/glpi:/var/www/html/glpi -p 80:80 --env "VERSION_GLPI=10.0.14" -d diouxx/glpi
```

# Развертывание при помощи docker-compose

## Развертывание без сохраняемых данных (только для быстрого тестирования!)
```yaml
version: "3.8"

services:
#MariaDB Container
  mariadb:
    image: mariadb:10.7
    container_name: mariadb
    hostname: mariadb
    environment:
      - MARIADB_ROOT_PASSWORD=password
      - MARIADB_DATABASE=glpidb
      - MARIADB_USER=glpi_user
      - MARIADB_PASSWORD=glpi

#GLPI Container
  glpi:
    image: diouxx/glpi
    container_name : glpi
    hostname: glpi
    ports:
      - "80:80"
```

## Развертывание определенного релиза

```yaml
version: "3.8"

services:
#MariaDB Container
  mariadb:
    image: mariadb:10.7
    container_name: mariadb
    hostname: mariadb
    environment:
      - MARIADB_ROOT_PASSWORD=password
      - MARIADB_DATABASE=glpidb
      - MARIADB_USER=glpi_user
      - MARIADB_PASSWORD=glpi

#GLPI Container
  glpi:
    image: diouxx/glpi
    container_name : glpi
    hostname: glpi
    environment:
      - VERSION_GLPI=10.0.14
    ports:
      - "80:80"
```

## Развертывание с постоянными данными для контейнера
Для развертывания с помощью Docker Compose используются файлы *docker-compose.yml* и *mariadb.env*.
Перед запуском необходимо изменить **_mariadb.env_**, чтобы персонализировать такие параметры, как:

* MariaDB root password
* GLPI database
* GLPI user database
* GLPI user password


### mariadb.env
```
MARIADB_ROOT_PASSWORD=password
MARIADB_DATABASE=glpidb
MARIADB_USER=glpi_user
MARIADB_PASSWORD=glpi
```

### docker-compose .yml
```yaml
version: "3.2"

services:
#MariaDB Container
  mariadb:
    image: mariadb:10.7
    container_name: mariadb
    hostname: mariadb
    volumes:
      - /var/lib/mysql:/var/lib/mysql
    env_file:
      - ./mariadb.env
    restart: always

#GLPI Container
  glpi:
    image: diouxx/glpi
    container_name : glpi
    hostname: glpi
    ports:
      - "80:80"
    volumes:
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
      - /var/www/html/glpi/:/var/www/html/glpi
    environment:
      - TIMEZONE=Europe/Moscow
    restart: always
```

Для развертывания необходимо просто запустить следующую команду в том же каталоге, что и файлы :

```sh
docker-compose up -d
```

# Переменные среды

## TIMEZONE
Если вам необходимо установить часовой пояс для Apache и PHP

При запуске из коносоли :
```sh
docker run --name glpi --hostname glpi --link mariadb:mariadb --volumes-from glpi-data -p 80:80 --env "TIMEZONE=Europe/Moscow" -d diouxx/glpi
```

Если запуск идёт помощи docker-compose, изменяем эти настройки :
```yaml
environment:
     TIMEZONE=Europe/Moscow
```
