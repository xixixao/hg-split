# Prints the current bookmark or commit
d=$PWD
while : ; do
  if test -d "$d/.git" ; then
    git=$d
    break
  elif test -d "$d/.hg" ; then
    hg=$d
    break
  fi
  test "$d" = / && break
  d=$(cd -P "$d/.." && echo "$PWD")
done

br=
if test -n "$hg" ; then
  dirstate=$(test -f $hg/.hg/dirstate && \
    hexdump -vn 20 -e '1/1 "%02x"' $hg/.hg/dirstate || \
    echo "empty")
  current="$hg/.hg/bookmarks.current"
  if  [[ -f "$current" ]]; then
    br=$(cat "$current")
  else
    br=$(echo $dirstate | cut -c 1-7)
  fi
fi

if [ -n "$br" ]; then
  printf "%s" "$br"
fi
