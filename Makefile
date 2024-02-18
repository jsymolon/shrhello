
# the prep file for the DSK, need trailing slash
LOADERPATH=/usr/share/cc65/target/apple2/util/

MERLINPATH=/opt/Merlin32_v1.0
MERLINLIB=${MERLINPATH}/Library
MERLIN=${MERLINPATH}/Linux64/Merlin32

# You may need to change this to where your AppleCommander is installed:
AC=~/Downloads/ac.jar

# Change this to your desired starting address in Apple ][ memory:
ADDR=2000

# Put the name of your sourcefile here:
PGM=shrhello

# Name of the final disk to add to and launch
DSKBK=TEST.2mg.backup
DSK=TEST.2mg

all: $(PGM)

install: $(PGM)

clean:
	rm -f $(PGM)
	rm -f *.o
	rm -f *.lst
	rm -f *.txt
	rm -f $(PGM).po

$(PGM):shrhello.s
	echo "assemble"
	$(MERLIN) -V $(MERLINLIB) $<
    
disk:$(PGM)
	echo "setup disk and run"
	# if not there, don't fail
	touch $(PGM).po
	# remove old disk
	rm $(PGM).po
	# create new disk and put a loader on it (from cc65, "cl65 --print-target-path")
	java -jar $(AC) -pro800 $(PGM).po $(VOLNAME) sys < $(LOADERPATH)loader.system
	# note need S16 for GS/OS "16" app
	java -jar $(AC) -p $(PGM).po $(PGM) S16 0x$(ADDR) < shrhello

launch:$(PRG)
	echo "run"
	gsplus -config ./config.cfg
    