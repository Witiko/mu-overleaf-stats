SHELL=/bin/bash
PARALLEL=/packages/run.64/parallel-20130822/bin/parallel
WEBPAGES=/www/lemma/projekty/mubeamer/index.html \
         /www/lemma/projekty/muletter/index.html \
         /www/lemma/projekty/fithesis3/index.html
JOBS=1
SLEEP=1s

.PHONY: all stats
all: stats
	git add stats
	git commit -m 'added '`date --rfc-3339=date`' results' &>/dev/null
	git push &>/dev/null

urls: $(WEBPAGES) static_urls
	sed -n '/^\s*#/!{s/#.*//;p}' <static_urls >$@
	set -e; for FNAME in $^; do \
	  xmllint -html -xpath "//a[contains(@class, 'overleaf')]/@href" - <$$FNAME 2>/dev/null; \
	done | sed -r 's/ href="([^"]*)"/\1\n/g' | sort -u >>$@

stats: urls
	$(PARALLEL) --jobs=$(JOBS) --halt=2 -- '\
	  URL={}; \
	  printf "%s\t%d\n" `date --rfc-3339=date` `wget -q -O- $$URL \
	    | xmllint -html -xpath "//div[@id='\''views_and_shares'\'']/a/text()" - 2>/dev/null \
	    | sed -r -n "/[^ ]/s/ *([0-9]*) views */\1/p" - 2>/dev/null` >>stats/$${URL##*/}; \
	  sleep $(SLEEP)' :::: $<
