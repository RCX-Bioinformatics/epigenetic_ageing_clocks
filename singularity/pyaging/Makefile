# Makefile for building Singularity container with specified versions

# Software versions (be aware of compatibility issues - pyaging has specific requirements)
PYTHON_VERSION=3.11-slim
REQUESTS_VERSION=2.32.3
PYAGING_VERSION=0.1.14
PIP_VERSION=25.0.1
CONTAINER_NAME=pyaging.sif
DEFINITION_FILE=pyaging.def

# Build the Singularity container
$(CONTAINER_NAME): $(DEFINITION_FILE)
	@echo "Building Singularity container..."
	singularity build \
	--build-arg PYTHON_VERSION=$(PYTHON_VERSION) \
	--build-arg PIP_VERSION=$(PIP_VERSION) \
	--build-arg PYAGING_VERSION=$(PYAGING_VERSION) \
	--build-arg REQUESTS_VERSION=$(REQUESTS_VERSION) \
	$(CONTAINER_NAME) $(DEFINITION_FILE)

# Clean up the container image
clean:
	@echo "Cleaning up..."
	rm -f $(CONTAINER_NAME)

# Help message
help:
	@echo "Makefile for building Singularity container with specified versions"
	@echo "Usage:"
	@echo "  make"  # Build the container with specified versions
	@echo "  make clean"  # Remove the container image