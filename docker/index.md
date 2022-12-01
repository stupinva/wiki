Шпаргалка по Docker
===================

[[!tag docker]]


* `docker container ls` - вывести список контейнеров,
* `docker inspect -f '{{ .Mounts }}' <контейнер>` - вывести информацию о каталогах хост-системы, монтируемых в контейнер,
* `docker inspect -f '{{range $index, $value := .Config.Env}} {{println $value}} {{end}}' <контейнер>` - вывести переменные окружения контейнера с их значениями,
* `docker inspect -f '{{range .NetworkSettings.Networks}} {{.IPAddress}} {{end}}' <контейнер>` - вывести IP-адреса контейнера,
* `docker exec -it <контейнер> <команда>` - запустить в работающем контейнере указанную команду в интерактивном режиме в терминале,
* `docker container restart <контейнер>` - перезапустить контейнер,
* `docker system df` - показать использование диска образами, контейнерами, локальными томами и кэшем сборки,
* `docker system prune` - очистить кэш сборки и т.п. для освобождения места на диске,
* `docker-compose -f <docker-compose.yml> stop <контейнер>` - остановить контейнер с указанным именем, описанный в указанном файле `docker-compose.yml`,
* `docker-compose -f <docker-compose.yml> down` - остановить контейнер, соответствующий файлу `docker-compose.yml`,
* `docker-compose -f <docker-compose.yml> up -d` - запустить в фоновом режиме контейнер, соответствующий файлу `docker-compose.yml`,
* `docker-compose -f <docker-compose.yml> pull` - получить обновления контейнера, соответствующего файлу `docker-compose.yml` из удалённого репозитория.

Если в текущем каталоге находится файл `docker-compose.yml`, то его имя с помощью опции `-f` можно не указывать.
