SHELL=/bin/bash
PYTHON=PYTHONHASHSEED=12345 /home/xnovot32/miniconda3/bin/python3.7
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
	git push origin master &>/dev/null
	git push mirror master &>/dev/null
	$(PYTHON) ./plot.py

urls: $(WEBPAGES)
	set -e; for FNAME in $^; do \
	  xmllint -html -xpath "//a[contains(@class, 'overleaf')]/@*[name()='data-project' \
                                                                     or name()='data-workplace' \
                                                                     or name()='href']" \
	          - <"$$FNAME" 2>/dev/null; \
	done | sed -r -e 's/( (data-(project|workplace)|href)="([^"]*)"){3}/&\n/g' \
             | sed -r -e 's/ (data-(project|workplace)|href)="([^"]*)"/\t\3/g' \
             | sed 's/^\t//' | sort -u -k 2 >$@
	echo 'https://www.overleaf.com/latex/templates/cstug-bulletin-article/yjdcyxtkmxmz	cstug	cstug' >>$@

stats: urls
	awk '{ print $$1 }' <$< | $(PARALLEL) --jobs=$(JOBS) --halt=2 -- '\
	  URL={}; \
	  printf "%s\t%d\n" `date --rfc-3339=date` `\
	    wget -q -O- $$URL | xmllint -html -xpath \
	      "//div[contains(@class, '\''field-title'\'') and text() = '\''View Count'\'']/../div[2]/text()" \
	      - 2>/dev/null` \
	    >>stats/$${URL##*/}; \
	  sleep $(SLEEP)'
