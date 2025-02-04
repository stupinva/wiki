Изменение пароля пользователя Grafana через базу данных
-------------------------------------------------------

Алгоритм хэширования паролей можно увидеть в исходных текстах сервера Grafana, в файле [grafana/grafana/blob/main/pkg/util/encoding.go](https://github.com/grafana/grafana/blob/a912c970e376322ec874cf7edae5d82afda4be29/pkg/util/encoding.go#L54C15-L54C80):

    pbkdf2.Key([]byte(password), []byte(salt), 10000, 50, sha256.New)

Как видно, Используется 10000 циклов хэширования с солью алгоритмом sha256, от результата остётся только 50 байт.

Для вычисления хэша можно воспользоваться онлайн-калькулятором по ссылке [Test hash_pbkdf2 online]https://onlinephp.io/hash-pbkdf2).

Т.к. в конечном счёте хэш помещается в базу данных в виде шеснадцатеричной строки, а не последовательности байт, то для хэширования на странице онлайн-калькулятора нужно указать длину результата 100 символов. Таким образом на странице онлайн-калькулятора нужно задать следующие настройки:

    $algo = sha256
    $password = пароль
    $salt = соль
    $iterations = 10000
    $length = 100
    $binary = false

Соль представляет собой случайную текстовую последовательность символов.

Дале для сборса пароля нужно выполнить в базе данных такой запрос:

    UPDATE user SET salt = 'соль', password = 'хэш' where login = 'login';

Если нужно не поменять пароль существующего пользователя, а создать нового пользователя, то сделать это можно с помощью запроса следующего вида:

    INSERT INTO user(version, login, email, org_id, is_admin, created, updated, salt, password) VALUES(0, 'логин', 'почтовый@ящик', 1, 1, '', '', 'соль', 'хэш');

Значение для поля org_id можно выбрать из результатов следующего запроса:

    SELECT id, name FROM org;

Если используется база данных, не поддерживающая поля с автоинкрементом, то может понадобиться узнать максимальный используемый идентификатор из таблицы user:

    SELECT MAX(id) FROM user;

И подставить в запрос значение на единицу больше:

    INSERT INTO user(id, version, login, email, org_id, is_admin, created, updated, salt, password) VALUES(идентификатор, 0, 'логин', 'почтовый@ящик', 1, 1, '', '', 'соль', 'хэш');
