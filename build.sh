zed_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$zed_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <zed_version> <build_version> [architecture]"
    echo "Example: $0 0.8.11 1 arm64"
    echo "Example: $0 0.8.11 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64"
    exit 1
fi

# Function to map Debian architecture to zed release name
get_zed_release() {
    local arch=$1
    case "$arch" in
        "amd64")
            echo "x86_64"
            ;;
        "arm64")
            echo "aarch64"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Function to build for a specific architecture
build_architecture() {
    local build_arch=$1
    local zed_release
    
    zed_release=$(get_zed_release "$build_arch")
    if [ -z "$zed_release" ]; then
        echo "❌ Unsupported architecture: $build_arch"
        echo "Supported architectures: amd64, arm64"
        return 1
    fi
    
    echo "Building for architecture: $build_arch using $zed_release"
    
    # Clean up any previous builds for this architecture
    rm -rf "zed-linux-${zed_release}" || true
    rm -f "zed-linux-${zed_release}.tar.gz" || true
    # Download and extract zed binary for this architecture
    if ! wget "https://github.com/zed-industries/zed/releases/download/v${zed_VERSION}/zed-linux-${zed_release}.tar.gz"; then
        echo "❌ Failed to download zed binary for $build_arch"
        return 1
    fi
    
    if ! tar -xf "zed-linux-${zed_release}.tar.gz"; then
        echo "❌ Failed to extract zed binary for $build_arch"
        return 1
    fi
    
    rm -f "zed-linux-${zed_release}.tar.gz"
    
    declare -a arr=("bookworm" "trixie" "forky" "sid")
    
    for dist in "${arr[@]}"; do
        FULL_VERSION="$zed_VERSION-${BUILD_VERSION}+${dist}_${build_arch}"
        echo "  Building $FULL_VERSION"
        
        if ! docker build . -t "zed-$dist-$build_arch" \
            --build-arg DEBIAN_DIST="$dist" \
            --build-arg zed_VERSION="$zed_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$build_arch" \
            --build-arg zed_RELEASE="$zed_release"; then
            echo "❌ Failed to build Docker image for $dist on $build_arch"
            return 1
        fi
        
        id="$(docker create "zed-$dist-$build_arch")"
        if ! docker cp "$id:/zed_$FULL_VERSION.deb" - > "./zed_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist on $build_arch"
            return 1
        fi
        
        if ! tar -xf "./zed_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist on $build_arch"
            return 1
        fi
    done
    
    # Clean up extracted directory
    rm -rf "zed.app" || true
    
    echo "✅ Successfully built for $build_arch"
    return 0
}

# Main build logic
if [ "$ARCH" = "all" ]; then
    echo "🚀 Building zed $zed_VERSION-$BUILD_VERSION for all supported architectures..."
    echo ""
    
    # All supported architectures
    ARCHITECTURES=("amd64" "arm64" "armel" "armhf" "ppc64el" "s390x" "riscv64")
    
    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="
        
        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi
        
        echo ""
    done
    
    echo "🎉 All architectures built successfully!"
    echo "Generated packages:"
    ls -la zed_*.deb
else
    # Build for single architecture
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi