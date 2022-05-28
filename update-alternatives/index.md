Использование update-alternatives
=================================

Настраиваем список альтернатив для ссылки /usr/bin/python под именем python:

    # update-alternatives --install /usr/bin/python2.7 python /usr/bin/python 0
    # update-alternatives --install /usr/bin/python3 python /usr/bin/python 1
    # update-alternatives --install /usr/bin/python3.5 python /usr/bin/python 2

Теперь для выбора определённой версии python как используемой по умолчанию, можно воспользоваться меню:

    # update-alternatives --config python
