Поддержка TLS в Mathopd
=======================

[[!tag mathopd]]

Оглавление
----------

[[!toc startlevel=2 levels=4]]

[PATCH] Add (alpha) GnuTLS support to Mathopd
---------------------------------------------

Mr Allwyn Fernandes Sun, 23 Sep 2007 21:43:56 -0700

Hi all,

While I usually hold off on sending in patches until they are complete with documentation and fully tested, this one has been a Wishlist item for Mathopd for a while, so I thought I'd send it through for anyone to play with...

It is a preliminary patch for TLSv1/SSLv3 support for Mathopd 1.5p6, based on GnuTLS. I haven't had time to clean this up and put in the relevant documentation as in the above patches, but I wanted to get it out there for people to try. The quick patch created here is a straight dump of my local svn repository, so it includes my other two patches for now. When I get a chance later, I should clean it up to only include GnuTLS, and provide the 1.6b9 version of the patch, too.

WARNING: This patch is only trivially tested, and is considered ALPHA quality for the moment! Use at your own risk, but feel free to let me know about any problems you have...

Quick HowTo: 

    Server { 
        TLS { 
            CACertFile ca-cert.pem 
            CRLFile crl.pem 
            CertFile cert.pem 
            KeyFile key.pem 
            DHParamsFile dhparams.pem 
            DHBits 1024 
        } 
        Control { 
            Alias / 
            Location /www/ 
        } 
    }

CertFile is the only required option, but if KeyFile is not supplied, CertFile must contain the private key as well. DHBits defaults to 1024, DH Params are generated if not supplied (but this can take some time, so for repeated testing, a dhparams file is suggested).

Everything seems to work, so far; I've not tested it extensively, but plain files and cgi scripts both appear to work as expected. Most things produce sensible error messages, but again, I haven't tested all possibilities.

This patch does NOT support SSLv2. I don't know if anyone on the planet is still using SSLv2 (it has been deprecated for over a decade), but when I get a chance I'll see how hard it is to include as well.

Patch: [[http://opensource.stobor.net/mathopd/gnutls.1.5p6.diff|gnutls.1.5p6.diff]] (or see attached). 

As usual, apply using:

    /tmp/mathopd-1.5p6$ gunzip gnutls.1.5p6.diff.gz | patch -p1

Further details will follow at [http://opensource.stobor.net/mathopd/#GnuTLS](https://web.archive.org/web/20140125092446/http://opensource.stobor.net/mathopd/#GnuTLS)

As always, if you have any problems, questions or comments, please don't hesitate to get back to me.

Cheers,

Allwyn.

--

Allwyn Fernandes

Director
Stobor Pty Ltd

Mobile: + 61 430 436 758

LinkedIn: [http://www.linkedin.com/in/AllwynFernandes](http://www.linkedin.com/in/AllwynFernandes)

[PATCH] Add TLS support to Mathopd
----------------------------------

Hi again,

I've updated this patch, and it's somewhat better now:

* Can now use either GnuTLS or OpenSSL as your TLS library.
* TLS now works even if *_SENDFILE is defined. Sendfile is used for non-TLS sockets, while traditional IO is used for TLS sockets.
* There's some documentation for the TLS configuration options. See config.txt and tls.txt.

OpenSSL support works, and is functional. OpenSSL CRL support is NOT implemented, because I can't figure out how to make it work yet. 

GnuTLS support works, and is functional. GnuTLS CRL support is implemented.

Please, please specify a DH Params file if you're doing repeated testing. DH params generation at startup can take a long time otherwise... 

Patch: [[http://opensource.stobor.net/mathopd/tls.1.5p6.diff|tls.1.5p6.diff]] (or see attached).

As usual, apply using: 

    /tmp/mathopd-1.5p6$ gunzip tls.1.5p6.diff.gz | patch -p1

Further details will follow at [http://opensource.stobor.net/mathopd/#TLS](https://web.archive.org/web/20140125092446/http://opensource.stobor.net/mathopd/#TLS)

As always, if you have any problems, questions or comments, please don't hesitate to get back to me.

Cheers,

Allwyn.

--

Allwyn Fernandes

Director
Stobor Pty Ltd

Mobile: + 61 430 436 758

LinkedIn: [http://www.linkedin.com/in/AllwynFernandes](http://www.linkedin.com/in/AllwynFernandes)

Patches for Mathopd HTTP Server
-------------------------------

The Mathopd HTTP Server is a small, fast HTTP/1.1 server, written by Michiel Boland.

The patches below either add functionality or modify existing functionality in the system:

* Include query string in Location redirects
* User-specifed HTTP Redirect Status Code
* TLS/SSL/HTTPS support with GnuTLS or OpenSSL

### Include query string in Location redirects

When using the "Location http://" syntax for redirects, Mathopd doesn't include the query string in the redirected url. For example, using the configuration: 

    Host example.net
    Control {
        Alias /
        Location http://example.com
    }

the following redirections occur:

* http://example.net/pages/sample.html → http://example.com/pages/sample.html
* http://example.net/pages/index.php → http://example.com/pages/index.php
* http://example.net/pages/fun.php?q=4 → http://example.com/pages/fun.php

This is not ideal; we would often like to have the query strings passed to the redirected page, as follows:

* http://example.net/pages/sample.html → http://example.com/pages/sample.html
* http://example.net/pages/index.php → http://example.com/pages/index.php
* http://example.net/pages/fun.php?q=4 → http://example.com/pages/fun.php?q=4

This patch implements that: [[Query String Patch for Mathopd 1.5p6|QueryStringInRedirect.1.5p6.diff]], [[Query String Patch for Mathopd 1.6b9|QueryStringInRedirect.1.6b9.diff]]. This is a relatively short, simple patch, and so should apply cleanly to other versions as well.

### User-specifed HTTP Redirect Status Code

Mathopd generates a "302 Moved" response when using the "Location http://" syntax for automatic redirects. This patch allows Mathopd to generate other 3xx redirect codes instead.

This patch adds a "RedirectStatus" keyword, which takes a single integer between 300 and 399. This sets the HTTP status code returned when redirecting. (In practice, only 301, 302, 303, and 307 do anything useful.)

One reason for using this patch is the [Google duplicate content penalty](http://www.google.com/search?q=duplicate+content+penalty). When multiple pages or domains have the same content, some search engines (notably Google) impose a penalty, lowering the result on the search result pages. Moreover, using a 302 redirect is considered the same as having duplicate content, while a 301 redirect is considered a permanent move, which means the content is only indexed under the redirected url.

Patch: [[Redirect Status (+ Query String Redirect) Patch for Mathopd 1.5p6|RedirectStatus.1.5p6.diff]], [[Redirect Status (+ Query String Redirect) Patch for Mathopd 1.6b9|RedirectStatus.1.6b9.diff]]. This patch also includes the above query string patch.

An alternative, if you do not wish to patch your server, is to use this short CGI program: [[301 Redirect CGI|301_cgi.c]]. Compile it to 301_cgi (bash$ gcc -o 301_cgi 301_cgi.c) and then use PutEnv to define a variable called MATHOPD_DESTINATION for the alias you wish to redirect:

    Virtual {
        Host example.net
        Control {
            Alias /
            PutEnv {
                MATHOPD_DESTINATION=http://example.com
            }
            Location /path/to/301_cgi
        }
    }

### TLS/SSL/HTTPS support with GnuTLS

2007-10-10: This has now been superseded by the patch below, which implements both GnuTLS and OpenSSL for TLS support.

### TLS/SSL/HTTPS support with GnuTLS or OpenSSL

2007-10-10: Implemented OpenSSL support. Fixed SENDFILE bug when in TLS mode. Added preliminary documentaion for TLS commands.

2007-10-08: USE_SSL_GNUTLS option is currently mutually incompatible with LINUX_SENDFILE (and probably FREEBSD_SENDFILE, although I can't test that...) If you are testing GnuTLS functionality in the current patch, please build without *_SENDFILE for the moment.

2007-09-24: Here is a preliminary patch for TLS/SSL support for Mathopd 1.5p6, based on GnuTLS. I haven't had time to clean this up and put in the relevant documentation as in the above patches, but I wanted to get it out there for people to try. The quick patch created here includes the above two patches. When I get a chance later, I'll clean it up to only include TLS, and provide the 1.6b9 version of the patch, too.

WARNING: This patch is only trivially tested, and is considered ALPHA quality for the moment! Use at your own risk, but feel free to let me know about any problems you have...

Quick HowTo:

    Server {
        TLS {
            CACertFile ca-cert.pem
            CRLFile crl.pem
            CertFile cert.pem
            KeyFile key.pem
            DHParamsFile dhparams.pem
            DHBits 1024
        }
        Control {
            Alias /
            Location /www/
        }
    }

CertFile is the only required option, but if KeyFile is not supplied, CertFile must contain the private key as well. DHBits defaults to 1024, DH Params are generated if not supplied (but this can take some time, so for repeated testing, a dhparams file is suggested).

Patch: [[TLS Patch for Mathopd 1.5p6 - beta|tls.1.5p6.diff]]

### Contact

If there are any queries or comments regarding the above patches, they can either be directed to the Mathopd Mailing List, or to [mathopd-patches@stobor.net](mailto:mathopd-patches@stobor.net)

Источники
---------

* [[PATCH] Add (alpha) GnuTLS support to Mathopd](https://www.mail-archive.com/mathopd%40mathopd.org/msg00355.html)
* [[PATCH] Add TLS support to Mathopd](https://www.mail-archive.com/mathopd@mathopd.org/msg00357.html)
* [Patches for Mathopd HTTP Server](https://web.archive.org/web/20140125092446/http://opensource.stobor.net/mathopd/)
