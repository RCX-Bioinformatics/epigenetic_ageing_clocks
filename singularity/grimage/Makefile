# Makefile for building Singularity container with specified versions

# Software versions
BASE_IMAGE_NAME=ubuntu22.04_R4.4.1.sif
BASE_IMAGE_FILE=ubuntu22.04_R4.4.1def
CONTAINER_NAME=grimage.sif
DEFINITION_FILE=grimage.def

# Build the Singularity container
$(CONTAINER_NAME): $(DEFINITION_FILE)
	@echo "Building Singularity container..."
	singularity build $(CONTAINER_NAME) $(DEFINITION_FILE)

# Build the base image
$(BASE_IMAGE_NAME):
	@echo "Building base image $(BASE_IMAGE_NAME)..."
	make -C ../ubuntu22.04_R4.4.1/
	singularity build ../ubuntu22.04_R4.4.1/$(BASE_IMAGE_NAME) ../ubuntu22.04_R4.4.1/$(BASE_IMAGE_FILE)

# Clean up the container image
clean:
	@echo "Cleaning up..."
	rm -f $(CONTAINER_NAME)

# Help message
help:
	@echo "Makefile for building Singularity container with specified versions"
	@echo "Usage:"
	@echo "  make"  # Build the container with specified versions based on the $(BASE_IMAGE)
	@echo "  make clean"  # Remove the container image