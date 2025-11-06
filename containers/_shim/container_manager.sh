# container() - Simple container system for creating user shims to containerized applications
container() {
    local user_home="/users/kltoomer"
    local containers_dir="${user_home}/bric/containers"
    if [ ! -d "$containers_dir" ]; then
        echo "Container directory not found: $containers_dir"
        return 1
    fi

    # Parse arguments from 'container <command> <container_name>'
    local action="$1"
    local container="$2"
    local bin="${containers_dir}/${container}/${container}_bin"

    case "$action" in
        load)
            if [ ! -d "$bin" ]; then
                echo "Container shim not found for ${container}"
                # Could add fuzzy search here later; since container names are encoded with
                # versions & bases, base matches could be listed by versison number
                return 1
            else
                if [[ ":$PATH:" == *":${bin}:"* ]]; then
                    echo "Container ${container} binaries already loaded in PATH"
                else
                    export PATH="${bin}:${PATH}"
                    echo "Loaded ${container} binaries to PATH"
                fi
            fi
            ;;
        unload)
            if [[ ":$PATH:" == *":${bin}:"* ]]; then
                export PATH="${PATH//${bin}:/}"
                export PATH="${PATH//:${bin}/}"
                export PATH="${PATH//${bin}/}"
                echo "Unloaded binaries for ${container} from PATH"
            else
                echo "Container ${container} not loaded in PATH"
            fi
            ;;
        list)
            echo "Checking loaded containers..."
            for con in ${containers_dir}/*; do
                conname=$(basename "$con")
                if [[ ":$PATH:" == *"${con}_bin:"* ]]; then
                    echo "  $conname"
                fi
            done
            ;;
        avail)
            echo "Shimmable containers:"
            for d in ${containers_dir}/*; do
                [ -d ${d}/$(basename ${d})_bin ] || continue
                echo " -- $(basename ${d})"
            done
            ;;
        show)
            echo "${container} binaries"
            echo "Commands: $(ls -1 ${bin} | wc -l)"
            ;;
        *)
            echo "Usage: container {load|unload|list|avail|show} <container>"
            ;;
    esac
}
