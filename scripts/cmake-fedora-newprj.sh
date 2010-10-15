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

while getopts "hA:B:L:M:V:i:m:s:" opt; do
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

function generate_file(){
    _file=$1
    shift
    _pathStr=$1
    shift

    if [ -e ${_file} ];then
	echo "${_file} already exists, skip generation!"
	return
    fi

    templateFileName=`basename ${_file}`".template"
#    echo templateFileName=${templateFileName}
    templateFile=`find_file ${templateFileName} ${_pathStr}`
#    echo templateFile=${templateFile}

    cp ${templateFile} ${_file}
    for var in $@; do
	value=$(eval echo \$${var})
	#echo var=$var value=$value
	sed -i.bak -e "s/<${var}>/$value/" ${_file}
    done

}


generate_file CMakeLists.txt ${PRJ_TEMPLATES_PATH} PRJ_NAME PRJ_AUTHORS\
  PRJ_LICENSE PRJ_MAINTAINER PRJ_VENDOR PRJ_SUMMARY
rm -f CMakeLists.txt.bak

generate_file RELEASE-NOTES.txt ${PRJ_TEMPLATES_PATH} PRJ_VER_INIT

mkdir -p SPECS
generate_file SPECS/project.spec.in ${PRJ_TEMPLATES_PATH}
generate_file SPECS/RPM-ChangeLog.in ${PRJ_TEMPLATES_PATH}

generate_file MAINTAINER_SETTING_NO_PACK ${PRJ_TEMPLATES_PATH} PRJ_SOURCE_VERSION_CONTROL

