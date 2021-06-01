## qrdec

### What?

This is the qr code decoder that was originally written by Timothy Terriberry
for maemo-barcode and that was later merged into zbar, where it saw a small
amount of further development. It was effectively written as a standalone
library and has seen virtually no modification to the core code (only small
additions to the character decoding) over the last decade, despite there being
a lot of code churn in zbar itself.

This is composed of the original commits pulled from the maemo-barcode SVN as
well as some additional commits from the original author that landed in the
zbar repository. This history isn't completely identical to its source, as I
made some minor modifications to a couple of the later patches to keep this
code free of any and all zbar-isms. The result is a standalone QR code decoding
library, along with a simple test tool that can decode QR codes from a PNG
image. The library depends on iconv, and the test tool additionally requires
libpng.

### Why?

zbar is not a small library. For the specific purpose of decoding QR codes, it's
seriously overkill, and I am interested in comparing the performance of this
vs. quirc, a library that implements a QR decoder in significantly fewer lines
of code. This decoder does generally appear to be more robust (it can decode
codes that I can barely identify as being QR codes) and stable than quirc,
though I think the real reason this hasn't seen much further development over
the last decade is pretty clear: just look at the code. Do you understand any
of it?

This also appears to try to adhere rigorously to the QR code specification, so
it supports some interesting/exotic QR code features that quirc doesn't, like
structured append, which allows spreading a single message across multiple
physical codes. It also properly represents the fact that a single QR code can
contain multiple data payloads, each with a different encoding format. I
suspect that the use of these features is pretty rare in the wild, since QR
codes usually just contain a URL or an identifier, but they probably have
interesting industrial applications.
