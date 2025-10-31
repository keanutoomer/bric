# container() - Simple container system for creating user shims to containerized applications
container() {
    local user_home="/users/kltoomer"
    local container_bins="${user_home}/bric/containers/apptainer/shim/bins"
    if [ ! -d "$container_bins" ]; then
        echo "Container bins directory not found: $container_bins"
        return 1
    fi

    # Parse arguments from 'container <command> <container_name>'
    local action="$1"
    local container="$2"
    local bin="${container_bins}/${container}_bins"

    case "$action" in
        load)
            if [ ! -d "$bin" ]; then
                echo "Container shim not found for: $container"
                # Could add fuzzy search here later; since container names are encoded with
                # versions & bases, base matches could be listed by versison number
                return 1
            else
                if [[ ":$PATH:" == *":${bin}:"* ]]; then
                    echo "Container $container already loaded"
                else
                    export PATH="${bin}:${PATH}"
                    echo "Loaded: $container"
                fi
            fi
            ;;
        unload)
            if [[ ":$PATH:" == *":${bin}:"* ]]; then
                export PATH="${PATH//${bin}:/}"
                export PATH="${PATH//:${bin}/}"
                export PATH="${PATH//${bin}/}"
                echo "Unloaded: $container"
            else
                echo "Container $container not loaded"
            fi
            ;;
        list)
            echo "Checking loaded containers..."
            for con in ~/containers/bins/*/; do
                conname=$(basename "$con")
                if [[ ":$PATH:" == *":${con}bin:"* ]]; then
                    echo "  $conname"
                fi
            done
            ;;
        avail)
            echo "Available containers:"
            ls -1 "${container_bins}" | sed 's/_bins//'
            ;;
        show)
            echo "container: $container"
            echo "Bin: $bin"
            echo "Commands: $(ls -1 ${bin} | wc -l)"
            ;;
        *)
            echo "Usage: container {load|unload|list|avail|show} <container>"
            ;;
    esac
}