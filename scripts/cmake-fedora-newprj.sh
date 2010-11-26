#!/usr/bin/env sh
#
CMAKE_TEMPLATES_PATH="/usr/share/cmake/Templates;Templates"

function print_usage(){
    cat <<END
Usage: $0 [OPTIONS] project_name
This command generate skeleton configuration files for cmake build system.

Options:
    -h: Print help message.
    -A { authors }: Authors. This will also apply to license document if
       possible.
    -B { cmake_templates_path }: Pathes which contain cmake templates.
       Pathes are splited with ';'.
       Default path is "/usr/share/cmake/Templates;Templates", use this option to
       override.
    -L { GPLv2+ | LGPLv2+ | GPLv3+ | LGPLv3+ | BSD }:
       LICENSE for this project. Licence files will be copied to current
       directory. Authors and vendor will also applied if -A and -V are
       given.
    -M { maintainer_contact}: name and email of a maintainer.
    -V { vendor }: Vendor. This will also apply to license document if
        possible.
    -e { old_spec(.in) }: Extract values from original spec or spec.in.
       This maybe handy when converting an old project to cmake-fedora.
    -i { initial_version }: Inital project version.
	Default value is 0.1.0 if this option is not given.
    -m { project_summary}: Project summary.
    -s { git | hg | svn | cvs }: source version control.
END
}

#Default Values
PRJ_AUTHORS="<PRJ_AUTHORS>"
PRJ_MAINTAINER="<PRJ_MAINTAINER>"
PRJ_VENDOR="<PRJ_VENDOR>"
PRJ_VER_INIT="0.1.0"
PRJ_SUMMARY="<PRJ_SUMMARY>"
PRJ_TEMPLATES_PATH="$CMAKE_TEMPLATES_PATH"
PRJ_LICENSE=""
PRJ_SOURCE_VERSION_CONTROL=""
OPT_EXTRACT_SPEC=""

# extract_from_spec
function extract_from_spec(){
    var=$1;
    value=$(eval echo \$${var});

    case $var in
	PRJ_AUTHORS )
	    newValue=`grep -e '^\* [A-Za-z]\+ [A-Za-z]\+ [0-9]\+ [0-9]\+ .*<' $OPT_EXTRACT_SPEC\
	    | sed -e 's/^\* [A-Za-z]\+ [A-Za-z]\+ [0-9]\+ [0-9]\+ \([^<]*\) *<.*/\1/' \
	    | head -n 1`
	    ;;
	PRJ_LICENSE )
	    newValue=`grep -e '^License:[[:space:]]*' $OPT_EXTRACT_SPEC \
	    | sed -e 's/License:[[:space:]]*//'`
	    ;;
	PRJ_MAINTAINER )
	    newValue=`grep -e '^\* [A-Za-z]\+ [A-Za-z]\+ [0-9]\+ [0-9]\+ .*<' $OPT_EXTRACT_SPEC \
	    | sed -e 's/^\* [A-Za-z]\+ [A-Za-z]\+ [0-9]\+ [0-9]\+ \([^>]*>\).*/\1/' \
	    | head -n 1`
	    ;;
	PRJ_VER_INIT )
	    newValue=`grep -e '^Version:[[:space:]]*[0-9]' $OPT_EXTRACT_SPEC\
	    | sed -e 's/Version:[[:space:]]*//'`
	    ;;
	PRJ_SUMMARY )
	    newValue=`grep -e '^Summary:[[:space:]]*' $OPT_EXTRACT_SPEC\
	    | sed -e 's/Summary:[[:space:]]*//'`
	    ;;
	*)
	    ;;
    esac

    if [ -n "$newValue" ];then
	echo "$newValue";
    else
	echo "$value";
    fi
}

while getopts "hA:B:L:M:V:e:i:m:s:" opt; do
    case $opt in
	h)
	    print_usage;
	    exit 0;
	    ;;
	A)
	    PRJ_AUTHORS="$OPTARG";
	    ;;
	B)
	    PRJ_TEMPLATES_PATH="$OPTARG";
	    ;;
	L)
	    PRJ_LICENSE="$OPTARG";
	    ;;
	M)
	    PRJ_MAINTAINER="$OPTARG";
	    ;;
	V)
	    PRJ_VENDOR="$OPTARG";
	    ;;
	e)
	    OPT_EXTRACT_SPEC=$OPTARG;
	    PRJ_AUTHORS=`extract_from_spec PRJ_AUTHORS`;
	    PRJ_LICENSE=`extract_from_spec PRJ_LICENSE`;
	    PRJ_MAINTAINER=`extract_from_spec PRJ_MAINTAINER`;
	    PRJ_VER_INIT=`extract_from_spec PRJ_VER_INIT`;
	    PRJ_SUMMARY=`extract_from_spec PRJ_SUMMARY`;
	    ;;
	i)
	    PRJ_VER_INIT="$OPTARG";
	    ;;
	m)
	    PRJ_SUMMARY=$OPTARG;
	    ;;
	s)
	    PRJ_SOURCE_VERSION_CONTROL=$OPTARG;
	    ;;
	*)
	    ;;
    esac
done
shift $((OPTIND-1));
PRJ_NAME=$1;
if [ -z $PRJ_NAME ];then
    print_usage
    exit 1
fi

if [ -n "$OPT_EXTRACT_SPEC" ];then
    for v in PRJ_AUTHORS PRJ_LICENSE PRJ_MAINTAINER PRJ_VER_INIT PRJ_SUMMARY;do
	value=$(eval echo \$${v})
	echo "Detected $v=$value"
    done
fi

function find_file(){
    _file=$1
    _paths=`echo $2 | xargs -d ';'`
    for _currDir in $_paths; do
	if [ -e "${_currDir}/fedora/${_file}" ];then
	    echo "${_currDir}/fedora/${_file}"
	    return
	fi
    done
}

function copy_file(){
    _dest=$2
    if [ -e ${_dest} ];then
	echo "${_dest} already exists, skip generation!" > /dev/stderr
	return 1
    fi
    _src=`find_file $1 ${PRJ_TEMPLATES_PATH}`
    cp $_src $_dest
    return 0
}

function generate_file2(){
    _dest=$1
    _src=$2
    templateFileName=`basename ${_src}`".template"
    shift 2

    if copy_file ${templateFileName} ${_dest} ;then
	for var in $@; do
	    value=$(eval echo \$${var})
	    #echo var=$var value=$value
	    sed -i.bak -e "s/<${var}>/$value/" ${_dest}
	done
    fi

}

function generate_file(){
    _file=$1
    shift
    generate_file2 $_file $_file $@
}


# generate_license _dest _src [[_pattern _replace] ...]
function generate_license(){
    _dest=$1
    _src=$2
    shift 2

    if copy_file ${_src} ${_dest} ;then
	_pattern=""
	_replace=""
	for _token in "$@"; do
	    #echo "_token=${_token}"
	    if [ "$_pattern" = "" ]; then
		_pattern=$_token
	    else
		_replace=$_token
		#echo "s/$_pattern/$_replace/"
		sed -i.bak -e "s/$_pattern/$_replace/" ${_dest}
		_pattern=""
		_replace=""
	    fi
	done
    fi
}

#generate files
generate_file CMakeLists.txt  PRJ_NAME PRJ_AUTHORS PRJ_LICENSE PRJ_MAINTAINER\
    PRJ_VENDOR PRJ_SUMMARY

generate_file RELEASE-NOTES.txt  PRJ_VER_INIT

generate_file ChangeLog.in

mkdir -p SPECS
generate_file SPECS/project.spec.in
generate_file SPECS/RPM-ChangeLog.in

YEAR=`date +%Y`
#copy licenses
case $PRJ_LICENSE in
    LGPLv3* )
        generate_license COPYING.LESSER lgpl-3.0.txt
	generate_license COPYING gpl-3.0.txt \
	    "<one line to give the program's name and a brief idea of what it does.>" \
	    "$PRJ_NAME - $PRJ_SUMMARY" \
	    "<year>" "$YEAR" \
	    "<name of author>" "$PRJ_AUTHORS" \
	    "<program>" "<$PRJ_NAME>"
	;;

    GPLv3* )
	generate_license COPYING gpl-3.0.txt \
	    "<one line to give the program's name and a brief idea of what it does.>" \
	    "$PRJ_NAME - $PRJ_SUMMARY" \
	    "<year>" "$YEAR" \
	    "<name of author>" "$PRJ_AUTHORS" \
	    "<program>" "<$PRJ_NAME>"
	;;

    LGPLv2* )
        generate_license COPYING.LESSER lgpl-2.1.txt \
	    "<one line to give the library's name and a brief idea of what it does.>" \
	    "$PRJ_NAME - $PRJ_SUMMARY" \
	    "<year>" "$YEAR" \
	    "<name of author>" "$PRJ_AUTHORS" \
	    "Frob" "<$PRJ_NAME>" \
	    "year name of author" "$YEAR $PRJ_AUTHORS" \
	    "Yoyodyne, Inc" "$PRJ_VENDOR" \
	    "a library for tweaking knobs" "$PRJ_SUMMARY" \
	    "James Random Hacker" "$PRJ_AUTHORS"
	generate_license COPYING gpl-2.0.txt \
	    "<one line to give the program's name and a brief idea of what it does.>" \
	    "$PRJ_NAME - $PRJ_SUMMARY" \
	    "<year>" "$YEAR" \
	    "<name of author>" "$PRJ_AUTHORS" \
	    "Gnomovision" "<$PRJ_NAME>" \
	    "version 69" "version $PRJ_VER_INIT" \
	    "year name of author" "$YEAR $PRJ_AUTHORS" \
	    "Yoyodyne, Inc." "$PRJ_VENDOR" \
	    "which makes passes at compilers" "$PRJ_SUMMARY" \
	    "James Hacker" "$PRJ_AUTHORS"
	;;

    GPLv2* )
	generate_license COPYING gpl-2.0.txt \
	    "<one line to give the program's name and a brief idea of what it does.>" \
	    "$PRJ_NAME - $PRJ_SUMMARY" \
	    "<year>" "$YEAR" \
	    "<name of author>" "$PRJ_AUTHORS" \
	    "Gnomovision" "<$PRJ_NAME>" \
	    "version 69" "version $PRJ_VER_INIT" \
	    "year name of author" "$YEAR $PRJ_AUTHORS" \
	    "Yoyodyne, Inc." "$PRJ_VENDOR" \
	    "which makes passes at compilers" "$PRJ_SUMMARY" \
	    "James Hacker" "$PRJ_AUTHORS"
	;;

    BSD )
	generate_license COPYING bsd-3-clauses.txt \
	    "<YEAR>" "$YEAR" \
	    "<OWNER>" "$PRJ_AUTHORS" \
	    "<ORGANIZATION>" "$PRJ_VENDOR"
	;;

    * )
	;;
esac

generate_file2 MAINTAINER_SETTING_NO_PACK MAINTAINER_SETTING PRJ_SOURCE_VERSION_CONTROL

if [ -f ChangeLog ]; then
    mv ChangeLog ChangeLog.prev
else
    touch ChangeLog.prev
fi

# Apply old RPM ChangeLog
# find spec first, then spec.in
if [ -n "$OPT_EXTRACT_SPEC" ];then
    oldspec=$OPT_EXTRACT_SPEC
else
    oldspec=`find . -name "${PRJ_NAME}.spec" | head -n 1`
fi
if [ -z "$oldspec" ];then
    oldspec=`find . -name "${PRJ_NAME}.spec.in" | head -n 1`
fi
if [ -n "$oldspec" ];then
    csplit -f 'NO_PACK_' $oldspec '%\%changelog%'+1
    mv NO_PACK_00 SPECS/RPM-ChangeLog.prev
else
    touch SPECS/RPM-ChangeLog.prev
fi


rm -f *.bak

