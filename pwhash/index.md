Хэширование паролей
===================

Пароли в базе данных будут храниться в виде, хэшированном по алгоритму SHA512. Для получения хэша пароля можно воспользоваться такой программкой на python:
  
    #!/usr/bin/python
  
    from hashlib import sha512
    from base64 import b64encode
    from sys import argv
  
    if len(argv):
        print '{SHA512}' + b64encode(sha512(argv[1]).digest())
        print '{SHA512.hex}' + sha512(argv[1]).hexdigest()
    else:
        print "Usage: sha512 <password>"

Поскольку результат хэширования - это произвольная последовательность байтов, то для удобства использования её кодируют так, чтобы в результате получились только символы, пригодные для печати. Сделать это можно одним из способов - закодировать с помощью base64 или преобразовать в шестнадцатеричную последовательность, а получившиеся цифры преобразовать в текст. Любой из результатов можно поместить в поле password таблицы mailbox.
  
Вот примеры результатов хэширования пароля:

    $ ./sha512.py 1
    {SHA512}Tf9Oo0DwqCPxXT9PAati6uDl2lecy4Ufjbnf6ExYsrN7iZA6dA4e4XLaeTpuedVg5ff5vQWKEqKAQz7W+kZRCg==
    {SHA512.hex}4dff4ea340f0a823f15d3f4f01ab62eae0e5da579ccb851f8db9dfe84c58b2b37b89903a740e1ee172da793a6e79d560e5f7f9bd058a12a280433ed6fa46510a
