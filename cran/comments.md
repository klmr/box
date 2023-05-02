There appear to be two false-positive `R CMD CHECK` NOTEs:

1. A NOTE about a possibly invalid URL, import.rticulate.org. I cannot reproduce this issue, and the URL is reachable.

2. The definition of `chr.<-` in `R/format.r` triggered a NOTE about invalid parameters. A discussion of this issue can be found at <https://stackoverflow.com/q/69674485/1968>. In a previous submission I had rewritten the code to work around this NOTE by adding a dummy `value` parameter. This passed `R CMD CHECK` up until R 4.2.0 but apparently R 4.3.0 gained another check (“S3 generic/method consistency”) which broke this workaround. The current submission instead calls `.S3method()`. I hope this is acceptable.
