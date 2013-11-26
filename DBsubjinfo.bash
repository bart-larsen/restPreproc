# run like 
#  DBsubjinfo.bash 11178_20131111 age
# or -- to get everyone's age and sex into a file:
#   for d in RewardRest/*_*; do b=$(basename $d); for t in sex age; do f=$d/$b.$t.txt; [ ! -r $f -o $(cat $f| wc -l) -lt 1 ] && ./DBsubjinfo.bash $b $t |tee $f; done; done
#
sid=$1
querytype=$2

[ -z "$querytype" -o -z "$sid" ] && echo "use: $0 luna_date <age,sex,subject, or visit>"

 SUBJECT=${sid%%_*}
 VISIT=${sid##*_}

function sqlquery {
  ## ** PASSWORD and USERNAME (lncd) ** ##
  ## **    defined in ~/.my.cnf     ** ##
  # https://mariadb.com/kb/en/mysqld-configuration-files-and-groups/
  # http://stackoverflow.com/questions/16299603/mysql-utilities-my-cnf-option-file
  query=$1
  dbhost=lncddb.acct.upmchs.net
  db=lunadb_nightly
  mysql -h $dbhost $db -Be "$query" 
}


 case $querytype in 
  age) 
     sqlquery "select datediff(vt.VisitDate,si.DateOfBirth)/365.25 as age from tvisittasks as vt left join tsubjectinfo as si on si.LunaID=vt.LunaID where si.LunaID = $SUBJECT and date_format(vt.VisitDate,'%Y%m%d') = '$VISIT'" |sed 1d
  ;;
  sex) 
     sqlquery "select SexID from tsubjectinfo where lunaid = ${SUBJECT}" | sed 1d |tr '[02]' 'F' | tr '1' 'M' 
  ;;
  subject)
     sqlquery "select * from tsubjectinfo where lunaid = ${SUBJECT}" 
  ;;
  visit)
     sqlquery "select date_format(vt.visitdate,'%y%m%d') as scandate, vl.*, vt.* from tvisittasks as vt join tvisitlog as vl on vl.visitid=vt.visitid having vt.lunaid = $SUBJECT and scandate = $VISIT"
  ;;
  *) echo "dont understand $querytype"; exit 1;;
 esac




