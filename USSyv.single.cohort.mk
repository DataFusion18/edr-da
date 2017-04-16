include paths.mk

prefix := `pwd`
subst_dir := 's|XXX_DIR_XXX|'${prefix}'|g'

met_driver := ed-inputs/met3/US-Syv/ED_MET_DRIVER_HEADER
ed2in_temp := run-ed/template/ED2IN
ed2_link := run-ed/template/ed_2.1
#ed2_link := run-ed/template/ed_2.1-opt

cohorts := 1cohort

denss := 0.05

dbhs := 20 30 40

pfts := temperate.North_Mid_Hardwood \
	temperate.Late_Hardwood \
	temperate.Northern_Pine \
	temperate.Late_Conifer

testsites := $(foreach c, $(cohorts), \
	$(foreach s, $(denss), \
	$(foreach d, $(dbhs), \
	$(foreach p, $(pfts), \
	ed-inputs/sites/US-WCr/rtm/$c/dens$s/dbh$d/$p/$p.lat46.5lon-89.5.css))))

results := $(foreach c, $(cohorts), \
	$(foreach s, $(denss), \
	$(foreach d, $(dbhs), \
	$(foreach p, $(pfts), \
	run-ed/$c/dens$s/dbh$d/$p/outputs/history.xml))))

.PHONY: sites edruns

all: sites edruns templates inversion/edr_path

sites: $(testsites)

edruns: $(results)

templates : $(met_driver) $(ed2in_temp) $(ed2_link)

inversion/edr_path:
	@echo $(EDR_EXE) > $@

$(testsites) : templates

$(results) : sites

%.css: 
	$(eval dt := $(shell expr match "$@" '.*dbh\([0-9]\+\).*'))
	$(eval pt := $(shell expr match "$@" '.*/\(.*\).lat.*'))
	$(eval st := $(shell expr match "$@" '.*dens\([0-9.]\+\).*'))
	Rscript testruns/generate_testrun_single_cohort_USSyv.R $(dt) $(pt) $(st)

%.xml: 
	$(eval dt := $(shell expr match "$@" '.*dbh\([0-9]\+\).*'))
	$(eval pt := $(shell expr match "$@" '.*/dens.*/dbh.*/\(.*\)/outputs/.*'))
	$(eval st := $(shell expr match "$@" '.*dens\([0-9.]\+\).*'))
	./exec_ed_test.sh $(cohorts) $(dt) $(pt) $(st)

$(ed2_link): 
	ln -fs $(ED_EXE) $@

clean:
	rm -rf ed-inputs/sites/US-Syv/rtm/1cohort \
	    run-ed/1cohort run-ed/template/ed_2.1 run-ed/template/ed_2.1-opt run-ed/template/ED2IN ed-inputs/met3/US-Syv/ED_MET_DRIVER_HEADER

%: %.temp
	sed $(subst_dir) $< > $@
