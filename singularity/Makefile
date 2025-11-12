# =================================================
# Meta Makefile to build all Singularity containers
# =================================================
# IMPORTANT:
# If you get permission denied errors when running this Makefile,
# rerun with sudo:
#   sudo make all

CONTAINERS := ubuntu22.04_R4.4.1 champ pyaging horvath minfi

.PHONY: all clean help $(CONTAINERS)

# -----------------------------
# Default: build all
# -----------------------------
all: ubuntu22.04_R4.4.1 champ pyaging horvath minfi

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

minfi:
	@echo "==============================================="
	@echo " Building container: minfi"
	@echo "==============================================="
	$(MAKE) -C minfi

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