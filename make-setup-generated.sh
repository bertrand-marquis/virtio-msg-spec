#! /bin/sh

VERSION=1.0
if [ x"$DATESTR" = x ]; then
    ISODATE=`git show --format=format:'%cd' --date=iso | head -n 1`
    DATESTR=`date -d "$DATE" +'%d %B %Y'`
fi

case "$1" in
    *-wd*)
	STAGE=wd
	STAGENAME="Working Draft"
	WORKINGDRAFT=`basename "$1" | sed 's/.*-wd//'`
	;;
    *-os*)
	STAGE=os
	STAGENAME="OASIS Standard"
	WORKINGDRAFT=""
	;;
    *-csd*)
	STAGE=csd
	STAGENAME="Committee Specification Draft"
	WORKINGDRAFT=`basename "$1" | sed 's/.*-csd//'`
	;;
    *-csprd*)
	STAGE=csprd
	STAGENAME="Committee Specification Public Review Draft"
	WORKINGDRAFT=`basename "$1" | sed 's/.*-csprd//'`
	STAGEEXTRATITLE=" / \newline Public Review Draft $WORKINGDRAFT"
	STAGEEXTRA=" / Public Review Draft $WORKINGDRAFT"
	;;
    *-cs*)
	STAGE=cs
	STAGENAME="Committee Specification"
	WORKINGDRAFT=""
	;;
    *)
	echo Unknown doc type >&2
	exit 1
esac

#Prepend OASIS unless already there
case "$STAGENAME" in
	OASIS*)
		OASISSTAGENAME="OASIS $STAGENAME"
		;;
	*)
		OASISSTAGENAME="$STAGENAME"
		;;
esac

cat > setup-generated.tex <<EOF
% define VIRTIO Working Draft number and date
\newcommand{\virtiorev}{$VERSION}
\newcommand{\virtioworkingdraftdate}{$DATESTR}
\newcommand{\virtioworkingdraft}{$WORKINGDRAFT}
\newcommand{\virtiodraftstage}{$STAGE}
\newcommand{\virtiodraftstageextra}{$STAGEEXTRA}
\newcommand{\virtiodraftstageextratitle}{$STAGEEXTRATITLE}
\newcommand{\virtiodraftstagename}{$STAGENAME}
\newcommand{\virtiodraftoasisstagename}{$OASISSTAGENAME}
EOF