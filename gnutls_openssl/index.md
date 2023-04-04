Розеттский камень GnuTLS/OpenSSL
================================

[[!tag openssl gnutls tls ssl]]

Содержание
----------

[[!toc startlevel=2 levels=4]]

Создание приватного ключа
-------------------------

С помощью `certtool` из GnuTLS:

    $ certtool --generate-privkey --bits 4096 --no-text --outfile ca.key
    $ chmod go= ca.key

С помощью OpenSSL:

    $ openssl genrsa -out ca.key 4096
    $ chmod go= ca.key

Создание самозаверенного сертификата удостоверяющего центра
-----------------------------------------------------------

С помощью `certtool` из GnuTLS:

    $ cat > ca.tpl <<END
    organization = "Test Inc."
    unit = "Sleeping dept"
    locality = Ufa
    state = "Bashkortostan Republic"
    country = RU
    cn = "CA Test"
    serial = 1
    expiration_days = 365
    ca
    cert_signing_key
    crl_signing_key
    END
    $ certtool --generate-self-signed --template ca.tpl --load-privkey ca.key --outfile ca.crt

Опция `serial = 1` задаёт серийный номер сертификата. При повторной выдаче сертификатов с теми же данными нужно увеличивать серийный номер сертификата, чтобы клиенты, запомнившие предыдущий сертификат, не отклоняли новый как поддельный, а принимали его как новую версию предыдущего сертификата.

Поле `unit` указывать не обязательно.

С помощью OpenSSL:

    $ cat > ca.cnf <<END
    [req]
    default_bits = 4096
    default_md = sha256
    default_days = 365
    distinguished_name = req_distinguished_name
    x509_extensions = v3_ca
    prompt = no
    
    [req_distinguished_name]
    0.organizationName = "Test Inc."
    organizationalUnitName = "Sleeping dept"
    localityName = Ufa
    stateOrProvinceName = "Bashkortostan Republic"
    countryName = RU
    commonName = "CA Test"
    
    [v3_ca]
    basicConstraints = critical, CA:true, pathlen:0
    keyUsage = critical, digitalSignature, cRLSign, keyCertSign
    END
    $ openssl req -new -key ca.key -config ca.cnf -x509 -out ca.crt

Поле `organizationUnitName` указывать не обязательно.

Опция `pathlen:0` запрещает подписывать этим сертификатом сертификаты промежуточных удостоверяющих центров. Если в цепочке заверения сертификатов допускается один промежуточный удостоверяющий центр, то эту опцию можно поменять на `pathlen:1` и т.п.

Создание запроса сертификата
----------------------------

С помощью `certtool` из GnuTLS:

    $ certtool --generate-privkey --bits 4096 --no-text --outfile www.key
    $ chmod go= www.key
    $ cat > www.tpl <<END
    organization = "Test Inc."
    unit = "Sleeping dept"
    locality = Ufa
    state = "Bashkortostan Republic"
    country = RU
    cn = "WWW Server Test"
    serial = 1
    expiration_days = 365
    dns_name = "localhost"
    ip_address = "127.0.0.1"
    tls_www_server
    encryption_key
    END
    $ certtool --generate-request --template www.tpl --load-privkey www.key --outfile www.csr

Опция `serial = 1` задаёт серийный номер сертификата. При повторной выдаче сертификатов с теми же данными нужно увеличивать серийный номер сертификата, чтобы клиенты, запомнившие предыдущий сертификат, не отклоняли новый как поддельный, а принимали его как новую версию предыдущего сертификата.

Поле `unit` указывать не обязательно.

При необходимости можно повторять опции `dns_name` и `ip_address` для задания дополнительных имён и адресов, принадлежащих серверу.

С помощью OpenSSL:

    $ cat > www.cnf <<END
    [req]
    default_bits = 4096
    default_md = sha256
    default_days = 365
    distinguished_name = req_distinguished_name
    x509_extensions = v3_req
    prompt = no
    
    [req_distinguished_name]
    0.organizationName = "Mathopd Test Inc."
    #organizationalUnitName = "Sleeping dept"
    localityName = Ufa
    stateOrProvinceName = "Bashkortostan Republic"
    countryName = RU
    commonName = localhost
    
    [v3_req]
    basicConstraints = CA:false
    keyUsage = nonRepudiation, digitalSignature, keyEncipherment, dataEncipherment
    END
    $ openssl req -new -key www.key -config www.cnf -out www.csr

Поле `organizationUnitName` указывать не обязательно.

Доменное имя защищаемого сервера в случае с OpenSSL необходимо указать в опции `commonName`. Если нужно доказать дополнительные доменные имена и/или IP-адреса, то для этого в секцию `[v3_req]` нужно можно добавить опцию `subjectAltName = @alt_names` и описать дополнительные доменные имена и IP-адреса в секции `[alt_names]`:

    [alt_names]
    DNS.1 = localhost.localdomain
    IP.1 = 127.0.0.1

Заверение сертификата
---------------------

С помощью `certtool` из GnuTLS:

    $ certtool --generate-certificate --load-request www.csr --load-ca-certificate ca.crt \
               --template www.tpl --load-ca-privkey ca.key --outfile www.crt

С помощью OpenSSL:

    $ openssl x509 -req -in www.csr -CA ca.crt -CAkey ca.key -CAserial ca.srl -CAcreateserial -out www.crt

При заверении сертификата создаётся файл `ca.srl` с отмеченными в нём серийными номерами выданных сертификатов, так что в отличие от утилиты `certool` из GnuTLS, обновлять вручную серийный номер нового сертификата с теми же данными не требуется.

Создание параметров Диффи-Хеллмана
----------------------------------

С помощью `certtool` из GnuTLS:

    $ certtool --generate-dh-params --outfile www.dh

С помощью OpenSSL:

    $ openssl dhparam -out www.dh 4096
