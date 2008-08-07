#!/bin/sh

DIST=`echo "$QUERY_STRING" | sed -n 's/^.*d=\([^&]*\).*$/\1/p' | sed "s/%20/ /g"`
if [ "$DIST" != "sid" ]
then
    DIST='lenny'
fi

VERSION=`date +%F.$DIST`

cat <<END
Cache-Control: no-cache
Content-Type: text/html

<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8" />
		<title>live build $VERSION</title>
        <link rel="stylesheet" href="http://webconverger.com/style.css" type="text/css">
	</head>
<body>

END

if test `ls /tmp/live.* | wc -l` -gt 0
then

	echo "<h1>BUILD IN PROGRESS !</h1>"
	echo "<p>Only one build at a time :)</p>"

else

	if [ -e logs/$VERSION.txt ]
	then
        if [[ `grep failed logs/$VERSION.txt` ]]
        then
            echo "<h1 style='color: red;'>BUILD $VERSION FAILED :-(</h1>"
        else
            echo "<h1 style='color: green;'>BUILD $VERSION SUCCEEDED :-)</h1>"
        fi
	else
        echo "<h1>Build $VERSION begun...</h1>"
        sudo /srv/web/build.webconverger.com/wrapper.sh
		#sudo /srv/web/build.webconverger.com/build.sh $DIST &> logs/$VERSION.txt &
	fi

fi

cat <<END
<p>Build log @
<a href="logs/$VERSION.txt">$VERSION.txt</a>
</p>

<pre>
$(uname -a)
$(lh --version | head -n1)
</pre>

<ul>
<li><a href="logs/">build log archive</a></li>
<li><a href="/?d=sid">build SID</a></li>
<li><a href="/">build lenny (default)</a></li>
<li><a href="http://git.webconverger.org/?p=build.git">CGI source code</a></li>
<li><a href="http://lists.alioth.debian.org/pipermail/debian-live-devel/2008-August/004046.html">Suggestions welcome</a></li>
</ul>



</body>
</html>
END
