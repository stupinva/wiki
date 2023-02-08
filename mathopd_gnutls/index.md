Поддержка TLS в Mathopd
=======================

Письмо 1
--------

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

Further details will follow at http://opensource.stobor.net/mathopd/#GnuTLS

As always, if you have any problems, questions or comments, please don't hesitate to get back to me.

Cheers,

Allwyn.

-- 
Allwyn Fernandes
Director
Stobor Pty Ltd

Mobile: + 61 430 436 758
LinkedIn: http://www.linkedin.com/in/AllwynFernandes

Письмо 2
--------

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

Further details will follow at http://opensource.stobor.net/mathopd/#TLS

As always, if you have any problems, questions or comments, please don't hesitate to get back to me.

Cheers,

Allwyn.

-- 
Allwyn Fernandes
Director
Stobor Pty Ltd

Mobile: + 61 430 436 758
LinkedIn: http://www.linkedin.com/in/AllwynFernandes

Источники
---------

* [[PATCH] Add (alpha) GnuTLS support to Mathopd](https://www.mail-archive.com/mathopd%40mathopd.org/msg00355.html)
* [[PATCH] Add TLS support to Mathopd](https://www.mail-archive.com/mathopd@mathopd.org/msg00357.html)
