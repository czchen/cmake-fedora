#!/bin/bash
if [ -e /etc/cmake-fedora.conf ]; then
    source /etc/cmake-fedora.conf
fi

FEDORA_CURRENT_RELEASE_TAGS=${FEDORA_CURRENT_RELEASE_TAGS:-"f17 f16 f15"}
EPEL_CURRENT_RELEASE_TAGS=${EPEL_CURRENT_RELEASE_TAGS:-"el6 el5"}

function print_usage(){
    cat <<END
Usage: $0 <srpm> [fedora | fedoraReleases]  [epel | epelReleases]
This command does the scratch build for fedora and epel releases with koji

Options:
    srpm: SRPM file to be sent to koji
    fedora: to build the currently supported fedora releases
        (i.e. $FEDORA_CURRENT_RELEASE_TAGS)
    fedoraReleases: The fedora releases to be built. (such as $FEDORA_CURRENT_RELEASE_TAGS)
    epel: to build the currently supported fedora releases
        (i.e. $EPEL_CURRENT_RELEASE_TAGS)
    epelReleases: The fedora releases to be built. (such as $EPEL_CURRENT_RELEASE_TAGS)


If neither fedora releases nor epel releases are specified, then it builds
both fedora and epel releases.
END
}

if [[ $# < 1 ]];then
    print_usage
    exit 0
fi

srpm="$1"
shift

_SUFFIX="-candidate"
TARGETS=

if [ "$1" == "fedora" ]; then
    TARGETS=$FEDORA_CURRENT_RELEASE_TAGS
    shift
fi

if [ "$1" == "epel" ]; then
    TARGETS="$TARGETS $EPEL_CURRENT_RELEASE_TAGS"
    shift
fi

TARGETS="$TARGETS $*"

[ -z "${TARGETS}" ] && TARGETS="$FEDORA_CURRENT_RELEASE_TAGS $EPEL_CURRENT_RELEASE_TAGS"

for t in $TARGETS; do
    echo "koji build --scratch $t$_SUFFIX $srpm"
#    koji build --scratch "$t$_SUFFIX" "$srpm"
done

