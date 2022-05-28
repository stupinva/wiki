Настройка и использование cntlm
===============================

Если вы привыкли пользоваться Linux, но вынуждены работать в Windows-окружении, то вам может пригодиться прокси-сервер cntlm. Этот прокси сервер умеет аутентифицироваться на прокси-сервере, работающем под управлением Windows, по алгоритмам LM, NT и NTLMv2.

Устанавливаем cntlm из репозитория:

    # apt-get install cntlm

Генерируем хэш пароля учётной записи:

    $ cntlm -H -d domain.tld -u stupin
    Password: 
    PassLM          B58AF0D6D2FAB837579B085E5E3D896C
    PassNT          4EFC855DBCC77DA945B489A78FB17DAD
    PassNTLMv2      8F6C40E03ED13AAC14299399E417F4FD    # Only for user 'stupin', domain 'domain.tld'

Прописываем логин, домен и хэш из строчки PassNTLMv2 в файл конфигурации /etc/cntlm.conf. Указываем необходимость использовать алгоритм аутентификации NTLMv2 и дополняем прочими настройками. В итоге файл конфигурации должен принять примерно следующий вид:

    $ egrep -v '^(#|$)' /etc/cntlm.conf 
    Username stupin
    Domain domain.tld
    PassNTLMv2 8F6C40E03ED13AAC14299399E417F4FD
    Proxy 10.0.25.3:8080
    NoProxy localhost, 127.0.0.*, 10.*, 192.168.*
    Listen 3128
    Auth NTLMv2

Осталось перезапустить прокси, чтобы новые настройки вступили в силу:

    # systemctl restart cntlm

После запуска cntlm будет готов принимать TCP-подключения на локальном адресе 127.0.0.1 на порт 3128:

    # netstat -tnlp | grep port 3128
    Active Internet connections (only servers)
    Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
    tcp        0      0 127.0.0.1:3128          0.0.0.0:*               LISTEN      7643/cntlm

Для проверки работы cntlm можно попробовать скачать какую-нибудь веб-страницу с его использованием, например вот так:

    $ http_proxy=http://127.0.0.1:3128/ wget http://stupin.su/blog/index.html

Чтобы перенаправлять веб-трафик от любых программ в прокси прозрачным образом, можно настроить [[redsocks]].
