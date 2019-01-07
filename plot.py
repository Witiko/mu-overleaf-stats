import datetime
import itertools
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.dates import MonthLocator, DayLocator, DateFormatter
from os import mkdir

# Retrieve the relation between projects, workplaces, and overleaf
# document ids.
projects = {}
overleaf_ids = {}
with open("urls", "rt") as descriptions:
    for line in descriptions:
        overleaf_url, project, workplace = line.strip().split('\t')
        overleaf_id = overleaf_url.split('/')[-1]
        if project not in projects:
            projects[project] = []
        projects[project].append(workplace)
        overleaf_ids[(project, workplace)] = overleaf_id

# For each project, produce a plot with one line per workplace.
palette = [(31, 119, 180), (174, 199, 232), (255, 127, 14), (255, 187, 120),    
           (44, 160, 44), (152, 223, 138), (214, 39, 40), (255, 152, 150),    
           (148, 103, 189), (197, 176, 213), (140, 86, 75), (196, 156, 148),    
           (227, 119, 194), (247, 182, 210), (127, 127, 127), (199, 199, 199),    
           (188, 189, 34), (219, 219, 141), (23, 190, 207), (158, 218, 229)]
try:
    mkdir("plots")
except OSError:
    pass
for project, workplaces in projects.items():
    fig, ax = plt.subplots(figsize=(15, 9.5))
    fig.suptitle(project)
    ax.xaxis.set_major_locator(MonthLocator())
    ax.xaxis.set_major_formatter(DateFormatter("%Y-%m-%d"))
#   ax.xaxis.set_minor_locator(DayLocator())
    ax.grid(True)
    ax.set_ylabel("Views")
    lineformats = itertools.cycle(itertools.product(["-", "--", "-.", ":"],
                                                    [(r/255., g/255., b/255.) for (r, g, b) in palette]))
    workplace_views = {}
    for workplace in workplaces:
        try:
            dates = []
            views = []
            with open("stats/%s" % overleaf_ids[(project, workplace)]) as samples:
                for line in samples:
                    yyyymmdd, views_str = line.strip().split('\t')
                    yyyy_str, mm_str, dd_str = yyyymmdd.split('-')
                    dates.append(datetime.date(int(yyyy_str), int(mm_str), int(dd_str)))
                    views.append(int(views_str))
            linefmt, linecolor = next(lineformats)
            ax.plot_date(dates, views, fmt=linefmt, linewidth=2, c=linecolor, label=workplace)
            workplace_views[workplace] = views[-1]
        except IOError:
            pass
    sorted_handles = [(handle, workplace) for handle, workplace, views in \
                      sorted([(handle, workplace, workplace_views[workplace]) \
                              for handle, workplace in zip(*plt.gca().get_legend_handles_labels())],
                             key=lambda x: x[2], reverse=True)]
    plt.legend([handle for handle, workplace in sorted_handles],
               [workplace for handle, workplace in sorted_handles],
               title="Workplaces", loc=2)
    fig.autofmt_xdate()
    fig.savefig("plots/%s.svg" % project)
    fig.savefig("plots/%s.pdf" % project)
