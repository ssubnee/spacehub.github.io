#!/bin/bash
#!/bin/sh

LANG=ko_KR.UTF-8
export LANG

clear
corp=SECURITYHUB
SC_VER="1.00"
HOSTNAME=`hostname`
YEAR=`date "+%Y"`
TODAY=`date "+%Y%m%d"`

RESULT_FILE=RESULT_${HOSTNAME}_NIXSVR-${TODAY}.txt

echo -n "전자금융기반시설 분석평가 기준"> $RESULT_FILE 2>&1
echo -n "스크립트 구동 시작 - ${TODAY} "> $RESULT_FILE 2>&1
date "+%H:%M:%S" >> $RESULT_FILE 2>&1
echo " " >> $RESULT_FILE 2>&1

echo -e "\nCopyright (c) ${YEAR} SECURITYHUB Co. Ltd. All right Reserved"

if [ \( `whoami | grep -i root | wc -l` -eq 0 \) ]; then
	echo "The diagnostic script did not run as root privilege"
	echo "root 권한으로 스크립트를 실행하여 주십시오."
	echo " "
	exit
fi


############ 인프라 및 버전 확인 ############
R_ver=0
if [ `cat /etc/*-release | uniq | grep -i -E "centos|fedora|red|xen" | wc -l ` -gt 0 ]; then
	infra="R"
	if [ `cat /etc/redhat-release | grep "6." | wc -l` -ne 0 ]; then
		R_ver=6
	else
		R_ver=7
	fi
elif [ `cat /etc/*-release | grep "suse" | wc -l` -ne 0 ]; then
	infra="S"
else infra="D"
fi


############ 변수 정의 ############
defs=(pass_warn_age pass_max_days pass_min_days)
defs_set=(7 90 1)
HOME_DIRS=`cat /etc/passwd | egrep -v 'nologin|false|sync|shutdown|halt' | grep -v "#" | awk -F":" 'length($6) > 0 {print $6}' | sort -u`
USER_ENV_FILES=".profile .bash_profile .bashrc .bash_login .cshrc .kshrc .login .exrc .netrc .history .sh_history .bash_history .dtprofile"
NFS_SERVICE="nfsd|rpc.mountd|lockd|statd|mountd"
RPC_SERVICE="rpc.cmsd|rpc.ttdbserverd|sadmind|rusersd|walld|sprayd|rstatd|rpc.nisd|rexd|rpc.pcnfsd|rpc.statd|rpc.ypupdated|rpc.rquotad|kcms_server|cachefsd"
AUTO_SERVICE="automountd|autofs|automount"
LOG_FILE="/etc/syslog.conf /etc/rsyslog.conf /etc/utmpx /var/adm/wtmp /var/adm/sulog /var/adm/loginlog /var/adm/aculog /var/adm/lastlog /var/adm/messages /var/adm/vold.log /var/adm/utmpx /var/adm/wtmpx /var/run/utmp /var/log/lastlog /var/log/messages /var/log/wtmp /var/log/utmp /var/log/authlog /var/log/syslog /var/log/xferlog /var/log/secure /var/log/auth /var/log/pacct /var/log/audit/audit.log"
dev_file="f b c p"

FUNC_CODE(){
	case $1 in
		01) CODE_S="01"; CODE_F="069"; CODE_N="비밀번호 관리정책 설정 미비";;
		02) CODE_S="02"; CODE_F="074"; CODE_N="불필요하거나 관리되지 않는 계정 존재";;
		03) CODE_S="03"; CODE_F="075"; CODE_N="유추 가능한 계정 비밀번호 존재";;
		04) CODE_S="04"; CODE_F="127"; CODE_N="계정 잠금 임계값 설정 미비";;
		05) CODE_S="05"; CODE_F="001"; CODE_N="SNMP Community 스트링 설정 미흡";;
		06) CODE_S="06"; CODE_F="004"; CODE_N="불필요한 SMTP 서비스 실행";;
		07) CODE_S="07"; CODE_F="005"; CODE_N="SMTP 서비스의 expn/vrfy 명령어 실행 제한 미비";;
		08) CODE_S="08"; CODE_F="006"; CODE_N="SMTP 서비스 로그 수준 설정 미흡";;
		09) CODE_S="09"; CODE_F="007"; CODE_N="취약한 버전의 SMTP 서비스 사용";;
		10) CODE_S="10"; CODE_F="008"; CODE_N="SMTP 서비스의 DoS 방지 기능 미설정";;
		11) CODE_S="11"; CODE_F="009"; CODE_N="SMTP 서비스 스팸 메일 릴레이 제한 미설정";;
		12) CODE_S="12"; CODE_F="010"; CODE_N="SMTP 서비스의 메일 queue 처리 권한 설정 미흡";;
		13) CODE_S="13"; CODE_F="011"; CODE_N="시스템 관리자 계정의 FTP 사용 제한 미비";;
		14) CODE_S="14"; CODE_F="012"; CODE_N=".netrc 파일 내 중요 정보 노출";;
		15) CODE_S="15"; CODE_F="013"; CODE_N="Anonymous 계정의 FTP 서비스 접속 제한 미비";;
		16) CODE_S="16"; CODE_F="014"; CODE_N="NFS 접근통제 미비";;
		17) CODE_S="17"; CODE_F="015"; CODE_N="불필요한 NFS 서비스 실행";;
		18) CODE_S="18"; CODE_F="016"; CODE_N="불필요한 RPC서비스 활성화";;
		19) CODE_S="19"; CODE_F="021"; CODE_N="FTP 서비스 접근 제어 설정 미비";;
		20) CODE_S="20"; CODE_F="022"; CODE_N="계정의 비밀번호 미설정, 빈 암호 사용 관리 미흡";;
		21) CODE_S="21"; CODE_F="025"; CODE_N="취약한 hosts.equiv 또는 .rhosts 설정 존재";;
		22) CODE_S="22"; CODE_F="026"; CODE_N="root 계정 원격 접속 제한 미비";;
		23) CODE_S="23"; CODE_F="027"; CODE_N="서비스 접근 IP 및 포트 제한 미비";;
		24) CODE_S="24"; CODE_F="028"; CODE_N="원격 터미널 접속 타임아웃 미설정";;
		25) CODE_S="25"; CODE_F="034"; CODE_N="불필요한 서비스 활성화";;
		26) CODE_S="26"; CODE_F="035"; CODE_N="취약한 서비스 활성화";;
		27) CODE_S="27"; CODE_F="037"; CODE_N="취약한 FTP 서비스 실행";;
		28) CODE_S="28"; CODE_F="040"; CODE_N="웹 서비스 디렉터리 리스팅 방지 설정 미흡";;
		29) CODE_S="29"; CODE_F="042"; CODE_N="웹 서비스 상위 디렉터리 접근 제한 설정 미흡";;
		30) CODE_S="30"; CODE_F="043"; CODE_N="웹 서비스 경로 내 불필요한 파일 존재";;
		31) CODE_S="31"; CODE_F="044"; CODE_N="웹 서비스 파일 업로드 및 다운로드 용량 제한 미설정";;
		32) CODE_S="32"; CODE_F="045"; CODE_N="웹 서비스 프로세스 권한 제한 미비";;
		33) CODE_S="33"; CODE_F="046"; CODE_N="웹 서비스 경로 설정 미흡";;
		34) CODE_S="34"; CODE_F="047"; CODE_N="웹 서비스 경로 내 불필요한 링크 파일 존재";;
		35) CODE_S="35"; CODE_F="048"; CODE_N="불필요한 웹 서비스 실행";;
		36) CODE_S="36"; CODE_F="060"; CODE_N="웹 서비스 기본 계정(아이디 또는 비밀번호) 미변경";;
		37) CODE_S="37"; CODE_F="062"; CODE_N="DNS 서비스 정보 노출";;
		38) CODE_S="38"; CODE_F="063"; CODE_N="DNS Recursive Query 설정 미흡";;
		39) CODE_S="39"; CODE_F="064"; CODE_N="취약한 버전의 DNS 서비스 사용";;
		40) CODE_S="40"; CODE_F="066"; CODE_N="DNS Zone Transfer 설정 미흡";;
		41) CODE_S="41"; CODE_F="070"; CODE_N="취약한 패스워드 저장 방식 사용";;
		42) CODE_S="42"; CODE_F="073"; CODE_N="관리자 그룹에 불필요한 사용자 존재";;
		43) CODE_S="43"; CODE_F="081"; CODE_N="Crontab 설정파일 권한 설정 미흡";;
		44) CODE_S="44"; CODE_F="082"; CODE_N="시스템 주요 디렉터리 권한 설정 미흡";;
		45) CODE_S="45"; CODE_F="083"; CODE_N="시스템 스타트업 스크립트 권한 설정 미흡";;
		46) CODE_S="46"; CODE_F="084"; CODE_N="시스템 주요 파일 권한 설정 미흡";;
		47) CODE_S="47"; CODE_F="087"; CODE_N="C 컴파일러 존재 및 권한 설정 미흡";;
		48) CODE_S="48"; CODE_F="091"; CODE_N="불필요하게 SUID, SGID bit가 설정된 파일 존재";;
		49) CODE_S="49"; CODE_F="092"; CODE_N="사용자 홈 디렉터리 설정 미흡";;
		50) CODE_S="50"; CODE_F="093"; CODE_N="불필요한 world writable 파일 존재";;
		51) CODE_S="51"; CODE_F="094"; CODE_N="Crontab 참조파일 권한 설정 미흡";;
		52) CODE_S="52"; CODE_F="095"; CODE_N="존재하지 않는 소유자 및 그룹 권한을 가진 파일 또는 디렉터리 존재";;
		53) CODE_S="53"; CODE_F="096"; CODE_N="사용자 환경파일의 소유자 또는 권한 설정 미흡";;
		54) CODE_S="54"; CODE_F="108"; CODE_N="로그에 대한 접근통제 및 관리 미흡";;
		55) CODE_S="55"; CODE_F="109"; CODE_N="시스템 주요 이벤트 로그 설정 미흡";;
		56) CODE_S="56"; CODE_F="112"; CODE_N="Cron 서비스 로깅 미설정 (항목명 변경)";;
		57) CODE_S="57"; CODE_F="115"; CODE_N="로그의 정기적 검토 및 보고 미수행";;
		58) CODE_S="58"; CODE_F="121"; CODE_N="root 계정의 PATH 환경변수 설정 미흡";;
		59) CODE_S="59"; CODE_F="122"; CODE_N="UMASK 설정 미흡";;
		60) CODE_S="60"; CODE_F="131"; CODE_N="SU 명령 사용가능 그룹 제한 미비";;
		61) CODE_S="61"; CODE_F="133"; CODE_N="Cron 서비스 사용 계정 제한 미비";;
		62) CODE_S="62"; CODE_F="134"; CODE_N="스택 영역 실행 방지 미설정";;
		63) CODE_S="63"; CODE_F="135"; CODE_N="TCP 보안 설정 미비";;
		64) CODE_S="64"; CODE_F="142"; CODE_N="중복 UID가 부여된 계정 존재";;
		65) CODE_S="65"; CODE_F="144"; CODE_N="/dev 경로에 불필요한 파일 존재";;
		66) CODE_S="66"; CODE_F="147"; CODE_N="불필요한 SNMP 서비스 실행";;
		67) CODE_S="67"; CODE_F="148"; CODE_N="웹 서비스 정보 노출";;
		68) CODE_S="68"; CODE_F="158"; CODE_N="불필요한 Telnet 서비스 실행";;
		69) CODE_S="69"; CODE_F="161"; CODE_N="ftpusers 파일의 소유자 및 권한 설정 미흡";;
		70) CODE_S="70"; CODE_F="163"; CODE_N="시스템 사용 주의사항 미출력";;
		71) CODE_S="71"; CODE_F="164"; CODE_N="구성원이 존재하지 않는 GID 존재";;
		72) CODE_S="72"; CODE_F="165"; CODE_N="불필요하게 Shell이 부여된 계정 존재";;
		73) CODE_S="73"; CODE_F="166"; CODE_N="불필요한 숨김 파일 또는 디렉터리 존재";;
		74) CODE_S="74"; CODE_F="170"; CODE_N="SMTP 서비스 정보 노출";;
		75) CODE_S="75"; CODE_F="171"; CODE_N="FTP 서비스 정보 노출";;
		76) CODE_S="76"; CODE_F="173"; CODE_N="DNS 서비스의 취약한 동적 업데이트 설정";;
		77) CODE_S="77"; CODE_F="174"; CODE_N="불필요한 DNS 서비스 실행";;
		78) CODE_S="78"; CODE_F="175"; CODE_N="NTP 및 시각 동기화 미설정";;
		79) CODE_S="79"; CODE_F="118"; CODE_N="주기적인 보안패치 및 벤더 권고사항 미적용";;
		*) echo "SCRIPT ERROR - 컨설턴트에 문의하십시오";;
	esac
	CODE_P="./${Result_Dir_Name}/U-${CODE_S}"
	echo -e "\n-------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
	echo -e -n "\n\e[31m(U-${CODE_S}\e[0m|SRV-${CODE_F}) ${CODE_N}"
	echo "(U-${CODE_S}|SRV-${CODE_F}) ${CODE_N}"													>>	$RESULT_FILE 2>&1
	echo -e "-------------------------------------------------------------------------------------\n"	>>	$RESULT_FILE 2>&1
}

############ 서비스 확인 ############
ch_service(){
damon="$1"
port="$2"
remove="$3"

if [ -z $remove ]; then
	ps -ef | egrep -i "$damon" | grep -v "grep"	> ps.txt
	systemctl list-units --type service -all | grep -v "inactive" | egrep -i "$damon" | grep -v "grep" 	>>	ps.txt
else
	ps -ef | egrep -i "$damon" | egrep -v "$remove" | grep -v "grep" > ps.txt
	systemctl list-units --type service -all | grep -v "inactive" | egrep -i "$damon"| egrep -v "$remove" | grep -v "grep"	>>	ps.txt
fi

ss -nl | grep ":$port\>" > netstat.txt

if [ `cat ps.txt | wc -l` -eq 0 ]; then
	echo "[ Disable - $damon 서비스 미구동중 ]"														>>	$RESULT_FILE 2>&1
	if [ $port != NA ]; then 
		if [ `cat netstat.txt | wc -l` -eq 0 ]; then
			echo "[ $port번 포트 상태: LISTENING 상태 아님 ]"											>>	$RESULT_FILE 2>&1
			echo pass
		else
			echo "[ $port번 포트 상태: LISTENING 상태 ]"												>>	$RESULT_FILE 2>&1
			cat netstat.txt																		>>	$RESULT_FILE 2>&1
			echo review
		fi
	else echo pass; fi
else
	echo "[ Enable - $damon 서비스 구동중 ]"															>>	$RESULT_FILE 2>&1
	cat ps.txt																					>>	$RESULT_FILE 2>&1
	if [ $port != NA ]; then 
		echo " "																				>>  $RESULT_FILE 2>&1
		if [ `cat netstat.txt | wc -l` -eq 0 ]; then
			echo "[ $port번 포트 상태: LISTENING 상태 아님 ]"											>>	$RESULT_FILE 2>&1
			echo review
		else
			echo "[ $port번 포트 상태: LISTENING 상태 ]"												>>	$RESULT_FILE 2>&1
			cat netstat.txt																		>>	$RESULT_FILE 2>&1
			echo check
		fi
	else echo check; fi
fi
}


############ 소유자, 권한 체크 ############
#check_per "/etc/hosts.lpd" "6" "0" "0" "NA"
check_per(){
per=`stat -c "%a" $1`
check_u=`echo $per | awk '{print substr($per, 1, 1)}'`
check_g=`echo $per | awk '{print substr($per, 2, 1)}'`
check_o=`echo $per | awk '{print substr($per, 3, 1)}'`

if [ "$check_g" == "" ]; then check_g=0; fi
if [ "$check_o" == "" ]; then check_o=0; fi

if [ $check_u -le $2 ] && [ $check_g -le $3 ] && [ $check_o -le $4 ]; then
	if [ `stat -c "%U" $1 | grep -i 'root' | wc -l` -eq 1 ]; then
		if [ -z $5 ]; then echo "o $1 파일 소유자 및 접근권한($2$3$4 이하) 설정 양호"; fi					>>  $RESULT_FILE 2>&1
	else
		if [ -z $5 ]; then echo "o $1 파일의 접근권한 설정은 $2$3$4 이하로 양호하나, 소유자 설정 미흡함"; fi		>>	$RESULT_FILE 2>&1
	fi
else
	if [ `stat -c "%U" $1 | grep -i 'root' | wc -l` -eq 1 ]; then
		if [ -z $5 ]; then echo "o $1 파일 소유자 설정은 양호하나 접근권한 $2$3$4 초과로 설정 미흡"; fi			>>  $RESULT_FILE 2>&1
	else
		if [ -z $5 ]; then echo "o $1 파일 소유자(root) 및 접근권한($2$3$4 이하) 설정 미흡함"; fi			>>  $RESULT_FILE 2>&1
	fi
fi

}


############ 파일 내 설정 값 검색 ############
#do_find_parameter "/etc/ssh/sshd_config" "PermitRootLogin( |	)+no"
do_find_parameter() {
filename="$1"
parameter_name="$2"
if [ -f $filename ]; then
    echo ">> $filename 파일 내 설정"
    if [ `cat $filename | grep -v "^\#" | egrep -i "$parameter_name" | wc -l` -eq 0 ]; then
		# 파일 내 설정 값 찾지 못할 경우
		echo "o $parameter_name 설정 값 존재하지 않음"
		return 99
    else
		# 파일 내 설정 값 찾은 경우
		cat $filename | egrep -i "$parameter_name"
		return 1
    fi
else
    # 파일 존재하지 않는 경우
    echo "o $filename 파일 존재하지 않음" && return 0
fi
}

web_option(){
	WEB=$1; CONF=$2; OPTION=$3; f_ch=1;
		echo "" > dir.txt
	if [ $WEB = "apache" ]; then
		cat $CONF | grep -n -i "<directory" | grep -v "#" | cut -d: -f1	>	start.txt
		cat $CONF | grep -n -i "</directory" | grep -v "#" | cut -d: -f1	>	end.txt
	elif [ $WEB = "nginx" ]; then
		cat $CONF | grep -n -i "location " | grep -v "#" | cut -d: -f1	>	start.txt
		cat $CONF | grep -n -i "}" | grep -v "#" | cut -d: -f1	>	end.txt
	fi
	start=(`cat start.txt`)
	end=(`cat end.txt`)
	for ((i=0;i<${#start[@]};i++))
	do
		s=`echo ${start[$i]}`
		e=`echo ${end[$i]}`
		com=`sed -n ${s}p $CONF`
		if [ `cat dir.txt | grep "$com" | wc -l` -eq 0 ]; then
			sed -n $s,${e}p $CONF	>>	dir.txt
			if [ $OPTION == "NA" ]; then f_ch=0
			elif [ `sed -n $s,${e}p $CONF | egrep -i "$OPTION" | grep -v "#" | wc -l` -gt 0 ]; then
				if [ $CONF != $ACONF ]; then ls -al $CONF; fi 										>>	$RESULT_FILE 2>&1
				sed -n $s,${e}p $CONF | grep -v "#"													>>	$RESULT_FILE 2>&1
				echo " "																			>>	$RESULT_FILE 2>&1
				f_ch=0
			fi
		fi
	done
	if [ $f_ch -eq 0 ]; then return 0; else return 99; fi
}

############ Apache 로우데이터 ############
if [ `ps -ef | egrep -i "httpd|apache2" | egrep -v "lighttp|ns-httpd|grep" | wc -l` -ge 1 ]; then
	APACHE_CHECK=ON
	if [ `ps -ef | egrep -i "httpd|apache2" | egrep -v "lighttp|ns-httpd|grep" | awk '{print $8}' | grep "/" | egrep -v "httpd.conf|apache2.conf" | uniq | wc -l` -gt 0 ]; then
		APROC1=`ps -ef | egrep -i "httpd|apache2" | grep -v "ns-httpd" | grep -v "grep" | awk '{print $8}' | grep "/" | egrep -v "httpd.conf|apache2.conf" | uniq`
		APROC=`echo $APROC1 | awk '{print $1}'`
		if [ `$APROC -V | grep -i "root" | wc -l` -gt 0 ]; then
			AHOME1=`$APROC -V | grep -i "root" | awk -F"\"" '{print $2}'`
			ACFILE=`$APROC -V | grep -i "server_config_file" | awk -F"\"" '{print $2}'`
		fi
	fi
	ACONF1=$AHOME1/$ACFILE
else
	APACHE_CHECK=OFF
fi

############ NginX 로우데이터 ############
if [ `ps -ef | egrep -i "nginx" | egrep -v "grep" | wc -l` -ge 1 ]; then
	NGINX_CHECK=ON
	ARRAY=(`ps -ef | egrep -i "nginx" | egrep -v "grep"`)
	for ((i=0;i<${#ARRAY[@]};i++))
	do
		if [ `echo ${ARRAY[$i]} | grep -i "nginx.conf" | wc -l` -ge 1 ]; then
			nxconf1=${ARRAY[$i]}
			nxdir1=`echo ${ARRAY[$i]} | cut -c -10`
		fi
	done
	echo " "																				>>	$RESULT_FILE 2>&1
else
	NGINX_CHECK=OFF
fi

AHOME=`echo $AHOME1 | tr -d ' '`
ACONF=`echo $ACONF1 | tr -d ' '`
nxconf=`echo $nxconf1 | tr -d ' '`
nxdir=`echo $nxdir1 | tr -d ' '`

############ Apache / NginX 관련 파일 없을 경우 입력 동작 ############
if [ $APACHE_CHECK = "OFF" ] && [ $NGINX_CHECK = "OFF" ]; then
	echo "*** 웹 서비스 미구동 중" | tee -a $RESULT_FILE
else
	pre_apache=0; pre_nginx=0
	echo "*** 웹 서비스 구동 중" | tee -a $RESULT_FILE
	if [ $APACHE_CHECK = "ON" ]; then
		if [ -z $AHOME ] || [ -z $ACONF ]; then
			pre_apache=1
			if [ ! -d $AHOME ] || [ ! -f $ACONF ]; then
				pre_apache=1
			fi
		fi
	fi
	if [ $NGINX_CHECK = "ON" ]; then
		if [ -z $nxdir ] || [ -z $nxconf ]; then
			pre_nginx=1
			if [ ! -d $nxdir ] || [ ! -f $nxconf ]; then
				pre_nginx=1
			fi
		fi
	fi
	if [ $pre_apache -eq 1 ] || [ $pre_nginx -eq 1 ]; then
		echo -e "\n\e[34m##################################################"
		echo -e "		     Pre-entry information"
		echo -e "##################################################\e[0m\n"
		if [ $pre_apache -eq 1 ]; then
			retry=0
			while true
			do
				if [ $retry -lt 2 ]; then
					if [ -z $AHOME ] || [ ! -d $AHOME ]; then
						echo "Do not exist $AHOME!! Please, Checked Apache root directory."
						echo -e -n "\e[33m#[Apache ServerRoot(Install Directory) Input ](ex. /etc/apache2) : \e[0m"
						read AHOME
						retry=0
					else
						retry=`expr $retry + 1`
					fi
					if [ -z $ACONF ] || [ ! -f $ACONF ]; then
						echo "Do not exist $ACONF!! Please, Checked Apache configure file."
						echo -e -n "\e[33m#[Apache httpd.conf File path Input ](ex. /etc/httpd/conf/httpd.conf) : \e[0m"
						read ACONF
						retry=0
					else
						retry=`expr $retry + 1`
					fi
				else
					echo " "
					break
				fi
				sleep 1
			done
		fi
		if [ $pre_nginx -eq 1 ]; then
			retry=0
			while true
			do
				if [ $retry -lt 2 ]; then
					if [ -z $nxdir ] || [ ! -d $nxdir ]; then
						echo "Do not exist $nxdir!! Please, Checked Nginx root directory."
						echo -e -n "\e[33m#[Enter full path to NginX install directory ](ex. /etc/nginx) : \e[0m"
						read nxdir
						retry=0
					else
						retry=`expr $retry + 1`
					fi
					if [ -z $nxconf ] || [ ! -f $nxconf ]; then
						echo "Do not exist $nxconf!! Please, Checked Nginx configure file."
						echo -e -n "\e[33m#[Enter full path to NginX config file](ex. /etc/nginx/nginx.conf) : \e[0m"
						read nxconf
						retry=0
					else
						retry=`expr $retry + 1`
					fi
				else
					echo " "
					break
				fi
				sleep 1
			done
		fi
	fi
	if [ $APACHE_CHECK = "ON" ]; then
		echo "Apache install directory : $AHOME" 2>&1 | tee -a $RESULT_FILE
		echo "Apache config file : $ACONF" 2>&1 | tee -a $RESULT_FILE
	elif [ $NGINX_CHECK = "ON" ]; then
		echo "NginX install directory : $nxdir" 2>&1 | tee -a $RESULT_FILE 
		echo "NginX config file : $nxconf" 2>&1 | tee -a $RESULT_FILE
	fi
fi

echo -e "\n\n\e[34m--------> 전자금융기반시설 분석평가 기준"
echo -e "##################################################"
echo -e "            Script ... START"
echo -e "##################################################\e[0m\n"

echo -e "\n"																					>>	$RESULT_FILE 2>&1
echo "====================================================================================="	>>	$RESULT_FILE 2>&1
echo "========================                                    ========================="	>>	$RESULT_FILE 2>&1
echo "==========                   Linux Security Check Script                   =========="	>>	$RESULT_FILE 2>&1
echo "========================                                    ========================="	>>	$RESULT_FILE 2>&1
echo "====================================================================================="	>>	$RESULT_FILE 2>&1
echo -e "\n"																					>>	$RESULT_FILE 2>&1

####################################################################

echo -e "\n\e[4m<< 사용자 인증 >>\e[0m"

FUNC_CODE "01"
echo ">> /etc/login.defs 파일"																>>	$RESULT_FILE 2>&1
if [ -f /etc/login.defs ]; then
	for ((i=0;i<${#defs[@]};i++))
	do
		ch_day=`cat /etc/login.defs | grep -i "${defs[$i]}" | grep -v "^#" | awk '{print $2}'`
		if [ -z $ch_day ]; then
			echo "o ${defs[$i]} 값이 주석처리 또는 존재하지 않아 미흡함"									>>	$RESULT_FILE 2>&1
		else
			if [ `expr $i % 2` -eq 0 ]; then
				if [ $ch_day -lt ${defs_set[$i]} ]; then
					echo "o ${defs[$i]} 가 ${defs_set[$i]}일 미만으로 설정이 미흡함"					>>	$RESULT_FILE 2>&1
				else
					echo "o ${defs[$i]} 가 ${defs_set[$i]}일 이상으로 설정이 양호"					>>	$RESULT_FILE 2>&1
					ch_defs_Y=`expr $ch_defs_Y + 1`
				fi
			else
				if [ $ch_day -gt ${defs_set[$i]} ]; then
					echo "o ${defs[$i]} 가 ${defs_set[$i]}일 초과로 설정이 미흡함"					>>	$RESULT_FILE 2>&1
				else
					echo "o ${defs[$i]} 가 ${defs_set[$i]}일 이하로 설정이 양호"					>>	$RESULT_FILE 2>&1
					ch_defs_Y=`expr $ch_defs_Y + 1`
				fi
			fi
		fi
		cat /etc/login.defs | grep -i "${defs[$i]}"	| egrep -v "*\."						>>	$RESULT_FILE 2>&1
	done
else
    echo " → /etc/login.defs 파일 존재하지 않음"													>>	$RESULT_FILE 2>&1
fi
echo " "																					>>	$RESULT_FILE 2>&1
do_find_parameter "/etc/security/pwquality.conf" "minlen|lcredit|ucredit|dcredit|ocredit|difok|maxrepeat|minclass|maxclassrepeat"	>>	$RESULT_FILE 2>&1
if [ $infra == "R" ]; then
	do_find_parameter "/etc/pam.d/system-auth" "pam_cracklib.so|minlen|pwquality"			>>	$RESULT_FILE 2>&1
	echo " "																				>>	$RESULT_FILE 2>&1
	do_find_parameter "/etc/pam.d/password-auth" "pam_cracklib.so|minlen|pwquality"			>>	$RESULT_FILE 2>&1
else
	do_find_parameter "/etc/pam.d/common-auth" "pam_cracklib.so|minlen|pwquality"			>>	$RESULT_FILE 2>&1
	echo " "																				>>	$RESULT_FILE 2>&1
	do_find_parameter "/etc/pam.d/common-password" "pam_cracklib.so|minlen|pwquality"		>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "02"
echo ">> 최근 접속정보"																				>>	$RESULT_FILE 2>&1
for user in $(egrep -v "/false|/nologin|/sync|shutdown|halt" /etc/passwd | cut -f1 -d:); do lastlog -u $user; done	>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo ">> 패스워드 변경 일"																			>>	$RESULT_FILE 2>&1
for user in $(egrep -v "/false|/nologin|/sync|/shutdown|/halt" /etc/passwd | cut -f1 -d:); do passwd -S $user; done	>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "03"
echo ">> /etc/passwd"																			>>	$RESULT_FILE 2>&1
cat /etc/passwd | egrep -v "/false|/nologin|/sync|/shutdown|/halt"								>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo ">> /etc/shadow"																			>>	$RESULT_FILE 2>&1
for user in $(egrep -v "/false|/nologin|/sync|/shutdown|/halt" /etc/passwd | cut -f1 -d:); do grep -i $user /etc/shadow; done	>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "04"
do_find_parameter "/etc/login.defs" "LOGIN_RETRIES"												>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo ">> PAM 설정 확인 - pam_tally / pam_faillock 확인"												>>	$RESULT_FILE 2>&1
if [ $infra == "R" ]; then
	do_find_parameter "/etc/pam.d/system-auth" "faillock|tally|deny|lock_time"					>>	$RESULT_FILE 2>&1
	echo " "																					>>	$RESULT_FILE 2>&1
	do_find_parameter "/etc/pam.d/password-auth" "faillock|tally|deny|lock_time"				>>	$RESULT_FILE 2>&1
else
	do_find_parameter "/etc/pam.d/common-auth" "faillock|tally|deny|lock_time"					>>	$RESULT_FILE 2>&1
	echo " "																					>>	$RESULT_FILE 2>&1
	do_find_parameter "/etc/pam.d/common-account" "faillock|tally|deny|lock_time"				>>	$RESULT_FILE 2>&1
fi
echo " "																						>>	$RESULT_FILE 2>&1
echo ">> PAM 설정 확인 - Telnet"																	>>	$RESULT_FILE 2>&1
ls -al /etc/pam.d/remote																		>>	$RESULT_FILE 2>&1
cat /etc/pam.d/remote																			>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo ">> PAM 설정 확인 - SSH"																		>>	$RESULT_FILE 2>&1
ls -al /etc/pam.d/sshd																			>>	$RESULT_FILE 2>&1
cat /etc/pam.d/sshd																				>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


####################################################################

echo -e "\n\e[4m<< 보안 관리 >>\e[0m"

FUNC_CODE "05"
ch=`ch_service "snmp" "161"`
if [ $ch == check ] || [ $ch == review ];then
	echo ">>  SNMP community name"																>>	$RESULT_FILE 2>&1
	do_find_parameter "/etc/snmp/snmpd.conf" "com2sec"											>>	$RESULT_FILE 2>&1
	if [ $? = 1 ]; then
		snmp_st=`cat /etc/snmp/snmpd.conf | grep -v "^\#" | grep -i "com2sec" | awk ' { printf $4 }' | tr '[A-Z]' '[a-z]'`
		if [ `echo $snmp_st | egrep -i "public|private" | wc -l` = 1 ] ; then
			echo "o SNMP Community String 초기 값(Public, Private) 설정 중으로 미흡"					>>	$RESULT_FILE 2>&1
		else
			echo "o SNMP Community String이 기본 값이 아닌 별도의 값으로 설정되어 있음"						>>	$RESULT_FILE 2>&1
		fi
	fi
	echo " "																					>>	$RESULT_FILE 2>&1
	do_find_parameter "/etc/snmp/snmpd.conf" "rwuser|rouser"									>>	$RESULT_FILE 2>&1
	if [ $? = 1 ]; then
		snmp_st=`cat /etc/snmp/snmpd.conf | grep -v "^\#" | egrep -i "rwuser|rouser" | awk '{ printf $2 }' | tr '[A-Z]' '[a-z]'`
		if [ `echo $snmp_st | egrep -i "public|private" | wc -l` = 1 ] ; then 
			echo "o SNMP Community String 초기 값(Public, Private) 설정 중으로 미흡"					>>	$RESULT_FILE 2>&1
		else
			echo " ㅇ SNMP Community String이 기본 값이 아닌 별도의 값으로 설정되어 있음"						>>	$RESULT_FILE 2>&1
		fi
	fi
	cat /etc/snmp/snmpd.conf | grep -v "^#" | egrep -i "rwuser|rouser|com2sec"					>>	$RESULT_FILE 2>&1
else
	echo "o SNMP 서비스 미구동 중으로 평가 해당없음"														>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "06"
echo ">> SMTP 구동 확인"																			>>	$RESULT_FILE 2>&1
echo " # sendmail"																				>>	$RESULT_FILE 2>&1
ch=`ch_service "sendmail" "25"`
if [ $ch == check ]; then
    sendmail_state=0
else
    sendmail_state=1
fi
echo -e "\n # postfix"																			>>	$RESULT_FILE 2>&1
ch=`ch_service "postfix" "25"`
if [ $ch == check ]; then
    postfix_state=0
else
    postfix_state=1
fi
echo -e "\n # Exim"																				>>	$RESULT_FILE 2>&1
ch=`ch_service "exim" "NA"`
if [ $ch == check ]; then
    exim_state=0
else
    exim_state=1
fi
echo -e ".........\e[7mDone!\e[0m"



FUNC_CODE "07" #SMTP 서비스의 expn/vrfy 명령어 실행 제한 미비
if [ $sendmail_state -eq 1 ] && [ $postfix_state -eq 1 ] && [ $exim_state -eq 1 ]; then
	echo "o SMTP(Sendmail, Postfix, Exim) 서비스 미구동 중으로 평가 해당없음"								>> $RESULT_FILE 2>&1
else
	if [ $sendmail_state -eq 0 ]; then
		do_find_parameter "/etc/mail/sendmail.cf" "PrivacyOptions|novrfy|noexpn|goaway"			>>	$RESULT_FILE 2>&1
	fi
	if [ $postfix_state -eq 0 ]; then
		do_find_parameter "/etc/postfix/main.cf" "disable_vrfy_command"							>>	$RESULT_FILE 2>&1
	fi
	if [ $exim_state -eq 0 ]; then
		do_find_parameter "/etc/exim4/exim4.conf.template" "acl_smtp_expn|acl_smtp_vrfy"		>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/exim/exim4.conf" "acl_smtp_expn|acl_smtp_vrfy"					>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/exim4/conf.d/*.conf" "acl_smtp_expn|acl_smtp_vrfy"				>>	$RESULT_FILE 2>&1
	fi
fi
echo -e ".........\e[7mDone!\e[0m"



FUNC_CODE "08" #SMTP 서비스 로그 수준 설정 미흡 #sendmail Default 9 #exim Default 5
if [ $sendmail_state -eq 1 ] && [ $postfix_state -eq 1 ] && [ $exim_state -eq 1 ]; then
	echo "o SMTP(Sendmail, Postfix, Exim) 서비스 미구동 중으로 평가 해당없음"								>> $RESULT_FILE 2>&1
else
	if [ $sendmail_state -eq 0 ]; then
		do_find_parameter "/etc/mail/sendmail.cf" "LogLevel"									>>	$RESULT_FILE 2>&1
	fi
	if [ $postfix_state -eq 0 ]; then
		do_find_parameter "/etc/postfix/main.cf" "debug_peer_level"								>>	$RESULT_FILE 2>&1
	fi
	if [ $exim_state -eq 0 ]; then
		do_find_parameter "/etc/exim4/exim4.conf.template" "log_level"							>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/exim/exim4.conf" "log_level"									>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/exim4/conf.d/*.conf" "log_level"								>>	$RESULT_FILE 2>&1
	fi
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "09" #취약한 버전의 SMTP 서비스 사용
if [ $sendmail_state -eq 1 ] && [ $postfix_state -eq 1 ] && [ $exim_state -eq 1 ]; then
	echo "o SMTP(Sendmail, Postfix, Exim) 서비스 미구동 중으로 평가 해당없음"								>> $RESULT_FILE 2>&1
else
	if [ $sendmail_state -eq 0 ]; then
		do_find_parameter "/etc/mail/sendmail.cf" "DZ"											>>	$RESULT_FILE 2>&1
		echo \$Z | /usr/lib/sendmail -bt -d0													>>	$RESULT_FILE 2>&1
	fi
	if [ $postfix_state -eq 0 ]; then
		echo ">> postfix 버전 확인"																>>	$RESULT_FILE 2>&1
		postconf -d mail_version																>>	$RESULT_FILE 2>&1
	fi
	if [ $exim_state -eq 0 ]; then
		echo ">> Exim 버전 확인"																	>>	$RESULT_FILE 2>&1
		exim -bV																				>>	$RESULT_FILE 2>&1
	fi
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "10" #SMTP 서비스의 DoS 방지 기능 미설정
if [ $sendmail_state -eq 1 ] && [ $postfix_state -eq 1 ] && [ $exim_state -eq 1 ]; then
	echo "o SMTP(Sendmail, Postfix, Exim) 서비스 미구동 중으로 평가 해당없음"								>>	$RESULT_FILE 2>&1
else
	if [ $sendmail_state -eq 0 ]; then
		do_find_parameter "/etc/mail/sendmail.cf" "MaxDaemonChildren|ConnectionRateThrottle|MinFreeBlocks|MaxHeadersLength|MaxMessageSize"	>>	$RESULT_FILE 2>&1
	fi
	if [ $postfix_state -eq 0 ]; then
		do_find_parameter "/etc/postfix/main.cf" "message_size_limit|header_size_limit|default_process_limit|local_destination_concurrency_limit|smtpd_recipient_limit"	>>	$RESULT_FILE 2>&1
	fi
	if [ $exim_state -eq 0 ]; then
		do_find_parameter "/etc/exim4/exim4.conf.template" "message_size_limit|header_maxsize|queue_run_max|recipients_max"	>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/exim/exim4.conf" "message_size_limit|header_maxsize|queue_run_max|recipients_max"	>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/exim4/conf.d/*.conf" "message_size_limit|header_maxsize|queue_run_max|recipients_max"	>>	$RESULT_FILE 2>&1
	fi
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "11" #SMTP 서비스 스팸 메일 릴레이 제한 미설정
if [ $sendmail_state -eq 1 ] && [ $postfix_state -eq 1 ] && [ $exim_state -eq 1 ]; then
	echo "o SMTP(Sendmail, Postfix, Exim) 서비스 미구동 중으로 평가 해당없음"								>>	$RESULT_FILE 2>&1
else
	if [ $sendmail_state -eq 0 ]; then
		echo -n "현재 버전: "																		>>	$RESULT_FILE 2>&1
		cat /etc/mail/sendmail.cf | grep -i "DZ" | cut -c 3-									>>	$RESULT_FILE 2>&1
		egrep -i "R$\*|Relaying\sdenied" /etc/mail/sendmail.cf									>>	$RESULT_FILE 2>&1
		if [ -f /etc/mail/access ]; then
			echo -e "\n>> /etc/mail/access 파일"													>>	$RESULT_FILE 2>&1
			cat /etc/mail/access | egrep -v "^[[:space:]]*(#.*)?$"								>>	$RESULT_FILE 2>&1
		fi
	fi
	if [ $postfix_state -eq 0 ]; then
		do_find_parameter "/etc/postfix/main.cf" "smtpd_recipient_restrictions|smtpd_relay_restrictions|permit"	>>	$RESULT_FILE 2>&1
	fi
	if [ $exim_state -eq 0 ]; then
		do_find_parameter "/etc/exim4/exim4.conf.template" "acl_smtp_rcpt|accept"				>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/exim/exim4.conf" "acl_smtp_rcpt|accept"							>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/exim4/conf.d/*.conf" "acl_smtp_rcpt|accept"						>>	$RESULT_FILE 2>&1
	fi
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "12" #SMTP 서비스의 메일 queue 처리 권한 설정 미흡
if [ $sendmail_state -eq 1 ] && [ $postfix_state -eq 1 ] && [ $exim_state -eq 1 ]; then
	echo "o SMTP(Sendmail, Postfix, Exim) 서비스 미구동 중으로 평가 해당없음"								>>	$RESULT_FILE 2>&1
else
	if [ $sendmail_state -eq 0 ]; then
		do_find_parameter "/etc/mail/sendmail.cf" "PrivacyOptions|restrictqrun"					>>	$RESULT_FILE 2>&1
	fi
	if [ $postfix_state -eq 0 ]; then
		if [ -f "/usr/sbin/postsuper" ]; then
			right=`stat -c "%a" /usr/sbin/postsuper`
			if [ ${right: -1} -eq 0 ]; then
				echo "ㅇ /usr/sbin/postsuper 실행 권한에 others 권한 부여되지 않음"							>>	$RESULT_FILE 2>&1
			else
				echo "ㅇ /usr/sbin/postsuper 실행 권한에 others 권한 부여되어 있어 미흡"							>>	$RESULT_FILE 2>&1
			fi
			ls -alL /usr/sbin/postsuper																>>	$RESULT_FILE 2>&1
		else
			postsuper_file=(`find / -type f -name "postsuper"`)
			for ((i=0;i<${#postsuper_file[@]};i++)); do
				ls -alL ${postsuper_file[$i]}														>>	$RESULT_FILE 2>&1
			done
		fi
	fi
	if [ $exim_state -eq 0 ]; then
		echo "o 수동 점검"																				>>	$RESULT_FILE 2>&1
	fi
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "13"
if [ `ch_service "ftp" "NA"` == check ]; then
	if [ `ps -ef | grep -i "ftp" | egrep -v -i "/sftp|grep" | wc -l` -eq 0 ]; then
		echo "ㅇ SFTP 사용 중이므로 인증된 사용자의 접근만 허용되어 양호"										>>	$RESULT_FILE 2>&1
	else
		echo ">> ftpusers 파일"																	>>	$RESULT_FILE 2>&1
		find /etc /usr /var -type f -name "ftpusers" -exec sh -c "ls -al {}; cat {};" \;		>>	$RESULT_FILE 2>&1
		echo -e "\n>> ftpusers 파일 내 root 계정 존재 확인"											>>	$RESULT_FILE 2>&1
		echo "# vsFTP 서비스"																		>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/vsftpd/ftpusers" "root"											>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/vsftpd/user_list" "root"										>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/vsftpd.ftpusers" "root"											>>	$RESULT_FILE 2>&1
		echo -e "\n# proftpd 서비스"																>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/ftpusers" "root"												>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/ftpd/ftpusers" "root"											>>	$RESULT_FILE 2>&1
	fi
else
	echo "o FTP 서비스 미구동 중으로 평가 해당없음"															>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "14" #.netrc 파일 내 중요 정보 노출
for DIR in $HOME_DIRS
do
	if [ -d $DIR ]; then
		if [ `find "$DIR" -type f -name '.netrc' | wc -l` -gt 0 ]; then
			for ntfile in `find "$DIR" -type f -name '.netrc'`
			do
				ls -alL $ntfile																	>>	$RESULT_FILE 2>&1
				echo "o $ntfile 파일 존재, 파일 내부에 아이디, 패스워드 등 민감한 정보 존재하는지 확인"				>>	$RESULT_FILE 2>&1
			done
		else
			echo "o $DIR/.netrc 파일 존재하지 않음"														>>	$RESULT_FILE 2>&1
		fi
	fi
done
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "15" #Anonymous 계정의 FTP 서비스 접속 제한 미비
if [ `ch_service "ftp" "NA"` == check ]; then
	if [ `ps -ef | grep -i "ftp" | egrep -v -i "/sftp|grep" | wc -l` -eq 0 ]; then
		echo "ㅇ SFTP 사용 중이므로 인증된 사용자의 접근만 허용되어 양호"											>>	$RESULT_FILE 2>&1
	else
		echo "# vsFTP 서비스"																		>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/vsftpd/ftpusers" "anonymous"									>>	$RESULT_FILE 2>&1
		echo -e "\n# proftpd 서비스"																>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/proftpd.conf" "User|UserAlias"									>>	$RESULT_FILE 2>&1
		do_find_parameter "/usr/local/etc/proftpd.conf" "User|UserAlias"						>>	$RESULT_FILE 2>&1
	fi
else
	echo "o FTP 서비스 미구동 중으로 평가 해당없음"															>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "16"
if [ `ch_service "nfsd" "2049"` == pass ]; then
	echo "o NFS 서비스 미구동 중으로 평가 해당없음"															>>	$RESULT_FILE 2>&1
else
	echo -e "\n>> /etc/exports 파일 - directory에 대한 hostname 조건 확인"								>>	$RESULT_FILE 2>&1
	cat /etc/exports																			>>	$RESULT_FILE 2>&1
	echo -e "\n>> /etc/nfsmount.conf 파일"														>>	$RESULT_FILE 2>&1
	cat /etc/nfsmount.conf																		>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "17"
ch=`ch_service "nfsd" "2049"` >/dev/null
if [ $ch == pass ]; then
	echo "o NFS 서비스 미구동 중으로 평가 해당없음"															>>	$RESULT_FILE 2>&1
else
	ch_service $NFS_SERVICE "NA"
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "18"
if [ `ch_service "$RPC_SERVICE" "NA"` == pass ]; then
	echo "o RPC 서비스 미구동 중으로 양호"																>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "19" #FTP 서비스 접근 제어 설정 미비 (2023 항목 추가)
if [ `ch_service "ftp" "NA"` == check ]; then
	if [ `ps -ef | grep -i "ftp" | egrep -v -i "/sftp|grep" | wc -l` -eq 0 ]; then
		echo "ㅇ SFTP 사용 중이므로 인증된 사용자의 접근만 허용되어 양호"										>>	$RESULT_FILE 2>&1
	else
		echo -e "\n>> 특정 IP에 대한 FTP 접근제어 설정"													>>	$RESULT_FILE 2>&1
		echo " # vsFTP 서비스"																		>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/vsftpd/vsftpd.conf" "listen|tcp_wrappers"						>>	$RESULT_FILE 2>&1
		echo "listen=YES, tcp_wrappers=YES 인 경우 U-23 확인"										>>	$RESULT_FILE 2>&1
		echo -e "\n # proftpd 서비스"																>>	$RESULT_FILE 2>&1
		echo " - TCPAccessFiles 확인"																>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/proftpd.conf" "TCPAccessFiles"									>>	$RESULT_FILE 2>&1
		echo "TCPAccessFiles 설정 중인 경우 U-23 확인"												>>	$RESULT_FILE 2>&1
		echo -e "\n - /etc/proftpd.conf 내 Limit LOGIN 확인"										>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/proftpd.conf" "Limit LOGIN"										>>	$RESULT_FILE 2>&1
		echo "<Limit LOGIN> 설정 중인 경우 하단에 출력되어 있는 proftpd.conf 전체 내용 확인"						>>	$RESULT_FILE 2>&1
		echo -e "\n - /usr/local/etc/proftpd.conf 내 Limit LOGIN 확인"								>>	$RESULT_FILE 2>&1
		do_find_parameter "/usr/local/etc/proftpd.conf" "Limit LOGIN"							>>	$RESULT_FILE 2>&1
		echo "<Limit LOGIN> 설정 중인 경우 하단에 출력되어 있는 proftpd.conf 전체 내용 확인"						>>	$RESULT_FILE 2>&1
	fi
else
	echo "o FTP 서비스 미구동 중으로 평가 해당없음"															>>	$RESULT_FILE 2>&1
fi

echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "20"
echo ">> /etc/shadow 파일"																		>>	$RESULT_FILE 2>&1
for user in $(egrep -v "/false|/nologin|/sync|/shutdown|/halt" /etc/passwd | cut -f1 -d:); do cat /etc/shadow | grep $user; done > shadowtmp.txt
cat shadowtmp.txt																				>>	$RESULT_FILE 2>&1
if [ -z `cat shadowtmp.txt | awk -F":" '$2=="!!" { printf $1}'` ]; then
	echo "o 비밀번호가 미설정된 계정 없어 양호"	>>	$RESULT_FILE 2>&1
fi
echo -e "\n>> NP(no passwd) 확인"																	>>	$RESULT_FILE 2>&1
for user in $(egrep -v "/false|/nologin|/sync|/shutdown|/halt" /etc/passwd | cut -f1 -d:); do passwd -S $user; done	>>	$RESULT_FILE 2>&1
rm -f shadowtmp.txt
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "21"
echo ">> /etc/hosts.equiv 파일 확인"															>>	$RESULT_FILE 2>&1
if [ -f /etc/hosts.equiv ]; then
	echo "o /etc/hosts.equiv 파일 존재"															>>	$RESULT_FILE 2>&1
	ls -al /etc/hosts.equiv																		>>	$RESULT_FILE 2>&1
	echo " "																					>>	$RESULT_FILE 2>&1
	cat /etc/hosts.equiv																		>>	$RESULT_FILE 2>&1
else
	echo "o /etc/hosts.equiv 파일 존재하지 않음"														>>	$RESULT_FILE 2>&1
fi
echo " "																						>>	$RESULT_FILE 2>&1
echo ">> rhost 설정"																				>>	$RESULT_FILE 2>&1
for dir in $HOME_DIRS
do
	if [ -f $dir/.rhosts ]; then
		echo "o $dir/.rhosts 권한 설정"															>>	$RESULT_FILE 2>&1
		ls -al $dir/.rhosts																		>>	$RESULT_FILE 2>&1
		echo " "																				>>	$RESULT_FILE 2>&1
		cat $dir/.rhosts																		>>	$RESULT_FILE 2>&1
	else
		echo "o $dir/.rhosts 파일 존재하지 않음"														>>	$RESULT_FILE 2>&1
	fi
done
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "22"
echo ">> SSH"																					>>	$RESULT_FILE 2>&1
if [ `ch_service "ssh" "NA" "ssh-agent"` == "check" ]; then
	echo " "																					>>	$RESULT_FILE 2>&1
	if [ -f /etc/ssh/sshd_config ]; then
		cat /etc/ssh/sshd_config | grep -v "^#" | grep -i "PermitRootLogin"	> Permit.txt
		if [ `cat Permit.txt | wc -l` -eq 1 ]; then
			if [ `cat Permit.txt | awk '{print $2}' | tr '[A-Z]' '[a-z]'` == "no" ]; then
				echo "ㅇ SSH 사용 중이며, root 계정 원격 접속 제한 중"										>>	$RESULT_FILE 2>&1
			else
				echo "ㅇ SSH 사용 중이며, root 계정 원격 접속 허용 중"										>>	$RESULT_FILE 2>&1
			fi
		elif [ `cat Permit.txt | wc -l` -gt 1 ]; then
			if [ `cat Permit.txt | head -1 | awk '{print $2}' | tr '[A-Z]' '[a-z]'` == "no" ]; then
				echo "ㅇ SSH 사용 중이며, root 계정 원격 접속 제한 중 (permitrootlogin no 값이 상단에 설정되어 있음)"	>>	$RESULT_FILE 2>&1
			else
				echo "ㅇ SSH 사용 중이며, root 계정 원격 접속 허용 중 (permitrootlogin yes 값이 상단에 설정되어 있음)"	>>	$RESULT_FILE 2>&1
			fi
		else
			if [ $infra == "R" ]; then
				echo "ㅇ SSH 사용 중이며, root 계정 원격 접속 허용 중 (기본값: 허용)"							>>	$RESULT_FILE 2>&1
			else
				echo "ㅇ SSH 사용 중이며, root 계정 원격 접속 제한 중 (기본값: 제한)"							>>	$RESULT_FILE 2>&1
			fi
		fi
		cat /etc/ssh/sshd_config | grep -i "PermitRootLogin"									>>	$RESULT_FILE 2>&1
		rm -f Permit.txt
	else
		echo "o /etc/ssh/sshd_config 존재하지 않음"													>>	$RESULT_FILE 2>&1
		sudo find /etc /usr /var -type f -name "sshd_config" -exec sh -c "ls -al {}; cat {};" \;	>>	$RESULT_FILE 2>&1
	fi
else
	"o SSH 서비스 미구동 중"																			>>	$RESULT_FILE 2>&1
fi
echo -e "\n>> Telnet"																			>>	$RESULT_FILE 2>&1
if [ `ch_service "telnet" "23"` == "check" ]; then
	if [ -f /etc/pam.d/login ]; then
		cat /etc/pam.d/login | grep -i "pts"	> pts.txt
		if [ `cat pts.txt | wc -l` -eq 0 ]; then
			echo "ㅇ /etc/pam.d/login 파일 내 pts 설정 존재하지 않음"										>>	$RESULT_FILE 2>&1
		else
			echo "ㅇ /etc/pam.d/login 파일 내 pts 설정 존재함"											>>	$RESULT_FILE 2>&1
		fi
		echo " "																				>>	$RESULT_FILE 2>&1
		cat /etc/pam.d/login																	>>	$RESULT_FILE 2>&1
	else
		echo "ㅇ /etc/pam.d/login 파일 존재하지 않음"													>>	$RESULT_FILE 2>&1
	fi
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "23"
echo ">> /etc/hosts.allow 권한 설정"																>>	$RESULT_FILE 2>&1
if [ -f /etc/hosts.allow ]; then
	if [ `cat /etc/hosts.allow | grep -v "^#" | wc -w` -eq 0 ]; then
		echo "ㅇ /etc/hosts.allow 파일 내 특정 접속 IP 및 포트 허용 설정 존재하지 않음"							>>	$RESULT_FILE 2>&1
	else
		echo "ㅇ /etc/hosts.allow 파일 내 특정 접속 IP 및 포트 허용 설정 존재"								>>	$RESULT_FILE 2>&1
	fi
	cat /etc/hosts.allow 																		>>	$RESULT_FILE 2>&1
else
	echo "ㅇ /etc/hosts.allow 파일 존재하지 않음"														>>	$RESULT_FILE 2>&1
fi
echo " "																						>>	$RESULT_FILE 2>&1
echo ">> /etc/hosts.deny 권한 설정"																>>	$RESULT_FILE 2>&1
if [ -f /etc/hosts.deny ]; then
	if [ `cat /etc/hosts.deny | grep -v "^#" | grep -i all:all | wc -l` -eq 0 ]; then
		echo "ㅇ /etc/hosts.allow 파일 내 Deny All 설정 존재하지 않음"									>>	$RESULT_FILE 2>&1
	else
		echo "ㅇ /etc/hosts.allow 파일 내 Deny All 설정 존재"											>>	$RESULT_FILE 2>&1
	fi
	cat /etc/hosts.deny																			>>	$RESULT_FILE 2>&1
else
	echo "ㅇ /etc/hosts.deny 파일 존재하지 않음"														>>	$RESULT_FILE 2>&1
fi
	echo -e "\n>> iptables "																	>>	$RESULT_FILE 2>&1
	if [ $infra == "R" ]; then
		rpm -qa | grep iptables																	>>	$RESULT_FILE 2>&1
		echo " "																				>>	$RESULT_FILE 2>&1
		iptables -nL -v --line-numbers															>>	$RESULT_FILE 2>&1
	else
		dpkg -l | grep -i iptables																>>	$RESULT_FILE 2>&1
	fi
	if [ $infra == R ]; then
		echo -e "\n>> firewalld"																>>	$RESULT_FILE 2>&1
		systemctl status firewalld																>>	$RESULT_FILE 2>&1
		rpm -qa | grep firewalld																>>	$RESULT_FILE 2>&1
		iptables -nL -v --line-numbers   														>>	$RESULT_FILE 2>&1
	else
		echo -e "\n>> Ubuntu UFW"																>>	$RESULT_FILE 2>&1
		dpkg -l | egrep -i firewall																>>	$RESULT_FILE 2>&1
		echo " "																				>>	$RESULT_FILE 2>&1
		echo "  - ufw status verbose 명령 실행"													>>	$RESULT_FILE 2>&1
		ufw status verbose																		>>	$RESULT_FILE 2>&1
		echo " "																				>>	$RESULT_FILE 2>&1
		echo "  - ufw show raw 명령 실행"															>>	$RESULT_FILE 2>&1
		ufw show raw																			>>	$RESULT_FILE 2>&1
	fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "24"
do_find_parameter "/etc/csh.login" "autologinout"												>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
do_find_parameter "/etc/profile" "TMOUT"														>>	$RESULT_FILE 2>&1
echo -e "\n>> env (환경변수) 내 TMOUT 설정 확인"														>>	$RESULT_FILE 2>&1
env | grep -i "tmout"																			>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "25"
if [ `ch_service "$AUTO_SERVICE" "NA"` == pass ]; then
	echo "o automountd 서비스 미구동 중으로 양호"														>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "26"
echo ">> tftp"																					>>	$RESULT_FILE 2>&1
ch_service "tftp" "69" >/dev/null
echo -e "\n>> talk"																				>>	$RESULT_FILE 2>&1
ch_service "talk" "517" >/dev/null
echo -e "\n>> ntalk"																			>>	$RESULT_FILE 2>&1
ch_service "ntalk" "518" >/dev/null
echo -e "\n>> finger"																			>>	$RESULT_FILE 2>&1
ch_service "finger" "79" >/dev/null
echo -e "\n>> rexec"																			>>	$RESULT_FILE 2>&1
ch_service "rexec" "512" >/dev/null
echo -e "\n>> rlogin"																			>>	$RESULT_FILE 2>&1
ch_service "rlogin" "513" >/dev/null
echo -e "\n>> rsh"																				>>	$RESULT_FILE 2>&1
ch_service "rsh" "514" >/dev/null
echo -e "\n>> echo"																				>>	$RESULT_FILE 2>&1
ch_service "echo" "7" >/dev/null
echo -e "\n>> discard"																			>>	$RESULT_FILE 2>&1
ch_service "discard" "9" >/dev/null
echo -e "\n>> daytime"																			>>	$RESULT_FILE 2>&1
ch_service "daytime" "13" >/dev/null
echo -e "\n>> chargen"																			>>	$RESULT_FILE 2>&1
ch_service "chargen" "19" >/dev/null
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "27"
if [ `ch_service "ftp" "NA"` == check ]; then
	if [ `ps -ef | grep -i "ftp" | egrep -v -i "/sftp|grep" | wc -l` -eq 0 ]; then
		echo "ㅇ SFTP 사용 중으로 양호"																>>	$RESULT_FILE 2>&1
	else
		if [ -f /etc/inetd.conf ]; then
			echo "▷ /etc/inetd.conf 파일 내 ftp 서비스 라인 확인"										>>	$RESULT_FILE 2>&1
			if [ `cat /etc/inetd.conf | grep -i "ftpd" | wc -l` -ne 0 ]; then
				cat /etc/inetd.conf | grep -i "ftpd"											>>	$RESULT_FILE 2>&1
			else echo " ftp 서비스 설정 없음"															>>	$RESULT_FILE 2>&1
			fi
		fi
	fi
else
	echo "o FTP 서비스 미구동 중으로 양호"																>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "28" # 웹 서비스 디렉터리 리스팅 방지 설정 미흡
if [ $APACHE_CHECK = "OFF" ] && [ $NGINX_CHECK = "OFF" ] ; then
	echo "o 웹 서비스(Apache, Nginx) 미구동 중이므로 평가 해당없음"											>>	$RESULT_FILE 2>&1
else
	if [ $APACHE_CHECK = "OFF" ]; then
		echo "o Apache 서비스 비활성화"																>>	$RESULT_FILE 2>&1
	else
		echo "o Apache 서비스 활성화"																>>	$RESULT_FILE 2>&1
		echo ">> $ACONF 파일 내 Indexes 설정 확인"													>>	$RESULT_FILE 2>&1
		web_option "apache" "$ACONF" "Indexes"
		echo -e "\n>> $ACONF 파일 내 Include 된 파일 확인"											>>	$RESULT_FILE 2>&1
		conf=(`cat $ACONF | grep -i "^include" | awk '{print$2}'`)
		for ((i=0;i<${#conf[@]};i++)); do
			if [ -f ${conf[$i]} ]; then
				ls -alL ${conf[$i]} | awk '{print $NF}'	>>	apache_extra.txt 2>&1
			else
				ls -alL $AHOME/${conf[$i]} | awk '{print $NF}'	>>	apache_extra.txt 2>&1
			fi
		done
		for extra in `cat apache_extra.txt`; do
			echo " ==> $extra <=="																>>	$RESULT_FILE 2>&1
			web_option "apache" "$extra" "Indexes"
		done
	fi
	if [ $NGINX_CHECK = "OFF" ]; then
		echo -e "\no Nginx 서비스 비활성화"															>>	$RESULT_FILE 2>&1
	else
		echo -e "\no Nginx 서비스 활성화"															>>	$RESULT_FILE 2>&1
		echo ">> $nxconf 파일 확인"																>>	$RESULT_FILE 2>&1
		if [ `grep -n -i autoindex $nxconf | grep -v '#' | wc -l` -eq 0 ]; then
			echo " - autoindex 설정 미존재"															>>	$RESULT_FILE 2>&1
		else
			grep -n -i autoindex $nxconf | grep -v '#'											>>	$RESULT_FILE 2>&1
		fi
	fi
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "29" #웹 서비스 상위 디렉터리 접근 제한 설정 미흡
if [ $APACHE_CHECK = "OFF" ] && [ $NGINX_CHECK = "OFF" ] ; then
	echo "o 웹 서비스(Apache, Nginx) 미구동 중이므로 평가 해당없음"											>>	$RESULT_FILE 2>&1
else
	if [ $APACHE_CHECK = "OFF" ]; then
		echo "o Apache 서비스 비활성화"																>>	$RESULT_FILE 2>&1
	else
		echo ">> Apache 버전 확인"																	>>	$RESULT_FILE 2>&1
		$APROC -V																				>>	$RESULT_FILE 2>&1
		if [ $infra == R ]; then 
			httpd -V																				>>	$RESULT_FILE 2>&1
			$AHOME/bin/httpd -V																		>>	$RESULT_FILE 2>&1
		fi
		if [ $infra == D ]; then dpkg -l | grep -i "apache"; else rpm -qa httpd; fi				>>	$RESULT_FILE 2>&1
	fi
	if [ $NGINX_CHECK = "OFF" ]; then
		echo -e "\no Nginx 서비스 비활성화"															>>	$RESULT_FILE 2>&1
	else
		echo -e "\no Nginx 서비스 활성화"															>>	$RESULT_FILE 2>&1
		web_option "nginx" "$nxconf" "NA"
		echo -e "\n>> $nxconf 파일 내 Include 된 파일 확인"											>>	$RESULT_FILE 2>&1
		conf=(`cat $nxconf | egrep -v "^#" | grep -i "include" | awk '{print$2}' | sed 's/.$//'` )
		for ((i=0;i<${#conf[@]};i++)); do
			ls -alL ${conf[$i]} | awk '{print $NF}'	>>	nginx_extra.txt 2>&1
		done
		for extra in `cat nginx_extra.txt`; do
			echo " ==> $extra <=="																>>	$RESULT_FILE 2>&1
			web_option "nginx" "$extra" "NA"
		done
	fi
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "30"
if [ $APACHE_CHECK = "OFF" ] && [ $NGINX_CHECK = "OFF" ] ; then
	echo "o 웹 서비스(Apache, Nginx) 미구동 중이므로 평가 해당없음"											>>	$RESULT_FILE 2>&1
else
	if [ $APACHE_CHECK = "OFF" ]; then
		echo "o Apache 서비스 비활성화"																>>	$RESULT_FILE 2>&1
	else
		echo "o Apache 서비스 활성화"																>>	$RESULT_FILE 2>&1
		echo ">> $AHOME 하위 기본 불필요 디렉터리"														>>	$RESULT_FILE 2>&1
		ls -al $AHOME | egrep -i 'manual|samples|docs|printenv|test-cgi|icons' | egrep "^d"		>>	$RESULT_FILE 2>&1
		echo -e "\n>> $AHOME 하위 백업파일 파일"														>>	$RESULT_FILE 2>&1
		find $AHOME -type f \( -name "*.bak" -o -name "*.backup" -o -name "*.org" -o -name "*.old" -o -name "*.zip" -o -name "*.tar" -o -name "*.tmp" -o -name "*.temp" \)	>>	$RESULT_FILE 2>&1
		echo -e "\n>> DocumentRoot 하위 백업파일 파일"												>>	$RESULT_FILE 2>&1
		AHDocR=$(cat $ACONF | grep -i DocumentRoot | grep -v '#' | awk -F'"' '{print $2}')		>>	$RESULT_FILE 2>&1
		find $AHDocR -type f \( -name "*.bak" -o -name "*.backup" -o -name "*.org" -o -name "*.old" -o -name "*.zip" -o -name "*.tar" -o -name "*.tmp" -o -name "*.temp" \)	>>	$RESULT_FILE 2>&1
	fi
	if [ $NGINX_CHECK = "OFF" ]; then
		echo -e "\no Nginx 서비스 비활성화"															>>	$RESULT_FILE 2>&1
	else
		echo -e "\no Nginx 서비스 활성화"															>>	$RESULT_FILE 2>&1
		echo ">> $nxdir 하위 기본 불필요 디렉터리"														>>	$RESULT_FILE 2>&1
		ls -al $nxdir | egrep -i 'manual|samples|docs|printenv|test-cgi|icons' | egrep "^d"		>>	$RESULT_FILE 2>&1
		echo -e "\n>> $nxdir 하위 백업파일 파일"														>>	$RESULT_FILE 2>&1
		find $nxdir -type f \( -name "*.bak" -o -name "*.backup" -o -name "*.org" -o -name "*.old" -o -name "*.zip" -o -name "*.tar" -o -name "*.tmp" -o -name "*.temp" \)	>>	$RESULT_FILE 2>&1
	fi
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "31" #웹 서비스 파일 업로드 및 다운로드 용량 제한 미설정
if [ $APACHE_CHECK = "OFF" ] && [ $NGINX_CHECK = "OFF" ] ; then
	echo "o 웹 서비스(Apache, Nginx) 미구동 중이므로 평가 해당없음"											>>	$RESULT_FILE 2>&1
else
	if [ $APACHE_CHECK = "OFF" ]; then
		echo "o Apache 서비스 비활성화"																>>	$RESULT_FILE 2>&1
	else
		echo "o Apache 서비스 활성화"																>>	$RESULT_FILE 2>&1
		echo ">> $ACONF 파일 내 LimitRequestBody 설정 확인"											>>	$RESULT_FILE 2>&1
		web_option "apache" "$ACONF" "LimitRequestBody"
		echo -e "\n>> $ACONF 파일 내 Include 된 파일 확인"												>>	$RESULT_FILE 2>&1
		for extra in `cat apache_extra.txt`; do
			echo " ==> $extra <=="																>>	$RESULT_FILE 2>&1
			web_option "apache" "$extra" "LimitRequestBody"
		done
	fi
	if [ $NGINX_CHECK = "OFF" ]; then
		echo -e "\no Nginx 서비스 비활성화"															>>	$RESULT_FILE 2>&1
	else
		echo -e "\no Nginx 서비스 활성화"															>>	$RESULT_FILE 2>&1
		echo ">> $nxconf 파일 확인"																>>	$RESULT_FILE 2>&1
		if [ `grep -n -i client_max_body_size $nxconf | grep -v '#' | wc -l` -gt 0 ]; then
			grep -n -i client_max_body_size $nxconf | grep -v '#'								>>	$RESULT_FILE 2>&1
		else
			echo " - client_max_body_size 설정 미존재"												>>	$RESULT_FILE 2>&1
		fi
	fi
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "32" #웹 서비스 프로세스 권한 제한 미비
if [ $APACHE_CHECK = "OFF" ] && [ $NGINX_CHECK = "OFF" ] ; then
	echo "o 웹 서비스(Apache, Nginx) 미구동 중이므로 평가 해당없음"											>>	$RESULT_FILE 2>&1
else
	if [ $APACHE_CHECK = "OFF" ]; then
		echo "o Apache 서비스 비활성화"																>>	$RESULT_FILE 2>&1
	else
		echo "o Apache 서비스 활성화"																>>	$RESULT_FILE 2>&1
		echo ">> Apache 데몬 구동 계정 확인"															>>	$RESULT_FILE 2>&1
		ps -ef | grep httpd | grep -v "lighttp" | grep -v "grep"								>>	$RESULT_FILE 2>&1
		echo -e "\n>> $ACONF 파일 내 user/group 설정 "													>>	$RESULT_FILE 2>&1
		egrep -n -i "user|group" $ACONF | grep -v '^\#'											>>	$RESULT_FILE 2>&1
	fi
	if [ $NGINX_CHECK = "OFF" ]; then
		echo -e "\no Nginx 서비스 비활성화"															>>	$RESULT_FILE 2>&1
	else
		echo -e "\no Nginx 서비스 활성화"															>>	$RESULT_FILE 2>&1
		echo ">> Nginx 데몬 구동 계정 확인"															>>	$RESULT_FILE 2>&1
		ps -ef | grep nginx | grep -v "grep"													>>	$RESULT_FILE 2>&1
	fi
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "33" #웹 서비스 경로 설정 미흡
if [ $APACHE_CHECK = "OFF" ] && [ $NGINX_CHECK = "OFF" ] ; then
	echo "o 웹 서비스(Apache, Nginx) 미구동 중이므로 평가 해당없음"											>>	$RESULT_FILE 2>&1
else
	if [ $APACHE_CHECK = "OFF" ]; then
		echo "o Apache 서비스 비활성화"																>>	$RESULT_FILE 2>&1
	else
		echo "o Apache 서비스 활성화"																>>	$RESULT_FILE 2>&1
		echo ">> $ACONF 내 DocumentRoot 확인"														>>	$RESULT_FILE 2>&1
		web_option "apache" "$ACONF" "DocumentRoot"
		echo -e "\n>> $ACONF 파일 내 Include 된 파일 확인"												>>	$RESULT_FILE 2>&1
		for extra in `cat apache_extra.txt`; do
			echo " ==> $extra <=="																>>	$RESULT_FILE 2>&1
			web_option "apache" "$extra" "DocumentRoot"
		done
	fi
	if [ $NGINX_CHECK = "OFF" ]; then
		echo -e "\no Nginx 서비스 비활성화"															>>	$RESULT_FILE 2>&1
	else
		echo -e "\no Nginx 서비스 활성화"															>>	$RESULT_FILE 2>&1
		echo ">> $nxconf 파일 확인"																>>	$RESULT_FILE 2>&1
		if [ `grep -n -i root $nxconf | grep -v '#' | wc -l` -eq 0 ]; then
			echo " - root 설정 없음"																>>	$RESULT_FILE 2>&1
		else
			grep -n -i root $nxconf | grep -v '#'												>>	$RESULT_FILE 2>&1
		fi
	fi
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "34" #웹 서비스 경로 내 불필요한 링크 파일 존재
if [ $APACHE_CHECK = "OFF" ] && [ $NGINX_CHECK = "OFF" ] ; then
	echo "o 웹 서비스(Apache, Nginx) 미구동 중이므로 평가 해당없음"											>>	$RESULT_FILE 2>&1
else
	if [ $APACHE_CHECK = "OFF" ]; then
		echo "o Apache 서비스 비활성화"																>>	$RESULT_FILE 2>&1
	else
		echo "o Apache 서비스 활성화"																>>	$RESULT_FILE 2>&1
		echo ">> $ACONF 파일 내 FollowSymLinks 설정 확인"												>>	$RESULT_FILE 2>&1
		web_option "apache" "$ACONF" "FollowSymLinks"
		echo -e "\n>> $ACONF 파일 내 Include 된 파일 확인"												>>	$RESULT_FILE 2>&1
		for extra in `cat apache_extra.txt`; do
			echo " ==> $extra <=="																>>	$RESULT_FILE 2>&1
			web_option "apache" "$extra" "FollowSymLinks"
		done
	fi
	if [ $NGINX_CHECK = "OFF" ]; then
		echo -e "\no Nginx 서비스 비활성화"															>>	$RESULT_FILE 2>&1
	else
		echo -e "\no Nginx 서비스 활성화"															>>	$RESULT_FILE 2>&1
		echo ">> $nxconf 파일 확인"																>>	$RESULT_FILE 2>&1
		if [ `grep -n -i disable_symlinks $nxconf | grep -v '#' | wc -l` -eq 0 ]; then
			echo " - disable_symlinks 설정 없음"													>>	$RESULT_FILE 2>&1
		else
			grep -n -i disable_symlinks $nxconf | grep -v '#'									>>	$RESULT_FILE 2>&1
		fi
	fi
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "35" # 불필요한 웹 서비스 실행
if [ $APACHE_CHECK = "OFF" ] && [ $NGINX_CHECK = "OFF" ] ; then
	echo " 웹 서비스(Apache, Nginx) 미구동 중이므로 양호"													>>	$RESULT_FILE 2>&1
else
	if [ $APACHE_CHECK = "OFF" ]; then
		echo "o Apache 서비스 비활성화"																>>	$RESULT_FILE 2>&1
	else
		echo "o Apache 서비스 활성화"																>>	$RESULT_FILE 2>&1
		ch_service "httpd|wsm|hth|htl" "NA" >/dev/null
	fi
	if [ $NGINX_CHECK = "OFF" ]; then
		echo -e "\no Nginx 서비스 비활성화"															>>	$RESULT_FILE 2>&1
	else
		echo -e "\no Nginx 서비스 활성화"															>>	$RESULT_FILE 2>&1
		ch_service "nginx" "NA" >/dev/null
	fi
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "36" # 웹 서비스 기본 계정(아이디 또는 비밀번호) 미변경
ch=`ch_service "tomcat|java|bootstrap" "NA"`
if [ $ch == check ]; then
	TOMCAT_PATH=`ps -ef | grep "tomcat" | grep -v "grep" | awk -F"catalina.home=" '{print $2}'| awk -F' -D' '{print $1}'`
	echo ">> Apache Tomcat 계정 현황"																>>	$RESULT_FILE 2>&1
	if [ -f $TOMCAT_PATH/conf/tomcat-users.xml ]; then
		cat $TOMCAT_PATH/conf/tomcat-users.xml													>>	$RESULT_FILE 2>&1
	else
		echo "#톰캣 홈디렉터리 확인하여 tomcat-users.xml 파일 수동 점검"										>>	$RESULT_FILE 2>&1
		echo ">> tomcat-users.xml"																>>	$RESULT_FILE 2>&1
		find /etc /usr /var -type f -name "tomcat-users.xml" -exec sh -c "ls -al {}; cat {} | grep -v '^\#';" \;  >>	$RESULT_FILE 2>&1
	fi
else
	echo "o Apache Tomcat 미구동 중으로 평가 해당없음"													>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "37" #DNS 서비스 정보 노출
ch=`ch_service "named" "53" "dnsmasq|systemd-hostnamed.service"`
if [ $ch == check ]; then
	echo ">> version 옵션 확인"																	>>	$RESULT_FILE 2>&1
	do_find_parameter "/etc/named.conf" "version"												>>	$RESULT_FILE 2>&1
else
	echo "o DNS 서버 미구동 중으로 평가 해당없음"															>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "38"
ch=`ch_service "named" "53" "dnsmasq|systemd-hostnamed.service"`
if [ $ch == check ]; then
	echo -e "\n>> recursion 옵션 확인"																	>>	$RESULT_FILE 2>&1
	do_find_parameter "/etc/named.conf" "recursion no"											>>	$RESULT_FILE 2>&1
	if [ $? -eq 1 ]; then
		echo -e "\n>> Recursion 서비스 ACL 설정 현황"													>>	$RESULT_FILE 2>&1
		echo " # Recursion 기능 현황"																>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/named.conf" "recursion"											>>	$RESULT_FILE 2>&1
		echo -e"\n # allow-recursion 현황"														>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/named.conf" "allow-recursion"									>>	$RESULT_FILE 2>&1
		echo -e"\n # Blackhole 현황"																>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/named.conf" "blackhole|acl"										>>	$RESULT_FILE 2>&1
	fi
else
	echo "o DNS 서버 미구동 중으로 평가 해당없음"															>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "39"
ch=`ch_service "named" "53" "dnsmasq|systemd-hostnamed.service"`
if [ $ch == check ]; then
	echo -e "\n>> >> 질의를 이용한 확인 확인"																>>	$RESULT_FILE 2>&1
	$dig @localhost +short porttest.dns-oarc.net TXT											>>	$RESULT_FILE 2>&1
	echo -e "\n>> >> DNS 버전 확인"																		>>	$RESULT_FILE 2>&1
	named -v																					>>	$RESULT_FILE 2>&1
else
	echo "o DNS 서버 미구동 중으로 평가 해당없음"															>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "40"
ch=`ch_service "named" "53" "dnsmasq|systemd-hostnamed.service"`
if [ $ch == check ]; then
	echo -e "\n>> /etc/named.conf의 allow-transfer 확인"												>>	$RESULT_FILE 2>&1
	do_find_parameter "/etc/named.conf" "allow-transfer"										>>	$RESULT_FILE 2>&1
	echo -e "\n>> /etc/named.boot의 \xfrnets 확인"													>>	$RESULT_FILE 2>&1
	do_find_parameter "/etc/named.conf" "\xfrnets"												>>	$RESULT_FILE 2>&1
else
	echo "o DNS 서버 미구동 중으로 평가 해당없음"															>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "41"
echo ">> 패스워드 암호화 사용여부 확인"																	>>	$RESULT_FILE 2>&1
if [ `cat /etc/passwd | grep "^root" | grep ":x:" | grep -v operator | wc -l` -gt 0 ]
then
    echo "ㅇ 쉐도우 패스워드 사용 중 "																	>>	$RESULT_FILE 2>&1
else
    echo "ㅇ 쉐도우 패스워드 미사용 중 "																	>>	$RESULT_FILE 2>&1
fi
echo -e "\n>> /etc/passwd 파일 "																	>>	$RESULT_FILE 2>&1
cat /etc/passwd | grep "^root" | grep ":x:" | grep -v operator									>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "42"
echo ">> root 그룹 확인"																			>>	$RESULT_FILE 2>&1
echo -e "\n     Group     |      Members"														>>	$RESULT_FILE 2>&1
awk -F: '$3==0 { printf "%-15s| %-20s\n", $1, $4 }' "/etc/group"								>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "43"
echo ">> /var/spool/cron/crontab/* 권한 확인"														>>	$RESULT_FILE 2>&1
ls -alLd /var/spool/cron/crontab/*																>>	$RESULT_FILE 2>&1
echo -e "\n>> /etc/at.allow 권한 확인"																>>	$RESULT_FILE 2>&1
ls -alLd /etc/at.allow																			>>	$RESULT_FILE 2>&1
echo -e "\n>> /etc/at.deny 권한 확인"																>>	$RESULT_FILE 2>&1
ls -alLd /etc/at.deny																			>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "44"
echo ">> 시스템 주요 디렉터리 권한 확인"																	>>	$RESULT_FILE 2>&1
ls -alLd /usr /bin /sbin /etc /var																>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "45" #시스템 스타트업 스크립트 권한 설정 미흡
echo ">> /etc/rc* 권한 확인"																		>>	$RESULT_FILE 2>&1
ls -alRL /etc/rc*																				>>	$RESULT_FILE 2>&1
echo -e "\n>> /sbin/rc* 권한 확인"																	>>	$RESULT_FILE 2>&1
ls -alRL /sbin/rc*																				>>	$RESULT_FILE 2>&1
echo -e "\n>> /etc/init* 권한 확인"																>>	$RESULT_FILE 2>&1
ls -alRL /etc/init*																				>>	$RESULT_FILE 2>&1
echo -e "\n>> /sbin/init* 권한 확인"																>>	$RESULT_FILE 2>&1
ls -alRL /sbin/init*																			>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "46" #시스템 주요 파일 권한 설정 미흡
echo ">> /etc/passwd 권한 확인"																	>>	$RESULT_FILE 2>&1
ls -alL /etc/passwd																				>>	$RESULT_FILE 2>&1
echo -e "\n>> /etc/shadow 권한 확인"															>>	$RESULT_FILE 2>&1
ls -alL /etc/shadow																				>>	$RESULT_FILE 2>&1
echo -e "\n>> /etc/hosts 권한 확인"																>>	$RESULT_FILE 2>&1
ls -alL /etc/hosts																				>>	$RESULT_FILE 2>&1
echo -e "\n>> /etc/(x)inetd.conf 권한 확인"														>>	$RESULT_FILE 2>&1
ls -alL /etc/inetd.conf																			>>	$RESULT_FILE 2>&1
ls -alL /etc/xinetd.conf																		>>	$RESULT_FILE 2>&1
echo -e "\n>> /etc/syslogd.conf 권한 확인"														>>	$RESULT_FILE 2>&1
ls -alL /etc/syslogd.conf																		>>	$RESULT_FILE 2>&1
echo -e "\n>> /etc/services 권한 확인"															>>	$RESULT_FILE 2>&1
ls -alL /etc/services																			>>	$RESULT_FILE 2>&1
echo -e "\n>> /etc/hosts.lpd 권한 확인"															>>	$RESULT_FILE 2>&1
ls -alL /etc/hosts.lpd																		    >>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "47" #C 컴파일러 존재 및 권한 설정 미흡
echo ">> C 컴파일러 확인"																			>>	$RESULT_FILE 2>&1
if [ `find /etc /usr -type f -name "gcc" | wc -l` -eq 0 ]; then
	echo "o gcc 파일 존재하지 않음"																	>>	$RESULT_FILE 2>&1
else
	find /etc /usr -type f -name "gcc" -exec ls -al {} \;										>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "48"
echo ">> /sbin 디렉터리 하위 SUID, SGID bit가 설정된 파일 확인"											>>	$RESULT_FILE 2>&1
find /sbin -user root -type f \( -perm -04000 -o -perm -02000 \) -exec ls -al {} \;				>>	$RESULT_FILE 2>&1
echo -e "\n>> /bin 디렉터리 하위 SUID, SGID bit가 설정된 파일 확인"										>>	$RESULT_FILE 2>&1
find /usr -user root -type f \( -perm -04000 -o -perm -02000 \) -exec ls -al {} \;				>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "49"
echo ">> 사용자의 홈디렉터리 소유자 확인"																	>>	$RESULT_FILE 2>&1
for DIR in $HOME_DIRS
do
	ls -dalL $DIR																				>>	$RESULT_FILE 2>&1
done

echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "50"
num=1; dir="/etc /bin /usr /var /tmp /home"
for DIR in $dir
do
	echo ">> "$num". "$DIR""																	>>	$RESULT_FILE 2>&1
	if [ `find $DIR -type f -perm -2 | wc -l` -eq 0 ]
	then
		echo "o $DIR 에 world writable 파일 존재하지 않음" 											>>	$RESULT_FILE 2>&1
	else
		find $DIR -type f -perm -2 -exec ls -al {} \; 											>>	$RESULT_FILE 2>&1
	fi
	echo " "																					>>	$RESULT_FILE 2>&1
	num=`expr $num + 1`
done
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "51" #Crontab 참조파일 권한 설정 미흡
echo ">> Crontab 참조파일 권한 확인"																	>>	$RESULT_FILE 2>&1
if [ -d /var/spool/cron/crontabs/ ]
then
	REFLIST=`ls -al /var/spool/cron/crontabs/ | egrep -i ".sh|.pl" | awk '{print $6}' `
	if [ `ls /var/spool/cron/crontabs/ | egrep -i ".sh|.pl" | wc -l` -eq 0 ]; then
		ls -alR /var/spool/cron/crontabs														>>	$RESULT_FILE 2>&1
		echo "/var/spool/cron/crontabs 하위 파일 내 참조파일(.sh, .pl) 존재하지 않음"						>>	$RESULT_FILE 2>&1
	else
		for file in $REFLIST
		do
			if [ -f $file ]
			then
				echo " $ ls -alL $file | awk '{print $1 " : " $NF}'"							>>	$RESULT_FILE 2>&1
				ls -alL $file																	>>	$RESULT_FILE 2>&1
				ls -alL $file | awk '{print $1 " : " $NF}'										>>	$RESULT_FILE 2>&1
			fi  
		done
	fi
else
	echo "o /var/spool/cron/crontabs 디렉터리가 존재하지 않음"											>>	$RESULT_FILE 2>&1
fi 
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "52"
num=1
for DIR in $dir
do
	echo ">> "$num". "$DIR""																	>>	$RESULT_FILE 2>&1
	if [ `find $DIR -nouser -nogroup | wc -l` -eq 0 ]; then
		echo "o $DIR 에 불분명한 파일 및 그룹 소유자 존재하지 않음"											>>	$RESULT_FILE 2>&1
	else
		find $DIR -type f \( -nouser -o -nogroup \) -exec ls -al {} \;							>>	$RESULT_FILE 2>&1
		check=`expr $check + 1`
	fi
	echo " "																					>>	$RESULT_FILE 2>&1
	num=`expr $num + 1`
done
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "53"
echo ">> /etc/profile 권한 확인"																	>>	$RESULT_FILE 2>&1
ls -al /etc/profile																				>>	$RESULT_FILE 2>&1
echo -e "\n>> 사용자 환경파일 권한 확인"																	>>	$RESULT_FILE 2>&1
for DIR in $HOME_DIRS
do
	for UENV_FILE in $USER_ENV_FILES
	do
		UENV_FILES=$DIR/$UENV_FILE
		if [ -f $UENV_FILES ]; then
			ls -alL $UENV_FILES																	>>	$RESULT_FILE 2>&1
		fi
	done
done
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "54"
for log in $LOG_FILE
do
	if [ -f $log ]; then
		echo ">> $log 파일 권한 확인"																>>	$RESULT_FILE 2>&1
		ls -alL $log																			>>	$RESULT_FILE 2>&1
		echo " "																				>>	$RESULT_FILE 2>&1
	fi
done
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "55" #시스템 주요 이벤트 로그 설정 미흡
echo ">> /etc/syslog.conf 파일"																	>>	$RESULT_FILE 2>&1
if [ -f /etc/syslog.conf ]; then
	cat /etc/syslog.conf																		>>	$RESULT_FILE 2>&1
else
	echo "ㅇ /etc/syslog.conf 파일 존재하지 않음"														>>	$RESULT_FILE 2>&1
fi
echo -e "\n>> /etc/rsyslog.conf 파일"															>>	$RESULT_FILE 2>&1
if [ -f /etc/rsyslog.conf ]; then
	cat /etc/rsyslog.conf																		>>	$RESULT_FILE 2>&1
	grep -i "^\$include" /etc/rsyslog.conf | awk '{print $2}'	>>	include.txt
	echo " "																					>>	$RESULT_FILE 2>&1
	if [ `cat include.txt | wc -l` -gt 0 ]; then
		echo "ㅇ InCludeconfig 파일 확인"															>>	$RESULT_FILE 2>&1
		for r_file in `cat include.txt`; do
			ls -al $r_file																		>>	$RESULT_FILE 2>&1
			cat $r_file | egrep -v "^#|^$"														>>	$RESULT_FILE 2>&1
			echo " "																			>>	$RESULT_FILE 2>&1
		done
	else
		"o InCludeconfig 에 해당하는 파일이 없습니다."													>>	$RESULT_FILE 2>&1
	fi
	rm -f include.txt
else
	echo "ㅇ /etc/rsyslog.conf 파일 존재하지 않음"													>>	$RESULT_FILE 2>&1    
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "56" #Cron 서비스 로깅 미설정
echo ">> /etc/syslog.conf 파일 - cron 로그"														>>	$RESULT_FILE 2>&1
if [ -f /etc/syslog.conf ]; then
	echo "U-55 참고"																				>>	$RESULT_FILE 2>&1
else
	echo "ㅇ /etc/syslog.conf 파일 존재하지 않음"														>>	$RESULT_FILE 2>&1
fi
echo -e "\n>> /etc/rsyslog.conf 파일 - cron 로그"													>>	$RESULT_FILE 2>&1
if [ -f /etc/rsyslog.conf ]; then
	echo "U-55 참고"																				>>	$RESULT_FILE 2>&1
else
	echo "ㅇ /etc/rsyslog.conf 파일 존재하지 않음"														>>	$RESULT_FILE 2>&1    
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "57"
echo ">> 인터뷰(로그기록에 대해 정기적 검토, 분석, 그에 대한 리포트 작성 및 보고등의 조치 여부) "							>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "58"
echo ">> PATH 환경변수 확인"																			>>	$RESULT_FILE 2>&1
echo $PATH																						>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "59" #UMASK 설정 미흡
if [ $infra == D ]; then
	echo ">> pam.d 확인 - common-session"															>>	$RESULT_FILE 2>&1
	cat /etc/pam.d/common-session | grep -v "^#" | grep -A 2 -B 2 -i "umask"					>>	$RESULT_FILE 2>&1
	cat /etc/pam.d/common-session-noninteractive | grep -v "^#" | grep -A 2 -B 2 -i "umask"		>>	$RESULT_FILE 2>&1
	echo -e "\n>> /etc/bash.bashrc 확인"															>>	$RESULT_FILE 2>&1
	cat /etc/bash.bashrc | grep -A 2 -B 2 -i "umask"											>>	$RESULT_FILE 2>&1
	echo " "																					>>	$RESULT_FILE 2>&1
fi
echo ">> /etc/login.defs 확인"																	>>	$RESULT_FILE 2>&1
(cat /etc/login.defs | egrep -i "UMASK|USERGROUPS_ENAB" || echo "ㅇ /etc/login.defs 파일 내 UMASK 설정이 존재하지 않음")	>>	$RESULT_FILE 2>&1
echo -e "\n>> /etc/profile 확인"																	>>	$RESULT_FILE 2>&1
cat /etc/profile | grep -A 2 -B 2 -i "umask"													>>	$RESULT_FILE 2>&1
if [ -f /etc/bashrc ]; then
	echo -e "\n>> /etc/bashrc 확인"																	>>	$RESULT_FILE 2>&1
	cat /etc/bashrc | grep -A 2 -B 2 -i "umask"														>>	$RESULT_FILE 2>&1
fi
echo -e "\n>>  user 별 환경설정 파일 확인"																>>	$RESULT_FILE 2>&1
for DIR in $HOME_DIRS
do
    for UENV_FILE in $USER_ENV_FILES
    do
        echo $DIR/$UENV_FILE	>>	tmp.txt 2>&1
    done
done
for HOME_UENV_FILE in `cat tmp.txt`
do
    if [ -f $HOME_UENV_FILE ]; then
        echo " # $HOME_UENV_FILE 파일 존재"														>>	$RESULT_FILE 2>&1
        cat $HOME_UENV_FILE | grep -i "umask"													>>	$RESULT_FILE 2>&1
        echo "-----------------------------"													>>	$RESULT_FILE 2>&1
    else
        echo " # $HOME_UENV_FILE 파일 존재하지 않음"													>>	$RESULT_FILE 2>&1
        echo "-----------------------------"													>>	$RESULT_FILE 2>&1
    fi
done
rm -f tmp.txt
echo " "																						>>	$RESULT_FILE 2>&1
echo -e "\n>> 현재 로그인 계정의 ENV(환경변수)확인"														>>	$RESULT_FILE 2>&1
whoami																							>>	$RESULT_FILE 2>&1
umask																							>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "60" #SU 명령 사용가능 그룹 제한 미비
echo ">> /etc/pam.d/su 파일 내 pam_wheel.so 라인 확인"												>>	$RESULT_FILE 2>&1
if [ `cat /etc/pam.d/su | grep -i "pam_wheel.so" | grep -v "^#" | wc -l` -eq 0 ]; then
	echo "o /etc/pam.d/su 파일 내 pam_wheel.so 미 설정 중"											>>	$RESULT_FILE 2>&1
else
	if [ `cat /etc/pam.d/su | grep -i "pam_wheel.so" | grep -v "^#" | egrep -i "group|use_uid" | wc -l` -eq 0 ]; then
		echo "o /etc/pam.d/su 파일 내 pam_wheel.so 설정 중이나 su 명령어 사용그룹 미지정 중"					>>	$RESULT_FILE 2>&1
	else
		echo "o /etc/pam.d/su 파일 내 pam_wheel.so 설정 중이며 su 명령어 사용그룹 지정 중"					>>	$RESULT_FILE 2>&1
	fi
fi
cat /etc/pam.d/su | grep -i "pam_wheel.so"														>>	$RESULT_FILE 2>&1
echo -e "\n>> /bin/su 파일"																		>>	$RESULT_FILE 2>&1
echo " # others 권한 확인"																			>>	$RESULT_FILE 2>&1
right=`stat -c "%a" /bin/su`
if [ ${right: -1} -eq 0 ]; then
	echo "o /bin/su 실행 권한에 others 권한 부여되지 않음"												>>	$RESULT_FILE 2>&1
else
	echo "o /bin/su 실행 권한에 others 권한 부여되어 있음"												>>	$RESULT_FILE 2>&1
fi
echo -e "\n # 소유그룹 확인"																			>>	$RESULT_FILE 2>&1
su_group=`stat -c "%G" /bin/su`
if [ `grep -i $su_group /etc/group | awk -F: '{print$4}' | grep -v "$su_group" | wc -w` -eq 0 ]; then
	echo "o /bin/su 소유그룹이 $su_group 이며 해당 그룹 내 $su_group만 존재"								>>	$RESULT_FILE 2>&1
	if [ $su_group != root ]; then
		echo "  - root가 아닌 그룹으로 해당 그룹 확인 필요"													>>	$RESULT_FILE 2>&1
	fi
else
	echo "o /bin/su 소유그룹이 $su_group 이며 해당 그룹 내 $su_group 외 계정 존재"							>>	$RESULT_FILE 2>&1
	echo "  - 해당 그룹 내 계정 확인 필요"																>>	$RESULT_FILE 2>&1
fi
ls -alL /bin/su																					>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "61" #Cron 서비스 사용 계정 제한 미비
# (양)cron.allow, cron.deny 파일 내부에 계정이 존재하는 경우
# (양)cron.allow, cron.deny 파일 둘 다 없는경우(root만 cron 사용 가능)
# (취)cron.allow, cron.deny 파일이 없거나 파일 내부에 계정이 없는 경우
# (취)cron.allow 파일이 없고 cron.deny 파일에 내부에 계정이 없는 경우
echo ">> /etc/cron.allow 파일 확인"																>>	$RESULT_FILE 2>&1
if [ -f /etc/cron.allow ]; then
	if [ -z `cat /etc/cron.allow` ]; then
		echo "o /etc/cron.allow 파일 존재하나 파일 내 설정 존재하지 않음"									>>	$RESULT_FILE 2>&1
	else
		echo "o /etc/cron.allow 파일 존재하며 파일 내 설정 존재"											>>	$RESULT_FILE 2>&1
	fi
	ls -al /etc/cron.allow																		>>	$RESULT_FILE 2>&1
	cat /etc/cron.allow																			>>	$RESULT_FILE 2>&1
else
    echo "o /etc/cron.allow 파일 존재하지 않음"														>>	$RESULT_FILE 2>&1
fi
echo -e "\n>> /etc/cron.deny 파일 확인"															>>	$RESULT_FILE 2>&1
if [ -f /etc/cron.deny ]; then
    if [ -z `cat /etc/cron.deny` ]; then
        echo "o /etc/cron.deny 파일 존재하나 파일 내 설정 존재하지 않음"										>>	$RESULT_FILE 2>&1
    else
        echo "o /etc/cron.deny 파일 존재하며 파일 내 설정 존재"											>>	$RESULT_FILE 2>&1
    fi
    ls -al /etc/cron.deny																		>>	$RESULT_FILE 2>&1
    cat /etc/cron.deny																			>>	$RESULT_FILE 2>&1
else
    echo "o /etc/cron.deny 파일 존재하지 않음"														>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "62"
echo "o Solraris OS만 점검 해당되므로 LINUX OS의 경우 평가 해당없음"											>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "63"
echo "o Solraris OS만 점검 해당되므로 LINUX OS의 경우 평가 해당없음"											>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "64"
if [ -f /etc/passwd ]
then
    echo ">> /etc/passwd 에서 UID 0 존재 확인"														>>	$RESULT_FILE 2>&1
    if [ `awk -F: '$3==0 { print $1, $3 }' "/etc/passwd" | grep -v "root" | wc -l` -eq 0 ]; then
        echo "o root 외 UID가 '0'인 계정 존재하지 않음"													>>	$RESULT_FILE 2>&1
    else
        echo "o root 외 UID가 '0'인 계정 존재함"														>>	$RESULT_FILE 2>&1
        awk -F: '$3==0 { print $1, $3 }' "/etc/passwd" | grep -v "root"							>>	$RESULT_FILE 2>&1
    fi
else
    echo "o /etc/passwd 파일 미존재"																>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "65"
for dev in $dev_file
do
	echo "" > check.txt
	echo "" > no_mm.txt
	echo "" > yes_mm.txt
	echo ">> "$dev" 파일"																			>>	$RESULT_FILE 2>&1
	if [ `find /dev -type $dev | wc -l` -eq 0 ]
	then
		echo "o" $dev "파일 존재하지 않음"															>>	$RESULT_FILE 2>&1
		no_file=`expr $no_file + 1`
	else
		find /dev -type $dev	>>	check.txt
		for file in `cat check.txt`
		do
			major=`stat -c "%t" $file`
			minor=`stat -c "%T" $file`
			if [ -z $major ] || [ -z $minor ]; then
				ls -al $file	>>	no_mm.txt
			else
				ls -al $file	>>	yes_mm.txt
			fi
		done
		if [ `cat no_mm.txt | wc -w` -eq 0 ]; then
			echo "o major, minor가 없는 device 파일 존재하지 않음"										>>	$RESULT_FILE 2>&1
		else
			echo "o major, minor가 없는 device 파일 존재함"											>>	$RESULT_FILE 2>&1
			cat no_mm.txt																		>>	$RESULT_FILE 2>&1
		fi
	fi
	echo " "																					>>	$RESULT_FILE 2>&1	
done
rm -f no_mm.txt; rm -f yes_mm.txt; rm -f check.txt
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "66"
ch=`ch_service "snmp" "161"`
if [ $ch == check ] || [ $ch == review ];then
	echo "o SNMP 서비스 구동 중으로 사용 목적 파악 필요"														>>	$RESULT_FILE 2>&1
else
	echo "o SNMP 서비스 미구동 중으로 양호"																>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "67" #웹 서비스 정보 노출
if [ $APACHE_CHECK = "OFF" ] && [ $NGINX_CHECK = "OFF" ] ; then
	echo "o 웹 서비스(Apache, Nginx) 미구동 중이므로 양호"													>>	$RESULT_FILE 2>&1
else
	if [ $APACHE_CHECK = "OFF" ]; then
		echo "o Apache 서비스 비활성화"																>>	$RESULT_FILE 2>&1
	else
		echo "o Apache 서비스 활성화"																>>	$RESULT_FILE 2>&1
		echo ">> $ACONF 내 ServerTokens, Serversignature 확인"										>>	$RESULT_FILE 2>&1
		web_option "apache" "$ACONF" "ServerTokens"												>>	$RESULT_FILE 2>&1
		if [ $? -ne 0 ]; then echo "o ServerTokens 설정 없음"; fi									>>	$RESULT_FILE 2>&1
		web_option "apache" "$ACONF" "Serversignature"											>>	$RESULT_FILE 2>&1
		if [ $? -ne 0 ]; then echo "o Serversignature 설정 없음"; fi								>>	$RESULT_FILE 2>&1
		echo -e "\n>> $ACONF 내 Include 된 파일의 ServerTokens, Serversignature 확인"					>>	$RESULT_FILE 2>&1
		for extra in `cat apache_extra.txt`; do
			echo " ==> $extra <=="																>>	$RESULT_FILE 2>&1
			web_option "apache" "$extra" "ServerTokens|Serversignature"
		done
	fi
	if [ $NGINX_CHECK = "OFF" ]; then
		echo -e "\no Nginx 서비스 비활성화"															>>	$RESULT_FILE 2>&1
	else
		echo -e "\no Nginx 서비스 활성화"															>>	$RESULT_FILE 2>&1
		echo ">> $nxconf 내 server_tokens 확인"													>>	$RESULT_FILE 2>&1
		if [ `grep -n -i server_tokens $nxconf | grep -v '#' | wc -l` -eq 0 ]
		then
			echo " - server_tokens 설정 없음"														>>	$RESULT_FILE 2>&1
		else
			grep -n -i server_tokens $nxconf | grep -v '#'										>>	$RESULT_FILE 2>&1
		fi
		echo -e "\n>> $nxconf 내 Include 된 파일의 server_tokens 확인"								>>	$RESULT_FILE 2>&1
		for extra in `cat nginx_extra.txt`; do
			echo " ==> $extra <=="																>>	$RESULT_FILE 2>&1
			web_option "nginx" "$extra" "server_tokens"
		done
	fi
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "68"
ch_service "telnet" "23" >/dev/null
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "69" #ftpusers 파일의 소유자 및 권한 설정 미흡
if [ `ch_service "ftp" "NA"` == check ]; then
	if [ `find /etc -type f -name "ftpusers" | wc -l` -eq 0 ]; then ftpusers="null"; else ftpusers=`find /etc -type f -name "ftpusers"`; fi
	if [ `find /etc -type f -name "user_list" | wc -l` -eq 0 ]; then userlist="null"; else userlist=`find /etc -type f -name "user_list"`; fi
	if [ `find /etc -type f -name "vsftpd.conf" | wc -l` -eq 0 ]; then vsftpd="null"; else vsftpd=`find /etc -type f -name "vsftpd.conf"`; fi
	if [ $ftpusers == "null" ] && [ $userlist == "null" ]; then
		echo -e "\n>> ftpusers, user_list 파일 확인"													>>	$RESULT_FILE 2>&1
		echo "o ftpusers, user_list 파일 존재하지 않음"													>>	$RESULT_FILE 2>&1
	else
		userlist_enable=`cat $vsftpd | grep -i "userlist_enable" | grep -v "^#" | awk -F'=' '{print $2}' | tr '[A-Z]' '[a-z]'`
		echo -e "\n>> userlist_enable 설정 확인"														>>	$RESULT_FILE 2>&1
		if [ -z $userlist_enable ]; then
			echo -e "o $vsftpd 파일 내 userlist_enable 설정없음 (ftpusers 확인)\n"							>>	$RESULT_FILE 2>&1
		else
			if [ $userlist_enable == "yes" ]; then
				echo "o $vsftpd 파일 내 userlist_enable = YES 설정 중 (user_list, ftpusers 확인)"			>>	$RESULT_FILE 2>&1
				cat $vsftpd | grep -i "userlist_enable" | grep -v "^#"								>>	$RESULT_FILE 2>&1
				echo " "																			>>	$RESULT_FILE 2>&1
				check_per "$userlist" "6" "4" "0"
				ls -alL "$userlist"																	>>	$RESULT_FILE 2>&1
			else
				echo "o $vsftpd 파일 내 userlist_enable = NO 설정 중 (ftpusers 확인)"						>>	$RESULT_FILE 2>&1
				cat $vsftpd | grep -i "userlist_enable" | grep -v "^#"								>>	$RESULT_FILE 2>&1
				echo " "																			>>	$RESULT_FILE 2>&1
			fi
		fi
		echo -e "\n>> $ftpusers 권한 확인"																>>	$RESULT_FILE 2>&1
		check_per "$ftpusers" "6" "4" "0"
		ls -al $ftpusers																			>>	$RESULT_FILE 2>&1
	fi
else
	echo "o FTP 서비스 미구동 중으로 양호"																	>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "70"
echo ">> /etc/issue 파일 - 로그인 경고메세지 설정"															>>	$RESULT_FILE 2>&1
cat /etc/issue																						>>	$RESULT_FILE 2>&1
echo ">> /etc/issue.net 파일 - 로그인 경고메세지 설정"														>>	$RESULT_FILE 2>&1
#Ubuntu 의 경우 /etc/motd 없을 시 /etc/issue.net 이 디폴트로 출력됨
cat /etc/issue.net																					>>	$RESULT_FILE 2>&1
echo -e "\n>> /etc/motd 파일 - 시스템 사용 주의사항 설정"														>>	$RESULT_FILE 2>&1
cat /etc/motd																						>>	$RESULT_FILE 2>&1
echo -e "\n>> /etc/ssh/sshd_config 파일 - Banner 값 설정"												>>	$RESULT_FILE 2>&1
if [ `ch_service "ssh" "NA" "ssh-agent"` == "check" ]; then
	SSH_BANNER=`cat /etc/ssh/sshd_config | grep -i "Banner"  | grep -v '\#' | awk -F ' ' '{ print $2 }'`
	if [ $SSH_BANNER ]; then
		echo " # SSH BANNER 위치 = [ $SSH_BANNER ]"													>>	$RESULT_FILE 2>&1
		cat /etc/ssh/sshd_config | grep -i "Banner"													>>	$RESULT_FILE 2>&1
		echo " # SSH BANNER 내용"																		>>	$RESULT_FILE 2>&1
		ls -alL $SSH_BANNER																			>>	$RESULT_FILE 2>&1
		cat $SSH_BANNER																				>>	$RESULT_FILE 2>&1
	else
		echo "o SSH BANNER 설정 존재하지 않음"															>>	$RESULT_FILE 2>&1
	fi
else
	echo "o SSH 서비스 미구동 중"																			>>	$RESULT_FILE 2>&1
fi
if [ $infra == "D" ]; then
	echo -e "\n>> .hushlogin 존재 확인(로그인 시 마지막 로그인 정보 등 출력 제한 파일)"								>>	$RESULT_FILE 2>&1
	sudo find /root -type f -name "*hushlogin"														>>	$RESULT_FILE 2>&1
	sudo find /home -type f -name "*hushlogin"														>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "71" #구성원이 존재하지 않는 GID 존재
cat /etc/passwd | awk -F: '{print$1}'	> pw.txt
cat /etc/group | awk -F: '$4==null' | awk -F: '{print$1}'	> gr.txt
for pw in `cat pw.txt`
do
	for gr in `cat gr.txt`
	do
		if [ $pw == $gr ]; then
			echo "$gr"	>> y.txt
		fi
	done
done
y=(`cat y.txt`)
cat /etc/group | awk -F: '$4==null'	> group.txt
for ((i=0;i<${#y[@]};i++))
do
	cat group.txt | grep -i ${y[$i]}	>> y_user.txt
done
diff -r group.txt y_user.txt | grep "<" | awk -F: '$3>999' | awk -F'<' '{print$2}'	> n_user.txt
echo ">> 구성원이 존재하지 않는 GID 존재 확인"																	>>	$RESULT_FILE 2>&1
if [ `cat n_user.txt | wc -l` -gt 0 ]; then
	echo "ㅇ GID 1000 이상인 그룹 중 구성원이 존재하지 않는 그룹 존재함"												>>	$RESULT_FILE 2>&1
	cat n_user.txt																					>>	$RESULT_FILE 2>&1
else
	echo "ㅇ GID 1000 이상인 그룹 중 구성원이 존재하지 않는 그룹 존재하지 않음"											>>	$RESULT_FILE 2>&1
fi
rm -f pw.txt; rm -f gr.txt; rm -f y.txt; rm -f group.txt; rm -f y_user.txt; rm -f n_user.txt
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "72"
echo ">> 불필요하게 Shell이 부여된 계정 확인"																	>>	$RESULT_FILE 2>&1
cat /etc/passwd | egrep "^daemon|^bin|^sys|^adm|^listen|^nobody|^nobody4|^noaccess|^diag|^operator|^games|^gopher" | grep -v "admin"	>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "73"
dir="/etc /bin /root /boot /tmp"; num=1
for DIR in $dir
do
	echo ">> "$num". "$DIR""																	>>	$RESULT_FILE 2>&1
	echo " # 숨겨진 파일 확인"																		>>	$RESULT_FILE 2>&1
	if [ `find $DIR -type f -name ".*" | wc -l` -eq 0 ]; then
		echo "o "$DIR" 내 숨겨진 파일 존재하지 않음"														>>	$RESULT_FILE 2>&1
	else
		find $DIR -type f -name ".*" -exec ls -al {} \;											>>	$RESULT_FILE 2>&1
	fi
	echo " # 숨겨진 디렉터리 확인"																		>>	$RESULT_FILE 2>&1
	if [ `find $DIR -type d -name ".*" | wc -l` -eq 0 ]; then
		echo "o "$DIR" 내 숨겨진 디렉터리 존재하지 않음"													>>	$RESULT_FILE 2>&1
	else
		find $DIR -type d -name ".*" -exec ls -ald {} \;										>>	$RESULT_FILE 2>&1
	fi
	echo " "																					>>	$RESULT_FILE 2>&1
	num=`expr $num + 1`
done
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "74" #SMTP 서비스 정보 노출 (2023 항목 추가)
if [ $sendmail_state -eq 1 ] && [ $postfix_state -eq 1 ] && [ $exim_state -eq 1 ]; then
	echo "o SMTP(Sendmail, Postfix, Exim) 서비스 미구동 중으로 평가 해당없음"								>>	$RESULT_FILE 2>&1
else
	if [ $sendmail_state -eq 0 ]; then
		do_find_parameter "/etc/mail/sendmail.cf" "SmtpGreetingMessage"									>>	$RESULT_FILE 2>&1
	fi
	if [ $postfix_state -eq 0 ]; then
		do_find_parameter "/etc/postfix/main.cf" "smtpd_banner"											>>	$RESULT_FILE 2>&1
	fi
	if [ $exim_state -eq 0 ]; then
		do_find_parameter "/etc/exim4/exim4.conf.template" "banner"										>>	$RESULT_FILE 2>&1
		echo " "																						>>	$RESULT_FILE 2>&1
		do_find_parameter "/etc/exim/exim4.conf" "banner"												>>	$RESULT_FILE 2>&1
	fi
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "75" #FTP 서비스 정보 노출 (2023 항목 추가)
if [ `ch_service "ftp" "NA"` == check ]; then
	echo -e "\n>> sftp 배너 확인"																>>	$RESULT_FILE 2>&1
	if [ `ps -ef | grep -i "ftp" | egrep -v -i "/sftp|grep" | wc -l` -eq 0 ]; then
		echo "o SFTP 서비스 구동 중으로 SSH_BANNER 확인"											>>	$RESULT_FILE 2>&1
	fi
	echo -e "\n>> vsftpd 배너 확인"															>>	$RESULT_FILE 2>&1
	if [ $vsftpd == "null" ]; then
		echo "o vsftpd.conf 파일 존재하지 않음"													>>	$RESULT_FILE 2>&1
	else
		cat $vsftpd | grep -i "banner"														>>	$RESULT_FILE 2>&1
	fi
	echo -e "\n>> proftpd 배너 확인"															>>	$RESULT_FILE 2>&1
	if [ -f /etc/proftpd.conf ]; then
		echo " # /etc/proftpd.conf"															>>	$RESULT_FILE 2>&1
		cat /etc/proftpd.conf | grep -i "banner"											>>	$RESULT_FILE 2>&1
	elif [ -f /usr/local/etc/proftpd.conf ]; then
		echo " # /usr/local/etc/proftpd.conf"												>>	$RESULT_FILE 2>&1
		cat /usr/local/etc/proftpd.conf | grep -i "banner"									>>	$RESULT_FILE 2>&1
	else
		echo "o proftpd.conf 파일 존재하지 않음"													>>	$RESULT_FILE 2>&1
	fi
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "76" #DNS 서비스의 취약한 동적 업데이트 설정 (2023 항목 추가)
ch=`ch_service "named" "53" "dnsmasq|systemd-hostnamed.service"`
if [ $ch == check ]; then
	echo -e "\n>> /etc/named.conf의 allow-update 확인"													>>	$RESULT_FILE 2>&1
	do_find_parameter "/etc/named.conf" "allow-update"											>>	$RESULT_FILE 2>&1
	echo -e "\n>> /etc/named.conf의 update-policy 확인"											>>	$RESULT_FILE 2>&1
	do_find_parameter "/etc/named.conf" "update-policy"											>>	$RESULT_FILE 2>&1
else
	echo "o DNS 서버 미구동 중으로 평가 해당없음"															>>	$RESULT_FILE 2>&1
fi
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "77" #불필요한 DNS 서비스 실행
if [ `ch_service "named" "53" "dnsmasq|systemd-hostnamed.service"` != check ]; then echo "o DNS 서버 미구동 중으로 양호"; fi	>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


FUNC_CODE "78" #NTP 및 시각 동기화 미설정 (2023 항목 추가)
echo ">> ntpq -pn 명령 실행"																		>>	$RESULT_FILE 2>&1
ntpq -pn																						>>	$RESULT_FILE 2>&1
echo -e "\n>> ntpstat 명령 실행"																	>>	$RESULT_FILE 2>&1
ntpstat 																						>>	$RESULT_FILE 2>&1
echo -e "\n>> chronyd 명령 실행"																	>>	$RESULT_FILE 2>&1
echo " # chronyc sources 확인"																	>>	$RESULT_FILE 2>&1
chronyc sources 																				>>	$RESULT_FILE 2>&1
echo -e "\n # chronyc tracking 확인"																>>	$RESULT_FILE 2>&1
chronyc tracking 																				>>	$RESULT_FILE 2>&1
echo -e "\n # timedatectl status 확인"															>>	$RESULT_FILE 2>&1
timedatectl status 																				>>	$RESULT_FILE 2>&1
echo -e "\n>> date \"+%Y-%m-%d %T\" 명령 실행"														>>	$RESULT_FILE 2>&1
date "+%Y-%m-%d %T" 																			>>	$RESULT_FILE 2>&1
echo -e "\n>> ss -nl 명령 실행"																	>>	$RESULT_FILE 2>&1
ss -nl | grep -i "udp" | grep "123"																>>	$RESULT_FILE 2>&1
echo -e "\n>> ps -ef 명령 실행"																	>>	$RESULT_FILE 2>&1
ps -ef | egrep -i "ntp|chrony" | egrep -v "grep"												>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"


####################################################################

echo -e "\n\e[4m<< 패치 관리 >>\e[0m"


FUNC_CODE "79"
echo "o 커널 버전: `uname -a | awk '{printf $3}'`"													>>	$RESULT_FILE 2>&1
if [ $infra == "R" ]; then
	echo "o 릴리즈 버전: `cat /etc/*-release | grep "release" | uniq | awk -F"release" '{printf $2}'`"	>>	$RESULT_FILE 2>&1
else 
	echo "o 릴리즈 버전: `cat /etc/*-release | grep -i "PRETTY_NAME"`"								>>	$RESULT_FILE 2>&1
fi
echo " "																						>>	$RESULT_FILE 2>&1
if [ $infra == "R" ]; then
	echo " >> 주요 패키지 리스트"																		>>	$RESULT_FILE 2>&1
	rpm -qa > /tmp/patch_list_tmp
	cat /tmp/patch_list_tmp | egrep -i "syslog|telnet|ssh|ftp|nfs|samba|ypserv|ntpd|vim"		>>	$RESULT_FILE 2>&1
else
	echo ">> 주요 패키지 리스트-ubuntu"																>>	$RESULT_FILE 2>&1
	dpkg -l | egrep -i "syslog|telnet|ssh|ftp|nfs|samba|ypserv|ntpd|vim"						>>	$RESULT_FILE 2>&1
fi
echo " "																						>>	$RESULT_FILE 2>&1
echo -e "\n>> uname -a 명령 실행"																	>>	$RESULT_FILE 2>&1
uname -a																						>>	$RESULT_FILE 2>&1
echo -e "\n>> /etc/*-release 명령 실행"															>>	$RESULT_FILE 2>&1
cat /etc/*-release | uniq																		>>	$RESULT_FILE 2>&1
echo -e "\n>> rpm -qa *-release 명령 실행"														>>	$RESULT_FILE 2>&1
rpm -qa *-release																				>>	$RESULT_FILE 2>&1
echo -e ".........\e[7mDone!\e[0m"



####################################################################

echo -e "\n\n"																					>>	$RESULT_FILE 2>&1
echo "======================================================================================"	>>	$RESULT_FILE 2>&1
echo "==========                 Collect Row Data - System status                 =========="	>>	$RESULT_FILE 2>&1
echo "======================================================================================"	>>	$RESULT_FILE 2>&1
echo -e "\n"																					>>	$RESULT_FILE 2>&1


echo -e "\n\n\e[34m##################################################"
echo -e "        Collect Row Data - System status"
echo -e "##################################################\e[0m\n"

echo "(1) DATE"
echo "======================================================================================"	>>	$RESULT_FILE 2>&1
echo "[ META DATA - (1) DATE ]"																	>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
date																							>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "DATE"																						>>	$RESULT_FILE 2>&1
echo -e "======================================================================================\n\n"	>>	$RESULT_FILE 2>&1

echo "(2) OS Information"
echo "======================================================================================"	>>	$RESULT_FILE 2>&1
echo "[ META DATA - (2) OS Information ]"														>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
uname -a																						>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "OS Information"																			>>	$RESULT_FILE 2>&1
echo -e "======================================================================================\n\n"	>>	$RESULT_FILE 2>&1

echo "(3) Process List"
echo "======================================================================================"	>>	$RESULT_FILE 2>&1
echo "[ META DATA - (3) Process List ]"															>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
ps -ef																							>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "Process List"																				>>	$RESULT_FILE 2>&1
echo -e "======================================================================================\n\n"	>>	$RESULT_FILE 2>&1

echo "(4) services"
echo "======================================================================================"	>>	$RESULT_FILE 2>&1
echo "[ META DATA - (4) services ]"																>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "[ o 전체 서비스 포트 상태 확인: /etc/services ]"													>>	$RESULT_FILE 2>&1
cat /etc/services																				>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "[ o 전체 서비스 구동상태확인 ]"																	>>	$RESULT_FILE 2>&1
systemctl list-unit-files																		>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "Services Information"																		>>	$RESULT_FILE 2>&1
echo -e "======================================================================================\n\n"	>>	$RESULT_FILE 2>&1

echo "(5) Netstat"
echo "======================================================================================"	>>	$RESULT_FILE 2>&1
echo "[ META DATA - (5) Netstat ]"																>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
if [ $infra == "R" ]; then
	echo "[ o netstat ]"																		>>	$RESULT_FILE 2>&1
	netstat -anp | egrep -i "tcp|udp" | grep -i listen											>>	$RESULT_FILE 2>&1
fi
echo " "																						>>	$RESULT_FILE 2>&1
echo "[ o ss ]"																					>>	$RESULT_FILE 2>&1
ss -nl | egrep -i "tcp|udp"																		>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "Network Connection Information"															>>	$RESULT_FILE 2>&1
echo -e "======================================================================================\n\n"	>>	$RESULT_FILE 2>&1

echo "(6) Ipconfig"
echo "======================================================================================"	>>	$RESULT_FILE 2>&1
echo "[ META DATA - (6) Ipconfig ]"																>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
ip a																							>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "Network Interface Information"															>>	$RESULT_FILE 2>&1
echo -e "======================================================================================\n\n"	>>	$RESULT_FILE 2>&1

####################################################################

echo -e "\n\n"																					>>	$RESULT_FILE 2>&1
echo "======================================================================================"	>>	$RESULT_FILE 2>&1
echo "==========                     Collect Row Data - FILE                      =========="	>>	$RESULT_FILE 2>&1
echo "======================================================================================"	>>	$RESULT_FILE 2>&1
echo -e "\n"																					>>	$RESULT_FILE 2>&1

echo -e "\n\n\e[34m##################################################"
echo -e "             Collect Row Data - FILE "
echo -e "##################################################\e[0m\n"

echo "(1) PAM file" | tee -a $RESULT_FILE
echo "======================================================================================"	>>	$RESULT_FILE 2>&1
echo "[ (1-1) system-auth ]"																	>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/pam.d/system-auth																		>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
echo "[ (1-2) password-auth ]"																	>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/pam.d/password-auth																	>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
echo "[ (1-3) common-auth ]"																	>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/pam.d/common-auth																		>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
echo "[ (1-4) common-password ]"																>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/pam.d/common-password																	>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
echo "[ (1-5) pwquality.conf ]"																	>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/security/pwquality.conf																>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo -e "======================================================================================\n\n"	>>	$RESULT_FILE 2>&1


echo "(2) SMTP file" | tee -a $RESULT_FILE
echo "======================================================================================"	>>	$RESULT_FILE 2>&1
echo "[ (2-1) /etc/mail/sendmail.cf ]"															>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/mail/sendmail.cf																		>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
echo "[ (2-2) /etc/postfix/main.cf ]"															>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/postfix/main.cf																		>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
echo "[ (2-3) /etc/exim4/exim4.conf.template ]"													>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/exim4/exim4.conf.template																>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
echo "[ (2-4) /etc/exim/exim4.conf ]"															>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/exim/exim4.conf																		>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
echo "[ (2-5) /etc/exim4/conf.d/*.conf ]"														>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
head -n -0 /tmp/script/a/*.config																>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo -e "======================================================================================\n\n"	>>	$RESULT_FILE 2>&1


echo "(3) FTP file" | tee -a $RESULT_FILE
echo "======================================================================================"	>>	$RESULT_FILE 2>&1
echo "[ (3-1) /etc/vsftpd/vsftpd.conf ]"															>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/vsftpd/vsftpd.conf																		>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
echo "[ (3-2) /etc/vsftpd/ftpusers ]"															>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/vsftpd/ftpusers																		>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
echo "[ (3-3) /etc/vsftpd/user_list ]"															>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/vsftpd/user_list																		>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
echo "[ (3-4) /etc/vsftpd.ftpusers ]"															>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/vsftpd.ftpusers																		>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
echo "[ (3-5) /etc/proftpd.conf ]"																>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/proftpd.conf																			>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
echo "[ (3-6) /usr/local/etc/proftpd.conf ]"													>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /usr/local/etc/proftpd.conf																	>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo -e "======================================================================================\n\n"	>>	$RESULT_FILE 2>&1


echo "(4) User file" | tee -a $RESULT_FILE
echo "======================================================================================"	>>	$RESULT_FILE 2>&1
echo "[ (4-1) /etc/passwd ]"																	>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/passwd																					>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
echo "[ (4-2) /etc/group ]"																		>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/group																					>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
echo "[ (4-3) /etc/shadow ]"																	>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/shadow																					>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
echo "[ (4-4) /etc/login.defs ]"																>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
cat /etc/login.defs																				>>	$RESULT_FILE 2>&1
echo " "																						>>	$RESULT_FILE 2>&1
echo -e "======================================================================================\n\n"	>>	$RESULT_FILE 2>&1


if [ $APACHE_CHECK = "ON" ] || [ $NGINX_CHECK = "ON" ]; then
	echo "(5) WEB Conf file" | tee -a $RESULT_FILE
	echo "======================================================================================"	>>	$RESULT_FILE 2>&1
	if [ $APACHE_CHECK = "ON" ]; then
		echo "[ (5-Apache-1) $ACONF ]"																	>>	$RESULT_FILE 2>&1
		echo " "																						>>	$RESULT_FILE 2>&1
		cat $ACONF																						>>	$RESULT_FILE 2>&1
		echo " "																						>>	$RESULT_FILE 2>&1
		echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
		if [ -f apache_extra.txt ]; then
			echo "[ (5-Apache-2) Include 파일 ]"															>>	$RESULT_FILE 2>&1
			for extra in `cat apache_extra.txt`; do
				echo " ==> $extra <=="																	>>	$RESULT_FILE 2>&1
				ls -alL $extra																			>>	$RESULT_FILE 2>&1
				cat $extra																				>>	$RESULT_FILE 2>&1
				echo " "																				>>	$RESULT_FILE 2>&1
			done
			rm -f apache_extra.txt
		fi
	fi
	if [ $NGINX_CHECK = "ON" ]; then
		echo "[ (5-NginX-1) $nxconf ]"																	>>	$RESULT_FILE 2>&1
		echo " "																						>>	$RESULT_FILE 2>&1
		cat $nxconf																						>>	$RESULT_FILE 2>&1
		echo " "																						>>	$RESULT_FILE 2>&1
		echo "---------------------------------------------------------------------------------------"	>>	$RESULT_FILE 2>&1
		if [ -f nginx_extra.txt ]; then
			echo "[ (5-NginX-2) Include 파일 ]"															>>	$RESULT_FILE 2>&1
			for extra in `cat nginx_extra.txt`; do
				echo " ==> $extra <=="																	>>	$RESULT_FILE 2>&1
				ls -alL $extra																			>>	$RESULT_FILE 2>&1
				cat $extra																				>>	$RESULT_FILE 2>&1
				echo " "																				>>	$RESULT_FILE 2>&1
			done
			rm -f nginx_extra.txt
		fi
	fi
	echo -e "======================================================================================\n\n"	>>	$RESULT_FILE 2>&1
	rm -f start.txt; rm -f extra.txt; rm -f end.txt; rm -f dir.txt
fi


rm -f ps.txt; rm -f netstat.txt

echo -e "\n\n\e[34m##################################################"
echo -e "                Script ... End"
echo -e "##################################################\e[0m\n"

echo -n "스크립트 구동 종료 - ${TODAY} ">> $RESULT_FILE 2>&1
date "+%H:%M:%S" >> $RESULT_FILE 2>&1

echo -e " └─ 스크립트 실행이 완료되었습니다."
echo -e " └─ \e[32m$RESULT_FILE 결과 파일을 회신해주세요.\e[0m\n\n"