#!/bin/bash
set -ue
set -o pipefail

# info SEAGREEN1
# shellcheck disable=SC2317
log_info() {
    printf "\033[38;5;84mpre-push %s\033[0m\n" "$1"
}
export -f log_info

# err MAGENTA
# shellcheck disable=SC2317
log_err() {
    printf "\033[38;5;201m[error] %s\033[0m\n" "$1"
}
export -f log_err

# shellcheck disable=SC2317
check() {
    local toplevel=$1
    local path=$2

    log_info "Checking ${toplevel} / ${path}..."

    # shellcheck disable=SC2155
    local origin_url=$(git config --get remote.origin.url)
    if [[ ! "$origin_url" =~ ^git@github\.com ]]; then
        log_info "  => external repository"
        return 0
    fi

    pushd "${toplevel}/${path}" >/dev/null

    # Check for uncommitted changes
    if ! git diff-index --quiet HEAD --; then
        log_err "There are uncommitted changes in ${path}"
        git status --short
        popd >/dev/null
        return 1
    fi

    # Check if current branch is different from remote main
    # shellcheck disable=SC2155
    local local_commit=$(git rev-parse HEAD)
    # shellcheck disable=SC2155
    local remote_commit=$(git rev-parse origin/main)

    if [ "$local_commit" != "$remote_commit" ]; then
        log_err "  => differs from origin/main"
        echo "  origin/main..main:"
        git --no-pager log --oneline "$remote_commit..$local_commit" 2>/dev/null | pr -to4 || true

        echo "  main..origin/main:"
        git --no-pager log --oneline "$local_commit..$remote_commit" 2>/dev/null | pr -to4 || true
        popd >/dev/null
        return 1
    fi

    popd >/dev/null
    return 0
}
export -f check

toplevel=$(git rev-parse --show-toplevel)
unset GIT_DIR

log_info "toplevel = '${toplevel}'"

#
# ALL submodules must be MAIN and latest
#
# shellcheck disable=SC2016
git submodule foreach "check \$toplevel \$path"

exit 0
