# =================================================
# Meta Makefile to build all Singularity containers
# =================================================
# IMPORTANT:
# If you get permission denied errors when running this Makefile,
# rerun with sudo:
#   sudo make all

CONTAINERS := ubuntu22.04_R4.4.1 champ pyaging horvath grimage dunedinpace

.PHONY: all clean help $(CONTAINERS)

# -----------------------------
# Default: build all
# -----------------------------
all: ubuntu22.04_R4.4.1 champ pyaging horvath grimage dunedinpace

# -----------------------------
# Build each container
# -----------------------------
ubuntu22.04_R4.4.1:
	@echo "==============================================="
	@echo " Building container: ubuntu22.04_R4.4.1"
	@echo "==============================================="
	$(MAKE) -C ubuntu22.04_R4.4.1

champ:
	@echo "==============================================="
	@echo " Building container: champ"
	@echo "==============================================="
	$(MAKE) -C champ

pyaging:
	@echo "==============================================="
	@echo " Building container: pyaging"
	@echo "==============================================="
	$(MAKE) -C pyaging

horvath:
	@echo "==============================================="
	@echo " Building container: horvath"
	@echo "==============================================="
	$(MAKE) -C horvath

grimage:
	@echo "==============================================="
	@echo " Building container: grimage"
	@echo "==============================================="
	$(MAKE) -C grimage

dunedinpace:
	@echo "==============================================="
	@echo " Building container: dunedinpace"
	@echo "==============================================="
	$(MAKE) -C dunedinpace

# -----------------------------
# Clean all containers
# -----------------------------
clean:
	@for dir in $(CONTAINERS); do \
		if [ -d $$dir ]; then \
			$(MAKE) -C $$dir clean; \
		fi \
	done
	@echo "All containers cleaned."

# -----------------------------
# Help
# -----------------------------
help:
	@echo ""
	@echo "Usage:"
	@echo "  make all      Build all containers (in order)"
	@echo "  make clean    Clean all built containers"
	@echo "  make help     Show this help message"
	@echo ""